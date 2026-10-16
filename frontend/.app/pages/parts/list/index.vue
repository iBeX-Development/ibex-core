<script setup lang="ts">
import { ref } from 'vue'
import { fetchPageData } from '~/components/ag_grid/ag_grid_directus'
import PicCellRenderer from '~/components/ag_grid/PictureCellRenderer.vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })

const { createItems, updateItem } = useDirectusItems()
const toaster = useToaster()
const myCompanyId = getMyCompanyId()

definePageMeta({
  middleware: ['auth'],
  title: 'Parts List',
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

// Modal start
import type { ColDef } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import ActionDropdownCellRenderer from '~/components/ag_grid/ActionDropdownCellRenderer.vue'
import DeletionModalForm from '~/components/form/DeletionModalForm.vue'
import PartsModalForm from '~/components/parts/PartsModalForm.vue'

const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const isImportModalOpen = ref(false)
const selectedItem = ref(-1)
const key = ref(1)
const key_update_modal = ref(2)

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
  console.log(isModalOpen.value)
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log(isModalOpen.value)
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const do_edit = (item) => {
  // Perform your action here
  selectedItem.value = item.id
  console.log(selectedItem.value)
  isModalOpen.value = true
}

const do_delete = async (item, type) => {
  isModalConfirmOpen.value = true
  selectedItem.value = item.id

  // Handle case where item might be undefined - use selectedItem.value instead
  const itemId = item?.id
  if (!itemId) {
    console.error('No item ID available for deletion')
    return
  }

  selectedItem.value = itemId
  console.log('do_delete', itemId)
  const data = {
    collection: 'Parts',
    id: itemId,
    item: {
      status: '0',
    },
  }
  await updateItem(data)
  handleChangeKey()
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const clearItem = () => {
  selectedItem.value = -1
}

// Parts import handlers
const partsFields = [
  { name: 'item_name', label: 'Item Name' },
  { name: 'item_mongolian_name', label: 'Item Mongolian Name' },
  { name: 'price', label: 'Price', type: 'number' },
  { name: 'manufacturer', label: 'Manufacturer' },
  { name: 'model_no', label: 'Model No' },
  { name: 'serial_no', label: 'Serial No' },
  { name: 'technical_data', label: 'Technical Data' },
  { name: 'special_information', label: 'Special Information' },
]

const handleImportClick = () => {
  isImportModalOpen.value = true
}

const handleImportModalClose = () => {
  isImportModalOpen.value = false
}

const handlePartsImport = async (partsData: any[]) => {
  try {
    if (!partsData || partsData.length === 0) {
      toaster.show({
        title: t('Error'),
        message: t('No parts to import'),
        color: 'danger',
        icon: 'mdi:alert-circle',
        closable: true,
      })
      return
    }

    // Create parts in batches
    const batchSize = 10
    const totalBatches = Math.ceil(partsData.length / batchSize)
    let importedCount = 0

    for (let i = 0; i < totalBatches; i++) {
      const batch = partsData.slice(i * batchSize, (i + 1) * batchSize)
      try {
        const response = await createItems({
          collection: 'Parts',
          items: batch.map((i) => ({ ...i, company_id: myCompanyId })),
        })
        if (response) {
          importedCount += batch.length
        }
      } catch (error) {
        console.error(`Error importing batch ${i + 1}:`, error)
      }
    }

    toaster.show({
      title: t('Success'),
      message: t(`${importedCount} parts imported successfully`),
      color: 'success',
      icon: 'mdi:check-circle',
      closable: true,
    })

    handleImportModalClose()
    refreshGrid()
  } catch (error) {
    console.error('Error importing parts:', error)
    toaster.show({
      title: t('Error'),
      message: t('Error importing parts. Please try again.'),
      color: 'danger',
      icon: 'mdi:alert-circle',
      closable: true,
    })
  }
}
// Modal end

// Grid functions

const gridApi = ref(null) // For storing ag-Grid API instance
const totalRows = ref(0) // Total rows from the backend
const paginationPageSize = ref(25) // Default page size
const rowModelType = ref('serverSide')
const dataSource = ref({})
const quickFilterText = ref('')
const defaultColDef = {
  resizable: true,
}

const onGridReady = (params) => {
  // Restore column state on grid load
  const savedState = localStorage.getItem('partsColumnState')
  if (savedState) {
    const state = JSON.parse(savedState)
    params.api.applyColumnState({ state: state, applyOrder: true })
  }
  // Grid api
  gridApi.value = params.api
  gridOptions.api = params.api

  dataSource.value = {
    getRows: (params) => {
      const { startRow, endRow, sortModel } = params.request
      // const filterModel = gridApi.value.getFilterModel()

      const sortField = sortModel.length ? sortModel[0].colId : null
      const sortOrder = sortModel.length ? sortModel[0].sort : null

      fetchPageData({
        filters: { status: '1' },
        currentPage: startRow / paginationPageSize.value + 1,
        pageSize: paginationPageSize.value,
        sortField: sortField,
        sortOrder: sortOrder,
        search: quickFilterText.value,
        searchField: 'part_number',
        collection: 'Parts',
        fields: [
          '*',
          'supplier.*',
          'segment.*',
          'family.*',
          'class.*',
          'commodity.*',
          'picture.*',
          'uom.*',
          'user_created.*',
          'date_created.*',
          'user_updated.*',
          'date_updated.*',
        ],
      })
        .then((response) => {
          console.log(response)
          const rowsThisPage = response.data
          const lastRow = response.totalCount

          params.success({
            rowData: rowsThisPage,
            rowCount: lastRow,
          })
        })
        .catch((error) => {
          console.error('Error fetching page data:', error)
          params.fail()
        })
    },
  }

  // Set the server-side datasource
  params.api.setGridOption('serverSideDatasource', dataSource.value)
}

const gridOptions = {
  rowModelType: 'serverSide', // Important for server-side pagination
  paginationPageSize: 25, // Start with 25 rows per page
  cacheBlockSize: 25, // Set fetch size to 25 rows per block
  pagination: true,
  paginationPageSizeSelector: false,
  serverSideDatasource: dataSource.value,
  resizable: true,
  suppressRowClickSelection: true, // Prevent row selection on row click
  rowMultiSelectWithClick: true, // Allow selecting multiple rows with clicks
  animateRows: false,
  tooltipShowDelay: 0,
  tooltipHideDelay: 2000,
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

const columnDefs: ColDef[] = ref([
  {
    field: 'status',
    headerName: t('Status'),
    headerClass: 'header-status',
    minWidth: 100,
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
  {
    field: 'user_updated.first_name',
    headerName: t('Updated by'),
    headerClass: 'header-user',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'date_updated',
    headerName: t('Updated date'),
    headerClass: 'header-date',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'name',
    headerName: t('Name'),
    headerClass: 'header-name',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'price',
    headerName: t('Price'),
    headerClass: 'header-price',
    minWidth: 100,
  },
  {
    field: 'supplier.name',
    headerName: t('Supplier'),
    headerClass: 'header-supplier',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'description',
    headerName: t('Description'),
    headerClass: 'header-description',
    minWidth: 200,
  },
  {
    field: 'part_number',
    headerName: t('Part Number'),
    headerClass: 'header-product',
    minWidth: 80,
  },
  {
    field: 'segment.description',
    headerName: t('Segment'),
    headerClass: 'header-segment',
    minWidth: 120,
  },
  {
    field: 'family.description',
    headerName: t('Family'),
    headerClass: 'header-family',
    minWidth: 120,
  },
  {
    field: 'class.description',
    headerName: t('Class'),
    headerClass: 'header-class',
    minWidth: 100,
  },
  {
    field: 'commodity.description',
    headerName: t('Commodity'),
    headerClass: 'header-commodity',
    minWidth: 120,
  },
  {
    field: 'picture',
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
    field: 'mongolian_name',
    headerName: t('Mongolian Name'),
    headerClass: 'header-name-mn',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'model_no',
    headerName: t('Model No'),
    headerClass: 'header-model',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'serial_no',
    headerName: t('Serial No'),
    headerClass: 'header-serial',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'material',
    headerName: t('Material'),
    headerClass: 'header-material',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'technical_data',
    headerName: t('Technical Data'),
    headerClass: 'header-technical',
    minWidth: 200,
    hide: true,
  },
  {
    field: 'special_information',
    headerName: t('Special Info'),
    headerClass: 'header-special',
    minWidth: 200,
    hide: true,
  },
  {
    field: 'user_defined_1',
    headerName: t('Custom Field 1'),
    headerClass: 'header-custom',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'user_defined_2',
    headerName: t('Custom Field 2'),
    headerClass: 'header-custom',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'user_defined_3',
    headerName: t('Custom Field 3'),
    headerClass: 'header-custom',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'uom.description',
    headerName: t('Unit of Measure'),
    headerClass: 'header-uom',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'actions',
    headerName: t('Actions'),
    minWidth: 108,
    sortable: false,
    filter: false,
    cellEditorPopup: true,
    cellRenderer: ActionDropdownCellRenderer,
    cellRendererParams: {
      onEditClick: do_edit,
      onDeleteClick: do_delete,
    },
    cellClass: 'actions-cell',
    cellStyle: {
      // 'background-color': 'green',
    },
  },
])

const onFilterTextBoxChanged = ({ target: { value } }) => {
  quickFilterText.value = value
  refreshGrid()
}

const saveColumnState = (params: any) => {
  console.log(params)
  const columnState = params.api.getColumnState()
  localStorage.setItem('partsColumnState', JSON.stringify(columnState))
}

const refreshGrid = () => {
  gridApi.value.refreshServerSide()
  gridApi.value.onFilterChanged()
  gridApi.value.refreshInfiniteCache()
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="work_order_list grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="left" @click="handleModalOpen">
          <Icon name="material-symbols:location-on" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts add') }}</span>
        </BaseButton>
        <BaseButton class="left cursor-pointer ml-1" @click="handleImportClick">
          <Icon name="octicon:upload-16" class="h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts import') }}</span>
        </BaseButton>
      </div>
      <!-- Grid -->

      <div
        class="grid_ag col-span-12 GridBody"
        :class="`ag-theme-quartz${$colorMode.value === 'light' ? '' : '-dark'}`"
      >
        <TairoContentWrapper>
          <template #left>
            <BaseInput
              icon="lucide:search"
              placeholder="Parts"
              :classes="{
                wrapper: 'w-[340px]',
              }"
              @input="onFilterTextBoxChanged"
            />
          </template>
        </TairoContentWrapper>
        <ag-grid-vue
          :style="{ height: '100%' }"
          @grid-ready="onGridReady"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list`"
          :gridOptions="gridOptions"
          :columnDefs="columnDefs"
          :defaultColDef="defaultColDef"
          :quickFilterText="quickFilterText"
          :onColumnMoved="saveColumnState"
          :onColumnPinned="saveColumnState"
          :onColumnVisible="saveColumnState"
          :onColumnResized="saveColumnState"
        >
        </ag-grid-vue>
        <PartsModalForm
          :key="selectedItem"
          title="Parts"
          code="Parts"
          :open="isModalOpen"
          :close="handleModalClose"
          :refresh="refreshGrid"
          size="2xl"
          :row="selectedItem"
        />
        <DeletionModalForm
          :key="selectedItem"
          code="Parts"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :row="selectedItem"
          :refresh="refreshGrid"
          :clear="clearItem"
        />
        <!-- Parts Import Modal -->
        <PartsImportModal
          :is-open="isImportModalOpen"
          :fields="partsFields"
          @close="handleImportModalClose"
          @import="handlePartsImport"
        />
      </div>
    </div>
  </div>
</template>
<style>
.work_order_list .grid_ag {
  min-height: 600px !important;
}
.work_order_list .ag-center-cols-container {
  overflow: visible;
}
.work_order_list .ag-row {
  overflow: visible;
  /* position: relative; */
}
.work_order_list .ag-row .actions-cell {
  overflow: visible;
}
</style>
