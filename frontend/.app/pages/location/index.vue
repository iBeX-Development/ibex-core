<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'

import { computed, onMounted, ref } from 'vue'
import SubsidebarLocationMenus from '~/components/global/SubsidebarLocationMenus'

const toaster = useToaster()

// const CACHE_KEY = 'sidebar_locations_cache_v2'
const CACHE_KEY = 'sidebar_locations_cache_v3'
const CACHE_TTL = 24 * 60 * 60 * 1000 // 24 hours
const myCompanyId = getMyCompanyId()

definePageMeta({
  middleware: ['auth'],
  title: 'Location',
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
const { t } = useI18n({ useScope: 'global' })

const itemsPerPage = ref(25)
const getTableHeaders = () => {
  return [
    { title: t('Name'), key: 'name', align: 'start', width: '30%' },
    { title: t('Code'), key: 'location_code', align: 'start', width: '30%' },
    { title: t('Position'), key: 'position', align: 'start', width: '30%' },
    { title: t('Region'), key: 'region.name', align: 'start', width: '30%' },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const navigation = ref<any[]>([])

const loadItems = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array = ['position']
  sortBy.map((sort_object) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })
  loading.value = true
  try {
    const filters = {
      status: '1',
      company_id: myCompanyId,
    }
    const items = await getItems<any>({
      collection: 'Location',
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
// Modal new & edit form
import DeletionModalForm from '~/components/form/DeletionModalForm.vue'
import DynamicModalForm from '~/components/form/DynamicModalForm.vue'
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const selectedObj = ref(null)
const key = ref(1)

const loadLocation = async () => {
  // 1. Show cached data immediately if available
  const cached = localStorage.getItem(CACHE_KEY)
  try {
    const filters: any = {
      status: '1',
      company_id: myCompanyId,
    }
    const locations = window.localStorage.getItem('locations')

    if (locations && locations !== '0') {
      filters.id = { _in: locations }
    }

    const items = await getItems<any>({
      collection: 'Location',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*', 'region.*'],
      },
    })
    const transformed = transformNavigation(items.data)
    navigation.value = transformed
    console.log('loadLocation - navigation', navigation.value)
    // Save to cache
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify({ data: transformed, ts: Date.now() }),
    )
  } catch (e) {
    console.log(e)
  }
}

const transformNavigation = (items: any[]) => {
  let show_locations: any[] = []
  const permissionsStr = window.localStorage.getItem('app_permissions') || '{}'
  const permissions = permissionsStr ? JSON.parse(permissionsStr) : null

  if (permissions && permissions[1] && permissions[1].includes('admin')) {
    show_locations = items
  } else if (permissions && Object.keys(permissions).length) {
    // items-д байгаа байрлалуудыг гүйлгэж үзнэ
    show_locations = items.filter((location: any) => permissions[location.id])
  } else {
    // Хэрэв ямар нэгэн permission байхгүй бол бүх items-г харуулна
    show_locations = items
  }

  const transformed_locations: any[] = show_locations.map((item: any) => {
    return {
      name: item.name,
      id: item.id,
      collection: 'Location',
      icon: 'ph:buildings-duotone',
      children: SubsidebarLocationMenus(item.id),
    }
  })
  if (transformed_locations.length == 0) {
    transformed_locations.unshift({
      name: 'No location',
      icon: 'ph:buildings-duotone',
      to: '/asset/by/',
    })
  }
  return transformed_locations
}

const handleModalOpen = () => {
  selectedItem.value = -1
  selectedObj.value = null
  isModalOpen.value = true
  console.log(isModalOpen.value)
  loadLocation()
}

const handleModalClose = () => {
  isModalOpen.value = false
  selectedObj.value = null
  console.log(isModalOpen.value)
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const do_make = async (item, type) => {
  let statuss = 1

  if (type == 'delete') {
    statuss = 0

    const updateData = {
      collection: 'Location',
      id: item.id,
      item: {
        status: '0',
      },
    }
    await updateItem(updateData)
    toaster.show({
      title: t('Success'),
      message: t(`Successfully deleted`),
      color: 'success',
      icon: 'ph:check',
      closable: true,
    })

    loadItems({
      page: 1,
      itemsPerPage: itemsPerPage.value,
      sortBy: [],
    })
  }
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
  selectedObj.value = null
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton @click="handleModalOpen">
          <Icon name="material-symbols:location-on" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Location add') }}</span>
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
                        selectedObj = item
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
          v-if="isModalOpen"
          :key="selectedItem"
          title="Location"
          code="Location"
          :open="isModalOpen"
          :close="handleModalClose"
          :row="selectedItem"
          :refresh="handleChangeKey"
          size="sm"
          icon="material-symbols:add-location-alt-rounded"
        />
        <DeletionModalForm
          :key="selectedItem"
          code="Location"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :row="selectedItem"
          :refresh="handleChangeKey"
          :clear="clearItem"
          :do_make="do_make"
          :itemsValue="selectedObj"
          actionType="delete"
        />
      </div>
    </div>
  </div>
</template>
