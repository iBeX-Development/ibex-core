<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
const { getItems, createItems, updateItem, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()

definePageMeta({
  middleware: ['auth'],
  title: 'Monitoring Bulk Apply',
  showback: true,
})

// ─── Types ────────────────────────────────────────────────────────────────
interface SharedField {
  field_key: string
  field_name_mn: string
  field_name_en: string
  unit?: string
}

interface FormatOption {
  code: string
  format_name: string
  fields: SharedField[]
}

interface AssetRow {
  id: string | number
  name: string
  asset_code?: string | null
  device_format_code?: string | null
}

interface AlertRule {
  field_key: string
  field_name: string
  condition: string
  threshold_type: string
  custom_value: number | null
  notify_popup: boolean
  notify_sound: boolean
  notify_browser: boolean
  notify_email: boolean
  email_address: string | null
  alert_message: string | null
  cooldown_minutes: number
  is_active: boolean
}

// ─── Options ───────────────────────────────────────────────────────────────
const conditionOptions = [
  { value: '>=', label: '>= (Их эсвэл тэнцүү)' },
  { value: '<=', label: '<= (Бага эсвэл тэнцүү)' },
]

const thresholdTypeOptions = computed(() => [
  { value: 'value1', label: 'Value 1' },
  { value: 'value2', label: 'Value 2' },
  { value: 'value3', label: 'Value 3' },
  { value: 'value4', label: 'Value 4' },
  // { value: 'custom', label: t('Enter manually') },
])

// ─── State ────────────────────────────────────────────────────────────────
const formats = ref<FormatOption[]>([])
const selectedFormatCode = ref<string>('')
const assets = ref<AssetRow[]>([])
const selectedAssetIds = ref<Set<string | number>>(new Set())
const assetSearch = ref('')
const loadingFormats = ref(false)
const loadingAssets = ref(false)
const applying = ref(false)
const activeTab = ref<'settings' | 'alerts'>('settings')

// Apply options
const applySettings = ref(true)
const applyAlerts = ref(true)
const replaceExistingAlerts = ref(true)

// Settings values keyed by field_key
const settingsValues = ref<
  Record<
    string,
    {
      value1: number | undefined
      value2: number | undefined
      value3: number | undefined
      value4: number | undefined
    }
  >
>({})

// Alert rules
const alertRules = ref<AlertRule[]>([])

// Progress
const progressDone = ref(0)
const progressTotal = ref(0)

// ─── Computed ────────────────────────────────────────────────────────────
const selectedFormat = computed(
  () => formats.value.find((f) => f.code === selectedFormatCode.value) ?? null,
)

const sharedFields = computed<SharedField[]>(
  () => selectedFormat.value?.fields ?? [],
)

const filteredAssets = computed(() => {
  const q = assetSearch.value.trim().toLowerCase()
  if (!q) return assets.value
  return assets.value.filter(
    (a) =>
      (a.asset_code || '').toLowerCase().includes(q) ||
      (a.name || '').toLowerCase().includes(q),
  )
})

const allFilteredSelected = computed(
  () =>
    filteredAssets.value.length > 0 &&
    filteredAssets.value.every((a) => selectedAssetIds.value.has(a.id)),
)

const selectedCount = computed(() => selectedAssetIds.value.size)

const canApply = computed(
  () =>
    selectedCount.value > 0 &&
    (applySettings.value || applyAlerts.value) &&
    !applying.value,
)

// ─── Load formats ───────────────────────────────────────────────────────────
const loadFormats = async () => {
  loadingFormats.value = true
  try {
    const res = await getItems<any>({
      collection: 'Device_tracking_fields',
      params: {
        filter: { is_shared_format: { _eq: true }, company_id: myCompanyId },
        fields: [
          'code',
          'format_name',
          'field_key',
          'field_name_mn',
          'field_name_en',
          'unit',
          'sort_order',
        ],
        sort: ['code', 'sort_order'],
        limit: -1,
      },
    })
    const rows: any[] = Array.isArray(res) ? res : (res as any)?.data ?? []
    const map = new Map<string, FormatOption>()
    for (const row of rows) {
      if (!row.code) continue
      if (!map.has(row.code)) {
        map.set(row.code, {
          code: row.code,
          format_name: row.format_name || row.code,
          fields: [],
        })
      }
      if (row.field_key) {
        map.get(row.code)!.fields.push({
          field_key: row.field_key,
          field_name_mn: row.field_name_mn || row.field_key,
          field_name_en: row.field_name_en || row.field_key,
          unit: row.unit || '',
        })
      }
    }
    formats.value = [...map.values()]
  } catch (e: any) {
    toaster.show({
      title: t('Error'),
      message: String(e?.message || e),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  } finally {
    loadingFormats.value = false
  }
}

// ─── Load assets for the selected format ────────────────────────────────────
const loadAssets = async () => {
  if (!selectedFormatCode.value) {
    assets.value = []
    return
  }
  loadingAssets.value = true
  try {
    const res = await getItems<any>({
      collection: 'Assets',
      params: {
        filter: {
          device_format_code: { _eq: selectedFormatCode.value },
          company_id: myCompanyId,
        },
        fields: ['id', 'name', 'asset_code', 'device_format_code'],
        sort: ['asset_code'],
        limit: -1,
      },
    })
    assets.value = Array.isArray(res) ? res : (res as any)?.data ?? []
  } catch (e: any) {
    toaster.show({
      title: t('Error'),
      message: String(e?.message || e),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  } finally {
    loadingAssets.value = false
  }
}

// ─── Format change ──────────────────────────────────────────────────────────
const onFormatChange = async () => {
  selectedAssetIds.value = new Set()
  alertRules.value = []
  settingsValues.value = {}
  // Initialise settings values for each shared field
  for (const f of sharedFields.value) {
    settingsValues.value[f.field_key] = {
      value1: undefined,
      value2: undefined,
      value3: undefined,
      value4: undefined,
    }
  }
  await loadAssets()
}

// ─── Asset selection ────────────────────────────────────────────────────────
const toggleAsset = (id: string | number) => {
  const s = new Set(selectedAssetIds.value)
  if (s.has(id)) s.delete(id)
  else s.add(id)
  selectedAssetIds.value = s
}

const toggleAllFiltered = () => {
  const s = new Set(selectedAssetIds.value)
  if (allFilteredSelected.value) {
    filteredAssets.value.forEach((a) => s.delete(a.id))
  } else {
    filteredAssets.value.forEach((a) => s.add(a.id))
  }
  selectedAssetIds.value = s
}

// ─── Alert rules ────────────────────────────────────────────────────────────
const addAlertRule = () => {
  const first = sharedFields.value[0]
  alertRules.value.push({
    field_key: first?.field_key ?? '',
    field_name: first?.field_name_mn ?? '',
    condition: '>',
    threshold_type: 'value1',
    custom_value: null,
    notify_popup: true,
    notify_sound: false,
    notify_browser: false,
    notify_email: false,
    email_address: null,
    alert_message: null,
    cooldown_minutes: 30,
    is_active: true,
  })
}

const removeAlertRule = (idx: number) => {
  alertRules.value.splice(idx, 1)
}

const onRuleFieldChange = (rule: AlertRule) => {
  const f = sharedFields.value.find((x) => x.field_key === rule.field_key)
  if (f) rule.field_name = f.field_name_mn
}

// ─── Apply ──────────────────────────────────────────────────────────────────
const applyToAssets = async () => {
  if (!canApply.value) return

  if (
    !confirm(
      t('Apply settings to the {n} selected assets?').replace(
        '{n}',
        String(selectedCount.value),
      ),
    )
  )
    return

  applying.value = true
  progressDone.value = 0
  progressTotal.value = selectedCount.value

  const ids = [...selectedAssetIds.value]
  let okCount = 0
  const errors: string[] = []

  for (const assetId of ids) {
    try {
      // ── Settings (Device_tracking_fields value1-4) ──
      if (applySettings.value) {
        // Load existing per-asset tracking records
        const existRes = await getItems<any>({
          collection: 'Device_tracking_fields',
          params: {
            filter: {
              code: { _eq: selectedFormatCode.value },
              asset: { _eq: assetId },
              is_shared_format: { _eq: false },
              company_id: myCompanyId,
            },
            fields: ['id', 'field_key'],
            limit: -1,
          },
        })
        const existList = Array.isArray(existRes)
          ? existRes
          : (existRes as any)?.data ?? []
        const existMap = new Map<string, string | number>()
        existList.forEach((r: any) => {
          if (r.field_key) existMap.set(String(r.field_key), r.id)
        })

        for (const f of sharedFields.value) {
          const vals = settingsValues.value[f.field_key]
          if (!vals) continue
          // Skip fields where all values are empty
          const allEmpty =
            vals.value1 === undefined &&
            vals.value2 === undefined &&
            vals.value3 === undefined &&
            vals.value4 === undefined
          if (allEmpty) continue

          const payload = {
            value1: vals.value1 ?? null,
            value2: vals.value2 ?? null,
            value3: vals.value3 ?? null,
            value4: vals.value4 ?? null,
          }
          const existingId = existMap.get(f.field_key)
          if (existingId) {
            await updateItem({
              collection: 'Device_tracking_fields',
              id: String(existingId),
              item: payload,
            })
          } else {
            await createItems({
              collection: 'Device_tracking_fields',
              items: [
                {
                  asset: parseInt(String(assetId)),
                  code: selectedFormatCode.value,
                  field_key: f.field_key,
                  field_name_mn: f.field_name_mn,
                  field_name_en: f.field_name_en,
                  unit: f.unit,
                  is_shared_format: false,
                  ...payload,
                  company_id: myCompanyId,
                },
              ],
            })
          }
        }
      }

      // ── Alerts (Monitoring_alerts) ──
      if (applyAlerts.value && alertRules.value.length) {
        if (replaceExistingAlerts.value) {
          const oldRes = await getItems<any>({
            collection: 'Monitoring_alerts',
            params: {
              filter: { asset: { _eq: assetId }, company_id: myCompanyId },
              fields: ['id'],
              limit: -1,
            },
          })
          const oldList = Array.isArray(oldRes)
            ? oldRes
            : (oldRes as any)?.data ?? []
          const oldIds = oldList.map((r: any) => r.id)
          if (oldIds.length) {
            await deleteItems({
              collection: 'Monitoring_alerts',
              items: oldIds,
            })
          }
        }

        const items = alertRules.value.map((rule) => ({
          asset: parseInt(String(assetId)),
          field_key: rule.field_key,
          field_name: rule.field_name || rule.field_key,
          condition: rule.condition,
          threshold_type: rule.threshold_type,
          custom_value:
            rule.threshold_type === 'custom' ? rule.custom_value ?? null : null,
          notify_popup: rule.notify_popup ? 1 : 0,
          notify_sound: rule.notify_sound ? 1 : 0,
          notify_browser: rule.notify_browser ? 1 : 0,
          notify_email: rule.notify_email ? 1 : 0,
          email_address: rule.notify_email ? rule.email_address : null,
          alert_message: rule.alert_message || null,
          cooldown_minutes: rule.cooldown_minutes || 30,
          is_active: rule.is_active ? 1 : 0,
          company_id: myCompanyId,
        }))

        if (items.length) {
          await createItems({ collection: 'Monitoring_alerts', items })
        }
      }

      okCount++
    } catch (e: any) {
      errors.push(`#${assetId}: ${String(e?.message || e)}`)
    } finally {
      progressDone.value++
    }
  }

  applying.value = false

  if (errors.length) {
    toaster.show({
      title: t('Finished (with errors)'),
      message: `${okCount}/${ids.length} ${t('succeeded')}. ${
        errors.length
      } ${t('errors')}`,
      color: 'warning',
      icon: 'ph:warning',
      closable: true,
    })
    console.error('Bulk apply errors:', errors)
  } else {
    toaster.show({
      title: t('Success'),
      message: `${okCount} ${t('assets configured')}`,
      color: 'success',
      icon: 'ph:check',
      closable: true,
    })
  }
}

onMounted(() => loadFormats())
</script>

<template>
  <div>
    <TairoContentWrapper>
      <template #left>
        <BaseHeading
          as="h2"
          size="md"
          weight="semibold"
          class="text-muted-800 dark:text-white"
        >
          {{ t('Apply to multiple assets') }}
        </BaseHeading>
        <BaseParagraph size="sm" class="text-muted-400 mt-1">
          {{
            t('Apply the same alerts and settings to multiple assets at once')
          }}
        </BaseParagraph>
      </template>
    </TairoContentWrapper>

    <div class="mt-4 grid grid-cols-1 lg:grid-cols-3 gap-4">
      <!-- ── Left: format + assets ─────────────────────────────────── -->
      <div class="lg:col-span-1 space-y-4">
        <!-- Format selector -->
        <BaseCard class="p-4">
          <label class="block text-xs font-medium text-muted-500 mb-1">{{
            t('Device format')
          }}</label>
          <select
            v-model="selectedFormatCode"
            class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-3 py-2 text-sm text-muted-700 dark:text-muted-200 focus:ring-2 focus:ring-primary-500"
            :disabled="loadingFormats"
            @change="onFormatChange"
          >
            <option value="" disabled>
              {{ loadingFormats ? t('Loading...') : t('Select a format') }}
            </option>
            <option v-for="fmt in formats" :key="fmt.code" :value="fmt.code">
              {{ fmt.format_name }} ({{ fmt.code }}) — {{ fmt.fields.length }}
              {{ t('field') }}
            </option>
          </select>
        </BaseCard>

        <!-- Asset multi-select -->
        <BaseCard v-if="selectedFormatCode" class="p-4">
          <div class="flex items-center justify-between mb-2">
            <label class="text-xs font-medium text-muted-500">{{
              t('Assets')
            }}</label>
            <span class="text-xs text-primary-500 font-medium"
              >{{ selectedCount }} {{ t('selected') }}</span
            >
          </div>

          <BaseInput
            v-model="assetSearch"
            icon="ph:magnifying-glass"
            :placeholder="t('Search...')"
            size="sm"
            class="mb-2"
          />

          <div v-if="loadingAssets" class="flex justify-center py-6">
            <BaseButtonIcon loading shape="full" size="sm" />
          </div>

          <template v-else>
            <div
              v-if="filteredAssets.length"
              class="flex items-center gap-2 px-2 py-1.5 border-b border-muted-100 dark:border-muted-800 mb-1"
            >
              <input
                type="checkbox"
                :checked="allFilteredSelected"
                class="rounded border-muted-300 text-primary-500 focus:ring-primary-500"
                @change="toggleAllFiltered"
              />
              <span class="text-xs text-muted-500">{{ t('Select all') }}</span>
            </div>

            <div class="max-h-80 overflow-y-auto space-y-0.5">
              <label
                v-for="a in filteredAssets"
                :key="a.id"
                class="flex items-center gap-2 px-2 py-1.5 rounded hover:bg-muted-50 dark:hover:bg-muted-800/50 cursor-pointer"
              >
                <input
                  type="checkbox"
                  :checked="selectedAssetIds.has(a.id)"
                  class="rounded border-muted-300 text-primary-500 focus:ring-primary-500"
                  @change="toggleAsset(a.id)"
                />
                <div class="min-w-0">
                  <span
                    class="text-sm font-medium text-muted-700 dark:text-muted-200"
                    >{{ a.asset_code || `#${a.id}` }}</span
                  >
                  <span class="ml-1 text-xs text-muted-400">{{ a.name }}</span>
                </div>
              </label>
            </div>

            <BaseParagraph
              v-if="!filteredAssets.length"
              size="xs"
              class="text-muted-400 text-center py-4"
            >
              {{ t('No assets with this format') }}
            </BaseParagraph>
          </template>
        </BaseCard>
      </div>

      <!-- ── Right: config ─────────────────────────────────────────── -->
      <div class="lg:col-span-2 space-y-4">
        <BaseCard v-if="selectedFormatCode" class="p-4">
          <!-- Tabs -->
          <div
            class="flex items-center gap-1 border-b border-muted-200 dark:border-muted-700 mb-4"
          >
            <button
              class="px-4 py-2 text-sm font-medium -mb-px border-b-2 transition-colors"
              :class="
                activeTab === 'settings'
                  ? 'border-primary-500 text-primary-500'
                  : 'border-transparent text-muted-400 hover:text-muted-600'
              "
              @click="activeTab = 'settings'"
            >
              <Icon name="ph:sliders" class="h-4 w-4 inline mr-1" />
              {{ t('Threshold values') }}
            </button>
            <button
              class="px-4 py-2 text-sm font-medium -mb-px border-b-2 transition-colors"
              :class="
                activeTab === 'alerts'
                  ? 'border-primary-500 text-primary-500'
                  : 'border-transparent text-muted-400 hover:text-muted-600'
              "
              @click="activeTab = 'alerts'"
            >
              <Icon name="ph:bell-ringing" class="h-4 w-4 inline mr-1" />
              {{ t('Alerts') }} ({{ alertRules.length }})
            </button>
          </div>

          <!-- Settings tab -->
          <div v-show="activeTab === 'settings'">
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead>
                  <tr
                    class="border-b border-muted-200 dark:border-muted-700 text-xs text-muted-500 uppercase"
                  >
                    <th class="px-2 py-2 text-left">{{ t('Field') }}</th>
                    <th class="px-2 py-2 text-left">Value 1</th>
                    <th class="px-2 py-2 text-left">Value 2</th>
                    <th class="px-2 py-2 text-left">Value 3</th>
                    <th class="px-2 py-2 text-left">Value 4</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-muted-100 dark:divide-muted-800">
                  <tr v-for="f in sharedFields" :key="f.field_key">
                    <td class="px-2 py-2">
                      <span
                        class="font-medium text-muted-700 dark:text-muted-200"
                        >{{ f.field_name_mn }}</span
                      >
                      <span v-if="f.unit" class="ml-1 text-xs text-muted-400"
                        >({{ f.unit }})</span
                      >
                    </td>
                    <td class="px-2 py-2">
                      <input
                        v-if="settingsValues[f.field_key]"
                        v-model.number="settingsValues[f.field_key].value1"
                        type="number"
                        class="w-20 rounded border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-2 py-1 text-sm"
                        placeholder="—"
                      />
                    </td>
                    <td class="px-2 py-2">
                      <input
                        v-if="settingsValues[f.field_key]"
                        v-model.number="settingsValues[f.field_key].value2"
                        type="number"
                        class="w-20 rounded border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-2 py-1 text-sm"
                        placeholder="—"
                      />
                    </td>
                    <td class="px-2 py-2">
                      <input
                        v-if="settingsValues[f.field_key]"
                        v-model.number="settingsValues[f.field_key].value3"
                        type="number"
                        class="w-20 rounded border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-2 py-1 text-sm"
                        placeholder="—"
                      />
                    </td>
                    <td class="px-2 py-2">
                      <input
                        v-if="settingsValues[f.field_key]"
                        v-model.number="settingsValues[f.field_key].value4"
                        type="number"
                        class="w-20 rounded border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-2 py-1 text-sm"
                        placeholder="—"
                      />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
            <BaseParagraph size="xs" class="text-muted-400 mt-2">
              {{
                t(
                  'Empty fields are skipped. Only fields with values are updated.',
                )
              }}
            </BaseParagraph>
          </div>

          <!-- Alerts tab -->
          <div v-show="activeTab === 'alerts'">
            <div class="flex justify-end mb-3">
              <BaseButton size="sm" color="primary" @click="addAlertRule">
                <Icon name="ph:plus" class="h-4 w-4 mr-1" />
                {{ t('Add alert') }}
              </BaseButton>
            </div>

            <div
              v-if="!alertRules.length"
              class="text-center py-8 text-muted-400"
            >
              <Icon
                name="ph:bell-slash"
                class="h-10 w-10 mx-auto mb-2 text-muted-300"
              />
              <BaseParagraph size="sm">{{
                t('No alerts added')
              }}</BaseParagraph>
            </div>

            <div class="space-y-3">
              <div
                v-for="(rule, idx) in alertRules"
                :key="idx"
                class="rounded-lg border border-muted-200 dark:border-muted-700 p-3"
              >
                <div class="flex items-start justify-between gap-2">
                  <div class="flex-1 grid grid-cols-1 sm:grid-cols-3 gap-2">
                    <!-- Field -->
                    <div>
                      <label class="block text-xs text-muted-500 mb-1">{{
                        t('Field')
                      }}</label>
                      <select
                        v-model="rule.field_key"
                        class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-2 py-1.5 text-sm"
                        @change="onRuleFieldChange(rule)"
                      >
                        <option
                          v-for="f in sharedFields"
                          :key="f.field_key"
                          :value="f.field_key"
                        >
                          {{ f.field_name_mn }} ({{ f.field_key }})
                        </option>
                      </select>
                    </div>

                    <!-- Condition -->
                    <div>
                      <label class="block text-xs text-muted-500 mb-1">{{
                        t('Condition')
                      }}</label>
                      <select
                        v-model="rule.condition"
                        class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-2 py-1.5 text-sm"
                      >
                        <option
                          v-for="opt in conditionOptions"
                          :key="opt.value"
                          :value="opt.value"
                        >
                          {{ opt.label }}
                        </option>
                      </select>
                    </div>

                    <!-- Threshold type -->
                    <div>
                      <label class="block text-xs text-muted-500 mb-1">{{
                        t('Threshold value')
                      }}</label>
                      <select
                        v-model="rule.threshold_type"
                        class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-2 py-1.5 text-sm"
                      >
                        <option
                          v-for="opt in thresholdTypeOptions"
                          :key="opt.value"
                          :value="opt.value"
                        >
                          {{ opt.label }}
                        </option>
                      </select>
                    </div>

                    <!-- Custom value -->
                    <div v-if="rule.threshold_type === 'custom'">
                      <label class="block text-xs text-muted-500 mb-1">{{
                        t('Numeric value')
                      }}</label>
                      <input
                        v-model.number="rule.custom_value"
                        type="number"
                        class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-2 py-1.5 text-sm"
                      />
                    </div>

                    <!-- Message -->
                    <div class="sm:col-span-3">
                      <label class="block text-xs text-muted-500 mb-1">{{
                        t('Alert message (optional)')
                      }}</label>
                      <input
                        v-model="rule.alert_message"
                        type="text"
                        class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-2 py-1.5 text-sm"
                        :placeholder="t('Leave blank to auto-generate')"
                      />
                    </div>

                    <!-- Notify types -->
                    <div class="sm:col-span-3 flex flex-wrap gap-3">
                      <label class="flex items-center gap-1.5 cursor-pointer">
                        <input
                          v-model="rule.notify_popup"
                          type="checkbox"
                          class="rounded border-muted-300 text-primary-500 focus:ring-primary-500"
                        />
                        <Icon name="ph:bell" class="h-4 w-4 text-primary-500" />
                        <span class="text-xs text-muted-600 dark:text-muted-300"
                          >popup</span
                        >
                      </label>
                      <label class="flex items-center gap-1.5 cursor-pointer">
                        <input
                          v-model="rule.notify_sound"
                          type="checkbox"
                          class="rounded border-muted-300 text-warning-500 focus:ring-warning-500"
                        />
                        <Icon
                          name="ph:speaker-high"
                          class="h-4 w-4 text-warning-500"
                        />
                        <span class="text-xs text-muted-600 dark:text-muted-300"
                          >sound</span
                        >
                      </label>
                      <label class="flex items-center gap-1.5 cursor-pointer">
                        <input
                          v-model="rule.notify_browser"
                          type="checkbox"
                          class="rounded border-muted-300 text-info-500 focus:ring-info-500"
                        />
                        <Icon
                          name="ph:bell-ringing"
                          class="h-4 w-4 text-info-500"
                        />
                        <span class="text-xs text-muted-600 dark:text-muted-300"
                          >browser</span
                        >
                      </label>
                      <label class="flex items-center gap-1.5 cursor-pointer">
                        <input
                          v-model="rule.notify_email"
                          type="checkbox"
                          class="rounded border-muted-300 text-success-500 focus:ring-success-500"
                        />
                        <Icon
                          name="ph:envelope"
                          class="h-4 w-4 text-success-500"
                        />
                        <span class="text-xs text-muted-600 dark:text-muted-300"
                          >email</span
                        >
                      </label>
                    </div>

                    <!-- Email address -->
                    <div v-if="rule.notify_email" class="sm:col-span-3">
                      <input
                        v-model="rule.email_address"
                        type="email"
                        class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-2 py-1.5 text-sm"
                        :placeholder="t('email@example.com')"
                      />
                    </div>
                  </div>

                  <BaseButtonIcon
                    size="xs"
                    color="danger"
                    @click="removeAlertRule(idx)"
                  >
                    <Icon name="ph:trash" class="h-3.5 w-3.5" />
                  </BaseButtonIcon>
                </div>
              </div>
            </div>
          </div>
        </BaseCard>

        <!-- Placeholder -->
        <BaseCard v-else class="p-10 text-center">
          <Icon
            name="ph:arrow-left"
            class="h-10 w-10 mx-auto mb-2 text-muted-300"
          />
          <BaseParagraph class="text-muted-400">{{
            t('Select a format first')
          }}</BaseParagraph>
        </BaseCard>

        <!-- Apply bar -->
        <BaseCard v-if="selectedFormatCode" class="p-4">
          <div class="flex flex-wrap items-center gap-4 mb-3">
            <label class="flex items-center gap-2 cursor-pointer">
              <input
                v-model="applySettings"
                type="checkbox"
                class="rounded border-muted-300 text-primary-500 focus:ring-primary-500"
              />
              <span class="text-sm text-muted-700 dark:text-muted-200">{{
                t('Apply threshold values')
              }}</span>
            </label>
            <label class="flex items-center gap-2 cursor-pointer">
              <input
                v-model="applyAlerts"
                type="checkbox"
                class="rounded border-muted-300 text-primary-500 focus:ring-primary-500"
              />
              <span class="text-sm text-muted-700 dark:text-muted-200">{{
                t('Apply alerts')
              }}</span>
            </label>
            <label
              v-if="applyAlerts"
              class="flex items-center gap-2 cursor-pointer"
            >
              <input
                v-model="replaceExistingAlerts"
                type="checkbox"
                class="rounded border-muted-300 text-warning-500 focus:ring-warning-500"
              />
              <span class="text-sm text-muted-700 dark:text-muted-200">{{
                t('Replace existing alerts')
              }}</span>
            </label>
          </div>

          <div
            v-if="applying"
            class="mb-3 h-2 w-full rounded-full bg-muted-100 dark:bg-muted-800 overflow-hidden"
          >
            <div
              class="h-full bg-primary-500 transition-all"
              :style="{
                width: progressTotal
                  ? `${(progressDone / progressTotal) * 100}%`
                  : '0%',
              }"
            />
          </div>

          <div class="flex items-center justify-between">
            <BaseParagraph size="sm" class="text-muted-500">
              <span v-if="applying">
                {{ progressDone }} / {{ progressTotal }}
              </span>
              <span v-else>
                {{ selectedCount }} {{ t('assets selected') }}
              </span>
            </BaseParagraph>
            <BaseButton
              color="primary"
              :disabled="!canApply"
              :loading="applying"
              @click="applyToAssets"
            >
              <Icon name="ph:check-circle" class="h-4 w-4 mr-1" />
              {{ t('Apply to all') }}
            </BaseButton>
          </div>
        </BaseCard>
      </div>
    </div>
  </div>
</template>
