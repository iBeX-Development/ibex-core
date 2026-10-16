<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { fetchPageData } from '~/components/ag_grid/ag_grid_directus'

const { t } = useI18n({ useScope: 'global' })
const { open } = usePanels()
const { getItems, updateItem, createItems } = useDirectusItems()

import { useRouter } from 'vue-router'
const router = useRouter()
const { params } = useRoute()

const myId = window.localStorage.getItem('myId')
const runtimeConfig = useRuntimeConfig()
const locationId = params.id
console.log('params->', locationId)
definePageMeta({
  middleware: ['auth'],
  title: 'Bin Location',
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
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import DeletionModalForm from '~/components/form/DeletionModalForm.vue'
import AddModalForm from './AddModalForm.vue'

const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const isModalApproveConfirmOpen = ref(false)

const selectedItem = ref(-1)
const itemsValue = ref(-1)
const selectedRow = ref(-1)
const editPartRow = ref(-1)
const actionType = ref(null)

const key = ref(1)
const last_row = ref(null)

const toaster = useToaster()
const currentRecord = ref(null)
const locations = ref(null)

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

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalApproveConfirmOpen.value = false
}

const do_make = async (item, type) => {
  let statuss = ''

  console.log('do_make', item, type)
  if (type == 'do_delete') {
    statuss = 'archived'
  }
  // else if (type == 'do_assign') statuss = 4
  const data = {
    collection: 'Bin_location',
    id: item.id,
    item: { status: statuss },
  }
  await updateItem(data)
  refreshGrid()
}

const do_delete = (item) => {
  actionType.value = 'do_delete'
  itemsValue.value = item

  isModalConfirmOpen.value = true
  selectedItem.value = item.id
}

const do_edit = async (editItem) => {
  // Perform your action here
  selectedItem.value = editItem.id
  selectedRow.value = editItem
  actionType.value = 'do_edit'

  isModalOpen.value = true
}
const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const clearItem = () => {
  selectedItem.value = -1
}

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
  // Grid api
  gridApi.value = params.api
  gridOptions.api = params.api

  const savedState = localStorage.getItem('binlocations')
  if (savedState) {
    const state = JSON.parse(savedState)
    params.api.applyColumnState({ state: state, applyOrder: true })
  } else {
    // Хэрэглэгч хараахан баганын өргөнийг өөрчлөөгүй анхны удаад л дэлгэц
    // дүүргэж тохируулна — эс тэгвэл хадгалсан өргөнийг дарж бичнэ
    params.api.sizeColumnsToFit()
  }

  window.addEventListener('resize', () => {
    // Хэрэглэгч аль хэдийн баганын өргөнийг гараар тохируулсан бол цонхны
    // хэмжээ өөрчлөгдөх бүрд түүнийг дахин дарж бичихгүй
    setTimeout(() => {
      if (!localStorage.getItem('binlocations')) {
        params.api.sizeColumnsToFit()
      }
    }, 0)
  })

  dataSource.value = {
    getRows: async (params) => {
      const { startRow, endRow, sortModel } = params.request
      const filterModels = gridApi.value.getFilterModel()
      let filters = {
        status: {
          _in: ['published'],
        },
        location: locationId ? locationId : undefined,
      }

      if (filterModels.date_created) {
        const transactionDate = filterModels.date_created
        if (transactionDate.dateFrom || transactionDate.dateTo) {
          if (transactionDate.type === 'inRange') {
            filters['date_created'] = {
              _between: [transactionDate.dateFrom, transactionDate.dateTo],
            }
          } else if (transactionDate.type === 'equals') {
            filters['date_created'] = {
              _in: [transactionDate.dateFrom],
            }
          } else if (transactionDate.type === 'lessThan') {
            filters['date_created'] = {
              _lte: transactionDate.dateFrom,
            }
          } else if (transactionDate.type === 'greaterThan') {
            filters['date_created'] = {
              _gte: transactionDate.dateFrom,
            }
          } else if (transactionDate.type === 'notEqual') {
            filters['date_created'] = {
              _neq: transactionDate.dateFrom,
            }
          }
        }
        // 3. Хэрэв формат танигдахгүй бол
        else {
          console.log('Unknown date_created format', transactionDate)
        }
      }

      if (filterModels?.['location.name']?.values) {
        filters['location'] = {
          _in: filterModels['location.name'].values,
        }
      }

      if (quickFilterText.value) {
        filters['name'] = {
          _contains: quickFilterText.value,
        }
      }

      const sortField = sortModel.length ? sortModel[0].colId : null
      const sortOrder = sortModel.length ? sortModel[0].sort : null

      fetchPageData({
        currentPage: startRow / paginationPageSize.value + 1,
        pageSize: paginationPageSize.value,
        sortField: sortField,
        sortOrder: sortOrder,
        filters: filters,
        search: quickFilterText.value,
        searchField: 'name',
        collection: 'Bin_location',
        fields: ['*', 'location.*', 'user_created.*', 'date_created.*'],
      })
        .then((response) => {
          // console.log('response', response)
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
  animateRows: false,
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

const actionFormatter = ({ value }) => {
  console.log('actionFormatter', value)
}

const dayFormatter = ({ value }) => {
  const localTime = new Date(value)
  const formattedTime =
    `${localTime.getFullYear()}/` +
    `${String(localTime.getMonth() + 1).padStart(2, '0')}/` +
    `${String(localTime.getDate()).padStart(2, '0')}`

  return formattedTime
}

const onRowClicked = (params) => {
  open('binlocation', {
    id: params.data.id,
    data: params.data,
    module: 'binlocation',
    name: params.data.name,
    refresh: refreshGrid,
    // refresh: refreshGrid(),
  })
}

const statusFormatter: ValueFormatterFunc = ({ value }) => {
  if (value === 1) return 'active'
  else if (value === 2) return 'approved'
  else if (value === 3) return 'returned'
}

const filterDateParams = {
  comparator: (filterLocalDateAtMidnight: Date, cellValue: string) => {
    const dateAsString = cellValue
    if (dateAsString == null) return -1
    const dateParts = dateAsString.split('/')
    const cellDate = new Date(
      Number(dateParts[2]),
      Number(dateParts[1]) - 1,
      Number(dateParts[0]),
    )

    if (filterLocalDateAtMidnight.getTime() === cellDate.getTime()) {
      return 0
    }

    if (cellDate < filterLocalDateAtMidnight) {
      return -1
    }

    if (cellDate > filterLocalDateAtMidnight) {
      return 1
    }
    return 0
  },
  minValidYear: 2000,
  maxValidYear: 2050,
  buttons: ['reset', 'apply'],
  maxNumConditions: 1,
  // closeOnApply: true,
  inRangeFloatingFilterDateFormat: 'Do MMM YYYY',
}

const columnDefs: ColDef[] = ref([
  {
    field: 'auto_number',
    headerName: t('ID'),
    headerClass: 'header-code',
    width: 50,
    maxWidth: 140,
    sortable: true,
    filter: false,
    editable: false,
    resizable: true,
    // pinned: 'left',
    onCellClicked: (params) => {
      onRowClicked(params)
    },
    cellStyle: { cursor: 'pointer' },
  },
  {
    field: 'name',
    headerName: t('Name'),
    headerClass: 'header-name',
    flex: 1,
    maxWidth: 380,
    resizable: true,
    onCellClicked: (params) => {
      onRowClicked(params)
    },
    cellStyle: { cursor: 'pointer' },
  },

  {
    field: 'user_created.first_name',
    headerName: t('Created by'),
    headerClass: 'header-assign',
    maxWidth: 250,
    resizable: true,
  },
  {
    field: 'date_created',
    headerName: t('Created'),
    headerClass: 'header-date',
    maxWidth: 280,
    valueFormatter: dateFormatter,
    resizable: true,
  },
  {
    field: 'actions',
    headerName: t('Actions'),
    maxWidth: 120,
    sortable: false,
    filter: false,
    cellEditorPopup: true,
    cellRenderer: ActionDropdownCellRenderer,
    // cellRenderer: (params) => {
    //   console.log('paramsparams', params)

    //   if (params.data.status === 2) {
    //     return
    //   }
    //   return ActionDropdownCellRenderer
    // },
    cellRendererParams: () => {
      return {
        onEditClick: do_edit,
        onDeleteClick: do_delete,
      }
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
  // console.log(params)
  const columnState = params.api.getColumnState()
  localStorage.setItem('binlocations', JSON.stringify(columnState))
}

const refreshGrid = () => {
  gridApi.value.refreshServerSide()
  gridApi.value.onFilterChanged()
  gridApi.value.refreshInfiniteCache()
}

onMounted(async () => {
  refreshGrid()
})
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="bin_location_list grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="left" @click="handleModalOpen">
          <Icon
            name="material-symbols-light:input-circle-rounded"
            class="-ms-1 h-4 w-4"
          />
          <span class="text-[11px]">{{ $t('Add') }}</span>
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
              :placeholder="$t('Search...')"
              :classes="{
                wrapper: 'w-[340px]',
              }"
              @input="onFilterTextBoxChanged"
            />
          </template>
        </TairoContentWrapper>
        <ag-grid-vue
          style="width: 100%; height: 560px"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list`"
          @grid-ready="onGridReady"
          :onColumnMoved="saveColumnState"
          :onColumnPinned="saveColumnState"
          :onColumnVisible="saveColumnState"
          :onColumnResized="saveColumnState"
          :gridOptions="gridOptions"
          :columnDefs="columnDefs"
          :defaultColDef="defaultColDef"
          :quickFilterText="quickFilterText"
        >
        </ag-grid-vue>
        <AddModalForm
          :key="selectedItem"
          :location="locationId"
          :row="selectedItem"
          :editPartRow="editPartRow"
          :item="selectedRow"
          title="Bin Location"
          module="Bin_location"
          code="Bin_location"
          :open="isModalOpen"
          :close="handleModalClose"
          :refresh="refreshGrid"
          size="md"
        />
        <DeletionModalForm
          :key="selectedItem"
          :itemsValue="itemsValue"
          code="Bin_location"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :do_make="do_make"
          :actionType="actionType"
          :row="selectedItem"
          :refresh="refreshGrid"
          :clear="clearItem"
        />
        <ConfirmModalForm
          :itemsValue="itemsValue"
          code="Bin_location"
          text="Do you agree to this action?"
          :open="isModalApproveConfirmOpen"
          :close="handleModalConfirmClose"
          :do_make="do_make"
          :actionType="actionType"
          :row="selectedItem"
          :refresh="refreshGrid"
          :clear="clearItem"
        />
      </div>
    </div>
  </div>
</template>
<style>
.bin_location_list .grid_ag {
  min-height: 560px !important;
}
.bin_location_list .ag-center-cols-container {
  overflow: visible;
  display: flex;
  flex-direction: column;
}
.bin_location_list .ag-row .locations-name {
  line-height: 1.5;
  font-size: 13px;
  justify-content: center;
  align-items: center;
  /* font-weight: 500; */
  border: none !important;
}
.bin_location_list .ag-row .locations-name:hover {
  font-weight: 500;
}
.bin_location_list .ag-row {
  overflow: visible;
  position: relative;
  transform: none !important;
  /* width: inherit; */
}
.bin_location_list .ag-row .status-cell {
  border: none !important;
}
.bin_location_list .ag-row .actions-cell {
  overflow: visible;
}
/* .ag-row:has(> .status-approved) .actions-cell {
  display: none;
} */
</style>
