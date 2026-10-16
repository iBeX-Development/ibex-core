<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'

import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import AddModalForm from './AddModalForm.vue'
const itemsValue = ref(-1)
const actionType = ref(null)
const { getItems, updateItem, updateItems, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const runtimeConfig = useRuntimeConfig()
const { token } = useDirectusToken()
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Login page',
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

import { ref } from 'vue'
const itemsPerPage = ref(10)
const getTableHeaders = () => {
  return [
    {
      title: t('Number'),
      key: 'id',
      align: 'start',
      width: '10%',
    },
    {
      title: t('Name'),
      key: '_name',
      align: 'start',
      width: '30%',
    },
    {
      title: t('Status'),
      key: 'status',
      align: 'start',
      width: '30%',
    },
    // { title: t('Created'), key: 'date_created', align: 'start', width: '30%' },
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
      active: 1,
      company_id: myCompanyId,
    }

    const items = await getItems({
      collection: 'Login_set',
      params: {
        filter: filters,
        meta: 'filter_count',
        search: search.value,
        fields: ['*'],
      },
    })

    serverItems.value = items.data
    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {
    loading.value = false
  }
}
// Modal new & edit form
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const rowItem = ref(-1)
const key = ref(1)
const key_update_modal = ref(-2)

const toaster = useToaster()

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
}

const handleModalClose = () => {
  isModalOpen.value = false
  selectedItem.value = -1
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const do_edit = (item) => {
  // Perform your action here
  selectedItem.value = item

  isModalOpen.value = true
}

const do_disable = async (item) => {
  selectedItem.value = item
  const res = await updateItem({
    collection: 'Login_set',
    id: item.id,
    item: {
      status: 'Draft',
    },
  })

  toaster.show({
    title: 'Success to disabled',
    color: 'success',
    icon: 'ph:check',
    closable: true,
  })

  // console.log(selectedItem.value, 'do_active', res)
  handleChangeKey()
}

const do_active = async (item) => {
  // Perform your action here
  selectedItem.value = item
  // const response = await fetch(
  //   runtimeConfig.public.directus.url + 'items/Login_set',
  //   {
  //     method: 'PATCH', // Use PATCH method for updates
  //     headers: {
  //       'Content-Type': 'application/json',
  //       Authorization: `Bearer ${token.value}`,
  //     },
  //     body: JSON.stringify({
  //       filter: {
  //         id: { _neq: item.id }, // item.id-с бусад бүх бичлэгийг сонгох
  //       },
  //       status: 'Draft',
  //     }),
  //   },
  // )
  // console.log('response ->>', response)

  const res = await updateItem({
    collection: 'Login_set',
    id: item.id,
    item: {
      status: 'Publish',
      active: 1,
    },
  })

  toaster.show({
    title: 'Success to actived',
    color: 'success',
    icon: 'ph:check',
    closable: true,
  })

  console.log(selectedItem.value, 'do_active', res)
  handleChangeKey()
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleChangeModalKey = () => {
  selectedItem.value = -1
}

const clearItem = () => {
  selectedItem.value = -1
}

const clickedDelete = (item) => {
  isModalConfirmOpen.value = true
  selectedItem.value = item.id
  actionType.value = 'do_delete'
  itemsValue.value = item
}

const do_make = async (item, type) => {
  let active = 1
  if (type == 'do_delete') {
    active = 0

    const data = {
      collection: 'Login_set',
      id: item.id,
      item: { active: active },
    }
    await updateItem(data)
    handleChangeKey()
  }
}

const getRowClass = (item) => {
  return item.status === 'active' ? 'hi' : 'bye'
}

const getCellClass = (key, value) => {
  if (key === 'status') {
    return value === 'active' ? 'text-green-500' : 'text-red-500'
  }
  if (key === 'name') {
    return 'font-bold text-blue-600'
  }
  if (key === 'code_color') {
    return {
      backgroundColor: value.bg_color, // bg_color
      color: value.text_color, // text_color
    }
  }
  return ''
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="" @click="handleModalOpen">
          <Icon name="ph:squares-four-duotone" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Items add') }}</span>
        </BaseButton>
      </div>
      <!-- Grid -->
      <div class="col-span-12">
        <BaseInput
          v-model="search"
          icon="lucide:search"
          :placeholder="$t('Search')"
          :classes="{
            wrapper: 'w-full sm:w-auto  Searching',
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
          class="elevation-1 -z-50 module_status"
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
                    v-if="item.status == 'Draft'"
                    :title="t('Active')"
                    :text="t('Set login')"
                    @click="do_active(item)"
                  >
                    <template #start>
                      <Icon
                        name="ic:twotone-done-outline"
                        class="me-2 block h-5 w-5"
                      />
                    </template>
                  </BaseDropdownItem>
                  <BaseDropdownDivider v-if="item.status == 'Draft'" />

                  <BaseDropdownItem
                    v-if="item.status == 'Publish'"
                    :title="t('Draft')"
                    :text="t('Draft to item')"
                    @click="do_disable(item)"
                  >
                    <template #start>
                      <Icon
                        name="material-symbols-light:design-services-outline"
                        class="me-2 block h-5 w-5"
                      />
                    </template>
                  </BaseDropdownItem>
                  <BaseDropdownDivider v-if="item.status == 'Publish'" />
                  <BaseDropdownItem
                    :title="t('Remove')"
                    :text="t('Remove from list')"
                    @click="clickedDelete"
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
        <AddModalForm
          :key="selectedItem"
          title="Status"
          code="Status"
          :open="isModalOpen"
          :close="handleModalClose"
          :editRow="selectedItem"
          :refresh="handleChangeKey"
          :refresh_modal="handleChangeModalKey"
        />
        <ConfirmModalForm
          code="Login_set"
          :key="selectedItem"
          :itemsValue="itemsValue"
          text="Do you really want to delete this record. This process cannot be undone?"
          :successfullText="false"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :do_make="do_make"
          :actionType="actionType"
          :row="selectedItem"
          :refresh="handleChangeKey"
          :clear="clearItem"
        />
      </div>
    </div>
  </div>
</template>

<style>
/* Or style all headers */
.module_status {
  margin-top: 1px;
}
.module_status .v-table {
  border-radius: 7px;
}

.module_status .v-data-table__th {
  height: 40px !important;
}

.module_status .v-data-table thead th {
  white-space: nowrap;
}

.module_status .v-data-table .v-data-table__td .wo_name {
  cursor: pointer;
  margin-right: 5px;
}

.module_status .statusCell {
  padding: 4px;
  width: 125px;
  border-radius: 100px;
  line-height: 1.5;
  font-size: 11px;
  border: 2px solid rgba(91, 91, 91, 0.1);
  display: flex;
  justify-content: center;
  align-items: center;
}
.v-data-table-footer {
  margin-top: 70px;
}
</style>
