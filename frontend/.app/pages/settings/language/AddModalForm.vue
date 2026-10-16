<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })

const props = defineProps<{
  isOpen: boolean
  existingKeys: string[]
  langs: { code: string; label: string; flag: string }[]
  activeTab: string
}>()

const emit = defineEmits<{
  close: []
  save: [{ key: string; translations: Record<string, string> }]
}>()

const key = ref('')
const keyError = ref('')
const translations = ref<Record<string, string>>({})

// Which languages the user selected to fill in
const selectedLangs = ref<string[]>([])

// Non-EN langs (EN is always implied as the key itself)
const otherLangs = computed(() => props.langs.filter(l => l.code !== 'en'))

const validate = () => {
  if (!key.value.trim()) {
    keyError.value = t('Please enter a key')
    return false
  }
  if (props.existingKeys.includes(key.value.trim())) {
    keyError.value = t('This key already exists')
    return false
  }
  keyError.value = ''
  return true
}

const onSave = () => {
  if (!validate()) return
  const result: Record<string, string> = { en: key.value.trim() }
  for (const lang of selectedLangs.value) {
    result[lang] = translations.value[lang] ?? ''
  }
  emit('save', { key: key.value.trim(), translations: result })
}

const toggleLang = (code: string) => {
  if (selectedLangs.value.includes(code)) {
    selectedLangs.value = selectedLangs.value.filter(c => c !== code)
  } else {
    selectedLangs.value = [...selectedLangs.value, code]
  }
}

const reset = () => {
  key.value = ''
  keyError.value = ''
  translations.value = {}
  // Default: select the active tab language (if not EN)
  selectedLangs.value = props.activeTab !== 'en' ? [props.activeTab] : []
}

watch(() => props.isOpen, (v) => { if (v) reset() })
</script>

<template>
  <Transition
    enter-active-class="transition duration-150 ease-out"
    enter-from-class="opacity-0"
    enter-to-class="opacity-100"
    leave-active-class="transition duration-100 ease-in"
    leave-from-class="opacity-100"
    leave-to-class="opacity-0"
  >
    <div v-if="isOpen" class="fixed inset-0 z-[9999] flex items-center justify-center p-4">
      <!-- Backdrop -->
      <div class="absolute inset-0 bg-muted-900/60 backdrop-blur-sm" @click="emit('close')" />

      <!-- Modal -->
      <div class="relative z-10 w-full max-w-lg rounded-xl bg-white dark:bg-muted-900 shadow-2xl">
        <!-- Header -->
        <div class="flex items-center justify-between border-b border-muted-200 dark:border-muted-700 px-5 py-4">
          <h3 class="flex items-center gap-2 font-semibold text-muted-900 dark:text-white">
            <Icon name="ph:plus-circle" class="h-4 w-4 text-primary-500" />
            {{ t('Add new translation') }}
          </h3>
          <button class="rounded-lg p-1 text-muted-400 hover:text-muted-600 dark:hover:text-muted-200 transition-colors" @click="emit('close')">
            <Icon name="ph:x" class="h-4 w-4" />
          </button>
        </div>

        <!-- Body -->
        <div class="max-h-[70vh] overflow-y-auto space-y-4 p-5">

          <!-- KEY (EN) -->
          <div>
            <label class="mb-1.5 block text-xs font-medium text-muted-700 dark:text-muted-300">
              🇺🇸 {{ t('Key (EN)') }} <span class="text-danger-500">*</span>
            </label>
            <input
              v-model="key"
              type="text"
              :placeholder="t('example: Work Order Status')"
              class="w-full rounded-lg border px-3 py-2 text-sm text-muted-900 dark:text-white bg-white dark:bg-muted-800 focus:outline-none focus:ring-2 focus:ring-primary-500 transition-colors"
              :class="keyError ? 'border-danger-400' : 'border-muted-300 dark:border-muted-600'"
              @input="keyError = ''"
              @keyup.enter="onSave"
            />
            <p v-if="keyError" class="mt-1 text-xs text-danger-500">{{ keyError }}</p>
            <p class="mt-1 text-xs text-muted-400">
              {{ t('The main word used in code — written inside') }}
              <code class="rounded bg-muted-100 dark:bg-muted-800 px-1">t('...')</code>
            </p>
          </div>

          <!-- Language selector -->
          <div>
            <label class="mb-2 block text-xs font-medium text-muted-700 dark:text-muted-300">
              {{ t('Select languages to translate') }}
            </label>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="lang in otherLangs"
                :key="lang.code"
                type="button"
                class="flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-xs font-medium transition-all"
                :class="selectedLangs.includes(lang.code)
                  ? 'border-primary-400 bg-primary-50 text-primary-700 dark:bg-primary-900/30 dark:text-primary-300 dark:border-primary-600'
                  : 'border-muted-200 dark:border-muted-700 text-muted-500 hover:border-muted-300 dark:hover:border-muted-500'"
                @click="toggleLang(lang.code)"
              >
                <span>{{ lang.flag }}</span>
                <span>{{ lang.label }}</span>
                <Icon
                  :name="selectedLangs.includes(lang.code) ? 'ph:check-circle-fill' : 'ph:circle'"
                  class="h-3.5 w-3.5"
                  :class="selectedLangs.includes(lang.code) ? 'text-primary-500' : 'text-muted-300'"
                />
              </button>
            </div>
          </div>

          <!-- Translation inputs for selected langs -->
          <div
            v-for="lang in otherLangs.filter(l => selectedLangs.includes(l.code))"
            :key="lang.code"
          >
            <label class="mb-1.5 block text-xs font-medium text-muted-700 dark:text-muted-300">
              {{ lang.flag }} {{ lang.label }}
            </label>
            <input
              v-model="translations[lang.code]"
              type="text"
              :placeholder="`${lang.label} ${t('translation')}...`"
              class="w-full rounded-lg border border-muted-300 dark:border-muted-600 px-3 py-2 text-sm text-muted-900 dark:text-white bg-white dark:bg-muted-800 focus:outline-none focus:ring-2 focus:ring-primary-500"
              @keyup.enter="onSave"
            />
          </div>

          <!-- Preview -->
          <div
            v-if="key || Object.values(translations).some(v => v)"
            class="rounded-lg border border-muted-200 dark:border-muted-700 bg-muted-50 dark:bg-muted-800 p-3 text-xs"
          >
            <p class="mb-2 text-muted-500">{{ t('Preview:') }}</p>
            <div class="flex items-start gap-2">
              <span class="rounded bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 px-1.5 py-0.5 font-mono">EN</span>
              <span class="break-words text-muted-800 dark:text-white">{{ key || '—' }}</span>
            </div>
            <div
              v-for="lang in otherLangs.filter(l => selectedLangs.includes(l.code) && translations[l.code])"
              :key="lang.code"
              class="mt-1 flex items-start gap-2"
            >
              <span class="rounded bg-success-100 dark:bg-success-900/30 text-success-700 dark:text-success-300 px-1.5 py-0.5 font-mono uppercase">{{ lang.code }}</span>
              <span class="break-words text-muted-800 dark:text-white">{{ translations[lang.code] }}</span>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="flex items-center justify-end gap-2 border-t border-muted-200 dark:border-muted-700 px-5 py-4">
          <button
            class="rounded-lg border border-muted-200 dark:border-muted-700 px-4 py-2 text-sm text-muted-600 dark:text-muted-300 hover:bg-muted-50 dark:hover:bg-muted-800 transition-colors"
            @click="emit('close')"
          >
            {{ t('Cancel') }}
          </button>
          <button
            class="inline-flex items-center gap-2 rounded-lg bg-primary-500 px-4 py-2 text-sm font-medium text-white hover:bg-primary-600 transition-colors"
            @click="onSave"
          >
            <Icon name="ph:floppy-disk" class="h-4 w-4" />
            {{ t('Save') }}
          </button>
        </div>
      </div>
    </div>
  </Transition>
</template>
