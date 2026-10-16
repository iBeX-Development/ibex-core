<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'

const user = useDirectusUser()
const { t } = useI18n({ useScope: 'global' })
const { getUsers } = useDirectusUsers()
const { getItems, deleteItems, updateItem, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const itemsPerPage = ref(25)
const getTableHeaders = ref([])
const getTableUserHeaders = () => {
  return [
    { title: t('Check'), key: 'check', align: 'start', width: '25%' },
    { title: t('First name'), key: 'first_name', align: 'start', width: '25%' },
    { title: t('Last name'), key: 'last_name', align: 'start', width: '25%' },
    { title: t('Email'), key: 'email', align: 'start', width: '30%' },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}

const getTableTeamHeaders = () => {
  return [
    { title: t('Check'), key: 'check', align: 'start', width: '25%' },
    { title: t('Name'), key: 'name', align: 'start', width: '30%' },
    {
      title: t('Users'),
      key: 'users',
      align: 'start',
      sortable: false,
    },
    {
      title: t('Created'),
      key: 'user_created.first_name',
      align: 'start',
      sortable: false,
    },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}

const getTableCompanyHeaders = () => {
  return [
    { title: t('Check'), key: 'check', align: 'start', width: '25%' },
    { title: t('Name'), key: 'name', align: 'start', width: '30%' },
    {
      title: t('Created'),
      key: 'user_created.first_name',
      align: 'start',
      sortable: false,
    },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const refreshKey = ref(0)
const checkedItems = ref<number[]>([]) // Array to store checked items' IDs

const props = defineProps({
  open: Boolean,
  chooseBttn: Boolean,
  chosedItems: Array,
  saveBttn: Boolean,
  close: Function,
  setUser: Function,
  saveUser: Function,
  class: String,
  filter: Object,
  collection: String,
  fields: String,
  useslot: Array,
})

console.log('collection', props)

if (props.collection == 'Users') {
  getTableHeaders.value = getTableUserHeaders()
} else if (props.collection == 'Teams') {
  getTableHeaders.value = getTableTeamHeaders()
} else if (props.collection == 'Contractors') {
  getTableHeaders.value = getTableCompanyHeaders()
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
    let filters = {
      active: 1,
      company_id: myCompanyId,
    }

    if (props.collection == 'Users') {
      const items1 = await getUsers({
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
      serverItems.value = items1.data
      totalItems.value = items1.meta.filter_count
    } else if (props.collection == 'Teams') {
      const items2 = await getItems({
        collection: 'Teams',
        params: {
          filter: filters,
          limit: itemsPerPage,
          page: page,
          sort: sort_array,
          meta: 'filter_count',
          search: search.value,
          fields: [
            '*,user_created.first_name, users.directus_users_id.first_name, users.directus_users_id.email',
          ],
        },
      })
      serverItems.value = items2.data
      totalItems.value = items2.meta.filter_count
    } else {
      const items2 = await getItems({
        collection: props.collection,
        params: {
          filter: { company_id: myCompanyId },
          limit: itemsPerPage,
          page: page,
          sort: sort_array,
          meta: 'filter_count',
          search: search.value,
          fields: ['*,user_created.first_name'],
        },
      })
      serverItems.value = items2.data
      totalItems.value = items2.meta.filter_count
    }
    // console.log('serverItems', serverItems)

    // Re-check the items if chosedItems is passed
    if (props.chosedItems && props.chosedItems.length > 0) {
      checkedItems.value = props.chosedItems.map((item: any) =>
        typeof item === 'object' ? item.id : item,
      )
    }

    loading.value = false
  } catch (e) {}
}

const handleChoose = () => {
  // console.log('checkedItems', checkedItems)
  const selectedItems = serverItems.value.filter((item) =>
    checkedItems.value.includes(item.id),
  )
  // console.log('Selected Items:', selectedItems)
  // Call the saveUser function with the selected items
  props.saveUser(selectedItems)
}

// watch(
//   () => props.open,
//   (newVal) => {
//     console.log('props.chosedItems', props)

//     if (newVal && props.chosedItems) {
//       checkedItems.value = [...props.chosedItems]
//     }
//   },
// )
watch(
  () => props.open,
  (newVal) => {
    if (newVal && props.chosedItems) {
      checkedItems.value = props.chosedItems.map((item: any) =>
        typeof item === 'object' ? item.id : item,
      )
    }
  },
)
</script>

<template>
  <TairoModal
    :open="props.open"
    :size="'xl'"
    @close="close"
    :classes="{ wrapper: 'TairoModal' }"
  >
    <template #header>
      <div :class="['flex w-full items-center justify-between ', props.class]">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
        >
          &nbsp;{{ t('Choose') }}
        </h3>
        <BaseButtonClose @click="close()" />
      </div>
    </template>

    <div class="max-h-[580px] overflow-y-auto TairoModalBody userCheckModal">
      <BaseInput
        v-model="search"
        icon="lucide:search"
        :placeholder="$t('Search')"
        :classes="{ wrapper: 'w-full sm:w-auto Search' }"
      />
      <v-data-table-server
        v-model:items-per-page="itemsPerPage"
        :key="refreshKey"
        :headers="getTableHeaders"
        :items-length="totalItems"
        :items="serverItems"
        :loading="loading"
        :search="search"
        :class="`elevation-1 ${props.class}`"
        item-value="name"
        :theme="$colorMode.value"
        @update:options="loadItems"
        :pageText="t('{0}-{1} of {2}', ['{0}', '{1}', '{2}'])"
        :items-per-page-options="[10, 25, 50, 100, -1]"
        :items-per-page-text="t('Item page')"
        :loading-text="t('loading')"
        :no-data-text="t('No records')"
      >
        <template v-slot:item.check="{ item }">
          <div>
            <BaseCheckbox
              v-model="checkedItems"
              :value="item.id"
              rounded="none"
              color="primary"
            />
          </div>
        </template>

        <template v-slot:item.action="{ item }">
          <div v-if="props.chooseBttn == true">
            <BaseButton
              :class="`Choose`"
              @click="
                () => {
                  props.setUser(item)
                  close()
                }
              "
              >{{ t('Choose') }}</BaseButton
            >
          </div>
        </template>

        <template
          v-if="props.collection == 'Teams'"
          v-slot:item.users="{ item }"
        >
          <div
            v-for="(user, ind) in item.users"
            :key="ind"
            shape="rounded"
            class="mr-5 my-1"
          >
            {{
              user?.directus_users_id?.first_name
                .toLowerCase()
                .replace(/^\w/, (c) => c.toUpperCase())
            }}
          </div>
        </template>
      </v-data-table-server>
      <div v-if="props.saveBttn == true" class="saveBox">
        <BaseButton @click="handleChoose" shape="curved" class="w-full save">
          {{ $t('Choose') }}
        </BaseButton>
      </div>
    </div>
  </TairoModal>
</template>

<style>
.v-overlay-container {
  z-index: 99999;
  display: flex;
}
.userCheckModal .v-data-table-footer {
  flex-wrap: unset !important;
}
.userCheckModal .saveBox {
  float: right;
  margin-top: 30px;
}
.userCheckModal .save {
  width: 210px;
}
</style>
