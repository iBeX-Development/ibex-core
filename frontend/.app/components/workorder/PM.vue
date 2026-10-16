<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import '~/assets/css/vcalendar.css'
import {
  active,
  priorities,
  statuses,
} from '~/components/workorder/WorkOrderConstants'

const user = useDirectusUser()
const { t } = useI18n({ useScope: 'global' })
const router = useRouter()

const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const props = defineProps({
  status: Object,
  location: Number,
  work_order_type: String,
  asset: Number,
})

const itemsPerPage = ref(25)
const getTableHeaders = () => {
  return [
    { title: t('Name'), key: 'name', align: 'start', width: '30%' },
    {
      title: t('Priority'),
      key: 'priority',
      align: 'start',
      width: '20%',
    },
    {
      title: t('Schedule'),
      key: 'schedule.name',
      align: 'start',
      width: '20%',
    },
    {
      title: t('Assigned to'),
      key: 'assigned_to.first_name',
      align: 'start',
      width: '10%',
    },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const refreshKey = ref(0)
const status = ref(statuses)
const priority = ref(priorities)
const enable = ref(active)

const handleChangeKey = () => {
  refreshKey.value =
    Math.random().toString(36).substring(2) + Date.now().toString(36)
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
      company_id: { _eq: myCompanyId },
    }
    if (props.status) {
      filters['status'] = props.status
    }
    if (props.work_order_type) {
      filters['type'] = {
        code_work_order: props.work_order_type,
      }
    }
    if (props.location) {
      filters['asset'] = {
        location: props.location,
      }
    }
    if (props.asset) {
      filters['asset'] = props.asset
    }
    console.log(filters)
    const items = await getItems<any>({
      collection: 'Work_pm',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: [
          '*',
          'assigned_to.first_name',
          'asset.*',
          'type.code_work_order',
          'schedule.*',
        ],
      },
    })
    serverItems.value = items.data
    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {
    console.log(e)
  }
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12 pm-table">
        <BaseInput
          v-model="search"
          icon="lucide:search"
          :placeholder="$t('Search')"
          :classes="{
            wrapper: 'flex justify-end mb-[10px]',
          }"
        />
        <v-data-table-server
          v-model:items-per-page="itemsPerPage"
          :key="refreshKey"
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
          <template v-slot:item.name="{ item }">
            <a v-bind="item" :href="'/pm/view/' + item.id">
              <BaseTag
                v-bind="item"
                :key="item.id"
                shape="rounded"
                color="primary"
                class="mr-5"
              >
                {{ item.name }}
              </BaseTag>
            </a>
          </template>

          <template v-slot:item.priority="{ item }">
            <BaseTag
              v-bind="item"
              :key="item.id"
              shape="rounded"
              color="warning"
              class="mr-5"
              >{{
                priority.filter((_priority) => {
                  return (
                    _priority.__original == item.priority ||
                    _priority.value == item.priority
                  )
                }).length > 0
                  ? priority.filter((_priority) => {
                      return (
                        _priority.__original == item.priority ||
                        _priority.value == item.priority
                      )
                    })[0].text
                  : 'ds'
              }}</BaseTag
            >
          </template>

          <template v-slot:item.schedule.name="{ item }">
            {{ item?.schedule ? item?.schedule.name : '-' }}
          </template>

          <!-- <template v-slot:item.status="{ item }">
            <BaseTag
              v-bind="item"
              :key="item.id"
              shape="rounded"
              color="warning"
              class="mr-5"
              >{{
                status.filter((_status) => {
                  return _status.value == item.status
                }).length > 0
                  ? status.filter((_status) => {
                      return _status.value == item.status
                    })[0].text
                  : ''
              }}</BaseTag
            >
          </template>

          <template v-slot:item.active="{ item }">
            <BaseTag
              v-bind="item"
              :key="item.id"
              shape="rounded"
              color="warning"
              class="mr-5"
              >{{
                enable.filter((_enable) => {
                  return _enable.value == item.active
                }).length > 0
                  ? enable.filter((_enable) => {
                      return _enable.value == item.active
                    })
                  : ''
              }}</BaseTag
            >
          </template> -->

          <!-- <template v-slot:item.action="{ item }">
            <div v-if="item?.id">
              <WorkorderDropdown
                :id="item?.id"
                :refresh="handleChangeKey"
                :work_order_type="item?.type?.code_work_order"
              />
            </div>
          </template> -->
        </v-data-table-server>
      </div>
    </div>
  </div>
</template>

<style>
.pm-table {
  margin-top: 5px;
}
.pm-table .v-data-table thead th {
  white-space: nowrap;
}

.pm-table .v-data-table .v-data-table__td .wo_name {
  cursor: pointer;
  margin-right: 5px;
}

.pm-table .v-data-table .v-data-table__td .nui-dropdown {
  margin-top: 0px !important;
}

.pm-table .v-data-table .v-data-table__td .nui-checkbox .nui-checkbox-inner {
  border-width: 1px !important;
}
.pm-table .v-data-table-footer {
  margin-top: 70px;
}
</style>
