<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'

import DeletionActiveModalForm from '~/components/form/DeletionActiveModalForm.vue'
import RoleModalForm from '~/components/form/RoleModalForm.vue'
import UserModalForm from '~/components/form/UserModalForm.vue'

const { getUsers } = useDirectusUsers()
const { getItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'User list',
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

const itemsPerPage = ref(10)
const getTableHeaders = () => {
  return [
    { title: t('First name'), key: 'first_name', align: 'start', width: '10%' },
    { title: t('Last name'), key: 'last_name', align: 'start', width: '10%' },
    { title: t('Email'), key: 'email', align: 'start', width: '10%' },
    { title: t('Active'), key: 'active', align: 'start', width: '10%' },
    { title: t('Company'), key: 'company', align: 'start', width: '15%' },
    {
      title: t('Roles'),
      key: 'roles',
      align: 'start',
      width: '20%',
      sortable: false,
    },
    {
      title: t('Location'),
      key: 'location',
      align: 'start',
      width: '50%',
      sortable: false,
    },

    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)

const loadItems = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array: string[] = []

  sortBy.map((sort_object: { order: string; key: any }) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })

  loading.value = true
  try {
    const filters = {
      // active: 1,
      company_id: myCompanyId,
    }

    const items = await getUsers({
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: ['*', 'company_id.name', 'role.*', 'location_id.*'],
      },
    })

    console.log('getUsers', items)

    serverItems.value = items.data
    totalItems.value = items.meta.filter_count
    loading.value = false
    // Default role read нээх
    serverItems.value.forEach((item, index) => {
      toggleRoleRead(index, item, true)
    })
  } catch (e) {}
}

// Modal new & edit form
const isModalOpen = ref(false)
const isRoleModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const selectedRowItems = ref(-1)
const task = ref('add')
// const isRoleRead = ref(false)

let activeRowIndex = ref<null | number>(null)

const readRoleItems = ref([])

const key = ref(1)
const key_update_modal = ref(2)

const toaster = useToaster()

const do_add = () => {
  selectedItem.value = -1
  selectedRowItems.value = -1
  isModalOpen.value = true
  task.value = 'add'
}

const do_edit = (item) => {
  selectedItem.value = item.id
  selectedRowItems.value = item
  isModalOpen.value = true
  task.value = 'edit'
}

const change_pass = (item: { id: number }) => {
  selectedItem.value = item.id
  isModalOpen.value = true
  task.value = 'change_pass'
}

const do_delete = (item: { id: number }) => {
  task.value = 'delete'
  isModalConfirmOpen.value = true
  selectedItem.value = item.id
}

const handleModalClose = () => {
  isModalOpen.value = false
  isRoleModalOpen.value = false
  selectedItem.value = -1
  selectedRowItems.value = -1
  task.value = 'add'
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleChangeModalKey = () => {
  selectedItem.value = -1
  selectedRowItems.value = -1
  task.value = 'add'
}

const clearItem = () => {
  selectedItem.value = -1
  selectedRowItems.value = -1
  task.value = 'add'
  isModalConfirmOpen.value = false
}

const path = () => {
  if (selectedItem.value == -1) return 'fields/directus_users'
  else return 'users/' + selectedItem.value
}

const set_title = () => {
  if (task.value === 'add') return 'Add user'
  else if (task.value === 'edit') return 'Edit user'
  else if (task.value === 'change_pass') return 'Change password'
  else return ''
}

const addRole = (user: { id: number }) => {
  // Logic to add role to the user
  console.log('Adding role to:', user)
  task.value = 'role'
  isRoleModalOpen.value = true
  selectedItem.value = user.id
}

const toggleRoleRead = async (
  index: number,
  item: { id: string },
  isDefault = false,
) => {
  if (activeRowIndex.value === index && !isDefault) {
    activeRowIndex.value = null
    return
  }

  activeRowIndex.value = index

  const res_items = await getItems({
    collection: 'Users_perm',
    params: {
      filter: { user_id: item.id, company_id: myCompanyId },
      meta: 'filter_count',
      fields: ['*', 'role.*', 'location.*'],
    },
  })

  readRoleItems.value[index] = res_items.data
}

const isRoleRead = (index: number) => {
  // Returns true if the current row is the active one
  return activeRowIndex.value === index
}

const deleteRole = async (index: number, roleItem: { id: number }) => {
  console.log('deleteRole', readRoleItems)

  if (!readRoleItems.value[index]) {
    readRoleItems.value[index] = []
  }

  // Check if readRoleItems[index] is an array
  if (Array.isArray(readRoleItems.value[index])) {
    readRoleItems.value[index] = readRoleItems.value[index].filter(
      (item) => item.id !== roleItem.id,
    )

    await deleteItems({
      collection: 'Users_perm',
      items: [roleItem.id],
    })

    console.log(`Role with ID ${roleItem.id} has been deleted`)
  } else {
    console.error(`No roles found for user at index ${index}`)
  }
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton @click="do_add()">
          <Icon
            name="material-symbols:manage-accounts-outline-rounded"
            class="-ms-1 h-4 w-4"
          />
          <span class="text-[11px]">{{ $t('User add') }}</span>
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
          <template #item.active="{ item }">
            {{ Number(item.active) === 1 ? t('Active') : t('Inactive') }}
          </template>
          <template #item.company="{ item }">
            {{ item.company_id?.name || '-' }}
          </template>

          <template v-slot:item.roles="{ item, index }">
            <div class="flex items-center space-x-2">
              <button
                @click="addRole(item)"
                class="text-sky-400 hover:text-sky-600"
              >
                <Icon name="ph:plus-circle-fill" class="h-5 w-5" />
                <!-- Use the plus icon -->
              </button>
              <span>{{ item.role?.name }}</span>
              <!-- <button
                @click="toggleRoleRead(index, item)"
                class="text-sky-400 hover:text-sky-600"
              >
                <Icon name="bx:down-arrow-circle" />
              </button> -->
            </div>
            <div style="margin-left: 16px" v-if="readRoleItems[index]">
              <div
                class="flex m-3"
                v-for="(roleItem, idx) in readRoleItems[index]"
                :key="idx"
                :permId="roleItem.id"
              >
                <div>{{ roleItem.role ? roleItem.role.name : '' }}</div>
                <div
                  class="ml-2.5 cursor-pointer"
                  @click="deleteRole(index, roleItem)"
                >
                  <Icon name="wpf:delete" />
                </div>
              </div>
            </div>
          </template>

          <template v-slot:item.location="{ item, index }">
            <div class="flex-col items-center space-x-2">
              <div class="ml-4">
                {{ item.location === 'all' ? $t('All') : item.location || '-' }}
              </div>
              <div v-if="readRoleItems[index]">
                <div
                  class="m-3"
                  v-for="(roleItem, idx) in readRoleItems[index]"
                  :key="idx"
                >
                  <span>{{
                    roleItem.location ? roleItem.location.name : ''
                  }}</span>
                </div>
              </div>
            </div>
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
                    :title="t('Change password')"
                    :text="t('Change password')"
                    @click="change_pass(item)"
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
                    @click="do_delete(item)"
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
        <UserModalForm
          :key="selectedItem"
          :title="set_title()"
          :code="Users"
          :path="path()"
          :task="task"
          :open="isModalOpen"
          :close="handleModalClose"
          :row="selectedItem"
          :rowItems="selectedRowItems"
          :refresh="handleChangeKey"
          :refresh_modal="handleChangeModalKey"
          size="2xl"
          schema_column="two-column-form"
          class="userForm"
          icon="material-symbols:manage-accounts-outline-rounded"
        />
        <RoleModalForm
          :key="selectedItem"
          :title="set_title()"
          :path="path()"
          :task="task"
          :open="isRoleModalOpen"
          :close="handleModalClose"
          :row="selectedItem"
          :refresh="handleChangeKey"
          :refresh_modal="handleChangeModalKey"
          size="2xl"
          schema_column="two-column-form"
        />
        <DeletionActiveModalForm
          :key="selectedItem"
          code="User"
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
.v-data-table__thead {
  white-space: nowrap;
  color: #939090;
}
</style>
