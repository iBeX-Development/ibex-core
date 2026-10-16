<script setup lang="ts">
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { ref } from 'vue'

import {
  ColumnsToolPanelModule,
  ExcelExportModule,
  MasterDetailModule,
  MenuModule,
  ModuleRegistry,
  MultiFilterModule,
  ServerSideRowModelModule,
  SetFilterModule,
  type ColDef,
  type ValueFormatterFunc,
} from 'ag-grid-enterprise'

import { AgGridVue } from 'ag-grid-vue3'

import { getData } from './data'

import menuActionsCellRenderer from './cell-renderers/menuActionsCellRenderer.vue'
import roleActionsCellRenderer from './cell-renderers/roleActionsCellRenderer.vue'
import StatusCellRenderer from './cell-renderers/statusCellRenderer.vue'
import UserCellRenderer from './cell-renderers/userCellRenderer.vue'
import RolesModalForm from './RolesModalForm.vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Permissions',
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

const config = useRuntimeConfig()
const { getItems, deleteItems, updateItem, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const runtimeConfig = useRuntimeConfig()
const { token } = useDirectusToken()

const { gridTheme, isDarkMode } = defineProps({
  gridTheme: {
    type: String,
    default: 'ag-theme-quartz',
  },
  isDarkMode: {
    type: Boolean,
  },
  middleware: ['auth'],
  title: 'Permissions',
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

ModuleRegistry.registerModules([
  ExcelExportModule,
  SetFilterModule,
  MultiFilterModule,
  MasterDetailModule,
  ColumnsToolPanelModule,
  MenuModule,
  ServerSideRowModelModule,
])

const gridApi = ref(null) // For storing ag-Grid API instance
const totalRows = ref(0) // Total rows from the backend
const paginationPageSize = ref(10) // Default page size
const rowModelType = ref('serverSide')
const dataSource = ref({})
const rowData = ref(null) // Initially null
const currentPage = ref(1) // Starting page
const cacheBlockSize = ref(10)

const rowHeight = 60
const activeTab = ref('active')
const statuses = {
  active: 'Active',
  paused: 'Inactive',
}

const masterDetail = true
const detailRowAutoHeight = true
const autoSizeStrategy = {
  type: 'fitGridWidth',
}

const isModalOpen = ref(false)
const isRoleModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const selectedRowItems = ref(-1)
const task = ref('')
const key = ref(1)
const key_update_modal = ref(2)

const userMenus = ref([])
const userRoles = ref([])

const quickFilterText = ref('')
const quickFilterStatus = ref('active')

const openModal = async (rowData, bttn) => {
  console.log('rowData', rowData)
  console.log('bttn', bttn)
  isModalOpen.value = true
  if (bttn == 'menu') {
    const menusRes = await getItems({
      collection: 'Menus',
      params: {
        filter: { position: 'start', is_active: 1 },
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    selectedRowItems.value = menusRes.data.map((menu) => ({
      ...menu,
      title: t(menu.title),
    }))
    selectedItem.value = rowData
  }

  if (bttn == 'role') {
    let filters = {
      status: '1',
      company_id: myCompanyId,
    }

    const rolefilters = `?filter[company_id][_eq]=${myCompanyId}`

    const rolesRes = await fetch(
      runtimeConfig.public.directus.url + 'roles' + rolefilters,
      {
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token.value}`,
        },
      },
    )

    const locationRes = await getItems({
      collection: 'Location',
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    // console.log('locationRes', locationRes.data)

    let jsonData = await rolesRes.json()
    rowData.locations = locationRes.data
    selectedRowItems.value = jsonData.data
    selectedItem.value = rowData
  }

  if (bttn == 'location') {
    // console.log('bttn', rowData)

    selectedRowItems.value = rowData
    selectedItem.value = rowData
  }

  task.value = bttn
}

const path = () => {
  if (selectedItem.value == -1) return 'fields/directus_users'
  else return 'users/' + selectedItem.value
}

const set_title = () => {
  if (task.value === 'role') return t('Roles')
  else if (task.value === 'menu') return t('Menus')
  else if (task.value === 'location') return t('Location menus')
  else return ''
}

const handleModalClose = () => {
  isModalOpen.value = false
  isRoleModalOpen.value = false
  selectedItem.value = -1
  selectedRowItems.value = -1
  task.value = ''
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const gridOptions = {
  rowModelType: 'serverSide', // Important for server-side pagination
  paginationPageSize: 10, // Start with 10 rows per page
  cacheBlockSize: 10, // Set fetch size to 10 rows per block
  pagination: true,
  paginationPageSizeSelector: false,
  serverSideDatasource: dataSource.value,
  // columnMenu: 'legacy',
  suppressHeaderMenuButton: true,
  flex: 1,
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

const fetchPageData = async (
  startRow,
  endRow,
  sortField,
  sortOrder,
  search,
  status,
) => {
  try {
    const response = await getData(
      startRow / paginationPageSize.value + 1,
      paginationPageSize.value,
      sortField,
      sortOrder,
      search,
      status,
    )

    return {
      data: response.data || [],
      totalCount: response.totalCount || 0,
    }
  } catch (error) {
    console.error('Error fetching page data:', error)
    return { data: [], totalCount: 0 } // Return empty on error
  }
}

const onGridReady = (params) => {
  gridApi.value = params.api
  gridOptions.api = params.api

  dataSource.value = {
    getRows: (params) => {
      const { startRow, endRow, sortModel } = params.request
      // const filterModel = gridApi.value.getFilterModel()

      const sortField = sortModel.length ? sortModel[0].colId : null
      const sortOrder = sortModel.length ? sortModel[0].sort : null

      fetchPageData(
        startRow,
        endRow,
        sortField,
        sortOrder,
        quickFilterText.value,
        quickFilterStatus.value,
      )
        .then((response) => {
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

const handleChangeKey = async () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
  selectedItem.value = -1
  selectedRowItems.value = -1
  task.value = ''

  if (gridOptions.api) {
    gridOptions.api.refreshServerSide()
  }
}

const handleChangeModalKey = () => {
  selectedItem.value = -1
  selectedRowItems.value = -1
  task.value = ''
}

const menusFormatter: ValueFormatterFunc = ({ value }) =>
  value === 'ALL' ? value : value.toString()
type Status = keyof typeof statuses

const statusFormatter: ValueFormatterFunc = ({ value }) => {
  return quickFilterStatus.value
}

const columnDefs: ColDef[] = ref([
  {
    field: 'first_name',
    headerName: t('Users'),
    cellRenderer: 'agGroupCellRenderer',
    headerClass: 'header-product',
    cellRendererParams: {
      innerRenderer: UserCellRenderer,
    },
    minWidth: 300,
  },
  {
    field: 'role',
    headerName: t('Main Role'),
  },
  {
    field: 'status',
    headerName: t('Status'),
    valueFormatter: statusFormatter,
    cellRenderer: StatusCellRenderer,
    filter: false,
    sortable: false,
    headerClass: 'header-status',
    width: 120,
  },
  {
    field: 'roles',
    headerName: t('Roles'),
    valueFormatter: menusFormatter,
    sortable: false,
    width: 80,
  },
  {
    field: 'menus',
    headerName: t('Menus'),
    valueFormatter: menusFormatter,
    sortable: false,
    width: 80,
  },
  {
    field: 'more',
    headerName: t('More'),
    cellRenderer: menuActionsCellRenderer,
    cellRendererParams: {
      onEditRole: openModal,
      onEditMenu: openModal,
    },
    minWidth: 194,
    filter: false,
    sortable: false,
  },
])
const defaultColDef = {
  resizable: true,
  suppressHeaderMenuButton: true,

  flex: 1,
  // animateRows: false,
  tooltipShowDelay: 0,
  tooltipHideDelay: 2000,
}
const detailCellRendererParams = {
  detailGridOptions: {
    columnDefs: [
      {
        field: 'location',
        headerName: t('Location'),
        flex: 0.66,
        maxWidth: 180,
        suppressHeaderMenuButton: true,
      },
      {
        field: 'role',
        headerName: t('Role'),
        suppressHeaderMenuButton: true,
        flex: 1,
        maxWidth: 160,
        tooltipField: 'role',
      },
      {
        field: 'LocationSubMenu',
        headerName: t('Location Sub Menu'),
        suppressHeaderMenuButton: true,
        maxWidth: 420,
        flex: 1,
        valueFormatter: ({ data, value }) =>
          data.LocationSubMenu === 'Admin'
            ? t('Admin')
            : data.LocationSubMenuNames.map((name) => t(name)).join(', '),
        tooltipValueGetter: ({ data, value }) =>
          data.LocationSubMenu === 'Admin'
            ? t('Admin')
            : data.LocationSubMenuNames.map((name) => t(name)).join(', '),
      },
      {
        field: 'Count',
        headerName: t('Count'),
        maxWidth: 80,
        suppressHeaderMenuButton: true,
        flex: 1,
        cellStyle: { justifyContent: 'start' },
      },
      {
        field: 'Actions',
        headerName: t('Actions'),
        maxWidth: 110,
        suppressHeaderMenuButton: true,
        flex: 1,
        cellStyle: { justifyContent: 'start' },
      },
      {
        field: 'More',
        headerName: t('More'),
        cellRenderer: roleActionsCellRenderer,
        cellRendererParams: {
          onEditLocation: openModal,
        },
        maxWidth: 120,
        suppressHeaderMenuButton: true,
        flex: 1,
      },
    ],
    headerHeight: 38,
    suppressHeaderMenuButton: true,
    flex: 1,
    enableBrowserTooltips: true,
    tooltipShowDelay: 0,
    tooltipHideDelay: 2000,
    tooltipMouseTrack: true,
  },

  getDetailRowData: ({
    successCallback,
    data: { rolesDetails },
  }: GetDetailRowDataParams) => successCallback(rolesDetails),
}

function handleTabClick(status: Status) {
  if (!gridApi.value) {
    return
  }

  // gridApi.value.setColumnFilterModel(
  //   'status',
  //   status === 'all' ? null : { values: [status] },
  // )
  // gridApi.value.onFilterChanged()
  quickFilterStatus.value = status
  gridApi.value.refreshServerSide()
  gridApi.value.onFilterChanged()
  gridApi.value.refreshInfiniteCache()

  activeTab.value = status
}

const onFilterTextBoxChanged = ({
  target: { value },
}: ChangeEvent<HTMLInputElement>) => {
  setTimeout(async () => {
    if (value.length > 3 || value.length == 0) {
      quickFilterText.value = value
      gridApi.value.refreshServerSide()
      gridApi.value.onFilterChanged()
      gridApi.value.refreshInfiniteCache()
    }
  }, 2000)
}

const themeClass = `${gridTheme}${isDarkMode ? '-dark' : ''}`
const totalPages = computed(() => {
  return Math.ceil(totalRows.value / paginationPageSize.value)
})
</script>

<template>
  <div class="wrapper user_list">
    <div class="container">
      <div class="exampleHeader">
        <div class="inputWrapper">
          <BaseInput
            icon="lucide:search"
            :placeholder="$t('Username')"
            :classes="{
              wrapper: 'w-[340px]',
            }"
            @input="onFilterTextBoxChanged"
          />

          <!-- <input
            type="text"
            placeholder="Search users..."
            @input="onFilterTextBoxChanged"
          /> -->
        </div>

        <div class="tabs">
          <button
            v-for="[key, displayValue] in Object.entries(statuses)"
            :class="{ tabButton: true, active: activeTab === key }"
            @click="handleTabClick(key)"
          >
            {{ $t(displayValue) }}
          </button>
        </div>
      </div>
      <div class="grid_ag" :class="themeClass">
        <ag-grid-vue
          :style="{ height: '100%' }"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_tree_list`"
          @grid-ready="onGridReady"
          :rowModelType="rowModelType"
          :gridOptions="gridOptions"
          :columnDefs="columnDefs"
          :defaultColDef="defaultColDef"
          :rowHeight="rowHeight"
          :masterDetail="masterDetail"
          :detailRowAutoHeight="detailRowAutoHeight"
          :autoSizeStrategy="autoSizeStrategy"
          :detailCellRendererParams="detailCellRendererParams"
          :quickFilterText="quickFilterText"
          :quickFilterStatus="quickFilterStatus"
        >
        </ag-grid-vue>
      </div>
      <div class="modal">
        <RolesModalForm
          :key="selectedItem"
          :title="set_title()"
          :task="task"
          :path="path()"
          :open="isModalOpen"
          :close="handleModalClose"
          :row="selectedItem"
          :rowItems="selectedRowItems"
          :refresh="handleChangeKey"
          :refresh_modal="handleChangeModalKey"
          size="2xl"
          schema_column="two-column-form"
        />
      </div>
    </div>
  </div>
</template>

<style>
@import 'ag-grid-community/styles/ag-grid.css';
@import 'ag-grid-community/styles/ag-theme-quartz.css';

:root {
  --layout-grid-header-height: 32px;
  --layout-grid-margin: 32px;
  /* --ag-row-border: 1px solid #c41717; */
}

.user_list .ag-theme-quartz .ag-body-viewport,
.user_list .ag-theme-quartz-dark .ag-body-viewport {
  padding-top: 8px;
}

.user_list .ag-theme-quartz .ag-row-group .ag-icon,
.user_list .ag-theme-quartz-dark .ag-row-group .ag-icon {
  opacity: 0.5;
}

.user_list .ag-theme-quartz .ag-row,
.user_list .ag-theme-quartz-dark .ag-row {
  border-bottom: none;
}

.user_list .ag-theme-quartz .ag-row:not(.ag-row-level-1),
.user_list .ag-theme-quartz-dark .ag-row:not(.ag-row-level-1) {
  border-radius: 8px;
  overflow: hidden;
}

/* Required to transition background color for row hover */
.user_list .ag-theme-quartz .ag-row:not(.ag-row-level-1)::before,
.user_list .ag-theme-quartz-dark .ag-row:not(.ag-row-level-1)::before {
  content: '';
  display: block;
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  pointer-events: none;
  transition: background-color 0.33s ease-in-out;
}

.user_list .ag-theme-quartz .ag-cell-expandable,
.user_list .ag-theme-quartz-dark .ag-cell-expandable {
  display: flex;
  justify-content: center;
  align-items: center;
}

.user_list .ag-theme-quartz .ag-cell,
.user_list .ag-theme-quartz-dark .ag-cell {
  display: flex;
  align-items: center;
}

.user_list .ag-theme-quartz .ag-cell:first-child,
.user_list .ag-theme-quartz-dark .ag-cell:first-child {
  border-top-left-radius: 8px;
  border-bottom-left-radius: 8px;
}

.user_list .ag-theme-quartz .ag-cell:last-child,
.user_list .ag-theme-quartz-dark .ag-cell:last-child {
  border-top-right-radius: 8px;
  border-bottom-right-radius: 8px;
}

.user_list .ag-theme-quartz .ag-right-aligned-cell,
.user_list .ag-theme-quartz-dark .ag-right-aligned-cell {
  justify-content: flex-end;
}

.user_list .ag-theme-quartz .ag-header {
  background-color: #f9fafb;
  color: #39485d;
  border-radius: 8px;
  border: 1px solid #eff0f1;
}

.user_list .ag-theme-quartz-dark .ag-header {
  background-color: #28313e !important;
  border-radius: 8px;
  border: none !important;
}

.user_list .ag-theme-quartz .ag-header-cell-text {
  color: #1f383c;
  display: flex;
  align-items: center;
}

.user_list .ag-theme-quartz-dark .ag-header-cell-text,
.user_list .ag-theme-quartz-dark .buttonCell .button-secondary {
  color: white !important;
}

.user_list .ag-theme-quartz .ag-root-wrapper,
.user_list .ag-theme-quartz-dark .ag-root-wrapper {
  border: none;
}

.user_list .ag-theme-quartz .ag-full-width-container .ag-row,
.user_list .ag-theme-quartz-dark .ag-full-width-container .ag-row,
.user_list .ag-theme-quartz .ag-full-width-container .ag-details-row,
.user_list .ag-theme-quartz-dark .ag-full-width-container .ag-details-row {
  background-color: transparent;
}

.user_list .ag-theme-quartz .ag-details-row,
.user_list .ag-theme-quartz-dark .ag-details-row {
  padding: 16px;
}

.user_list .ag-theme-quartz .ag-paging-panel {
  height: 40px;
}

.user_list .ag-theme-quartz .ag-paging-panel > span:last-child {
  margin-right: 0;
}

.user_list .ag-center-cols-viewport {
  min-height: unset !important;
}

.user_list .ag-center-cols-viewport .ag-center-cols-container {
  font-size: 12px;
}
.user_list .grid_ag {
  --ag-header-background-color: transparent !important;

  height: calc(
    100vh - var(--layout-grid-header-height) - 62px - var(--layout-grid-margin)
  );
  margin: 0 var(--layout-grid-margin) var(--layout-grid-margin);
}

.user_list .exampleHeader {
  display: flex;
  justify-content: space-between;
  padding-bottom: 16px;
  padding-top: 8px;
  margin: var(--layout-grid-margin) var(--layout-grid-margin) 0;
}

.user_list .exampleHeader {
  padding-bottom: 16px;
  padding-top: 8px;
}

.user_list .exampleHeader span {
  margin-right: 12px;
  font-size: 14px;
}

.user_list .inputWrapper {
  position: relative;
  display: flex;
  align-items: center;
  overflow: visible;
}

.user_list .inputWrapper svg {
  position: absolute;
  left: 8px;
  pointer-events: none;
}

.user_list .inputWrapper input {
  font-size: 14px;
  padding: 0.375em 0.75em 0.375em 2.4em;
  line-height: 1.4;
  border-radius: 6px;
  border: 1px solid var(--color-input-border, #d0d5dd);
  background-color: transparent;
  outline: none;
}

.user_list .tabs {
  display: flex;
  border-radius: 8px;
  overflow: hidden;
  background-color: var(--color-bg-secondary, #f9fafb);
  border: 1px solid var(--color-border-secondary, #eff0f1);
  color: #39485d;
  border-radius: 8px;
}

.user_list .tabButton {
  appearance: none;
  display: inline-block;
  padding: 0.375em 1em 0.5em;
  white-space: nowrap;
  font-size: 14px;
  font-weight: 500;
  border-radius: 6px;
  border: none;
  background-color: var(--color-bg-secondary, #f9fafb);
  color: var(--color-text-secondary, #39485d);
  cursor: pointer;
  box-shadow: none;
  transition: background 0.3s, color 0.3s;
}

.user_list .tabButton:hover {
  background: #7c7c7c23;
  color: rgba(37, 37, 37, 0.6);
}

.user_list .tabButton.active {
  background: #8363ee;
  color: white;
  font-weight: 500;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.user_list .ag-theme-quartz-dark .ag-header-cell-text:before {
  filter: invert(1);
}

.user_list .v-overlay {
  z-index: 10001 !important;
}
</style>
