<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import * as XLSX from 'xlsx'
import { useDatahubMassImport } from '~/composables/useDatahubMassImport'
import { useMonitoringAlerts } from '~/composables/useMonitoringAlerts'

const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const props = defineProps({
  isOpen: { type: Boolean, default: false },
})

const emit = defineEmits(['close', 'done'])

const { isImporting, progress, currentAsset, results, massImport } =
  useDatahubMassImport()

const _monitoringAlertAssetId = ref<number | null>(null)
const {
  browserNotif,
  popupModal,
  closeBrowserPopup,
  closePopupModal,
  runCheckForAssets,
} = useMonitoringAlerts(_monitoringAlertAssetId as any)

const alertCheckCountdown = ref<number | null>(null)
let countdownInterval: ReturnType<typeof setInterval> | null = null

const fileInput = ref<HTMLInputElement | null>(null)
const selectedFileName = ref('')
const selectedFile = ref<File | null>(null)
// sheets parsed from Excel: [{ assetCode, rows, headers }]
const parsedSheets = ref<
  Array<{ assetCode: string; rows: Record<string, any>[]; headers: string[] }>
>([])
const parseError = ref('')
const isDone = ref(false)

const hasSheets = computed(() => parsedSheets.value.length > 0)

// ── File selection ───────────────────────────────────────────────────────────
const triggerFileInput = () => fileInput.value?.click()

const handleFileSelect = (event: Event) => {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file) return
  parseError.value = ''
  parsedSheets.value = []
  selectedFileName.value = file.name
  selectedFile.value = file
  parseExcel(file)
}

/**
 * Parse all sheets.
 * If a sheet contains an "Asset_Code" column, rows are grouped by that value
 * (each unique Asset_Code becomes its own entry). Otherwise, sheet name is used.
 */
const parseExcel = (file: File) => {
  const reader = new FileReader()
  reader.onload = (e) => {
    try {
      const data = e.target?.result
      const workbook = XLSX.read(data, { type: 'binary' })

      const sheets: Array<{
        assetCode: string
        rows: Record<string, any>[]
        headers: string[]
      }> = []

      for (const sheetName of workbook.SheetNames) {
        const ws = workbook.Sheets[sheetName]
        const jsonData = XLSX.utils.sheet_to_json(ws, {
          header: 1,
          defval: '',
        }) as any[][]

        if (jsonData.length < 2) continue

        const headers: string[] = (jsonData[0] as string[]).map((h) =>
          String(h).trim(),
        )
        const rows: Record<string, any>[] = []

        for (let i = 1; i < jsonData.length; i++) {
          const row = jsonData[i]
          if (row.every((v: any) => v === '' || v === null || v === undefined))
            continue
          const obj: Record<string, any> = {}
          headers.forEach((h, idx) => {
            obj[h] = row[idx] ?? ''
          })
          rows.push(obj)
        }

        if (rows.length === 0) continue

        // Detect Asset_Code column (case-insensitive)
        const assetCodeHeader = headers.find(
          (h) => h.toLowerCase() === 'asset_code',
        )

        if (assetCodeHeader) {
          // Group rows by Asset_Code value
          const grouped = new Map<string, Record<string, any>[]>()
          for (const row of rows) {
            const ac = String(row[assetCodeHeader] ?? '').trim()
            if (!ac) continue
            if (!grouped.has(ac)) grouped.set(ac, [])
            grouped.get(ac)!.push(row)
          }
          for (const [assetCode, assetRows] of grouped) {
            sheets.push({ assetCode, rows: assetRows, headers })
          }
        } else {
          // Fallback: sheet name = asset_code
          sheets.push({ assetCode: sheetName.trim(), rows, headers })
        }
      }

      if (sheets.length === 0) {
        parseError.value = t('No valid data sheets found in the file')
        return
      }

      parsedSheets.value = sheets
    } catch (err: any) {
      parseError.value = t('Failed to parse Excel: ') + err.message
    }
  }
  reader.readAsBinaryString(file)
}

// ── Import ───────────────────────────────────────────────────────────────────
const startImport = async () => {
  isDone.value = false
  await massImport(
    parsedSheets.value.map((s) => ({ assetCode: s.assetCode, rows: s.rows })),
  )
  isDone.value = true
  emit('done', results.value, selectedFileName.value, selectedFile.value)

  // 60 секундийн дараа monitoring alerts шалгана
  const importedIds = results.value
    .filter((r) => r.asset_id)
    .map((r) => r.asset_id as number)
  console.log('[MassImport] importedIds:', importedIds)
  if (importedIds.length) {
    alertCheckCountdown.value = 10
    console.log(
      '[MassImport] Starting 10s countdown, then will call runCheckForAssets for:',
      importedIds,
    )
    countdownInterval = setInterval(() => {
      if (alertCheckCountdown.value !== null && alertCheckCountdown.value > 0) {
        alertCheckCountdown.value--
      }
      if (alertCheckCountdown.value === 0) {
        if (countdownInterval) clearInterval(countdownInterval)
        countdownInterval = null
        alertCheckCountdown.value = null
        console.log('[MassImport] Countdown done — calling runCheckForAssets')
        runCheckForAssets(importedIds)
      }
    }, 1000)
  } else {
    console.warn('[MassImport] No importedIds — skipping alert check')
  }
}

// ── Reset / Close ────────────────────────────────────────────────────────────
const reset = () => {
  parsedSheets.value = []
  selectedFileName.value = ''
  selectedFile.value = null
  parseError.value = ''
  isDone.value = false
  alertCheckCountdown.value = null
  if (countdownInterval) {
    clearInterval(countdownInterval)
    countdownInterval = null
  }
  if (fileInput.value) fileInput.value.value = ''
}

const handleClose = () => {
  reset()
  emit('close')
}

// ── Template download ────────────────────────────────────────────────────────
const isTemplateLoading = ref(false)

const downloadTemplate = async () => {
  isTemplateLoading.value = true
  try {
    // 1. Fetch all assets with their location
    const assets: any[] = await getItems({
      collection: 'Assets',
      params: {
        fields: ['id', 'asset_code', 'location.location_code'],
        limit: -1,
      },
    })

    if (assets.length === 0) {
      // Fallback: empty template with example
      const wb = XLSX.utils.book_new()
      const ws = XLSX.utils.aoa_to_sheet([
        [
          'Location_Code',
          'Asset_Code',
          'timestamp',
          'speed',
          'fuel_level',
          'engine_hours',
          'odometer',
        ],
        ['LOC-001', 'ASSET-001', 1700000000, '', '', '', ''],
      ])
      XLSX.utils.book_append_sheet(wb, ws, 'FM001')
      XLSX.writeFile(wb, 'datahub_mass_import_template.xlsx')
      return
    }

    // 2. Fetch tracking fields for all assets
    const assetIds = assets.map((a: any) => a.id).filter(Boolean)
    const trackingFields: any[] = await getItems({
      collection: 'Device_tracking_fields',
      params: {
        filter: {
          asset: { _in: assetIds },
          is_active: { _eq: true },
          company_id: { _eq: myCompanyId },
        },
        fields: ['asset', 'field_key', 'sort_order'],
        sort: ['asset', 'sort_order'],
        limit: -1,
      },
    })

    // 3. Build assetId → field_keys map
    const assetFieldMap = new Map<number, string[]>()
    for (const tf of trackingFields) {
      if (!assetFieldMap.has(tf.asset)) assetFieldMap.set(tf.asset, [])
      assetFieldMap.get(tf.asset)!.push(tf.field_key)
    }

    // 4. Group assets by their field configuration (same fields → same sheet)
    const formatGroups = new Map<
      string,
      Array<{ asset_code: string; location_code: string }>
    >()
    const defaultFields = ['speed', 'fuel_level', 'engine_hours', 'odometer']

    for (const asset of assets) {
      const fields = assetFieldMap.get(asset.id) ?? defaultFields
      const formatKey = fields.join(',')
      if (!formatGroups.has(formatKey)) formatGroups.set(formatKey, [])
      formatGroups.get(formatKey)!.push({
        asset_code: asset.asset_code ?? '',
        location_code: asset.location?.location_code ?? '',
      })
    }

    // 5. Create one Excel sheet per format group
    const wb = XLSX.utils.book_new()
    let sheetIdx = 1
    for (const [formatKey, assetList] of formatGroups) {
      const sensorFields = formatKey.split(',')
      const header = [
        'Location_Code',
        'Asset_Code',
        'timestamp',
        ...sensorFields,
      ]
      const dataRows = assetList.map((a) => [
        a.location_code,
        a.asset_code,
        '',
        ...sensorFields.map(() => ''),
      ])
      const ws = XLSX.utils.aoa_to_sheet([header, ...dataRows])
      XLSX.utils.book_append_sheet(
        wb,
        ws,
        `FM${String(sheetIdx).padStart(3, '0')}`,
      )
      sheetIdx++
    }

    XLSX.writeFile(wb, 'datahub_mass_import_template.xlsx')
  } catch (e: any) {
    console.error('Template download failed:', e)
  } finally {
    isTemplateLoading.value = false
  }
}

// ── Result helpers ───────────────────────────────────────────────────────────
const totalInserted = computed(() =>
  results.value.reduce((s, r) => s + r.inserted, 0),
)
const totalDup = computed(() =>
  results.value.reduce((s, r) => s + r.skipped_duplicate, 0),
)
const totalNoAsset = computed(() =>
  results.value.reduce((s, r) => s + r.skipped_no_asset, 0),
)
</script>

<template>
  <div
    v-if="isOpen"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
  >
    <div
      class="flex w-full max-w-3xl flex-col rounded-lg bg-white shadow-xl dark:bg-muted-900"
      style="max-height: 90vh"
    >
      <!-- Header -->
      <div
        class="flex items-center justify-between border-b border-muted-200 px-6 py-4 dark:border-muted-800"
      >
        <div>
          <h2 class="text-base font-semibold text-muted-900 dark:text-white">
            {{ $t('Datahub Mass Import') }}
          </h2>
          <p class="mt-0.5 text-xs text-muted-500 dark:text-muted-400">
            {{ $t('Excel: each sheet name = Asset Code') }}
          </p>
        </div>
        <button
          class="text-muted-400 hover:text-muted-600"
          @click="handleClose"
        >
          <Icon name="mdi:close" class="h-5 w-5" />
        </button>
      </div>

      <!-- Body (scrollable) -->
      <div class="flex-1 overflow-y-auto p-6">
        <!-- Step 1: File selection -->
        <div v-if="!hasSheets && !isDone" class="space-y-4">
          <input
            ref="fileInput"
            type="file"
            accept=".xlsx,.xls"
            class="hidden"
            @change="handleFileSelect"
          />

          <!-- Drop zone -->
          <div
            class="flex cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed border-muted-300 p-10 transition hover:border-primary-400 dark:border-muted-700"
            @click="triggerFileInput"
          >
            <Icon
              name="mdi:file-excel-outline"
              class="mb-3 h-10 w-10 text-green-500"
            />
            <p class="text-sm font-medium text-muted-700 dark:text-muted-300">
              {{ $t('Click to select Excel file') }}
            </p>
            <p class="mt-1 text-xs text-muted-500">
              {{ $t('Each sheet = one asset (sheet name = Asset Code)') }}
            </p>
          </div>

          <!-- Parse error -->
          <div
            v-if="parseError"
            class="rounded-lg bg-red-50 p-3 text-sm text-red-700 dark:bg-red-900/20 dark:text-red-300"
          >
            <Icon name="mdi:alert-circle" class="me-1 h-4 w-4" />
            {{ parseError }}
          </div>

          <!-- Format info -->
          <div class="rounded-lg bg-blue-50 p-4 dark:bg-blue-900/20">
            <p
              class="mb-2 text-xs font-semibold text-blue-800 dark:text-blue-200"
            >
              {{ $t('Format rules:') }}
            </p>
            <ul class="space-y-1 text-xs text-blue-700 dark:text-blue-300">
              <li>• {{ $t('Sheet name must match Asset Code exactly') }}</li>
              <li>• {{ $t('First row = column headers') }}</li>
              <li>
                •
                {{ $t('Must include: timestamp (unix) or dated_time column') }}
              </li>
              <li>• {{ $t('Duplicate timestamps per asset are skipped') }}</li>
              <li>• {{ $t('Each asset can have its own set of columns') }}</li>
            </ul>
          </div>

          <button
            class="flex w-full items-center justify-center gap-2 rounded-lg border-2 border-primary-500 px-4 py-2 text-sm font-medium text-primary-600 hover:bg-primary-50 disabled:opacity-50 dark:border-primary-400 dark:text-primary-400 dark:hover:bg-primary-900/20"
            :disabled="isTemplateLoading"
            @click="downloadTemplate"
          >
            <Icon
              :name="isTemplateLoading ? 'mdi:loading' : 'mdi:download'"
              :class="['h-4 w-4', isTemplateLoading && 'animate-spin']"
            />
            {{
              isTemplateLoading
                ? $t('Fetching asset formats...')
                : $t('Download Template')
            }}
          </button>
        </div>

        <!-- Step 2: Preview sheets -->
        <div v-else-if="hasSheets && !isImporting && !isDone" class="space-y-4">
          <div class="flex items-center justify-between">
            <p class="text-sm font-medium text-muted-900 dark:text-white">
              {{ parsedSheets.length }} {{ $t('sheets found') }} —
              <span class="text-muted-500 text-xs">{{ selectedFileName }}</span>
            </p>
            <button
              class="text-xs text-primary-600 hover:underline dark:text-primary-400"
              @click="reset"
            >
              {{ $t('Change file') }}
            </button>
          </div>

          <!-- Sheet preview table -->
          <div
            class="max-h-64 overflow-y-auto rounded-lg border border-muted-200 dark:border-muted-800"
          >
            <table class="w-full text-xs">
              <thead class="sticky top-0 bg-muted-100 dark:bg-muted-800">
                <tr>
                  <th class="px-3 py-2 text-left font-medium text-muted-600">
                    {{ $t('Asset Code (Sheet)') }}
                  </th>
                  <th class="px-3 py-2 text-center font-medium text-muted-600">
                    {{ $t('Rows') }}
                  </th>
                  <th class="px-3 py-2 text-left font-medium text-muted-600">
                    {{ $t('Columns') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-muted-100 dark:divide-muted-800">
                <tr
                  v-for="sheet in parsedSheets"
                  :key="sheet.assetCode"
                  class="hover:bg-muted-50 dark:hover:bg-muted-800/50"
                >
                  <td
                    class="px-3 py-2 font-mono font-semibold text-muted-800 dark:text-muted-200"
                  >
                    {{ sheet.assetCode }}
                  </td>
                  <td
                    class="px-3 py-2 text-center text-muted-600 dark:text-muted-400"
                  >
                    {{ sheet.rows.length }}
                  </td>
                  <td class="px-3 py-2 text-muted-500 dark:text-muted-400">
                    {{ sheet.headers.join(', ') }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Step 3: Importing progress -->
        <div v-else-if="isImporting" class="space-y-4">
          <div class="flex flex-col items-center py-6">
            <Icon
              name="mdi:loading"
              class="mb-4 h-10 w-10 animate-spin text-primary-500"
            />
            <p class="text-sm font-medium text-muted-700 dark:text-muted-300">
              {{ $t('Importing') }}
              <span class="font-mono font-semibold text-primary-600">{{
                currentAsset
              }}</span
              >...
            </p>
            <!-- Progress bar -->
            <div
              class="mt-4 h-2 w-full max-w-xs rounded-full bg-muted-200 dark:bg-muted-700"
            >
              <div
                class="h-2 rounded-full bg-primary-500 transition-all duration-300"
                :style="{ width: `${progress}%` }"
              />
            </div>
            <p class="mt-1 text-xs text-muted-500">{{ progress }}%</p>
          </div>
        </div>

        <!-- Step 4: Results -->
        <div v-else-if="isDone" class="space-y-4">
          <!-- Monitoring alert countdown badge -->
          <div
            v-if="alertCheckCountdown !== null"
            class="flex items-center gap-2 rounded-lg bg-warning-50 dark:bg-warning-900/20 border border-warning-200 dark:border-warning-800 px-3 py-2 text-xs text-warning-700 dark:text-warning-300"
          >
            <Icon name="ph:bell" class="h-4 w-4 shrink-0" />
            <span>
              Monitoring alerts
              <strong>{{ alertCheckCountdown }}с</strong> дараа monitoring
              alerts шалгана...
            </span>
          </div>

          <!-- Summary -->
          <div class="grid grid-cols-3 gap-3">
            <div
              class="rounded-lg bg-green-50 p-3 text-center dark:bg-green-900/20"
            >
              <p class="text-2xl font-bold text-green-700 dark:text-green-400">
                {{ totalInserted }}
              </p>
              <p class="text-xs text-green-600 dark:text-green-300">
                {{ $t('Inserted') }}
              </p>
            </div>
            <div
              class="rounded-lg bg-yellow-50 p-3 text-center dark:bg-yellow-900/20"
            >
              <p
                class="text-2xl font-bold text-yellow-700 dark:text-yellow-400"
              >
                {{ totalDup }}
              </p>
              <p class="text-xs text-yellow-600 dark:text-yellow-300">
                {{ $t('Duplicates Skipped') }}
              </p>
            </div>
            <div
              class="rounded-lg bg-red-50 p-3 text-center dark:bg-red-900/20"
            >
              <p class="text-2xl font-bold text-red-600 dark:text-red-400">
                {{ totalNoAsset }}
              </p>
              <p class="text-xs text-red-500 dark:text-red-300">
                {{ $t('Asset Not Found') }}
              </p>
            </div>
          </div>

          <!-- Per-asset result table -->
          <div
            class="max-h-72 overflow-y-auto rounded-lg border border-muted-200 dark:border-muted-800"
          >
            <table class="w-full text-xs">
              <thead class="sticky top-0 bg-muted-100 dark:bg-muted-800">
                <tr>
                  <th class="px-3 py-2 text-left font-medium text-muted-600">
                    {{ $t('Asset Code') }}
                  </th>
                  <th class="px-3 py-2 text-center font-medium text-muted-600">
                    {{ $t('Total') }}
                  </th>
                  <th class="px-3 py-2 text-center font-medium text-green-600">
                    {{ $t('Inserted') }}
                  </th>
                  <th class="px-3 py-2 text-center font-medium text-yellow-600">
                    {{ $t('Dup.') }}
                  </th>
                  <th class="px-3 py-2 text-left font-medium text-red-500">
                    {{ $t('Note') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-muted-100 dark:divide-muted-800">
                <tr
                  v-for="r in results"
                  :key="r.asset_code"
                  class="hover:bg-muted-50 dark:hover:bg-muted-800/50"
                >
                  <td
                    class="px-3 py-2 font-mono font-semibold text-muted-800 dark:text-muted-200"
                  >
                    {{ r.asset_code }}
                  </td>
                  <td class="px-3 py-2 text-center text-muted-600">
                    {{ r.total_rows }}
                  </td>
                  <td class="px-3 py-2 text-center">
                    <span
                      class="rounded-full bg-green-100 px-1.5 py-0.5 text-green-700 dark:bg-green-900/30 dark:text-green-400"
                      >{{ r.inserted }}</span
                    >
                  </td>
                  <td class="px-3 py-2 text-center">
                    <span
                      class="rounded-full bg-yellow-100 px-1.5 py-0.5 text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400"
                      >{{ r.skipped_duplicate }}</span
                    >
                  </td>
                  <td class="px-3 py-2 text-red-500 dark:text-red-400">
                    {{ r.error ?? '' }}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div
        class="flex items-center justify-between border-t border-muted-200 px-6 py-4 dark:border-muted-800"
      >
        <button
          class="text-sm text-muted-500 hover:text-muted-700 dark:hover:text-muted-300"
          @click="handleClose"
        >
          {{ $t('Close') }}
        </button>

        <button
          v-if="hasSheets && !isImporting && !isDone"
          class="rounded-lg bg-primary-500 px-5 py-2 text-sm font-medium text-white hover:bg-primary-600 disabled:opacity-50"
          :disabled="isImporting"
          @click="startImport"
        >
          <Icon name="mdi:upload" class="me-1 h-4 w-4" />
          {{ $t('Start Import') }} ({{ parsedSheets.length }}
          {{ $t('assets') }})
        </button>

        <button
          v-else-if="isDone"
          class="rounded-lg bg-primary-500 px-5 py-2 text-sm font-medium text-white hover:bg-primary-600"
          @click="reset"
        >
          {{ $t('Import Another File') }}
        </button>
      </div>
    </div>
  </div>

  <!-- ─── Browser notification popup (in-page, same as runCommand) ─────── -->
  <Transition
    enter-active-class="transition duration-300 ease-out"
    enter-from-class="translate-x-8 opacity-0"
    enter-to-class="translate-x-0 opacity-100"
    leave-active-class="transition duration-200 ease-in"
    leave-from-class="translate-x-0 opacity-100"
    leave-to-class="translate-x-8 opacity-0"
  >
    <div
      v-if="browserNotif.show"
      class="fixed top-20 right-6 z-[9999] w-[360px] max-w-[calc(100vw-2rem)]"
    >
      <div
        class="relative overflow-hidden rounded-xl bg-white dark:bg-muted-900 shadow-2xl ring-1 ring-muted-200 dark:ring-muted-700"
      >
        <div class="flex items-start gap-3 p-4">
          <div
            class="flex-shrink-0 flex items-center justify-center w-10 h-10 rounded-full bg-danger-100 dark:bg-danger-900/30"
          >
            <Icon name="ph:warning-fill" class="h-6 w-6 text-danger-500" />
          </div>
          <div class="min-w-0 flex-1">
            <p
              class="text-sm font-semibold text-muted-800 dark:text-white pr-4"
            >
              {{ browserNotif.title }}
            </p>
            <p
              class="mt-0.5 text-sm text-muted-500 dark:text-muted-300 break-words"
            >
              {{ browserNotif.message }}
            </p>
            <div
              v-if="browserNotif.asset || browserNotif.location"
              class="mt-2 flex flex-wrap items-center gap-2"
            >
              <span
                v-if="browserNotif.asset"
                class="inline-flex items-center gap-1 rounded bg-muted-100 dark:bg-muted-800 px-1.5 py-0.5 text-xs text-muted-600 dark:text-muted-300"
              >
                <Icon name="ph:wrench" class="h-3 w-3" />{{
                  browserNotif.asset
                }}
              </span>
              <span
                v-if="browserNotif.location"
                class="inline-flex items-center gap-1 rounded bg-muted-100 dark:bg-muted-800 px-1.5 py-0.5 text-xs text-muted-600 dark:text-muted-300"
              >
                <Icon name="ph:map-pin" class="h-3 w-3" />{{
                  browserNotif.location
                }}
              </span>
            </div>
          </div>
          <button
            class="flex-shrink-0 text-muted-400 hover:text-muted-600 dark:hover:text-muted-200"
            @click="closeBrowserPopup"
          >
            <Icon name="ph:x" class="h-4 w-4" />
          </button>
        </div>
        <div class="h-1 w-full bg-muted-100 dark:bg-muted-800">
          <div class="browser-notif-bar h-full bg-danger-500" />
        </div>
      </div>
    </div>
  </Transition>

  <!-- ─── Centered popup modal (notify_popup, same as runCommand) ────────── -->
  <Transition
    enter-active-class="transition duration-200 ease-out"
    enter-from-class="opacity-0"
    enter-to-class="opacity-100"
    leave-active-class="transition duration-150 ease-in"
    leave-from-class="opacity-100"
    leave-to-class="opacity-0"
  >
    <div
      v-if="popupModal.show"
      class="fixed inset-0 z-[9998] flex items-center justify-center p-4"
    >
      <div
        class="absolute inset-0 bg-muted-900/60 backdrop-blur-sm"
        @click="closePopupModal"
      />
      <div
        class="relative z-10 w-[420px] max-w-full overflow-hidden rounded-xl bg-white dark:bg-muted-900 shadow-2xl"
      >
        <div class="flex items-center justify-end px-3 pt-3">
          <button
            class="flex items-center justify-center w-7 h-7 rounded-md border border-muted-200 dark:border-muted-700 text-muted-400 hover:text-muted-600 dark:hover:text-muted-200 transition-colors"
            @click="closePopupModal"
          >
            <Icon name="ph:x" class="h-4 w-4" />
          </button>
        </div>
        <div class="px-6 pb-6 pt-2 text-center">
          <div
            class="mx-auto mb-4 flex items-center justify-center w-16 h-16 rounded-full bg-danger-100 dark:bg-danger-900/30"
          >
            <Icon name="ph:warning-fill" class="h-9 w-9 text-danger-500" />
          </div>
          <p class="text-base font-semibold text-muted-800 dark:text-white">
            {{ popupModal.title }}
          </p>
          <p class="mt-2 text-sm text-muted-500 dark:text-muted-300">
            {{ popupModal.message }}
          </p>
          <div
            v-if="popupModal.asset || popupModal.location"
            class="mt-3 flex flex-wrap items-center justify-center gap-2"
          >
            <span
              v-if="popupModal.asset"
              class="inline-flex items-center gap-1 rounded-full bg-muted-100 dark:bg-muted-800 px-2.5 py-1 text-xs font-medium text-muted-700 dark:text-muted-200"
            >
              <Icon name="ph:wrench" class="h-3.5 w-3.5 text-primary-500" />{{
                popupModal.asset
              }}
            </span>
            <span
              v-if="popupModal.location"
              class="inline-flex items-center gap-1 rounded-full bg-muted-100 dark:bg-muted-800 px-2.5 py-1 text-xs font-medium text-muted-700 dark:text-muted-200"
            >
              <Icon name="ph:map-pin" class="h-3.5 w-3.5 text-primary-500" />{{
                popupModal.location
              }}
            </span>
          </div>
          <div class="mt-6 flex justify-center">
            <BaseButton color="danger" @click="closePopupModal">{{
              $t('Close')
            }}</BaseButton>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>
