<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Schedule',
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

const { getItems } = useDirectusItems()

const itemsPerPage = ref(10)
const getTableHeaders = () => {
  return [
    { title: t('Name'), key: 'name', align: 'start', width: '20%' },
    {
      title: t('Created'),
      key: 'date_created',
      align: 'start',
      width: '20%',
    },
    {
      title: t('Type'),
      key: 'repeat_types',
      align: 'start',
      width: '20%',
    },
    {
      title: t('Unit'),
      key: 'repeat_unit',
      align: 'start',
      width: '20%',
    },
    { title: t('Cycle'), key: 'repeat', align: 'start', width: '10%' },
    {
      title: t('Action'),
      key: 'action',
      align: 'start',
      width: '10%',
      sortable: false,
    },
  ]
}

const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)

// Modal new & edit form
import DeletionActiveModalForm from '~/components/form/DeletionActiveModalForm.vue'
import DynamicModalForm from '~/components/form/DynamicModalForm.vue'
import ScheduleModalForm from './ScheduleModalForm.vue'

const isModalOpen = ref(false)
const isModalNewOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const editRow = ref(-1)
const key = ref(1)

const toaster = useToaster()

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
  console.log(isModalOpen.value)
}

const handleModalNewOpen = () => {
  selectedItem.value = -1
  isModalNewOpen.value = true
  console.log(isModalOpen.value)
}

const handleModalClose = () => {
  isModalOpen.value = false
  isModalNewOpen.value = false
  editRow.value = -1
  selectedItem.value = -1
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const do_edit = (item) => {
  // Perform your action here
  selectedItem.value = item.id
  editRow.value = item
  isModalNewOpen.value = true
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const clearItem = () => {
  selectedItem.value = -1
  editRow.value = -1
}

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
      active: '1',
    }
    const items = await getItems<any>({
      collection: 'Schedule',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: ['*', 'region.*'],
      },
    })
    serverItems.value = items.data
    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {}
}

const formattedServerItems = serverItems.value.map((item) => ({
  ...item,
  date_created: new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  }).format(new Date(item.date_created)), // Convert and format the datetime
}))
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <!-- <BaseButton class="float-right" @click="handleModalOpen">
          <Icon name="material-symbols:location-on" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Schedule add') }}</span>
        </BaseButton> -->
        <BaseButton @click="handleModalNewOpen">
          <Icon
            name="material-symbols:schedule-outline"
            class="-ms-1 h-4 w-4"
          />
          <span class="text-[11px]">{{ $t('Schedule new') }}</span>
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
          class="elevation-1 -z-50 schedules"
          item-value="name"
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
          title="Schedule"
          code="Schedule"
          :open="isModalOpen"
          :close="handleModalClose"
          :row="selectedItem"
          :refresh="handleChangeKey"
          icon="material-symbols:schedule-outline"
          size="md"
        />
        <ScheduleModalForm
          :key="selectedItem"
          :row="selectedItem"
          :open="isModalNewOpen"
          :editRow="editRow"
          :close="handleModalClose"
          title="Schedule"
          code="Schedule"
          :refresh="handleChangeKey"
          size="md"
          :clear="clearItem"
          icon="material-symbols:schedule-outline"
        />
        <DeletionActiveModalForm
          :key="selectedItem"
          code="Schedule"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :row="selectedItem"
          :refresh="handleChangeKey"
          :clear="clearItem"
        />
      </div>
    </div>
  </div>
</template>

<style>
.schedules .v-data-table-header__content {
  white-space: nowrap;
}
.schedules .v-data-table__td {
  white-space: nowrap;
}
</style>
