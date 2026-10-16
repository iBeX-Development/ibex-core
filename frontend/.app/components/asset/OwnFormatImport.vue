<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import * as XLSX from 'xlsx'

const { t } = useI18n({ useScope: 'global' })

const props = defineProps({
  assetId: {
    type: [Number, String],
    required: true,
  },
})

const emit = defineEmits(['imported'])

const isModalOpen = ref(false)
const importMethod = ref('excel') // 'json' or 'excel'
const jsonInput = ref('')
const excelInput = ref('')
const fileInput = ref<HTMLInputElement | null>(null)
const error = ref<string | null>(null)
const success = ref(false)
const importedCount = ref(0)
const isDragging = ref(false)
const loading = ref(false)

// Step tracking
const step = ref(1) // 1: Upload file, 2: Preview & Configure, 3: Save
const detectedFields = ref<any[]>([]) // Fields detected from file
const sampleData = ref<any[]>([]) // Sample rows for preview
const saveToFieldConfig = ref(true) // Save columns to Device_tracking_fields
const deviceFormatCode = ref('') // Assets.device_format_code / Device_tracking_fields.code

const { getItems, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

// Sample JSON format for reference
const sampleJsonFormat = {
  fields: [
    {
      field_key: 'timestamp',
      field_name_mn: 'Түүхэн цагийн цаг',
      field_name_en: 'Timestamp',
      unit: '',
    },
    {
      field_key: 'latitude',
      field_name_mn: 'Latitude',
      field_name_en: 'Latitude',
      unit: '',
    },
    {
      field_key: 'longitude',
      field_name_mn: 'Longitude',
      field_name_en: 'Longitude',
      unit: '',
    },
    {
      field_key: 'speed',
      field_name_mn: 'Хурд (км/ц)',
      field_name_en: 'Speed (km/h)',
      unit: 'km/h',
    },
    {
      field_key: 'fuel_level',
      field_name_mn: 'Түлш (%)',
      field_name_en: 'Fuel Level (%)',
      unit: '%',
    },
    {
      field_key: 'engine_hours',
      field_name_mn: 'Хөдөлгүүрийн цаг (ц)',
      field_name_en: 'Engine Hours (h)',
      unit: 'hour',
    },
    {
      field_key: 'odometer',
      field_name_mn: 'Гүйлт (км)',
      field_name_en: 'Odometer (km)',
      unit: 'km',
    },
    {
      field_key: 'altitude',
      field_name_mn: 'Өндөр (м)',
      field_name_en: 'Altitude (m)',
      unit: 'm',
    },
    {
      field_key: 'direction',
      field_name_mn: 'Чиглэл (°)',
      field_name_en: 'Direction (°)',
      unit: '°',
    },
  ],
  data: [
    {
      timestamp: '2024-04-03T10:00:00Z',
      latitude: 47.9184,
      longitude: 106.9177,
      speed: 45,
      fuel_level: 75,
      engine_hours: 120,
      odometer: 1500,
      altitude: 1350,
      direction: 90,
      asset: 1,
    },
  ],
}

// Default field mappings
const defaultFieldMappings: Record<string, any> = {
  timestamp: { mn: 'Түүхэн цагийн цаг', en: 'Timestamp', unit: '' },
  latitude: { mn: 'Latitude', en: 'Latitude', unit: '' },
  longitude: { mn: 'Longitude', en: 'Longitude', unit: '' },
  speed: { mn: 'Хурд (км/ц)', en: 'Speed (km/h)', unit: 'km/h' },
  fuel_level: { mn: 'Түлш (%)', en: 'Fuel Level (%)', unit: '%' },
  engine_hours: {
    mn: 'Хөдөлгүүрийн цаг (ц)',
    en: 'Engine Hours (h)',
    unit: 'hour',
  },
  odometer: { mn: 'Гүйлт (км)', en: 'Odometer (km)', unit: 'km' },
  altitude: { mn: 'Өндөр (м)', en: 'Altitude (m)', unit: 'm' },
  direction: { mn: 'Чиглэл (°)', en: 'Direction (°)', unit: '°' },
  satellites: { mn: 'Дагуул', en: 'Satellites', unit: '' },
  temperature: { mn: 'Температур', en: 'Temperature', unit: '°C' },
}

// Check if file is loaded
const isFileLoaded = computed(() => {
  if (importMethod.value === 'json') {
    return jsonInput.value.trim().length > 0
  } else if (importMethod.value === 'excel') {
    return excelInput.value.trim().length > 0
  }
  return false
})

// Clear file inputs
const clearFileInputs = () => {
  jsonInput.value = ''
  excelInput.value = ''
  error.value = null
  detectedFields.value = []
  sampleData.value = []
  step.value = 1
  if (fileInput.value) {
    fileInput.value.value = ''
  }
}

const openModal = () => {
  isModalOpen.value = true
  error.value = null
  success.value = false
  step.value = 1
  deviceFormatCode.value = ''
  clearFileInputs()
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
  clearFileInputs()
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

  try {
    if (file.name.endsWith('.json')) {
      const text = await file.text()
      importMethod.value = 'json'
      jsonInput.value = text
      await analyzeJsonFile(text)
    } else if (file.name.endsWith('.xlsx') || file.name.endsWith('.xls')) {
      importMethod.value = 'excel'
      const arrayBuffer = await file.arrayBuffer()
      const workbook = XLSX.read(arrayBuffer, { type: 'array' })
      const firstSheet = workbook.Sheets[workbook.SheetNames[0]]
      const jsonData = XLSX.utils.sheet_to_json(firstSheet)
      excelInput.value = JSON.stringify(jsonData)
      await analyzeExcelData(jsonData)
    } else {
      error.value = t('Please upload a JSON or Excel file')
    }
  } catch (e: any) {
    error.value = t('Error reading file:') + ' ' + e.message
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
    return
  }

  const files = event.dataTransfer?.files
  if (files && files.length > 0) {
    await processFile(files[0])
  }
}

// Analyze JSON file structure
const analyzeJsonFile = async (jsonText: string) => {
  try {
    const data = JSON.parse(jsonText)
    const fields: any[] = []
    let dataRecords: any[] = []

    // Check if it has our expected format with fields array
    if (data.fields && Array.isArray(data.fields)) {
      // Extract fields configuration
      data.fields.forEach((field: any) => {
        fields.push({
          field_key: field.key || field.field_key,
          field_name_mn: field.label_mn || field.field_name_mn || '',
          field_name_en: field.label_en || field.field_name_en || '',
          unit: field.unit || '',
        })
      })

      // Extract data
      if (data.data && Array.isArray(data.data)) {
        dataRecords = data.data
      }
    } else if (Array.isArray(data)) {
      // Plain array - detect fields from first object
      dataRecords = data
      if (data.length > 0) {
        const firstRow = data[0]
        Object.keys(firstRow).forEach((key) => {
          const mapping = defaultFieldMappings[key] || {
            mn: key,
            en: key,
            unit: '',
          }
          fields.push({
            field_key: key,
            field_name_mn: mapping.mn,
            field_name_en: mapping.en,
            unit: mapping.unit,
          })
        })
      }
    }

    detectedFields.value = fields
    sampleData.value = dataRecords.slice(0, 5) // First 5 rows for preview
    step.value = 2

    if (fields.length === 0) {
      throw new Error(t('No field information found'))
    }
  } catch (e: any) {
    error.value = t('Invalid JSON format:') + ' ' + e.message
  }
}

// Analyze Excel data structure
const analyzeExcelData = async (jsonData: any[]) => {
  try {
    if (!jsonData || jsonData.length === 0) {
      throw new Error('Excel file is empty')
    }

    const fields: any[] = []
    const firstRow = jsonData[0]
    const columnNames = Object.keys(firstRow)

    // Check if this is a configuration Excel file (has field_key, field_name_mn, field_name_en, unit columns)
    const isConfigFormat =
      columnNames.includes('field_key') &&
      columnNames.includes('field_name_mn') &&
      columnNames.includes('field_name_en')

    if (isConfigFormat) {
      // This is a configuration file - read each row as a field definition
      jsonData.forEach((row) => {
        // Skip header row if it was included as data (field_key value is literally "field_key")
        const fieldKeyValue = row.field_key ? String(row.field_key).trim() : ''

        if (
          fieldKeyValue !== '' &&
          fieldKeyValue !== 'field_key' && // Skip header row
          fieldKeyValue !== 'Field Key' &&
          fieldKeyValue !== 'FIELD_KEY'
        ) {
          fields.push({
            field_key: fieldKeyValue,
            field_name_mn: row.field_name_mn || fieldKeyValue,
            field_name_en: row.field_name_en || fieldKeyValue,
            unit: row.unit || '',
          })
        }
      })
      // For config format, we don't have sample data (it's configuration, not data)
      sampleData.value = []
    } else {
      // This is a data file - extract column names as fields
      Object.keys(firstRow).forEach((key) => {
        const mapping = defaultFieldMappings[
          key.toLowerCase().replace(/\s+/g, '_')
        ] || {
          mn: key,
          en: key,
          unit: '',
        }
        fields.push({
          field_key: key.toLowerCase().replace(/\s+/g, '_'),
          field_name_mn: mapping.mn,
          field_name_en: mapping.en,
          unit: mapping.unit,
        })
      })
      sampleData.value = jsonData.slice(0, 5) // First 5 rows for preview
    }

    detectedFields.value = fields
    step.value = 2
  } catch (e: any) {
    error.value = 'Excel файл уншихад алдаа гарлаа: ' + e.message
  }
}

// Save field configuration to Device_tracking_fields
const saveFieldConfiguration = async () => {
  if (!saveToFieldConfig.value || detectedFields.value.length === 0) {
    return
  }

  try {
    // Delete existing configs for this asset
    const existingResponse = await getItems<any>({
      collection: 'Device_tracking_fields',
      params: {
        filter: {
          asset: { _eq: props.assetId },
        },
      },
    })

    const existing = Array.isArray(existingResponse)
      ? existingResponse
      : (existingResponse as any)?.data || []

    if (existing.length > 0) {
      const idsToDelete = existing.map((item: any) => item.id)
      await deleteItems({
        collection: 'Device_tracking_fields',
        items: idsToDelete,
      })
    }

    // Create new configs (timestamp-ийг тусад нь хадгалдаг тул орхино)
    const fieldsToSave = detectedFields.value.filter(
      (field) => field.field_key !== 'timestamp',
    )
    const code = deviceFormatCode.value.trim() || null
    const newConfigs = fieldsToSave.map((field, index) => ({
      asset: parseInt(String(props.assetId)),
      code,
      format_name: code,
      field_key: field.field_key,
      field_name_mn: field.field_name_mn,
      field_name_en: field.field_name_en,
      unit: field.unit || '',
      is_active: true,
      sort_order: index,
      company_id: myCompanyId,
      is_shared_format: !!code,
    }))

    if (newConfigs.length > 0) {
      await createItems({
        collection: 'Device_tracking_fields',
        items: newConfigs,
      })
    }

    console.log(`${newConfigs.length} талбарын тохиргоо хадгалагдлаа`)
  } catch (e: any) {
    console.error('Field configuration хадгалахад алдаа:', e)
    throw new Error('Талбарын тохиргоо хадгалахад алдаа гарлаа')
  }
}

// Save data to Asset_field_data_json
const saveDataRecords = async () => {
  if (sampleData.value.length === 0) {
    return 0 // No data to save
  }

  try {
    // Get all data (not just sample)
    let allData: any[] = []
    if (importMethod.value === 'json') {
      const data = JSON.parse(jsonInput.value)
      if (data.data && Array.isArray(data.data)) {
        allData = data.data
      } else if (Array.isArray(data)) {
        allData = data
      }
    } else if (importMethod.value === 'excel') {
      allData = JSON.parse(excelInput.value)
    }

    // Create records for Asset_field_data_json
    const records = allData.map((row) => {
      // Extract timestamp as Unix timestamp (milliseconds)
      let timestamp = Date.now()
      if (row.timestamp) {
        timestamp = new Date(row.timestamp).getTime()
      } else if (row['Тухайн үеийн цаг'] || row['Timestamp']) {
        timestamp = new Date(
          row['Тухайн үеийн цаг'] || row['Timestamp'],
        ).getTime()
      }

      // Build field_values JSON
      const fieldValues: Record<string, any> = {}
      detectedFields.value.forEach((field) => {
        const value =
          row[field.field_key] ||
          row[field.field_name_mn] ||
          row[field.field_name_en]
        if (value !== undefined && value !== null) {
          fieldValues[field.field_key] = value
        }
      })

      return {
        asset: parseInt(String(props.assetId)),
        timestamp,
        field_values: fieldValues,
        import_source: importMethod.value,
        company_id: myCompanyId,
      }
    })

    // DUAL STORAGE STRATEGY:
    // 1. Save individual rows to Asset_field_data_json (for querying/filtering)
    await createItems({
      collection: 'Asset_field_data_json',
      items: records,
    })

    // 2. Save as snapshot to Datahub_history (for version control/history)
    const snapshot = {
      asset: parseInt(String(props.assetId)),
      snapshot_type: 'tracking_import',
      snapshot_at: Date.now(), // Unix timestamp in milliseconds
      data_snapshot: records, // Array of all imported records
      source: importMethod.value,
      record_count: records.length,
      company_id: myCompanyId,
    }

    await createItems({
      collection: 'Datahub_history',
      items: [snapshot],
    })

    return records.length
  } catch (e: any) {
    console.error('Data хадгалахад алдаа:', e)
    throw new Error('Error saving data: ' + e.message)
  }
}

// Set the asset's device_format_code so it matches Device_tracking_fields.code
const saveAssetFormatCode = async () => {
  const code = deviceFormatCode.value.trim()
  if (!code || !props.assetId) return

  const config = useRuntimeConfig()
  const { token } = useDirectusToken()
  const baseUrl = ((config.public.directus as any)?.url ?? '').replace(
    /\/$/,
    '',
  )
  await $fetch(`${baseUrl}/items/Assets/${props.assetId}`, {
    method: 'PATCH',
    body: { device_format_code: code },
    headers: token.value ? { Authorization: `Bearer ${token.value}` } : {},
  })
}

// Process and save imported data
const processImport = async () => {
  error.value = null
  success.value = false

  if (!deviceFormatCode.value.trim()) {
    error.value = t('Format code is required')
    return
  }

  loading.value = true

  try {
    let count = 0

    // Step 1: Save field configuration
    if (saveToFieldConfig.value) {
      await saveFieldConfiguration()
      await saveAssetFormatCode()
    }

    // Step 2: Save data records (only if data exists)
    if (sampleData.value.length > 0) {
      count = await saveDataRecords()
    }

    importedCount.value = count
    success.value = true
    step.value = 3

    // Import дуусаад server-side monitoring alert checker дуудна (fire-and-forget)
    // try {
    //   await $fetch('/api/trigger-monitoring-alerts', {
    //     method: 'POST',
    //     body: { assetId: props.assetId },
    //   })
    // } catch (_e) {
    //   // checker ажилсан эсэх нь import-ийн үр дүнд нөлөөлөхгүй
    // }

    emit('imported', count)

    // Close immediately if only config saved (no data), otherwise wait 2 seconds
    const delay = count === 0 ? 500 : 2000
    setTimeout(() => {
      closeModal()
    }, delay)
  } catch (e: any) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

// Go back to step 1
const backToUpload = () => {
  step.value = 1
  clearFileInputs()
}

// Download sample JSON
const downloadSampleJson = () => {
  const blob = new Blob([JSON.stringify(sampleJsonFormat, null, 2)], {
    type: 'application/json',
  })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = 'own_column_format_excel.json'
  a.click()
  URL.revokeObjectURL(url)
}

// Download sample Excel
const downloadSampleExcel = () => {
  const wb = XLSX.utils.book_new()
  const ws = XLSX.utils.aoa_to_sheet([
    ['field_key', 'field_name_mn', 'field_name_en', 'unit'],
    ['timestamp', 'Түүхэн цагийн цаг', 'Timestamp', ''],
    ['latitude', 'Latitude', 'Latitude', ''],
    ['longitude', 'Longitude', 'Longitude', ''],
    ['speed', 'Хурд (км/ц)', 'Speed (km/h)', 'km/h'],
    ['fuel_level', 'Түлш (%)', 'Fuel Level (%)', '%'],
    ['engine_hours', 'Хөдөлгүүрийн цаг (ц)', 'Engine Hours (h)', 'hour'],
    ['odometer', 'Гүйлт (км)', 'Odometer (km)', 'km'],
    ['altitude', 'Өндөр (м)', 'Altitude (m)', 'm'],
    ['direction', 'Чиглэл (°)', 'Direction (°)', '°'],
  ])
  XLSX.utils.book_append_sheet(wb, ws, 'Tracking Data')
  XLSX.writeFile(wb, 'own_column_format_excel.xlsx')
}

defineExpose({ openModal, closeModal })
</script>

<template>
  <div class="format-import">
    <BaseButton color="primary" @click="openModal" :disabled="!assetId">
      <Icon name="ph:upload" class="h-4 w-4 mr-2" />
      {{ $t('Format') }}
    </BaseButton>

    <TairoModal
      :open="isModalOpen"
      size="xl"
      @close="closeModal"
      class="overflow-y-auto"
    >
      <template #header>
        <div class="p-4 flex items-center gap-3">
          <div class="p-5 text-primary-500">
            <BaseHeading as="h3" size="sm" weight="medium">
              {{ $t('Tracking Data Fields') }}
            </BaseHeading>
            <BaseParagraph size="xs" class="text-muted-400">
              {{ $t('Import JSON/Excel file and save column configuration') }}
            </BaseParagraph>
          </div>
        </div>
      </template>

      <!-- Modal Body with Scroll -->
      <div class="max-h-[70vh] overflow-y-auto px-6">
        <!-- Step Indicator -->
        <div class="mb-6 flex items-center justify-center gap-4">
          <div class="flex items-center gap-2">
            <div
              :class="[
                'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
                step >= 1
                  ? 'bg-primary-500 text-white'
                  : 'bg-muted-200 dark:bg-muted-700 text-muted-400',
              ]"
            >
              1
            </div>
            <span class="text-sm">{{ $t('Upload file') }}</span>
          </div>
          <Icon name="ph:arrow-right" class="h-4 w-4 text-muted-400" />
          <div class="flex items-center gap-2">
            <div
              :class="[
                'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
                step >= 2
                  ? 'bg-primary-500 text-white'
                  : 'bg-muted-200 dark:bg-muted-700 text-muted-400',
              ]"
            >
              2
            </div>
            <span class="text-sm">{{ $t('Settings') }}</span>
          </div>
          <Icon name="ph:arrow-right" class="h-4 w-4 text-muted-400" />
          <div class="flex items-center gap-2">
            <div
              :class="[
                'w-8 h-8 rounded-full flex items-center justify-center text-sm font-medium',
                step >= 3
                  ? 'bg-success-500 text-white'
                  : 'bg-muted-200 dark:bg-muted-700 text-muted-400',
              ]"
            >
              3
            </div>
            <span class="text-sm">{{ $t('Save') }}</span>
          </div>
        </div>

        <!-- Error Message -->
        <div
          v-if="error"
          class="mb-4 bg-danger-50 dark:bg-danger-900/20 border border-danger-200 dark:border-danger-800 rounded-lg p-3"
        >
          <div class="flex items-center gap-2">
            <Icon name="ph:warning" class="h-5 w-5 text-danger-500" />
            <p class="text-danger-700 dark:text-danger-300 text-sm">
              {{ error }}
            </p>
          </div>
        </div>

        <!-- Success Message -->
        <div
          v-if="success"
          class="mb-4 bg-success-50 dark:bg-success-900/20 border border-success-200 dark:border-success-800 rounded-lg p-3"
        >
          <div class="flex items-center gap-2">
            <Icon name="ph:check-circle" class="h-5 w-5 text-success-500" />
            <p class="text-success-700 dark:text-success-300 text-sm">
              {{ importedCount }} {{ $t('records imported successfully') }}
            </p>
          </div>
        </div>

        <!-- Step 1: File Upload -->
        <div v-if="step === 1" class="space-y-4">
          <!-- Import Method Selection -->
          <div class="flex gap-2 mb-4 types">
            <button
              :class="[
                'flex-1 py-3 px-4 rounded-lg font-medium transition-colors',
                importMethod === 'excel'
                  ? 'bg-primary-500 text-white'
                  : 'bg-muted-100 dark:bg-muted-800 text-muted-600 hover:bg-muted-200 dark:hover:bg-muted-700',
              ]"
              @click="importMethod = 'excel'"
            >
              <div class="flex items-center justify-center gap-2">
                <Icon name="ph:file-xls" class="h-5 w-5" />
                <span>Excel</span>
              </div>
            </button>
            <button
              :class="[
                'flex-1 py-3 px-4 rounded-lg font-medium transition-colors',
                importMethod === 'json'
                  ? 'bg-primary-500 text-white'
                  : 'bg-muted-100 dark:bg-muted-800 text-muted-600 hover:bg-muted-200 dark:hover:bg-muted-700',
              ]"
              @click="importMethod = 'json'"
            >
              <div class="flex items-center justify-center gap-2">
                <Icon name="ph:file-js" class="h-5 w-5" />
                <span>JSON</span>
              </div>
            </button>
          </div>

          <!-- File Upload Area -->
          <div :key="`upload-${importMethod}`">
            <label
              v-if="!isFileLoaded"
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
                    : $t('Excel file (.xlsx, .xls)')
                }}
              </p>
              <input
                ref="fileInput"
                type="file"
                class="hidden"
                :accept="importMethod === 'json' ? '.json' : '.xlsx,.xls'"
                @change="handleFileUpload"
              />
            </label>

            <!-- File Loaded Success Banner -->
            <div
              v-else
              class="bg-success-50 dark:bg-success-900/20 border-2 border-success-500 rounded-lg p-6 text-center"
            >
              <Icon
                name="ph:check-circle"
                class="text-success-500 mx-auto mb-3 h-12 w-12"
              />
              <p
                class="text-success-700 dark:text-success-300 font-medium mb-2"
              >
                {{ $t('File read successfully') }}
              </p>
              <p class="text-success-600 dark:text-success-400 text-sm mb-4">
                {{ detectedFields.length }} {{ $t('fields detected') }}
              </p>
              <BaseButton size="sm" color="default" @click="clearFileInputs">
                {{ $t('Choose another file') }}
              </BaseButton>
            </div>
          </div>

          <!-- Sample Download Links -->
          <div
            class="bg-info-50 dark:bg-info-900/20 border border-info-200 dark:border-info-800 rounded-lg p-3"
          >
            <p class="text-info-700 dark:text-info-300 text-sm mb-2">
              {{ $t('Download template file:') }}
            </p>
            <div class="flex gap-2 types">
              <BaseButton
                size="sm"
                color="success"
                @click="downloadSampleExcel"
              >
                <Icon name="ph:file-xls" class="h-4 w-4 mr-1" />
                Excel
              </BaseButton>
              <BaseButton size="sm" color="info" @click="downloadSampleJson">
                <Icon name="ph:file-js" class="h-4 w-4 mr-1" />
                JSON
              </BaseButton>
            </div>
          </div>
        </div>

        <!-- Step 2: Preview & Configure -->
        <div v-else-if="step === 2" class="space-y-4">
          <div
            class="bg-muted-50 dark:bg-muted-900/50 border border-muted-200 dark:border-muted-700 rounded-lg p-4"
          >
            <h4 class="font-medium mb-2">
              {{ $t('Format code') }} <span class="text-danger-500">*</span>
            </h4>
            <BaseInput
              v-model="deviceFormatCode"
              size="sm"
              name="device_format_code"
              :placeholder="$t('e.g. TELTONIKA_FMB920')"
              :error="
                !deviceFormatCode.trim() ? $t('Format code is required') : ''
              "
              class="border"
            />
            <p class="text-muted-400 mt-1 text-xs">
              {{
                $t(
                  'Saved as Assets.device_format_code and Device_tracking_fields.code so this format can be reused later',
                )
              }}
            </p>
          </div>

          <div
            class="bg-muted-50 dark:bg-muted-900/50 border border-muted-200 dark:border-muted-700 rounded-lg p-4"
          >
            <h4 class="font-medium mb-3">
              {{ $t('Detected fields') }} ({{ detectedFields.length }})
            </h4>

            <!-- Field Configuration Table -->
            <div class="overflow-x-auto max-h-96 overflow-y-auto">
              <table class="w-full text-sm">
                <thead class="sticky top-0 bg-muted-50 dark:bg-muted-900/50">
                  <tr class="border-b border-muted-200 dark:border-muted-700">
                    <th class="text-left py-2 px-2">{{ $t('Field Key') }}</th>
                    <th class="text-left py-2 px-2">
                      {{ $t('Mongolian name') }}
                    </th>
                    <th class="text-left py-2 px-2">{{ $t('English') }}</th>
                    <th class="text-left py-2 px-2">{{ $t('Unit') }}</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="(field, index) in detectedFields"
                    :key="index"
                    class="border-b border-muted-100 dark:border-muted-800"
                  >
                    <td class="py-2 px-2">
                      <code
                        class="text-xs bg-muted-100 dark:bg-muted-800 px-2 py-1 rounded"
                      >
                        {{ field.field_key }}
                      </code>
                    </td>
                    <td class="py-2 px-2">
                      <BaseInput
                        v-model="field.field_name_mn"
                        size="sm"
                        :placeholder="$t('Mongolian name')"
                      />
                    </td>
                    <td class="py-2 px-2">
                      <BaseInput
                        v-model="field.field_name_en"
                        size="sm"
                        :placeholder="$t('English name')"
                      />
                    </td>
                    <td class="py-2 px-2">
                      <BaseInput
                        v-model="field.unit"
                        size="sm"
                        :placeholder="$t('Unit')"
                        class="w-20"
                      />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Sample Data Preview -->
          <div
            v-if="sampleData.length > 0"
            class="bg-muted-50 dark:bg-muted-900/50 border border-muted-200 dark:border-muted-700 rounded-lg p-4"
          >
            <h4 class="font-medium mb-3">
              {{ $t('Data example') }} ({{ sampleData.length }}
              {{ $t('rows') }})
            </h4>
            <div class="overflow-x-auto max-h-64 overflow-y-auto">
              <pre class="text-xs bg-muted-100 dark:bg-muted-800 p-3 rounded">{{
                JSON.stringify(sampleData, null, 2)
              }}</pre>
            </div>
            <p class="text-xs text-muted-500 mt-2">
              <Icon name="ph:info" class="h-3 w-3 inline mr-1" />
              {{
                sampleData.length < 5
                  ? $t('All rows')
                  : $t('Showing first 5 rows')
              }}
            </p>
          </div>

          <!-- Uploaded File Content (Full JSON/Excel data) -->
          <div
            class="bg-muted-50 dark:bg-muted-900/50 border border-muted-200 dark:border-muted-700 rounded-lg p-4"
          >
            <div class="flex items-center justify-between mb-3">
              <h4 class="font-medium">
                {{ $t('Uploaded data') }}
              </h4>
              <BaseTag color="primary" size="sm">
                {{ importMethod === 'json' ? 'JSON' : 'Excel → JSON' }}
              </BaseTag>
            </div>
            <div class="overflow-x-auto max-h-96 overflow-y-auto">
              <pre class="text-xs bg-muted-100 dark:bg-muted-800 p-3 rounded">{{
                importMethod === 'json'
                  ? jsonInput
                  : JSON.stringify(JSON.parse(excelInput), null, 2)
              }}</pre>
            </div>
            <p class="text-xs text-muted-500 mt-2">
              <Icon name="ph:file-text" class="h-3 w-3 inline mr-1" />
              {{ $t('All data shown in JSON format') }}
            </p>
          </div>

          <!-- Configuration Options -->
          <div class="flex items-center gap-3">
            <BaseCheckbox v-model="saveToFieldConfig" />
            <label class="text-sm">
              {{ $t('Save field settings to Device_tracking_fields table') }}
            </label>
          </div>
        </div>

        <!-- Step 3: Success -->
        <div v-else-if="step === 3" class="text-center py-8">
          <Icon
            name="ph:check-circle"
            class="h-16 w-16 mx-auto mb-4 text-success-500"
          />
          <h3 class="text-xl font-semibold mb-2">
            {{ $t('Imported successfully!') }}
          </h3>
          <p class="text-muted-600 dark:text-muted-400">
            <template v-if="importedCount > 0">
              {{ importedCount }} {{ $t('records saved') }}
            </template>
            <template v-else>
              {{ $t('Field settings saved') }}
            </template>
          </p>
        </div>
      </div>
      <!-- End Modal Body -->

      <template #footer>
        <div class="flex items-center justify-between w-full">
          <BaseButton v-if="step === 2" color="default" @click="backToUpload">
            <Icon name="ph:arrow-left" class="h-4 w-4 mr-2" />
            {{ $t('Back') }}
          </BaseButton>
          <BaseButton v-else color="default" @click="closeModal">
            <Icon name="ph:x-circle" class="h-4 w-4 mr-2" />
            {{ $t('Cancel') }}
          </BaseButton>

          <BaseButton
            v-if="step === 2"
            color="primary"
            :loading="loading"
            @click="processImport"
            :disabled="detectedFields.length === 0 || !deviceFormatCode.trim()"
          >
            <Icon name="ph:floppy-disk" class="h-4 w-4 mr-2" />
            {{ $t('Save') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>
  </div>
</template>

<style scoped>
.format-import {
  display: inline-block;
}
</style>
