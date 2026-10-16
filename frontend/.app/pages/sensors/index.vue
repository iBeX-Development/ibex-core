<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Sensors type',
  showback: true,
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})

const { getItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const itemsPerPage = ref(25)
const getTableHeaders = () => {
  return [
    {
      title: t('Device Name'),
      key: 'device_name',
      align: 'start',
    },
    {
      title: t('Active'),
      key: 'status',
      align: 'start',
    },
    {
      title: t('Device Type'),
      key: 'device_type',
      align: 'start',
    },
    {
      title: t('Device ID'),
      key: 'device_id',
      align: 'start',
    },
    {
      title: t('Description'),
      key: 'description',
      align: 'start',
    },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const refreshKey = ref(0)

const loadItems = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array = []
  sortBy.map((sort_object) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })
  loading.value = true
  try {
    const filters = {
      // status: 'published',
      company_id: myCompanyId,
    }
    const items = await getItems<any>({
      collection: 'Sensors',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: ['*'],
      },
    })
    serverItems.value = items.data
    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {}
}
// Modal new & edit form
import DeletionModalForm from '~/components/form/DeletionModalForm.vue'
import DynamicModalForm from '~/components/form/DynamicModalForm.vue'
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const key = ref(1)

const toaster = useToaster()

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
  console.log(isModalOpen.value)
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log(isModalOpen.value)
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const do_edit = (item) => {
  // Perform your action here
  selectedItem.value = item.id
  console.log(selectedItem.value)
  isModalOpen.value = true
  handleChangeKey()
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const clearItem = () => {
  selectedItem.value = -1
}

// Sensor-т тохируулсан (Sensors.asset FK-аар холбогдсон) asset-ийг харуулах
const isAssetsModalOpen = ref(false)
const assetsForSensor = ref([])
const assetsModalLoading = ref(false)
const selectedSensorForAssets = ref(null)

const showAssets = async (sensor) => {
  selectedSensorForAssets.value = sensor
  isAssetsModalOpen.value = true
  assetsForSensor.value = []

  if (!sensor.asset) return

  assetsModalLoading.value = true
  try {
    const response = await getItems({
      collection: 'Assets',
      params: {
        filter: { id: { _eq: sensor.asset } },
        fields: ['id', 'asset_code', 'name', 'status'],
      },
    })
    assetsForSensor.value = Array.isArray(response)
      ? response
      : response?.data || []
  } catch (err) {
    console.warn('⚠️ Could not load assigned asset:', err)
  } finally {
    assetsModalLoading.value = false
  }
}

const closeAssetsModal = () => {
  isAssetsModalOpen.value = false
}

const do_delete = async (item, type) => {
  isModalConfirmOpen.value = true

  // Handle case where item might be undefined - use selectedItem.value instead
  const itemId = item?.id || selectedItem.value
  if (!itemId) {
    console.error('No item ID available for deletion')
    return
  }

  selectedItem.value = itemId
  console.log('do_delete', itemId)
  const data = {
    collection: 'Sensors',
    id: itemId,
    item: {
      status: 'draft',
    },
  }
  await updateItem(data)
  handleChangeKey()
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton @click="handleModalOpen">
          <Icon
            name="fluent:device-meeting-room-microphone-below-16-regular"
            class="-ms-1 h-4 w-4"
          />
          <span class="text-[11px]">{{ $t('Add IoT device ') }}</span>
        </BaseButton>
      </div>
      <!-- Grid -->
      <div class="col-span-12">
        <BaseInput
          v-model="search"
          icon="lucide:search"
          :placeholder="$t('Search')"
          :classes="{
            wrapper: 'w-full sm:w-auto Searching',
          }"
        />
        <v-data-table-server
          v-model:items-per-page="itemsPerPage"
          :key="key"
          :headers="getTableHeaders()"
          :items-length="totalItems"
          :items="serverItems"
          :loading="loading"
          :search="search"
          class="elevation-1 -z-50"
          item-value="device_name"
          :theme="$colorMode.value"
          @update:options="loadItems"
          :pageText="t('{0}-{1} of {2}', ['{0}', '{1}', '{2}'])"
          :items-per-page-options="[
            { value: 5, title: '5' },
            { value: 10, title: '10' },
            { value: 25, title: '25' },
            { value: 50, title: '50' },
            { value: 100, title: '100' },
            { value: -1, title: t('All') },
          ]"
          :items-per-page-text="t('Item per page')"
          :loading-text="t('loading')"
          :no-data-text="t('No records')"
        >
          <template v-slot:item.status="{ item }">
            <span
              class="rounded-full px-2 py-0.5 text-xs font-medium"
              :class="
                item.status === 'published'
                  ? 'bg-success-100 text-success-700 dark:bg-success-500/20 dark:text-success-400'
                  : 'bg-muted-200 text-muted-600 dark:bg-muted-700 dark:text-muted-300'
              "
            >
              {{ item.status === 'published' ? t('Published') : t('Draft') }}
            </span>
          </template>
          <template v-slot:item.action="{ item }">
            <div class="">
              <BaseDropdown
                flavor="context"
                label="Dropdown"
                orientation="end"
                condensed
                shape="curved"
                class="absolute mt-[-18px]"
              >
                <div class="">
                  <BaseDropdownItem
                    :title="t('Edit')"
                    :text="t('Edit record')"
                    @click="do_edit(item)"
                  >
                    <template #start>
                      <Icon
                        name="ph:pencil-line-fill"
                        class="me-2 block h-5 w-5"
                      />
                    </template>
                  </BaseDropdownItem>
                  <BaseDropdownDivider />
                  <BaseDropdownItem
                    :title="t('Assets')"
                    :text="t('Show in Assets')"
                    @click="showAssets(item)"
                  >
                    <template #start>
                      <Icon
                        name="fluent:device-meeting-room-microphone-below-16-regular"
                        class="me-2 block h-5 w-5"
                      />
                    </template>
                  </BaseDropdownItem>
                  <BaseDropdownDivider />
                  <BaseDropdownItem
                    :title="t('Remove')"
                    :text="t('Remove from list')"
                    @click="
                      () => {
                        isModalConfirmOpen = true
                        selectedItem = item.id
                      }
                    "
                  >
                    <template #start>
                      <Icon
                        name="ph:trash-duotone"
                        class="me-2 block h-5 w-5"
                      />
                    </template>
                  </BaseDropdownItem>
                </div>
              </BaseDropdown>
            </div>
          </template>
        </v-data-table-server>
        <DynamicModalForm
          :key="selectedItem"
          title="Sensors"
          code="Sensors"
          :open="isModalOpen"
          :close="handleModalClose"
          :row="selectedItem"
          :refresh="handleChangeKey"
          icon="fluent:device-meeting-room-microphone-below-16-regular"
          size="xl"
          schema_column="two-column-form"
          :fields="[
            {
              name: 'device_id',
              label: t('Device ID'),
              type: 'text',
              required: true,
            },
            {
              name: 'device_name',
              label: t('Device Name'),
              type: 'text',
              required: true,
            },
            {
              name: 'status',
              label: t('Device status'),
              type: 'select',
              required: true,
              options: [
                { value: 'published', label: t('Published') },
                { value: 'draft', label: t('Draft') },
              ],
              value: 'published',
            },
            {
              name: 'device_type',
              label: t('Device Type'),
              type: 'text',
              required: true,
            },
            {
              name: 'device_model',
              label: t('Device Model'),
              type: 'text',
              required: true,
            },
            {
              name: 'device_imei',
              label: t('Device imei'),
              type: 'text',
              required: false,
            },
            {
              name: 'description',
              label: t('Description'),
              type: 'text',
              required: false,
              class: 'col-span-2 !max-w-full',
            },
          ]"
        />
        <DeletionModalForm
          :key="selectedItem"
          code="Sensors"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :row="selectedItem"
          :refresh="handleChangeKey"
          :clear="clearItem"
          :do_make="do_delete"
        />
        <TairoModal
          :open="isAssetsModalOpen"
          size="sm"
          @close="closeAssetsModal"
        >
          <template #header>
            <div class="flex items-center gap-3">
              <Icon name="ph:cube-duotone" class="h-5 w-5" />
              <BaseHeading as="h3" size="sm" weight="medium">
                {{ t('Assigned assets') }}
                <span v-if="selectedSensorForAssets" class="text-muted-400">
                  — {{ selectedSensorForAssets.device_name }}
                </span>
              </BaseHeading>
            </div>
          </template>

          <div v-if="assetsModalLoading" class="text-center py-8">
            <Icon
              name="svg-spinners:blocks-shuffle-3"
              class="h-8 w-8 mx-auto text-primary-500"
            />
          </div>
          <div
            v-else-if="assetsForSensor.length === 0"
            class="text-center py-8 text-muted-400"
          >
            {{ t('No assets connected') }}
          </div>
          <div v-else class="space-y-2">
            <div
              v-for="asset in assetsForSensor"
              :key="asset.id"
              class="border-muted-200 dark:border-muted-700 flex items-center justify-between rounded-lg border p-3"
            >
              <div>
                <p class="text-muted-800 dark:text-muted-100 font-medium">
                  {{ asset.asset_code }}
                </p>
                <p class="text-muted-500 text-sm">{{ asset.name }}</p>
              </div>
              <span
                class="rounded-full px-2 py-0.5 text-xs font-medium"
                :class="
                  asset.status === '1'
                    ? 'bg-success-100 text-success-700 dark:bg-success-500/20 dark:text-success-400'
                    : 'bg-muted-200 text-muted-600 dark:bg-muted-700 dark:text-muted-300'
                "
              >
                {{ asset.status === '1' ? t('Enabled') : t('Disabled') }}
              </span>
            </div>
          </div>

          <template #footer>
            <BaseButton color="default" @click="closeAssetsModal">
              {{ t('Close') }}
            </BaseButton>
          </template>
        </TairoModal>
      </div>
    </div>
  </div>
</template>
