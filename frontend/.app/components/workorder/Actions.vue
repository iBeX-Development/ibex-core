<script setup lang="ts">
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { format } from 'date-fns'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'

import PriorityCell from '~/components/custom/priorityCell.vue'

import { active } from '~/components/workorder/WorkOrderConstants'

const user = useDirectusUser()
const { t } = useI18n({ useScope: 'global' })
const router = useRouter()

const { getItems } = useDirectusItems()

const props = defineProps({
  work_order: Object,
  loadActions: Object,
  type: String,
  collection: {
    type: String,
    default: 'Work_order_actions',
  },
})

console.log('open_wo_status', props.type)

const itemsPerPage = ref(25)
const getTableHeaders = () => {
  return [
    {
      title: t('From'),
      key: 'first_user.first_name',
      align: 'start',
      sortable: false,
    },
    {
      title: t('To'),
      key: 'next_user.first_name',
      align: 'start',
      sortable: false,
    },
    {
      title: t('Created'),
      key: 'date_created',
      align: 'start',
      sortable: false,
    },
    {
      title: t('Type'),
      key: 'type',
      align: 'start',
      sortable: false,
    },
    {
      title: t('Status'),
      key: 'action_status',
      align: 'start',
      sortable: false,
      filterable: false,
    },
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
const currentRecord = ref(null)

const gridApi = ref()
const { params } = useRoute()
const rowData = ref([])
const key = ref(1)
const emit = defineEmits(['update:loadActions'])

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    const filters = {
      wo_id: props.work_order?.id,
    }

    const items = await getItems({
      collection: props.collection,
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*', 'first_user.*', 'next_user.*'],
      },
    })

    // console.log('items_opop', items)
    serverItems.value = items.data
    totalItems.value = items.meta.filter_count
    emit('update:loadActions', items)

    loading.value = false
  } catch (e) {}
}

onMounted(async () => {
  if (props.loadActions) {
    serverItems.value = props.loadActions.data
    totalItems.value = props.loadActions.meta.filter_count

    loading.value = false
    console.log('action-loaded', props.loadActions)
  } else await loadItems(1, -1)
})
</script>

<template>
  <div class="relative action_list min-h-[450px]">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6 wo_actions">
      <div class="col-span-12 action_table">
        <v-data-table-server
          v-model:items-per-page="itemsPerPage"
          :key="refreshKey"
          :item-key="'id'"
          :headers="getTableHeaders()"
          :items-length="totalItems"
          :items="serverItems"
          :loading="loading"
          :search="search"
          class="elevation-1 -z-50 rounded"
          style="border-top: 1px solid #d5d5d5"
          :theme="$colorMode.value"
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
          <template v-slot:item.action_status="{ item }">
            <PriorityCell
              fieldName="action_status"
              :value="item.action_status"
            />
          </template>
          <template v-slot:item.date_created="{ item }">
            <p class="text-xxs">
              {{ format(new Date(item.date_created), 'yyyy-MM-dd HH:mm') }}
            </p>
          </template>
        </v-data-table-server>
      </div>
    </div>
  </div>
</template>

<style>
/* Or style all headers */
.action_table {
  border-radius: 5px;
}
.action_table .v-table {
  max-width: 100%;
}
.action_table .v-data-table__thead {
  color: gray;
}
.action_table .v-data-table {
  margin: auto;
}
.dark .action_table .v-data-table {
  border-color: #e5e7eb !important;
}
.action_table .v-table .v-table__wrapper > table > thead > tr > th {
  border-color: gray;
}
.action_list .v-data-table thead th {
  white-space: nowrap;
}
.action_list .v-data-table .v-data-table__td .nui-checkbox .nui-checkbox-inner {
  border-width: 1px !important;
}
.action_list .v-data-table-footer {
  margin-top: 70px;
}
</style>
