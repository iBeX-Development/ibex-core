<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import * as XLSX from 'xlsx'

const { t } = useI18n({ useScope: 'global' })

interface Props {
  assetId?: string | number | null
}

const props = defineProps<Props>()

const { getItems, createItems, updateItem, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

// Available field options (max 10)
const availableFields = [
  { key: 'latitude', mn: 'Latitude', en: 'Latitude', unit: '°' },
  { key: 'longitude', mn: 'Longitude', en: 'Longitude', unit: '°' },
  { key: 'speed', mn: 'Speed', en: 'Speed', unit: 'км/ц' },
  { key: 'altitude', mn: 'Өндөр', en: 'Altitude', unit: 'м' },
  { key: 'direction', mn: 'Чиглэл', en: 'Direction', unit: '°' },
  { key: 'satellites', mn: 'Дагуул', en: 'Satellites', unit: '' },
  { key: 'odometer', mn: 'Гүйлт', en: 'Odometer', unit: 'км' },
  { key: 'fuel_level', mn: 'Fuel', en: 'Fuel Level', unit: '%' },
  {
    key: 'engine_hours',
    mn: 'Engine hours',
    en: 'Engine Hours',
    unit: 'ц',
  },
  { key: 'temperature', mn: 'Температур', en: 'Temperature', unit: '°C' },
]

interface FieldConfig {
  id?: string | number
  field_key: string
  field_name_mn: string
  field_name_en: string
  unit: string
  is_active: boolean
  sort_order: number
}

const selectedFields = ref<FieldConfig[]>([])
const loading = ref(false)
const isOpen = ref(false)

const loadFieldConfig = async () => {
  if (!props.assetId) return

  loading.value = true
  try {
    const response = await getItems<any>({
      collection: 'Device_tracking_fields',
      params: {
        filter: {
          asset: { _eq: props.assetId },
        },
        sort: ['sort_order'],
      },
    })

    const items = Array.isArray(response)
      ? response
      : (response as any)?.data || []

    if (items.length > 0) {
      selectedFields.value = items.map((item: any) => ({
        id: item.id,
        field_key: item.field_key,
        field_name_mn: item.field_name_mn,
        field_name_en: item.field_name_en,
        unit: item.unit || '',
        is_active: item.is_active ?? true,
        sort_order: item.sort_order || 0,
      }))
    } else {
      // Initialize with default first 7 fields
      selectedFields.value = availableFields
        .slice(0, 7)
        .map((field, index) => ({
          field_key: field.key,
          field_name_mn: field.mn,
          field_name_en: field.en,
          unit: field.unit,
          is_active: true,
          sort_order: index,
        }))
    }
  } catch (error) {
    console.error('Error loading field config:', error)
  } finally {
    loading.value = false
  }
}

const saveFieldConfig = async () => {
  if (!props.assetId) {
    alert(t('Asset ID not found'))
    return
  }

  if (selectedFields.value.filter((f) => f.is_active).length > 10) {
    alert(t('Maximum 10 fields can be selected'))
    return
  }

  loading.value = true
  try {
    // Delete existing configs
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

    // Delete old records
    if (existing.length > 0) {
      try {
        const idsToDelete = existing.map((item: any) => item.id)
        await deleteItems({
          collection: 'Device_tracking_fields',
          items: idsToDelete,
        })
      } catch (e) {
        console.error('Error deleting old config:', e)
      }
    }

    // Create new configs
    const newConfigs = selectedFields.value
      .filter((f) => f.is_active)
      .map((field, index) => ({
        asset: parseInt(String(props.assetId)),
        field_key: field.field_key,
        field_name_mn: field.field_name_mn,
        field_name_en: field.field_name_en,
        unit: field.unit || '',
        is_active: true,
        sort_order: index,
        company_id: myCompanyId,
      }))

    if (newConfigs.length > 0) {
      await createItems({
        collection: 'Device_tracking_fields',
        items: newConfigs,
      })
    }

    alert(t('Field settings saved successfully'))
    isOpen.value = false
  } catch (error) {
    console.error('Error saving field config:', error)
    alert(t('Error saving'))
  } finally {
    loading.value = false
  }
}

const addField = () => {
  if (selectedFields.value.length >= 10) {
    alert(t('Maximum 10 fields can be added'))
    return
  }

  // Find first unused field
  const usedKeys = selectedFields.value.map((f) => f.field_key)
  const unusedField = availableFields.find((f) => !usedKeys.includes(f.key))

  if (unusedField) {
    selectedFields.value.push({
      field_key: unusedField.key,
      field_name_mn: unusedField.mn,
      field_name_en: unusedField.en,
      unit: unusedField.unit,
      is_active: true,
      sort_order: selectedFields.value.length,
    })
  }
}

const removeField = (index: number) => {
  selectedFields.value.splice(index, 1)
  // Reorder
  selectedFields.value.forEach((field, idx) => {
    field.sort_order = idx
  })
}

const moveUp = (index: number) => {
  if (index === 0) return
  const temp = selectedFields.value[index]
  selectedFields.value[index] = selectedFields.value[index - 1]
  selectedFields.value[index - 1] = temp
  // Update sort order
  selectedFields.value.forEach((field, idx) => {
    field.sort_order = idx
  })
}

const moveDown = (index: number) => {
  if (index === selectedFields.value.length - 1) return
  const temp = selectedFields.value[index]
  selectedFields.value[index] = selectedFields.value[index + 1]
  selectedFields.value[index + 1] = temp
  // Update sort order
  selectedFields.value.forEach((field, idx) => {
    field.sort_order = idx
  })
}

const openModal = () => {
  isOpen.value = true
  loadFieldConfig()
}

const closeModal = () => {
  isOpen.value = false
}

// Export field structure as Excel template
const exportTemplateExcel = async () => {
  await loadFieldConfig()

  if (selectedFields.value.length === 0) {
    alert(t('No field settings found'))
    return
  }

  const activeFields = selectedFields.value.filter((f) => f.is_active)

  // Create header row with bilingual names
  const headers: any = {}
  activeFields.forEach((field) => {
    headers[`${field.field_name_mn} (${field.unit})`] = ''
    headers[`${field.field_name_en} (${field.unit})`] = ''
  })

  // Create sample data row
  const sampleData: any = {}
  activeFields.forEach((field) => {
    const sampleValue = getSampleValue(field.field_key)
    sampleData[`${field.field_name_mn} (${field.unit})`] = sampleValue
    sampleData[`${field.field_name_en} (${field.unit})`] = sampleValue
  })

  const worksheet = XLSX.utils.json_to_sheet([headers, sampleData])
  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Own Tracking Template')

  const fileName = `own_tracking_template_${props.assetId}_${
    new Date().toISOString().split('T')[0]
  }.xlsx`
  XLSX.writeFile(workbook, fileName)
  alert(t('Template exported successfully'))
}

// Export field structure as JSON template
const exportTemplateJSON = async () => {
  await loadFieldConfig()

  if (selectedFields.value.length === 0) {
    alert(t('No field settings found'))
    return
  }

  const activeFields = selectedFields.value.filter((f) => f.is_active)

  const template = {
    asset_id: props.assetId,
    created_at: new Date().toISOString(),
    fields: activeFields.map((field) => ({
      field_key: field.field_key,
      field_name_mn: field.field_name_mn,
      field_name_en: field.field_name_en,
      unit: field.unit,
      sort_order: field.sort_order,
    })),
    sample_data: {
      timestamp: Math.floor(Date.now() / 1000),
      ...Object.fromEntries(
        activeFields.map((field) => [
          field.field_key,
          getSampleValue(field.field_key),
        ]),
      ),
    },
  }

  const jsonStr = JSON.stringify(template, null, 2)
  const blob = new Blob([jsonStr], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `own_tracking_template_${props.assetId}_${
    new Date().toISOString().split('T')[0]
  }.json`
  link.click()
  URL.revokeObjectURL(url)
  alert(t('Template exported successfully'))
}

// Get sample value for field
const getSampleValue = (fieldKey: string): any => {
  const samples: Record<string, any> = {
    latitude: 47.9184,
    longitude: 106.9177,
    speed: 45,
    altitude: 1350,
    direction: 180,
    satellites: 12,
    odometer: 125000,
    fuel_level: 75,
    engine_hours: 1234.5,
    temperature: 25,
  }
  return samples[fieldKey] || 0
}

defineExpose({ openModal, exportTemplateExcel, exportTemplateJSON })

onMounted(() => {
  if (props.assetId) {
    loadFieldConfig()
  }
})
</script>

<template>
  <div class="tracking-fields-config">
    <BaseButton color="default" @click="openModal" :disabled="!assetId">
      <Icon name="ph:gear" class="h-4 w-4 mr-2" />
      {{ $t('Field settings') }}
    </BaseButton>

    <TairoModal :open="isOpen" size="lg" @close="closeModal">
      <template #header>
        <div class="flex items-center gap-3">
          <Icon name="ph:list-checks" class="h-5 w-5" />
          <div>
            <BaseHeading as="h3" size="sm" weight="medium">
              {{ $t('Tracking Data Fields (Max 10)') }}
            </BaseHeading>
            <BaseParagraph size="xs" class="text-muted-400">
              {{
                $t(
                  'Select up to 10 fields and configure their Mongolian/English names',
                )
              }}
            </BaseParagraph>
          </div>
        </div>
      </template>

      <div v-if="loading" class="text-center py-8">
        <Icon
          name="svg-spinners:blocks-shuffle-3"
          class="h-8 w-8 mx-auto text-primary-500"
        />
      </div>

      <div v-else class="space-y-4">
        <!-- Selected Fields List -->
        <div class="space-y-2">
          <div
            v-for="(field, index) in selectedFields"
            :key="index"
            class="border border-muted-200 dark:border-muted-700 rounded-lg p-4 flex items-center gap-3"
          >
            <!-- Order buttons -->
            <div class="flex flex-col gap-1">
              <BaseButton
                size="sm"
                color="default"
                @click="moveUp(index)"
                :disabled="index === 0"
              >
                <Icon name="ph:caret-up" class="h-4 w-4" />
              </BaseButton>
              <BaseButton
                size="sm"
                color="default"
                @click="moveDown(index)"
                :disabled="index === selectedFields.length - 1"
              >
                <Icon name="ph:caret-down" class="h-4 w-4" />
              </BaseButton>
            </div>

            <!-- Field Key -->
            <div class="flex-shrink-0 w-32">
              <BaseSelect
                v-model="field.field_key"
                @change="
                  () => {
                    const selected = availableFields.find(
                      (f) => f.key === field.field_key,
                    )
                    if (selected) {
                      field.field_name_mn = selected.mn
                      field.field_name_en = selected.en
                      field.unit = selected.unit
                    }
                  }
                "
              >
                <option
                  v-for="opt in availableFields"
                  :key="opt.key"
                  :value="opt.key"
                >
                  {{ opt.key }}
                </option>
              </BaseSelect>
            </div>

            <!-- Mongolian Name -->
            <div class="flex-1">
              <BaseInput
                v-model="field.field_name_mn"
                :placeholder="$t('Mongolian name')"
                size="sm"
              />
            </div>

            <!-- English Name -->
            <div class="flex-1">
              <BaseInput
                v-model="field.field_name_en"
                :placeholder="$t('English name')"
                size="sm"
              />
            </div>

            <!-- Unit -->
            <div class="w-20">
              <BaseInput
                v-model="field.unit"
                :placeholder="$t('Unit')"
                size="sm"
              />
            </div>

            <!-- Remove button -->
            <BaseButton size="sm" color="danger" @click="removeField(index)">
              <Icon name="ph:trash" class="h-4 w-4" />
            </BaseButton>
          </div>
        </div>

        <!-- Add Field Button -->
        <BaseButton
          color="primary"
          @click="addField"
          :disabled="selectedFields.length >= 10"
          class="w-full"
        >
          <Icon name="ph:plus" class="h-4 w-4 mr-2" />
          {{ $t('Add field') }}
          ({{ selectedFields.length }}/10)
        </BaseButton>

        <!-- Export Template Section -->
        <div
          class="p-4 bg-success-50 dark:bg-success-900/20 border border-success-200 dark:border-success-800 rounded-lg space-y-3"
        >
          <div class="flex items-center gap-2">
            <Icon name="ph:file-arrow-down" class="h-5 w-5 text-success-600" />
            <p class="font-medium text-success-700 dark:text-success-400">
              {{ $t('Export template') }}
            </p>
          </div>
          <p class="text-sm text-muted-600 dark:text-muted-400">
            {{
              $t(
                'Create a template file based on configured field structure, then import tracking data',
              )
            }}
          </p>
          <div class="flex gap-2">
            <BaseButton
              size="sm"
              color="success"
              @click="exportTemplateExcel"
              :disabled="selectedFields.filter((f) => f.is_active).length === 0"
            >
              <Icon name="ph:file-xls" class="h-4 w-4 mr-2" />
              {{ $t('Excel Template') }}
            </BaseButton>
            <BaseButton
              size="sm"
              color="info"
              @click="exportTemplateJSON"
              :disabled="selectedFields.filter((f) => f.is_active).length === 0"
            >
              <Icon name="ph:file-js" class="h-4 w-4 mr-2" />
              {{ $t('JSON Template') }}
            </BaseButton>
          </div>
        </div>

        <!-- Info -->
        <div
          class="p-3 bg-info-50 dark:bg-info-900/20 border border-info-200 dark:border-info-800 rounded-lg text-sm"
        >
          <Icon name="ph:info" class="h-4 w-4 inline mr-2" />
          {{ $t('These fields will be used in Excel and JSON exports') }}
        </div>
      </div>

      <template #footer>
        <div class="flex items-center justify-between w-full">
          <BaseButton color="default" @click="closeModal">
            {{ $t('Cancel') }}
          </BaseButton>
          <BaseButton
            color="primary"
            :loading="loading"
            @click="saveFieldConfig"
          >
            {{ $t('Save') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>
  </div>
</template>

<style scoped>
.tracking-fields-config {
  display: inline-block;
}
</style>
