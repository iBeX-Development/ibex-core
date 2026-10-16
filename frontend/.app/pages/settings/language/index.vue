<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import AddModalForm from './AddModalForm.vue'

const { t, locale, setLocaleMessage } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const { getItems, createItems, updateItem, deleteItems } = useDirectusItems()
const myCompanyId = Number(getMyCompanyId())

definePageMeta({
  middleware: ['auth'],
  title: 'Language Settings',
  showback: true,
})

// ─── Language definitions ─────────────────────────────────────────────────
type Language = { code: string; label: string; flag: string; icon?: string }

const DEFAULT_LANGUAGES: Language[] = [
  { code: 'en', label: 'English', flag: '🇺🇸' },
  { code: 'mn', label: 'Монгол', flag: '🇲🇳' },
  { code: 'zh', label: '中文', flag: '🇨🇳' },
  { code: 'jp', label: '日本語', flag: '🇯🇵' },
  { code: 'ko', label: '한국어', flag: '🇰🇷' },
  { code: 'kz', label: 'Қазақша', flag: '🇰🇿' },
]

// ─── State ────────────────────────────────────────────────────────────────
const allMaps = ref<Record<string, Record<string, string>>>({})
// Тухайн компанийн override-үүд: overrideMaps[lang][key] = value
const overrideMaps = ref<Record<string, Record<string, string>>>({})
// Directus мөрийн id-г хадгална (update/delete хийхэд хэрэгтэй)
const overrideRowsMap = ref<Record<string, Record<string, string | number>>>({})
const languages = ref<Language[]>(DEFAULT_LANGUAGES)
const activeLangs = ref<string[]>(['en', 'mn'])
const activeTab = ref('mn')
const loading = ref(true)
const saving = ref(false)
const configSaving = ref(false)

// dirty[langCode] = { key: newValue }
const dirty = ref<Record<string, Record<string, string>>>({})

// Pagination + search
const search = ref('')
const page = ref(1)
const perPage = 50

// Inline edit
const editingKey = ref<string | null>(null)
const editingVal = ref('')

// Add modal
const isAddOpen = ref(false)

// Add language modal
const isAddLangOpen = ref(false)
const newLangForm = ref<Language>({ code: '', label: '', flag: '' })
const addLangSaving = ref(false)

// Delete confirm
const deleteKey = ref<string | null>(null)

// ─── Helpers ──────────────────────────────────────────────────────────────
const enMap = computed(() => allMaps.value['en'] ?? {})
const enKeys = computed(() => Object.keys(enMap.value))
const enCount = computed(() => enKeys.value.length)
const currentLang = computed(() =>
  languages.value.find((l) => l.code === activeTab.value),
)

const dirtyForLang = (lang: string) => dirty.value[lang] ?? {}
const dirtyCountForLang = (lang: string) =>
  Object.keys(dirtyForLang(lang)).length
const currentDirty = computed(() => dirtyForLang(activeTab.value))
const currentDirtyCount = computed(() => dirtyCountForLang(activeTab.value))

const isLangActive = (code: string) => activeLangs.value.includes(code)
const iconExtensions = ['svg', 'png', 'jpg', 'jpeg', 'webp']
const languageIconExtensionIndex = ref<Record<string, number>>({})

const languageIconSrc = (language: Language) => {
  if (!language.icon) return ''
  if (/\.(svg|png|jpe?g|webp)(\?.*)?$/i.test(language.icon)) {
    return language.icon
  }
  const index = languageIconExtensionIndex.value[language.code] ?? 0
  return `${language.icon}.${iconExtensions[index]}`
}

const tryNextLanguageIconExtension = (language: Language) => {
  if (/\.(svg|png|jpe?g|webp)(\?.*)?$/i.test(language.icon ?? '')) return
  const currentIndex = languageIconExtensionIndex.value[language.code] ?? 0
  if (currentIndex < iconExtensions.length - 1) {
    languageIconExtensionIndex.value = {
      ...languageIconExtensionIndex.value,
      [language.code]: currentIndex + 1,
    }
  }
}

// base JSON дээр компанийн override-г нэгтгэсэн "жинхэнэ" утга — end-user
// хэрэглэгч бодит байдал дээр яг үүнийг л харна
const effectiveMap = (lang: string) => ({
  ...(allMaps.value[lang] ?? {}),
  ...(overrideMaps.value[lang] ?? {}),
})

// ─── Table entries ────────────────────────────────────────────────────────
const allEntries = computed(() => {
  const map = effectiveMap(activeTab.value)
  const overrides = overrideMaps.value[activeTab.value] ?? {}
  const d = currentDirty.value
  return enKeys.value.map((key) => ({
    key,
    en: enMap.value[key] ?? key,
    current: key in d ? d[key] : map[key] ?? '',
    isDirty: key in d,
    isOverridden: key in overrides,
  }))
})

const filtered = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return allEntries.value
  return allEntries.value.filter(
    (e) =>
      e.key.toLowerCase().includes(q) ||
      e.en.toLowerCase().includes(q) ||
      e.current.toLowerCase().includes(q),
  )
})

const totalPages = computed(() => Math.ceil(filtered.value.length / perPage))
const paginated = computed(() => {
  const start = (page.value - 1) * perPage
  return filtered.value.slice(start, start + perPage)
})

// Тухайн компанийн Translation_overrides мөрүүдийг ачаална (бүх хэлээр)
const loadOverrides = async () => {
  if (!myCompanyId) return
  try {
    const res = await getItems<any>({
      collection: 'Translation_overrides',
      params: {
        filter: { company_id: { _eq: myCompanyId } },
        fields: ['id', 'lang_code', 'key', 'value'],
        limit: -1,
      },
    })
    const rows = Array.isArray(res) ? res : (res as any)?.data ?? []
    const maps: Record<string, Record<string, string>> = {}
    const rowsMap: Record<string, Record<string, string | number>> = {}
    for (const row of rows) {
      if (!maps[row.lang_code]) maps[row.lang_code] = {}
      if (!rowsMap[row.lang_code]) rowsMap[row.lang_code] = {}
      maps[row.lang_code][row.key] = row.value
      rowsMap[row.lang_code][row.key] = row.id
    }
    overrideMaps.value = maps
    overrideRowsMap.value = rowsMap
  } catch {
    overrideMaps.value = {}
    overrideRowsMap.value = {}
  }
}

// ─── Load ─────────────────────────────────────────────────────────────────
const load = async () => {
  loading.value = true
  try {
    const data = await $fetch<any>('/api/translations')
    const configuredLanguages = data.config?.languages
    languages.value = configuredLanguages?.length
      ? configuredLanguages
      : DEFAULT_LANGUAGES
    for (const l of languages.value) {
      allMaps.value[l.code] = data[l.code] ?? {}
    }
    await loadOverrides()
    for (const l of languages.value) {
      const merged = effectiveMap(l.code)
      if (Object.keys(merged).length) {
        setLocaleMessage(l.code, merged)
      }
    }
    if (data.config?.active) activeLangs.value = data.config.active
  } catch {
    toaster.show({
      title: t('Error'),
      message: t('Failed to load translations'),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  }
  loading.value = false
}

// ─── Tab switch ───────────────────────────────────────────────────────────
const switchTab = (code: string) => {
  commitEdit()
  activeTab.value = code
  page.value = 1
  search.value = ''
}

// ─── Add language ───────────────────────────────────────────────────────────
const addLanguage = async () => {
  const code = newLangForm.value.code.trim().toLowerCase()
  const label = newLangForm.value.label.trim()
  if (!/^[a-z][a-z0-9_-]{1,15}$/.test(code) || !label) {
    toaster.show({
      title: t('Error'),
      message: t('Use a valid language code'),
      color: 'danger',
    })
    return
  }
  if (languages.value.some((l) => l.code === code)) {
    toaster.show({
      title: t('Error'),
      message: t('Language code already exists'),
      color: 'danger',
    })
    return
  }

  const language: Language = {
    code,
    label,
    flag: newLangForm.value.flag.trim(),
  }
  addLangSaving.value = true
  try {
    const nextLanguages = [...languages.value, language]
    await $fetch('/api/translations', {
      method: 'POST',
      body: { config: { active: activeLangs.value, languages: nextLanguages } },
    })
    languages.value = nextLanguages
    allMaps.value[language.code] = {}
    isAddLangOpen.value = false
    newLangForm.value = { code: '', label: '', flag: '' }
    switchTab(language.code)
    toaster.show({
      title: t('Added'),
      message: `"${language.label}" ${t('Added')}`,
      color: 'success',
      icon: 'ph:plus-circle',
      closable: true,
    })
  } catch {
    toaster.show({
      title: t('Error'),
      message: t('Error saving'),
      color: 'danger',
    })
  }
  addLangSaving.value = false
}

// ─── Toggle active / inactive ─────────────────────────────────────────────
const toggleActive = async (code: string) => {
  if (code === 'en') return
  configSaving.value = true
  const newActive = isLangActive(code)
    ? activeLangs.value.filter((c) => c !== code)
    : [...activeLangs.value, code]
  if (!newActive.includes('en')) newActive.unshift('en')
  try {
    await $fetch('/api/translations', {
      method: 'POST',
      body: { config: { active: newActive, languages: languages.value } },
    })
    activeLangs.value = newActive
    toaster.show({
      title: isLangActive(code) ? t('Active') : t('Inactive'),
      message: `${code.toUpperCase()} ${
        isLangActive(code) ? t('active') : t('inactive')
      }`,
      color: 'success',
      icon: 'ph:check-circle',
      closable: true,
    })
  } catch {
    toaster.show({
      title: t('Error'),
      message: t('Error saving'),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  }
  configSaving.value = false
}

// ─── Inline edit ──────────────────────────────────────────────────────────
const startEdit = (key: string) => {
  if (activeTab.value === 'en') return
  editingKey.value = key
  const map = effectiveMap(activeTab.value)
  const d = dirtyForLang(activeTab.value)
  editingVal.value = key in d ? d[key] : map[key] ?? ''
}

const commitEdit = () => {
  if (!editingKey.value) return
  const lang = activeTab.value
  const key = editingKey.value
  const original = effectiveMap(lang)[key] ?? ''
  if (!dirty.value[lang]) dirty.value[lang] = {}
  if (editingVal.value !== original) {
    dirty.value[lang] = { ...dirty.value[lang], [key]: editingVal.value }
  } else {
    const { [key]: _, ...rest } = dirty.value[lang]
    dirty.value[lang] = rest
  }
  editingKey.value = null
}

const cancelEdit = () => {
  editingKey.value = null
}

// ─── Save current lang (company override — Translation_overrides руу бичнэ,
// base JSON-д хүрэхгүй) ─────────────────────────────────────────────────────
const saveCurrentTab = async () => {
  const lang = activeTab.value
  if (lang === 'en' || !currentDirtyCount.value || !myCompanyId) return
  saving.value = true
  try {
    const rowsForLang = overrideRowsMap.value[lang] ?? {}
    await Promise.all(
      Object.entries(currentDirty.value).map(([key, value]) => {
        const existingId = rowsForLang[key]
        if (existingId) {
          return updateItem({
            collection: 'Translation_overrides',
            id: String(existingId),
            item: { value, date_updated: new Date().toISOString() },
          })
        }
        return createItems({
          collection: 'Translation_overrides',
          items: [{ company_id: myCompanyId, lang_code: lang, key, value }],
        })
      }),
    )
    await loadOverrides()
    dirty.value[lang] = {}
    setLocaleMessage(lang, effectiveMap(lang))
    toaster.show({
      title: t('Saved'),
      message: t('Translations saved'),
      color: 'success',
      icon: 'ph:check-circle',
      closable: true,
    })
  } catch {
    toaster.show({
      title: t('Error'),
      message: t('Error saving translations'),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  }
  saving.value = false
}

// Компанийн override-г хасаад base (default) утга руу буцаана
const resetToDefault = async (key: string) => {
  const lang = activeTab.value
  const rowId = overrideRowsMap.value[lang]?.[key]
  if (!rowId) return
  try {
    await deleteItems({
      collection: 'Translation_overrides',
      items: [String(rowId)],
    })
    const { [key]: _removedMap, ...restMap } = overrideMaps.value[lang] ?? {}
    overrideMaps.value = { ...overrideMaps.value, [lang]: restMap }
    const { [key]: _removedRow, ...restRows } =
      overrideRowsMap.value[lang] ?? {}
    overrideRowsMap.value = { ...overrideRowsMap.value, [lang]: restRows }
    if (dirty.value[lang]?.[key] !== undefined) {
      const { [key]: _d, ...restDirty } = dirty.value[lang]
      dirty.value[lang] = restDirty
    }
    setLocaleMessage(lang, effectiveMap(lang))
    toaster.show({
      title: t('Saved'),
      message: t('Reverted to default'),
      color: 'success',
      icon: 'ph:arrow-counter-clockwise',
      closable: true,
    })
  } catch {
    toaster.show({
      title: t('Error'),
      message: t('Error saving'),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  }
}

// ─── Add new ──────────────────────────────────────────────────────────────
const onAdd = async (payload: {
  key: string
  translations: Record<string, string>
}) => {
  const { key, translations } = payload
  if (!key.trim()) return
  const langsToUpdate: Record<string, Record<string, string>> = {}
  for (const l of languages.value) {
    langsToUpdate[l.code] = {
      ...(allMaps.value[l.code] ?? {}),
      [key]: translations[l.code] ?? (l.code === 'en' ? key : ''),
    }
  }
  try {
    await $fetch('/api/translations', {
      method: 'POST',
      body: { langs: langsToUpdate },
    })
    for (const l of languages.value) {
      allMaps.value[l.code] = langsToUpdate[l.code]
      setLocaleMessage(l.code, effectiveMap(l.code))
    }
    isAddOpen.value = false
    toaster.show({
      title: t('Added'),
      message: `"${key}" ${t('Added')}`,
      color: 'success',
      icon: 'ph:plus-circle',
      closable: true,
    })
  } catch {
    toaster.show({
      title: t('Error'),
      message: t('Error adding translation'),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  }
}

// ─── Delete ───────────────────────────────────────────────────────────────
const confirmDelete = (key: string) => {
  deleteKey.value = key
}

const doDelete = async () => {
  if (!deleteKey.value) return
  const key = deleteKey.value
  const langsToUpdate: Record<string, Record<string, string>> = {}
  for (const l of languages.value) {
    const { [key]: _, ...rest } = allMaps.value[l.code] ?? {}
    langsToUpdate[l.code] = rest
  }
  try {
    await $fetch('/api/translations', {
      method: 'POST',
      body: { langs: langsToUpdate },
    })
    for (const l of languages.value) {
      allMaps.value[l.code] = langsToUpdate[l.code]
      if (dirty.value[l.code]) {
        const { [key]: _, ...rest } = dirty.value[l.code]
        dirty.value[l.code] = rest
      }
    }

    // Key устсан тул бүх компанийн энэ key-тэй override мөрүүдийг цэвэрлэнэ
    // (default-руу буцах шаардлагагүй болсон "хогорсон" мөрүүд)
    try {
      const orphans = await getItems<any>({
        collection: 'Translation_overrides',
        params: {
          filter: { key: { _eq: key } },
          fields: ['id'],
          limit: -1,
        },
      })
      const orphanRows = Array.isArray(orphans)
        ? orphans
        : (orphans as any)?.data ?? []
      if (orphanRows.length) {
        await deleteItems({
          collection: 'Translation_overrides',
          items: orphanRows.map((r: any) => String(r.id)),
        })
      }
    } catch {
      // цэвэрлэгээ амжилтгүй бол ч гэсэн key нь base-ээс устсан хэвээр
    }
    await loadOverrides()
    for (const l of languages.value) {
      setLocaleMessage(l.code, effectiveMap(l.code))
    }

    deleteKey.value = null
    toaster.show({
      title: t('Deleted'),
      message: `"${key}" ${t('Deleted')}`,
      color: 'success',
      icon: 'ph:trash',
      closable: true,
    })
  } catch {
    toaster.show({
      title: t('Error'),
      message: t('Error deleting translation'),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  }
}

watch(search, () => {
  page.value = 1
})
onMounted(load)
</script>

<template>
  <div class="mx-auto max-w-6xl space-y-4 p-4">
    <!-- ── Language Tabs ───────────────────────────────────────────────── -->
    <div class="flex flex-wrap gap-2">
      <button
        v-for="lang in languages"
        :key="lang.code"
        class="lang relative flex items-center gap-2 rounded-xl border px-4 py-2.5 text-sm font-medium transition-all"
        :class="
          activeTab === lang.code
            ? 'bg-primary-500 border-primary-500 text-white shadow-md'
            : 'bg-white dark:bg-muted-800 border-muted-200 dark:border-muted-700 text-muted-600 dark:text-muted-300 hover:border-primary-300'
        "
        @click="switchTab(lang.code)"
      >
        <img
          v-if="lang.icon"
          :src="languageIconSrc(lang)"
          :alt="lang.label"
          class="h-5 w-5 rounded-full object-cover"
          @error="tryNextLanguageIconExtension(lang)"
        />
        <span v-else class="text-lg leading-none">{{
          lang.flag || lang.code
        }}</span>
        <span>{{ lang.label }}</span>
        <!-- Active/Inactive pill -->
        <span
          class="rounded-full px-1.5 py-0.5 text-[10px] font-bold leading-none"
          :class="
            activeTab === lang.code
              ? 'bg-white/25 text-white'
              : isLangActive(lang.code)
              ? 'bg-success-100 text-success-700 dark:bg-success-900/40 dark:text-success-300'
              : 'bg-muted-100 text-muted-400 dark:bg-muted-700'
          "
        >
          {{ isLangActive(lang.code) ? 'ON' : 'OFF' }}
        </span>
        <!-- Dirty indicator dot -->
        <span
          v-if="dirtyCountForLang(lang.code) > 0"
          class="absolute -right-1 -top-1 h-2.5 w-2.5 rounded-full border-2 border-white bg-warning-400 dark:border-muted-900"
        />
      </button>

      <!-- Add language -->
      <button
        class="flex items-center gap-1.5 rounded-xl border border-dashed border-muted-300 px-4 py-2.5 text-sm font-medium text-muted-500 transition-all hover:border-primary-400 hover:text-primary-500 dark:border-muted-600"
        @click="isAddLangOpen = true"
      >
        <Icon name="ph:plus" class="h-4 w-4" />
        {{ t('Add language') }}
      </button>
    </div>

    <!-- ── Add language modal ──────────────────────────────────────────── -->
    <Transition
      enter-active-class="transition duration-150 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-100 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="isAddLangOpen"
        class="fixed inset-0 z-[9999] flex items-center justify-center p-4"
      >
        <div
          class="absolute inset-0 bg-muted-900/60 backdrop-blur-sm"
          @click="isAddLangOpen = false"
        />
        <div
          class="relative z-10 w-[380px] max-w-full rounded-xl bg-white dark:bg-muted-900 shadow-2xl p-6"
        >
          <div class="mb-4 flex items-center gap-3">
            <div
              class="flex h-10 w-10 items-center justify-center rounded-full bg-primary-100 dark:bg-primary-900/30"
            >
              <Icon name="ph:translate" class="h-5 w-5 text-primary-500" />
            </div>
            <p class="font-semibold text-muted-900 dark:text-white">
              {{ t('Add language') }}
            </p>
          </div>
          <div class="space-y-3">
            <label class="block">
              <span class="mb-1 block text-[11px] font-medium text-muted-500">{{
                t('Code')
              }}</span>
              <input
                v-model="newLangForm.code"
                placeholder="fr"
                class="w-full rounded-md border border-muted-300 bg-white px-2 py-1.5 text-sm dark:border-muted-600 dark:bg-muted-800"
              />
            </label>
            <label class="block">
              <span class="mb-1 block text-[11px] font-medium text-muted-500">{{
                t('Language name')
              }}</span>
              <input
                v-model="newLangForm.label"
                placeholder="Français"
                class="w-full rounded-md border border-muted-300 bg-white px-2 py-1.5 text-sm dark:border-muted-600 dark:bg-muted-800"
              />
            </label>
            <label class="block">
              <span class="mb-1 block text-[11px] font-medium text-muted-500">{{
                t('Flag or Emojipedia')
              }}</span>
              <input
                v-model="newLangForm.flag"
                placeholder="🇫🇷"
                class="w-full rounded-md border border-muted-300 bg-white px-2 py-1.5 text-sm dark:border-muted-600 dark:bg-muted-800"
              />
            </label>
          </div>
          <div class="mt-5 flex justify-end gap-2">
            <button
              class="rounded-lg border border-muted-200 dark:border-muted-700 px-4 py-2 text-sm text-muted-600 dark:text-muted-300 hover:bg-muted-50 dark:hover:bg-muted-800 transition-colors"
              @click="isAddLangOpen = false"
            >
              {{ t('Cancel') }}
            </button>
            <button
              :disabled="addLangSaving"
              class="inline-flex items-center gap-2 rounded-lg bg-primary-500 px-4 py-2 text-sm font-medium text-white hover:bg-primary-600 disabled:opacity-50 transition-colors"
              @click="addLanguage"
            >
              <Icon
                :name="addLangSaving ? 'ph:spinner' : 'ph:plus'"
                class="h-4 w-4"
                :class="{ 'animate-spin': addLangSaving }"
              />
              {{ t('Add') }}
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <!-- ── Tab header + controls ───────────────────────────────────────── -->
    <div class="flex items-center justify-between">
      <div class="Tab_header flex items-center gap-3">
        <img
          v-if="currentLang?.icon"
          :src="languageIconSrc(currentLang)"
          :alt="currentLang.label"
          class="h-9 w-9 rounded-full object-cover"
          @error="tryNextLanguageIconExtension(currentLang)"
        />
        <span v-else class="text-3xl leading-none">{{
          currentLang?.flag
        }}</span>
        <div>
          <h2 class="font-bold text-muted-900 dark:text-white">
            {{ currentLang?.label }}
          </h2>
          <p class="text-xs text-muted-400">{{ enCount }} {{ t('words') }}</p>
        </div>
        <!-- Active/Inactive toggle (not for EN) -->
        <button
          v-if="activeTab !== 'en'"
          class="flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-xs font-medium transition-colors"
          :class="
            isLangActive(activeTab)
              ? 'border-success-400 bg-success-50 text-success-700 hover:bg-success-100 dark:bg-success-900/20 dark:text-success-300 dark:border-success-700'
              : 'border-muted-300 bg-muted-50 text-muted-500 hover:bg-muted-100 dark:bg-muted-800 dark:border-muted-600'
          "
          :disabled="configSaving"
          @click="toggleActive(activeTab)"
        >
          <Icon
            :name="isLangActive(activeTab) ? 'ph:eye' : 'ph:eye-slash'"
            class="h-3.5 w-3.5"
          />
          {{ isLangActive(activeTab) ? t('Active') : t('Inactive') }}
        </button>
      </div>

      <div class="Save flex items-center gap-2">
        <!-- Save button -->
        <button
          v-if="currentDirtyCount"
          :disabled="saving"
          class="inline-flex items-center gap-2 rounded-lg bg-primary-500 px-4 py-2 text-sm font-semibold text-white hover:bg-primary-600 disabled:opacity-50 transition-colors"
          @click="saveCurrentTab"
        >
          <Icon
            :name="saving ? 'ph:spinner' : 'ph:floppy-disk'"
            class="h-4 w-4"
            :class="{ 'animate-spin': saving }"
          />
          {{ saving ? t('Saving...') : `${currentDirtyCount} ${t('changes')}` }}
        </button>
        <!-- Add -->
        <button
          class="inline-flex items-center gap-2 rounded-lg border border-primary-500 px-4 py-2 text-sm font-medium text-primary-500 hover:bg-primary-50 dark:hover:bg-primary-900/20 transition-colors"
          @click="isAddOpen = true"
        >
          <Icon name="ph:plus" class="h-4 w-4" />
          {{ t('Add') }}
        </button>
      </div>
    </div>

    <!-- ── EN read-only notice ─────────────────────────────────────────── -->
    <div
      v-if="activeTab === 'en'"
      class="flex items-center gap-2 rounded-lg border border-info-200 bg-info-50 dark:bg-info-900/20 dark:border-info-700 px-4 py-2 text-xs text-info-700 dark:text-info-300"
    >
      <Icon name="ph:info" class="h-4 w-4 shrink-0" />
      {{ t('English is the base key — use the Add button to add new words') }}
    </div>

    <!-- ── Search ──────────────────────────────────────────────────────── -->
    <div class="Search flex items-center gap-3">
      <div class="relative flex-1">
        <Icon
          name="ph:magnifying-glass"
          class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-400"
        />
        <input
          v-model="search"
          type="text"
          :placeholder="t('Search key or translation...')"
          class="w-full rounded-lg border border-muted-300 dark:border-muted-600 bg-white dark:bg-muted-800 pl-9 pr-3 py-2 text-sm text-muted-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
        />
      </div>
      <span class="whitespace-nowrap text-xs text-muted-400"
        >{{ filtered.length }} {{ t('results') }}</span
      >
    </div>

    <!-- ── Unsaved banner ──────────────────────────────────────────────── -->
    <div
      v-if="currentDirtyCount"
      class="flex items-center gap-3 rounded-lg border border-warning-300 dark:border-warning-700 bg-warning-50 dark:bg-warning-900/20 px-4 py-2 text-sm text-warning-800 dark:text-warning-300"
    >
      <Icon name="ph:pencil-simple" class="h-4 w-4 shrink-0" />
      <span
        ><strong>{{ currentDirtyCount }}</strong>
        {{ t('unsaved changes — click "Save" button above') }}</span
      >
    </div>

    <!-- ── Table ───────────────────────────────────────────────────────── -->
    <div
      class="overflow-hidden rounded-xl border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900"
    >
      <!-- Loading -->
      <div
        v-if="loading"
        class="flex items-center justify-center py-16 text-muted-400"
      >
        <Icon name="ph:spinner" class="mr-2 h-6 w-6 animate-spin" />
        {{ t('Loading...') }}
      </div>

      <table v-else class="w-full text-sm">
        <thead
          class="border-b border-muted-200 dark:border-muted-700 bg-muted-50 dark:bg-muted-800"
        >
          <tr>
            <th
              class="w-8 px-3 py-3 text-left text-xs font-medium uppercase tracking-wider text-muted-400"
            >
              #
            </th>
            <th
              class="w-2/5 px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-muted-500"
            >
              {{ t('Key (EN)') }}
            </th>
            <th
              class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wider text-muted-500"
            >
              {{ currentLang?.flag }} {{ currentLang?.label }}
            </th>
            <th
              class="w-20 px-3 py-3 text-center text-xs font-medium uppercase tracking-wider text-muted-500"
            >
              {{ t('Actions') }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-muted-100 dark:divide-muted-800">
          <tr
            v-for="(entry, idx) in paginated"
            :key="entry.key"
            class="group transition-colors hover:bg-muted-50/60 dark:hover:bg-muted-800/40"
            :class="{
              'bg-warning-50/40 dark:bg-warning-900/10': entry.isDirty,
            }"
          >
            <!-- Row # -->
            <td class="px-3 py-2.5 text-xs text-muted-400">
              {{ (page - 1) * perPage + idx + 1 }}
            </td>

            <!-- Key (EN) -->
            <td class="px-4 py-2.5">
              <span
                class="break-words font-mono text-xs text-muted-700 dark:text-muted-300"
                >{{ entry.en }}</span
              >
              <span
                v-if="entry.isDirty"
                class="ml-1.5 inline-block h-1.5 w-1.5 rounded-full bg-warning-400 align-middle"
              />
            </td>

            <!-- Translation value -->
            <td class="px-4 py-2.5">
              <!-- Edit mode -->
              <div
                v-if="editingKey === entry.key"
                class="flex items-center gap-2"
              >
                <input
                  v-model="editingVal"
                  type="text"
                  autofocus
                  class="flex-1 rounded-lg border border-primary-400 bg-white dark:bg-muted-800 px-2 py-1 text-sm text-muted-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-primary-500"
                  @keyup.enter="commitEdit"
                  @keyup.escape="cancelEdit"
                />
                <button
                  class="rounded-md bg-primary-500 px-2 py-1 text-xs text-white hover:bg-primary-600"
                  @click="commitEdit"
                >
                  ✓
                </button>
                <button
                  class="rounded-md bg-muted-200 dark:bg-muted-700 px-2 py-1 text-xs text-muted-600 dark:text-muted-300"
                  @click="cancelEdit"
                >
                  ✕
                </button>
              </div>
              <!-- View mode (EN = read-only) -->
              <span
                v-else
                class="block rounded px-1 -mx-1 transition-colors"
                :class="[
                  activeTab !== 'en'
                    ? 'cursor-pointer hover:bg-primary-50 dark:hover:bg-primary-900/20'
                    : 'cursor-default',
                  entry.isDirty
                    ? 'font-medium text-warning-700 dark:text-warning-300'
                    : 'text-muted-800 dark:text-white',
                ]"
                :title="activeTab !== 'en' ? t('Edit: ') + entry.key : ''"
                @dblclick="startEdit(entry.key)"
              >
                <template v-if="entry.current">{{ entry.current }}</template>
                <span
                  v-else
                  class="italic text-muted-300 dark:text-muted-600"
                  >{{ t('— no translation —') }}</span
                >
                <span
                  v-if="entry.isOverridden"
                  class="ml-1.5 rounded-full bg-info-100 px-1.5 py-0.5 text-[10px] font-semibold text-info-700 dark:bg-info-900/40 dark:text-info-300"
                  :title="t('Custom translation for this company')"
                  >{{ t('Custom') }}</span
                >
              </span>
            </td>

            <!-- Actions -->
            <td class="px-3 py-2.5 text-center">
              <div class="flex items-center justify-center gap-1">
                <button
                  v-if="activeTab !== 'en'"
                  class="rounded-lg p-1.5 text-muted-400 transition-colors hover:bg-primary-50 dark:hover:bg-primary-900/20 hover:text-primary-500"
                  :title="t('Edit')"
                  @click="startEdit(entry.key)"
                >
                  <Icon name="ph:pencil-simple" class="h-4 w-4" />
                </button>
                <button
                  v-if="activeTab !== 'en' && entry.isOverridden"
                  class="rounded-lg p-1.5 text-muted-400 transition-colors hover:bg-warning-50 dark:hover:bg-warning-900/20 hover:text-warning-500"
                  :title="t('Reset to default')"
                  @click="resetToDefault(entry.key)"
                >
                  <Icon name="ph:arrow-counter-clockwise" class="h-4 w-4" />
                </button>
                <button
                  class="rounded-lg p-1.5 text-muted-400 transition-colors hover:bg-danger-50 dark:hover:bg-danger-900/20 hover:text-danger-500"
                  :title="t('Delete')"
                  @click="confirmDelete(entry.key)"
                >
                  <Icon name="ph:trash" class="h-4 w-4" />
                </button>
              </div>
            </td>
          </tr>

          <!-- Empty -->
          <tr v-if="!paginated.length">
            <td colspan="4" class="py-12 text-center text-sm text-muted-400">
              <Icon
                name="ph:translate"
                class="mx-auto mb-2 h-8 w-8 text-muted-300"
              />
              <p>{{ t('No results found') }}</p>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- Pagination -->
      <div
        v-if="!loading && totalPages > 1"
        class="flex items-center justify-between border-t border-muted-100 dark:border-muted-800 px-4 py-3"
      >
        <span class="text-xs text-muted-400">
          {{ (page - 1) * perPage + 1 }}–{{
            Math.min(page * perPage, filtered.length)
          }}
          / {{ filtered.length }}
        </span>
        <div class="flex items-center gap-1">
          <button
            :disabled="page === 1"
            class="rounded-lg p-1.5 text-muted-500 hover:bg-muted-100 dark:hover:bg-muted-800 disabled:opacity-30 transition-colors"
            @click="page--"
          >
            <Icon name="ph:caret-left" class="h-4 w-4" />
          </button>
          <template v-for="p in totalPages" :key="p">
            <button
              v-if="p === 1 || p === totalPages || Math.abs(p - page) <= 2"
              :class="[
                'min-w-[2rem] rounded-lg px-2 py-1 text-xs font-medium transition-colors',
                p === page
                  ? 'bg-primary-500 text-white'
                  : 'text-muted-500 hover:bg-muted-100 dark:hover:bg-muted-800',
              ]"
              @click="page = p"
            >
              {{ p }}
            </button>
            <span
              v-else-if="Math.abs(p - page) === 3"
              class="px-1 text-xs text-muted-300"
              >…</span
            >
          </template>
          <button
            :disabled="page === totalPages"
            class="rounded-lg p-1.5 text-muted-500 hover:bg-muted-100 dark:hover:bg-muted-800 disabled:opacity-30 transition-colors"
            @click="page++"
          >
            <Icon name="ph:caret-right" class="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- ── Add modal ───────────────────────────────────────────────────── -->
    <AddModalForm
      :is-open="isAddOpen"
      :existing-keys="enKeys"
      :langs="languages"
      :active-tab="activeTab"
      @close="isAddOpen = false"
      @save="onAdd"
    />

    <!-- ── Delete confirm ──────────────────────────────────────────────── -->
    <Transition
      enter-active-class="transition duration-150 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-100 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="deleteKey"
        class="fixed inset-0 z-[9999] flex items-center justify-center p-4"
      >
        <div
          class="absolute inset-0 bg-muted-900/60 backdrop-blur-sm"
          @click="deleteKey = null"
        />
        <div
          class="relative z-10 w-[420px] max-w-full rounded-xl bg-white dark:bg-muted-900 shadow-2xl p-6"
        >
          <div class="mb-4 flex items-center gap-3">
            <div
              class="flex h-10 w-10 items-center justify-center rounded-full bg-danger-100 dark:bg-danger-900/30"
            >
              <Icon name="ph:trash" class="h-5 w-5 text-danger-500" />
            </div>
            <div>
              <p class="font-semibold text-muted-900 dark:text-white">
                {{ t('Delete?') }}
              </p>
              <p class="mt-0.5 text-xs text-muted-500">
                {{ t('Cannot be undone') }}
              </p>
            </div>
          </div>
          <p
            class="mb-5 rounded-lg bg-muted-50 dark:bg-muted-800 px-3 py-2 font-mono text-xs text-muted-700 dark:text-muted-300 break-words"
          >
            {{ deleteKey }}
          </p>
          <div class="flex justify-end gap-2">
            <button
              class="rounded-lg border border-muted-200 dark:border-muted-700 px-4 py-2 text-sm text-muted-600 dark:text-muted-300 hover:bg-muted-50 dark:hover:bg-muted-800 transition-colors"
              @click="deleteKey = null"
            >
              {{ t('Cancel') }}
            </button>
            <button
              class="rounded-lg bg-danger-500 px-4 py-2 text-sm font-medium text-white hover:bg-danger-600 transition-colors"
              @click="doDelete"
            >
              {{ t('Delete') }}
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>
