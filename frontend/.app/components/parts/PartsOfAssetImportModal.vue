<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import * as XLSX from 'xlsx'

const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

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
})

const emit = defineEmits(['close', 'import'])

// Excel columns for Asset_Parts import
// location_code is reference-only (auto-filled in template, not used during import)
const fields = [
  { name: 'location_code', label: 'Location_Code', required: true },
  { name: 'asset_code', label: 'Asset_Code', required: true },
  { name: 'part_number', label: 'Part_Number', required: true },
  { name: 'quantity', label: 'Quantity', required: true, type: 'number' },
]

const fileInput = ref<HTMLInputElement | null>(null)
const currentFile = ref<File | null>(null)
const loading = ref(false)
const isProcessing = ref(false)
const selectedFileName = ref('')
const importedData = ref<any[]>([])
const validRows = ref<any[]>([])
const validationErrors = ref<string[]>([])

const hasData = computed(() => importedData.value.length > 0)
const hasErrors = computed(() => validationErrors.value.length > 0)

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return

  if (
    !file.name.endsWith('.xlsx') &&
    !file.name.endsWith('.xls') &&
    !file.type.includes('spreadsheet')
  ) {
    alert(t('Please select a valid Excel file'))
    return
  }

  selectedFileName.value = file.name
  currentFile.value = file
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

      const jsonData = XLSX.utils.sheet_to_json(worksheet, {
        header: 1,
        defval: '',
      }) as any[][]

      if (jsonData.length < 2) {
        alert(t('Excel file must contain headers and at least one data row'))
        isProcessing.value = false
        return
      }

      // Find header row
      let headerRowIndex = 0
      let headers: string[] = []

      for (let i = 0; i < Math.min(jsonData.length, 5); i++) {
        const row = (jsonData[i] as string[]).map((h) =>
          h.toString().trim().toLowerCase(),
        )
        const hasValidHeaders = row.some((h) =>
          fields.some((f) => f.name.toLowerCase() === h),
        )
        if (hasValidHeaders) {
          headerRowIndex = i
          headers = row
          break
        }
      }

      if (headers.length === 0) {
        // Fallback: use first row
        headerRowIndex = 0
        headers = (jsonData[0] as string[]).map((h) =>
          h.toString().trim().toLowerCase(),
        )
      }

      // Map field names to column indices
      const fieldToIndex: Record<string, number> = {}
      fields.forEach((field) => {
        const idx = headers.findIndex((h) => h === field.name.toLowerCase())
        if (idx !== -1) fieldToIndex[field.name] = idx
      })

      // Parse data rows
      const dataRows = jsonData
        .slice(headerRowIndex + 1)
        .map((row, rowIdx) => {
          const obj: any = { _rowIndex: headerRowIndex + rowIdx + 2 }
          let hasData = false

          fields.forEach((field) => {
            const idx = fieldToIndex[field.name]
            if (idx !== undefined) {
              const val = (row[idx] ?? '').toString().trim()
              obj[field.name] = val
              if (val !== '') hasData = true
            } else {
              obj[field.name] = ''
            }
          })

          return hasData ? obj : null
        })
        .filter((r) => r !== null)

      // Validate
      validationErrors.value = []
      const validated: any[] = []
      const requiredFields = fields.filter((f) => f.required).map((f) => f.name)

      dataRows.forEach((row) => {
        const errors: string[] = []
        const rowNum = row._rowIndex

        requiredFields.forEach((fieldName) => {
          if (!row[fieldName] || row[fieldName].toString().trim() === '') {
            errors.push(`"${fieldName}" required`)
          }
        })

        fields.forEach((field) => {
          if (field.type === 'number' && row[field.name]) {
            if (isNaN(parseFloat(row[field.name]))) {
              errors.push(`"${field.name}" must be a number`)
            }
          }
        })

        const clean = { ...row }
        delete clean._rowIndex

        if (errors.length === 0) {
          validated.push(clean)
        } else {
          validationErrors.value.push(`Row ${rowNum}: ${errors.join(', ')}`)
        }
      })

      importedData.value = dataRows.map((r) => {
        const c = { ...r }
        delete c._rowIndex
        return c
      })
      validRows.value = validated
    } catch (error: any) {
      console.error('Excel parse error:', error)
      validationErrors.value = [`Error parsing file: ${error.message}`]
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
  try {
    emit('import', validRows.value, selectedFileName.value, currentFile.value)
    resetForm()
  } finally {
    loading.value = false
  }
}

const resetForm = () => {
  importedData.value = []
  validRows.value = []
  validationErrors.value = []
  selectedFileName.value = ''
  currentFile.value = null
  isProcessing.value = false
  if (fileInput.value) fileInput.value.value = ''
  emit('close')
}

const handleClose = () => resetForm()
const triggerFileInput = () => fileInput.value?.click()

const resetFileSelection = () => {
  importedData.value = []
  validRows.value = []
  validationErrors.value = []
  selectedFileName.value = ''
  if (fileInput.value) fileInput.value.value = ''
  triggerFileInput()
}

const downloadTemplate = async () => {
  const locationFilter: any = props.locationId
    ? { location: { _eq: props.locationId } }
    : {}

  let assets: any[] = []
  let existingPartsLocation: any[] = []

  try {
    // Fetch all assets in the location
    assets = await getItems({
      collection: 'Assets',
      params: {
        filter: props.locationId
          ? {
              location: { _eq: props.locationId },
              status: '1',
              company_id: { _eq: myCompanyId },
            }
          : { status: '1', company_id: { _eq: myCompanyId } },
        fields: ['id', 'asset_code', 'location.location_code'],
        limit: -1,
      },
    })

    // Fetch existing Asset_Parts records for those assets
    if (assets.length > 0) {
      const assetIds = assets.map((a: any) => a.id).filter(Boolean)
      existingPartsLocation = await getItems({
        collection: 'Asset_Parts',
        params: {
          filter: {
            ...locationFilter,
            asset: { _in: assetIds },
            status: '1',
            // company_id: { _eq: myCompanyId },
          },
          fields: [
            'id',
            'quantity',
            'part.part_number',
            'asset.asset_code',
            'asset.location.location_code',
          ],
          limit: -1,
        },
      })
    }
  } catch (e) {
    console.warn('Could not fetch data for template:', e)
  }

  // Build a set of asset_codes that already have Asset_Parts entries
  const assetCodesWithParts = new Set(
    existingPartsLocation.map((pl: any) => pl.asset?.asset_code),
  )

  const header = ['Location_Code', 'Asset_Code', 'Part_Number', 'Quantity']
  const rows: any[][] = []

  // Pre-filled rows: existing Asset_Parts records
  for (const pl of existingPartsLocation) {
    rows.push([
      pl.asset?.location?.location_code ?? '',
      pl.asset?.asset_code ?? '',
      pl.part?.part_number ?? '',
      pl.quantity ?? '',
    ])
  }

  // Empty rows: assets that have no Asset_Parts entries yet
  for (const a of assets) {
    if (!assetCodesWithParts.has(a.asset_code)) {
      rows.push([a.location?.location_code ?? '', a.asset_code ?? '', '', ''])
    }
  }

  if (rows.length === 0) {
    rows.push(['', '', '', ''])
  }

  const ws = XLSX.utils.aoa_to_sheet([header, ...rows])
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, 'Sheet1')
  XLSX.writeFile(wb, 'parts_of_asset_template.xlsx')
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
          {{ $t('Import Parts of Asset') }}
        </h2>
        <button
          class="text-muted-400 hover:text-muted-600 dark:hover:text-muted-200"
          @click="handleClose"
        >
          <Icon name="mdi:close" class="h-6 w-6" />
        </button>
      </div>

      <!-- Body -->
      <div class="p-6">
        <!-- Processing -->
        <div
          v-if="isProcessing"
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

        <!-- File Selection -->
        <div v-else-if="!hasData" class="space-y-4">
          <input
            ref="fileInput"
            type="file"
            accept=".xlsx,.xls"
            class="hidden"
            @change="handleFileSelect"
          />

          <div
            class="flex cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed border-muted-300 p-8 transition hover:border-muted-400 dark:border-muted-700 dark:hover:border-muted-600"
            @click="triggerFileInput"
          >
            <Icon name="mdi:cloud-upload" class="mb-2 h-8 w-8 text-muted-400" />
            <p class="text-sm font-medium text-muted-600 dark:text-muted-300">
              {{ $t('Click to select Excel file') }}
            </p>
            <p
              class="text-center text-xs text-muted-500 dark:text-muted-400 mt-1"
            >
              {{ $t('Supported formats: .xlsx, .xls') }}
            </p>
          </div>

          <!-- Column info -->
          <div class="rounded-lg bg-blue-50 p-4 dark:bg-blue-900/20">
            <p
              class="text-sm font-medium text-blue-900 dark:text-blue-200 mb-2"
            >
              {{ $t('Required columns:') }}
            </p>
            <div class="flex flex-wrap gap-2">
              <span
                v-for="field in fields"
                :key="field.name"
                :class="[
                  'rounded px-2 py-0.5 text-xs font-mono',
                  field.required
                    ? 'bg-blue-200 text-blue-900 dark:bg-blue-800 dark:text-blue-100'
                    : 'bg-muted-200 text-muted-700 dark:bg-muted-700 dark:text-muted-300',
                ]"
              >
                {{ field.label }}{{ field.required ? ' *' : '' }}
              </span>
            </div>
          </div>

          <button
            class="w-full rounded-lg border-2 border-primary-600 px-4 py-2 text-sm font-medium text-primary-600 hover:bg-primary-50 dark:border-primary-400 dark:text-primary-400 dark:hover:bg-primary-900/20"
            @click="downloadTemplate"
          >
            <span class="flex items-center justify-center gap-2">
              <Icon name="mdi:download" class="h-4 w-4" />
              {{ $t('Download Template') }}
            </span>
          </button>
        </div>

        <!-- Preview -->
        <div v-else class="space-y-4">
          <!-- Errors -->
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
                    v-for="(err, idx) in validationErrors.slice(0, 5)"
                    :key="idx"
                  >
                    • {{ err }}
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
                {{ validRows.length }} / {{ importedData.length }}
                {{ $t('rows ready to import') }}
              </p>
              <p
                v-if="selectedFileName"
                class="mt-1 text-xs text-muted-500 dark:text-muted-400"
              >
                {{ $t('File') }}: {{ selectedFileName }}
              </p>
            </div>
            <button
              class="text-xs text-primary-600 hover:text-primary-700 dark:text-primary-400"
              @click="resetFileSelection"
            >
              {{ $t('Change file') }}
            </button>
          </div>

          <!-- Table preview -->
          <div
            class="max-h-96 overflow-y-auto rounded-lg border border-muted-200 dark:border-muted-800"
          >
            <table class="w-full text-sm">
              <thead class="sticky top-0 bg-muted-100 dark:bg-muted-800">
                <tr>
                  <th
                    v-for="field in fields"
                    :key="field.name"
                    class="border-b border-muted-200 px-4 py-2 text-left dark:border-muted-700"
                  >
                    {{ field.label }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="(row, index) in importedData.slice(0, 10)"
                  :key="index"
                  class="border-b border-muted-200 hover:bg-muted-50 dark:border-muted-700 dark:hover:bg-muted-800"
                >
                  <td
                    v-for="field in fields"
                    :key="field.name"
                    class="border-r border-muted-200 px-4 py-2 dark:border-muted-700"
                  >
                    {{ row[field.name] || '-' }}
                  </td>
                </tr>
              </tbody>
            </table>
            <div
              v-if="importedData.length > 10"
              class="bg-muted-50 px-4 py-2 text-center text-xs text-muted-600 dark:bg-muted-800 dark:text-muted-400"
            >
              {{ $t('and') }} {{ importedData.length - 10 }}
              {{ $t('more rows') }}
            </div>
          </div>

          <!-- Progress -->
          <div v-if="loading" class="space-y-2">
            <p class="text-sm text-muted-600 dark:text-muted-400">
              {{ $t('Importing') }}...
            </p>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div
        class="flex justify-end gap-3 border-t border-muted-200 p-6 dark:border-muted-800"
      >
        <button
          :disabled="loading"
          class="rounded-lg px-4 py-2 text-sm font-medium text-muted-700 hover:bg-muted-100 disabled:opacity-50 dark:text-muted-300 dark:hover:bg-muted-800"
          @click="handleClose"
        >
          {{ $t('Cancel') }}
        </button>
        <button
          v-if="hasData"
          :disabled="loading || validRows.length === 0"
          class="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700 disabled:opacity-50"
          @click="submitImport"
        >
          <span v-if="!loading"
            >{{ $t('Import') }} ({{ validRows.length }})</span
          >
          <span v-else>{{ $t('Importing') }}...</span>
        </button>
        <button
          v-else
          class="rounded-lg bg-primary-600 px-4 py-2 text-sm font-medium text-white hover:bg-primary-700"
          @click="triggerFileInput"
        >
          {{ $t('Select File') }}
        </button>
      </div>
    </div>
  </div>
</template>
