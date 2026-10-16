<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { fetchPageData } from '~/components/ag_grid/ag_grid_directus'

const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Unit of measure',
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
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const key = ref(1)
const key_update_modal = ref(2)

const toaster = useToaster()

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

const do_delete = (item) => {
  isModalConfirmOpen.value = true
  selectedItem.value = item.id
}
const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const clearItem = () => {
  selectedItem.value = -1
}
// Modal end

// Grid functions

const gridApi = ref(null) // For storing ag-Grid API instance
const totalRows = ref(0) // Total rows from the backend
const paginationPageSize = ref(5) // Default page size
const rowModelType = ref('serverSide')
const dataSource = ref({})
const quickFilterText = ref('')
const defaultColDef = {
  resizable: false,
}

const { gridTheme, isDarkMode } = defineProps({
  gridTheme: {
    type: String,
    default: 'ag-theme-quartz',
  },
  isDarkMode: {
    type: Boolean,
  },
})
const themeClass = `${gridTheme}${isDarkMode ? '-dark' : ''}`

const onGridReady = (params) => {
  // Restore column state on grid load
  const savedState = localStorage.getItem('uomColumnState')
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
        currentPage: startRow / paginationPageSize.value + 1,
        pageSize: paginationPageSize.value,
        sortField: sortField,
        sortOrder: sortOrder,
        search: quickFilterText.value,
        searchField: 'code',
        collection: 'uom',
        fields: ['*'],
      })
        .then((response) => {
          console.log(response)
          const rowsThisPage = response.data
          const lastRow = response.totalCount

          params.success({
            rowData: rowsThisPage,
            lastRow: lastRow,
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
  paginationPageSize: 10, // Start with 10 rows per page
  cacheBlockSize: 10, // Set fetch size to 10 rows per block
  pagination: true,
  paginationPageSizeSelector: false,
  serverSideDatasource: dataSource.value,
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
    field: 'code',
    headerName: 'Custom Field 3',
    headerClass: 'header-custom',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'description',
    headerName: 'Unit of Measure',
    headerClass: 'header-uom',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'actions',
    headerName: 'Actions',
    minWidth: 108,
    sortable: false,
    filter: false,
    cellRenderer: ActionDropdownCellRenderer,
    cellRendererParams: {
      onEditClick: do_edit,
      onDeleteClick: do_delete,
    },
  },
])

const onFilterTextBoxChanged = ({
  target: { value },
}: ChangeEvent<HTMLInputElement>) => {
  quickFilterText.value = value
  gridApi.value.refreshServerSide()
  gridApi.value.onFilterChanged()
  gridApi.value.refreshInfiniteCache()
}

const saveColumnState = (params: any) => {
  console.log(params)
  const columnState = params.api.getColumnState()
  localStorage.setItem('partsColumnState', JSON.stringify(columnState))
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="float-right" @click="handleModalOpen">
          <Icon name="material-symbols:location-on" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts add') }}</span>
        </BaseButton>
      </div>
      <!-- Grid -->

      <div class="grid_ag col-span-12" :class="themeClass">
        <TairoContentWrapper>
          <template #left>
            <BaseInput
              icon="lucide:search"
              shape="curved"
              placeholder="Filter parts..."
              :classes="{
                wrapper: 'w-full md:w-auto',
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
          :rowHeight="80"
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
          :refresh="handleChangeKey"
          size="2xl"
          :row="selectedItem"
        />
        <DeletionModalForm
          :key="selectedItem"
          code="Parts"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :row="selectedItem"
          :refresh="handleChangeKey"
          :clear="clearItem"
        />
      </div>
    </div>
  </div>
</template>
<style scoped>
.grid_ag {
  min-height: 560px !important;
}
.ag-row {
  z-index: -1 !important;
  overflow: visible;
}
.ag-row-focus {
  z-index: -2 !important;
  overflow: visible;
}
</style>
