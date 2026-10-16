<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import * as XLSX from 'xlsx'

const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()

interface Props {
  assetId?: string | number | null
  deviceId?: string | number | null
}

const props = defineProps<Props>()

const { updateItem, getItems, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

// Fields list with value1-4 — Raw data (device_format_code) болон LiveData
// (Sensor_reading/AssetOwnLiveData.vue-ийн switch) хоёр эх сурвалжийн
// талбарууд НЭГ хүснэгтэд, "is_mode" баганаар нь ялгаж хамт харагдана
const fields = ref<
  Array<{
    id: string | number // Device_tracking_fields id
    trackingId?: string | number | null // Device_tracking_fields id (if exists)
    field_name_mn: string
    field_name_en: string
    field_key?: string
    unit?: string
    code?: string
    value1: number | undefined
    value2: number | undefined
    value3: number | undefined
    value4: number | undefined
    is_show: number
    is_mode: 'rawdata' | 'livedata'
  }>
>([])

// Settings хүснэгтэд зөвхөн is_show=1 (идэвхтэй) талбаруудыг л харуулна —
// is_show=0 бол hide хийнэ
const visibleFields = computed(() => fields.value.filter((f) => f.is_show === 1))

const loading = ref(false)
const importLoading = ref(false)
const fileInput = ref<HTMLInputElement | null>(null)
const importedData = ref<any[]>([])

// Module-level formatCode so saveSettings can access it
const currentFormatCode = ref<string | null>(null)

// Load fields — Raw data (device_format_code-той холбоотой, is_mode='rawdata')
// болон LiveData (asset-д шууд холбогдсон, is_mode='livedata') хоёрыг НЭГ
// жагсаалт болгож нэгтгэнэ
const loadFields = async () => {
  if (!props.assetId) return
  loading.value = true
  try {
    // 1. Get asset's device_format_code
    const assetRes = await getItems<any>({
      collection: 'Assets',
      params: {
        filter: { id: { _eq: props.assetId } },
        fields: ['id', 'device_format_code'],
        limit: 1,
      },
    })
    const assetList = Array.isArray(assetRes)
      ? assetRes
      : (assetRes as any)?.data ?? []
    const formatCode = assetList[0]?.device_format_code
    currentFormatCode.value = formatCode ?? null

    let rawDataFields: (typeof fields.value)[number][] = []

    if (formatCode) {
      // 2. Load field definitions from Device_tracking_fields
      const formatRes = await getItems<any>({
        collection: 'Device_tracking_fields',
        params: {
          filter: {
            code: { _eq: formatCode },
            is_shared_format: { _eq: true },
            company_id: { _eq: myCompanyId },
          },
          sort: ['sort_order'],
          fields: [
            'id',
            'field_key',
            'field_name_mn',
            'field_name_en',
            'unit',
            'sort_order',
          ],
          limit: -1,
        },
      })
      const formatFields = Array.isArray(formatRes)
        ? formatRes
        : (formatRes as any)?.data ?? []

      // 3. Load existing tracking field values for this asset
      const trackingRes = await getItems<any>({
        collection: 'Device_tracking_fields',
        params: {
          filter: { code: { _eq: formatCode }, asset: { _eq: props.assetId } },
          fields: [
            'id',
            'field_key',
            'value1',
            'value2',
            'value3',
            'value4',
            'is_show',
          ],
          limit: -1,
        },
      })
      const trackingList = Array.isArray(trackingRes)
        ? trackingRes
        : (trackingRes as any)?.data ?? []
      const trackingMap = new Map<string, any>()
      trackingList.forEach((tf: any) => {
        if (tf.field_key) trackingMap.set(String(tf.field_key), tf)
      })

      // 4. Merge format fields with existing tracking values
      rawDataFields = formatFields.map((ff: any) => {
        const existing = trackingMap.get(String(ff.field_key ?? ''))
        return {
          id: ff.id,
          trackingId: existing?.id ?? null,
          field_name_mn: ff.field_name_mn || ff.field_key,
          field_name_en: ff.field_name_en || ff.field_key,
          field_key: ff.field_key,
          unit: ff.unit || '',
          code: formatCode,
          value1: existing?.value1 ?? undefined,
          value2: existing?.value2 ?? undefined,
          value3: existing?.value3 ?? undefined,
          value4: existing?.value4 ?? undefined,
          is_show: existing?.is_show === 0 ? 0 : 1,
          is_mode: 'rawdata' as const,
        }
      })
    }

    // 5. LiveData (AssetOwnLiveData.vue-ийн switch-ээр бүртгэгдсэн) талбарууд —
    // device_format_code-оос үл хамааран, зөвхөн asset-аар шүүнэ
    const liveDataRes = await getItems<any>({
      collection: 'Device_tracking_fields',
      params: {
        filter: {
          asset: { _eq: props.assetId },
          is_mode: { _eq: 'livedata' },
        },
        sort: ['sort_order'],
        fields: [
          'id',
          'field_key',
          'field_name_mn',
          'field_name_en',
          'unit',
          'code',
          'value1',
          'value2',
          'value3',
          'value4',
          'is_show',
        ],
        limit: -1,
      },
    })
    const liveDataItems = Array.isArray(liveDataRes)
      ? liveDataRes
      : (liveDataRes as any)?.data ?? []
    // "code" баганад тухайн sensor-ын device_id хадгалагддаг (2 sensor ижил
    // field_key үүсгэвэл code-оор нь ялгана) — хүснэгтэд шууд харуулна
    const liveDataFields = liveDataItems.map((item: any) => ({
      id: item.id,
      trackingId: item.id,
      field_name_mn: item.field_name_mn || item.field_key,
      field_name_en: item.field_name_en || item.field_key,
      field_key: item.field_key,
      unit: item.unit || '',
      code: item.code || '',
      value1: item.value1 ?? undefined,
      value2: item.value2 ?? undefined,
      value3: item.value3 ?? undefined,
      value4: item.value4 ?? undefined,
      is_show: item.is_show === 0 ? 0 : 1,
      is_mode: 'livedata' as const,
    }))

    fields.value = [...rawDataFields, ...liveDataFields]
  } catch (error) {
    console.error('Error loading fields:', error)
  } finally {
    loading.value = false
  }
}

const saveSettings = async () => {
  loading.value = true
  try {
    // Save device_format_code back to the Asset
    // if (props.assetId && currentFormatCode.value) {
    //   await updateItem({
    //     collection: 'Assets',
    //     id: String(props.assetId),
    //     item: { device_format_code: currentFormatCode.value },
    //   })
    // }

    for (const field of fields.value) {
      const payload = {
        value1: field.value1 ?? null,
        value2: field.value2 ?? null,
        value3: field.value3 ?? null,
        value4: field.value4 ?? null,
        is_show: field.is_show,
      }

      if (field.trackingId) {
        // Update existing Device_tracking_fields record
        await updateItem({
          collection: 'Device_tracking_fields',
          id: String(field.trackingId),
          item: payload,
        })
      } else {
        // Create new Device_tracking_fields record for this asset + field
        const created = await createItems({
          collection: 'Device_tracking_fields',
          items: [
            {
              asset: parseInt(String(props.assetId)),
              code:
                field.is_mode === 'livedata'
                  ? null
                  : currentFormatCode.value ?? null,
              field_key: field.field_key,
              field_name_mn: field.field_name_mn,
              field_name_en: field.field_name_en,
              unit: field.unit,
              is_shared_format: false,
              is_mode: field.is_mode,
              company_id: myCompanyId,
              ...payload,
            },
          ],
        })
        // Store the new id so subsequent saves update instead of create
        const createdItem = Array.isArray(created)
          ? created[0]
          : (created as any)?.data?.[0]
        if (createdItem?.id) {
          field.trackingId = createdItem.id
        }
      }
    }

    toaster.show({
      title: t('Success'),
      message: t('Settings saved successfully'),
      color: 'success',
      icon: 'ph:check',
      closable: true,
    })
  } catch (error) {
    console.error('Error saving settings:', error)
    toaster.show({
      title: t('Error'),
      message: t('Error saving settings: ') + error,
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  } finally {
    loading.value = false
  }
}

// is_show switch дарахад тухайн field-ийг DB-д (бодит мөр байвал) шууд
// хадгалж, локал байдлаар toggle хийнэ — шинэ (trackingId-гүй) field бол
// дараагийн "Save Settings" дарахад л хадгалагдана
const toggleIsShow = async (field: (typeof fields.value)[number]) => {
  field.is_show = field.is_show === 0 ? 1 : 0

  if (!field.trackingId) return
  try {
    await updateItem({
      collection: 'Device_tracking_fields',
      id: String(field.trackingId),
      item: { is_show: field.is_show },
    })
  } catch (error) {
    console.error('Error updating is_show:', error)
  }
}

const resetForm = () => {
  // Reset value1-4 but keep fields
  fields.value.forEach((field) => {
    field.value1 = undefined
    field.value2 = undefined
    field.value3 = undefined
    field.value4 = undefined
  })
}

const refreshFields = () => {
  loadFields()
}

// Format value with decimals and unit
const formatValue = (value: any, decimals: number = 1, unit: string = '') => {
  if (value === null || value === undefined || value === '') return '-'
  const num = typeof value === 'number' ? value : parseFloat(value)
  if (isNaN(num)) return '-'
  return `${num.toFixed(decimals)}${unit ? ' ' + unit : ''}`
}

// Bilingual field definitions
const fieldDefinitions = {
  field_name: { en: 'Field Name', mn: 'Талбарын нэр' },
  unit: { en: 'Unit', mn: 'Хэмжих нэгж' },
  value1: { en: 'Value 1', mn: 'Утга 1' },
  value2: { en: 'Value 2', mn: 'Утга 2' },
  value3: { en: 'Value 3', mn: 'Утга 3' },
  value4: { en: 'Value 4', mn: 'Утга 4' },
}

// Export to Excel with bilingual headers
const exportToExcel = () => {
  if (fields.value.length === 0) {
    toaster.show({
      title: t('Warning'),
      message: t('No data to export'),
      color: 'warning',
      icon: 'ph:warning',
      closable: true,
    })
    return
  }

  const exportData = fields.value.map((field) => {
    return {
      [fieldDefinitions.field_name.mn]: field.field_name_mn,
      [fieldDefinitions.field_name.en]: field.field_name_en,
      field_key: field.field_key,
      [fieldDefinitions.unit.mn]: field.unit || '-',
      [fieldDefinitions.unit.en]: field.unit || '-',
      [fieldDefinitions.value1.mn]: field.value1 || '-',
      [fieldDefinitions.value1.en]: field.value1 || '-',
      [fieldDefinitions.value2.mn]: field.value2 || '-',
      [fieldDefinitions.value2.en]: field.value2 || '-',
      [fieldDefinitions.value3.mn]: field.value3 || '-',
      [fieldDefinitions.value3.en]: field.value3 || '-',
      [fieldDefinitions.value4.mn]: field.value4 || '-',
      [fieldDefinitions.value4.en]: field.value4 || '-',
    }
  })

  const worksheet = XLSX.utils.json_to_sheet(exportData)
  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Device Settings')

  const fileName = `device_settings_${props.assetId}_${
    new Date().toISOString().split('T')[0]
  }.xlsx`
  XLSX.writeFile(workbook, fileName)
}

// Export to JSON with bilingual field names
const exportToJSON = () => {
  if (fields.value.length === 0) {
    toaster.show({
      title: t('Warning'),
      message: t('No data to export'),
      color: 'warning',
      icon: 'ph:warning',
      closable: true,
    })
    return
  }

  const exportData = fields.value.map((field) => {
    return {
      [fieldDefinitions.field_name.mn]: field.field_name_mn,
      [fieldDefinitions.field_name.en]: field.field_name_en,
      field_key: field.field_key,
      [fieldDefinitions.unit.mn]: field.unit || null,
      [fieldDefinitions.unit.en]: field.unit || null,
      [fieldDefinitions.value1.mn]: field.value1 || null,
      [fieldDefinitions.value1.en]: field.value1 || null,
      [fieldDefinitions.value2.mn]: field.value2 || null,
      [fieldDefinitions.value2.en]: field.value2 || null,
      [fieldDefinitions.value3.mn]: field.value3 || null,
      [fieldDefinitions.value3.en]: field.value3 || null,
      [fieldDefinitions.value4.mn]: field.value4 || null,
      [fieldDefinitions.value4.en]: field.value4 || null,
    }
  })

  const jsonStr = JSON.stringify(exportData, null, 2)
  const blob = new Blob([jsonStr], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `device_settings_${props.assetId}_${
    new Date().toISOString().split('T')[0]
  }.json`
  link.click()
  URL.revokeObjectURL(url)
}

// Save settings to history table
const saveToHistory = async () => {
  if (fields.value.length === 0) {
    toaster.show({
      title: t('Warning'),
      message: t('No data to save'),
      color: 'warning',
      icon: 'ph:warning',
      closable: true,
    })
    return
  }

  try {
    loading.value = true
    const { createItems } = useDirectusItems()

    const historyRecord = {
      asset: parseInt(String(props.assetId)),
      timestamp: new Date().toISOString(),
      data_type: 'device_settings',
      data_snapshot: JSON.stringify(
        fields.value.map((field) => ({
          field_name_mn: field.field_name_mn,
          field_name_en: field.field_name_en,
          field_key: field.field_key,
          unit: field.unit,
          value1: field.value1,
          value2: field.value2,
          value3: field.value3,
          value4: field.value4,
        })),
      ),
      record_count: fields.value.length,
      date_range_start: new Date().toISOString(),
      date_range_end: new Date().toISOString(),
      company_id: myCompanyId,
    }

    await createItems({
      collection: 'Datahub_history',
      items: [historyRecord],
    })

    toaster.show({
      title: t('Success'),
      message: t('Settings successfully saved to history'),
      color: 'success',
      icon: 'ph:database',
      closable: true,
    })
  } catch (e: any) {
    console.error('Error saving history:', e)
    toaster.show({
      title: t('Error'),
      message: t('Error saving history: ') + e.message,
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  } finally {
    loading.value = false
  }
}

// Import Excel data
const handleFileUpload = async (event: any) => {
  const file = event.target.files[0]
  if (!file) return

  try {
    importLoading.value = true

    // Read Excel file
    const arrayBuffer = await file.arrayBuffer()
    const workbook = XLSX.read(arrayBuffer, { type: 'array' })
    const firstSheet = workbook.Sheets[workbook.SheetNames[0]]
    const jsonData = XLSX.utils.sheet_to_json(firstSheet)

    if (jsonData.length === 0) {
      toaster.show({
        title: t('Error'),
        message: t('Excel file is empty'),
        color: 'danger',
        icon: 'ph:warning',
        closable: true,
      })
      return
    }

    importedData.value = jsonData
    await processImportedData(jsonData)
  } catch (e: any) {
    console.error('Error importing Excel:', e)
    toaster.show({
      title: t('Error'),
      message: t('Error importing Excel file: ') + e.message,
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  } finally {
    importLoading.value = false
    if (fileInput.value) {
      fileInput.value.value = ''
    }
  }
}

const processImportedData = async (data: any[]) => {
  if (!props.assetId) {
    toaster.show({
      title: t('Error'),
      message: t('Asset ID not found'),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
    return
  }

  try {
    // Get tracking field configuration
    if (fields.value.length === 0) {
      await loadFields()
    }

    if (fields.value.length === 0) {
      toaster.show({
        title: t('Error'),
        message: t('Configure field settings first'),
        color: 'warning',
        icon: 'ph:warning',
        closable: true,
      })
      return
    }

    // Create records for Asset_field_data_json
    const records = data.map((row) => {
      // Extract timestamp (use current time if not provided)
      let timestamp = Date.now()
      if (row.timestamp) {
        timestamp = new Date(row.timestamp).getTime()
      }

      // Build field_values JSON based on tracking fields config
      const fieldValues: Record<string, any> = {}
      fields.value.forEach((field) => {
        const fieldKey = field.field_key || ''
        // Try to find value in row data (case-insensitive)
        let value = null

        // Try exact match first
        if (row[fieldKey] !== undefined) {
          value = row[fieldKey]
        } else {
          // Try case-insensitive match
          const rowKey = Object.keys(row).find(
            (k) => k.toLowerCase() === fieldKey.toLowerCase(),
          )
          if (rowKey) {
            value = row[rowKey]
          }
        }

        if (value !== null && value !== undefined) {
          fieldValues[fieldKey] = value
        }
      })

      return {
        asset: parseInt(String(props.assetId)),
        timestamp: timestamp,
        field_values: fieldValues,
        company_id: myCompanyId,
      }
    })

    // Save to Asset_field_data_json
    await createItems({
      collection: 'Asset_field_data_json',
      items: records,
    })

    // Create history snapshot
    const historyRecord = {
      asset: parseInt(String(props.assetId)),
      timestamp: Date.now(),
      data_type: 'tracking_data_import',
      data_snapshot: JSON.stringify(data),
      record_count: data.length,
      date_range_start: Date.now(),
      date_range_end: Date.now(),
      company_id: myCompanyId,
    }

    await createItems({
      collection: 'Datahub_history',
      items: [historyRecord],
    })

    toaster.show({
      title: t('Success'),
      message: t(`${data.length} records imported successfully`),
      color: 'success',
      icon: 'ph:check-circle',
      closable: true,
    })
  } catch (e: any) {
    console.error('Error processing imported data:', e)
    toaster.show({
      title: t('Error'),
      message: t('Error saving data: ') + e.message,
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  }
}

const triggerFileInput = () => {
  fileInput.value?.click()
}

// Download sample Excel template
const downloadSampleExcel = () => {
  if (fields.value.length === 0) {
    toaster.show({
      title: t('Warning'),
      message: t('Configure field settings first'),
      color: 'warning',
      icon: 'ph:warning',
      closable: true,
    })
    return
  }

  try {
    // Create headers with field names
    const headers = ['timestamp', ...fields.value.map((f) => f.field_key || '')]

    // Create second row with Mongolian field names as description
    const mnNames = [
      'Date & time',
      ...fields.value.map((f) => f.field_name_mn || f.field_key || ''),
    ]

    // Create third row with units
    const units = [
      'YYYY-MM-DD HH:MM:SS',
      ...fields.value.map((f) => (f.unit ? `(${f.unit})` : '')),
    ]

    // Create sample data rows (3 examples)
    const sampleRow1 = ['2026-04-04 14:30:00', ...fields.value.map(() => '')]
    const sampleRow2 = ['2026-04-04 15:00:00', ...fields.value.map(() => '')]
    const sampleRow3 = ['2026-04-04 15:30:00', ...fields.value.map(() => '')]

    // Create worksheet with all rows
    const ws = XLSX.utils.aoa_to_sheet([
      headers,
      mnNames,
      units,
      sampleRow1,
      sampleRow2,
      sampleRow3,
    ])

    // Set column widths
    const colWidths = [{ wch: 20 }, ...fields.value.map(() => ({ wch: 15 }))]
    ws['!cols'] = colWidths

    // Style header row (first row should be bold)
    const range = XLSX.utils.decode_range(ws['!ref'] || 'A1')
    for (let C = range.s.c; C <= range.e.c; ++C) {
      const address = XLSX.utils.encode_col(C) + '1'
      if (!ws[address]) continue
      ws[address].s = {
        font: { bold: true },
        fill: { fgColor: { rgb: 'CCCCCC' } },
      }
    }

    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, 'Tracking Data')

    const fileName = `tracking_data_template_${props.assetId}_${
      new Date().toISOString().split('T')[0]
    }.xlsx`
    XLSX.writeFile(wb, fileName)

    toaster.show({
      title: t('Success'),
      message: t(`${fields.value.length} column Excel template downloaded`),
      color: 'success',
      icon: 'ph:download',
      closable: true,
    })
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

// Load fields on mount
onMounted(() => {
  if (props.assetId) {
    loadFields()
  }
})
</script>

<template>
  <div class="field_settings">
    <div class="w-full">
      <BaseCard>
        <div class="space-y-6">
          <div class="flex items-center justify-between">
            <div>
              <BaseHeading as="h3" size="md" weight="medium" class="mb-2">
                {{ $t('Monitoring Field Settings') }}
              </BaseHeading>
            </div>

            <div class="flex items-center gap-2">
              <BaseButton
                color="primary"
                :loading="loading"
                @click="saveSettings"
              >
                {{ $t('Save Settings') }}
              </BaseButton>
              <BaseButton
                color="primary"
                :loading="loading"
                @click="refreshFields"
              >
                <Icon name="ph:arrows-clockwise" class="h-4 w-4 mr-2" />
                {{ $t('Refresh Fields') }}
              </BaseButton>

              <!-- Import Button -->
              <div
                class="flex items-center gap-2 border-l border-muted-300 dark:border-muted-700 pl-2"
              >
                <input
                  ref="fileInput"
                  type="file"
                  accept=".xlsx,.xls"
                  class="hidden"
                  @change="handleFileUpload"
                />
                <BaseButton
                  color="info"
                  :disabled="loading || fields.length === 0"
                  @click="downloadSampleExcel"
                >
                  <Icon name="ph:download" class="h-4 w-4 mr-2" />
                  {{ $t('Template') }}
                </BaseButton>
                <!-- <BaseButton
                  color="success"
                  :loading="importLoading"
                  :disabled="loading || fields.length === 0"
                  @click="triggerFileInput"
                >
                  <Icon name="ph:upload" class="h-4 w-4 mr-2" />
                  {{ $t('Import Excel') }}
                </BaseButton> -->
              </div>
            </div>
          </div>

          <!-- Table -->
          <div v-if="visibleFields.length > 0">
            <!-- Import Instructions -->
            <!-- <div
              class="mb-4 p-4 bg-info-50 dark:bg-info-900/20 border border-info-200 dark:border-info-800 rounded-lg"
            >
              <div class="flex items-start gap-3">
                <Icon
                  name="ph:info"
                  class="h-5 w-5 text-info-600 dark:text-info-400 mt-0.5"
                />
                <div class="flex-1">
                  <p
                    class="text-sm text-info-800 dark:text-info-200 font-medium mb-2"
                  >
                    {{ $t('Excel import instructions') }}:
                  </p>
                  <ul
                    class="text-xs text-info-700 dark:text-info-300 space-y-1"
                  >
                    <li>
                      •
                      {{ $t('Excel file must contain the following fields') }}:
                    </li>
                    <li class="ml-4">
                      <code
                        class="bg-info-100 dark:bg-info-900/40 px-1 rounded"
                      >
                        {{ fields.map((f) => f.field_key).join(', ') }}
                      </code>
                    </li>
                    <li>
                      •
                      {{
                        $t(
                          'timestamp field (optional) - date and time information',
                        )
                      }}
                    </li>
                    <li>• {{ $t('First row must be a header') }}</li>
                  </ul>
                </div>
              </div>
            </div> -->

            <div class="overflow-x-auto">
              <table class="w-full">
                <thead>
                  <tr class="border-b border-muted-200 dark:border-muted-700">
                    <th
                      class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                    >
                      #
                    </th>
                    <th
                      class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                    >
                      {{ $t('Type') }}
                    </th>
                    <th
                      class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                    >
                      {{ $t('Code') }}
                    </th>
                    <th
                      class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                    >
                      {{ $t('Field Name') }}
                    </th>
                    <th
                      class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                    >
                      {{ $t('Value 1') }}
                    </th>
                    <th
                      class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                    >
                      {{ $t('Value 2') }}
                    </th>
                    <th
                      class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                    >
                      {{ $t('Value 3') }}
                    </th>
                    <th
                      class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                    >
                      {{ $t('Value 4') }}
                    </th>
                    <th
                      class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                    >
                      {{ $t('Active') }}
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="(field, index) in visibleFields"
                    :key="field.id"
                    class="border-b border-muted-200 dark:border-muted-700 hover:bg-muted-50 dark:hover:bg-muted-800/50 transition-colors"
                  >
                    <td
                      class="py-3 px-4 text-sm text-muted-600 dark:text-muted-400"
                    >
                      {{ index + 1 }}
                    </td>
                    <td class="py-3 px-4">
                      <span
                        class="rounded-full px-2 py-0.5 text-xs font-medium"
                        :class="
                          field.is_mode === 'livedata'
                            ? 'bg-info-100 text-info-700 dark:bg-info-500/20 dark:text-info-400'
                            : 'bg-muted-200 text-muted-600 dark:bg-muted-700 dark:text-muted-300'
                        "
                      >
                        {{
                          field.is_mode === 'livedata' ? $t('Live') : $t('Raw')
                        }}
                      </span>
                    </td>
                    <td
                      class="py-3 px-4 text-sm text-muted-600 dark:text-muted-400"
                    >
                      {{ field.code || '-' }}
                    </td>
                    <td class="py-3 px-4">
                      <div class="flex flex-col">
                        <BaseText size="sm" weight="medium">
                          {{ field.field_name_mn }}
                        </BaseText>
                        <BaseText
                          size="xs"
                          class="text-muted-400"
                          v-if="field.unit"
                        >
                          ({{ field.unit }})
                        </BaseText>
                      </div>
                    </td>
                    <td class="py-3 px-4">
                      <BaseInput
                        v-model.number="field.value1"
                        type="number"
                        placeholder="Value 1"
                        size="sm"
                        class="max-w-[120px]"
                        :disabled="!field.is_show"
                      />
                    </td>
                    <td class="py-3 px-4">
                      <BaseInput
                        v-model.number="field.value2"
                        type="number"
                        placeholder="Value 2"
                        size="sm"
                        class="max-w-[120px]"
                        :disabled="!field.is_show"
                      />
                    </td>
                    <td class="py-3 px-4">
                      <BaseInput
                        v-model.number="field.value3"
                        type="number"
                        placeholder="Value 3"
                        size="sm"
                        class="max-w-[120px]"
                        :disabled="!field.is_show"
                      />
                    </td>
                    <td class="py-3 px-4">
                      <BaseInput
                        v-model.number="field.value4"
                        type="number"
                        placeholder="Value 4"
                        size="sm"
                        class="max-w-[120px]"
                        :disabled="!field.is_show"
                      />
                    </td>
                    <td class="py-3 px-4">
                      <button
                        type="button"
                        class="w-8 h-5 rounded-full transition-colors relative shrink-0 inline-flex"
                        :class="
                          field.is_show
                            ? 'bg-primary-500'
                            : 'bg-muted-300 dark:bg-muted-600'
                        "
                        :title="$t('Show in charts')"
                        @click="toggleIsShow(field)"
                      >
                        <span
                          class="absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform"
                          :class="
                            field.is_show ? 'translate-x-3' : 'translate-x-0'
                          "
                        />
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Empty State -->
          <div
            v-else
            class="text-center py-12 border-2 border-dashed border-muted-200 dark:border-muted-700 rounded-lg"
          >
            <Icon
              name="ph:file-dashed"
              class="h-12 w-12 mx-auto text-muted-400 mb-4"
            />
            <BaseHeading as="h4" size="sm" weight="medium" class="mb-2">
              {{ $t('No tracking fields found') }}
            </BaseHeading>
            <BaseParagraph size="sm" class="text-muted-400 mb-4">
              {{
                $t(
                  'No format selected for this asset. Please select a format from the OwnTracking tab.',
                )
              }}
            </BaseParagraph>
            <BaseButton
              color="default"
              :loading="loading"
              @click="refreshFields"
            >
              <Icon name="ph:arrows-clockwise" class="h-4 w-4 mr-2" />
              {{ $t('Refresh Fields') }}
            </BaseButton>
          </div>

          <!-- Actions -->
          <div
            v-if="visibleFields.length > 0"
            class="flex justify-between items-center pt-4 border-muted-200 dark:border-muted-700"
          >
            <BaseText size="sm" class="text-muted-500">
              {{ visibleFields.length }} {{ $t('fields configured') }}
            </BaseText>
            <div class="flex gap-2">
              <!-- <BaseButton
                color="default"
                :disabled="loading"
                @click="resetForm"
              >
                {{ $t('Reset Values') }}
              </BaseButton> -->
              <!-- <BaseButton
                color="primary"
                :loading="loading"
                @click="saveSettings"
              >
                {{ $t('Save Settings') }}
              </BaseButton> -->
            </div>
          </div>
        </div>
      </BaseCard>
    </div>
  </div>
</template>
