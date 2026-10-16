<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import * as XLSX from 'xlsx'

const { t } = useI18n({ useScope: 'global' })
const { getItems, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const toaster = useToaster()
const props = defineProps({
  assetId: {
    type: [Number, String],
    required: true,
  },
})

const emit = defineEmits(['imported'])

const isModalOpen = ref(false)
const importMethod = ref('excel') // 'json', 'csv', or 'excel' - default to excel
const jsonInput = ref('')
const csvInput = ref('')
const excelInput = ref('')
const fileInput = ref<HTMLInputElement | null>(null)
const error = ref<string | null>(null)
const success = ref(false)
const importedCount = ref(0)
const isDragging = ref(false)
const trackingFields = ref<any[]>([])
const loadingFields = ref(false)
const loading = ref(false)
const loadingFile = ref(false)

// Check if file is loaded for current import method
const isFileLoaded = computed(() => {
  if (importMethod.value === 'json') {
    return jsonInput.value.trim().length > 0
  } else if (importMethod.value === 'csv') {
    return csvInput.value.trim().length > 0
  } else if (importMethod.value === 'excel') {
    return excelInput.value.trim().length > 0
  }
  return false
})

// Clear file inputs
const clearFileInputs = () => {
  jsonInput.value = ''
  csvInput.value = ''
  excelInput.value = ''
  error.value = null
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

const openModal = () => {
  isModalOpen.value = true
  error.value = null
  success.value = false
}

const closeModal = () => {
  isModalOpen.value = false
  clearFileInputs()
  success.value = false
}

// Clear inputs when switching import method
watch(importMethod, () => {
  error.value = null
  success.value = false
  if (fileInput.value) {
    fileInput.value.value = ''
  }
})

// Handle file upload
const handleFileUpload = async (event: any) => {
  const file = event.target.files[0]
  if (!file) return
  await processFile(file)
}

// Process file (used by both upload and drag-drop)
const processFile = async (file: File) => {
  error.value = null
  loadingFile.value = true

  try {
    if (file.name.endsWith('.json')) {
      const text = await file.text()
      importMethod.value = 'json'
      jsonInput.value = text
    } else if (file.name.endsWith('.csv')) {
      const text = await file.text()
      importMethod.value = 'csv'
      csvInput.value = text
    } else if (file.name.endsWith('.xlsx') || file.name.endsWith('.xls')) {
      importMethod.value = 'excel'
      // Read Excel file
      const arrayBuffer = await file.arrayBuffer()
      const workbook = XLSX.read(arrayBuffer, { type: 'array' })
      const firstSheet = workbook.Sheets[workbook.SheetNames[0]]
      const csvData = XLSX.utils.sheet_to_csv(firstSheet)
      excelInput.value = csvData
    } else {
      error.value = 'JSON, CSV эсвэл Excel файл оруулна уу'
    }
  } catch (e: any) {
    error.value = 'Файл уншихад алдаа гарлаа: ' + e.message
  } finally {
    loadingFile.value = false
  }
}

// Drag and drop handlers
const handleDragOver = (event: DragEvent) => {
  event.preventDefault()
  if (!isFileLoaded.value) {
    isDragging.value = true
  }
}

const handleDragLeave = (event: DragEvent) => {
  event.preventDefault()
  isDragging.value = false
}

const handleDrop = async (event: DragEvent) => {
  event.preventDefault()
  isDragging.value = false

  if (isFileLoaded.value) {
    return // Don't allow drop if file already loaded
  }

  const files = event.dataTransfer?.files
  if (files && files.length > 0) {
    await processFile(files[0])
  }
}

// Parse JSON data
const parseJsonData = (jsonText: string) => {
  try {
    const data = JSON.parse(jsonText)
    const records = []

    // Support different JSON formats
    if (data.telemetry && Array.isArray(data.telemetry)) {
      // Our custom format
      records.push(...data.telemetry)
    } else if (data.result && Array.isArray(data.result)) {
      // Flespi API format
      records.push(...data.result)
    } else if (Array.isArray(data)) {
      // Direct array format
      records.push(...data)
    } else {
      throw new Error('Дэмжигдээгүй JSON формат')
    }

    return records
  } catch (e: any) {
    throw new Error('JSON формат буруу байна: ' + e.message)
  }
}

// Parse CSV data - flexible parser for any columns
const parseCsvData = (csvText: string) => {
  try {
    const lines = csvText.trim().split('\n')
    if (lines.length < 2) {
      throw new Error('CSV дата хоосон байна')
    }

    const headers = lines[0].split(',').map((h: string) => h.trim())
    const records: any[] = []

    for (let i = 1; i < lines.length; i++) {
      const line = lines[i].trim()
      if (!line) continue // Skip empty lines

      const values = line.split(',').map((v: string) => v.trim())
      const record: any = {}

      headers.forEach((header: string, index: number) => {
        const value = values[index]
        if (!value) return // Skip empty values

        // Convert to appropriate type
        if (header === 'timestamp' || header === 'dated_time') {
          // Try to parse as timestamp
          const numValue = parseInt(value)
          if (!isNaN(numValue)) {
            record[header] = numValue
          } else {
            // Might be ISO date string
            record[header] = value
          }
        } else if (!isNaN(parseFloat(value)) && value !== '') {
          record[header] = parseFloat(value)
        } else {
          record[header] = value
        }
      })

      // Keep record with all its fields (no mapping to specific format)
      if (Object.keys(record).length > 0) {
        records.push(record)
      }
    }

    return records
  } catch (e: any) {
    throw new Error('CSV формат буруу байна: ' + e.message)
  }
}

// Process and save imported data
const processImport = async () => {
  error.value = null
  success.value = false
  loading.value = true

  console.log('🔄 Import started, loading:', loading.value)

  try {
    let records = []

    if (importMethod.value === 'json') {
      if (!jsonInput.value.trim()) {
        throw new Error('JSON дата оруулна уу')
      }
      records = parseJsonData(jsonInput.value)
    } else if (importMethod.value === 'csv') {
      if (!csvInput.value.trim()) {
        throw new Error('CSV дата оруулна уу')
      }
      records = parseCsvData(csvInput.value)
    } else if (importMethod.value === 'excel') {
      if (!excelInput.value.trim()) {
        throw new Error('Excel файл сонгоно уу')
      }
      // Excel файлыг CSV болгон уншсан байгаа тул CSV parser ашиглана
      records = parseCsvData(excelInput.value)
    }

    if (records.length === 0) {
      throw new Error('Дата олдсонгүй')
    }

    console.log(
      `📊 Parsed ${records.length} records from ${importMethod.value}`,
    )

    console.log(
      'Importing data for asset:',
      props.assetId,
      'type:',
      typeof props.assetId,
    )

    // Prepare data for Asset_field_data_json (individual rows)
    const assetFieldDataRecords = records.map((record) => {
      // Ensure asset ID is a proper integer
      const assetId = parseInt(String(props.assetId))
      if (isNaN(assetId)) {
        throw new Error(`Invalid asset ID: ${props.assetId}`)
      }

      // Parse timestamp properly
      let timestampUnix: number // For bigint field
      let timestampISO: string // For datetime field

      if (record.timestamp) {
        const tsValue = String(record.timestamp).trim()

        // Try parsing as Unix timestamp (number)
        const ts = parseInt(tsValue)
        if (!isNaN(ts)) {
          // Check if timestamp is in reasonable range (after year 2000)
          if (ts > 946684800 && ts < 9999999999) {
            // Unix timestamp in seconds (10 digits)
            timestampUnix = ts
            timestampISO = new Date(ts * 1000).toISOString()
          } else if (ts > 946684800000) {
            // Unix timestamp in milliseconds (13 digits)
            timestampUnix = Math.floor(ts / 1000)
            timestampISO = new Date(ts).toISOString()
          } else {
            // Invalid timestamp, use current time
            console.warn(
              `Invalid timestamp value: ${record.timestamp}, using current time`,
            )
            const now = Date.now()
            timestampUnix = Math.floor(now / 1000)
            timestampISO = new Date(now).toISOString()
          }
        } else {
          // Try parsing as date string (e.g., "2024-03-28 10:00:00" or "2024-03-28T10:00:00")
          try {
            const date = new Date(tsValue)
            if (!isNaN(date.getTime())) {
              timestampUnix = Math.floor(date.getTime() / 1000)
              timestampISO = date.toISOString()
            } else {
              console.warn(
                `Invalid date string: ${tsValue}, using current time`,
              )
              const now = Date.now()
              timestampUnix = Math.floor(now / 1000)
              timestampISO = new Date(now).toISOString()
            }
          } catch (e) {
            console.warn(
              `Failed to parse timestamp: ${tsValue}, using current time`,
            )
            const now = Date.now()
            timestampUnix = Math.floor(now / 1000)
            timestampISO = new Date(now).toISOString()
          }
        }
      } else if (record.dated_time) {
        // Try to parse dated_time if timestamp is missing
        try {
          const date = new Date(record.dated_time)
          if (!isNaN(date.getTime())) {
            timestampUnix = Math.floor(date.getTime() / 1000)
            timestampISO = date.toISOString()
          } else {
            const now = Date.now()
            timestampUnix = Math.floor(now / 1000)
            timestampISO = new Date(now).toISOString()
          }
        } catch (e) {
          const now = Date.now()
          timestampUnix = Math.floor(now / 1000)
          timestampISO = new Date(now).toISOString()
        }
      } else {
        const now = Date.now()
        timestampUnix = Math.floor(now / 1000)
        timestampISO = new Date(now).toISOString()
      }

      // Build field_values dynamically from all record fields (except timestamp)
      const fieldValues: any = {
        dated_time: timestampISO, // Always include ISO timestamp for display
      }

      // Add all other fields from the record
      Object.keys(record).forEach((key) => {
        // Skip timestamp as it's used as main timestamp field
        if (key !== 'timestamp' && key !== 'dated_time') {
          fieldValues[key] = record[key]
        }
      })

      // Add GPS fields if they exist (for backward compatibility)
      if (record['position.latitude'])
        fieldValues.latitude = record['position.latitude']
      if (record['position.longitude'])
        fieldValues.longitude = record['position.longitude']
      if (record['position.speed']) fieldValues.speed = record['position.speed']
      if (record['fuel.level']) fieldValues.fuel_level = record['fuel.level']
      if (record['engine.hours'])
        fieldValues.engine_hours = record['engine.hours']
      if (record['position.odometer'])
        fieldValues.odometer = record['position.odometer']
      if (record['position.altitude'])
        fieldValues.altitude = record['position.altitude']
      if (record['position.direction'])
        fieldValues.direction = record['position.direction']
      if (record['position.satellites'])
        fieldValues.satellites = record['position.satellites']

      return {
        asset: assetId,
        timestamp: timestampUnix, // bigint - Unix timestamp in seconds (number)
        timestamp_date: timestampISO, // datetime - ISO date string
        field_values: fieldValues,
        import_source: importMethod.value,
        company_id: myCompanyId,
      }
    })

    console.log('Asset_field_data_json sample:', assetFieldDataRecords[0])

    // 1️⃣ Save to Asset_field_data_json - individual rows for querying/filtering
    console.log(
      `💾 Saving ${assetFieldDataRecords.length} records to Asset_field_data_json...`,
    )
    await createItems({
      collection: 'Asset_field_data_json',
      items: assetFieldDataRecords,
    })
    console.log('✅ Asset_field_data_json saved')

    // 2️⃣ Save to Datahub_history - snapshot for audit trail
    const historySnapshot = {
      asset: parseInt(String(props.assetId)),
      snapshot_type: 'tracking_import',
      snapshot_at: new Date().toISOString(),
      data_snapshot: assetFieldDataRecords,
      source: importMethod.value,
      record_count: records.length,
      company_id: myCompanyId,
    }

    console.log('💾 Saving snapshot to Datahub_history...')
    await createItems({
      collection: 'Datahub_history',
      items: [historySnapshot],
    })
    console.log('✅ Datahub_history saved')

    console.log('✅ Import completed successfully')

    importedCount.value = records.length
    success.value = true

    // Import дуусаад server-side monitoring alert checker дуудна (fire-and-forget)
    // try {
    //   await $fetch('/api/trigger-monitoring-alerts', {
    //     method: 'POST',
    //     body: { assetId: props.assetId },
    //   })
    // } catch (_e) {
    //   // checker ажилсан эсэх нь import-ийн үр дүнд нөлөөлөхгүй
    // }

    emit('imported', records.length)

    setTimeout(() => {
      closeModal()
    }, 2000)
  } catch (e: any) {
    console.error('❌ Import error:', e)
    error.value = e.message
  } finally {
    loading.value = false
    console.log('🏁 Import finished, loading:', loading.value)
  }
}

// Download sample files
const downloadSampleJson = () => {
  let sampleData: any

  if (trackingFields.value.length > 0) {
    // Use custom tracking fields
    const record1: any = {
      timestamp: '2024-03-28 10:00:00',
    }
    const record2: any = {
      timestamp: '2024-03-28 10:30:00',
    }

    trackingFields.value.forEach((field) => {
      record1[field.field_key] = 0
      record2[field.field_key] = 0
    })

    sampleData = {
      description: `Дата импортлох формат - ${trackingFields.value.length} custom талбар`,
      result: [record1, record2],
    }
  } else {
    // Default GPS format
    sampleData = {
      description: 'Дата импортлох формат - GPS tracking',
      result: [
        {
          timestamp: '2024-03-28 10:00:00',
          latitude: 47.9184,
          longitude: 106.9177,
          speed: 45.5,
          fuel_level: 75.2,
        },
        {
          timestamp: '2024-03-28 10:30:00',
          latitude: 47.9185,
          longitude: 106.9178,
          speed: 50.0,
          fuel_level: 75.1,
        },
      ],
    }
  }

  const blob = new Blob([JSON.stringify(sampleData, null, 2)], {
    type: 'application/json',
  })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `tracking_data_sample_${props.assetId}.json`
  a.click()
  URL.revokeObjectURL(url)

  if (trackingFields.value.length > 0) {
    toaster.show({
      title: t('Success'),
      message: t(
        `${trackingFields.value.length} field JSON example downloaded`,
      ),
      color: 'success',
      icon: 'ph:download',
      closable: true,
    })
  }
}

const downloadSampleCsv = () => {
  let csvContent: string

  if (trackingFields.value.length > 0) {
    // Use custom tracking fields
    const headers = [
      'timestamp',
      ...trackingFields.value.map((f) => f.field_key),
    ]
    const headerRow = headers.join(',')
    const row1 = [
      '2024-03-28 10:00:00',
      ...trackingFields.value.map(() => '0'),
    ].join(',')
    const row2 = [
      '2024-03-28 10:30:00',
      ...trackingFields.value.map(() => '0'),
    ].join(',')

    csvContent = `${headerRow}\n${row1}\n${row2}`
  } else {
    // Default GPS format
    csvContent = `timestamp,latitude,longitude,speed,fuel_level
2024-03-28 10:00:00,47.9184,106.9177,45.5,75.2
2024-03-28 10:30:00,47.9185,106.9178,50.0,75.1`
  }

  const blob = new Blob([csvContent], { type: 'text/csv' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `tracking_data_sample_${props.assetId}.csv`
  a.click()
  URL.revokeObjectURL(url)

  if (trackingFields.value.length > 0) {
    toaster.show({
      title: t('Success'),
      message: t(`${trackingFields.value.length} field CSV example downloaded`),
      color: 'success',
      icon: 'ph:download',
      closable: true,
    })
  }
}

// Load tracking fields configuration
const loadTrackingFields = async () => {
  if (!props.assetId) return

  try {
    loadingFields.value = true
    const response = await getItems<any>({
      collection: 'Device_tracking_fields',
      params: {
        filter: {
          asset: { _eq: props.assetId },
          company_id: { _eq: myCompanyId },
        },
        sort: ['sort_order'],
      },
    })

    const items = Array.isArray(response)
      ? response
      : (response as any)?.data || []
    trackingFields.value = items
  } catch (e) {
    console.error('Error loading tracking fields:', e)
  } finally {
    loadingFields.value = false
  }
}

const downloadSampleExcel = () => {
  try {
    // Use custom tracking fields if available, otherwise use default fields
    let headers: string[]
    let mnNames: string[]
    let units: string[]

    if (trackingFields.value.length > 0) {
      // Custom fields from Device_tracking_fields
      headers = [
        'timestamp',
        ...trackingFields.value.map((f) => f.field_key || ''),
      ]
      mnNames = [
        'Date & time',
        ...trackingFields.value.map(
          (f) => f.field_name_mn || f.field_key || '',
        ),
      ]
      units = [
        'YYYY-MM-DD HH:MM:SS',
        ...trackingFields.value.map((f) => (f.unit ? `(${f.unit})` : '')),
      ]
    } else {
      // Default GPS fields
      headers = [
        'timestamp',
        'latitude',
        'longitude',
        'speed',
        'fuel_level',
        'engine_hours',
        'odometer',
        'altitude',
        'direction',
        'satellites',
      ]
      mnNames = [
        'Date & time',
        'Latitude',
        'Longitude',
        'Хурд (км/ц)',
        'Түлш (%)',
        'Хөдөлгүүр (ц)',
        'Гүйлт (м)',
        'Өндөр (м)',
        'Чиглэл (°)',
        'Хиймэл дагуул',
      ]
      units = [
        'YYYY-MM-DD HH:MM:SS',
        '',
        '',
        'km/h',
        '%',
        'hours',
        'meters',
        'meters',
        'degrees',
        'count',
      ]
    }

    // Create sample data rows with current date
    const now = new Date()
    const formatDateTime = (date: Date) => {
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      const hours = String(date.getHours()).padStart(2, '0')
      const minutes = String(date.getMinutes()).padStart(2, '0')
      const seconds = String(date.getSeconds()).padStart(2, '0')
      return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
    }

    const sampleRow1 = [formatDateTime(now), ...headers.slice(1).map(() => '')]
    const sampleRow2 = [
      formatDateTime(new Date(now.getTime() + 30 * 60 * 1000)), // +30 min
      ...headers.slice(1).map(() => ''),
    ]
    const sampleRow3 = [
      formatDateTime(new Date(now.getTime() + 60 * 60 * 1000)), // +60 min
      ...headers.slice(1).map(() => ''),
    ]

    // Create worksheet
    const ws = XLSX.utils.aoa_to_sheet([
      headers,
      mnNames,
      units,
      sampleRow1,
      sampleRow2,
      sampleRow3,
    ])

    // Set column widths
    const colWidths = [
      { wch: 20 },
      ...headers.slice(1).map(() => ({ wch: 15 })),
    ]
    ws['!cols'] = colWidths

    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, 'GPS Data')

    const fileName = `tracking_data_template_${props.assetId}_${
      new Date().toISOString().split('T')[0]
    }.xlsx`
    XLSX.writeFile(wb, fileName)

    if (trackingFields.value.length > 0) {
      toaster.show({
        title: t('Success'),
        message: t(
          `${trackingFields.value.length} column Excel template downloaded`,
        ),
        color: 'success',
        icon: 'ph:download',
        closable: true,
      })
    }
  } catch (e: any) {
    console.error('Error creating Excel template:', e)
    toaster.show({
      title: t('Error'),
      message: t('Error creating Excel template: ') + e.message,
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  }
}

// Load tracking fields on mount
onMounted(() => {
  if (props.assetId) {
    loadTrackingFields()
  }
})

defineExpose({
  openModal,
})
</script>

<template>
  <div>
    <BaseButton color="primary" @click="openModal">
      <Icon name="ph:upload" class="h-4 w-4 mr-2" />
      {{ $t('Data') }}
    </BaseButton>

    <TairoModal :open="isModalOpen" size="xl" @close="closeModal">
      <template #header>
        <div class="flex w-full items-center justify-between">
          <h3
            class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
          >
            {{ $t('Import data') }}
          </h3>
          <BaseButtonClose @click="closeModal" />
        </div>
      </template>

      <div v-show="isModalOpen" class="space-y-6 max-h-[70vh] overflow-y-auto">
        <!-- Import Method Selection -->
        <div>
          <!-- Tabs Style Selector -->
          <div class="flex gap-2 mb-4">
            <button
              type="button"
              :class="[
                'flex-1 px-4 py-3 rounded-lg font-medium transition-all',
                importMethod === 'excel'
                  ? 'bg-primary-500 text-white shadow-lg shadow-primary-500/30'
                  : 'bg-muted-100 dark:bg-muted-800 text-muted-600 dark:text-muted-400 hover:bg-muted-200 dark:hover:bg-muted-700',
              ]"
              @click="importMethod = 'excel'"
            >
              <div class="flex items-center justify-center gap-2">
                <Icon name="ph:file-xls" class="h-5 w-5" />
                <span>Excel</span>
              </div>
            </button>
            <button
              type="button"
              :class="[
                'flex-1 px-4 py-3 rounded-lg font-medium transition-all',
                importMethod === 'json'
                  ? 'bg-primary-500 text-white shadow-lg shadow-primary-500/30'
                  : 'bg-muted-100 dark:bg-muted-800 text-muted-600 dark:text-muted-400 hover:bg-muted-200 dark:hover:bg-muted-700',
              ]"
              @click="importMethod = 'json'"
            >
              <div class="flex items-center justify-center gap-2">
                <Icon name="ph:file-code" class="h-5 w-5" />
                <span>JSON</span>
              </div>
            </button>

            <button
              type="button"
              :class="[
                'flex-1 px-4 py-3 rounded-lg font-medium transition-all',
                importMethod === 'csv'
                  ? 'bg-primary-500 text-white shadow-lg shadow-primary-500/30'
                  : 'bg-muted-100 dark:bg-muted-800 text-muted-600 dark:text-muted-400 hover:bg-muted-200 dark:hover:bg-muted-700',
              ]"
              @click="importMethod = 'csv'"
            >
              <div class="flex items-center justify-center gap-2">
                <Icon name="ph:file-csv" class="h-5 w-5" />
                <span>CSV</span>
              </div>
            </button>
          </div>

          <!-- Format Description -->
          <div
            class="bg-info-50 dark:bg-info-900/20 border border-info-200 dark:border-info-800 rounded-lg p-3 mb-4"
          >
            <div class="flex items-start gap-2">
              <Icon
                name="ph:info"
                class="h-5 w-5 text-info-500 flex-shrink-0 mt-0.5"
              />
              <div class="text-sm text-info-700 dark:text-info-300">
                <p v-if="importMethod === 'json'" class="font-medium mb-1">
                  {{ $t('JSON format') }}
                </p>
                <p v-else-if="importMethod === 'csv'" class="font-medium mb-1">
                  {{ $t('CSV format') }}
                </p>
                <p v-else class="font-medium mb-1">
                  {{ $t('Excel format') }}
                </p>
                <p class="text-xs text-info-600 dark:text-info-400">
                  <span v-if="importMethod === 'json'">
                    {{
                      $t(
                        'Supports JSON format data import from Flespi, Wialon and other systems.',
                      )
                    }}
                  </span>
                  <span v-else-if="importMethod === 'csv'">
                    {{
                      $t(
                        'Import data from CSV file or text. First row must be field name (header).',
                      )
                    }}
                  </span>
                  <span v-else>
                    {{
                      $t(
                        'Import Excel file (.xlsx, .xls). First row must be field name (header).',
                      )
                    }}
                  </span>
                </p>
              </div>
            </div>
          </div>
        </div>

        <!-- File Upload -->
        <div :key="`upload-${importMethod}`">
          <!-- Loading File Indicator -->
          <div
            v-if="loadingFile"
            class="bg-primary-50 dark:bg-primary-900/20 border-2 border-primary-500 rounded-lg p-6 text-center"
          >
            <Icon
              name="svg-spinners:90-ring-with-bg"
              class="text-primary-500 mx-auto mb-3 h-12 w-12"
            />
            <p class="text-primary-700 dark:text-primary-300 font-medium mb-2">
              {{ $t('Reading file...') }}
            </p>
            <p class="text-primary-600 dark:text-primary-400 text-sm">
              {{ $t('Please wait') }}
            </p>
          </div>

          <!-- File Loaded Success Banner -->
          <div
            v-else-if="isFileLoaded"
            class="bg-success-50 dark:bg-success-900/20 border-2 border-success-500 rounded-lg p-6 text-center"
          >
            <Icon
              name="ph:check-circle"
              class="text-success-500 mx-auto mb-3 h-12 w-12"
            />
            <p class="text-success-700 dark:text-success-300 font-medium mb-2">
              {{ $t('File read successfully') }}
            </p>
            <BaseButton size="sm" color="default" @click="clearFileInputs">
              <Icon name="ph:x-circle" class="h-4 w-4 mr-1" />
              {{ $t('Clear') }}
            </BaseButton>
          </div>

          <!-- Drag & Drop Area -->
          <label
            v-else
            :class="[
              'block w-full cursor-pointer rounded-lg border-2 border-dashed p-8 text-center transition-all duration-200',
              isDragging
                ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20 scale-105'
                : 'border-muted-300 dark:border-muted-700 hover:border-primary-500 dark:hover:border-primary-500',
            ]"
            @dragover="handleDragOver"
            @dragleave="handleDragLeave"
            @drop="handleDrop"
          >
            <Icon
              name="ph:cloud-arrow-up"
              :class="[
                'mx-auto mb-4 h-12 w-12 transition-all duration-200',
                isDragging ? 'text-primary-500 scale-110' : 'text-muted-400',
              ]"
            />
            <p
              :class="[
                'font-medium mb-2 transition-colors',
                isDragging
                  ? 'text-primary-600 dark:text-primary-400'
                  : 'text-muted-600 dark:text-muted-400',
              ]"
            >
              {{
                isDragging
                  ? $t('Drop file here')
                  : $t('Select or drag and drop file')
              }}
            </p>
            <p class="text-muted-400 text-sm">
              {{
                importMethod === 'json'
                  ? $t('JSON file (.json)')
                  : importMethod === 'csv'
                  ? $t('CSV file (.csv)')
                  : $t('Excel file (.xlsx, .xls)')
              }}
            </p>
            <input
              ref="fileInput"
              type="file"
              class="hidden"
              :accept="
                importMethod === 'json'
                  ? '.json'
                  : importMethod === 'csv'
                  ? '.csv'
                  : '.xlsx,.xls'
              "
              @change="handleFileUpload"
            />
          </label>
        </div>

        <!-- JSON Input -->
        <div v-if="importMethod === 'json'" class="space-y-3">
          <div class="flex items-center justify-between">
            <div>
              <label class="text-muted-700 dark:text-muted-300 font-medium">
                {{ $t('JSON data') }}
              </label>
              <p
                v-if="trackingFields.length > 0"
                class="text-xs text-primary-600 dark:text-primary-400 mt-0.5"
              >
                <Icon name="ph:check-circle" class="h-3 w-3 inline mr-1" />
                {{ trackingFields.length }}
                {{ $t('configured fields will be used') }}
              </p>
            </div>
            <BaseButton size="sm" @click="downloadSampleJson">
              <Icon name="ph:download" class="h-4 w-4 mr-1" />
              {{ $t('Download example') }}
            </BaseButton>
          </div>
        </div>

        <!-- CSV Input -->
        <div v-if="importMethod === 'csv'" class="space-y-3">
          <div class="flex items-center justify-between">
            <div>
              <label class="text-muted-700 dark:text-muted-300 font-medium">
                {{ $t('CSV data') }}
              </label>
              <p
                v-if="trackingFields.length > 0"
                class="text-xs text-primary-600 dark:text-primary-400 mt-0.5"
              >
                <Icon name="ph:check-circle" class="h-3 w-3 inline mr-1" />
                {{ trackingFields.length }}
                {{ $t('configured fields will be used') }}
              </p>
            </div>
            <BaseButton size="sm" @click="downloadSampleCsv">
              <Icon name="ph:download" class="h-4 w-4 mr-1" />
              {{ $t('Download example') }}
            </BaseButton>
          </div>
        </div>

        <!-- Excel Input -->
        <div v-if="importMethod === 'excel'" class="space-y-3">
          <div class="flex items-center justify-between">
            <div>
              <label class="text-muted-700 dark:text-muted-300 font-medium">
                {{ $t('Excel file') }}
              </label>
              <p
                v-if="trackingFields.length > 0"
                class="text-xs text-primary-600 dark:text-primary-400 mt-0.5"
              >
                <Icon name="ph:check-circle" class="h-3 w-3 inline mr-1" />
                {{ trackingFields.length }}
                {{ $t('configured fields will be used') }}
              </p>
            </div>
            <BaseButton size="sm" @click="downloadSampleExcel">
              <Icon name="ph:download" class="h-4 w-4 mr-1" />
              {{ $t('Download example') }}
            </BaseButton>
          </div>
        </div>

        <!-- Error Message -->
        <BaseMessage v-if="error" type="danger" class="mb-4">
          <Icon name="ph:warning-circle" class="h-5 w-5 mr-2" />
          {{ error }}
        </BaseMessage>

        <!-- Success Message -->
        <BaseMessage v-if="success" type="success" class="mb-4">
          <Icon name="ph:check-circle" class="h-5 w-5 mr-2" />
          {{ importedCount }} {{ $t('records imported successfully') }}
        </BaseMessage>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-3">
          <BaseButton color="default" :disabled="loading" @click="closeModal">
            {{ $t('Cancel') }}
          </BaseButton>
          <BaseButton
            color="primary"
            :loading="loading"
            :disabled="loading"
            @click="processImport"
          >
            <Icon v-if="!loading" name="ph:upload" class="h-4 w-4 mr-2" />
            {{ loading ? $t('Importing...') : $t('Import') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>
  </div>
</template>
