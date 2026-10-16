<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const { getItems: getStates } = useDirectusItems()

const loading = ref(true)
const gridApi = ref()
const { params } = useRoute()
const rowData = ref([])
const key = ref(1)
const stateMap = ref<Record<string, string>>({})

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
const dayFormatter = ({ value }) => {
  const localTime = new Date(value)
  const formattedTime =
    `${localTime.getFullYear()}/` +
    `${String(localTime.getMonth() + 1).padStart(2, '0')}/` +
    `${String(localTime.getDate()).padStart(2, '0')}`

  return formattedTime
}

const formatDate = (val: any) => {
  if (!val) return '—'
  const d = new Date(val)
  return (
    `${d.getFullYear()}/${String(d.getMonth() + 1).padStart(2, '0')}/${String(
      d.getDate(),
    ).padStart(2, '0')} ` +
    `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(
      2,
      '0',
    )}`
  )
}

const columnDefs = ref([
  {
    headerName: '',
    checkboxSelection: true,
    headerCheckboxSelection: true,
    filter: false,
    sortable: false,
    width: 40,
  },
  {
    headerName: '№',
    valueGetter: (params) => {
      return params.api.getDisplayedRowCount() - params.node.rowIndex
    },
    filter: false,
    sortable: false,
    width: 70,
    cellStyle: { textAlign: 'center' },
  },
  {
    headerName: t('Debt'),
    field: 'transaction_id.auto_number',
    sortable: true,
    filter: false,
    editable: false,
    resizable: true,
    // maxWidth: 120,
  },
  {
    headerName: t('Location'),
    field: 'transaction_id.location.name',
    sortable: true,
    filter: false,
    editable: false,
    // maxWidth: 150,
    resizable: true,
  },
  {
    headerName: t('Income name'),
    field: 'transaction_id.name',
    sortable: true,
    filter: false,
    editable: false,
    valueGetter: (params: any) =>
      params.node.rowPinned ? 'Нийт' : params.data?.transaction_id?.name,
    cellStyle: (params: any) =>
      params.node.rowPinned ? { fontWeight: 700 } : null,
  },
  {
    headerName: t('Work order'),
    field: 'transaction_id.work_order.name',
    headerClass: 'header-supplier',
    // maxWidth: 150,
    resizable: true,
  },
  {
    headerName: t('Quantity'),
    field: 'qty',
    sortable: true,
    filter: false,
    editable: false,
    resizable: true,
    // maxWidth: 120,
    cellStyle: (params: any) =>
      params.node.rowPinned ? { fontWeight: 700 } : null,
  },
  {
    headerName: t('State'),
    field: 'part_state',
    headerClass: 'header-state',
    // maxWidth: 150,
    resizable: true,
    valueFormatter: (params) => {
      if (!params.value) return '—'
      return stateMap.value[String(params.value)] ?? params.value
    },
  },
  {
    headerName: t('Price'),
    field: 'price',
    headerClass: 'header-Price',
    // maxWidth: 140,
    resizable: true,
    valueFormatter: (params: any) => {
      if (params.node.rowPinned) {
        return Number(params.value || 0).toLocaleString()
      }
      return params.value
    },
    cellStyle: (params: any) =>
      params.node.rowPinned ? { fontWeight: 700 } : null,
  },
  {
    field: 'transaction_id.assign_user.first_name',
    headerName: t('Assigned'),
    headerClass: 'header-assign',
    // maxWidth: 150,
    resizable: true,
  },
  {
    field: 'transaction_id.approved_user.first_name',
    headerName: t('Approved'),
    headerClass: 'header-assign',
    // maxWidth: 150,
    resizable: true,
  },
  {
    field: 'transaction_id.approved_user.first_name',
    headerName: t('Approved'),
    headerClass: 'header-assign',
    // maxWidth: 150,
    resizable: true,
  },
  {
    field: 'transaction_id.user_created.first_name',
    headerName: t('User Created'),
    headerClass: 'header-assign',
    // maxWidth: 150,
    resizable: true,
  },
  {
    field: 'transaction_id.date_created',
    headerName: t('Created date'),
    headerClass: 'header-transaction-date',
    width: 180,
    maxWidth: 280,
    resizable: true,
    valueFormatter: (params: any) => {
      if (!params.value) return '—'
      return formatDate(params.value)
    },
    // cellStyle: { fontSize: '11px' },
    // filter: 'agDateColumnFilter',
    // filterParams: filterDateParams,
  },
])

// Footer total row (total quantity & total amount = qty * price)
const pinnedBottomRow = computed(() => {
  const totalQty = rowData.value.reduce(
    (s: number, r: any) => s + (Number(r.qty) || 0),
    0,
  )
  const totalAmount = rowData.value.reduce(
    (s: number, r: any) => s + (Number(r.qty) || 0) * (Number(r.price) || 0),
    0,
  )
  return [
    {
      _total: true,
      qty: totalQty,
      price: totalAmount,
    },
  ]
})

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    const filters = {
      part: props.part,
      transaction_id: { location: params.id, status: 2 },
      transaction_type: 'outcome',
    }

    console.log('filters', filters)
    const items = await getItems<any>({
      collection: 'Transaction_parts',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: [
          '*',
          'part.*',
          'transaction_id.* ',
          'transaction_id.location.*',
          'transaction_id.supplier.*',
          'transaction_id.work_order.*',
          'transaction_id.user_created.*',
          'transaction_id.assign_user.*',
          'transaction_id.approved_user.*',
        ],
      },
    })

    console.log('items', items)

    const list = items.data ?? []
    rowData.value = [...list].sort((a: any, b: any) => {
      const da = new Date(a?.transaction_id?.date_created ?? 0).getTime()
      const db = new Date(b?.transaction_id?.date_created ?? 0).getTime()
      if (db !== da) return db - da
      return (b?.transaction_id?.id ?? 0) - (a?.transaction_id?.id ?? 0)
    })
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
  domLayout: 'autoHeight',
  defaultColDef: {
    sortable: true,
    filter: true,
    resizable: true,
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
  const statesRes = await getStates({
    collection: 'States',
    params: {
      filter: { company_id: { _eq: myCompanyId } },
      fields: ['id', 'name'],
      limit: -1,
    },
  })
  const statesList = Array.isArray(statesRes)
    ? statesRes
    : (statesRes as any)?.data ?? []
  statesList.forEach((s: any) => {
    stateMap.value[String(s.id)] = s.name
  })

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
          style="width: 100%"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list`"
          :columnDefs="columnDefs"
          :gridOptions="gridOptions"
          @grid-ready="onGridReady"
          :rowData="rowData"
          :pinnedBottomRowData="pinnedBottomRow"
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
