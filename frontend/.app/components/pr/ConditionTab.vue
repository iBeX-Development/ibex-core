<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import PredictiveConditionConfig from '~/components/pr/PredictiveConditionConfig.vue'

const { t } = useI18n({ useScope: 'global' })

const { updateItem, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

definePageMeta({
  middleware: ['auth'],
  title: 'Preview asset',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})
ModuleRegistry.registerModules([ClientSideRowModelModule, RichSelectModule])

const props = defineProps([
  'work_order',
  'location',
  'refresh',
  'clickedtab',
  'readonly',
  'freeze',
])
const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selectedRow = ref(-1)
const detailRowAutoHeight = true

const loading = ref(true)
const gridApi = ref()
const { getItems } = useDirectusItems()
const { params } = useRoute()
const rowData = ref([])
const key = ref(1)

const editRow = ref(-1)
const isModalNewOpen = ref(false)
const isModalConfirmOpen = ref(false)

const autoSizeStrategy = {
  type: 'fitGridWidth',
}

const gridOptions = ref({
  defaultColDef: {
    sortable: true,
    filter: false,
    resizable: true,
    suppressAutoSize: true,
    autoSizeAllColumns: true,
    suppressHeaderMenuButton: true,
    autoSizeStrategy: {
      type: 'fitCellContents',
    },

    // wrapHeaderText: true, // Header name багтахгүй бол багана дотор хугалж бичих
    // autoHeaderHeight: true, // Толгойн өндөр автоматаар тохирох
    flex: 0,
  },
  rowSelection: 'multiple',
  localeText: {
    noRowsToShow: t('No Rows To Show'),
    page: t('Page'),
    to: t('to'),
    of: t('of'),
    pageSizeSelectorLabel: t('Page Size:'),
    sortAscending: t('Sort Ascending'),
    sortDescending: t('Sort Descending'),
    clearColumn: t('Clear Sort'),
    pinColumn: t('Pin Column'),
    pinLeft: t('Pin Left'),
    pinRight: t('Pin Right'),
    noPin: t('No Pin'),
    autosizeThisColumn: t('Autosize This Column'),
    autosizeAllColumns: t('Autosize All Columns'),
    columnChooser: t('Choose Columns'),
    resetColumns: t('Reset Columns'),
    alertButton: t('Click Alert Button and Close Menu'),
  },
  // suppressHorizontalScroll: true, // Хэвтээ scroll идэвхгүй болгох
})

const dateFormatter = ({ value }) => {
  const localTime = new Date(value)
  const formattedTime =
    `${localTime.getFullYear()}/` +
    `${String(localTime.getMonth() + 1).padStart(2, '0')}/` +
    `${String(localTime.getDate()).padStart(2, '0')}, ` +
    `${String(localTime.getHours()).padStart(2, '0')}:` +
    `${String(localTime.getMinutes()).padStart(2, '0')}`

  return formattedTime
}
const scheduleFormatter = ({ value }) => {
  console.log('value', value)
  // return formattedTime
}
const columnDefs = ref([])

let columnDefsPublic = [
  {
    headerName: '',
    checkboxSelection: true,
    headerCheckboxSelection: true,
    filter: false,
    width: 20,
  },
  {
    headerName: t('Schedule name'),
    field: 'schedule_id.name',
    sortable: true,
    filter: true,
    editable: false,
    cellEditor: 'agRichSelectCellEditor',
  },
  {
    headerName: t('Schedule type'),
    field: 'schedule_id.repeat_types',
    sortable: true,
    filter: false,
    // editable: props.transaction_data?.status === 2 ? false : true,
    editable: false,
  },
  {
    headerName: t('Created'),
    field: 'schedule_id.date_created',
    sortable: true,
    filter: true,
    // editable: props.transaction_data?.status === 2 ? false : true,
    editable: false,
  },
  // {
  //   field: 'schedule_id.description',
  //   headerName: 'Description',
  //   headerClass: 'header-description',
  //   minWidth: 180,
  // },
]

let columnDefsPrivate = [
  {
    headerName: '',
    checkboxSelection: true,
    headerCheckboxSelection: true,
    filter: false,
    width: 20,
  },
  {
    headerName: t('Name'),
    field: 'name',
    sortable: true,
    filter: true,
    editable: false,
    cellEditor: 'agRichSelectCellEditor',
  },
  {
    headerName: t('Type'),
    field: 'repeat_types',
    sortable: true,
    filter: false,
    // editable: props.transaction_data?.status === 2 ? false : true,
    editable: false,
  },
  {
    headerName: t('Unit'),
    field: 'repeat_unit',
    sortable: true,
    filter: false,
    // editable: props.transaction_data?.status === 2 ? false : true,
    editable: false,
  },
  {
    headerName: t('Schedule'),
    field: 'schedules_date',
    sortable: true,
    filter: false,
    // editable: props.transaction_data?.status === 2 ? false : true,
    editable: false,
    valueFormatter: (params) => {
      console.log('params', params)
      if (params.data.repeat_unit == 'daily') {
        return (params.data.schedules_date || [])
          .map((s) =>
            s.hour != null && s.min != null
              ? String(s.hour).toString().padStart(2, '0') +
                ':' +
                String(s.min).toString().padStart(2, '0')
              : '----',
          )
          .join(',')
      } else if (params.data.repeat_unit == 'weekly') {
        return params.data.schedules_date
          .map((item) => {
            let day = ''
            if (item.date === 1) day = 'Monday'
            else if (item.date === 2) day = 'Tuesday'
            else if (item.date === 3) day = 'Wednesday'
            else if (item.date === 4) day = 'Thursday'
            else if (item.date === 5) day = 'Friday'
            else if (item.date === 6) day = 'Saturday'
            else if (item.date === 7) day = 'Sunday'

            return day // `return` хийх ёстой
          })
          .join(', ') // Өгөгдлийг string болгон нэгтгэх
      } else if (params.data.repeat_unit == 'monthly') {
        return (
          (params.data.schedules_date || [])
            .map((s) => (s.date ? String(s.date) : 'Unknown'))
            .join(', ') + ' days'
        )
      } else if (params.data.repeat_unit == 'yearly') {
        return params.data.schedules_date
          .map((s) =>
            s.month && s.date ? `${s.month}/${s.date}` : 'Invalid Date',
          )
          .join(', ')
      }
      // const priority = priorities.find((s) => s.value === params.value)
      // return priority ? priority.text : '' // Map numeric value to text in grid cells
    },
  },
  {
    headerName: t('Repeat'),
    field: 'repeat',
    sortable: true,
    filter: false,
    // editable: props.transaction_data?.status === 2 ? false : true,
    editable: false,
  },
  {
    headerName: t('Created'),
    field: 'date_created',
    sortable: true,
    filter: true,
    // editable: props.transaction_data?.status === 2 ? false : true,
    editable: false,
    valueFormatter: dateFormatter,
  },
]

if (props.clickedtab == 'public') columnDefs.value = columnDefsPublic
else columnDefs.value = columnDefsPrivate

const loadItems = async (page, itemsPerPage, is_schedule) => {
  loading.value = true
  try {
    // console.log('loadItems_fn', is_schedule)

    if (is_schedule == 1) {
      const updateData = {
        collection: 'Work_order',
        id: props.work_order?.id,
        item: { schedule: 1 },
      }

      updateItem(updateData).then((res) => {
        console.log('set_schedule', res)
      })
    }

    const filters = {
      status: 'Active',
      work_order: props.work_order?.id,
    }
    // console.log('filters', filters)

    const items = await getItems<any>({
      collection: 'Work_order_schedules',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*', 'schedule_id.*', 'work_order.* '],
      },
    })
    rowData.value = items.data
    console.log('items', items)

    if (is_schedule == 0 && items.meta.filter_count == 0) {
      const updateData = {
        collection: 'Work_order',
        id: props.work_order?.id,
        item: { schedule: 0 },
      }

      updateItem(updateData).then((res) => {
        console.log('no_schedule', res)
      })
    }
    loading.value = false
  } catch (e) {}
}

const onGridReady = async (grid_params) => {
  gridApi.value = grid_params.api
  grid_params.api.sizeColumnsToFit({
    defaultMinWidth: 600,
    columnLimits: [{ key: 'name', minWidth: 100 }],
  }) // Багануудыг дэлгэцэнд тааруулах

  grid_params.api.autoSizeAllColumns()

  // const datasource = createServerSideDatasource()
  // await gridApi.value.setGridOption('serverSideDatasource', datasource)
}

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
}

const addConfig = () => {
  selectedItem.value = -1
  isModalNewOpen.value = true

  console.log('addConfig', isModalNewOpen)
}

const handleModalClose = () => {
  selectedItem.value = -1
  selectedRow.value = -1
  isModalOpen.value = false
  isModalNewOpen.value = false
  editRow.value = -1

  props.refresh()
  refresh('tab')
  console.log(isModalOpen.value)
}

const setSchedule = (obj: any) => {
  let insertData: any = {
    work_order: props.work_order?.id,
    schedule_id: obj?.id,
    company_id: myCompanyId,
  }
  createItems({
    collection: 'Work_order_schedules',
    items: [insertData],
  }).then((response) => {
    console.log('create_sch', response)
    refresh('tab')
  })
}

const deleteRows = async () => {
  const sel = gridApi.value.getSelectedRows()
  if (sel && sel.length > 0) {
    const ids = sel.map((item) => item.id)
    // gridApi.value.applyTransaction({ remove: sel })
  }

  props.refresh()
}

onMounted(async () => {
  await loadItems(1, -1, 'read')
})

const refresh = (newData) => {
  loadItems(1, -1, 1)

  // gridApi.value.refreshClientSideRowModel()
  // gridApi.value.applyTransaction({ add: [newData] });
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}
</script>

<template>
  <div class="relative" style="min-height: 500px">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <div
        v-if="
          !props.freeze &&
          props.work_order?.completed_at === null &&
          props.work_order?.action_status !== 2 &&
          !props.readonly
        "
        class="col-span-12"
      >
        <BaseButton class="float-right" @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('delete condition') }}</span>
        </BaseButton>

        <!-- <BaseButton class="float-right mr-10" @click="handleModalOpen">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Schedule add') }}</span>
        </BaseButton> -->

        <BaseButton class="float-right mr-10" @click="addConfig">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Add condition') }}</span>
        </BaseButton>
      </div>
      <!-- Header -->
      <!-- <div class="col-span-12">
        <ag-grid-vue
          :key="key"
          style="width: 100%; height: 560px"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list`"
          :columnDefs="columnDefs"
          :gridOptions="gridOptions"
          :autoSizeStrategy="autoSizeStrategy"
          @grid-ready="onGridReady"
          :rowData="rowData"
        >
        </ag-grid-vue>
      </div> -->

      <!-- Predictive Maintenance Condition Configuration -->
      <div class="col-span-12 mt-4">
        <div class="border-t border-muted-200 dark:border-muted-700 pt-4">
          <PredictiveConditionConfig
            :work_order="props.work_order"
            :location="props.location || props.work_order?.location"
            :openForm="isModalNewOpen"
            @close="isModalNewOpen = false"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.Schedule .v-data-table-header__content {
  white-space: nowrap;
}
.grid_ag_list .edit_duration .ag-header-cell-text {
  color: #04a504;
}
</style>
