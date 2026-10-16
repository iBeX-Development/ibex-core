<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { AgGridVue } from 'ag-grid-vue3'
import { onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import ModalAssetsList from '~/components/workorder/ModalAssetsList.vue'

ModuleRegistry.registerModules([ClientSideRowModelModule])

const { t } = useI18n({ useScope: 'global' })
const { getItems, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()

const props = defineProps<{
  work_order: Record<string, any> | null
  location: number | null
  openForm?: boolean
}>()

const emit = defineEmits<{
  (e: 'close'): void
}>()

// ---- Types ----
type TriggerMode = 'interval' | 'threshold'

interface ConfigRow {
  id: number
  assetId: number | null
  assetName: string
  pmName: string
  trackingFieldId: number | null
  trackingFieldName: string
  triggerMode: TriggerMode // 'interval' = Тоолууртай, 'threshold' = тоолуургүй
  intervalValue: string // interval mode: e.g. 5000
  intervalStartValue: string // interval mode: starting value e.g. 120000
  thresholdValueKey: string // threshold mode: 'value1'…'value5' preset key
  thresholdStartDate: string // threshold mode: generation start date
  thresholdValue: string | number | null
  trackingFields: any[]
  loadingFields: boolean
}

// ---- State ----
const configs = ref<any[]>([])
const loadingConfigs = ref(false)
const isFormOpen = ref(false)
const submitting = ref(false)

const configRows = ref<ConfigRow[]>([])
let nextRowId = 1

const isModalAssetOpen = ref(false)
const selectedRowId = ref<number | null>(null)

const valueKeys = [
  { key: 'value1', label: 'Value 1' },
  { key: 'value2', label: 'Value 2' },
  { key: 'value3', label: 'Value 3' },
  { key: 'value4', label: 'Value 4' },
]

// ---- Row helpers ----
function makeRow(): ConfigRow {
  return {
    id: nextRowId++,
    assetId: null,
    assetName: '',
    pmName: '',
    trackingFieldId: null,
    trackingFieldName: '',
    triggerMode: 'interval',
    intervalValue: '',
    intervalStartValue: '',
    thresholdValueKey: '',
    thresholdStartDate: '',
    thresholdValue: null,
    trackingFields: [],
    loadingFields: false,
  }
}

function addConfigRow() {
  configRows.value.push(makeRow())
}

function removeConfigRow(rowId: number) {
  configRows.value = configRows.value.filter((r) => r.id !== rowId)
}

function getRow(rowId: number): ConfigRow | undefined {
  return configRows.value.find((r) => r.id === rowId)
}

function getAvailableValueKeysForRow(rowId: number) {
  const row = getRow(rowId)
  if (!row || !row.trackingFieldId) return []
  const field = row.trackingFields.find((f) => f.id === row.trackingFieldId)
  if (!field) return []
  return valueKeys.filter(
    (vk) =>
      field[vk.key] !== null &&
      field[vk.key] !== undefined &&
      field[vk.key] !== 0,
  )
}

function getThresholdPreview(rowId: number) {
  const row = getRow(rowId)
  if (!row || !row.trackingFieldId || !row.thresholdValueKey) return null
  const field = row.trackingFields.find((f) => f.id === row.trackingFieldId)
  if (!field) return null
  return field[row.thresholdValueKey]
}

function getFieldUnit(rowId: number) {
  const row = getRow(rowId)
  if (!row || !row.trackingFieldId) return ''
  const field = row.trackingFields.find((f) => f.id === row.trackingFieldId)
  return field?.unit || ''
}

function getFieldValueForKey(rowId: number, valueKey: string) {
  const row = getRow(rowId)
  if (!row || !row.trackingFieldId) return null
  const field = row.trackingFields.find((f) => f.id === row.trackingFieldId)
  return field ? field[valueKey] : null
}

// ---- Template event handlers (no TS casting needed) ----
function openAssetPicker(rowId: number) {
  selectedRowId.value = rowId
  isModalAssetOpen.value = true
}

function handleAssetSelected(asset: any) {
  const row = getRow(selectedRowId.value!)
  if (!row) return
  const prevAssetName = row.assetName
  row.assetId = asset.id
  row.assetName = asset.name
  if (!row.pmName || row.pmName === prevAssetName) row.pmName = asset.name
  isModalAssetOpen.value = false
  selectedRowId.value = null
  loadTrackingFieldsForRow(row.id, asset.id)
}

function onFieldChange(rowId: number, e: Event) {
  const val = (e.target as HTMLSelectElement).value
  const row = getRow(rowId)
  if (!row) return
  row.trackingFieldId = val ? Number(val) : null
  row.thresholdValueKey = ''
  row.thresholdValue = null
  const field = row.trackingFields.find((f) => String(f.id) === val)
  row.trackingFieldName = field ? field.field_name_mn || field.field_key : ''
}

function onThresholdChange(rowId: number, e: Event) {
  const val = (e.target as HTMLSelectElement).value
  const row = getRow(rowId)
  if (!row) return
  row.thresholdValueKey = val
  const field = row.trackingFields.find((f) => f.id === row.trackingFieldId)
  row.thresholdValue = field ? field[val] : null
}

function onThresholdStartDateChange(rowId: number, e: Event) {
  const val = (e.target as HTMLInputElement).value
  const row = getRow(rowId)
  if (!row) return
  row.thresholdStartDate = val
}

function onTriggerModeChange(rowId: number, e: Event) {
  const val = (e.target as HTMLSelectElement).value as TriggerMode
  const row = getRow(rowId)
  if (!row) return
  row.triggerMode = val
  // reset both sides when switching
  row.intervalValue = ''
  row.intervalStartValue = ''
  row.thresholdValueKey = ''
  row.thresholdStartDate = ''
  row.thresholdValue = null
}

function onIntervalValueChange(rowId: number, e: Event) {
  const val = (e.target as HTMLInputElement).value
  const row = getRow(rowId)
  if (!row) return
  row.intervalValue = val
}

function onIntervalStartValueChange(rowId: number, e: Event) {
  const val = (e.target as HTMLInputElement).value
  const row = getRow(rowId)
  if (!row) return
  row.intervalStartValue = val
}

// ---- Data loading ----
const loadConfigs = async () => {
  if (!props.work_order?.id) return
  loadingConfigs.value = true
  try {
    const response = await getItems<any>({
      collection: 'Predictive_tracking_configs',
      params: {
        filter: { pm_work_order: { _eq: props.work_order.id } },
        fields: [
          '*',
          'asset.id',
          'asset.name',
          'pm_work_order.id',
          'pm_work_order.name',
          'field.id',
          'field.value1',
          'field.value2',
          'field.value3',
          'field.value4',
          'field.unit',
        ],
        sort: ['-date_created'],
        limit: -1,
      },
    })
    configs.value = Array.isArray(response)
      ? response
      : (response as any)?.data || []
  } catch (e) {
    console.error('loadConfigs error:', e)
    configs.value = []
  } finally {
    loadingConfigs.value = false
  }
}

const loadTrackingFieldsForRow = async (
  rowId: number,
  assetId: number | string,
) => {
  const row = getRow(rowId)
  if (!row) return
  row.loadingFields = true
  row.trackingFields = []
  row.trackingFieldId = null
  row.trackingFieldName = ''
  row.thresholdValueKey = ''
  row.thresholdStartDate = ''
  row.thresholdValue = null
  try {
    const response = await getItems<any>({
      collection: 'Device_tracking_fields',
      params: {
        filter: { asset: { _eq: assetId } },
        sort: ['sort_order'],
        limit: -1,
      },
    })
    row.trackingFields = Array.isArray(response)
      ? response
      : (response as any)?.data || []
  } catch (e) {
    console.error('loadTrackingFieldsForRow error:', e)
  } finally {
    row.loadingFields = false
  }
}

// ---- Watches ----
watch(
  () => props.openForm,
  (val) => {
    if (val) {
      isFormOpen.value = true
      if (configRows.value.length === 0) addConfigRow()
    } else {
      resetForm()
    }
  },
)

// ---- Handlers ----
const resetForm = () => {
  configRows.value = []
  isFormOpen.value = false
  emit('close')
}

// Prevents form modal from closing while asset picker is open
const onFormClose = () => {
  if (isModalAssetOpen.value) return
  resetForm()
}

const toggleForm = () => {
  if (isFormOpen.value) {
    resetForm()
  } else {
    isFormOpen.value = true
    if (configRows.value.length === 0) addConfigRow()
  }
}

const createPM = async () => {
  const invalidRows = configRows.value.filter((r) => {
    if (!r.assetId || !r.trackingFieldId) return true
    if (r.triggerMode === 'interval')
      return r.intervalValue === '' || r.intervalStartValue === ''
    return !r.thresholdValueKey || !r.thresholdStartDate
  })
  if (invalidRows.length > 0) {
    toaster.show({
      title: t('Warning'),
      message: t('Please fill all required fields for each row'),
      color: 'warning',
      icon: 'ph:warning',
      closable: true,
    })
    return
  }

  submitting.value = true
  try {
    let successCount = 0

    // Create PM for each config row
    for (const row of configRows.value) {
      const pmTitle = (row.pmName || row.assetName || '').trim()
      const field = row.trackingFields.find((f) => f.id === row.trackingFieldId)
      const isInterval = row.triggerMode === 'interval'

      await createItems({
        collection: 'Predictive_tracking_configs',
        items: [
          {
            pm_work_order: props.work_order?.id,
            asset: row.assetId,
            field: isInterval ? null : row.trackingFieldId,
            field_key: field?.field_key,
            field_name: field?.field_name_mn || field?.field_key,
            threshold_type: isInterval ? 'interval' : 'threshold',
            threshold_value: isInterval ? null : row.thresholdValueKey,
            start_date: isInterval ? null : row.thresholdStartDate,
            trigger_interval: isInterval ? parseFloat(row.intervalValue) : null,
            start_point: isInterval ? parseFloat(row.intervalStartValue) : null,
            triggered_at: null,
            pm_name: pmTitle,
            company_id: myCompanyId,
          },
        ],
      })

      successCount++
    }

    toaster.show({
      title: t('Success'),
      message: `${successCount} PM ${t('PM created successfully')}`,
      color: 'success',
      icon: 'ph:check-circle',
      closable: true,
    })

    resetForm()
    await loadConfigs()
  } catch (e) {
    console.error('createPM error:', e)
    toaster.show({
      title: t('Error'),
      message: t('Error creating PM'),
      color: 'danger',
      icon: 'ph:x-circle',
      closable: true,
    })
  } finally {
    submitting.value = false
  }
}

const deleteConfig = async (config: any) => {
  try {
    await deleteItems({
      collection: 'Predictive_tracking_configs',
      items: [config.id],
    })
    configs.value = configs.value.filter((c) => c.id !== config.id)
    toaster.show({
      title: t('Deleted'),
      message: t('Configuration deleted'),
      color: 'info',
      icon: 'ph:trash',
      closable: true,
    })
  } catch (e) {
    console.error('deleteConfig error:', e)
  }
}

// ---- AG Grid ----
const gridApi = ref<any>(null)

const gridOptions = {
  defaultColDef: {
    sortable: true,
    resizable: true,
    suppressHeaderMenuButton: true,
    flex: 1,
  },
  localeText: {
    noRowsToShow: t('No Rows To Show'),
    page: t('Page'),
    to: t('to'),
    of: t('of'),
    pageSizeSelectorLabel: t('Page Size:'),
    sortAscending: t('Sort Ascending'),
    sortDescending: t('Sort Descending'),
    clearColumn: t('Clear Sort'),
    pinColumn: t('Pin Column'),
    pinLeft: t('Pin Left'),
    pinRight: t('Pin Right'),
    noPin: t('No Pin'),
    autosizeThisColumn: t('Autosize This Column'),
    autosizeAllColumns: t('Autosize All Columns'),
    columnChooser: t('Choose Columns'),
    resetColumns: t('Reset Columns'),
    alertButton: t('Click Alert Button and Close Menu'),
  },
  rowSelection: 'single' as const,
  suppressScrollOnNewData: true,
  suppressCellFocus: true,
}

const columnDefs = ref([
  {
    headerName: t('Asset'),
    field: 'asset.name',
    minWidth: 140,
    valueGetter: (p: any) => p.data?.asset?.name || p.data?.asset || '',
  },
  {
    headerName: t('PM Name'),
    field: 'pm_name',
    minWidth: 140,
  },
  {
    headerName: t('Tracking Field'),
    field: 'field_name',
    minWidth: 140,
    valueGetter: (p: any) => p.data?.field_name || p.data?.field_key || '',
  },
  {
    headerName: t('Type'),
    minWidth: 110,
    valueGetter: (p: any) => {
      if (p.data?.threshold_type === 'interval') return '🔢 Тоолууртай'
      if (p.data?.threshold_type === 'threshold') return '📊 Тоолуургүй'
      return p.data?.threshold_type || ''
    },
  },
  {
    headerName: t('Trigger Value'),
    minWidth: 150,
    valueGetter: (p: any) => {
      if (p.data?.threshold_type === 'interval')
        return p.data?.trigger_interval != null
          ? `${p.data.trigger_interval} (давтамж)`
          : ''
      return p.data?.threshold_value != null
        ? (() => {
            const key = p.data.threshold_value
            const fieldData = p.data?.field
            const val = fieldData && key ? fieldData[key] : null
            const unit = fieldData?.unit ? ` ${fieldData.unit}` : ''
            return val != null ? `≥ ${val}${unit}` : ''
          })()
        : ''
    },
  },
  {
    headerName: t('Start'),
    minWidth: 160,
    valueGetter: (p: any) => {
      if (p.data?.threshold_type === 'interval') {
        const startPoint = p.data?.start_point
        const unit = p.data?.field?.unit ? ` ${p.data.field.unit}` : ''
        return startPoint != null ? `${startPoint}${unit}` : ''
      }

      if (p.data?.threshold_type === 'threshold') {
        return p.data?.start_date || ''
      }

      return ''
    },
  },
  {
    headerName: '',
    field: 'id',
    width: 60,
    flex: 0,
    sortable: false,
    cellRenderer: (p: any) => {
      const btn = document.createElement('button')
      btn.innerHTML =
        '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6l-1 14H6L5 6"></path><path d="M10 11v6"></path><path d="M14 11v6"></path><path d="M9 6V4h6v2"></path></svg>'
      btn.className =
        'flex items-center justify-center w-6 h-6 rounded text-muted-400 hover:text-danger-500 transition-colors'
      btn.addEventListener('click', () => deleteConfig(p.data))
      return btn
    },
  },
])

const onGridReady = (params: any) => {
  gridApi.value = params.api
}

onMounted(async () => {
  await loadConfigs()
})
</script>

<template>
  <div class="relative p-2">
    <!-- Section header -->
    <div class="flex items-center justify-between mb-4">
      <div class="flex items-center gap-2">
        <Icon name="ph:gear-six-duotone" class="h-5 w-5 text-primary-500" />
        <BaseHeading
          as="h4"
          size="sm"
          weight="semibold"
          class="text-muted-800 dark:text-white"
        >
          {{ $t('Predictive Maintenance Condition Config') }}
        </BaseHeading>
      </div>
      <!-- <BaseButton size="sm" @click="toggleForm">
        <Icon name="octicon:plus-16" class="-ms-1 h-4 w-4 mr-1" />
        <span class="text-[11px]">{{ $t('Add configuration') }}</span>
      </BaseButton> -->
    </div>

    <!-- Add form modal -->
    <TairoModal :open="isFormOpen" @close="onFormClose" size="3xl">
      <template #header>
        <div class="flex items-center gap-2">
          <Icon name="ph:gear-six-duotone" class="h-5 w-5 text-primary-500" />
          <BaseHeading as="h3" size="sm" weight="semibold">
            {{ $t('New configuration') }}
          </BaseHeading>
        </div>
      </template>

      <!-- Config rows table -->
      <div class="w-full overflow-x-auto">
        <table class="w-full text-sm border-collapse min-w-[700px]">
          <thead>
            <tr class="border-b border-muted-200 dark:border-muted-700">
              <th
                class="text-left py-2 px-3 text-xs font-semibold text-muted-500 uppercase tracking-wider w-[22%]"
              >
                {{ $t('Asset') }} <span class="text-danger-500">*</span>
              </th>
              <th
                class="text-left py-2 px-3 text-xs font-semibold text-muted-500 uppercase tracking-wider w-[22%]"
              >
                {{ $t('PM Name') }} <span class="text-danger-500">*</span>
              </th>
              <th
                class="text-left py-2 px-3 text-xs font-semibold text-muted-500 uppercase tracking-wider w-[26%]"
              >
                {{ $t('Tracking Field') }}
                <span class="text-danger-500">*</span>
              </th>
              <th
                class="text-left py-2 px-3 text-xs font-semibold text-muted-500 uppercase tracking-wider w-[18%]"
              >
                {{ $t('Type') }} <span class="text-danger-500">*</span>
              </th>
              <th
                class="text-left py-2 px-3 text-xs font-semibold text-muted-500 uppercase tracking-wider w-[24%]"
              >
                {{ $t('Trigger Value') }}
                <span class="text-danger-500">*</span>
              </th>
              <th class="w-8"></th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="row in configRows"
              :key="row.id"
              class="border-b border-muted-100 dark:border-muted-800 hover:bg-muted-50 dark:hover:bg-muted-900/50"
            >
              <!-- Asset -->
              <td class="py-2 px-3">
                <button
                  type="button"
                  @click="openAssetPicker(row.id)"
                  class="w-full text-left rounded-lg border border-muted-300 dark:border-muted-700 bg-white dark:bg-muted-900 px-3 py-2 text-sm text-muted-700 dark:text-muted-200 hover:border-primary-400 transition-colors truncate"
                  :class="
                    row.assetName ? '' : 'text-muted-400 dark:text-muted-500'
                  "
                >
                  {{ row.assetName || $t('Select asset') }}
                </button>
              </td>

              <!-- PM Name -->
              <td class="py-2 px-3">
                <input
                  v-model="row.pmName"
                  type="text"
                  :placeholder="$t('PM name')"
                  class="nui-focus border-muted-300 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 w-full rounded-lg border bg-white px-3 py-2 text-sm text-muted-600 transition-shadow duration-300 focus:ring-0"
                />
              </td>

              <!-- Tracking Field -->
              <td class="py-2 px-3">
                <select
                  :value="row.trackingFieldId"
                  :disabled="!row.assetId || row.loadingFields"
                  @change="onFieldChange(row.id, $event)"
                  class="nui-focus border-muted-300 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 w-full rounded-lg border bg-white px-3 py-2 text-sm text-muted-600 transition-shadow duration-300 focus:ring-0 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  <option value="">
                    {{
                      row.loadingFields
                        ? $t('Loading...')
                        : !row.assetId
                        ? $t('Select asset first')
                        : row.trackingFields.length
                        ? $t('Select field')
                        : $t('No configuration')
                    }}
                  </option>
                  <option
                    v-for="field in row.trackingFields"
                    :key="field.id"
                    :value="field.id"
                  >
                    {{ field.field_name_mn || field.field_key }}
                    {{ field.unit ? `(${field.unit})` : '' }}
                  </option>
                </select>
              </td>

              <!-- Mode: Тоолууртай / Тоолуургүй -->
              <td class="py-2 px-3">
                <select
                  :value="row.triggerMode"
                  :disabled="!row.trackingFieldId"
                  @change="onTriggerModeChange(row.id, $event)"
                  class="nui-focus border-muted-300 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 w-full rounded-lg border bg-white px-3 py-2 text-sm text-muted-600 transition-shadow duration-300 focus:ring-0 disabled:cursor-not-allowed disabled:opacity-50"
                >
                  <option value="interval">🔢 {{ $t('With counter') }}</option>
                  <option value="threshold">
                    📊 {{ $t('Without counter') }}
                  </option>
                </select>
              </td>

              <!-- Trigger Value: changes based on mode -->
              <td class="py-2">
                <!-- interval mode: start value + interval inputs -->
                <div
                  v-if="row.triggerMode === 'interval'"
                  class="flex flex-col gap-1"
                >
                  <input
                    type="number"
                    min="0"
                    :value="row.intervalStartValue"
                    :disabled="!row.trackingFieldId"
                    :placeholder="
                      $t('Start value') +
                      (getFieldUnit(row.id)
                        ? ' (' + getFieldUnit(row.id) + ')'
                        : '')
                    "
                    @input="onIntervalStartValueChange(row.id, $event)"
                    class="w-[200px] nui-focus border-muted-300 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 rounded-lg border bg-white px-3 py-2 text-sm text-muted-600 transition-shadow duration-300 focus:ring-0 disabled:cursor-not-allowed disabled:opacity-50"
                  />
                  <input
                    type="number"
                    min="1"
                    :value="row.intervalValue"
                    :disabled="!row.trackingFieldId"
                    :placeholder="
                      $t('Interval') +
                        (getFieldUnit(row.id)
                          ? ' (' + getFieldUnit(row.id) + ')'
                          : '') || '5000'
                    "
                    @input="onIntervalValueChange(row.id, $event)"
                    class="w-[200px] nui-focus border-muted-300 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 rounded-lg border bg-white px-3 py-2 text-sm text-muted-600 transition-shadow duration-300 focus:ring-0 disabled:cursor-not-allowed disabled:opacity-50"
                  />
                </div>
                <!-- threshold mode: pick a preset value1-5 from Device_tracking_fields -->
                <div v-else class="flex flex-col gap-1">
                  <select
                    :value="row.thresholdValueKey"
                    :disabled="!row.trackingFieldId"
                    @change="onThresholdChange(row.id, $event)"
                    class="nui-focus border-muted-300 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 w-[200px] rounded-lg border bg-white px-3 py-2 text-sm text-muted-600 transition-shadow duration-300 focus:ring-0 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    <option value="">{{ $t('Select threshold') }}</option>
                    <option
                      v-for="vk in getAvailableValueKeysForRow(row.id)"
                      :key="vk.key"
                      :value="vk.key"
                    >
                      {{ getFieldValueForKey(row.id, vk.key) }}
                      {{ getFieldUnit(row.id) }}
                    </option>
                  </select>
                  <input
                    type="datetime-local"
                    :value="row.thresholdStartDate"
                    :disabled="!row.trackingFieldId"
                    :placeholder="$t('Start date')"
                    @input="onThresholdStartDateChange(row.id, $event)"
                    class="w-[200px] nui-focus border-muted-300 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 rounded-lg border bg-white px-3 py-2 text-sm text-muted-600 transition-shadow duration-300 focus:ring-0 disabled:cursor-not-allowed disabled:opacity-50"
                  />
                </div>
              </td>

              <!-- Delete row -->
              <td class="py-2 px-2 text-center">
                <button
                  type="button"
                  @click="removeConfigRow(row.id)"
                  :disabled="configRows.length <= 1"
                  class="flex h-7 w-7 items-center justify-center rounded-full text-muted-400 hover:bg-danger-50 hover:text-danger-500 dark:hover:bg-danger-500/10 transition-colors disabled:opacity-30 disabled:pointer-events-none"
                >
                  <Icon name="octicon:trash-16" class="h-4 w-4" />
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Add row button -->
      <div class="pt-3">
        <BaseButton size="sm" @click="addConfigRow">
          <Icon name="octicon:plus-16" class="-ms-1 h-4 w-4 mr-1" />
          {{ $t('Add row') }}
        </BaseButton>
      </div>

      <template #footer>
        <div class="flex w-full items-center justify-between">
          <span class="text-xs text-muted-400">
            {{ configRows.length }} {{ $t('rows') }}
          </span>
          <div class="flex gap-2">
            <BaseButton size="sm" @click="resetForm">
              {{ $t('Cancel') }}
            </BaseButton>
            <BaseButton
              size="sm"
              color="primary"
              :loading="submitting"
              :disabled="submitting"
              @click="createPM"
            >
              <Icon name="ph:plus-circle" class="-ms-1 h-4 w-4 mr-1" />
              {{ $t('Create PM') }}
            </BaseButton>
          </div>
        </div>
      </template>
    </TairoModal>

    <!-- Config list -->
    <div v-if="loadingConfigs" class="flex items-center justify-center py-8">
      <BasePlaceload class="h-4 w-32 rounded" />
    </div>

    <div
      v-else-if="configs.length === 0"
      class="flex flex-col items-center justify-center py-10 text-center"
    >
      <Icon
        name="ph:gear-six"
        class="h-12 w-12 text-muted-300 dark:text-muted-600 mb-2"
      />
      <p class="text-sm text-muted-400 dark:text-muted-500">
        {{ $t('No configuration') }}
      </p>
      <p class="text-xs text-muted-400 dark:text-muted-500 mt-1">
        {{ $t('Click "Add configuration" button to add a new one') }}
      </p>
    </div>

    <div v-else>
      <AgGridVue
        :class="`ag-theme-quartz${$colorMode.value === 'light' ? '' : '-dark'}`"
        style="width: 100%; height: 240px"
        :columnDefs="columnDefs"
        :rowData="configs"
        :gridOptions="gridOptions"
        @grid-ready="onGridReady"
      />
    </div>

    <!-- Asset selection modal -->
    <ModalAssetsList
      :open="isModalAssetOpen"
      :location="props.location || props.work_order?.location?.id || null"
      :close="() => (isModalAssetOpen = false)"
      :setAsset="handleAssetSelected"
    />
  </div>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}
</style>
