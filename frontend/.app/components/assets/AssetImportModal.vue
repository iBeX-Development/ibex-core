<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import * as XLSX from 'xlsx'
import { mapExcelRowToAsset } from '~/utils/excelMapping'

const { t } = useI18n({ useScope: 'global' })

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
  locationId: {
    type: [String, Number],
    required: true,
  },
  fields: {
    type: Array,
    default: () => [
      { name: 'asset_code', label: 'Asset Code', required: true },
      { name: 'name', label: 'Asset Name', required: true },
      { name: 'reading_type', label: 'Reading Type', required: true },
      { name: 'serial_number', label: 'Serial Number' },
      { name: 'model_number', label: 'Model Number' },
      { name: 'purchase_cost', label: 'Purchase Cost' },
      { name: 'description', label: 'Description' },
    ],
  },
})

const emit = defineEmits(['close', 'import'])

const fileInput = ref<HTMLInputElement | null>(null)
const loading = ref(false)
const isProcessing = ref(false)
const selectedFileName = ref('')
const importedData = ref<any[]>([])
const validRows = ref<any[]>([])
const excelFile = ref<File | null>(null)
const importProgress = ref(0)
const validationErrors = ref<string[]>([])

const hasData = computed(() => importedData.value.length > 0)
const hasErrors = computed(() => validationErrors.value.length > 0)

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]

  if (!file) return

  // Check if file is Excel format
  if (
    !file.name.endsWith('.xlsx') &&
    !file.name.endsWith('.xls') &&
    !file.type.includes('spreadsheet')
  ) {
    alert(t('Please select a valid Excel file'))
    return
  }

  excelFile.value = file
  selectedFileName.value = file.name
  isProcessing.value = true
  parseExcelFile(file)
}

const parseExcelFile = (file: File) => {
  const reader = new FileReader()

  reader.onload = (e) => {
    try {
      const data = e.target?.result
      const workbook = XLSX.read(data, { type: 'binary' })
      const sheetName = workbook.SheetNames[0]
      const worksheet = workbook.Sheets[sheetName]

      // Convert sheet to JSON with headers in first row
      const jsonData = XLSX.utils.sheet_to_json(worksheet, {
        header: 1,
        defval: '',
      }) as any[][]

      if (jsonData.length < 2) {
        alert(t('Excel file must contain headers and at least one data row'))
        return
      }

      // First row is headers - trim and normalize
      const headers = (jsonData[0] as string[]).map((h) =>
        h.trim().toLowerCase(),
      )

      // Create a mapping from field names to header indices
      const fieldToHeaderIndex: Record<string, number> = {}
      props.fields.forEach((field) => {
        const headerIndex = headers.findIndex(
          (h) => h === field.name.toLowerCase(),
        )
        if (headerIndex !== -1) {
          fieldToHeaderIndex[field.name] = headerIndex
        }
      })

      // Convert data rows to objects using the field mapping
      const dataRows = jsonData
        .slice(1)
        .map((row) => {
          const obj: any = {}
          props.fields.forEach((field) => {
            const headerIndex = fieldToHeaderIndex[field.name]
            if (headerIndex !== undefined) {
              obj[field.name] = (row[headerIndex] || '').toString().trim()
            }
          })
          return obj
        })
        .filter((row) => Object.values(row).some((v) => v !== ''))

      // Validate each row based on fields definition
      validationErrors.value = []
      const validRowsArray: any[] = []
      const requiredFields = props.fields
        .filter((f) => f.required)
        .map((f) => f.name)

      dataRows.forEach((row, index) => {
        const errors: string[] = []

        // Check required fields
        requiredFields.forEach((fieldName) => {
          const value = row[fieldName] || ''
          if (!value || value.toString().trim() === '') {
            errors.push(`Missing required field: ${fieldName}`)
          }
        })

        if (errors.length === 0) {
          validRowsArray.push(row)
        } else {
          validationErrors.value.push(`Row ${index + 2}: ${errors.join(', ')}`)
        }
      })

      // Always show all parsed rows in preview (not just valid ones)
      importedData.value = dataRows
      validRows.value = validRowsArray

      if (validationErrors.value.length > 0) {
        console.warn('Validation errors:', validationErrors.value)
      }
    } catch (error) {
      console.error('Error parsing Excel file:', error)
      alert(t('Error parsing Excel file'))
    } finally {
      isProcessing.value = false
    }
  }

  reader.readAsBinaryString(file)
}

const submitImport = async () => {
  if (validRows.value.length === 0) {
    alert(t('No valid data to import'))
    return
  }

  loading.value = true
  importProgress.value = 0

  try {
    // Map only valid rows to asset format
    const assetsToCreate = validRows.value.map((row) =>
      mapExcelRowToAsset(row, props.locationId, props.fields),
    )

    // Emit the import event with the data
    emit('import', assetsToCreate)

    // Reset on success
    resetForm()
  } catch (error) {
    console.error('Error during import:', error)
    alert(t('Error during import'))
  } finally {
    loading.value = false
  }
}

const resetForm = () => {
  importedData.value = []
  validRows.value = []
  excelFile.value = null
  importProgress.value = 0
  validationErrors.value = []
  selectedFileName.value = ''
  isProcessing.value = false

  if (fileInput.value) {
    fileInput.value.value = ''
  }

  emit('close')
}

const handleClose = () => {
  resetForm()
}

const triggerFileInput = () => {
  fileInput.value?.click()
}

const resetFileSelection = () => {
  importedData.value = []
  validRows.value = []
  excelFile.value = null
  validationErrors.value = []
  selectedFileName.value = ''
  if (fileInput.value) {
    fileInput.value.value = ''
  }
  triggerFileInput()
}

const downloadTemplate = () => {
  let url_prefix =
    'https://api.ibex.mn/assets/a6f40ea3-61eb-4dc9-a527-f2583ec8c618'
  if (window.location.hostname === 'smartgps.ibex.mn') {
    url_prefix =
      'https://smartgps-admin.ibex.mn/assets/0e2a0032-90f0-44ac-bcac-9abad5fa43c9'
  }

  const link = document.createElement('a')
  link.href = url_prefix
  link.download = 'asset_import_template.xlsx'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
}
</script>

<template>
  <div
    v-if="isOpen"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
  >
    <div
      class="w-full max-w-2xl rounded-lg bg-white shadow-lg dark:bg-muted-900"
    >
      <!-- Header -->
      <div
        class="flex items-center justify-between border-b border-muted-200 p-6 dark:border-muted-800"
      >
        <h2 class="text-lg font-semibold text-muted-900 dark:text-white">
          {{ $t('Import Assets from Excel') }}
        </h2>
        <button
          @click="handleClose"
          class="text-muted-400 hover:text-muted-600 dark:hover:text-muted-200"
        >
          <Icon name="mdi:close" class="h-6 w-6" />
        </button>
      </div>

      <!-- Body -->
      <div class="p-6">
        <!-- Processing State -->
        <div v-if="isProcessing" class="space-y-4">
          <div
            class="flex items-center justify-center rounded-lg border border-muted-200 p-8 dark:border-muted-800"
          >
            <div class="text-center">
              <Icon
                name="mdi:loading"
                class="mb-3 inline-block h-8 w-8 animate-spin text-primary-500"
              />
              <p class="text-sm font-medium text-muted-600 dark:text-muted-400">
                {{ $t('Processing') }} {{ selectedFileName }}...
              </p>
            </div>
          </div>
        </div>
        <!-- File Selection State -->
        <div v-else-if="!hasData" class="space-y-4">
          <!-- File Upload Area -->
          <input
            ref="fileInput"
            type="file"
            accept=".xlsx,.xls"
            class="hidden"
            @change="handleFileSelect"
          />

          <div
            @click="triggerFileInput"
            class="flex cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed border-muted-300 p-8 transition hover:border-muted-400 dark:border-muted-700 dark:hover:border-muted-600"
          >
            <Icon name="mdi:cloud-upload" class="mb-2 h-8 w-8 text-muted-400" />
            <p class="text-center text-xs text-muted-500 dark:text-muted-400">
              {{ $t('Supported formats: .xlsx, .xls') }}
            </p>
          </div>

          <div class="rounded-lg bg-blue-50 p-4 dark:bg-blue-900/20">
            <p class="text-sm text-blue-900 dark:text-blue-200">
              <strong>{{ $t('Required columns:') }}</strong>
              {{
                props.fields
                  .filter((f) => f.required)
                  .map((f) => f.name)
                  .join(', ')
              }}
            </p>
          </div>

          <div class="flex gap-3">
            <button
              @click="downloadTemplate"
              class="flex-1 rounded-lg border-2 border-primary-600 px-4 py-2 text-sm font-medium text-primary-600 hover:bg-primary-50 dark:border-primary-400 dark:text-primary-400 dark:hover:bg-primary-900/20"
            >
              <span class="flex items-center justify-center gap-2">
                <Icon name="mdi:download" class="h-4 w-4" />
                {{ $t('Download Template') }}
              </span>
            </button>
          </div>
        </div>

        <!-- Data Preview -->
        <div v-else class="space-y-4">
          <!-- Validation Errors Alert -->
          <div
            v-if="hasErrors"
            class="rounded-lg bg-red-50 p-4 dark:bg-red-900/20"
          >
            <div class="flex items-start gap-3">
              <Icon
                name="mdi:alert-circle"
                class="mt-0.5 h-5 w-5 text-red-600 dark:text-red-400"
              />
              <div class="flex-1">
                <h3 class="font-medium text-red-900 dark:text-red-200">
                  {{ $t('Validation Errors') }}
                </h3>
                <ul
                  class="mt-2 list-inside space-y-1 text-sm text-red-800 dark:text-red-300"
                >
                  <li
                    v-for="(error, idx) in validationErrors.slice(0, 5)"
                    :key="idx"
                  >
                    • {{ error }}
                  </li>
                </ul>
                <p
                  v-if="validationErrors.length > 5"
                  class="mt-2 text-xs text-red-600 dark:text-red-400"
                >
                  {{ $t('and') }} {{ validationErrors.length - 5 }}
                  {{ $t('more errors') }}
                </p>
              </div>
            </div>
          </div>

          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-medium text-muted-900 dark:text-white">
                {{ importedData.length }} {{ $t('assets ready to import') }}
              </p>
              <p
                v-if="selectedFileName"
                class="text-xs text-muted-500 dark:text-muted-400 mt-1"
              >
                {{ $t('File') }}: {{ selectedFileName }}
              </p>
            </div>
            <button
              @click="resetFileSelection"
              class="text-xs text-primary-600 hover:text-primary-700 dark:text-primary-400"
            >
              {{ $t('Change file') }}
            </button>
          </div>

          <!-- Data Table Preview -->
          <div
            class="max-h-96 overflow-y-auto rounded-lg border border-muted-200 dark:border-muted-800"
          >
            <table class="w-full text-sm">
              <thead class="sticky top-0 bg-muted-100 dark:bg-muted-800">
                <tr>
                  <th
                    v-for="field in props.fields"
                    :key="field.name"
                    class="border-b border-muted-200 px-4 py-2 text-left dark:border-muted-700"
                  >
                    {{ $t(field.label) }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="(row, index) in importedData.slice(0, 5)"
                  :key="index"
                  class="border-b border-muted-200 hover:bg-muted-50 dark:border-muted-700 dark:hover:bg-muted-800"
                >
                  <td
                    v-for="field in props.fields"
                    :key="field.name"
                    class="border-r border-muted-200 px-4 py-2 dark:border-muted-700"
                  >
                    {{ row[field.name] || '-' }}
                  </td>
                </tr>
              </tbody>
            </table>
            <div
              v-if="importedData.length > 5"
              class="bg-muted-50 px-4 py-2 text-center text-xs text-muted-600 dark:bg-muted-800 dark:text-muted-400"
            >
              {{ $t('and') }} {{ importedData.length - 5 }}
              {{ $t('more rows') }}
            </div>
          </div>

          <!-- Progress -->
          <div v-if="loading" class="space-y-2">
            <div class="flex items-center justify-between text-sm">
              <span>{{ $t('Importing') }}...</span>
              <span>{{ importProgress }}%</span>
            </div>
            <div
              class="h-2 w-full overflow-hidden rounded-full bg-muted-200 dark:bg-muted-800"
            >
              <div
                class="h-full bg-primary-500 transition-all duration-300"
                :style="{ width: `${importProgress}%` }"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div
        class="flex justify-end gap-3 border-t border-muted-200 p-6 dark:border-muted-800"
      >
        <button
          @click="handleClose"
          :disabled="loading"
          class="rounded-lg px-4 py-2 text-sm font-medium text-muted-700 hover:bg-muted-100 disabled:opacity-50 dark:text-muted-300 dark:hover:bg-muted-800"
        >
          {{ $t('Cancel') }}
        </button>
        <button
          v-if="hasData"
          @click="submitImport"
          :disabled="loading"
          class="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
        >
          <span v-if="!loading">{{ $t('Import Assets') }}</span>
          <span v-else>{{ $t('Importing') }}...</span>
        </button>
        <button
          v-else
          @click="triggerFileInput"
          class="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700"
        >
          {{ $t('Select File') }}
        </button>
      </div>
    </div>
  </div>
</template>
