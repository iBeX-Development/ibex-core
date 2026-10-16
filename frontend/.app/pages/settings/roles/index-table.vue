<script setup lang="ts">
definePageMeta({
  middleware: ['auth'],
  title: 'Roles',
  showback: true,
  preview: {
    title: 'Table list 1',
    description: 'For list views and collections',
    categories: ['layouts', 'lists'],
    src: '/img/screens/layouts-table-list-1.png',
    srcDark: '/img/screens/layouts-table-list-1-dark.png',
    order: 44,
  },
})

const props = defineProps({
  location: Number,
  work_order: Number,
  type: String,
  tab: String,
  assigned: String,
  className: String,
})

import { useI18n } from 'vue-i18n'
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import AddModalForm from './AddModalForm.vue'

const active_tab = ref('tab-1')
const myId = window.localStorage.getItem('myId')
const { open } = usePanels()
const route = useRoute()
const router = useRouter()
const loading = ref(false)

const { params } = useRoute()
const teams = ref([])
const wo_statuses = ref([])
const roles_users = ref([])
const key = ref(1)

const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const { getUsers } = useDirectusUsers()
const config = useRuntimeConfig()
const { getItems, deleteItems, updateItem, createItems } = useDirectusItems()
const runtimeConfig = useRuntimeConfig()
const { token } = useDirectusToken()

const page = computed({
  get: () => Number.parseInt((route.query.page as string) ?? '1', 10),
  set: (value) => {
    router.push({
      query: {
        ...route.query,
        page: value,
      },
    })
  },
})

const data = ref([])
const all_users = ref([])
const filterValue = ref('')
const filterNumber = ref('')
const perPage = ref(10)

//comments
const file_items = ref(null)
const selectedItem = ref(null)
const isOpenImg = ref(false)
const isOpenComment = ref(false)
const isModalOpen = ref(false)
const isModalApproveConfirmOpen = ref(false)

// userlist
const isModalUserListOpen = ref(false)

const query = computed(() => {
  return {
    filter: filterValue.value,
    perPage: perPage.value,
    page: page.value,
  }
})

const selected = ref<number[]>([])

const refresh = async (item) => {
  console.log('refreshed')
  data.value = []
  key.value += 1
  await loadRoles()
}
const itemsPerPage = ref(25)
const search = ref('')
const serverItems = ref([])
const totalItems = ref(0)

const getTableHeaders = () => {
  return [
    { title: t('Name'), key: 'name', align: 'start', width: '30%' },
    {
      title: t('Description'),
      key: 'description',
      align: 'start',
      width: '30%',
    },
    { title: t('Users'), key: 'users', align: 'start', width: '30%' },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const onEdit = (item) => {
  selectedItem.value = item
  isModalOpen.value = true
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)

  console.log('onEdit', item)
}

const onDelete = (item) => {
  selectedItem.value = item
  isModalOpen.value = false
  isModalApproveConfirmOpen.value = true
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)

  console.log('onDelete', item)
}

const onRowClicked = (item) => {
  // console.log('onRowClicked', item)
  open('rolePermissionMore', { role: item })
}

const loadRoles = async (pager = 1, itemsPerPage = 20, sortBy = []) => {
  try {
    loading.value = true

    let sort_array = ['-created_at']
    let searchField = 'id'
    sortBy.map((sort_object) => {
      let sort_direction = sort_object?.order == 'asc' ? '' : '-'
      let sort_key = sort_object?.key
      sort_array.push(sort_direction.concat(sort_key))
    })
    const filters =
      filterValue.value != ''
        ? `?filter[name][_contains]=${encodeURIComponent(
            filterValue.value,
          )}&filter[is_active][_eq]=1`
        : '?filter[is_active][_eq]=1'

    const url = `${runtimeConfig.public.directus.url}roles${filters}`

    // console.log('Request URL:', url)

    const rolesRes = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.value}`,
      },
    })

    let jsonData = await rolesRes.json()
    data.value = jsonData.data
    console.log('items.data', jsonData)

    serverItems.value = jsonData.data
    totalItems.value = jsonData.data.length

    loading.value = false
  } catch (e) {
    console.log(e)
  }
}

const loadAddRoles = async () => {
  const res_items = await getItems({
    collection: 'Users_perm',
    params: {
      // filter: { user_id: item.id },
      meta: 'filter_count',
      fields: ['*'],
    },
  })

  roles_users.value = res_items.data
  // console.log('res_items', roles_users)
}

const handleModalOpen = () => {
  selectedItem.value = null
  isModalOpen.value = true
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log(isModalOpen.value)
}

const do_make = async (item, type) => {
  console.log('do_make.delete', item, type)

  let url = `${runtimeConfig.public.directus.url}roles/${item.id}`
  const response = await fetch(url, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token.value}`,
    },
    body: JSON.stringify({
      is_active: 0,
    }),
  })

  const result = await response.json()

  if (response.ok) {
    console.log('delete_ok', response)
    await loadRoles({ page: 1, itemsPerPage: -1, sortBy: [] })
  } else {
    toaster.show({
      title: t('Error'),
      message: t(`HTTP error! status: ${response.status}`),
      color: 'danger',
      closable: true,
    })
  }
}

const handleChangeKey = async () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
  await loadRoles({ page: 1, itemsPerPage: -1, sortBy: [] })
}

const handleChangeModalKey = () => {
  selectedItem.value = null
}

const handleModalConfirmClose = () => {
  isModalOpen.value = false
  isModalApproveConfirmOpen.value = false
  selectedItem.value = null
}

onMounted(async () => {
  await loadRoles()
  await loadAddRoles()
})

const getUserCountForRole = (roleId) => {
  if (roles_users.value.length > 0)
    return roles_users.value.filter((r) => r.role === roleId).length
  return 0
}

const showUsers = (item, cnt) => {
  if (cnt == 0) return
  let roleUser = roles_users.value
    .filter((r) => r.role === item.id)
    .map((r) => r.user_id)
  isModalUserListOpen.value = true

  all_users.value = [...roleUser, ...item.users]

  console.log('item.all_users', all_users)
}

const handleModalUserListClose = () => {
  isModalUserListOpen.value = false
}

watch(filterValue, async () => {
  await loadRoles()
})
</script>

<template>
  <div
    class="relative pb-20 dark:[--color-input-default-bg:var(--color-muted-950)] my_roles"
  >
    <TairoContentWrapper>
      <!-- <div class="relative mt-[60px]"> -->
      <!-- <template #right>
        <BaseInput
          v-model="filterValue"
          icon="lucide:search"
          :placeholder="$t('Filter')"
          :classes="{
            wrapper: 'w-[340px]',
          }"
        />
      </template>
      <template #left>
        <BaseButton class="w-full sm:w-32" @click="handleModalOpen">
          <Icon name="lucide:plus" class="size-4" />
          <span style="white-space: nowrap">{{ $t('Add Role') }}</span>
        </BaseButton>
      </template> -->
      <!-- </div> -->
      <div class="grid grid-cols-12 gap-6">
        <!-- Header -->
        <div class="col-span-12">
          <BaseButton class="w-full sm:w-32" @click="handleModalOpen">
            <Icon name="lucide:plus" class="size-4" />
            <span style="white-space: nowrap">{{ $t('Add Role') }}</span>
          </BaseButton>
        </div>
        <div class="col-span-12 GridBody">
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
                      @click="onEdit(item)"
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
                      @click="onDelete(item)"
                    >
                      <template #start>
                        <Icon
                          name="ph:trash-duotone"
                          class="me-2 block h-5 w-5"
                        />
                      </template>
                    </BaseDropdownItem>
                    <BaseDropdownDivider />
                    <BaseDropdownItem
                      :title="t('More')"
                      :text="t('More options')"
                      @click="onRowClicked(item)"
                    >
                      <template #start>
                        <Icon
                          name="ph:dots-three-outline"
                          class="me-2 block h-5 w-5"
                        />
                      </template>
                    </BaseDropdownItem>
                  </div>
                </BaseDropdown>
              </div>
            </template>
          </v-data-table-server>
          <!-- <div class="flex mt-6">
            <BasePagination
              v-model:page="page"
              :total="data?.length ?? 0"
              :items-per-page="perPage"
              rounded="lg"
              class="w-full"
            />
          </div> -->
        </div>
      </div>
    </TairoContentWrapper>
    <UserList
      :open="isModalUserListOpen"
      :close="handleModalUserListClose"
      :users="all_users"
      :searchInput="false"
      :chooseInput="false"
      :title="$t('Users')"
    />
    <AddModalForm
      :key="key"
      :title="$t('Role')"
      code="Role"
      :open="isModalOpen"
      :close="handleModalClose"
      :editRow="selectedItem"
      :refresh="handleChangeKey"
      :refresh_modal="handleChangeModalKey"
    />
    <ConfirmModalForm
      code="Role"
      :text="$t('Are you sure delete this role?')"
      :successfullText="false"
      :itemsValue="selectedItem"
      actionType="delete"
      :open="isModalApproveConfirmOpen"
      :close="handleModalConfirmClose"
      :do_make="do_make"
    />
  </div>
</template>
<style>
.my_roles .completed_items {
  background: #e6f7e6;
}

/* .my_task_dark .bg-white {
  background-color: rgb(30 41 59) !important;
  color: #94a3b8 !important;
} */
</style>
