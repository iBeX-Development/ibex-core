<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import * as XLSX from 'xlsx'

const { t } = useI18n({ useScope: 'global' })

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
  fields: {
    type: Array,
    default: () => [
      { name: 'item_name', label: 'Name' },
      { name: 'item_mongolian_name', label: 'Mongolian Name' },
      { name: 'price', label: 'Price', type: 'number' },
      { name: 'manufacturer', label: 'Manufacturer' },
      { name: 'model_no', label: 'Model No' },
      { name: 'serial_no', label: 'Serial No' },
      { name: 'technical_data', label: 'Technical Data' },
      { name: 'special_information', label: 'Special Information' },
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

      console.log('Raw Excel data:', jsonData)
      if (jsonData.length < 2) {
        alert(t('Excel file must contain headers and at least one data row'))
        return
      }

      // Find the first non-empty row that contains headers
      let headerRowIndex = 0
      let headers: string[] = []

      for (let i = 0; i < jsonData.length; i++) {
        const potentialHeaders = (jsonData[i] as string[]).map((h) =>
          h.toString().trim().toLowerCase(),
        )

        // Check if this row contains any of our expected field names
        const hasValidHeaders = potentialHeaders.some((h) =>
          props.fields.some((field) => field.name.toLowerCase() === h),
        )

        if (hasValidHeaders) {
          headerRowIndex = i
          headers = potentialHeaders
          console.log(`Found headers in row ${i + 1}:`, headers)
          break
        }
      }

      if (headers.length === 0) {
        alert(t('Could not find header row with expected field names'))
        return
      }

      console.log('Excel headers found:', headers)
      console.log(
        'Expected field names:',
        props.fields.map((f) => f.name),
      )

      // Create a mapping from field names to header indices
      const fieldToHeaderIndex: Record<string, number> = {}
      props.fields.forEach((field) => {
        const headerIndex = headers.findIndex(
          (h) => h.toLowerCase().trim() === field.name.toLowerCase().trim(),
        )
        if (headerIndex !== -1) {
          fieldToHeaderIndex[field.name] = headerIndex
          console.log(
            `✅ Mapped field "${field.name}" to column ${headerIndex} (header: "${headers[headerIndex]}")`,
          )
        } else {
          console.warn(`❌ Field "${field.name}" not found in Excel headers`)
          console.log(`Available headers:`, headers)
          console.log(`Looking for:`, field.name.toLowerCase().trim())
        }
      })

      console.log('Final field mapping:', fieldToHeaderIndex)

      // Convert data rows to objects using the field mapping
      const dataRows = jsonData
        .slice(headerRowIndex + 1) // Skip header row and any rows before it
        .map((row, rowIndex) => {
          const obj: any = {}
          let hasAnyData = false

          props.fields.forEach((field) => {
            const headerIndex = fieldToHeaderIndex[field.name]
            if (headerIndex !== undefined && row[headerIndex] !== undefined) {
              const cellValue = row[headerIndex]
              const stringValue = (cellValue || '').toString().trim()
              obj[field.name] = stringValue
              if (stringValue !== '') {
                hasAnyData = true
              }
            } else {
              obj[field.name] = ''
            }
          })

          // Add row index for debugging (accounting for header row position)
          obj._rowIndex = headerRowIndex + rowIndex + 2 // +2 because we're 1-indexed and skipped header

          return hasAnyData ? obj : null
        })
        .filter((row) => row !== null) // Remove completely empty rows

      // Validate each row based on fields definition
      validationErrors.value = []
      const validatedRows: any[] = [] // Use different name to avoid conflict
      const requiredFields = props.fields
        .filter((f) => f.required)
        .map((f) => f.name)

      console.log('Parsed dataRows:', dataRows)
      console.log('Required fields:', requiredFields)

      if (dataRows.length === 0) {
        validationErrors.value.push('No data rows found in Excel file')
        console.log('No data rows found after filtering')
      }

      dataRows.forEach((row, index) => {
        const errors: string[] = []
        const rowNumber = row._rowIndex || index + 2

        console.log(`Validating row ${rowNumber}:`, row)

        // Check required fields
        requiredFields.forEach((fieldName) => {
          const value = row[fieldName] || ''
          console.log(`  Checking required field "${fieldName}": "${value}"`)
          if (!value || value.toString().trim() === '') {
            errors.push(`Missing required field: ${fieldName}`)
          }
        })

        // Validate number fields
        props.fields.forEach((field) => {
          if (field.type === 'number' && row[field.name]) {
            const numValue = parseFloat(row[field.name])
            if (isNaN(numValue)) {
              errors.push(
                `Invalid number format for ${field.name}: ${row[field.name]}`,
              )
            }
          }
        })

        console.log(
          `  Row ${rowNumber} validation result: ${
            errors.length === 0 ? 'VALID' : 'INVALID'
          }`,
        )
        if (errors.length > 0) {
          console.log(`  Errors:`, errors)
        }

        if (errors.length === 0) {
          // Remove _rowIndex before adding to valid rows
          const cleanRow = { ...row }
          delete cleanRow._rowIndex
          validatedRows.push(cleanRow) // Use the local array
        } else {
          validationErrors.value.push(`Row ${rowNumber}: ${errors.join(', ')}`)
        }
      })

      // Always show all parsed rows in preview (not just valid ones)
      const displayRows = dataRows.map((row) => {
        const cleanRow = { ...row }
        delete cleanRow._rowIndex
        return cleanRow
      })

      importedData.value = displayRows
      validRows.value = validatedRows // Assign the local array to the reactive ref

      console.log(
        `Processing complete: ${displayRows.length} total rows, ${validatedRows.length} valid rows`,
      )

      if (validationErrors.value.length > 0) {
        console.log('Validation errors:', validationErrors.value)
      } else {
        console.log('All rows passed validation')
      }
    } catch (error) {
      console.error('Error parsing Excel file:', error)
      validationErrors.value = [
        `Error parsing Excel file: ${error.message || 'Unknown error'}`,
      ]
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
    // Map only valid rows to part format - ensure all fields are included
    const partsToCreate = validRows.value.map((row) => {
      // Create a complete data object with all fields
      const partData = {
        name: row.item_name || '',
        mongolian_name: row.item_mongolian_name || '',
        manufacturer: row.manufacturer || '',
        price: row.price ? parseFloat(row.price) : 0,
        special_information: row.special_information || '', // Map special_information to description
        model_no: row.model_no || '',
        serial_no: row.serial_no || '',
        technical_data: row.technical_data || '',
        status: '1', // Default status
      }

      console.log('Creating part with data:', partData)

      return partData
    })

    console.log('Parts to create:', partsToCreate)

    // Emit the import event with the data
    emit('import', partsToCreate)

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
    'https://api.ibex.mn/assets/2fc158ed-669b-4a3f-a3a5-3211fc3fc087'
  if (window.location.hostname === 'smartgps.ibex.mn') {
    url_prefix =
      'https://smartgps-admin.ibex.mn/assets/5c6980d9-c6e5-49d1-bf7c-3f33f162deef'
  }

  const link = document.createElement('a')
  link.href = url_prefix
  link.download = 'parts_import_template.xlsx'
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
          {{ $t('Import Parts from Excel') }}
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
                {{ importedData.length }} {{ $t('parts ready to import') }}
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
              <thead
                class="table-rows sticky top-0 bg-muted-100 dark:bg-muted-800"
              >
                <tr>
                  <th
                    v-for="field in props.fields"
                    :key="field.name"
                    class="border-b border-muted-200 px-4 py-2 text-left dark:border-muted-700"
                  >
                    {{ field.label }}
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
          <span v-if="!loading">Import Parts</span>
          <span v-else>Importing...</span>
        </button>
        <button
          v-else
          @click="triggerFileInput"
          class="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700"
        >
          Select File
        </button>
      </div>
    </div>
  </div>
</template>
