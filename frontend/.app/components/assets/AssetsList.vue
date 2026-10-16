<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
import PicCellRenderer from '~/components/ag_grid/PictureCellRenderer.vue'

const { open, close } = usePanels()

const request = ref(null)
const { t } = useI18n({ useScope: 'global' })
const { params } = useRoute()
const { getItems, updateItem } = useDirectusItems()

const max_depth = 5

let locationId: Number = 0
let isClickNextPage = false // Хуудаслалтын товч дарагдсаныг хянах

// Modal start
import type { ColDef } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import ActionDropdownCellRenderer from '~/components/ag_grid/ActionDropdownCellRenderer.vue'
import DeletionModalForm from '~/components/form/DeletionModalForm.vue'

const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const itemsValue = ref(-1)
const key = ref(1)
const currentPage = ref(1)
const selectedCount = ref(0)

//Components
import { fetchPageData } from '~/components/ag_grid/ag_grid_directus'

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
}

const handleModalClose = () => {
  isModalOpen.value = false
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const do_edit = (item) => {
  // Perform your action here
  selectedItem.value = item.id
  itemsValue.value = item
  // console.log('do_edit', item)
  open('asset', {
    id: item.id,
    data: item,
    refresh: refreshGrid,
  })
}

const do_delete_confirm = (item) => {
  isModalConfirmOpen.value = true
  selectedItem.value = item.id
  itemsValue.value = item
}

const do_delete = async (item: any) => {
  const itemId = item?.id || selectedItem.value
  if (!itemId) return
  selectedItem.value = itemId
  await updateItem({ collection: 'Assets', id: itemId, item: { status: '0' } })
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const clearItem = () => {
  selectedItem.value = -1
}

// Grid functions
let previousStartRow = 0 // Өмнөх хуудасны эхлэх мөр
const gridApi = ref(null) // For storing ag-Grid API instance
const totalRows = ref(0) // Total rows from the backend
const paginationPageSize = ref(10) // Default page size
const pager = ref(1)
const dataSource = ref({})
const lastRow = ref(0)
const quickFilterText = ref('')
const windowHeight = ref(560)

const props = defineProps({
  gridTheme: {
    type: String,
    default: 'ag-theme-quartz',
  },
  isDarkMode: {
    type: Boolean,
  },
  location: Number,
  type: {
    type: String,
    default: 'assets',
  },
})

const themeClass = computed(
  () => `${props.gridTheme}${props.isDarkMode ? '-dark' : ''}`,
)

const gridOptions = {
  rowModelType: 'serverSide',
  paginationPageSize: 10,
  paginationPageSizeSelector: [10, 20, 30, 50, 70, 100],
  cacheBlockSize: 10,
  pagination: true,
  serverSideDatasource: dataSource.value,
  // loadingOverlayComponent: '',
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
  defaultColDef: {
    flex: 1,
  },
  autoGroupColumnDef: {
    headerName: t('Asset Code'), // Бүлэгийн гарчиг
    field: 'asset_code',
    minWidth: 300,
    sortable: false,
    cellRendererParams: {
      suppressCount: true,
    },
    onCellClicked: (params) => {
      if (params.colDef.field === 'asset_code') {
        let getInfo = false
        if (quickFilterText.value.length > 3) getInfo = true
        onRowClicked(params, getInfo)
      }
    },
    filter: 'agTextColumnFilter',
    filterParams: {
      maxNumConditions: 1,
      filterOptions: ['contains', 'equals'],
      buttons: ['reset'],
    },
  },

  treeData: true,
  groupDefaultExpanded: -1, // Бүх бүлэглэлүүдийг өргөжүүлэх
  // getDataPath: (data) => data.path,
  isServerSideGroupOpenByDefault: () => false,
  isServerSideGroup: (dataItem: any) => {
    return dataItem.children?.length > 0 ? dataItem.children : false
  },
  getServerSideGroupKey: (dataItem: any) => {
    return dataItem.id
  },
  onPaginationChanged: (params) => {
    if (gridApi.value) {
      currentPage.value = gridApi.value.paginationGetCurrentPage() // Одоогийн хуудасны индекс (0-ээс эхэлдэг)
      const currentStartRow = currentPage.value * paginationPageSize.value // Одоогийн хуудасны эхлэх мөр

      // console.log('Current Page:', currentPage.value) // Хуудасны индексийг 1-ээс эхлэхээр харуулах
      // console.log('Current Start Row:', currentStartRow)
      if (currentPage.value > 0 && currentStartRow !== previousStartRow) {
        isClickNextPage = true
        previousStartRow = currentStartRow
      }
      changePaginationSize(params.api.paginationGetPageSize())
    }
  },
}

const dateFormatter = ({ value }) => {
  const localTime = new Date(value)
  const formattedTime =
    `${localTime.getFullYear()}/` +
    `${String(localTime.getMonth() + 1).padStart(2, '0')}/` +
    `${String(localTime.getDate()).padStart(2, '0')}, ` +
    `${String(localTime.getHours()).padStart(2, '0')}:` +
    `${String(localTime.getMinutes()).padStart(2, '0')}:` +
    `${String(localTime.getSeconds()).padStart(2, '0')}`

  return formattedTime
}

const supplierFormatter = ({ value }) => {
  const supplierName = value[0]?.Supplier_id?.name || '-'
  return supplierName
}

const columnDefs: ColDef[] = ref([
  // {
  //   field: 'asset_code',
  //   headerName: 'Code',
  //   headerClass: 'header-asset_code',
  //   minWidth: 250,
  //   rowGroup: true,
  //   sortable: false,
  //   filter: false,
  //   // hide: true,
  // },
  {
    field: 'name',
    headerName: t('Name'),
    headerClass: 'header-name',
    sortable: true,
    cellClass: 'asset-name',
    filter: 'agTextColumnFilter',
    filterParams: {
      textFormatter: (text) => text.toLowerCase(),
      maxNumConditions: 1,
      filterOptions: ['contains'],
      buttons: ['reset'],
    },
  },
  {
    field: 'description',
    headerName: t('Description'),
    headerClass: 'header-description',
    sortable: false,
    filter: 'agTextColumnFilter',
    filterParams: {
      textFormatter: (text) => text.toLowerCase(),
      maxNumConditions: 1,
      filterOptions: ['contains'],
      buttons: ['reset'],
    },
  },
  {
    field: 'model_number',
    headerName: t('Model'),
    headerClass: 'header-model_number',
    sortable: false,
    filter: false,
    hide: true,
  },
  {
    field: 'asset_supplier',
    headerName: t('Supplier'),
    headerClass: 'header-asset_supplier',
    sortable: false,
    filter: false,
    valueFormatter: supplierFormatter,
    hide: true,
  },
  {
    field: 'file',
    headerName: t('Picture'),
    headerClass: 'header-picture',
    cellRenderer: PicCellRenderer,
    cellRendererParams: (params) => {
      // console.log('params', params)
    },
    // maxWidth: 150,
    width: 80,
    hide: true,
  },
  {
    field: 'user_created.first_name',
    headerName: t('Created by'),
    headerClass: 'header-user',
    sortable: false,
    hide: true,
  },
  {
    field: 'date_created',
    headerName: t('Created date'),
    headerClass: 'header-date',
    sortable: false,
    hide: true,
    filter: 'agSetColumnFilter',
    valueFormatter: dateFormatter,
  },
  {
    field: 'actions',
    headerName: t('Actions'),
    width: 120,
    sortable: false,
    filter: false,
    pinned: 'right',
    cellEditorPopup: true,
    cellRenderer: ActionDropdownCellRenderer,
    cellRendererParams: {
      onEditClick: do_edit,
      onDeleteClick: do_delete_confirm,
    },
    cellClass: 'actions-cell',
    cellStyle: {
      // 'background-color': 'green',
    },
  },
])

const loadParts = async (numberss) => {
  try {
    if (!numberss || numberss.length <= 0) return
    let filters = {
      location: locationId,
      'part.part_number': {
        _icontains: numberss,
      },
    }
    const pitems = await getItems({
      collection: 'Asset_Parts',
      params: {
        filter: {
          location: locationId,
          part: {
            part_number: {
              _icontains: numberss, // Хайлт хийх хэсэг
            },
          },
        },
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    // console.log('partrs_search', pitems)
    // ids =  pitems.data.map(part => part.id);
    let assets = pitems?.data.map((part) => part.asset)
    return assets
  } catch (e) {
    console.log('fetch err', e)
  }
}

const field_build = () => {
  let fields = []
  fields.push(
    '*',
    'asset_supplier.Supplier_id.name',
    'user_created.*',
    'file.*',
  )
  for (let i = 0; i <= max_depth; i++) {
    const joined_string = Array.from({ length: i }, () => 'children').join('.')
    if (joined_string != '')
      fields.push(
        [
          joined_string.concat('.*'),
          joined_string.concat('.asset_supplier'),
          joined_string.concat('.user_created.*'),
          joined_string.concat('.file.*'),
        ].join(','),
      )
  }
  return fields
}

const onGridReady = (params) => {
  const savedState = localStorage.getItem('assetsColumnState')
  if (savedState) {
    const state = JSON.parse(savedState)
    params.api.applyColumnState({ state: state, applyOrder: true })
  }

  // Grid api
  gridApi.value = params.api
  request.value = params.request

  dataSource.value = {
    getRows: async (params) => {
      let getchilds = true
      const { startRow, endRow, sortModel } = params.request
      const filterModel = gridApi.value.getFilterModel()
      const sortField = sortModel.length ? sortModel[0].colId : null
      const sortOrder = sortModel.length ? sortModel[0].sort : null
      gridOptions.api = params.api

      let temp_filter: any = {
        status: { _eq: '1' },
      }
      if (filterModel.name && filterModel.name.filter) {
        let type = filterModel.name.type
        if (type == 'contains')
          temp_filter['name'] = { _icontains: filterModel.name.filter }
        else if (type == 'equals') temp_filter['name'] = filterModel.name.filter
      }
      if (filterModel.description && filterModel.description.filter) {
        temp_filter['description'] = {
          _icontains: filterModel.description.filter,
        }
      }

      if (
        filterModel['ag-Grid-AutoColumn'] &&
        filterModel['ag-Grid-AutoColumn'].filter
      ) {
        let type = filterModel['ag-Grid-AutoColumn'].type
        if (type == 'contains')
          temp_filter['asset_code'] = {
            _icontains: filterModel['ag-Grid-AutoColumn'].filter,
          }
        else if (type == 'equals') {
          let lower = filterModel['ag-Grid-AutoColumn'].filter.toLowerCase()
          let upper = filterModel['ag-Grid-AutoColumn'].filter.toUpperCase()
          temp_filter['asset_code'] = {
            _in: [lower, upper],
          }
        }
      }

      if (quickFilterText.value.length > 3) {
        let assets = await loadParts(quickFilterText.value)
        temp_filter['id'] = { _in: assets }
        getchilds = false
      }

      const result = await getData(params, temp_filter, getchilds)
      const rowss = result?.data || []
      lastRow.value = result?.totalCount || 0

      console.log('result', result)

      if (rowss.length > 0) {
        mappingChildren(rowss, request, params)
        isClickNextPage = false
        gridApi.value.hideOverlay()
      } else {
        // gridApi.value.setGridOption('loading', false)
        // gridApi.value.setGridOption('rowData', [])
        params.success({ rowData: [], rowCount: 0 })
        gridApi.value.showNoRowsOverlay()
        // params.fail()
        // return
      }
    },
  }

  params.api.setGridOption('serverSideDatasource', dataSource.value)
}

async function getData(params: any, set_filter: any, get_childs: boolean) {
  let filter: any = { location: locationId }

  if (get_childs) {
    filter.parent = { _null: true }
  }

  let _fields = field_build()

  if (Object.keys(set_filter).length > 0) {
    filter = { ...filter, ...set_filter }
  }

  if (!get_childs) {
    _fields = [
      'parent.*',
      'file.*',
      'asset_type',
      'id',
      'asset_code',
      'manufacturer',
      'reading_type',
      'department',
      'description',
      'model_number',
      'safety_notes',
      'serial_number',
      'barcode',
      'available_hour',
      'Warranty_start_date',
      'warranty_finish_date',
      'Inspection_done_date',
      'Inspection_next_due_date',
      'purchase_cost',
      'location',
      'name',
      'files',
      'asset_supplier.Supplier_id.name',
    ]
  }

  try {
    return await fetchPageData({
      currentPage: currentPage.value + 1,
      pageSize: paginationPageSize.value,
      sortField: 'id',
      sortOrder: 'asc',
      filters: filter,
      collection: 'Assets',
      fields: _fields,
      deep: true,
    })
  } catch (error) {
    console.error('Error fetching Assets:', error)
    return { data: [], totalCount: 0 }
  }
}

function mappingChildren(data: any[], request: any, params: any) {
  const result = {
    rowData: data,
    lastRow: lastRow.value,
    rowCount: lastRow.value,
  }

  setTimeout(() => {
    params.success(result)
    const groupingChildren = (route: string[], node: any) => {
      if (node.children) {
        gridApi.value.applyServerSideRowData({
          route,
          successParams: {
            rowData: node.children,
            rowCount: node.children.length,
          },
        })
        node.children.forEach((child: any) => {
          groupingChildren([...route, child.id], child)
        })
      }
    }
    result.rowData.forEach((topLevelNode: any) => {
      groupingChildren([topLevelNode.id], topLevelNode)
    })
  }, 200)
}

const onFilterTextBoxChanged = ({ target: { value } }) => {
  // quickFilterText.value = value

  setTimeout(async () => {
    if (value.length > 3 || value.length == 0) {
      quickFilterText.value = value
      refreshGrid()
    }
  }, 300)
}

const saveColumnState = (params: any) => {
  const columnState = params.api.getColumnState()
  localStorage.setItem('assetsColumnState', JSON.stringify(columnState))
}

const changePaginationSize = (newSize) => {
  let save_state_pagesize = props.type + '_pagesize'
  if (newSize != paginationPageSize.value)
    localStorage.setItem(save_state_pagesize, JSON.stringify(newSize))

  if (newSize == 10) {
    windowHeight.value = 560
  } else if (newSize == 20) {
    windowHeight.value = 980
  } else if (newSize == 30) {
    windowHeight.value = 1380
  }
  paginationPageSize.value = newSize // Шинэ хуудаслалтын хэмжээг хадгалах
  gridOptions.cacheBlockSize = newSize // Шинэчилсэн cacheBlockSize
  gridOptions.paginationPageSize = newSize // Шинэ paginationPageSize

  if (gridApi.value) {
    gridApi.value.setGridOption('cacheBlockSize', newSize)
    gridApi.value.setGridOption('paginationPageSize', newSize)
    // gridApi.value.purgeServerSideCache() // Серверээс дахин дата татах
  }
}

const refreshGrid = () => {
  handleModalConfirmClose()
  close()
  itemsValue.value = -1
  selectedItem.value = -1
  gridApi.value?.refreshServerSide()
  gridApi.value?.onFilterChanged()
}

onMounted(() => {
  locationId = params?.id
})

const onRowClicked = (params, loading = false) => {
  open('asset', {
    id: params.data.id,
    data: params.data,
    // refresh: refreshGrid,
  })

  // if (params.data.parent) {
  //   console.log('Leaf node clicked:', params.data)
  // } else {
  //   console.log('Parent node clicked:', params.data)
  // }
}

function selectionChanged(event) {
  selectedCount.value = event.api.getSelectedRows().length
  const panel = document.querySelector('.ag-paging-panel')

  if (panel) {
    let selectedText = panel.querySelector('#row-selected-count')

    if (!selectedText) {
      selectedText = document.createElement('span')
      selectedText.id = 'row-selected-count'
      selectedText.style.marginLeft = '20px'
      panel.appendChild(selectedText)
    }

    selectedText.textContent = `Selected: ${selectedCount.value}`
  }

  // console.log('event', event)
  // console.log('selectedCount' + selectedCount.value)
}
</script>

<template>
  <div class="relative tabGridBody">
    <!-- table -->
    <div class="assets_list grid grid-cols-4 gap-6">
      <!-- Grid -->

      <div class="grid_ag col-span-4" :class="themeClass">
        <TairoContentWrapper>
          <template #left>
            <BaseInput
              icon="lucide:search"
              :placeholder="t('Part number')"
              :classes="{
                wrapper: 'w-[340px]',
              }"
              @input="onFilterTextBoxChanged"
            />
          </template>
        </TairoContentWrapper>
        <ag-grid-vue
          :style="{ height: '100%' }"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_tree`"
          :columnDefs="columnDefs"
          @grid-ready="onGridReady"
          :gridOptions="gridOptions"
          :quickFilterText="quickFilterText"
          :onColumnMoved="saveColumnState"
          :onColumnPinned="saveColumnState"
          :onColumnVisible="saveColumnState"
          :onColumnResized="saveColumnState"
          @sort-changed="saveColumnState"
          @selection-changed="selectionChanged"
        >
        </ag-grid-vue>
        <DeletionModalForm
          :key="selectedItem"
          code="assets"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :row="selectedItem"
          :refresh="refreshGrid"
          :clear="clearItem"
          :do_make="do_delete"
          actionType="deleted"
          :itemsValue="itemsValue"
        />
      </div>
    </div>
  </div>
</template>

<style>
.assets_list .grid_ag {
  min-height: 560px !important;
}

/* .assets_list .header-name .ag-header-cell-label {
  justify-content: center;
}
.assets_list .asset-name {
  display: flex;
  justify-content: center;
} */
.assets_list .ag-center-cols-container {
  overflow: visible;
}
.assets_list .ag-row {
  overflow: visible;
  /* position: relative; */
}
.assets_list .ag-row .actions-cell {
  overflow: visible;
}
</style>
