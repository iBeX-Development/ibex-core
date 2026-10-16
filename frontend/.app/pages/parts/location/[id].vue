<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import PicCellRenderer from '~/components/ag_grid/PictureCellRenderer.vue'
import SetBinLocationModal from '~/components/parts/SetBinLocationModal.vue'
import ShiftLocationModal from '~/components/parts/ShiftLocationModal.vue'

import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
const { updateItem, createItems, deleteItems } = useDirectusItems()
const { token } = useDirectusToken()
const myCompanyId = getMyCompanyId()
const runtimeConfig = useRuntimeConfig()
const { open } = usePanels()

definePageMeta({
  middleware: ['auth'],
  title: 'Warehouse',
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
ModuleRegistry.registerModules([ClientSideRowModelModule, RichSelectModule])

const parts_codes = ref([])

const columnDefs = ref([
  {
    headerName: '',
    field: 'checkboxSelection',
    headerCheckboxSelection: false,
    checkboxSelection: true,
    width: 45,
    pinned: 'left',
    lockPosition: true,
    suppressMenu: false,
    suppressMovable: true,
    sortable: false,
    filter: false,
    resizable: false,
    cellClass: 'ag-cell-center',
    headerClass: 'ag-header-center',
    headerComponent: 'agColumnHeader',
    headerComponentParams: {
      template:
        '<div class="ag-cell-label-container" role="presentation">' +
        '  <div ref="eLabel" class="ag-header-cell-label" role="presentation">' +
        '    <input type="checkbox" id="wo-header-checkbox" style="cursor:pointer;width:14px;height:14px;" />' +
        '  </div>' +
        '</div>',
    },
  },
  {
    headerName: t('Part number'),
    field: 'part.part_number',
    sortable: true,
    filter: false,
    resizable: true,
    editable: false,
    onCellClicked: (params) => {
      if (!params.value) return
      // Утгыг clipboard руу хуулна
      navigator.clipboard
        .writeText(params.value)
        .then(() => {
          console.log('Copied:', params.value)
        })
        .catch((err) => console.error('Failed to copy:', err))
    },
    onCellClicked: (params) => {
      onRowClicked(params)
    },
  },
  {
    headerName: t('Description'),
    field: 'part.description',
    sortable: true,
    filter: true,
    resizable: true,
    editable: false,
    minWidth: 220,
    // cellEditor: 'agRichSelectCellEditor',
    // cellEditorParams: (params) => {
    //   // Extract the values (display text) from the options
    //   return {
    //     values: parts_codes.value.map((opt) => opt.name),
    //   }
    // },
    // onCellValueChanged: (params) => {
    //   console.log(params.newValue)
    //   const selectedOption = parts_codes.value.find(
    //     (opt) => opt.name === params.newValue,
    //   )
    //   if (selectedOption) {
    //     const updateData = params.data
    //     updateData.price = selectedOption?.price
    //     updateData.part.id = selectedOption?.id
    //     updateData.amount = selectedOption?.price * params.data.quantity
    //     asyncUpdateRow(params.data)
    //     params.node.setDataValue('price', selectedOption?.price)
    //     return params.node.setDataValue('amount', updateData.amount)
    //   }
    // },
  },
  {
    headerName: t('Asset'),
    field: 'asset_amount',
    sortable: true,
    filter: false,
    // Asset_Parts-аас live тооцдог болсон тул гараар засварлахгүй
    editable: false,
    // maxWidth: 140,
    cellClass: 'asset_amount counts',
    cellStyle: {
      color: '#5f5b5b',
    },
  },
  {
    headerName: t('Income'),
    field: 'income_amount',
    sortable: true,
    filter: true,
    editable: false,
    // maxWidth: 140,
    cellClass: 'income_amount counts',
    // income_amount нь Transaction_parts-аас live тооцсон "цэвэр" орлого тул
    // shift-ийг дахин хасах шаардлагагүй (live тооцоолол нь shift-ийг огт
    // оруулаагүй байгаа)
    cellStyle: {
      color: '#54b5a6',
    },
    valueGetter: (params: any) => Number(params.data?.income_amount) || 0,
  },
  {
    headerName: t('Debt'),
    field: 'outcome_amount',
    sortable: true,
    filter: true,
    editable: false,
    // maxWidth: 140,
    cellClass: 'outcome_amount counts',
    cellStyle: {
      color: '#e24f62',
    },
    valueGetter: (params: any) => Number(params.data?.outcome_amount) || 0,
  },
  {
    headerName: t('Shift'),
    field: 'shift_amount',
    sortable: true,
    filter: true,
    editable: false,
    // maxWidth: 140,
    cellClass: 'shift_amount counts',
    cellStyle: (params: any) => ({
      color:
        (params.value ?? 0) > 0
          ? '#54b5a6'
          : (params.value ?? 0) < 0
          ? '#e24f62'
          : '#888',
    }),
    valueFormatter: (params: any) => {
      const v = Number(params.value) || 0
      return v > 0 ? `+${v}` : `${v}`
    },
  },
  // {
  //   headerName: 'Outcome',
  //   field: 'outcome_amount',
  //   sortable: true,
  //   filter: true,
  //   editable: false,
  //   maxWidth: 140,
  //   cellClass: 'outcome_amount counts',
  //   cellStyle: {
  //     color: '#e24f62',
  //   },
  // },
  {
    headerName: t('Stock'),
    valueGetter: (params) => {
      // income_amount/outcome_amount нь live тооцсон "цэвэр" (shift-гүй) утга
      // тул нийт бодит үлдэгдэлд shift_in/shift_out-ыг буцааж нэмнэ
      const income =
        (params.data?.income_amount || 0) + (params.data?.shift_in || 0)
      const outcome =
        (params.data?.outcome_amount || 0) + (params.data?.shift_out || 0)
      return income - outcome
    },
    sortable: true,
    filter: true,
    editable: false,
    cellClass: 'stock_amount counts',
    cellStyle: {
      color: '#51aacf',
    },
  },
  {
    headerName: t('Binned'),
    field: 'binned_amount',
    sortable: true,
    filter: false,
    editable: false,
    // maxWidth: 140,
    cellClass: 'binned_amount counts',
    cellStyle: (params: any) => ({
      color: params.value > 0 ? '#8b5cf6' : '#aaa',
    }),
    valueFormatter: (params: any) =>
      params.value != null ? String(params.value) : '0',
  },
  {
    field: 'min_amount',
    headerName: t('Min'),
    headerClass: 'header-class',
    // maxWidth: 120,
    editable: true,
    onCellValueChanged: (params) => {
      console.log(params)
      const updateData = params.data
      updateData.min_amount = params.newValue
      asyncUpdateCount(params.data)
    },
    cellStyle: (params: any) => ({
      color: params.value > 0 ? 'blue' : '#aaa',
    }),
  },
  {
    field: 'max_amount',
    headerName: t('Max'),
    headerClass: 'header-class',
    // maxWidth: 120,
    editable: true,
    onCellValueChanged: (params) => {
      console.log(params)
      const updateData = params.data
      updateData.max_amount = params.newValue
      asyncUpdateCount(params.data)
    },
    cellStyle: (params: any) => ({
      color: params.value > 0 ? 'green' : '#aaa',
    }),
  },
  {
    field: 'picture',
    headerName: t('Picture'),
    headerClass: 'header-picture',
    cellRenderer: PicCellRenderer,
    cellRendererParams: (params) => {
      // console.log('cellRendererParams', params)
    },
    // maxWidth: 150,
    width: 150,
    resizable: true,
    hide: true,
  },

  {
    field: 'part.mongolian_name',
    headerName: t('Mongolian Name'),
    headerClass: 'header-name-mn',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'part.model_no',
    headerName: t('Model No'),
    headerClass: 'header-model',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'part.serial_no',
    headerName: t('Serial No'),
    headerClass: 'header-serial',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'part.material',
    headerName: t('Material'),
    headerClass: 'header-material',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'part.technical_data',
    headerName: t('Technical Data'),
    headerClass: 'header-technical',
    minWidth: 200,
    hide: true,
  },
  {
    field: 'part.special_information',
    headerName: t('Special Info'),
    headerClass: 'header-special',
    minWidth: 200,
    hide: true,
  },
  {
    field: 'user_created.first_name',
    headerName: t('Created by'),
    headerClass: 'header-user',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'date_created',
    headerName: t('Created date'),
    headerClass: 'header-date',
    minWidth: 120,
    hide: true,
  },
  // {
  //   field: 'segment.description',
  //   headerName: 'Segment',
  //   headerClass: 'header-segment',
  //   minWidth: 120,
  // },
  // {
  //   field: 'family.description',
  //   headerName: 'Family',
  //   headerClass: 'header-family',
  //   minWidth: 120,
  // },
])

const loading = ref(true)
const gridApi = ref()
const { getItems } = useDirectusItems()
const { params } = useRoute()
const rowData = ref([])
const key = ref(1)
const totalItems = ref(0)
const selectedCount = ref(0)
const quickFilterText = ref('')

let parts_items_all = []
const partIds = new Set() // Use a Set to avoid duplicate IDs

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    const filters = {
      location: params.id,
      company_id: myCompanyId,
    }
    const items = await getItems<any>({
      collection: 'Parts_Amounts',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        search: quickFilterText.value,
        searchField: 'part.part_number',
        meta: 'filter_count',
        fields: ['*', 'part.*', 'part.picture.*', 'location.*'],
      },
    })

    rowData.value = items.data
    totalItems.value = items.meta?.filter_count ?? items.data.length
    console.log('rowData', rowData)

    // Load Parts_Bin_location qty per part for this location
    try {
      const partIds = items.data.map((r: any) => r.part?.id).filter(Boolean)
      if (partIds.length) {
        const binRes = await getItems<any>({
          collection: 'Parts_Bin_location',
          params: {
            filter: {
              part: { _in: partIds },
              location: { _eq: params.id },
              status: { _neq: 'archived' },
            },
            fields: ['part', 'qty'],
            limit: -1,
          },
        })
        const binList = Array.isArray(binRes) ? binRes : binRes?.data ?? []
        const binMap: Record<number, number> = {}
        for (const b of binList) {
          const pid = typeof b.part === 'object' ? b.part?.id : b.part
          binMap[pid] = (binMap[pid] ?? 0) + (parseInt(b.qty) || 0)
        }
        rowData.value = items.data.map((r: any) => ({
          ...r,
          binned_amount: binMap[r.part?.id] ?? 0,
        }))
      }
    } catch (e) {
      console.warn('Failed to load bin amounts:', e)
    }

    // Load Parts_shift_history to split outcome into debt & shift per part
    try {
      const partIds = items.data.map((r: any) => r.part?.id).filter(Boolean)
      const shiftInMap: Record<number, number> = {}
      const shiftOutMap: Record<number, number> = {}
      if (partIds.length) {
        const shiftRes = await getItems<any>({
          collection: 'Parts_shift_history',
          params: {
            filter: {
              company_id: { _eq: myCompanyId },
              part: { _in: partIds },
              _or: [
                { from_location: { _eq: params.id } },
                { to_location: { _eq: params.id } },
              ],
            },
            fields: ['part', 'qty', 'from_location', 'to_location'],
            limit: -1,
          },
        })
        const shiftList = Array.isArray(shiftRes)
          ? shiftRes
          : shiftRes?.data ?? []
        for (const sh of shiftList) {
          const pid = typeof sh.part === 'object' ? sh.part?.id : sh.part
          const qty = parseInt(sh.qty) || 0
          const toId =
            typeof sh.to_location === 'object'
              ? sh.to_location?.id
              : sh.to_location
          const fromId =
            typeof sh.from_location === 'object'
              ? sh.from_location?.id
              : sh.from_location
          if (String(toId) === String(params.id))
            shiftInMap[pid] = (shiftInMap[pid] ?? 0) + qty
          if (String(fromId) === String(params.id))
            shiftOutMap[pid] = (shiftOutMap[pid] ?? 0) + qty
        }
      }
      rowData.value = rowData.value.map((r: any) => {
        const pid = r.part?.id
        const shiftIn = shiftInMap[pid] ?? 0
        const shiftOut = shiftOutMap[pid] ?? 0
        return {
          ...r,
          shift_in: shiftIn,
          shift_out: shiftOut,
          shift_amount: shiftIn - shiftOut,
        }
      })
    } catch (e) {
      console.warn('Failed to load shift amounts:', e)
    }

    // Income/Debt/Asset-ийг Parts_Amounts-ийн cache-аас биш, эх сурвалжаас нь
    // (батлагдсан Transaction_parts, Asset_Parts) тухай бүрд шинээр тооцно —
    // ингэснээр edit/delete/approve дараалал алгасагдсан ч дата хэзээ ч
    // алдаатай (out of sync) болохгүй.
    try {
      const partIds = items.data.map((r: any) => r.part?.id).filter(Boolean)
      if (partIds.length) {
        const [tpRes, assetRes] = await Promise.all([
          getItems<any>({
            collection: 'Transaction_parts',
            params: {
              filter: {
                company_id: { _eq: myCompanyId },
                part: { _in: partIds },
                transaction_id: {
                  location: { _eq: params.id },
                  status: { _eq: 2 },
                },
              },
              fields: ['part', 'qty', 'transaction_type'],
              limit: -1,
            },
          }),
          getItems<any>({
            collection: 'Asset_Parts',
            params: {
              filter: {
                company_id: { _eq: myCompanyId },
                part: { _in: partIds },
                location: { _eq: params.id },
              },
              fields: ['part', 'quantity'],
              limit: -1,
            },
          }),
        ])

        const tpList = Array.isArray(tpRes) ? tpRes : tpRes?.data ?? []
        const incomeMap: Record<number, number> = {}
        const outcomeMap: Record<number, number> = {}
        for (const tp of tpList) {
          const pid = typeof tp.part === 'object' ? tp.part?.id : tp.part
          const qty = parseInt(tp.qty) || 0
          const isIncome =
            tp.transaction_type === 'income' || tp.transaction_type === 'INCOME'
          if (isIncome) incomeMap[pid] = (incomeMap[pid] ?? 0) + qty
          else outcomeMap[pid] = (outcomeMap[pid] ?? 0) + qty
        }

        const assetList = Array.isArray(assetRes)
          ? assetRes
          : assetRes?.data ?? []
        const assetMap: Record<number, number> = {}
        for (const ap of assetList) {
          const pid = typeof ap.part === 'object' ? ap.part?.id : ap.part
          assetMap[pid] = (assetMap[pid] ?? 0) + (parseInt(ap.quantity) || 0)
        }

        rowData.value = rowData.value.map((r: any) => {
          const pid = r.part?.id
          return {
            ...r,
            income_amount: incomeMap[pid] ?? 0,
            outcome_amount: outcomeMap[pid] ?? 0,
            asset_amount: assetMap[pid] ?? 0,
          }
        })
      }
    } catch (e) {
      console.warn('Failed to load live income/outcome/asset amounts:', e)
    }

    loading.value = false
  } catch (e) {}
}

const loadParts = async ({ page, itemsPerPage }) => {
  try {
    const filters = {
      status: '1',
    }
    const items = await getItems<any>({
      collection: 'Parts',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    parts_codes.value = items.data
  } catch (e) {}
}

const onGridReady = async (grid_params: any) => {
  gridApi.value = grid_params.api
  const savedState = localStorage.getItem('locationwareHouseColumnState')
  if (savedState) {
    const state = JSON.parse(savedState)
    grid_params.api.applyColumnState({ state: state, applyOrder: true })
  } else {
    // Хэрэглэгч хараахан баганын өргөнийг өөрчлөөгүй анхны удаад л
    // дэлгэц дүүргэж тохируулна — эс тэгвэл хадгалсан өргөнийг дарж бичнэ
    grid_params.api.sizeColumnsToFit()
  }
}

const saveColumnState = (params: any) => {
  console.log(params)
  const columnState = params.api.getColumnState()
  localStorage.setItem(
    'locationwareHouseColumnState',
    JSON.stringify(columnState),
  )
}

const gridOptions = {
  defaultColDef: {
    sortable: true,
    filter: true,
    resizable: true,
  },
  rowSelection: 'multiple' as const,
  pagination: true,
  paginationPageSize: 25,
  paginationPageSizeSelector: [10, 25, 50, 100],
  animateRows: false,
  onGridSizeChanged: (params: any) => {
    // Хэрэглэгч аль хэдийн баганын өргөнийг гараар тохируулсан бол цонхны
    // хэмжээ өөрчлөгдөх бүрд түүнийг дахин дарж бичихгүй
    const savedState = localStorage.getItem('locationwareHouseColumnState')
    if (!savedState) params.api.sizeColumnsToFit()
  },
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
}

const selectionChanged = (event: any) => {
  const api = event.api
  const pageSize = api.paginationGetPageSize()
  const currentPage = api.paginationGetCurrentPage()
  const start = currentPage * pageSize
  const end = Math.min(start + pageSize, api.getDisplayedRowCount())
  let count = 0
  for (let i = start; i < end; i++) {
    if (api.getDisplayedRowAtIndex(i)?.isSelected()) count++
  }
  selectedCount.value = count
  const total = end - start
  const cb = document.querySelector(
    '#wo-header-checkbox',
  ) as HTMLInputElement | null
  if (cb) {
    cb.checked = count > 0 && count === total
    cb.indeterminate = count > 0 && count < total
  }
}

const getRowNodeId = (data) => {
  return data.id
}

const asyncUpdateRow = async (data) => {
  console.log('Update data ds: ', data)
}

const asyncUpdateCount = async (data) => {
  console.log('Update data : ', data)
  if (data && data.id) {
    const updateData = {
      collection: 'Parts_Amounts',
      id: data.id,
      item: {
        min_amount: data.min_amount,
        max_amount: data.max_amount,
      },
    }
    updateItem(updateData)
  }
}

const asyncInsertRow = async (data) => {
  const insertData = data
  insertData.location = params.id
  insertData.part = getDefaultRow()?.id
  // Asset_Parts create
  createItems({
    collection: 'Asset_Parts',
    items: [{ ...insertData, company_id: myCompanyId }],
  }).then((response) => {
    const rowDataOverride = response[0]
    rowDataOverride.part = {
      id: response[0].part,
      name: parts_codes.value.find((opt) => opt.id === response[0].part).name,
      price: parts_codes.value.find((opt) => opt.id === response[0].part).price,
    }
    rowDataOverride.location = {
      id: response[0].location,
    }
    console.log(gridApi.value)
    gridApi.value.applyTransactionAsync({ add: [rowDataOverride] })
  })
}
const addEmptyRow = async () => {
  const defaultRow = {
    'part.name': getDefaultRow()?.name,
    'location.id': params.id,
    quantity: 0.0,
    min_quantity: 0.0,
    max_quantity: 0.0,
    price: getDefaultRow()?.price,
    amount: 0.0,
  } // Customize the default values
  try {
    // Insert the row into the database asynchronously
    await asyncInsertRow(defaultRow)
  } catch (error) {
    console.error('Error adding new row:', error)
  }
}

const deleteRows = async () => {
  const sel = gridApi.value.getSelectedRows()
  if (sel && sel.length > 0) {
    const ids = sel.map((item) => item.id)
    gridApi.value.applyTransaction({ remove: sel })
    deleteItems({
      collection: 'Asset_Parts',
      items: ids,
    })
  }
}

const isBinModalOpen = ref(false)
const selectedRowsForBin = ref([])

const isShiftModalOpen = ref(false)
const selectedRowsForShift = ref([])

const setBinLocation = () => {
  const sel = gridApi.value?.getSelectedRows() ?? []
  if (!sel.length) {
    useToaster().show({
      title: t('Warning'),
      message: t('Please select at least one row'),
      color: 'warning',
      icon: 'ph:warning-circle',
      closable: true,
    })
    return
  }
  selectedRowsForBin.value = sel
  isBinModalOpen.value = true
}

const closeBinModal = () => {
  isBinModalOpen.value = false
}

const shiftLocation = () => {
  const sel = gridApi.value?.getSelectedRows() ?? []
  if (!sel.length) {
    useToaster().show({
      title: t('Warning'),
      message: t('Please select at least one row'),
      color: 'warning',
      icon: 'ph:warning-circle',
      closable: true,
    })
    return
  }
  selectedRowsForShift.value = sel
  isShiftModalOpen.value = true
}

const closeShiftModal = () => {
  isShiftModalOpen.value = false
}
onMounted(async () => {
  await loadItems({ page: 1, itemsPerPage: -1 })

  // Header checkbox: event delegation — works regardless of when ag-grid renders the custom header
  document.addEventListener('change', (e) => {
    const target = e.target as HTMLInputElement
    if (target?.id !== 'wo-header-checkbox' || !gridApi.value) return
    const api = gridApi.value
    const pageSize = api.paginationGetPageSize()
    const currentPage = api.paginationGetCurrentPage()
    const start = currentPage * pageSize
    const end = Math.min(start + pageSize, api.getDisplayedRowCount())
    for (let i = start; i < end; i++) {
      const node = api.getDisplayedRowAtIndex(i)
      if (node) node.setSelected(target.checked)
    }
  })
})

const getDefaultRow = () => {
  return parts_codes.value
    ? parts_codes.value[0]
    : { id: null, name: '', price: 0, amount: 0 }
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const onFilterTextBoxChanged = ({
  target: { value },
}: ChangeEvent<HTMLInputElement>) => {
  quickFilterText.value = value
  refreshGrid()
}

const refreshGrid = () => {
  if (gridApi.value) {
    gridApi.value.setFilterModel(null)
    gridApi.value.onFilterChanged()
  }
}

const onRowClicked = (params) => {
  console.log('DemoTransactionMore:', params.data)

  open('transaction', {
    id: params.data.part.id,
    data: params.data.part,
    module: 'parts',
    // refresh: refreshGrid(),
  })
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12 h-[40px]">
        <!-- <BaseButton class="mr-4" @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts delete') }}</span>
        </BaseButton> -->
        <BaseButton class="mr-4" @click="setBinLocation">
          <Icon name="fluent:board-split-16-filled" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Set Bin Location') }}</span>
        </BaseButton>

        <BaseButton class="mr-4" @click="shiftLocation">
          <Icon name="octicon:arrow-right-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Shift Location') }}</span>
        </BaseButton>

        <!-- <BaseButton class="mr-4" @click="addEmptyRow">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts add') }}</span>
        </BaseButton> -->
      </div>

      <!-- GridBody -->
      <div class="col-span-12 GridBody">
        <TairoContentWrapper>
          <template #left>
            <BaseInput
              icon="lucide:search"
              :placeholder="$t('Part number')"
              :classes="{
                wrapper: 'w-[340px]',
              }"
              @input="onFilterTextBoxChanged"
            />
          </template>
        </TairoContentWrapper>
        <ag-grid-vue
          :key="key"
          style="width: 100%; height: 560px"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list pars_section`"
          :columnDefs="columnDefs"
          :gridOptions="gridOptions"
          @grid-ready="onGridReady"
          :quickFilterText="quickFilterText"
          :rowData="rowData"
          :onColumnMoved="saveColumnState"
          :onColumnPinned="saveColumnState"
          :onColumnVisible="saveColumnState"
          :onColumnResized="saveColumnState"
          @selection-changed="selectionChanged"
        >
        </ag-grid-vue>
        <!-- Footer -->
        <div
          class="flex items-center justify-between border-t border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-4 py-2"
        >
          <div class="flex items-center gap-3">
            <span class="text-xs text-muted-500 dark:text-muted-400">
              {{ $t('Total') }}:
              <span class="font-semibold text-muted-800 dark:text-muted-200">{{
                totalItems
              }}</span>
            </span>
            <span
              v-if="selectedCount > 0"
              class="flex items-center gap-1 text-xs font-semibold text-primary-600 dark:text-primary-400"
            >
              <Icon name="ph:check-square-fill" class="h-3.5 w-3.5" />
              {{ selectedCount }} {{ $t('selected') }}
            </span>
          </div>
          <span
            v-if="loading"
            class="flex items-center gap-1 text-xs text-muted-400"
          >
            <Icon name="mdi:loading" class="h-3.5 w-3.5 animate-spin" />
            {{ $t('Loading') }}...
          </span>
        </div>

        <!-- Shift Location Modal -->
        <ShiftLocationModal
          :open="isShiftModalOpen"
          :close="closeShiftModal"
          :selected-rows="selectedRowsForShift"
          :current-location-id="params.id"
          :refresh="() => loadItems({ page: 1, itemsPerPage: -1 })"
        />

        <!-- Set Bin Location Modal -->
        <SetBinLocationModal
          :open="isBinModalOpen"
          :close="closeBinModal"
          :selected-rows="selectedRowsForBin"
          :locationId="params.id"
          :refresh="() => loadItems({ page: 1, itemsPerPage: -1 })"
        />
      </div>
    </div>
  </div>
</template>

<style>
.pars_section .counts {
  font-weight: 500;
}
.pars_section .ag-header-center {
  width: 45px !important;
}
/* Pinned checkbox баганын хажуугийн босоо зураасыг арилгах */
.pars_section .ag-pinned-left-header,
.pars_section .ag-pinned-left-cols-container,
.pars_section .ag-cell-last-left-pinned {
  border-right: none !important;
}
</style>
