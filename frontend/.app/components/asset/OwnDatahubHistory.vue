<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })

interface Props {
  assetId?: string | number | null
  dataType?: 'tracking' | 'device_settings' | 'all'
}

const props = withDefaults(defineProps<Props>(), {
  dataType: 'all',
})

const { getItems, deleteItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const loading = ref(false)
const historyRecords = ref<any[]>([])
const selectedRecord = ref<any>(null)
const showDetailModal = ref(false)

// Pagination
const currentPage = ref(1)
const itemsPerPage = ref(10)

// Filters
const filterType = ref(props.dataType)
const startDate = ref('')
const endDate = ref('')

const totalPages = computed(() => {
  return Math.ceil(historyRecords.value.length / itemsPerPage.value)
})

const paginatedRecords = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage.value
  const end = start + itemsPerPage.value
  return historyRecords.value.slice(start, end)
})

const loadHistory = async () => {
  if (!props.assetId) return

  loading.value = true
  try {
    let filter: any = {
      asset: { _eq: props.assetId },
      company_id: { _eq: myCompanyId },
    }

    // Apply data type filter
    if (filterType.value !== 'all') {
      filter.data_type = { _eq: filterType.value }
    }

    // Apply date range filter
    if (startDate.value && endDate.value) {
      filter.timestamp = {
        _between: [
          new Date(startDate.value).toISOString(),
          new Date(endDate.value).toISOString(),
        ],
      }
    }

    const response = await getItems<any>({
      collection: 'Datahub_history',
      params: {
        filter,
        sort: ['-timestamp'],
        limit: -1,
        fields: ['*'],
      },
    })

    historyRecords.value = Array.isArray(response)
      ? response
      : (response as any)?.data || []

    currentPage.value = 1
  } catch (error) {
    console.error('Error loading history:', error)
  } finally {
    loading.value = false
  }
}

const viewDetails = (record: any) => {
  selectedRecord.value = record
  showDetailModal.value = true
}

const closeDetailModal = () => {
  showDetailModal.value = false
  selectedRecord.value = null
}

const formatDate = (date: string) => {
  return new Date(date).toLocaleString('mn-MN')
}

const formatDataType = (type: string) => {
  switch (type) {
    case 'tracking':
      return t('Tracking Data')
    case 'device_settings':
      return t('Device Settings')
    default:
      return type
  }
}

const parseSnapshot = (snapshot: any) => {
  if (typeof snapshot === 'string') {
    try {
      return JSON.parse(snapshot)
    } catch {
      return snapshot
    }
  }
  return snapshot
}

const deleteRecord = async (id: number) => {
  if (!confirm(t('Delete this history record?'))) {
    return
  }

  try {
    loading.value = true
    await deleteItem({
      collection: 'Datahub_history',
      id,
    })
    await loadHistory()
  } catch (error) {
    console.error('Error deleting record:', error)
    alert(t('Error deleting'))
  } finally {
    loading.value = false
  }
}

const goToPage = (page: number) => {
  if (page >= 1 && page <= totalPages.value) {
    currentPage.value = page
  }
}

onMounted(() => {
  if (props.assetId) {
    loadHistory()
  }
})
</script>

<template>
  <div class="datahub-history">
    <BaseCard class="p-6">
      <div class="space-y-6">
        <!-- Header -->
        <div class="flex items-center justify-between">
          <div>
            <BaseHeading as="h3" size="md" weight="medium" class="mb-2">
              {{ $t('Data History') }}
            </BaseHeading>
            <BaseParagraph size="sm" class="text-muted-400">
              {{
                $t('View historical snapshots of tracking data and settings')
              }}
            </BaseParagraph>
          </div>

          <BaseButton color="primary" :loading="loading" @click="loadHistory">
            <Icon name="ph:arrows-clockwise" class="h-4 w-4 mr-2" />
            {{ $t('Refresh') }}
          </BaseButton>
        </div>

        <!-- Filters -->
        <div class="flex items-center gap-4 flex-wrap">
          <!-- Data Type Filter -->
          <div class="flex items-center gap-2">
            <label class="text-sm text-muted-600 dark:text-muted-400">
              {{ $t('Type') }}:
            </label>
            <select
              v-model="filterType"
              @change="loadHistory"
              class="border border-muted-300 dark:border-muted-700 dark:bg-muted-800 rounded px-3 py-1.5 text-sm"
            >
              <option value="all">{{ $t('All') }}</option>
              <option value="tracking">{{ $t('Tracking Data') }}</option>
              <option value="device_settings">
                {{ $t('Device Settings') }}
              </option>
            </select>
          </div>

          <!-- Date Range Filter -->
          <div class="flex items-center gap-2">
            <label class="text-sm text-muted-600 dark:text-muted-400">
              {{ $t('From') }}:
            </label>
            <input
              v-model="startDate"
              type="date"
              class="border border-muted-300 dark:border-muted-700 dark:bg-muted-800 rounded px-3 py-1.5 text-sm"
            />
            <span class="text-muted-400">-</span>
            <label class="text-sm text-muted-600 dark:text-muted-400">
              {{ $t('To') }}:
            </label>
            <input
              v-model="endDate"
              type="date"
              class="border border-muted-300 dark:border-muted-700 dark:bg-muted-800 rounded px-3 py-1.5 text-sm"
            />
            <BaseButton size="sm" color="primary" @click="loadHistory">
              <Icon name="ph:funnel" class="h-4 w-4" />
              {{ $t('Filter') }}
            </BaseButton>
          </div>
        </div>

        <!-- Loading State -->
        <div v-if="loading" class="text-center py-8">
          <Icon
            name="svg-spinners:blocks-shuffle-3"
            class="h-8 w-8 mx-auto text-primary-500"
          />
        </div>

        <!-- History Table -->
        <div v-else-if="historyRecords.length > 0" class="space-y-4">
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
                    {{ $t('Timestamp') }}
                  </th>
                  <th
                    class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                  >
                    {{ $t('Type') }}
                  </th>
                  <th
                    class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                  >
                    {{ $t('Records') }}
                  </th>
                  <th
                    class="text-left py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                  >
                    {{ $t('Date Range') }}
                  </th>
                  <th
                    class="text-right py-3 px-4 text-sm font-semibold text-muted-800 dark:text-muted-100"
                  >
                    {{ $t('Actions') }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="(record, index) in paginatedRecords"
                  :key="record.id"
                  class="border-b border-muted-200 dark:border-muted-700 hover:bg-muted-50 dark:hover:bg-muted-800/50 transition-colors"
                >
                  <td
                    class="py-3 px-4 text-sm text-muted-600 dark:text-muted-400"
                  >
                    {{ (currentPage - 1) * itemsPerPage + index + 1 }}
                  </td>
                  <td class="py-3 px-4">
                    <BaseText size="sm">
                      {{ formatDate(record.timestamp) }}
                    </BaseText>
                  </td>
                  <td class="py-3 px-4">
                    <BaseBadge
                      :color="
                        record.data_type === 'tracking' ? 'primary' : 'success'
                      "
                      size="sm"
                    >
                      {{ formatDataType(record.data_type) }}
                    </BaseBadge>
                  </td>
                  <td class="py-3 px-4">
                    <BaseText size="sm" weight="medium">
                      {{ record.record_count || 0 }}
                    </BaseText>
                  </td>
                  <td class="py-3 px-4">
                    <div
                      v-if="record.date_range_start && record.date_range_end"
                      class="text-xs text-muted-500"
                    >
                      <div>{{ formatDate(record.date_range_start) }}</div>
                      <div>{{ formatDate(record.date_range_end) }}</div>
                    </div>
                    <span v-else class="text-muted-400">-</span>
                  </td>
                  <td class="py-3 px-4 text-right">
                    <div class="flex items-center justify-end gap-2">
                      <BaseButton
                        size="sm"
                        color="default"
                        @click="viewDetails(record)"
                      >
                        <Icon name="ph:eye" class="h-4 w-4" />
                      </BaseButton>
                      <BaseButton
                        size="sm"
                        color="danger"
                        @click="deleteRecord(record.id)"
                      >
                        <Icon name="ph:trash" class="h-4 w-4" />
                      </BaseButton>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Pagination -->
          <div
            v-if="totalPages > 1"
            class="flex items-center justify-between pt-4 border-t border-muted-200 dark:border-muted-700"
          >
            <BaseText size="sm" class="text-muted-500">
              {{ historyRecords.length }} {{ $t('total records') }}
            </BaseText>

            <div class="flex items-center gap-2">
              <BaseButton
                size="sm"
                color="default"
                :disabled="currentPage === 1"
                @click="goToPage(currentPage - 1)"
              >
                <Icon name="ph:caret-left" class="h-4 w-4" />
              </BaseButton>

              <span class="text-sm text-muted-600 dark:text-muted-400">
                {{ currentPage }} / {{ totalPages }}
              </span>

              <BaseButton
                size="sm"
                color="default"
                :disabled="currentPage === totalPages"
                @click="goToPage(currentPage + 1)"
              >
                <Icon name="ph:caret-right" class="h-4 w-4" />
              </BaseButton>
            </div>
          </div>
        </div>

        <!-- Empty State -->
        <div
          v-else
          class="text-center py-12 border-2 border-dashed border-muted-200 dark:border-muted-700 rounded-lg"
        >
          <Icon
            name="ph:clock-counter-clockwise"
            class="h-12 w-12 mx-auto text-muted-400 mb-4"
          />
          <BaseHeading as="h4" size="sm" weight="medium" class="mb-2">
            {{ $t('No history records found') }}
          </BaseHeading>
          <BaseParagraph size="sm" class="text-muted-400">
            {{ $t('Export data or save settings to create history snapshots') }}
          </BaseParagraph>
        </div>
      </div>
    </BaseCard>

    <!-- Detail Modal -->
    <TairoModal :open="showDetailModal" size="xl" @close="closeDetailModal">
      <template #header>
        <div class="flex items-center gap-3">
          <Icon name="ph:file-text" class="h-5 w-5" />
          <div>
            <BaseHeading as="h3" size="sm" weight="medium">
              {{ $t('History Record Details') }}
            </BaseHeading>
          </div>
        </div>
      </template>

      <div v-if="selectedRecord" class="space-y-4">
        <!-- Metadata -->
        <div class="grid grid-cols-2 gap-4">
          <div>
            <BaseText size="xs" class="text-muted-400">
              {{ $t('Timestamp') }}
            </BaseText>
            <BaseText size="sm" weight="medium">
              {{ formatDate(selectedRecord.timestamp) }}
            </BaseText>
          </div>
          <div>
            <BaseText size="xs" class="text-muted-400">
              {{ $t('Type') }}
            </BaseText>
            <BaseText size="sm" weight="medium">
              {{ formatDataType(selectedRecord.data_type) }}
            </BaseText>
          </div>
          <div>
            <BaseText size="xs" class="text-muted-400">
              {{ $t('Record Count') }}
            </BaseText>
            <BaseText size="sm" weight="medium">
              {{ selectedRecord.record_count || 0 }}
            </BaseText>
          </div>
          <div v-if="selectedRecord.date_range_start">
            <BaseText size="xs" class="text-muted-400">
              {{ $t('Date Range') }}
            </BaseText>
            <BaseText size="sm" weight="medium">
              {{ formatDate(selectedRecord.date_range_start) }}
              <br />
              {{ formatDate(selectedRecord.date_range_end) }}
            </BaseText>
          </div>
        </div>

        <!-- Notes -->
        <div v-if="selectedRecord.notes">
          <BaseText size="xs" class="text-muted-400">
            {{ $t('Notes') }}
          </BaseText>
          <BaseText size="sm">
            {{ selectedRecord.notes }}
          </BaseText>
        </div>

        <!-- Data Snapshot -->
        <div>
          <BaseText size="xs" class="text-muted-400 mb-2">
            {{ $t('Data Snapshot') }}
          </BaseText>
          <pre
            class="bg-muted-100 dark:bg-muted-800 p-4 rounded text-xs overflow-x-auto max-h-96"
            >{{
              JSON.stringify(
                parseSnapshot(selectedRecord.data_snapshot),
                null,
                2,
              )
            }}</pre
          >
        </div>
      </div>

      <template #footer>
        <BaseButton color="default" @click="closeDetailModal">
          {{ $t('Close') }}
        </BaseButton>
      </template>
    </TairoModal>
  </div>
</template>

<style scoped>
.datahub-history {
  width: 100%;
}
</style>
