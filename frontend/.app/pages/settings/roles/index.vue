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
const myCompanyId = getMyCompanyId()

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
          )}&filter[is_active][_eq]=1&filter[company_id][_eq]=${myCompanyId}`
        : `?filter[is_active][_eq]=1&filter[company_id][_eq]=${myCompanyId}`

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
      filter: { company_id: myCompanyId },
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

// item.users (directus_users.role reverse relation) болон Users_perm-ийн
// user_id-ууд давхцаж болдог тул (нэг хэрэглэгч хоёуланд нь орсон байж болно)
// давхардлыг арилгаж, өвөрмөц хэрэглэгчийн id-уудыг буцаана
const getRoleUserIds = (item) => {
  const permUserIds = roles_users.value
    .filter((r) => r.role === item.id)
    .map((r) => r.user_id)

  return [...new Set([...(item.users || []), ...permUserIds])]
}

const getUserCountForRole = (item) => {
  return getRoleUserIds(item).length
}

const showUsers = (item, cnt) => {
  if (cnt == 0) return
  isModalUserListOpen.value = true
  all_users.value = getRoleUserIds(item)

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
        <div class="col-span-12">
          <div
            :class="`w-full my_task_${
              $colorMode.value === 'light' ? '' : 'dark'
            } `"
          >
            <BaseInput
              v-model="filterValue"
              icon="lucide:search"
              :placeholder="$t('Search')"
              :classes="{
                wrapper: 'w-full sm:w-auto Searching',
              }"
            />
            <TairoTable rounded="sm" :scrollable="false">
              <template #header>
                <TairoTableHeading spaced class="p-4">
                  <div class="flex items-center">№</div>
                </TairoTableHeading>
                <TairoTableHeading spaced>
                  {{ $t('Role Name') }}
                </TairoTableHeading>
                <TairoTableHeading spaced>
                  {{ $t('Description') }}
                </TairoTableHeading>
                <TairoTableHeading spaced>
                  {{ $t('Users') }}
                </TairoTableHeading>
                <TairoTableHeading spaced class="text-end">
                  {{ $t('Action') }}
                </TairoTableHeading>
              </template>

              <!-- <BaseCheckboxGroup v-model="selected" as-child> -->
              <TairoTableRow v-for="(item, index) in data" :key="item.id">
                <TairoTableCell spaced>
                  <div class="flex items-center">
                    <!-- <BaseCheckbox :value="item.id" /> -->
                    <p class="font-heading text-sm font-semibold">
                      {{ index + 1 }}.
                    </p>
                  </div>
                </TairoTableCell>
                <TairoTableCell spaced>
                  <div class="flex items-center">
                    <div
                      class="ms-3 leading-none max-w-[272px] overflow-hidden text-ellipsis whitespace-nowrap"
                      :title="item.name"
                    >
                      <h4
                        class="text-muted-900 dark:text-white font-sans text-sm font-medium"
                      >
                        {{ item.name }}
                      </h4>
                    </div>
                  </div>
                </TairoTableCell>
                <TairoTableCell spaced class="capitalize">
                  <h4
                    class="text-muted-900 dark:text-white font-sans text-sm font-medium"
                  >
                    {{ item.description }}
                  </h4>
                </TairoTableCell>
                <TairoTableCell
                  spaced
                  class="capitalize cursor-pointer"
                  @click="showUsers(item, getUserCountForRole(item))"
                >
                  {{ getUserCountForRole(item) }}
                </TairoTableCell>
                <TairoTableCell spaced>
                  <div class="flex justify-end">
                    <BaseButtonAction
                      v-if="!item.admin_access"
                      color="muted"
                      class="mr-2"
                      @click="onDelete(item)"
                    >
                      <span>{{ $t('Delete') }}</span>
                    </BaseButtonAction>
                    <BaseButtonAction
                      v-if="!item.admin_access"
                      color="muted"
                      class="mr-2"
                      @click="onEdit(item)"
                    >
                      <span>{{ $t('Edit') }}</span>
                    </BaseButtonAction>
                    <BaseButtonAction color="muted" @click="onRowClicked(item)">
                      <span>{{ $t('More') }}</span>
                    </BaseButtonAction>
                  </div>
                </TairoTableCell>
              </TairoTableRow>
            </TairoTable>
          </div>
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
