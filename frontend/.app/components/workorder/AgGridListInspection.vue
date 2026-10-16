<script setup lang="ts">
import {
  GetContextMenuItemsParams,
  GetMainMenuItemsParams,
  ModuleRegistry,
} from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import {
  ClipboardModule,
  // CellSelectionModule,
  // ColumnMenuModule,
  // ContextMenuModule,
  ExcelExportModule,
  RichSelectModule,
} from 'ag-grid-enterprise'

import { AgGridVue } from 'ag-grid-vue3'
import { format } from 'date-fns'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { fetchPageData } from '~/components/ag_grid/ag_grid_directus'
import PriorityCellRenderer from '~/components/ag_grid/priorityCellRenderer.vue'
// import WoStatusCellRenderer from '~/components/ag_grid/wo_statusCellRenderer.vue'
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import WorkOrderDeletionModalForm from '~/components/form/WorkOrderDeletionModalForm.vue'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'

import {
  action_status,
  priorities,
} from '~/components/workorder/WorkOrderConstants'

import {
  completed_wo_status,
  open_status_id,
  open_wo_status,
  wo_status,
} from '~/components/workorder/WorkOrderStatus'
import ActionDropdownCellRenderer from '../ag_grid/ActionDropdownCellRenderer.vue'

const { t } = useI18n({ useScope: 'global' })
const { updateItem, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const { open } = usePanels()
const user = useDirectusUser()
const toaster = useToaster()
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()

ModuleRegistry.registerModules([
  RichSelectModule,
  ClipboardModule,
  ExcelExportModule,
  // ClientSideRowModelModule,
  // ColumnMenuModule,
  // ContextMenuModule,
  // CellSelectionModule,
])

const filter_modules = {
  request: 'Request',
  open: 'Open',
  completed: 'Completed',
}
const activeTab = ref('request')
const parts_codes = ref([])
const columnDefs = ref([])
const prints = [
  { id: 1, name: 'Printed' },
  { id: 0, name: 'No Print' },
]

const props = defineProps({
  status: Object,
  wo_status: Object,
  wo_status_items: Object,
  location: String,
  work_order_type: String,
  asset: Number,
  class: String,
  type: String,
  tab: String,
  code: String,
})

// Grid actions
const current_row = ref(null)
const isModalConfirmOpen = ref(false)
const isModalUserListOpen = ref(false)
let wo_statuss = props.wo_status || false

const isModalApproveConfirmOpen = ref(false)

const actionType = ref('')
const selectedItem = ref(-1)
const itemsValue = ref(-1)

const loading = ref(true)
const gridApi = ref(null)
const agGridEl = ref<HTMLElement | null>(null)
const selectedCount = ref(0)
const totalRows = ref(0) // Total rows from the backend
const paginationPageSize = ref(10) // Default page size
const rowModelType = ref('serverSide')
const dataSource = ref({})
const quickFilterText = ref('')
const quickFilterStatus = ref('request')
const windowHeight = ref(560)

const defaultColDef = {
  resizable: false,
}

const { getItems } = useDirectusItems()
const { params } = useRoute()
const rowData = ref([])
// getRows datasource-аас сүүлд амжилттай татсан хуудасны мөрүүд — Next/Prev
// навигацид ашиглана
const loadedRowsForNav = ref<any[]>([])
const key = ref(1)
const myId = window.localStorage.getItem('myId')

function handleTabClick(status, type) {
  if (!gridApi.value) {
    return
  }

  quickFilterStatus.value = status
  gridApi.value.refreshServerSide()
  gridApi.value.onFilterChanged()
  gridApi.value.refreshInfiniteCache()

  activeTab.value = status
}

const onRowClicked = (params) => {
  console.log(params.data)
  console.log('props.wo_status_items', props.wo_status_items)

  if (props.type == 'inspection') {
    open('inspectionmore', {
      id: params.data.id,
      data: params.data,
      wo_statuses: props.wo_status_items,
      type: props.type,
      tab: props.tab,
      refresh: refresh,
      pm_type: props.tab,
      active_tab: props.tab,
      list: loadedRowsForNav.value,
    })
  }
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

const column_pm = [
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
        '  <span ref="eMenu" class="ag-header-icon ag-header-cell-menu-button"></span>' +
        '  <div ref="eLabel" class="ag-header-cell-label" role="presentation">' +
        '    <input type="checkbox" id="insp-header-checkbox" style="cursor:pointer;width:14px;height:14px;" />' +
        '  </div>' +
        '</div>',
    },
  },
  {
    headerName: t('INSP Number'),
    field: 'auto_number',
    sortable: true,
    editable: false,
    resizable: true,
    pinned: 'left',
    // maxWidth: 160,
    cellRenderer: (params) => {
      return `
        <span>
          INSP #${params.data.auto_number}
        </span>
      `
    },
    onCellClicked: (params) => {
      onRowClicked(params)
    },
  },
  {
    headerName: t('INSP #'),
    field: 'template_pm',
    sortable: true,
    editable: false,
    resizable: true,
    width: 100,
    filter: 'agNumberColumnFilter',
    filterParams: {
      maxNumConditions: 1,
      filterOptions: ['equals', 'greaterThan', 'lessThan'],
      buttons: ['reset'],
    },
    cellRenderer: (params) => {
      return params.value != null ? `#${params.value}` : ''
    },
  },
  {
    headerName: t('Name'),
    field: 'name',
    sortable: true,
    editable: false,
    resizable: true,
    filter: 'agTextColumnFilter',
    filterParams: {
      textFormatter: (text) => text.toLowerCase(),
      maxNumConditions: 1,
      filterOptions: ['contains'],
      buttons: ['reset'],
    },
    // pinned: 'left',
    width: 280,
    onCellClicked: (params) => {
      onRowClicked(params)
    },
    tooltipValueGetter: (p) => p.value,
    headerTooltip: 'Work name',
  },
  {
    headerName: t('Priority'),
    field: 'priority',
    sortable: true,
    editable: false,
    maxWidth: 150,
    resizable: true,
    filter: 'agSetColumnFilter', // Enable set filter
    filterParams: {
      values: priorities.map((s) => s.value), // Provide numeric values for the filter
      valueFormatter: (params) => {
        const priority = priorities.find((s) => s.value === params.value)
        return priority ? t(priority.text) : params.value // Map numeric value to text
      },
      suppressRemoveAll: true, // Disable "Remove All" button
      checkbox: true, // Enable checkboxes in the filter
    },
    valueFormatter: (params) => {
      const priority = priorities.find((s) => s.value === params.value)
      return priority ? t(priority.text) : '' // Map numeric value to text in grid cells
    },
    cellRenderer: PriorityCellRenderer,
    cellStyle: { margin: '8px 0px 0px 4px' },
    cellClass: 'priority-cell',
  },
  {
    headerName: t('Created date'),
    field: 'date_created',
    sortable: true,
    editable: false,
    width: 150,
    valueGetter: (params) => {
      if (params.data?.date_created) {
        const date = new Date(params.data.date_created)
        return format(date, 'yyyy-MM-dd HH:mm') // Format the date
      } else {
        return ''
      }
    },
    filter: 'agDateColumnFilter',
    filterParams: filterDateParams,
  },
  {
    headerName: t('Schedule'),
    field: 'schedule_names', // API-ээс авсан өгөгдлийг энэ талбарт хадгална
    sortable: true,
    resizable: true,
    editable: false,
    width: 150,
    tooltipValueGetter: (p) => p.value,
  },
  {
    headerName: t('Times'),
    field: 'schedules_date',
    sortable: true,
    filter: false,
    editable: false,
    valueFormatter: (params) => {
      if (params.data.repeat_unit == 'daily') {
        return (params.data.schedules_date || [])
          .map((s) =>
            s.hour != null && s.min != null
              ? String(s.hour).toString().padStart(2, '0') +
                ':' +
                String(s.min).toString().padStart(2, '0')
              : '-',
          )
          .join(', ')
      } else if (params.data.repeat_unit == 'weekly') {
        return params.data.schedules_date
          .map((item) => {
            let day = ''
            if (item.date === 1) day = 'Mon'
            else if (item.date === 2) day = 'Tue'
            else if (item.date === 3) day = 'Wed'
            else if (item.date === 4) day = 'Thu'
            else if (item.date === 5) day = 'Fri'
            else if (item.date === 6) day = 'Sat'
            else if (item.date === 7) day = 'Sun'

            const time =
              item.hour != null && item.min != null
                ? String(item.hour).toString().padStart(2, '0') +
                  ':' +
                  String(item.min).toString().padStart(2, '0')
                : '-'

            return `${day} ${time}`
          })
          .join(', ')
      } else if (params.data.repeat_unit == 'monthly') {
        return (params.data.schedules_date || [])
          .map((s) => {
            const date = s.date ? String(s.date) : 'Unknown'
            const time =
              s.hour != null && s.min != null
                ? String(s.hour).toString().padStart(2, '0') +
                  ':' +
                  String(s.min).toString().padStart(2, '0')
                : '-'
            return `${date}th ${time}`
          })
          .join(', ')
      } else if (params.data.repeat_unit == 'yearly') {
        return params.data.schedules_date
          .map((s) => {
            const dateStr =
              s.month && s.date ? `${s.month}/${s.date}` : 'Invalid Date'
            const time =
              s.hour != null && s.min != null
                ? String(s.hour).toString().padStart(2, '0') +
                  ':' +
                  String(s.min).toString().padStart(2, '0')
                : '-'
            return `${dateStr} ${time}`
          })
          .join(', ')
      }
    },
  },
  {
    headerName: t('Accept'),
    field: 'action_status',
    sortable: true,
    editable: false,
    resizable: true,

    width: 180,
    filter: 'agSetColumnFilter', // Enable set filter
    filterParams: {
      values: action_status.map((s) => s.id), // Provide numeric values for the filter
      valueFormatter: (params) => {
        let aaction = action_status.find((s) => s.id === params.value)
        return aaction ? t(aaction.name) : params.value // Map numeric value to text
      },
      suppressRemoveAll: true, // Disable "Remove All" button
      checkbox: true, // Enable checkboxes in the filter
    },
    valueFormatter: (params) => {
      let aaction = action_status.find((s) => s.id === params.value)
      return aaction ? t(aaction.name) : ''
    },
    cellRenderer: PriorityCellRenderer,
  },
  {
    headerName: t('Assign to'),
    field: 'assigned_to.first_name',
    sortable: true,
    editable: false,
    width: 160,
    filter: 'agTextColumnFilter',
    filterParams: {
      textFormatter: (text) => text.toLowerCase(),
      maxNumConditions: 1,
      filterOptions: ['contains'],
      buttons: ['reset'],
    },
  },
  {
    headerName: t('Shift User'),
    field: 'shift_user_name',
    sortable: true,
    editable: false,
    width: 160,
    filter: 'agTextColumnFilter',
    filterParams: {
      textFormatter: (text) => text.toLowerCase(),
      maxNumConditions: 1,
      filterOptions: ['contains'],
      buttons: ['reset'],
    },
    tooltipValueGetter: (p) => p.value,
  },
  {
    headerName: t('Actions'),
    maxWidth: 120,
    sortable: false,
    filter: false,
    cellEditorPopup: true,
    // pinned: 'right',
    cellRenderer: ActionDropdownCellRenderer,
    cellRendererParams: (params) => {
      let actions = {
        onEditClick: false,
        onReturnClick: false,
        onDeleteClick: false,
        onCompleteClick: false,
        onApproveClick: false,
        onAssignClick: false,
        onAcceptClick: false,
        onStart: false,
        module: 'inspection',
      }
      // actions.onDeleteClick = do_delete
      if (props.tab == 'inspection_templates') {
        actions.onDeleteClick = do_delete

        if (params.data.action_status === 2) {
          //approved
          actions.onStart = do_start
          actions.onReturnClick = do_return
        }
        if (params.data.action_status !== 2) {
          //returned, creared, assiged
          actions.onAssignClick = do_assign
          actions.onApproveClick = do_approve
        }
      }

      if (props.tab == 'delivered') {
        actions.onDeleteClick = do_delete
        actions.onCompleteClick = do_complete

        // if (params.data.action_status === 2) {
        //   //approved
        //   actions.onReturnClick = do_return
        // }
        // if (params.data.action_status !== 2) {
        //   actions.onAcceptClick = do_approved_wo
        //   // actions.onApproveClick = do_approve
        // }
      }

      if (props.tab == 'completed') {
        actions.onAcceptClick = do_accept_wo
      }

      return actions
    },
    cellClass: 'actions-cell',
    cellStyle: {
      // 'background-color': 'green',
    },
  },
]

if (props.type == 'inspection') {
  if (props.tab == 'delivered') {
    // delivered: template_pm харуулна, schedules_date/schedule_names хасна
    columnDefs.value = column_pm.filter(
      (col) => col.field !== 'schedules_date' && col.field !== 'schedule_names',
    )
  } else if (props.tab == 'completed') {
    // completed: template_pm болон schedules_date/schedule_names хасна
    const completedCols = column_pm.filter(
      (col) =>
        col.field !== 'schedules_date' &&
        col.field !== 'schedule_names' &&
        col.field !== 'template_pm',
    )
    columnDefs.value = completedCols.map((col) => {
      if (col.field === 'action_status') {
        return {
          ...col,
          headerName: t('Status'),
          valueGetter: () => 7, // action_status id=7 → 'completed'
        }
      }
      return col
    })
  } else if (props.tab == 'inspection_templates') {
    // inspection_templates: template_pm болон shift_user_name хасна
    columnDefs.value = column_pm.filter(
      (col) => col.field !== 'shift_user_name' && col.field !== 'template_pm',
    )
  } else {
    // бусад таб: template_pm хасна
    columnDefs.value = column_pm.filter((col) => col.field !== 'template_pm')
  }
}

async function fetchScheduleData(rowData) {
  const requests = rowData.map(async (row) => {
    const filters = {
      status: 'Active',
      work_order: row.id,
      // schedule_id: { _nnull: true },
    }

    const sch_items = await getItems({
      collection: 'Work_inspection_schedules',
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*', 'schedule_id.*', 'schedules_date.*'],
      },
    })

    if (sch_items.data && sch_items.data.length > 0) {
      const schedule_names =
        sch_items.data
          .map((s) => {
            if (s.schedule_id) {
              return s.schedule_id.name
            } else {
              return s.name + ' - ' + s.repeat_types + ', ' + s.repeat_unit
            }
          })
          .join(', ') || ''

      // Collect all schedules_date and repeat_unit data
      const allSchedulesDate = []
      let firstRepeatUnit = null

      sch_items.data.forEach((schedule) => {
        if (schedule.repeat_unit) {
          firstRepeatUnit = schedule.repeat_unit
        }
        if (schedule.schedules_date && Array.isArray(schedule.schedules_date)) {
          allSchedulesDate.push(...schedule.schedules_date)
        }
      })

      return {
        row,
        schedule_names,
        schedules_date: allSchedulesDate,
        repeat_unit: firstRepeatUnit,
      }
    }
  })

  // 🚀 Бүх хүсэлтийг зэрэг гүйцэтгэнэ
  const results = await Promise.all(requests)
  // console.log('requests results:', results)

  // 🎯 `rowData`-г шинэчлэнэ
  results.forEach((result) => {
    if (result) {
      const { row, schedule_names, schedules_date, repeat_unit } = result
      row.schedule_names = schedule_names
      row.schedules_date = schedules_date
      row.repeat_unit = repeat_unit
    }
  })
}

async function fetchShiftUserData(rowData) {
  const requests = rowData.map(async (row) => {
    const filters = {
      work_order: row.id,
    }

    const shift_user_items = await getItems({
      collection: 'Work_inspection_users',
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*', 'shift_user.*'],
      },
    })

    if (shift_user_items.data && shift_user_items.data.length > 0) {
      const shift_user_name =
        shift_user_items.data
          ?.map((s) => (s.shift_user ? s.shift_user.first_name : '-'))
          .join(', ') || '-'

      return {
        row,
        shift_user_name,
      }
    }

    return {
      row,
      shift_user_name: '-',
    }
  })

  const results = await Promise.all(requests)

  results.forEach((result) => {
    if (result) {
      const { row, shift_user_name } = result
      row.shift_user_name = shift_user_name
    }
  })
}

const onGridReady = (params) => {
  // Restore column state on grid load
  // console.log('_onGridReady_props -->', params)

  let save_state = props.type
  if (save_state == 'inspection') {
    save_state = props.tab
  }

  const savedState = localStorage.getItem(save_state)
  const savedStatePageSize = localStorage.getItem(props.type + '_pagesize')

  if (savedState) {
    const state = JSON.parse(savedState)
    params.api.applyColumnState({ state: state, applyOrder: true })
  }

  if (savedStatePageSize) {
    try {
      // Try multiple methods
      if (params.api.paginationSetPageSize) {
        params.api.paginationSetPageSize(savedStatePageSize)
      } else if (params.api.setGridOption) {
        params.api.setGridOption('paginationPageSize', savedStatePageSize)
      } else {
        gridOptions.paginationPageSize = savedStatePageSize
      }
    } catch (error) {
      console.error('Error setting page size:', error)
    }
  }

  // params.api.sizeColumnsToFit()
  // Grid api
  // const openedPanel = params.api.getOpenedToolPanel()
  // const showAdvancedFilter = params.api.showAdvancedFilterBuilder()
  // const showContextMenu = params.api.showContextMenu()
  // const pinned = params.api.setPinnedTopRowData()

  // // Grid api
  // console.log('openedPanel->', openedPanel)
  // console.log('showAdvancedFilter->', showAdvancedFilter)
  // console.log('showContextMenu->', showContextMenu)
  // console.log('pinned->', pinned)

  // topRowPinned, status bar,  menu Item component deer pinned oruulah

  gridApi.value = params.api
  gridOptions.api = params.api

  // Custom header checkbox — current page only
  nextTick(() => {
    const cb = document.querySelector(
      '#insp-header-checkbox',
    ) as HTMLInputElement | null
    if (cb) {
      cb.addEventListener('change', () => {
        const nodes = params.api.getRenderedNodes?.() ?? []
        nodes.forEach((n: any) => n.setSelected(cb.checked))
      })
    }
  })

  dataSource.value = {
    getRows: async (params) => {
      const { startRow, endRow, sortModel } = params.request
      const filterModel = gridApi.value.getFilterModel()
      const sortField = sortModel.length ? sortModel[0].colId : null
      const sortOrder = sortModel.length ? sortModel[0].sort : null

      let filter_user = await filterUser(filterModel)
      let filter_initial = { ...filterBuild(filterModel), ...filter_user }
      console.log('filter_initial_insp', filter_initial)
      // console.log('params', params)

      fetchPageData({
        currentPage: Math.floor(startRow / paginationPageSize.value) + 1,
        pageSize: paginationPageSize.value,
        sortField: sortField,
        sortOrder: sortOrder,
        search: quickFilterText.value,
        searchField: 'name',
        collection: 'Work_inspections',
        fields: [
          '*',
          'assigned_to.*',
          'wo_status.*',
          'schedule.*',
          'type.*',
          'template_pm.*',
          'wo_status.code_color.*',
          'completed_user.first_name',
        ],
        filters: filter_initial,
      })
        .then((response) => {
          // console.log('response', response)
          const rowsThisPage = response.data
          const lastRow = response.totalCount

          if (props.type === 'inspection') {
            let rowData = response.data
            totalRows.value = lastRow
            fetchScheduleData(rowData).then(async () => {
              // Fetch shift_user data for delivered tab
              if (props.tab === 'delivered' || props.tab === 'completed') {
                await fetchShiftUserData(rowData)
              }
              loadedRowsForNav.value = rowData
              params.success({
                rowData: rowData, // Use the updated row data
                rowCount: lastRow, // Total row count for pagination
              })
              if (lastRow === 0) params.api?.showNoRowsOverlay()
              else params.api?.hideOverlay()
            })
            return
          }

          totalRows.value = lastRow
          loadedRowsForNav.value = rowsThisPage
          params.success({
            rowData: rowsThisPage,
            rowCount: lastRow,
          })
          if (lastRow === 0) params.api?.showNoRowsOverlay()
          else params.api?.hideOverlay()
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
  rowModelType: 'serverSide', // Important for server-side pagination
  paginationPageSize: 10, // Start with 10 rows per page
  cacheBlockSize: 10, // Set fetch size to 10 rows per block
  pagination: true,
  paginationPageSizeSelector: [10, 20, 30, 50, 70, 100],
  serverSideDatasource: dataSource.value,
  rowSelection: 'multiple', // Enable multiple row selection
  suppressRowClickSelection: true, // Prevent row selection on row click
  rowMultiSelectWithClick: true, // Allow selecting multiple rows with clicks
  animateRows: false,
  tooltipShowDelay: 0,
  tooltipHideDelay: 2000,
  defaultColDef: {
    flex: 1,
  },

  getMainMenuItems: (params: GetMainMenuItemsParams) => {
    // console.log('menuItem->', params)
    return [
      ...params.defaultItems,
      'separator',
      {
        name: 'Click Alert Button and Close Menu',
        menuItem: 'MenuItem',
        menuItemParams: {
          buttonValue: 'Alert',
        },
      },
    ]
  },
  getContextMenuItems: (params: GetContextMenuItemsParams) => {
    // console.log('menuItem_1 ->', params)
    let defaults = params.defaultItems
    let options = [
      'copy',
      'copyWithHeaders',
      'export',
      'pinSubMenu',
      'autoSizeAll',
    ]
    return [
      ...(options || []),
      'separator',
      {
        name: 'Print',
        menuItem: 'MenuItem',
        menuItemParams: {
          buttonValue: 'Alert',
        },
      },
    ]
  },
  onPaginationChanged: (params) => {
    nextTick(() => updateSelectionBadge(params.api))
    changePaginationSize(params.api.paginationGetPageSize())
  },
}

function updateSelectionBadge(api?: any) {
  const panel =
    (api ?? gridApi.value)
      ?.getGridOption?.('context')
      ?.__gridContainer?.querySelector('.ag-paging-panel') ??
    document.querySelector('.Work_inspection_list .ag-paging-panel')
  if (!panel) return
  let el = panel.querySelector('#insp-selected-count') as HTMLElement | null
  if (!el) {
    el = document.createElement('span')
    el.id = 'insp-selected-count'
    el.style.cssText =
      'margin-right:16px;font-size:12px;font-weight:600;display:flex;align-items:center;gap:4px;white-space:nowrap;color:inherit;'
    panel.insertBefore(el, panel.firstChild)
  }
  if (selectedCount.value > 0) {
    el.textContent = `☑ ${selectedCount.value} selected`
    el.style.display = 'flex'
  } else {
    el.style.display = 'none'
  }
}

function selectionChanged(event) {
  const rendered = event.api.getRenderedNodes?.() ?? []
  selectedCount.value = rendered.filter((n: any) => n.isSelected()).length
  // header checkbox sync
  const cb = document.querySelector(
    '#insp-header-checkbox',
  ) as HTMLInputElement | null
  if (cb) {
    const total = rendered.length
    cb.checked = selectedCount.value > 0 && selectedCount.value === total
    cb.indeterminate = selectedCount.value > 0 && selectedCount.value < total
  }
  updateSelectionBadge(event.api)
}

const saveColumnState = (params: any) => {
  let save_state = props.type
  if (save_state == 'inspection') {
    save_state = props.tab
  }
  const columnState = params.api.getColumnState()
  localStorage.setItem(save_state, JSON.stringify(columnState))
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

const filterUser = async (filterModel) => {
  let filters = {}
  if (
    filterModel['assigned_to.first_name'] &&
    filterModel['assigned_to.first_name'].filter.length > 3
  ) {
    async function getUserIdsByFirstName(firstName) {
      const response = await fetch(
        runtimeConfig.public.directus.url +
          `users?filter[first_name][_icontains]=${firstName}`,
        {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token.value}`,
          },
        },
      )

      const data = await response.json()
      return data.data.map((user) => user.id)
    }

    const firstNameFilter = filterModel['assigned_to.first_name'].filter

    const userIds = await getUserIdsByFirstName(firstNameFilter)
    filters['assigned_to'] = {
      _in: userIds,
    }

    // console.log('userIds', userIds)
  }

  return filters
}

// Filter functions
const filterBuild = (filterModel) => {
  let filters: any = {
    active: '1',
  }

  let wo_status_filter = wo_status
  // console.log('wo_status_filter', wo_status_filter, wo_status)

  if (props.status) {
    // console.log('filterModel', filterModel)
    // console.log('wo_status_oruulah', props.wo_status)
    // console.log('wo_status_items', props.wo_status_items)
    // console.log('_status', props.status)
    // Status override
    // if (
    //   filterModel.status &&
    //   filterModel.status.values &&
    //   filterModel.status.values.length > 0
    // ) {
    //   filters['status'] = { _in: filterModel.status.values }
    // } else {
    //   filters['status'] = props.status
    // }

    if (
      filterModel.wo_status &&
      filterModel.wo_status.values &&
      filterModel.wo_status.values.length > 0
    ) {
      filters['wo_status'] = { _in: filterModel.wo_status.values }
    } else {
      // console.log('endee')
      filters['wo_status'] = wo_status_filter
    }
  }

  if (filterModel.id && filterModel.id.filter) {
    let searchId = filterModel.id.filter
    let type = filterModel.id.type
    if (type === 'inRange') {
      filters['id'] = {
        _between: [searchId, filterModel.id.filterTo],
      }
    } else if (type === 'equals') {
      filters['id'] = searchId
    } else if (type === 'lessThan') {
      filters['id'] = {
        _lte: searchId,
      }
    } else if (type === 'greaterThan') {
      filters['id'] = {
        _gte: searchId,
      }
    } else if (type === 'notEqual') {
      filters['id'] = {
        _neq: searchId,
      }
    }
  }

  if (filterModel.name && filterModel.name.filter) {
    filters['name'] = { _icontains: filterModel.name.filter }
  }

  if (filterModel.action_status && filterModel.action_status.values) {
    filters['action_status'] = { _in: filterModel.action_status.values }
  }

  if (filterModel.wo_status && filterModel.wo_status.values) {
    filters['wo_status'] = { _in: filterModel.wo_status.values }
  }

  if (filterModel.priority && filterModel.priority.values) {
    filters['priority'] = {
      _in: filterModel.priority.values.map((value) =>
        parseInt(value.replace(/\D/g, ''), 10),
      ),
    }
  }

  if (filterModel.printed && filterModel.printed.values) {
    filters['printed'] = filterModel.printed.values[0] == 1 ? true : false
  }

  if (filterModel.date_created) {
    const createdAtt = filterModel.date_created
    if (createdAtt.dateFrom || createdAtt.dateTo) {
      if (createdAtt.type === 'inRange') {
        filters['date_created'] = {
          _between: [createdAtt.dateFrom, createdAtt.dateTo],
        }
      } else if (createdAtt.type === 'equals') {
        filters['date_created'] = {
          _in: [createdAtt.dateFrom],
        }
      } else if (createdAtt.type === 'lessThan') {
        filters['date_created'] = {
          _lte: createdAtt.dateFrom,
        }
      } else if (createdAtt.type === 'greaterThan') {
        filters['date_created'] = {
          _gte: createdAtt.dateFrom,
        }
      } else if (createdAtt.type === 'notEqual') {
        filters['date_created'] = {
          _neq: createdAtt.dateFrom,
        }
      }
    }
    // 3. Хэрэв формат танигдахгүй бол
    else {
      console.log('Unknown transaction_date format', createdAtt)
    }
  }

  if (filterModel.due) {
    const duedate = filterModel.due
    if (duedate.dateFrom || duedate.dateTo) {
      if (duedate.type === 'equals') {
        // console.log('duedate.dateFrom', duedate.dateFrom)
        const start = duedate.dateFrom.split(' ')[0] + 'T00:00:00'
        const end = duedate.dateFrom.split(' ')[0] + 'T23:59:59.999'
        filters['due'] = {
          _between: [start, end],
        }
      } else if (duedate.type === 'lessThan') {
        filters['due'] = {
          _lt: duedate.dateFrom.split(' ')[0] + 'T00:00:00',
        }
      } else if (duedate.type === 'greaterThan') {
        filters['due'] = {
          _gt: duedate.dateFrom.split(' ')[0] + 'T23:59:59.999',
        }
      } else if (duedate.type === 'notEqual') {
        filters['due'] = {
          _or: [
            { _lt: duedate.dateFrom.split(' ')[0] + 'T00:00:00' },
            { _gt: duedate.dateFrom.split(' ')[0] + 'T23:59:59.999' },
          ],
        }
      } else if (duedate.type === 'inRange') {
        const start = duedate.dateFrom.split(' ')[0] + 'T00:00:00'
        const end = duedate.dateTo.split(' ')[0] + 'T23:59:59.999'
        filters['due'] = {
          _between: [start, end],
        }
      }
      // if (duedate.type === 'inRange') {
      //   filters['due'] = {
      //     _between: [duedate.dateFrom, duedate.dateTo],
      //   }
      // } else if (duedate.type === 'equals') {
      //   filters['due'] = {
      //     _in: [duedate.dateFrom],
      //   }
      // } else if (duedate.type === 'lessThan') {
      //   filters['due'] = {
      //     _lte: duedate.dateFrom,
      //   }
      // } else if (duedate.type === 'greaterThan') {
      //   filters['due'] = {
      //     _gte: duedate.dateFrom,
      //   }
      // } else if (duedate.type === 'notEqual') {
      //   filters['due'] = {
      //     _neq: duedate.dateFrom,
      //   }
      // }
    }
    // 3. Хэрэв формат танигдахгүй бол
    else {
      console.log('Unknown transaction_date format', duedate)
    }
  }

  if (filterModel.completed_at) {
    const completedate = filterModel.completed_at
    if (completedate.dateFrom || completedate.dateTo) {
      if (completedate.type === 'inRange') {
        filters['completed_at'] = {
          _between: [completedate.dateFrom, completedate.dateTo],
        }
      } else if (completedate.type === 'equals') {
        filters['completed_at'] = {
          _in: [completedate.dateFrom],
        }
      } else if (completedate.type === 'lessThan') {
        filters['completed_at'] = {
          _lte: completedate.dateFrom,
        }
      } else if (completedate.type === 'greaterThan') {
        filters['completed_at'] = {
          _gte: completedate.dateFrom,
        }
      } else if (completedate.type === 'notEqual') {
        filters['completed_at'] = {
          _neq: completedate.dateFrom,
        }
      }
    }
    // 3. Хэрэв формат танигдахгүй бол
    else {
      console.log('Unknown transaction_date format', completedate)
    }
  }

  if (props.location) {
    filters['location'] = props.location
  }

  // PM list filter
  if (props.type == 'inspection') {
    // completed = hoish
    // generated = direct
    // filters['wo_status'] = open_wo_status
    filters.created_type = 'inspection'

    if (props.tab == 'inspection_templates') {
      // filters.pm_type = 'pm' // ene string type
      filters['pm_type'] = { _in: ['inspection'] } // ene dropdown type
    }
    if (props.tab == 'delivered') {
      filters.created_type = 'ins_generated'
      filters['wo_status'] = open_wo_status
      filters['pm_type'] = { _in: ['delivered', 'generated', 'completed'] }
    }
    if (props.tab == 'completed') {
      filters.created_type = 'ins_generated'
      filters['wo_status'] = completed_wo_status
      filters['pm_type'] = { _in: ['delivered', 'generated', 'completed'] }
    }
  }
  return filters
}

const do_edit = (item) => {
  open('inspectionmore', {
    id: item.id,
    data: item,
    wo_statuses: props.wo_status_items,
    type: props.type,
    refresh: refresh,
    active_tab: props.tab,
  })
}

const do_delete = (item) => {
  current_row.value = item
  isModalConfirmOpen.value = true
}

const do_complete = (item) => {
  current_row.value = item
  console.log('do_complete')

  // console.log('do_make_items', asset_code.value)
  // console.log('cDate', cDate.value)
  // console.log('cDateTime', cDateTime.value)

  const completed_status = wo_status_items.find(
    (item) =>
      item?.type?.toLowerCase() === 'completed' ||
      item?.status_text?.toLowerCase() === 'completed',
  )

  const updateData = {
    collection: 'Work_inspections',
    id: item.id,
    item: {
      status: '3',
      wo_status: completed_status.id,
      completed_at: new Date().toISOString(),
    },
  }

  updateItem(updateData).then((res) => {
    console.log('Updated')
    // router.push(`/inspection/location/completed/${params.id}`)
  })
  refresh(item)
}

const do_approve = async (item) => {
  console.log('do_approve')
  actionType.value = 'do_approve'

  // Fetch latest record from backend to avoid stale grid row data
  let latestItem = null
  try {
    const latest = await getItems<any>({
      collection: 'Work_inspections',
      params: {
        filter: { id: item.id },
        fields: [
          'id',
          'asset',
          'location',
          'assigned_team',
          'assigned_to',
          'priority',
          'type',
          'work_type',
          'department',
        ],
        limit: 1,
      },
    })
    latestItem = Array.isArray(latest) ? latest[0] : latest?.data?.[0]
  } catch (e) {
    console.log('approve field check error', e)
  }

  if (!latestItem) {
    toaster.show({
      title: t('Error'),
      message: t('Failed to fetch work order data'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  const missingFields: string[] = []
  // if (latestItem.asset == null) missingFields.push(t('Asset'))
  if (latestItem.location == null) missingFields.push(t('Location'))
  if (latestItem.assigned_team == null) missingFields.push(t('Team'))
  if (latestItem.priority == null) missingFields.push(t('Priority'))
  if (latestItem.type == null) missingFields.push(t('Group Type'))
  if (latestItem.work_type == null) missingFields.push(t('Work Type'))
  if (latestItem.department == null) missingFields.push(t('Department'))

  if (missingFields.length > 0) {
    toaster.show({
      title: t('Warning'),
      message:
        t('Please fill in required fields before approving') +
        ': ' +
        missingFields.join(', '),
      color: 'warning',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  // Check Work_inspection_schedules
  try {
    const schedules = await getItems<any>({
      collection: 'Work_inspection_schedules',
      params: {
        filter: { work_order: { _eq: item.id } },
        fields: ['id'],
        limit: 1,
      },
    })
    const scheduleList = Array.isArray(schedules)
      ? schedules
      : (schedules as any)?.data ?? []
    if (scheduleList.length === 0) {
      toaster.show({
        title: t('Warning'),
        message: t('No schedule linked to this inspection template'),
        color: 'warning',
        icon: 'ph:warning-circle-fill',
        closable: true,
      })
      return
    }
  } catch (e) {
    console.log('schedule check error', e)
  }

  // Check Work_inspection_users
  try {
    const users = await getItems<any>({
      collection: 'Work_inspection_users',
      params: {
        filter: { work_order: { _eq: item.id } },
        fields: ['id'],
        limit: 1,
      },
    })
    const userList = Array.isArray(users) ? users : (users as any)?.data ?? []
    if (userList.length === 0) {
      toaster.show({
        title: t('Warning'),
        message: t('No users linked to this inspection template'),
        color: 'warning',
        icon: 'ph:warning-circle-fill',
        closable: true,
      })
      return
    }
  } catch (e) {
    console.log('users check error', e)
  }

  const do_returned = await createItems({
    collection: 'Work_inpection_actions',
    items: {
      wo_id: item.id,
      first_user: myId,
      action_status: 2,
      company_id: myCompanyId,
    },
  })

  const data = {
    collection: 'Work_inspections',
    id: item.id,
    item: { action_status: 2 },
  }
  await updateItem(data)

  refresh(item)
}

const do_return = async (item, type) => {
  actionType.value = 'do_return'
  const do_returned = await createItems({
    collection: 'Work_inpection_actions',
    items: {
      wo_id: item.id,
      first_user: myId,
      action_status: 3,
      company_id: myCompanyId,
    },
  })

  let updateData = {}
  if (type == 'request') {
    updateData = {
      accepted_user: null,
      type: 3, //???
      is_accepted: false,
      action_status: 3,
    }
  }

  if (type == 'open') {
    updateData = { action_status: 3 }
  }
  if (type == 'pm' || type == 'inspection') {
    updateData = { action_status: 3 }
  }

  const data = {
    collection: 'Work_inspections',
    id: item.id,
    item: updateData,
  }

  await updateItem(data)
  refresh(item)
}

const do_decline = async (item, type) => {
  actionType.value = 'do_decline'
  const do_returned = await createItems({
    collection: 'Work_inpection_actions',
    items: {
      wo_id: item.id,
      first_user: myId,
      action_status: 6,
      company_id: myCompanyId,
    },
  })

  let updateData = {
    accepted_user: null,
    type: 3, //???
    is_accepted: false,
    action_status: 6,
  }

  const data = {
    collection: 'Work_inspections',
    id: item.id,
    item: updateData,
  }

  await updateItem(data)
  refresh(item)
}

const do_assign = (item) => {
  actionType.value = 'do_assign'
  isModalUserListOpen.value = true
  current_row.value = item
}

const do_accept = async (item) => {
  actionType.value = 'do_accept'

  const do_accepted = await createItems({
    collection: 'Work_inpection_actions',
    items: {
      wo_id: item.id,
      first_user: myId,
      action_status: 5,
      company_id: myCompanyId,
    },
  })

  const data = {
    collection: 'Work_inspections',
    id: item.id,
    item: {
      action_status: 5,
      accepted_user: myId,
      type: 2, //????
      is_accepted: true,
      accept_info: {
        date: new Date().toISOString(),
        user_id: myId,
        user_name:
          (user.value?.first_name ?? '') + ' ' + (user.value?.last_name ?? ''),
        action_type: 'accept',
        source:
          t('type') +
          ' :' +
          props.type +
          (props.location ? ' ' + t('location') + ' :' + props.location : ''),
      },
    },
  }

  await updateItem(data)
  refresh(item)
}

const do_approved_wo = async (item) => {
  actionType.value = 'do_approved_wo'
  isModalApproveConfirmOpen.value = true
  itemsValue.value = item
  selectedItem.value = item.id
}

const do_accept_wo = async (item) => {
  actionType.value = 'do_accept_wo'

  // Fetch latest record to validate required fields
  let latestItem = null
  try {
    const latest = await getItems<any>({
      collection: 'Work_inspections',
      params: {
        filter: { id: item.id },
        fields: [
          'id',
          'asset',
          'location',
          'assigned_team',
          'assigned_to',
          'priority',
          'type',
          'work_type',
          'department',
        ],
        limit: 1,
      },
    })
    latestItem = Array.isArray(latest) ? latest[0] : latest?.data?.[0]
  } catch (e) {
    console.log('do_accept_wo field check error', e)
  }

  if (!latestItem) {
    toaster.show({
      title: t('Error'),
      message: t('Failed to fetch inspection data'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  const missingFields: string[] = []
  // if (latestItem.asset == null) missingFields.push(t('Asset'))
  if (latestItem.location == null) missingFields.push(t('Location'))
  if (latestItem.assigned_team == null) missingFields.push(t('Team'))
  if (latestItem.priority == null) missingFields.push(t('Priority'))
  if (latestItem.type == null) missingFields.push(t('Group Type'))
  if (latestItem.work_type == null) missingFields.push(t('Work Type'))
  if (latestItem.department == null) missingFields.push(t('Department'))

  if (missingFields.length > 0) {
    toaster.show({
      title: t('Warning'),
      message:
        t('Please fill in required fields before approving') +
        ': ' +
        missingFields.join(', '),
      color: 'warning',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  isModalApproveConfirmOpen.value = true
  itemsValue.value = item
  selectedItem.value = item.id
}

// Work_inspection_* коллекцийн бичлэгүүдийг Work_order_* коллекц руу хуулна
// (id болон Directus-ийн автомат талбаруудыг хасаж, work_order холбоосыг шинэ WO рүү оноож)
const copyRelatedRecords = async (
  sourceCollection,
  targetCollection,
  sourceWoId,
  targetWoId,
  // *_item collection-ууд (Work_order_item/Work_inspection_item г.м) FK
  // талбараа "workorder" (доогуур зурааcгүй) гэж нэрлэдэг, харин бусад бүх
  // *_Parts/*_Tradecode/*_comments/*_files collection "work_order" (доогуур
  // зурааcтай) ашигладаг тул дуудах бүрд зөв нэрийг нь дамжуулна.
  woField = 'work_order',
) => {
  try {
    const res = await getItems<any>({
      collection: sourceCollection,
      params: {
        filter: { [woField]: { _eq: sourceWoId } },
        limit: -1,
        fields: ['*'],
      },
    })
    const records = Array.isArray(res) ? res : res?.data ?? []
    if (!records.length) return

    // *_item collection-ууд эцэг/хүүхэд (parent+pos) шаталсан бүтэцтэй тул
    // хуучин id-руу заасан parent-ыг шууд хуулж болохгүй — эхлээд parent-гүй
    // үүсгээд, хуучин→шинэ id зураглалаар parent-ыг нь дараа нь тохируулна.
    const newItems = records.map((r) => {
      const {
        id,
        user_created,
        date_created,
        user_updated,
        date_updated,
        parent,
        ...rest
      } = r
      const payload: Record<string, any> = {
        ...rest,
        [woField]: targetWoId,
        company_id: myCompanyId,
      }
      if ('parent' in r) payload.parent = null
      return payload
    })

    const created = await createItems({
      collection: targetCollection,
      items: newItems,
    })
    const createdList = Array.isArray(created) ? created : created?.data ?? []

    const idMap: Record<number, number> = {}
    records.forEach((r, i) => {
      const newId = createdList[i]?.id
      if (newId != null) idMap[r.id] = newId
    })

    await Promise.all(
      records.map((r, i) => {
        if (r.parent == null) return null
        const newParentId = idMap[r.parent]
        const newOwnId = createdList[i]?.id
        if (newParentId == null || newOwnId == null) return null
        return updateItem({
          collection: targetCollection,
          id: newOwnId,
          item: { parent: newParentId },
        })
      }),
    )
  } catch (e) {
    console.log(`copy ${sourceCollection} -> ${targetCollection} error`, e)
  }
}

const do_make = async (item, type) => {
  console.log('Work_inpection_actions', item, type)

  if (type == 'do_accept_wo') {
    // 1. Work_inspections-ийн бүрэн мэдээллийг татна
    let insItem = null
    try {
      const latest = await getItems<any>({
        collection: 'Work_inspections',
        params: {
          filter: { id: item.id },
          fields: ['*'],
          limit: 1,
        },
      })
      insItem = Array.isArray(latest) ? latest[0] : latest?.data?.[0]
    } catch (e) {
      console.log('do_make: fetch Work_inspections error', e)
    }

    if (!insItem) {
      toaster.show({
        title: t('Error'),
        message: t('Failed to fetch inspection data'),
        color: 'danger',
        icon: 'ph:warning-circle-fill',
        closable: true,
      })
      return
    }

    // 2. Work_order шинэ бичлэг үүсгэнэ
    const newWo = await createItems({
      collection: 'Work_order',
      items: [
        {
          name: insItem.name,
          asset: insItem.asset,
          location: insItem.location,
          assigned_team: insItem.assigned_team,
          assigned_to: insItem.assigned_to,
          priority: insItem.priority,
          type: insItem.type,
          work_type: insItem.work_type,
          department: insItem.department,
          history_description: insItem.history_description,
          safety_notes: insItem.safety_notes,
          budget: insItem.budget,
          budget_actual_amount: insItem.budget_actual_amount,
          budget_planned_amount: insItem.budget_planned_amount,
          other_amount: insItem.other_amount,
          status: 1,
          wo_status: open_status_id,
          action_status: 2, // approved
          created_type: 'ins_generated',
          wo_prefix: 'INSP',
          is_accepted: true,
          accepted_user: myId,
          source_ins: item.id,
          accept_info: {
            date: new Date().toISOString(),
            user_id: myId,
            user_name:
              (user.value?.first_name ?? '') +
              ' ' +
              (user.value?.last_name ?? ''),
            action_type: 'accept INSP to WO',
            source:
              t('type') +
              ' :' +
              props.type +
              (props.location
                ? ' ' + t('location') + ' :' + props.location
                : ''),
          },
          company_id: myCompanyId,
        },
      ],
    })

    const newWoId = Array.isArray(newWo) ? newWo[0]?.id : newWo?.data?.[0]?.id
    const newWoNumber = Array.isArray(newWo)
      ? newWo[0]?.wo_number
      : newWo?.data?.[0]?.id

    if (!newWoId) {
      toaster.show({
        title: t('Error'),
        message: t('Failed to create Work Order'),
        color: 'danger',
        icon: 'ph:warning-circle-fill',
        closable: true,
      })
      return
    }

    // 3. Work_order_actions лог
    await createItems({
      collection: 'Work_order_actions',
      items: {
        wo_id: newWoId,
        first_user: myId,
        action_status: 2,
        type: 'ins_generated',
        company_id: myCompanyId,
      },
    })

    // 4. Work_inpection_Parts, Work_inspection_Tradecode, Work_inspection_comments, Work_inspection_files — Work_order_* руу хуулна
    await copyRelatedRecords(
      'Work_inspection_item',
      'Work_order_item',
      item.id,
      newWoId,
      'workorder',
    )
    await copyRelatedRecords(
      'Work_inpection_Parts',
      'Work_order_Parts',
      item.id,
      newWoId,
    )
    await copyRelatedRecords(
      'Work_inspection_Tradecode',
      'Work_order_Tradecode',
      item.id,
      newWoId,
    )
    await copyRelatedRecords(
      'Work_inspection_comments',
      'Work_order_comments',
      item.id,
      newWoId,
    )
    await copyRelatedRecords(
      'Work_inspection_files',
      'Work_order_files',
      item.id,
      newWoId,
    )

    // 5. Work_inspections-ийг completed болгоно
    await updateItem({
      collection: 'Work_inspections',
      id: item.id,
      item: {
        pm_type: 'completed',
        action_status: 2,
        is_accepted: true,
        accepted_user: myId,
      },
    })

    toaster.show({
      title: t('Success'),
      message: t('Work Order created successfully') + ' #' + newWoNumber,
      color: 'success',
      icon: 'ph:check-circle-fill',
      closable: true,
    })

    refresh(item)
    return
  }

  if (type == 'do_approved_wo') {
    let do_approved = await createItems({
      collection: 'Work_inpection_actions',
      items: {
        wo_id: item.id,
        first_user: myId,
        action_status: 2, //approved
        company_id: myCompanyId,
      },
    })

    const data = {
      collection: 'Work_inspections',
      id: item.id,
      item: {
        action_status: 2, //approved
        type: 2,
        wo_status: open_status_id,
        accepted_user: myId,
        is_accepted: true,
      },
    }

    // console.log('data', data)

    await updateItem(data)
    refresh(item)
  }
}

const do_start = async (item) => {
  const filters = {
    status: 'Active',
    work_order: item?.id,
  }
  const sch_items = await getItems<any>({
    collection: 'Work_inspection_schedules',
    params: {
      filter: filters,
      meta: 'filter_count',
      fields: ['*', 'schedule_id.*'],
    },
  })

  // console.log('sch_items', sch_items, sch_items.data[0])
  if (sch_items.data.length == 0) {
    toaster.show({
      title: t('Error'),
      message: 'No schedule!',
      color: 'Error',
      icon: 'mdi:alert',
      closable: true,
      duration: 1000,
    })
  } else {
    try {
      for (const item of [sch_items.data[0]]) {
        if (item.type == 'public') {
          // if (item.schedule_id?.repeat_types === 'completed') {
          //   let manual_cron_completed =
          //     runtimeConfig.public.directus.url +
          //     `db/manual_cron_completed?work_id=${item.id}`
          //   const response = await fetch(manual_cron_completed, {
          //     method: 'GET',
          //     headers: {
          //       Authorization: `Bearer ${token.value}`,
          //     },
          //   })
          //   console.log('Completed Response:', response)
          //   toaster.show({
          //     title: t('Created public'),
          //     color: 'success',
          //     icon: 'ph:user-circle-fill',
          //     closable: true,
          //   })
          // }
          if (item.schedule_id?.repeat_types === 'direct') {
            let manual_cron =
              runtimeConfig.public.directus.url +
              `db/manual_inspection?work_id=${item.id}`
            const response = await fetch(manual_cron, {
              method: 'GET',
              headers: {
                Authorization: `Bearer ${token.value}`,
              },
            })
            console.log('Direct Response:', response)
            toaster.show({
              title: t('Created public'),
              color: 'success',
              icon: 'ph:user-circle-fill',
              closable: true,
            })
          }
        } else if (item.type == 'private') {
          // if (item.repeat_types === 'completed') {
          //   let manual_cron_completed =
          //     runtimeConfig.public.directus.url +
          //     `db/manual_cron_completed?work_id=${item.work_order}`
          //   const response = await fetch(manual_cron_completed, {
          //     method: 'GET',
          //     headers: {
          //       Authorization: `Bearer ${token.value}`,
          //     },
          //   })
          //   console.log('Completed Response:', response)
          //   toaster.show({
          //     title: t('Created'),
          //     color: 'success',
          //     icon: 'ph:user-circle-fill',
          //     closable: true,
          //   })
          // }
          if (item.repeat_types === 'direct') {
            let manual_cron =
              runtimeConfig.public.directus.url +
              `db/manual_inspection?work_id=${item.work_order}`
            const response = await fetch(manual_cron, {
              method: 'GET',
              headers: {
                Authorization: `Bearer ${token.value}`,
              },
            })
            console.log('Direct Response:', response)

            toaster.show({
              title: t('Created'),
              color: 'success',
              icon: 'ph:user-circle-fill',
              closable: true,
            })
          }
        }
      }
    } catch (error) {
      toaster.show({
        title: t('Error'),
        message: 'Field type!',
        color: 'Error',
        icon: 'ph:user-circle-fill',
        closable: true,
        duration: 1000,
      })
      console.log('Error add item:', error)
    }
  }
}

const handleModalUserListClose = () => {
  isModalUserListOpen.value = false
}

const handleModalConfirmClose = (item) => {
  isModalConfirmOpen.value = false
  isModalApproveConfirmOpen.value = false
}

const setItem = (itemId, type) => {
  const res = createItems({
    collection: 'Work_inpection_actions',
    items: {
      wo_id: itemId,
      first_user: myId,
      action_status: 0,
      company_id: myCompanyId,
    },
  })

  if (type == 'delete') {
    const data = {
      collection: 'Work_inspections',
      id: itemId,
      item: {
        active: '0',
      },
    }
    updateItem(data)
  }
}
const refresh = (item) => {
  // console.log('refreshed')
  if (item) {
    // const newItem = { id: 6, name: "New Item", price: 100 };
    // const updatedData = [...gridApi.value.getDisplayedRowCount(), item];
    // gridApi.value.setRowData(updatedData);
    //   const newItem = { id: 6, name: "New Item", price: 100 };
    // gridOptions.api.applyTransaction({ add: [newItem] });
  }

  gridApi.value.refreshCells({ force: true })
  gridApi.value.refreshServerSide({ purge: false })
  gridApi.value.deselectAll()

  // gridApi.value.refreshServerSide()
  // gridApi.value.onFilterChanged()
  // gridApi.value.refreshInfiniteCache()
  // gridApi.valuerefreshServerSideStore({ purge: true });
}

const clearItem = () => {
  selectedItem.value = -1
}

const setUser = async (user) => {
  if (current_row.value) {
    const assign = await createItems({
      collection: 'Work_inpection_actions',
      items: {
        wo_id: current_row.value.id,
        first_user: myId,
        next_user: user.id,
        action_status: 4,
        company_id: myCompanyId,
      },
    })

    const data = {
      collection: 'Work_inspections',
      id: current_row.value.id,
      item: {
        assigned_to: user.id,
        action_status: 4,
      },
    }

    await updateItem(data)
    isModalUserListOpen.value = false
    refresh(current_row.value)
    toaster.show({
      title: t('Update'),
      message: t(`Record assigned successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }
}

let timeoutSearch = null
const onFilterTextBoxChanged = (event) => {
  const value = event.target.value

  // өмнөх timeout-оо цэвэрлэнэ
  clearTimeout(timeoutSearch)

  // 300ms дараа filter-г ажиллуулна
  timeoutSearch = setTimeout(() => {
    quickFilterText.value = value
    refreshed(quickFilterText.value)
  }, 300)
}

const refreshed = (item) => {
  console.log('refreshed with:', item)

  if (gridApi.value) {
    gridApi.value.refreshCells({ force: true })
    gridApi.value.refreshServerSide({ purge: false })
    gridApi.value.deselectAll()
  }
}

// For multi selection
defineExpose({
  gridApi,
  refresh,
  filterBuild,
  gridOptions,
})
</script>

<template>
  <div
    :class="[
      'relative',
      ['open', 'pm', 'inspection'].includes(props.type)
        ? 'tabGridBody'
        : 'tabGridBody',
    ]"
  >
    <!-- Grid -->
    <div class="grid grid-cols-12 Work_inspection_list">
      <div class="col-span-12 work_status">
        <div>
          <TairoContentWrapper>
            <template #left>
              <BaseInput
                icon="lucide:search"
                :placeholder="t('Name')"
                :classes="{
                  wrapper: 'w-[340px]',
                }"
                @input="onFilterTextBoxChanged"
              />
            </template>
          </TairoContentWrapper>
        </div>
      </div>
      <!-- Header -->
      <div class="col-span-12">
        <ag-grid-vue
          ref="agGridEl"
          :key="key"
          :style="{ width: '100%', height: windowHeight + 'px' }"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list ${props.type}_ag_grid ${props.code}_ag_grid`"
          :columnDefs="columnDefs"
          :gridOptions="gridOptions"
          :quickFilterText="quickFilterText"
          @grid-ready="onGridReady"
          :rowData="rowData"
          :onColumnMoved="saveColumnState"
          :onColumnPinned="saveColumnState"
          :onColumnVisible="saveColumnState"
          :onColumnResized="saveColumnState"
          @selection-changed="selectionChanged"
        >
        </ag-grid-vue>
        <UserList
          :open="isModalUserListOpen"
          :close="handleModalUserListClose"
          :setUser="setUser"
        />
        <ConfirmModalForm
          :itemsValue="itemsValue"
          code="Work_inspections"
          text="Do you approve to this action?"
          :open="isModalApproveConfirmOpen"
          :close="handleModalConfirmClose"
          :do_make="do_make"
          :actionType="actionType"
          :row="selectedItem"
          :clear="clearItem"
        />

        <WorkOrderDeletionModalForm
          :key="current_row?.id"
          code="Work_inspections"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :row="current_row?.id"
          :refresh="refresh"
          :setItem="setItem"
        />
      </div>
    </div>
  </div>
</template>
<style>
.Work_inspection_list {
  min-height: 560px !important;
}
.Work_inspection_list .ag-center-cols-container {
  overflow: visible;
  display: flex;
  flex-direction: column;
}
.Work_inspection_list .ag-row {
  overflow: visible;
  position: relative;
  transform: none !important;
  /* width: inherit; */
}
.Work_inspection_list .ag-row .status-cell,
.Work_inspection_list .ag-row .priority-cell {
  border: none !important;
}
.Work_inspection_list .ag-row .actions-cell {
  overflow: visible;
  border: none !important;
}

.Work_inspection_list .ag-row .actions-hide {
  display: none;
}
.Work_inspection_list .work_status {
  display: flex;
  justify-content: space-between;
}

.Work_inspection_list .ag-cell.empty_action {
  display: none;
}

/* .ag-menu {
  width: 250px !important;
  max-width: 280px;
  min-width: 230px;
  white-space: nowrap;
} */

.ag-menu {
  border-radius: 8px;
  box-shadow: 4px 5px 18px 2px rgb(0 0 0 / 20%);
}

.ag-menu-list {
  display: flex;
  flex-direction: column;
  cursor: default;
  width: 100%;
}
.ag-menu-option {
  display: flex;
}
.ag-menu-option-text {
  flex: 1;
}
.ag-menu-option-part {
  display: flex;
}
.ag-menu-separator {
  display: flex;
  align-items: center;
}
.ag-menu-separator .ag-menu-separator-part:first-child {
  display: block;
  width: 100%;
  height: 1px;
}
/* .ag-menu-separator-part:after {
  border-top: 1px solid var(--ag-menu-separator-color);
  content: '';
  display: block;
} */

.ag-menu-separator-part {
  display: none;
}
.ag-menu-option-part,
.ag-menu-separator-part {
  vertical-align: middle;
}
</style>
