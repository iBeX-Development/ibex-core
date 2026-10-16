<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import '~/assets/css/vcalendar.css'
const { open } = usePanels()

import PriorityCell from '~/components/custom/priorityCell.vue'
import WorkorderDropdown from '~/components/workorder/Dropdown.vue'
import {
  completed_wo_status,
  open_wo_status,
  wo_status,
} from '~/components/workorder/WorkOrderStatus'

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
  call_type: String,
  asset: Number,
  class: String,
  wo_status: Object,
  wo_status_items: Object,
  type: String,
})

// console.log('open_wo_status', props)

const itemsPerPage = ref(10)
const getTableHeaders = () => {
  return [
    {
      title: t('Number'),
      key: 'id',
      align: 'start',
      width: '6%',
      sortable: true,
    },
    {
      title: t('Priority'),
      key: 'priority',
      align: 'start',
      width: '6%',
      sortable: true,
    },
    {
      title: t('Name'),
      key: 'name',
      align: 'start',
      width: '20%',
      sortable: true,
    },
    // {
    //   title: t('Status'),
    //   key: 'status',
    //   align: 'start',
    //   width: '13%',
    //   sortable: true,
    //   filterable: true,
    // },
    {
      title: t('Status'),
      key: 'wo_status',
      align: 'start',
      width: '13%',
      sortable: true,
      filterable: true,
    },
    {
      title: t('Created'),
      key: 'created_at',
      align: 'start',
      width: '9%',
      sortable: true,
    },
    {
      title: t('Due date'),
      key: 'due',
      align: 'start',
      width: '10%',
      sortable: true,
      style: { color: 'green' },
    },
    {
      title: t('Assigned'),
      key: 'assigned_to.first_name',
      align: 'start',
      width: '10%',
      sortable: false,
    },
    {
      title: t('State'),
      key: 'is_accepted',
      align: 'start',
      width: '6%',
      sortable: true,
    },
    {
      title: t('Printed'),
      key: 'printed',
      align: 'start',
      width: '10%',
      sortable: true,
    },
    // { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const toaster = useToaster()
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const refreshKey = ref(0)
const enable = ref(active)
const filter_status = ref('')
const { updateItem } = useDirectusItems()
const currentRecord = ref(null)

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
      active: '1',
      company_id: { _eq: myCompanyId },
    }

    let merged_status = {
      _in: [...new Set([...open_wo_status._in, ...completed_wo_status._in])],
    }

    let wo_status_filter1 = wo_status
    let wo_status_filter = merged_status
    if (props.status) {
      // if (props.type == 'open') {
      //   wo_status_filter = open_wo_status
      // } else if (props.type == 'completed') {
      //   wo_status_filter = completed_wo_status
      // } else if (props.type == 'pm') {
      //   wo_status_filter = draft_status_id
      // } else {
      //   wo_status_filter = wo_status
      // }
      // console.log('wo_status_oruulah', open_wo_status)

      // Status override
      if (filter_status.value === '') {
        // filters['status'] = props.status
        filters['wo_status'] = wo_status_filter
      } else {
        filters['_and'] = []
        let temp_filter = { status: props.status }
        filters['_and'].push(temp_filter)
        temp_filter = {
          status: { _eq: filter_status.value },
        }
        filters['_and'].push(temp_filter)
      }
    }

    if (props.work_order_type && props.work_order_type == 'pm') {
      filters['created_type'] = { _in: ['pm', 'system'] }
    } else if (props.work_order_type && props.work_order_type == 'wo') {
      filters['created_type'] = { _in: ['request', 'open'] }
    }

    if (props.work_order_type != 'request') {
      if (props.location) {
        filters['_or'] = []
        let temp_filter = {}
        temp_filter['asset'] = {
          location: props.location,
        }
        filters['_or'].push(temp_filter)

        temp_filter = {}
        temp_filter['location'] = props.location
        filters['_or'].push(temp_filter)
      }
      if (props.asset) {
        filters['asset'] = props.asset
      }
    } else {
      if (props.location) {
        filters['location'] = props.location
      }
    }

    // console.log('sodoooo_', filters)

    const items = await getItems<any>({
      collection: 'Work_inspections',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: [
          '*',
          'assigned_to.*',
          'assigned_team.name',
          'asset.*',
          'type.code_work_order',
          'wo_status.*',
          'wo_status.code_color.*',
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

const getPriorityColor = (priorityValue) => {
  const priority = priorities.find(
    (p) => p.value == priorityValue || p.__original == priorityValue,
  )
  return priority?.defaultColor || 'gray'
}

const getStatusColor = (statusValue) => {
  const status = statuses.find((s) => s.value === statusValue)
  return status?.color || 'gray'
}

const showAsset = (item) => {
  // console.log('showAsset', item)
  open('asset', {
    id: item.id,
    data: item,
    // refresh: refreshGrid(),
  })
}

const onClick = (item) => {
  // console.log('onClick', item)

  // if ([1, 2, 8].includes(item.wo_status.id)) {
  open('workorderopenmore', {
    id: item.id,
    data: item,
    backBttn: true,
    active_tab: props.work_order_type,
    backFn: showAsset(item),
  })
  // } else if (item.wo_status.id == 3) {
  //   open('workordercompletedmore', {
  //     id: item.id,
  //     data: item,
  //     backBttn: true,
  //     active_tab: props.work_order_type,
  //     backFn: showAsset(item),
  //     // refresh: refreshGrid(),
  //   })
  // }
}

const exportExcel = () => {
  try {
    let filters = {
      active: '1',
    }
    if (props.status) {
      // console.log('filter_status.value', filter_status.value)
      // Status override
      if (filter_status.value === '') {
        filters['status'] = props.status
      } else {
        filters['_and'] = []
        let temp_filter = { status: props.status }
        filters['_and'].push(temp_filter)
        temp_filter = {
          status: { _eq: filter_status.value },
        }
        filters['_and'].push(temp_filter)
      }
    }
    if (props.work_order_type) {
      filters['type'] = {
        code_work_order: props.work_order_type,
      }
    }
    if (props.work_order_type != 'request') {
      if (props.location) {
        filters['_or'] = []
        let temp_filter = {}
        temp_filter['asset'] = {
          location: props.location,
        }
        filters['_or'].push(temp_filter)
        temp_filter = {}
        temp_filter['location'] = props.location
        filters['_or'].push(temp_filter)
      }
      if (props.asset) {
        filters['asset'] = props.asset
      }
    } else {
      if (props.location) {
        filters['location'] = props.location
      }
    }

    const items = getItems<any>({
      collection: 'Work_inspections',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        sort: 'id',
        meta: 'filter_count',
        search: search.value,
        export: 'csv',
        fields: [
          'id',
          'name',
          'priority',
          'status',
          'created_at',
          'due',
          'type.code_work_order',
        ],
      },
    }).then((response) => {
      console.log(response)
    })
    console.log(items)
    /*const blob = new Blob([items], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      link.href = window.URL.createObjectURL(blob);
      link.download = "workorders.csv";
      link.style.display = 'none';

      // Append link to the document, trigger click to download, then remove the link
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);*/
  } catch (e) {
    console.log(e)
  }
}

defineExpose({
  exportExcel,
})
// Choose modal
const isModalUserListOpen = ref(false)
const handleModalUserListClose = () => {
  isModalUserListOpen.value = false
}
const handleModalUserListOpen = (item) => {
  isModalUserListOpen.value = true
  currentRecord.value = item
}
const setUser = async (user) => {
  if (currentRecord.value) {
    const data = {
      collection: 'Work_inspections',
      id: currentRecord.value.id,
      item: {
        assigned_to: user.id,
      },
    }
    await updateItem(data)
    isModalUserListOpen.value = false
    handleChangeKey()
    toaster.show({
      title: t('Update'),
      message: t(`Record updated successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }
}
</script>

<template>
  <div class="relative workorder_list">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12 wo-table">
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
          show-select
          :key="refreshKey"
          :item-key="'id'"
          :headers="getTableHeaders()"
          :items-length="totalItems"
          :items="serverItems"
          :loading="loading"
          :search="search"
          class="elevation-1 -z-50"
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
          <!-- <template v-slot:thead>
            <tr>
              <td>&nbsp;</td>
              <td>&nbsp;</td>
              <td>&nbsp;</td>
              <td>
                <p class="p-1">
                  <BaseSelect
                    v-model="filter_status"
                    size="sm"
                    rounded="md"
                    label=""
                    @change="handleChangeKey"
                  >
                    <option value="" selected>{{ t('All') }}</option>
                    <option
                      v-for="status in statuses"
                      :key="status.value"
                      :value="status.value"
                    >
                      {{ status.text }}
                    </option>
                  </BaseSelect>
                </p>
              </td>
            </tr>
          </template> -->

          <template v-slot:item.priority="{ item }">
            <div>
              <PriorityCell fieldName="priority" :value="item.priority" />
            </div>
          </template>
          <!-- 
          <template v-slot:item.status="{ item }">
            <PriorityCell fieldName="status" :value="item.status" />
          </template> -->

          <template v-slot:item.wo_status="{ item }">
            <PriorityCell fieldName="wo_status" :value="item.wo_status" />
          </template>

          <template v-slot:item.name="{ item }">
            <!-- <a v-bind="item" :href="'/workorder/location/'+(item.status == 1 ? 'open' : item.status == 3 ? 'completed' : 'open')+'/'+item?.asset?.location+'/view/'+item.id">
              <BaseTag v-bind="item" :key="item.id" shape="rounded" color="primary" class="mr-5" >
                  {{item.name}}
              </BaseTag>
              </a> -->

            <div v-bind="item">
              <BaseTag
                v-bind="item"
                :key="item.id"
                shape="curved"
                color="default"
                class="wo_name"
                shadow="hover"
                @click="onClick(item)"
              >
                {{ item.name }}
              </BaseTag>
            </div>
          </template>

          <template v-slot:item.created_at="{ item }">
            <p class="text-xxs">{{ item.created_at?.split('T')[0] }}</p>
          </template>

          <template v-slot:item.due="{ item }">
            <p class="text-xxs">{{ item.due?.split('T')[0] }}</p>
          </template>

          <template v-slot:item.is_accepted="{ item }">
            <div>
              <BaseCheckbox
                v-model="item.is_accepted"
                label=""
                rounded="sm"
                readonly="readonly"
              />
            </div>
          </template>

          <template v-slot:item.printed="{ item }">
            <div>
              <BaseCheckbox
                v-model="item.printed"
                label=""
                rounded="sm"
                readonly="readonly"
              />
            </div>
          </template>

          <template v-slot:item.action="{ item }">
            <div class="">
              <WorkorderDropdown
                :id="item?.id"
                :refresh="handleChangeKey"
                :item="item"
                :handleAssignTo="() => handleModalUserListOpen(item)"
              />
            </div>
          </template>
        </v-data-table-server>
        <UserList
          :open="isModalUserListOpen"
          :close="handleModalUserListClose"
          :setUser="setUser"
        />
      </div>
    </div>
  </div>
</template>

<style>
/* Or style all headers */
.wo-table {
  margin-top: 5px;
}
.workorder_list .v-data-table thead th {
  white-space: nowrap;
}

.workorder_list .v-data-table .v-data-table__td .wo_name {
  cursor: pointer;
  margin-right: 5px;
}

.workorder_list .v-data-table .v-data-table__td .nui-dropdown {
  margin-top: 0px !important;
}

.workorder_list
  .v-data-table
  .v-data-table__td
  .nui-checkbox
  .nui-checkbox-inner {
  border-width: 1px !important;
}
.workorder_list .v-data-table-footer {
  margin-top: 70px;
}
</style>
