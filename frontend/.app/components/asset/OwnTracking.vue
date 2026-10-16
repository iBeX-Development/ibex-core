<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import { AgGridVue } from 'ag-grid-vue3'
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import * as XLSX from 'xlsx'

ModuleRegistry.registerModules([ClientSideRowModelModule])

const { t } = useI18n({ useScope: 'global' })

const props = defineProps({
  assetId: {
    type: [Number, String],
    required: true,
  },
  deviceId: {
    type: [Number, String],
    default: null,
  },
})
const { getItems, createItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const loading = ref(true)
const error = ref<string | null>(null)
const trackingData = ref<any>(null)
const telemetryData = ref<any[]>([])

// Pagination (ag-grid-ийн built-in pager ашиглана)
const itemsPerPage = ref(10)

// Date range - using string for input compatibility
const now = new Date()
const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
const weekAgo = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000)

const formatDateForInput = (date: Date) => {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

const startDate = ref(formatDateForInput(weekAgo))
const endDate = ref(formatDateForInput(now))

// Calculate time range from date inputs
const getTimeRange = () => {
  const start = new Date(startDate.value)
  start.setHours(0, 0, 0, 0)

  const end = new Date(endDate.value)
  end.setHours(23, 59, 59, 999)

  return {
    from: Math.floor(start.getTime() / 1000),
    to: Math.floor(end.getTime() / 1000),
  }
}

// Computed values - support both GPS format and custom fields
const currentSpeed = computed(() => {
  return (
    trackingData.value?.['position.speed'] || trackingData.value?.speed || 0
  )
})

const currentLocation = computed(() => {
  const lat =
    trackingData.value?.['position.latitude'] || trackingData.value?.latitude
  const lon =
    trackingData.value?.['position.longitude'] || trackingData.value?.longitude
  const latNum = lat !== undefined && lat !== null ? Number(lat) : null
  const lonNum = lon !== undefined && lon !== null ? Number(lon) : null
  if (latNum !== null && lonNum !== null && !isNaN(latNum) && !isNaN(lonNum)) {
    return { lat: latNum, lon: lonNum }
  }
  return null
})

const fuelLevel = computed(() => {
  return (
    trackingData.value?.['fuel.level'] ||
    trackingData.value?.['can.fuel.level'] ||
    trackingData.value?.fuel_level ||
    0
  )
})

const engineHours = computed(() => {
  return (
    trackingData.value?.['engine.hours'] ||
    trackingData.value?.engine_hours ||
    0
  )
})

const odometer = computed(() => {
  return (
    trackingData.value?.['position.odometer'] ||
    trackingData.value?.odometer ||
    0
  )
})

const lastUpdate = computed(() => {
  const timestamp = trackingData.value?.timestamp
  if (timestamp) {
    return formatTimestamp(timestamp)
  }
  return '-'
})

// Format Unix timestamp to readable Mongolian format: YYYY.MM.DD HH:MM:SS
const formatTimestamp = (timestamp: number): string => {
  const date = new Date(timestamp * 1000)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  const seconds = String(date.getSeconds()).padStart(2, '0')
  return `${year}.${month}.${day} ${hours}:${minutes}:${seconds}`
}

const formatSpeed = (speed: any) => {
  return Math.round(speed || 0)
}

const formatDistance = (meters: any) => {
  if (!meters) return '0'
  const km = meters / 1000
  return km.toFixed(2)
}

const formatHours = (hours: any) => {
  if (!hours) return '0'
  return hours.toFixed(1)
}

// Load data from Asset_field_data_json (imported records)
const loadFromDatabase = async (applyDateFilter = false) => {
  if (!props.assetId) {
    return
  }

  loading.value = true
  error.value = null

  try {
    // Try both string and integer asset ID
    const assetIdInt = parseInt(props.assetId as string)
    const assetIdStr = String(props.assetId)

    let filter: any = {
      _or: [
        { asset: { _eq: props.assetId } },
        { asset: { _eq: assetIdInt } },
        { asset: { _eq: assetIdStr } },
      ],
    }

    // Apply date filter only when search button is clicked
    if (applyDateFilter) {
      const { from, to } = getTimeRange()
      const startTimestamp = from // Unix timestamp in seconds
      const endTimestamp = to

      console.log('=== Loading data with date filter ===')
      console.log('Timestamp range:', {
        from: startTimestamp,
        to: endTimestamp,
      })

      filter = {
        company_id: myCompanyId,
        _and: [
          filter,
          {
            timestamp: {
              _between: [startTimestamp, endTimestamp],
            },
          },
        ],
      }
    }

    const response = await getItems<any>({
      collection: 'Asset_field_data_json',
      params: {
        filter: filter,
        sort: ['-timestamp'],
        limit: -1,
        fields: ['*'],
      },
    })

    const items = (
      Array.isArray(response) ? response : (response as any)?.data || []
    ) as any[]
    console.log(
      '📊 Loaded items:',
      items.length,
      'records from Asset_field_data_json',
    )

    if (items && items.length > 0) {
      // Convert Asset_field_data_json records to telemetry format
      telemetryData.value = []

      items.forEach((item: any) => {
        try {
          const fieldValues =
            typeof item.field_values === 'string'
              ? JSON.parse(item.field_values)
              : item.field_values

          const timestamp = item.timestamp // Already in Unix seconds

          // Build record with dynamic fields from field_values
          const record: any = {
            timestamp,
            import_source: item.import_source || 'unknown',
            ...fieldValues, // Spread all custom fields
          }

          telemetryData.value.push(record)
        } catch (e) {
          console.error('Error parsing field_values:', e)
        }
      })

      // Reset to first page when data changes
      historyGridApi.value?.paginationGoToFirstPage()

      // Set latest as current tracking data
      trackingData.value = telemetryData.value[0]

      console.log(
        '✅ Telemetry data loaded:',
        telemetryData.value.length,
        'records',
      )
    } else {
      console.log('⚠️ No data found in Asset_field_data_json')
      telemetryData.value = []
      trackingData.value = null
    }
  } catch (e: any) {
    console.error('❌ Дата татахад алдаа:', e)
    error.value = e.message || t('Error loading data')
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  console.log('OwnTracking mounted')
  console.log('assetId:', props.assetId)
  console.log('deviceId:', props.deviceId)

  // Load available formats and asset's saved format, then load fields
  await loadAvailableFormats()
  await loadCustomFieldConfig()

  // Load all data without date filter on mount
  await loadFromDatabase(false)
})

const importRef = ref<{ openModal: () => void } | null>(null)
const OwnFormatImportRef = ref<{ openModal: () => void } | null>(null)
const fieldConfigRef = ref<{
  openModal: () => void
  exportTemplateExcel: () => void
  exportTemplateJSON: () => void
} | null>(null)

const handleImported = async (count: number) => {
  // Import дууссаны дараа Asset_field_data_json-аас бүх дата татах
  console.log(`${count} бичлэг импортлогдлоо`)
  await loadFromDatabase(false)
}

// Bilingual field definitions (default fallback)
const fieldDefinitions = {
  timestamp: { en: 'Timestamp', mn: 'Date & time' },
  'position.latitude': { en: 'Latitude', mn: 'Latitude' },
  'position.longitude': { en: 'Longitude', mn: 'Longitude' },
  'position.speed': { en: 'Speed (km/h)', mn: 'Хурд (км/ц)' },
  'position.altitude': { en: 'Altitude (m)', mn: 'Өндөр (м)' },
  'position.direction': { en: 'Direction (°)', mn: 'Чиглэл (°)' },
  'position.satellites': { en: 'Satellites', mn: 'Дагуул' },
  'position.odometer': { en: 'Odometer (km)', mn: 'Гүйлт (км)' },
  'fuel.level': { en: 'Fuel Level (%)', mn: 'Түлш (%)' },
  'engine.hours': { en: 'Engine Hours (h)', mn: 'Хөдөлгүүрийн цаг (ц)' },
}

// Load custom field configuration
const customFields = ref<any[]>([])

// ── History ag-grid ────────────────────────────────────────────────────
// Баганын байрлал хадгалах: localStorage-д хадгалсан дараалалтай нь
// тааруулж colDefs-ийг ҮҮСГЭХ мөчид нь угаас нь эрэмбэлнэ (өгөгдөл дахин
// ачаалагдах бүрд ag-grid анхны дараалал руугаа буцахаас сэргийлнэ)
const historyColumnOrderKey = computed(
  () => `historyColumnOrder_${props.assetId}`,
)

const getSavedHistoryColumnOrder = (): string[] => {
  if (typeof window === 'undefined') return []
  try {
    const raw = window.localStorage.getItem(historyColumnOrderKey.value)
    const parsed = raw ? JSON.parse(raw) : []
    return Array.isArray(parsed) ? parsed : []
  } catch (_e) {
    return []
  }
}

const orderedCustomFields = computed(() => {
  const fields = customFields.value
  const savedOrder = getSavedHistoryColumnOrder()
  if (!savedOrder.length) return fields

  const byKey = new Map(fields.map((f: any) => [f.field_key, f]))
  const ordered: any[] = []
  for (const key of savedOrder) {
    const field = byKey.get(key)
    if (field) {
      ordered.push(field)
      byKey.delete(key)
    }
  }
  return [...ordered, ...byKey.values()]
})

const historyGridApi = ref<any>(null)

const saveHistoryColumnOrder = () => {
  if (!historyGridApi.value || typeof window === 'undefined') return
  try {
    const order = historyGridApi.value
      .getColumnState()
      .map((s: any) => s.colId as string)
      .filter((id: string) => id !== 'timestamp')
    window.localStorage.setItem(
      historyColumnOrderKey.value,
      JSON.stringify(order),
    )
  } catch (_e) {}
}

const onHistoryGridReady = (params: any) => {
  historyGridApi.value = params.api
}

const onHistoryColumnMoved = (event: any) => {
  if (event.finished) saveHistoryColumnOrder()
}

const SOURCE_BADGE_CLASS: Record<string, string> = {
  excel:
    'bg-success-100 text-success-700 dark:bg-success-900/30 dark:text-success-400',
  json: 'bg-info-100 text-info-700 dark:bg-info-900/30 dark:text-info-400',
  csv: 'bg-warning-100 text-warning-700 dark:bg-warning-900/30 dark:text-warning-400',
}

const historyColumnDefs = computed(() => {
  const dateCol = {
    headerName: t('Date'),
    field: 'timestamp',
    pinned: 'left',
    minWidth: 170,
    valueFormatter: (p: any) => formatTimestamp(p.value),
  }

  if (orderedCustomFields.value.length > 0) {
    const dynamicDefs = orderedCustomFields.value.map((field: any) => ({
      headerName: field.unit
        ? `${field.field_name_mn} (${field.unit})`
        : field.field_name_mn,
      headerTooltip: field.field_name_en,
      field: field.field_key,
      minWidth: 140,
      valueFormatter: (p: any) =>
        p.value === undefined || p.value === null ? '-' : String(p.value),
    }))
    return [dateCol, ...dynamicDefs]
  }

  return [
    dateCol,
    {
      headerName: t('Source'),
      field: 'import_source',
      minWidth: 120,
      cellRenderer: (p: any) => {
        const value = p.value || '-'
        const cls =
          SOURCE_BADGE_CLASS[value] ||
          'bg-muted-100 text-muted-700 dark:bg-muted-900/30 dark:text-muted-400'
        return `<span class="px-2 py-0.5 rounded text-xs font-medium ${cls}">${value}</span>`
      },
    },
    {
      headerName: t('Latitude'),
      colId: 'latitude',
      minWidth: 130,
      valueGetter: (p: any) =>
        p.data?.latitude ?? p.data?.['position.latitude'] ?? '-',
    },
    {
      headerName: t('Longitude'),
      colId: 'longitude',
      minWidth: 130,
      valueGetter: (p: any) =>
        p.data?.longitude ?? p.data?.['position.longitude'] ?? '-',
    },
    {
      headerName: t('Speed'),
      colId: 'speed',
      minWidth: 110,
      valueGetter: (p: any) =>
        p.data?.speed ?? p.data?.['position.speed'] ?? '-',
    },
    {
      headerName: t('Fuel'),
      colId: 'fuel',
      minWidth: 110,
      valueGetter: (p: any) =>
        p.data?.fuel_level ?? p.data?.['fuel.level'] ?? '-',
    },
  ]
})

const historyDefaultColDef = {
  sortable: true,
  filter: false,
  resizable: true,
  suppressHeaderMenuButton: true,
}

// ─── Device_tracking_fields selector ───────────────────────────────
interface FormatOption {
  code: string
  format_name: string
  description: string
  fields: any[]
}
const availableFormats = ref<FormatOption[]>([])
const selectedFormatCode = ref<string>('')
const isSavingFormat = ref(false)
const formatSaved = ref(false)

async function loadAvailableFormats() {
  try {
    const res = await getItems<any>({
      collection: 'Device_tracking_fields',
      params: {
        filter: { company_id: myCompanyId, status: 'published' },
        fields: ['*'],
        sort: ['code', 'sort_order'],
        limit: -1,
      },
    })
    const rows: any[] = Array.isArray(res) ? res : (res as any)?.data ?? []
    const map = new Map<string, FormatOption>()
    for (const row of rows) {
      if (!map.has(row.code)) {
        map.set(row.code, {
          code: row.code,
          format_name: row.format_name,
          description: row.description ?? '',
          fields: [],
        })
      }
      map.get(row.code)!.fields.push(row)
    }
    availableFormats.value = [...map.values()]
    console.log('availableFormats ', availableFormats)
  } catch (e) {
    console.warn('Failed to load Device_tracking_fields:', e)
  }
}

const selectedFormat = computed(
  () =>
    availableFormats.value.find((f) => f.code === selectedFormatCode.value) ??
    null,
)

const sharedFormatFields = computed(
  () =>
    selectedFormat.value?.fields.filter(
      (field) => field.is_shared_format === true,
    ) ?? [],
)

async function saveFormatCode() {
  if (!props.assetId) return
  isSavingFormat.value = true
  formatSaved.value = false
  try {
    const config = useRuntimeConfig()
    const { token } = useDirectusToken()
    const baseUrl = ((config.public.directus as any)?.url ?? '').replace(
      /\/$/,
      '',
    )
    await $fetch(`${baseUrl}/items/Assets/${props.assetId}`, {
      method: 'PATCH',
      body: { device_format_code: selectedFormatCode.value || null },
      headers: token.value ? { Authorization: `Bearer ${token.value}` } : {},
    })
    // Reload fields from new format
    await loadCustomFieldConfig()
    formatSaved.value = true
    setTimeout(() => {
      formatSaved.value = false
    }, 2000)
  } catch (e) {
    console.warn('Failed to save format code:', e)
  } finally {
    isSavingFormat.value = false
  }
}

// Device_tracking_fields.is_show (0/1 switch) — 0 бол Current status картан дээр
// нуугдана. Утга байхгүй бол анхныхаараа харуулна.
const isFieldShown = (field: any): boolean =>
  !(field.is_show === 0 || field.is_show === '0' || field.is_show === false)

// "is_show" switch дарахад тухайн field-ийг DB-д хадгалж, локал байдлаар toggle хийнэ
const toggleFieldShow = async (field: any) => {
  const newValue = isFieldShown(field) ? 0 : 1
  field.is_show = newValue

  if (!field.id) return
  try {
    await updateItem({
      collection: 'Device_tracking_fields',
      id: field.id,
      item: { is_show: newValue },
    })
  } catch (err) {
    console.warn('⚠️ Could not update is_show:', err)
  }
}

// Helper to get icon and color for field type
const getFieldIcon = (
  fieldKey: string,
): {
  icon: string
  color:
    | 'default'
    | 'primary'
    | 'info'
    | 'success'
    | 'warning'
    | 'danger'
    | undefined
} => {
  const iconMap: Record<
    string,
    {
      icon: string
      color:
        | 'default'
        | 'primary'
        | 'info'
        | 'success'
        | 'warning'
        | 'danger'
        | undefined
    }
  > = {
    speed: { icon: 'ph:speedometer', color: 'primary' },
    latitude: { icon: 'ph:map-pin', color: 'info' },
    longitude: { icon: 'ph:map-pin', color: 'info' },
    fuel_level: { icon: 'ph:gas-pump', color: 'success' },
    engine_hours: { icon: 'ph:engine', color: 'warning' },
    odometer: { icon: 'ph:gauge', color: 'info' },
    altitude: { icon: 'ph:mountains', color: 'default' },
    direction: { icon: 'ph:compass', color: 'default' },
    satellites: { icon: 'ph:satellite', color: 'default' },
    temperature: { icon: 'ph:thermometer', color: 'danger' },
    worked_time: { icon: 'ph:clock', color: 'primary' },
    used_energy: { icon: 'ph:lightning', color: 'warning' },
    created_money: { icon: 'ph:currency-circle-dollar', color: 'success' },
    spend_balance: { icon: 'ph:wallet', color: 'info' },
  }
  return iconMap[fieldKey] || { icon: 'ph:chart-line', color: 'primary' }
}

const loadCustomFieldConfig = async () => {
  if (!props.assetId) return

  try {
    // 1. Load the asset's saved format code
    const config = useRuntimeConfig()
    const { token } = useDirectusToken()
    const baseUrl = ((config.public.directus as any)?.url ?? '').replace(
      /\/$/,
      '',
    )
    let formatCode: string | null = null
    try {
      const assetRes = await $fetch<{ data: { device_format_code?: string } }>(
        `${baseUrl}/items/Assets/${props.assetId}?fields=device_format_code`,
        {
          headers: token.value
            ? { Authorization: `Bearer ${token.value}` }
            : {},
        },
      )
      formatCode = assetRes?.data?.device_format_code ?? null
    } catch (e) {
      // field may not exist yet
    }

    if (formatCode) {
      console.log('formatCode', formatCode)
      selectedFormatCode.value = formatCode
      // Load fields from Device_tracking_fields for this code
      const response = await getItems<any>({
        collection: 'Device_tracking_fields',
        params: {
          filter: {
            company_id: myCompanyId,
            code: { _eq: formatCode },
            is_active: { _neq: false },
            is_shared_format: { _eq: true },
          },
          sort: ['sort_order'],
        },
      })
      const items = Array.isArray(response)
        ? response
        : (response as any)?.data || []

      console.log('Device_tracking_fields_is_shared_format', items)
      customFields.value = items.length > 0 ? items : []
    } else {
      // Fallback: try Device_tracking_fields (legacy per-asset config)
      const response = await getItems<any>({
        collection: 'Device_tracking_fields',
        params: {
          filter: {
            company_id: myCompanyId,
            asset: { _eq: props.assetId },
            is_active: { _eq: true },
            is_shared_format: { _eq: false },
          },
          sort: ['sort_order'],
        },
      })
      const items = Array.isArray(response)
        ? response
        : (response as any)?.data || []
      customFields.value = items.length > 0 ? items : []
    }
  } catch (error: any) {
    console.warn(
      '⚠️ Device_tracking_fields эрх байхгүй эсвэл алдаа гарлаа:',
      error.message,
    )
    customFields.value = []
  }
}

// Generate JSON format example based on custom fields or default
const formatExample = computed(() => {
  if (customFields.value.length > 0) {
    // Use custom field configuration
    const exampleData: any = {
      timestamp: 1711584000,
    }

    customFields.value.forEach((field) => {
      const sampleValues: Record<string, any> = {
        latitude: 47.9184,
        longitude: 106.9177,
        speed: 45.5,
        altitude: 1350,
        direction: 180,
        satellites: 12,
        odometer: 125000,
        fuel_level: 75.2,
        engine_hours: 1234.5,
        temperature: 25,
      }

      exampleData[field.field_key] = sampleValues[field.field_key] || 0
    })

    return {
      result: [exampleData],
    }
  } else {
    // Default static format
    return {
      result: [
        {
          timestamp: 1711584000,
          'position.latitude': 47.9184,
          'position.longitude': 106.9177,
          'position.speed': 45.5,
          'position.altitude': 1350,
          'fuel.level': 75.2,
          'engine.hours': 1234.5,
          'position.odometer': 125000,
        },
      ],
    }
  }
})

// Get supported fields description
const supportedFieldsList = computed(() => {
  if (customFields.value.length > 0) {
    return customFields.value.map((field) => ({
      key: field.field_key,
      mn: field.field_name_mn,
      en: field.field_name_en,
      unit: field.unit,
    }))
  }
  return null // Use default list
})

// Export to Excel with bilingual headers (using custom field config if available)
const exportToExcel = async () => {
  if (telemetryData.value.length === 0) {
    alert(t('No data to export'))
    return
  }

  // Load custom field configuration
  await loadCustomFieldConfig()

  const exportData = telemetryData.value.map((record) => {
    const row: any = {}

    if (customFields.value.length > 0) {
      // Use custom field configuration
      row['Огноо цаг (MN)'] = formatTimestamp(record.timestamp)
      row['Timestamp (EN)'] = formatTimestamp(record.timestamp)

      customFields.value.forEach((field: any) => {
        const key = field.field_key
        let value: any = record[key] // Get value directly from record using field_key

        // Format specific field types
        if (value !== undefined && value !== null) {
          if (key === 'latitude' || key === 'longitude') {
            value = typeof value === 'number' ? value.toFixed(6) : value
          } else if (key === 'odometer') {
            value = typeof value === 'number' ? formatDistance(value) : value
          } else if (key === 'engine_hours') {
            value = typeof value === 'number' ? formatHours(value) : value
          } else if (typeof value === 'number') {
            // Format other numbers nicely
            value = value.toLocaleString('en-US', { maximumFractionDigits: 2 })
          }
        } else {
          value = '-'
        }

        // Set both MN and EN columns with unit
        const columnMN = field.unit
          ? `${field.field_name_mn} (${field.unit})`
          : field.field_name_mn
        const columnEN = field.unit
          ? `${field.field_name_en} (${field.unit})`
          : field.field_name_en

        row[columnMN] = value
        row[columnEN] = value
      })
    } else {
      // Use default field definitions
      return {
        [fieldDefinitions.timestamp.mn]: formatTimestamp(record.timestamp),
        [fieldDefinitions.timestamp.en]: formatTimestamp(record.timestamp),
        [fieldDefinitions['position.latitude'].mn]:
          record['position.latitude']?.toFixed(6) || '-',
        [fieldDefinitions['position.latitude'].en]:
          record['position.latitude']?.toFixed(6) || '-',
        [fieldDefinitions['position.longitude'].mn]:
          record['position.longitude']?.toFixed(6) || '-',
        [fieldDefinitions['position.longitude'].en]:
          record['position.longitude']?.toFixed(6) || '-',
        [fieldDefinitions['position.speed'].mn]: formatSpeed(
          record['position.speed'],
        ),
        [fieldDefinitions['position.speed'].en]: formatSpeed(
          record['position.speed'],
        ),
        [fieldDefinitions['position.altitude'].mn]: Math.round(
          record['position.altitude'] || 0,
        ),
        [fieldDefinitions['position.altitude'].en]: Math.round(
          record['position.altitude'] || 0,
        ),
        [fieldDefinitions['position.direction'].mn]: Math.round(
          record['position.direction'] || 0,
        ),
        [fieldDefinitions['position.direction'].en]: Math.round(
          record['position.direction'] || 0,
        ),
        [fieldDefinitions['position.satellites'].mn]:
          record['position.satellites'] || 0,
        [fieldDefinitions['position.satellites'].en]:
          record['position.satellites'] || 0,
        [fieldDefinitions['position.odometer'].mn]: formatDistance(
          record['position.odometer'],
        ),
        [fieldDefinitions['position.odometer'].en]: formatDistance(
          record['position.odometer'],
        ),
        [fieldDefinitions['fuel.level'].mn]: Math.round(
          record['fuel.level'] || 0,
        ),
        [fieldDefinitions['fuel.level'].en]: Math.round(
          record['fuel.level'] || 0,
        ),
        [fieldDefinitions['engine.hours'].mn]: formatHours(
          record['engine.hours'],
        ),
        [fieldDefinitions['engine.hours'].en]: formatHours(
          record['engine.hours'],
        ),
      }
    }

    return row
  })

  const worksheet = XLSX.utils.json_to_sheet(exportData)
  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Own Tracking Data')

  const fileName = `own_tracking_data_${props.assetId}_${
    new Date().toISOString().split('T')[0]
  }.xlsx`
  XLSX.writeFile(workbook, fileName)
}

// Export to JSON with bilingual field names (using custom field config if available)
const exportToJSON = async () => {
  if (telemetryData.value.length === 0) {
    alert(t('No data to export'))
    return
  }

  // Load custom field configuration
  await loadCustomFieldConfig()

  const exportData = telemetryData.value.map((record) => {
    const item: any = {
      timestamp_unix: record.timestamp,
      timestamp_iso: new Date(record.timestamp * 1000).toISOString(),
      timestamp_formatted: formatTimestamp(record.timestamp),
    }

    if (customFields.value.length > 0) {
      // Use custom field configuration - data comes directly from field_values
      customFields.value.forEach((field: any) => {
        const key = field.field_key
        let value: any = record[key] // Get value directly from record using field_key

        // Format specific field types
        if (value !== undefined && value !== null) {
          if (key === 'latitude' || key === 'longitude') {
            value =
              typeof value === 'number' ? parseFloat(value.toFixed(6)) : value
          } else if (key === 'odometer') {
            value =
              typeof value === 'number'
                ? parseFloat(formatDistance(value))
                : value
          } else if (key === 'engine_hours') {
            value =
              typeof value === 'number' ? parseFloat(formatHours(value)) : value
          } else if (typeof value === 'number') {
            // Keep numbers as-is for JSON
            value = value
          }
        } else {
          value = null
        }

        // Store with bilingual keys
        item[field.field_name_mn] = value
        item[field.field_name_en] = value
      })
    } else {
      // Use default field definitions
      Object.keys(fieldDefinitions).forEach((key) => {
        const fieldDef = fieldDefinitions[key as keyof typeof fieldDefinitions]
        let value: any

        if (key === 'timestamp') {
          value = new Date(record.timestamp * 1000).toISOString()
        } else if (key === 'position.odometer') {
          value = parseFloat(formatDistance(record[key]))
        } else if (key === 'engine.hours') {
          value = parseFloat(formatHours(record[key]))
        } else if (
          key === 'position.speed' ||
          key === 'position.altitude' ||
          key === 'position.direction' ||
          key === 'fuel.level'
        ) {
          value = Math.round(record[key] || 0)
        } else if (
          key === 'position.latitude' ||
          key === 'position.longitude'
        ) {
          value = record[key]?.toFixed(6) || null
        } else {
          value = record[key] || null
        }

        // Store with bilingual keys
        item[fieldDef.mn] = value
        item[fieldDef.en] = value
      })
    }

    return item
  })

  const jsonStr = JSON.stringify(exportData, null, 2)
  const blob = new Blob([jsonStr], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `own_tracking_data_${props.assetId}_${
    new Date().toISOString().split('T')[0]
  }.json`
  link.click()
  URL.revokeObjectURL(url)
}

// Import from JSON/Excel - Save directly to Datahub_history
const importFromFile = async (jsonData: any[]) => {
  if (!jsonData || jsonData.length === 0) {
    alert(t('No data to import'))
    return
  }

  try {
    loading.value = true

    const historyRecords = jsonData.map((record) => ({
      asset: parseInt(String(props.assetId)),
      timestamp: record.timestamp
        ? new Date(record.timestamp * 1000).toISOString()
        : new Date().toISOString(),
      data_type: 'tracking',
      data_snapshot: JSON.stringify({
        latitude: record['position.latitude'] || record.latitude,
        longitude: record['position.longitude'] || record.longitude,
        speed: record['position.speed'] || record.speed,
        altitude: record['position.altitude'] || record.altitude,
        direction: record['position.direction'] || record.direction,
        satellites: record['position.satellites'] || record.satellites,
        odometer: record['position.odometer'] || record.odometer,
        fuel_level: record['fuel.level'] || record.fuel_level,
        engine_hours: record['engine.hours'] || record.engine_hours,
      }),
      record_count: 1,
      date_range_start: record.timestamp
        ? new Date(record.timestamp * 1000).toISOString()
        : new Date().toISOString(),
      date_range_end: record.timestamp
        ? new Date(record.timestamp * 1000).toISOString()
        : new Date().toISOString(),
      company_id: myCompanyId,
    }))

    await createItems({
      collection: 'Datahub_history',
      items: historyRecords,
    })

    alert(t('Data imported successfully'))

    // Reload data from history
    await loadFromDatabase(false)
  } catch (e: any) {
    console.error('Error importing to history:', e)
    alert(t('Error during import: ') + e.message)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="own-tracking">
    <div class="mb-6 flex items-center justify-between">
      <div class="flex items-center gap-3 headers">
        <!-- Field Configuration Button -->
        <AssetTrackingFieldsConfig ref="fieldConfigRef" :asset-id="assetId" />

        <!-- Device Fields Format Selector -->
        <div class="availableFormats flex items-center gap-2">
          <select
            v-model="selectedFormatCode"
            class="rounded-lg border border-muted-200 bg-white px-2 py-1.5 text-xs text-muted-900 focus:border-primary-400 focus:outline-none dark:border-muted-700 dark:bg-muted-800 dark:text-white"
          >
            <option value="">{{ $t('-- Select Format --') }}</option>
            <option
              v-for="fmt in availableFormats"
              :key="fmt.code"
              :value="fmt.code"
            >
              {{ fmt.code }} — {{ fmt.format_name }}
            </option>
          </select>
          <button
            class="flex items-center gap-1 rounded-lg bg-primary-500 px-2 py-1.5 text-[11px] font-medium text-white hover:bg-primary-600 disabled:opacity-50"
            :disabled="isSavingFormat"
            @click="saveFormatCode"
          >
            <Icon
              :name="
                isSavingFormat
                  ? 'mdi:loading'
                  : formatSaved
                  ? 'mdi:check'
                  : 'mdi:content-save'
              "
              :class="['h-3.5 w-3.5', isSavingFormat && 'animate-spin']"
            />
            {{ formatSaved ? $t('Saved') : $t('Save') }}
          </button>
        </div>

        <!-- Date Range Selection -->
        <div class="flex items-center gap-2">
          <!-- Date inputs -->
          <div class="flex items-center gap-2">
            <label class="text-muted-600 dark:text-muted-400 text-xs">
              {{ $t('Start') }}:
            </label>
            <input
              v-model="startDate"
              type="date"
              class="border border-muted-300 dark:border-muted-700 dark:bg-muted-800 rounded px-2 py-1.5 text-sm"
            />
            <span class="text-muted-400">~</span>
            <label class="text-muted-600 dark:text-muted-400 text-xs">
              {{ $t('End') }}:
            </label>
            <input
              v-model="endDate"
              type="date"
              class="border border-muted-300 dark:border-muted-700 dark:bg-muted-800 rounded px-2 py-1.5 text-sm"
            />
          </div>

          <BaseButton
            size="sm"
            color="primary"
            @click="loadFromDatabase(true)"
            :disabled="loading"
          >
            <Icon name="ph:magnifying-glass" class="h-4 w-4" />
            <span class="ml-1.5">{{ $t('Search') }}</span>
          </BaseButton>

          <BaseButton
            size="sm"
            color="default"
            @click="loadFromDatabase(false)"
            :disabled="loading"
          >
            <Icon name="ph:list" class="h-4 w-4" />
            <span class="ml-1.5">{{ $t('All') }}</span>
          </BaseButton>
        </div>

        <!-- Own Import Component -->
        <AssetOwnFormatImport
          ref="OwnFormatImportRef"
          :asset-id="assetId"
          @imported="handleImported"
        />

        <!-- Flespi Import (legacy) -->
        <AssetOwnDataImport
          ref="importRef"
          :asset-id="assetId"
          @imported="handleImported"
        />
      </div>
    </div>

    <!-- Format Documentation -->
    <BaseCard
      class="p-4 mb-6 bg-info-50 dark:bg-info-900/20 border border-info-200 dark:border-info-800"
    >
      <details class="text-sm">
        <summary
          class="text-muted-700 dark:text-muted-300 cursor-pointer font-medium flex items-center gap-2"
        >
          <Icon name="ph:info" class="h-5 w-5" />
          {{ $t('Data format information') }}
        </summary>
        <div class="mt-4 space-y-3 text-muted-600 dark:text-muted-400">
          <!-- No Custom Config - Show Helper Text -->
          <div
            v-if="customFields.length === 0"
            class="bg-warning-50 dark:bg-warning-900/20 border border-warning-200 dark:border-warning-800 rounded-lg p-4"
          >
            <div class="flex items-start gap-3">
              <Icon
                name="ph:warning-circle"
                class="h-6 w-6 text-warning-500 flex-shrink-0 mt-0.5"
              />
              <div class="flex-1">
                <p class="font-medium text-warning-700 dark:text-warning-300">
                  {{ $t('Field settings not configured') }}
                </p>
                <p class="text-sm text-warning-600 dark:text-warning-400 mt-1">
                  {{
                    $t(
                      'To configure your fields in JSON/Excel format, click the "Format" button.',
                    )
                  }}
                </p>
                <BaseButton
                  size="sm"
                  color="warning"
                  class="mt-3"
                  @click="OwnFormatImportRef?.openModal()"
                >
                  <Icon name="ph:gear" class="h-4 w-4 mr-1" />
                  {{ $t('Configure') }}
                </BaseButton>
              </div>
            </div>

            <!-- Default Format Example -->
            <div
              class="mt-4 pt-4 border-t border-warning-200 dark:border-warning-700"
            >
              <p class="text-sm mb-2">
                {{ $t('Currently using default format:') }}
              </p>
              <pre
                class="bg-muted-100 dark:bg-muted-800 p-3 rounded text-xs overflow-x-auto"
                >{{ JSON.stringify(formatExample, null, 2) }}</pre
              >
            </div>
          </div>

          <!-- Custom Config Exists - Show Custom Format -->
          <div v-else class="space-y-3">
            <div
              class="bg-success-50 dark:bg-success-900/20 border border-success-200 dark:border-success-800 rounded-lg p-3"
            >
              <div class="flex items-center gap-2">
                <Icon name="ph:check-circle" class="h-5 w-5 text-success-500" />
                <p
                  class="text-sm font-medium text-success-700 dark:text-success-300"
                >
                  {{ $t('Your configured format is being used') }}
                  ({{ customFields.length }} {{ $t('field') }})
                </p>
              </div>
            </div>

            <!-- <p>
              {{
                $t(
                  'JSON format data can be imported from GPS tracking systems:',
                )
              }}
            </p> -->
            <pre
              class="selectedFormat bg-muted-100 dark:bg-muted-800 p-3 rounded text-xs overflow-x-auto"
              >{{ JSON.stringify(formatExample, null, 2) }}</pre
            >
            <div class="flex items-start gap-2 configured_format">
              <Icon
                name="ph:arrow-right"
                class="h-5 w-5 flex-shrink-0 mt-0.5"
              />
              <div class="w-full">
                <!-- Selected format info -->
                <div v-if="selectedFormat" class="mb-3">
                  <p class="font-medium flex items-center gap-1.5">
                    <span
                      class="rounded bg-primary-100 px-1.5 py-0.5 font-mono text-[11px] font-bold text-primary-700 dark:bg-primary-900/40 dark:text-primary-300"
                    >
                      {{ selectedFormat.code }}
                    </span>
                    {{ selectedFormat.format_name }}
                    <span
                      v-if="selectedFormat.description"
                      class="text-xs font-normal text-muted-400"
                      >— {{ selectedFormat.description }}</span
                    >
                  </p>
                  <!-- Field table -->
                  <div
                    class="mt-2 overflow-x-auto rounded-lg border border-muted-200 dark:border-muted-700"
                  >
                    <table class="w-full text-xs">
                      <thead class="bg-muted-50 dark:bg-muted-800">
                        <tr>
                          <th
                            class="px-2 py-1.5 text-left font-medium text-muted-500"
                          >
                            #
                          </th>
                          <th
                            class="px-2 py-1.5 text-left font-medium text-muted-500"
                          >
                            field_key
                          </th>
                          <th
                            class="px-2 py-1.5 text-left font-medium text-muted-500"
                          >
                            {{ $t('MN name') }}
                          </th>
                          <th
                            class="px-2 py-1.5 text-left font-medium text-muted-500"
                          >
                            {{ $t('EN name') }}
                          </th>
                          <th
                            class="px-2 py-1.5 text-left font-medium text-muted-500"
                          >
                            unit
                          </th>
                        </tr>
                      </thead>
                      <tbody
                        class="divide-y divide-muted-100 dark:divide-muted-800 sharedFormatFields"
                      >
                        <tr class="bg-muted-50/50 dark:bg-muted-900/50">
                          <td class="px-2 py-1 text-muted-400">0</td>
                          <td
                            class="px-2 py-1 font-mono font-semibold text-muted-700 dark:text-muted-300"
                          >
                            timestamp
                          </td>
                          <td class="px-2 py-1 text-muted-500">
                            {{ $t('Date & time') }}
                          </td>
                          <td class="px-2 py-1 text-muted-500">Timestamp</td>
                          <td class="px-2 py-1 text-muted-400">Unix</td>
                        </tr>
                        <tr
                          v-for="(f, idx) in sharedFormatFields"
                          :key="f.field_key"
                          class="hover:bg-muted-50 dark:hover:bg-muted-800/50"
                        >
                          <td class="px-2 py-1 text-muted-400">
                            {{ idx + 1 }}
                          </td>
                          <td
                            class="px-2 py-1 font-mono text-muted-800 dark:text-muted-200"
                          >
                            {{ f.field_key }}
                          </td>
                          <td
                            class="px-2 py-1 text-muted-600 dark:text-muted-400"
                          >
                            {{ f.field_name_mn }}
                          </td>
                          <td
                            class="px-2 py-1 text-muted-600 dark:text-muted-400"
                          >
                            {{ f.field_name_en }}
                          </td>
                          <td class="px-2 py-1 text-muted-500">{{ f.unit }}</td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
                <div v-else class="text-xs text-muted-400 italic">
                  {{
                    $t(
                      'No format selected. Please choose from the dropdown above and click Save.',
                    )
                  }}
                </div>
              </div>
            </div>
          </div>
        </div>
      </details>
    </BaseCard>

    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <BaseIconBox size="xl" color="primary" class="animate-pulse">
        <Icon name="svg-spinners:blocks-shuffle-3" class="h-8 w-8" />
      </BaseIconBox>
    </div>

    <!-- Error State -->
    <BaseCard v-else-if="error" class="p-6">
      <div class="flex items-center gap-4 text-danger-500">
        <Icon name="ph:warning-circle" class="h-8 w-8" />
        <div>
          <p class="font-semibold">{{ $t('An error occurred') }}</p>
          <p class="text-sm">{{ error }}</p>
        </div>
      </div>
    </BaseCard>

    <!-- Data Display -->
    <div v-else-if="trackingData" class="space-y-6">
      <!-- Current Status Cards -->
      <div>
        <BaseHeading as="h4" size="md" weight="semibold" class="mb-3">
          {{ $t('Current status') }}
          <span
            v-if="customFields.length > 0"
            class="text-sm text-muted-400 font-normal ml-2"
          >
            ({{ customFields.length }} {{ $t('field') }})
          </span>
        </BaseHeading>

        <!-- Dynamic Fields from Device_tracking_fields -->
        <div
          v-if="customFields.length > 0"
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3"
        >
          <BaseCard
            v-for="field in customFields"
            :key="field.field_key"
            class="p-4"
          >
            <div class="flex items-center gap-3">
              <BaseIconBox
                :color="getFieldIcon(field.field_key).color"
                size="sm"
              >
                <Icon
                  :name="getFieldIcon(field.field_key).icon"
                  class="h-5 w-5"
                />
              </BaseIconBox>
              <div class="flex-1 min-w-0">
                <p
                  class="text-muted-400 text-xs font-medium truncate"
                  :title="field.field_name_en"
                >
                  {{ field.field_name_mn }}
                </p>
                <p class="text-muted-800 dark:text-muted-100 text-m font-bold">
                  {{
                    trackingData?.[field.field_key] !== undefined &&
                    trackingData?.[field.field_key] !== null
                      ? typeof trackingData[field.field_key] === 'number'
                        ? trackingData[field.field_key].toLocaleString(
                            'en-US',
                            { maximumFractionDigits: 2 },
                          )
                        : trackingData[field.field_key]
                      : '-'
                  }}
                  <span
                    v-if="
                      field.unit &&
                      trackingData?.[field.field_key] !== undefined
                    "
                    class="text-sm font-normal ml-1"
                  >
                    {{ field.unit }}
                  </span>
                </p>
              </div>
              <button
                type="button"
                class="w-8 h-5 rounded-full transition-colors relative shrink-0 inline-flex"
                :class="
                  isFieldShown(field)
                    ? 'bg-primary-500'
                    : 'bg-muted-300 dark:bg-muted-600'
                "
                :title="$t('Show in charts')"
                @click="toggleFieldShow(field)"
              >
                <span
                  class="absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform"
                  :class="
                    isFieldShown(field) ? 'translate-x-3' : 'translate-x-0'
                  "
                />
              </button>
            </div>
          </BaseCard>
        </div>

        <!-- Fallback: Default GPS Fields -->
        <div
          v-else
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3"
        >
          <!-- Speed -->
          <BaseCard class="p-4">
            <div class="flex items-center gap-3">
              <BaseIconBox color="primary" size="md">
                <Icon name="ph:speedometer" class="h-5 w-5" />
              </BaseIconBox>
              <div>
                <p class="text-muted-400 text-xs font-medium uppercase">
                  {{ $t('Speed') }}
                </p>
                <p class="text-muted-800 dark:text-muted-100 text-xl font-bold">
                  {{ formatSpeed(currentSpeed) }}
                  <span class="text-sm font-normal">км/ц</span>
                </p>
              </div>
            </div>
          </BaseCard>

          <!-- Fuel Level -->
          <BaseCard class="p-4">
            <div class="flex items-center gap-3">
              <BaseIconBox color="success" size="md">
                <Icon name="ph:gas-pump" class="h-5 w-5" />
              </BaseIconBox>
              <div>
                <p class="text-muted-400 text-xs font-medium uppercase">
                  {{ $t('Fuel') }}
                </p>
                <p class="text-muted-800 dark:text-muted-100 text-xl font-bold">
                  {{ Math.round(fuelLevel) }}
                  <span class="text-sm font-normal">%</span>
                </p>
              </div>
            </div>
          </BaseCard>

          <!-- Odometer -->
          <BaseCard class="p-4">
            <div class="flex items-center gap-3">
              <BaseIconBox color="info" size="md">
                <Icon name="ph:gauge" class="h-5 w-5" />
              </BaseIconBox>
              <div>
                <p class="text-muted-400 text-xs font-medium uppercase">
                  {{ $t('Run') }}
                </p>
                <p class="text-muted-800 dark:text-muted-100 text-xl font-bold">
                  {{ formatDistance(odometer) }}
                  <span class="text-sm font-normal">км</span>
                </p>
              </div>
            </div>
          </BaseCard>

          <!-- Engine Hours -->
          <BaseCard class="p-4">
            <div class="flex items-center gap-3">
              <BaseIconBox color="warning" size="md">
                <Icon name="ph:engine" class="h-5 w-5" />
              </BaseIconBox>
              <div>
                <p class="text-muted-400 text-xs font-medium uppercase">
                  {{ $t('Engine hours') }}
                </p>
                <p class="text-muted-800 dark:text-muted-100 text-xl font-bold">
                  {{ formatHours(engineHours) }}
                  <span class="text-sm font-normal">ц</span>
                </p>
              </div>
            </div>
          </BaseCard>
        </div>
      </div>

      <!-- Location Card -->
      <BaseCard v-if="currentLocation" class="p-6">
        <div class="flex items-start gap-4">
          <BaseIconBox color="primary" size="lg">
            <Icon name="ph:map-pin" class="h-6 w-6" />
          </BaseIconBox>
          <div class="flex-1">
            <p class="text-muted-800 dark:text-muted-100 font-semibold mb-2">
              {{ $t('Last location') }}
            </p>
            <div class="text-muted-600 dark:text-muted-400 space-y-1">
              <p>
                <span class="font-medium">{{ $t('Latitude') }}:</span>
                {{ currentLocation.lat.toFixed(6) }}
              </p>
              <p>
                <span class="font-medium">{{ $t('Longitude') }}:</span>
                {{ currentLocation.lon.toFixed(6) }}
              </p>
              <p class="text-xs text-muted-400">
                {{ $t('Last updated') }}: {{ lastUpdate }}
              </p>
            </div>
            <BaseButton
              :href="`https://www.google.com/maps?q=${currentLocation.lat},${currentLocation.lon}`"
              target="_blank"
              color="primary"
              size="sm"
              class="mt-4"
            >
              <Icon name="ph:map-trifold" class="h-4 w-4 mr-2" />
              {{ $t('View on map') }}
            </BaseButton>
          </div>
        </div>
      </BaseCard>

      <!-- Telemetry History -->
      <BaseCard v-if="telemetryData.length > 0" class="p-6">
        <div class="flex items-center justify-between mb-4">
          <BaseHeading as="h4" size="md" weight="semibold">
            {{ $t('History') }} ({{ telemetryData.length }} {{ $t('record') }})
          </BaseHeading>
        </div>

        <div class="nui-slimscroll overflow-x-auto">
          <ag-grid-vue
            :class="`ag-theme-quartz${
              $colorMode.value === 'light' ? '' : '-dark'
            }`"
            style="width: 100%; height: auto"
            dom-layout="autoHeight"
            :column-defs="historyColumnDefs"
            :default-col-def="historyDefaultColDef"
            :row-data="telemetryData"
            :pagination="true"
            :pagination-page-size="itemsPerPage"
            :suppress-cell-focus="true"
            @grid-ready="onHistoryGridReady"
            @column-moved="onHistoryColumnMoved"
          />
        </div>
      </BaseCard>

      <!-- Export Buttons -->
      <div
        class="flex items-center gap-2 border-l border-muted-300 dark:border-muted-700 pl-3"
      >
        <!-- Tracking Fields Config Button -->
        <AssetTrackingFieldsConfig :assetId="assetId" />

        <BaseButton
          size="sm"
          color="success"
          @click="exportToExcel"
          :disabled="loading || telemetryData.length === 0"
        >
          <Icon name="ph:file-xls" class="h-4 w-4" />
          <span class="ml-1.5">{{ $t('Excel') }}</span>
        </BaseButton>

        <BaseButton
          size="sm"
          color="info"
          @click="exportToJSON"
          :disabled="loading || telemetryData.length === 0"
        >
          <Icon name="ph:file-js" class="h-4 w-4" />
          <span class="ml-1.5">{{ $t('JSON') }}</span>
        </BaseButton>
      </div>
    </div>

    <!-- No Data State -->
    <BaseCard v-else class="p-12">
      <div class="text-center space-y-4">
        <Icon
          name="ph:database"
          class="h-16 w-16 mx-auto mb-4 text-muted-400"
        />
        <div>
          <p
            class="text-muted-800 dark:text-muted-100 font-semibold text-lg mb-2"
          >
            {{ $t('No information available') }}
          </p>
        </div>
        <div class="flex justify-center gap-3 mt-6">
          <BaseButton color="primary" @click="OwnFormatImportRef?.openModal()">
            <Icon name="ph:upload" class="h-4 w-4 mr-2" />
            {{ $t('Format') }}
          </BaseButton>
          <BaseButton color="default" @click="importRef?.openModal()">
            <Icon name="ph:cloud-arrow-down" class="h-4 w-4 mr-2" />
            {{ $t('Data') }}
          </BaseButton>
        </div>
      </div>
    </BaseCard>
  </div>
</template>

<style scoped>
.own-tracking {
  width: 100%;
}
</style>
