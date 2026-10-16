<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { format } from 'date-fns'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const { updateItem, createItems, deleteItems } = useDirectusItems()

const props = defineProps({
  open: Boolean,
  title: String,
  asset_id: Number,
  location_id: Number,
  part: Number,
  item_data: Object,
})

// console.log('part_item_data', props.item_data)
// console.log('part', props.part)

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

const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selectedRow = ref(-1)
const editPartRow = ref(-1)
const toaster = useToaster()

const parts_codes = ref([])
const do_edit = (item) => {
  // selectedItem.value = item.id
  // isModalOpen.value = true
  console.log('do_edit')
}

const do_delete = (item) => {
  // isModalConfirmOpen.value = true
  // selectedItem.value = item.id
  console.log('do_delete')
}

const columnDefs = ref([
  {
    headerName: '№',
    valueGetter: (params) => {
      return params.api.getDisplayedRowCount() - params.node.rowIndex
    },
    checkboxSelection: true,
    headerCheckboxSelection: true,
    filter: false,
    sortable: false,
    width: 10,
    cellStyle: { textAlign: 'start' },
  },
  {
    headerName: t('Asset Code'),
    field: 'work_order.asset.asset_code',
    sortable: true,
    filter: false,
    editable: false,
  },
  {
    headerName: t('Location'),
    field: 'work_order.asset.location.name',
    sortable: true,
    filter: false,
    editable: false,
  },
  {
    headerName: t('Work number'),
    field: 'work_order.wo_number',
    sortable: true,
    filter: false,
    editable: false,
  },
  {
    headerName: t('Work name'),
    field: 'work_order.name',
    sortable: true,
    filter: true,
    editable: false,
  },
  {
    headerName: t('Work started'),
    field: 'work_order.started_at',
    sortable: true,
    filter: true,
    editable: false,
    valueGetter: (params) => {
      if (params.data?.work_order?.started_at) {
        const date = new Date(params.data.work_order.started_at)
        return format(date, 'yyyy-MM-dd HH:mm') // Format the date
      } else {
        return ''
      }
    },
  },
  {
    headerName: t('Quantity'),
    field: 'quantity',
    sortable: true,
    filter: false,
    editable: false,
  },
])

const loading = ref(true)
const gridApi = ref()
const { getItems } = useDirectusItems()
const { params } = useRoute()
const rowData = ref([])
const key = ref(1)

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    const filters = {
      parts: props.part,
    }

    const items = await getItems<any>({
      collection: 'Work_order_Parts',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: '-work_order.started_at',
        meta: 'filter_count',
        fields: [
          '*',
          'part.*',
          'work_order.asset.*',
          'work_order.asset.location.*',
          'work_order.*',
        ],
      },
    })
    rowData.value = items.data
    console.log('Asset', items)
    loading.value = false
  } catch (e) {}
}

const onGridReady = async (grid_params) => {
  gridApi.value = params.api
  gridOptions.api = params.api
  // const datasource = createServerSideDatasource()
  // await gridApi.value.setGridOption('serverSideDatasource', datasource)
}

const gridOptions = ref({
  defaultColDef: {
    sortable: true,
    filter: true,
    resizable: true,
    flex: 1,
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
})
const getRowNodeId = (data) => {
  return data.id
}

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
}

const handleModalClose = () => {
  isModalOpen.value = false
  selectedItem.value = -1
  selectedRow.value = -1
  editPartRow.value = -1
  console.log(isModalOpen.value)
}

onMounted(async () => {
  await loadItems(1, -1)
})

const getDefaultRow = () => {
  return parts_codes.value
    ? parts_codes.value[0]
    : { id: null, name: '', price: 0, amount: 0 }
}

const refreshGrid = async () => {
  console.log('refreshGrid')
  // gridApi.value.refreshServerSide()
  // gridApi.value.onFilterChanged()
  // gridApi.value.refreshInfiniteCache()
  await loadItems(1, -1)
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6 part_ag">
      <!-- Header -->
      <div class="col-span-12">
        <ag-grid-vue
          :key="key"
          style="width: 100%; height: 560px"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list`"
          :columnDefs="columnDefs"
          :gridOptions="gridOptions"
          @grid-ready="onGridReady"
          :rowData="rowData"
        >
        </ag-grid-vue>
      </div>
    </div>
  </div>
</template>
<style>
.part_ag .grid_ag {
  min-height: 560px !important;
}
.part_ag .ag-center-cols-container {
  overflow: visible;
}
.part_ag .ag-row {
  overflow: visible;
  /* position: relative; */
}
.part_ag .ag-row .actions-cell {
  overflow: visible;
}
</style>
