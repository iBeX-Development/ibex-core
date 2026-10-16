<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Work types',
  showback: true,
  preview: {
    title: 'WorkOrder- work_type',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})

const { getItems } = useDirectusItems()

const itemsPerPage = ref(25)
const getTableHeaders = () => {
  return [
    { title: t('Code'), key: 'code', align: 'start', width: '40%' },
    { title: t('Name'), key: 'name', align: 'start', width: '40%' },
    {
      title: t('Description'),
      key: 'description',
      align: 'start',
      width: '40%',
    },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)

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
      status: 'published',
    }
    const items = await getItems<any>({
      collection: 'Work_types',
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
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const clearItem = () => {
  selectedItem.value = -1
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton @click="handleModalOpen">
          <Icon name="mingcute:department-line" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Type add') }}</span>
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
                orientation="start"
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
          title="Work_types"
          code="Work_types"
          :open="isModalOpen"
          :close="handleModalClose"
          :row="selectedItem"
          :refresh="handleChangeKey"
          size="sm"
        />
        <DeletionModalForm
          :key="selectedItem"
          code="Work_types"
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
