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
import CommentCellRender from '~/components/ag_grid/CommentCellRender.vue'

import { fetchPageData } from '~/components/ag_grid/ag_grid_directus'
import CheckBoxCellRenderer from '~/components/ag_grid/checkBoxCellRenderer.vue'
import PriorityCellRenderer from '~/components/ag_grid/priorityCellRenderer.vue'
import WoStatusCellRenderer from '~/components/ag_grid/wo_statusCellRenderer.vue'
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import WorkOrderDeletionModalForm from '~/components/form/WorkOrderDeletionModalForm.vue'
import { sendNotification } from '../../compsables/sendNotification'

import {
  action_status,
  priorities,
  statuses,
} from '~/components/workorder/WorkOrderConstants'

import ProgressCellRenderer from '~/components/ag_grid/ProgressCellRenderer.vue'
import {
  completed_wo_status,
  open_status_id,
  open_wo_status,
  wo_status,
} from '~/components/workorder/WorkOrderStatus'
import ActionDropdownCellRenderer from '../ag_grid/ActionDropdownCellRenderer.vue'

const { t } = useI18n({ useScope: 'global' })
const { locale } = useI18n({ useScope: 'global' })
const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()
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
  request: t('Request'),
  open: t('Open'),
  completed: t('Completed'),
}
const selectedCount = ref(0)
const eventType = ref('WoAgList')
const columnChangeEvents = ref(false)

const paginationGetCurrentPage = ref(0)
const activeTab = ref('request')
const parts_codes = ref([])
const columnDefs = ref([])
const locationItem = ref([])
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
  assigned: String,
  className: String,
  show_location: Boolean,
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
const pageSizeToHeight = (size: number) => {
  const rowHeight = 42
  const headerHeight = 120 // pagination bar + header row
  return size * rowHeight + headerHeight
}

const _savedPageSize = parseInt(
  localStorage.getItem(props.type + '_pagesize') || '10',
  10,
)
const windowHeight = ref(pageSizeToHeight(_savedPageSize))

const loading = ref(true)
const gridApi = ref(null) // For storing ag-Grid API instance
const totalRows = ref(0) // Total rows from the backend
const paginationPageSize = ref(10) // Default page size
const rowModelType = ref('serverSide')
const dataSource = ref({})
const quickFilterText = ref('')
const progressCache = new Map()

// ── Дэлгэрэнгүй хайлт (Trades/Parts бүртгэгдсэн эсэхээр) ────────────────────
const isAdvancedSearchOpen = ref(false)
const advancedSearch = reactive<{
  trades: string
  parts: string
  groupType: string
  workType: string
  department: string
}>({
  trades: 'any',
  parts: 'any',
  groupType: 'any',
  workType: 'any',
  department: 'any',
})
const hasActiveAdvancedSearch = computed(
  () =>
    advancedSearch.trades !== 'any' ||
    advancedSearch.parts !== 'any' ||
    advancedSearch.groupType !== 'any' ||
    advancedSearch.workType !== 'any' ||
    advancedSearch.department !== 'any',
)

// Group type (Work_order.type -> Work_group_type) / Work type
// (Work_order.work_type -> Work_types) сонголтууд. Department нь
// autocomplete2 (FormKit) ашигладаг тул өөрөө ачаалдаг — энд урьдчилан
// татах шаардлагагүй
const groupTypeOptions = ref<any[]>([])
const workTypeOptions = ref<any[]>([])

const loadAdvancedSearchTypeOptions = async () => {
  try {
    const groupTypeRes = await getItems<any>({
      collection: 'Work_group_type',
      params: {
        filter: { status: '1' },
        limit: -1,
        fields: ['id', 'name'],
      },
    })
    groupTypeOptions.value = Array.isArray(groupTypeRes)
      ? groupTypeRes
      : groupTypeRes?.data ?? []

    const workTypeRes = await getItems<any>({
      collection: 'Work_types',
      params: {
        filter: { status: 'published' },
        limit: -1,
        fields: ['id', 'code'],
      },
    })
    workTypeOptions.value = Array.isArray(workTypeRes)
      ? workTypeRes
      : workTypeRes?.data ?? []
  } catch (e) {
    console.error('Unable to load advanced search type options:', e)
  }
}

// Advanced search панел (v-if) хаагдах/дахин нээгдэхэд autocomplete2
// component дахин mount хийгддэг тул сонгосон утгыг өөрөө хадгалж, дараа
// нь :value-ээр дамжуулж харуулна (эс тэгвэл дахин нээхэд хоосон харагддаг байсан)
const selectedDepartment = ref<any>(null)

const onAdvancedDepartmentPicked = (item: any) => {
  selectedDepartment.value = item ?? null
  advancedSearch.department = item?.id ?? 'any'
}

// Тухайн relation collection (Work_order_Tradecode/Work_order_Parts)-д
// бүртгэлтэй, өвөрмөц work_order id-уудыг олно (тухайн компанийн хэмжээнд).
// Уг мөрийн company_id хоосон байж болох (хуучин өгөгдөл) тул харилцагч
// work_order-ын company_id-аар шалгана — Work_order үргэлж company_id-тай
const getWorkOrderIdsWithRelation = async (
  collection: string,
): Promise<number[]> => {
  try {
    const res = await getItems<any>({
      collection,
      params: {
        filter: { work_order: { company_id: { _eq: myCompanyId } } },
        groupBy: ['work_order'],
        aggregate: { count: 'id' },
        limit: -1,
      },
    })
    const rows = Array.isArray(res) ? res : (res as any)?.data ?? []
    return rows
      .map((r: any) => Number(r.work_order))
      .filter((id: number) => !isNaN(id))
  } catch (e) {
    console.error('Unable to load relation ids:', collection, e)
    return []
  }
}

const applyAdvancedSearch = () => {
  isAdvancedSearchOpen.value = false
  refreshed(quickFilterText.value)
}

const clearAdvancedSearch = () => {
  advancedSearch.trades = 'any'
  advancedSearch.parts = 'any'
  advancedSearch.groupType = 'any'
  advancedSearch.workType = 'any'
  advancedSearch.department = 'any'
  selectedDepartment.value = null
  isAdvancedSearchOpen.value = false
  refreshed(quickFilterText.value)
}

const buildProgressMap = async (workOrderIds) => {
  if (!workOrderIds || workOrderIds.length === 0) return {}

  const missingIds = workOrderIds.filter((id) => !progressCache.has(String(id)))

  if (missingIds.length === 0) {
    const cachedMap = {}
    for (const id of workOrderIds) {
      cachedMap[String(id)] = progressCache.get(String(id)) ?? 0
    }
    return cachedMap
  }
  try {
    const items = await getItems({
      collection: 'Work_order_item',
      params: {
        filter: {
          active: 1,
          workorder: { _in: missingIds },
        },
        aggregate: {
          count: '*',
        },
        groupBy: 'workorder, template_type, value',
        meta: 'filter_count',
      },
    })

    const totals = {}
    const completed = {}

    for (const row of items?.data || []) {
      const woId = String(row.workorder)
      const count = parseInt(row.count, 10) || 0

      totals[woId] = (totals[woId] || 0) + count

      const isTemplate5 = row.template_type === 5 && row.value === '1'
      const isTemplate7 =
        row.template_type === 7 && row.value !== null && row.value !== ''

      if (isTemplate5 || isTemplate7) {
        completed[woId] = (completed[woId] || 0) + count
      }
    }

    for (const id of missingIds) {
      const key = String(id)
      const total = totals[key] || 0
      const done = completed[key] || 0
      const value = total > 0 ? Math.floor((done / total) * 100) : 0
      progressCache.set(key, value)
    }

    const progressMap = {}
    for (const id of workOrderIds) {
      progressMap[String(id)] = progressCache.get(String(id)) ?? 0
    }

    return progressMap
  } catch (e) {
    console.log(e)
    return {}
  }
}

// batlagdsan (approved) OUTCOME transaction-tai (debt-tei) work order-uudiig oloh
const buildDebtMap = async (workOrderIds) => {
  if (!workOrderIds || workOrderIds.length === 0) return {}
  try {
    const items = await getItems({
      collection: 'Transaction',
      params: withCompanyFilter({
        filter: {
          transaction_type: 'OUTCOME',
          status: { _in: [2] },
          work_order: { _in: workOrderIds },
        },
        limit: -1,
        fields: ['work_order'],
      }),
    })

    const rows = Array.isArray(items) ? items : items?.data ?? []
    const debtMap = {}
    for (const row of rows) {
      const woId = row?.work_order?.id ?? row?.work_order
      if (woId != null) debtMap[String(woId)] = true
    }
    return debtMap
  } catch (e) {
    console.log(e)
    return {}
  }
}

const hasApprovedDebt = async (workOrderId) => {
  if (!workOrderId) return false
  const debtMap = await buildDebtMap([workOrderId])
  return !!debtMap[String(workOrderId)]
}

const quickFilterStatus = ref('request')

// Create filtered open_wo_status without ID 1
const getFilteredOpenWoStatus = () => {
  if (open_wo_status && open_wo_status._in) {
    return { _in: open_wo_status._in.filter((id) => id !== 3) }
  }
  return open_wo_status
}
const filtered_open_wo_status = getFilteredOpenWoStatus()

const defaultColDef = {
  resizable: false,
}

const { params } = useRoute()
const rowData = ref([])
// getRows datasource-аас сүүлд амжилттай татсан хуудасны мөрүүд — Next/Prev
// навигацид ашиглана (server-side row model тул forEachNodeAfterFilterAndSort
// найдвартай ажиллахгүй тул өөрсдөө хадгална)
const loadedRowsForNav = ref<any[]>([])
const key = ref(1)
const myId = window.localStorage.getItem('myId')
const wo_actions = JSON.parse(window.localStorage.getItem('wo_actions'))
const permissions = JSON.parse(
  window.localStorage.getItem('app_permissions') || '{}',
)

const isAdmin = ref(false)
const doAccepted = ref(false)
const doCreated = ref(false)
const doDeclined = ref(false)
const doApproved = ref(false)
const doAssigned = ref(false)
const doReturned = ref(false)
const doDeleted = ref(false)
const doEdited = ref(false)

if (permissions && permissions[1] && permissions[1].includes('admin')) {
  doAccepted.value = true
  doCreated.value = true
  doDeclined.value = true
  doApproved.value = true
  doAssigned.value = true
  doReturned.value = true
  doDeleted.value = true
  doEdited.value = true
  isAdmin.value = true
} else {
  if (wo_actions && wo_actions[String(props.location)]?.length) {
    let do_actions = wo_actions?.[String(props.location)] ?? []

    do_actions.forEach((action) => {
      switch (action.id) {
        case 0: // deleted
          doDeleted.value = true
          break
        case 1: // created
          doCreated.value = true
          break
        case 2: // approved
          doApproved.value = true
          break
        case 3: // returned
          doReturned.value = true
          break
        case 4: // assigned
          doAssigned.value = true
          break
        case 5: // accepted
          doAccepted.value = true
          break
        case 6: //  declined
          doDeclined.value = true
          break
        case 7: //  edit
          doEdited.value = true
          break
      }
    })

    // console.log('wo_actions_dss', props.location)
    // console.log('do_actions', do_actions)
  }
}
const filterModuleKeys = Object.keys(filter_modules)
function onTabChange(tab: string) {
  const index = parseInt(tab.replace('tab-', '')) - 1
  const key = filterModuleKeys[index]
  handleTabClick(key, activeTab.value)
}

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

const getStatusColor = (statusValue) => {
  const status = statuses.find((s) => s.value === statusValue)
  return status?.color || 'gray'
}

const getPriorityColor = (priorityValue) => {
  const priority = priorities.find(
    (p) => p.value == priorityValue || p.__original == priorityValue,
  )
  return priority?.defaultColor || 'gray'
}

const onRowClicked = (params) => {
  // console.log(params.data)
  // console.log('props.wo_status_items', props.wo_status_items)
  if (['open', 'request', 'completed', 'allworks'].includes(props.type)) {
    open('workorderopenmore', {
      id: params.data.id,
      data: params.data,
      wo_statuses: props.wo_status_items,
      type: props.type,
      refresh: refresh,
      freeze: props.type == 'completed' ? true : false,
      // Server-side datasource-аас сүүлд амжилттай татсан хуудасны
      // мөрүүд — Next/Prev навигацид ашиглана
      list: loadedRowsForNav.value,
      onClose: (message: any) => {
        // console.log('onMessagess')
        // console.log(message)
        // close()
      },
    })
  }
  // else if (props.type == 'completed') {
  //   open('workordercompletedmore', {
  //     id: params.data.id,
  //     data: params.data,
  //     wo_statuses: props.wo_status_items,
  //     type: props.type,
  //     refresh: refresh,
  //   })
  // }
  else if (props.type == 'pm') {
    open('workorderpmmore', {
      id: params.data.id,
      data: params.data,
      wo_statuses: props.wo_status_items,
      type: props.type,
      tab: props.tab,
      refresh: refresh,
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

const column_complete = [
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
    headerName: t('WO number'),
    field: 'wo_number',
    sortable: true,
    editable: false,
    // maxWidth: 130,
    resizable: true,
    pinned: 'left',
    cellRenderer: (params) => {
      return `
        <span>
          WO #${params.data.wo_number ?? params.data.id}
        </span>
      `
    },
    onCellClicked: (params) => {
      onRowClicked(params)
    },
    cellStyle: { cursor: 'pointer' },
    cellClass: 'task_number',
    filter: 'agNumberColumnFilter',
    filterParams: {
      maxNumConditions: 1,
      buttons: ['reset'],
      filterOptions: [
        'equals',
        'inRange',
        'lessThan',
        'greaterThan',
        'notEqual',
      ],
    },
  },
  {
    headerName: t('Name'),
    field: 'name',
    sortable: true,
    editable: false,
    resizable: true,
    // maxWidth: 180,
    onCellClicked: (params) => {
      onRowClicked(params)
    },
    filter: 'agTextColumnFilter',
    filterParams: {
      textFormatter: (text) => text.toLowerCase(),
      maxNumConditions: 1,
      filterOptions: ['contains'],
      buttons: ['reset'],
    },
    tooltipValueGetter: (p) => p.value,
    headerTooltip: t('Work name'),
  },
  {
    headerName: t('Progress'),
    field: 'wo_percent',
    sortable: true,
    editable: false,
    resizable: true,
    headerClass: 'header-picture',
    cellRenderer: ProgressCellRenderer,
    cellRendererParams: (params) => {
      // console.log('params', params)
    },
    // maxWidth: 150,
    width: 120,
  },
  {
    headerName: t('Priority'),
    field: 'priority',
    sortable: true,
    editable: false,
    resizable: true,
    maxWidth: 130,
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
    headerName: t('Status'),
    field: 'wo_status',
    sortable: true,
    filter: 'agSetColumnFilter', // Enable set filter
    editable: false,
    maxWidth: 170,
    resizable: true,
    // hide: !wo_statuss ? true : false,
    filterParams: {
      values: (params) => {
        if (props.type == 'allworks') {
          const all_statuses = props.wo_status_items.map((status) => status.id)
          params.success(all_statuses)
          return
        }
        const filter_statuses = props.wo_status_items
          .filter((status) => status.type === props.type)
          .map((status) => status.id)

        params.success(filter_statuses)
      }, // Provide numeric values for the filter
      valueFormatter: (params) => {
        const status = props.wo_status_items.find((s) => s.id == params.value)
        return status ? t(status.name) : params.value // Map numeric value to text
      },

      suppressRemoveAll: true, // Disable "Remove All" button
      checkbox: true, // Enable checkboxes in the filter
    },
    cellRenderer: WoStatusCellRenderer,
    cellStyle: { margin: '9px 0px 0px 4px' },
    cellClass: 'status-cell',
  },
  {
    headerName: t('Completed'),
    field: 'completed_user.first_name',
    sortable: true,
    filter: false,
    editable: false,
    resizable: true,
    cellClass: 'completed_user',
    // maxWidth: 160,
  },
  {
    headerName: t('Completed date'),
    field: 'completed_at',
    sortable: true,
    editable: false,
    // maxWidth: 180,
    resizable: true,
    valueGetter: (params) => {
      if (params.data.completed_at) {
        const date = new Date(params.data.completed_at)
        return format(date, 'yyyy-MM-dd HH:mm') // Format the date
      } else {
        return ''
      }
    },
    // cellStyle: { color: '#057dbc' },
    cellClass: 'completed_at',
    filter: 'agDateColumnFilter',
    filterParams: filterDateParams,
  },
  {
    headerName: t('Start date'),
    field: 'started_at',
    sortable: true,
    resizable: true,

    editable: false,
    valueGetter: (params) => {
      if (params.data?.started_at) {
        const date = new Date(params.data.started_at)
        return format(date, 'yyyy-MM-dd') // Format the date
      } else {
        return ''
      }
    },
    filter: 'agDateColumnFilter',
    filterParams: filterDateParams,
  },
  {
    headerName: t('Due date'),
    field: 'due',
    sortable: true,
    editable: false,
    maxWidth: 160,
    resizable: true,

    valueGetter: (params) => {
      if (params.data.due) {
        const date = new Date(params.data.due)
        return format(date, 'yyyy-MM-dd') // Format the date
      } else {
        return ''
      }
    },
    filter: 'agDateColumnFilter',
    filterParams: filterDateParams,
  },
  {
    headerName: t('Printed'),
    field: 'printed',
    sortable: false,
    filter: 'agSetColumnFilter',
    editable: false,
    maxWidth: 160,
    cellClass: 'status-cell',
    cellRenderer: CheckBoxCellRenderer,
    filterParams: {
      values: (params) => {
        let filter_print = prints.map((status) => status.id)
        params.success(filter_print)
      }, // Provide numeric values for the filter
      valueFormatter: (params) => {
        let p = prints.find((s) => s.id == params.value)
        return p ? t(p.name) : params.value // Map numeric value to text
      },

      suppressRemoveAll: true, // Disable "Remove All" button
      checkbox: true, // Enable checkboxes in the filter
    },
  },
  {
    field: 'actions',
    headerName: t('Actions'),
    maxWidth: 108,
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
        onApproveClick: false,
        onDeclinedClick: false,
        onAssignClick: false,
        module: 'completed',
      }

      //approved
      if (doReturned.value && !params.data.has_debt)
        actions.onReturnClick = do_return

      return actions
    },
    cellClass: 'actions-cell',
    cellStyle: {
      // 'background-color': 'green',
    },
  },
]

const column_open = [
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
    headerName: t('WO number'),
    field: 'wo_number',
    sortable: true,
    editable: false,
    pinned: 'left',
    resizable: true,
    // maxWidth: 160,
    cellRenderer: (params) => {
      return `
        <span>
          WO #${params.data.wo_number ?? params.data.id}
        </span>
      `
    },
    onCellClicked: (params) => {
      onRowClicked(params)
    },
    cellStyle: { cursor: 'pointer' },
    filter: 'agNumberColumnFilter',
    filterParams: {
      maxNumConditions: 1,
      buttons: ['reset'],
      filterOptions: [
        'equals',
        'inRange',
        'lessThan',
        'greaterThan',
        'notEqual',
      ],
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
    tooltipValueGetter: (p) => p.value,
    headerTooltip: t('Work name'),
    // pinned: 'left',
    // maxWidth: 180,
  },
  {
    headerName: t('Progress'),
    field: '',
    sortable: true,
    editable: false,
    resizable: true,
    headerClass: 'header-picture',
    cellRenderer: ProgressCellRenderer,
    cellRendererParams: (params) => {
      // console.log('params', params)
    },
    // maxWidth: 150,
    width: 120,
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
    headerName: t('Status'),
    field: 'wo_status',
    sortable: true,
    filter: 'agSetColumnFilter', // Enable set filter
    editable: false,
    resizable: true,
    maxWidth: 170,
    // hide: !wo_statuss ? true : false,
    filterParams: {
      values: (params) => {
        if (props.type == 'allworks') {
          const all_statuses = props.wo_status_items.map((status) => status.id)
          params.success(all_statuses)
          return
        }
        const filter_statuses = props.wo_status_items
          .filter((status) => status.type === props.type)
          .map((status) => status.id)

        params.success(filter_statuses)
      }, // Provide numeric values for the filter
      valueFormatter: (params) => {
        const status = props.wo_status_items.find((s) => s.id == params.value)
        return status ? t(status.name) : params.value // Map numeric value to text
      },

      suppressRemoveAll: true, // Disable "Remove All" button
      checkbox: true, // Enable checkboxes in the filter
    },
    cellRenderer: WoStatusCellRenderer,
    cellStyle: { margin: '9px 0px 0px 4px' },
    cellClass: 'status-cell',
  },
  {
    headerName: t('Created date'),
    field: 'created_at',
    sortable: true,
    editable: false,
    valueGetter: (params) => {
      if (params.data?.created_at) {
        const date = new Date(params.data.created_at)
        return format(date, 'yyyy-MM-dd HH:mm') // Format the date
      } else {
        return ''
      }
    },
    filter: 'agDateColumnFilter',
    filterParams: filterDateParams,
  },
  {
    headerName: t('Created type'),
    field: 'created_type',
    sortable: true,
    editable: false,
    resizable: true,
    width: 150,
    filter: 'agSetColumnFilter',
    filterParams: {
      values: [
        'request',
        'open',
        'ins_generated',
        'pm_generated',
        'pdm_generated',
      ],
      suppressRemoveAll: true,
      checkbox: true,
    },

    cellRenderer: PriorityCellRenderer,
  },
  {
    headerName: t('Start date'),
    field: 'started_at',
    sortable: true,
    resizable: true,

    editable: false,
    valueGetter: (params) => {
      if (params.data?.started_at) {
        const date = new Date(params.data.started_at)
        return format(date, 'yyyy-MM-dd') // Format the date
      } else {
        return ''
      }
    },
    filter: 'agDateColumnFilter',
    filterParams: filterDateParams,
  },
  {
    headerName: t('Due date'),
    field: 'due',
    sortable: true,
    resizable: true,

    editable: false,
    valueGetter: (params) => {
      if (params.data?.due) {
        const date = new Date(params.data.due)
        return format(date, 'yyyy-MM-dd') // Format the date
      } else {
        return ''
      }
    },
    filter: 'agDateColumnFilter',
    filterParams: filterDateParams,
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
    headerName: t('Comments'),
    field: 'comment_cnt',
    sortable: true,
    editable: false,
    hide: false,
    width: 120,
    filter: false,
    cellRenderer: CommentCellRender,
    cellRendererParams: (params) => {
      // console.log('params', params)
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
    headerName: t('Printed'),
    field: 'printed',
    sortable: false,
    filter: 'agSetColumnFilter',
    editable: false,
    width: 150,
    cellClass: 'status-cell',
    cellRenderer: CheckBoxCellRenderer,
    filterParams: {
      values: (params) => {
        let filter_print = prints.map((status) => status.id)
        params.success(filter_print)
      }, // Provide numeric values for the filter
      valueFormatter: (params) => {
        let p = prints.find((s) => s.id == params.value)
        return p ? t(p.name) : params.value // Map numeric value to text
      },

      suppressRemoveAll: true, // Disable "Remove All" button
      checkbox: true, // Enable checkboxes in the filter
    },
  },
  {
    field: 'actions',
    headerName: t('Actions'),
    maxWidth: 108,
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
        onApproveClick: false,
        onDeclinedClick: false,
        onAssignClick: false,
        module: 'open',
      }

      // if (!wo_actions) {
      //   return
      // }

      //accepted, created
      if ([1, 5].includes(params.data.action_status)) {
        actions.onEditClick = do_edit
        if (doDeleted.value && !params.data.has_debt)
          actions.onDeleteClick = do_delete
        if (doAssigned.value) actions.onAssignClick = do_assign
        if (doApproved.value) actions.onApproveClick = do_approve
        if (doDeclined.value) actions.onDeclinedClick = do_decline
      }

      //approved
      if (params.data.action_status === 2) {
        if (doReturned.value && !params.data.has_debt)
          actions.onReturnClick = do_return
      }

      //returned
      if (params.data.action_status === 3) {
        actions.onEditClick = do_edit
        if (doDeleted.value && !params.data.has_debt)
          actions.onDeleteClick = do_delete
        if (doAssigned.value) actions.onAssignClick = do_assign
        if (doApproved.value) actions.onApproveClick = do_approve
        if (doDeclined.value) actions.onDeclinedClick = do_decline
      }

      //assigned
      if (params.data.action_status === 4) {
        if (doAssigned.value) actions.onAssignClick = do_assign
        if (doApproved.value) actions.onApproveClick = do_approve
        if (doDeclined.value) actions.onDeclinedClick = do_decline
      }

      //declined
      if (params.data.action_status === 6) {
        actions.onEditClick = do_edit
        if (doDeleted.value && !params.data.has_debt)
          actions.onDeleteClick = do_delete
        if (doAssigned.value) actions.onAssignClick = do_assign
        if (doApproved.value) actions.onApproveClick = do_approve
      }

      return actions
    },
    cellClass: 'actions-cell',
    cellStyle: {
      // 'background-color': 'green',
    },
  },
]

const column_req = [
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
    headerName: t('Req number'),
    field: 'req_number',
    sortable: true,
    editable: false,
    resizable: true,
    pinned: 'left',
    // maxWidth: 160,
    cellRenderer: (params) => {
      return `
        <span>
          REQ #${params.data.req_number ?? params.data.id}
        </span>
      `
    },
    onCellClicked: (params) => {
      onRowClicked(params)
    },
    cellStyle: { cursor: 'pointer' },
    filter: 'agNumberColumnFilter',
    filterParams: {
      maxNumConditions: 1,
      buttons: ['reset'],
      filterOptions: [
        'equals',
        'inRange',
        'lessThan',
        'greaterThan',
        'notEqual',
      ],
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
    tooltipValueGetter: (p) => p.value,
    headerTooltip: 'Work name',
    // pinned: 'left',
    // maxWidth: 180,
  },
  // {
  //   headerName: 'Progress',
  //   field: '',
  //   sortable: true,
  //   editable: false,
  //   resizable: true,
  //   headerClass: 'req-progress',
  //   cellRenderer: ProgressCellRenderer,
  //   cellRendererParams: (params) => {
  //     // console.log('params', params)
  //   },
  //   // maxWidth: 150,
  //   width: 120,
  // },
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
    headerName: t('Status'),
    field: 'wo_status',
    sortable: true,
    filter: 'agSetColumnFilter', // Enable set filter
    editable: false,
    resizable: true,
    maxWidth: 170,
    // hide: !wo_statuss ? true : false,
    filterParams: {
      values: (params) => {
        if (props.type == 'allworks') {
          const all_statuses = props.wo_status_items.map((status) => status.id)
          params.success(all_statuses)
          return
        }
        const filter_statuses = props.wo_status_items
          .filter((status) => status.type === props.type)
          .map((status) => status.id)

        params.success(filter_statuses)
      }, // Provide numeric values for the filter
      valueFormatter: (params) => {
        const status = props.wo_status_items.find((s) => s.id == params.value)
        return status ? t(status.name) : params.value // Map numeric value to text
      },

      suppressRemoveAll: true, // Disable "Remove All" button
      checkbox: true, // Enable checkboxes in the filter
    },
    cellRenderer: WoStatusCellRenderer,
    cellStyle: { margin: '9px 0px 0px 4px' },
    cellClass: 'status-cell',
  },
  {
    headerName: t('Created date'),
    field: 'created_at',
    sortable: true,
    editable: false,
    valueGetter: (params) => {
      if (params.data?.created_at) {
        const date = new Date(params.data.created_at)
        return format(date, 'yyyy-MM-dd HH:mm') // Format the date
      } else {
        return ''
      }
    },
    filter: 'agDateColumnFilter',
    filterParams: filterDateParams,
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
    field: 'actions',
    headerName: t('Actions'),
    maxWidth: 108,
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
        onApproveClick: false,
        onAssignClick: false,
        onAcceptClick: false,
        module: 'request',
      }

      // if (!wo_actions) {
      //   return
      // }

      if ([1, 6].includes(params.data.action_status)) {
        if (doAccepted.value) actions.onAcceptClick = do_accept
      }
      return actions
    },
    cellClass: (params) => {
      // console.log('empty_action', params.data)
      return [1, 6].includes(params.data.action_status)
        ? 'actions-cell'
        : 'empty_action actions-cell'
    },
    // cellClass: (params) =>
    //   params.data.type.code_work_order === 'wo_1'
    //     ? 'actions-hide actions-cell'
    //     : 'actions-cell',

    cellStyle: {
      // 'background-color': 'green',
    },
  },
]

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
        '  <div ref="eLabel" class="ag-header-cell-label" role="presentation">' +
        '    <input type="checkbox" id="wo-header-checkbox" style="cursor:pointer;width:14px;height:14px;" />' +
        '  </div>' +
        '</div>',
    },
  },
  // {
  //   headerName: 'WO number',
  //   field: 'id',
  //   sortable: true,
  //   editable: false,
  //   resizable: true,
  //   pinned: 'left',
  //   // maxWidth: 160,
  //   cellRenderer: (params) => {
  //     return `
  //       <span>
  //         WO #${params.data.id}
  //       </span>
  //     `
  //   },
  // },
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
    field: 'created_at',
    sortable: true,
    editable: false,
    width: 150,
    valueGetter: (params) => {
      if (params.data?.created_at) {
        const date = new Date(params.data.created_at)
        return format(date, 'yyyy-MM-dd HH:mm') // Format the date
      } else {
        return ''
      }
    },
    filter: 'agDateColumnFilter',
    filterParams: filterDateParams,
  },
  {
    headerName: t('Start date'),
    field: 'started_at',
    sortable: true,
    resizable: true,

    editable: false,
    valueGetter: (params) => {
      if (params.data?.started_at) {
        const date = new Date(params.data.started_at)
        return format(date, 'yyyy-MM-dd') // Format the date
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
    field: 'actions',
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
        onApproveClick: false,
        onAssignClick: false,
        onAcceptClick: false,
        onStart: false,
        module: 'pm',
      }

      // if (!wo_actions) {
      //   return
      // }

      if (!params.data.has_debt) actions.onDeleteClick = do_delete
      if (props.tab == 'pm_templates') {
        if (params.data.action_status === 2) {
          //approved
          if (!params.data.has_debt) actions.onReturnClick = do_return
          actions.onStart = do_start
        }
        if (params.data.action_status !== 2) {
          //returned, creared, assiged
          actions.onAssignClick = do_assign
          actions.onApproveClick = do_approve
        }
      }

      if (props.tab == 'generated') {
        actions.onAcceptClick = do_approved_wo
      }

      return actions
    },
    cellClass: 'actions-cell',
    cellStyle: {
      // 'background-color': 'green',
    },
  },
]
if (props.show_location) {
  let location_column = {
    headerName: t('Location'),
    field: 'location.name',
    sortable: true,
    editable: false,
    resizable: true,
    width: 200,
    filter: 'agTextColumnFilter',
    filterParams: {
      textFormatter: (text) => text.toLowerCase(),
      maxNumConditions: 1,
      filterOptions: ['contains'],
      buttons: ['reset'],
    },
  }
  column_complete.push(location_column)
  column_open.push(location_column)
  column_req.push(location_column)
  column_pm.push(location_column)
}

// Анхдагчаар нуугдмал (hide: true) багана — "Choose Columns" цэснээс
// хэрэглэгч өөрөө гаргаж болно
const hidden_columns = [
  {
    headerName: t('Group type'),
    field: 'type.name',
    sortable: true,
    editable: false,
    resizable: true,
    hide: true,
    filter: 'agTextColumnFilter',
  },
  {
    headerName: t('Work Type'),
    field: 'work_type.code',
    sortable: true,
    editable: false,
    resizable: true,
    hide: true,
    filter: 'agTextColumnFilter',
  },
  {
    headerName: t('Planned budget'),
    field: 'budget_planned_amount',
    sortable: true,
    editable: false,
    resizable: true,
    hide: true,
    filter: 'agNumberColumnFilter',
    valueFormatter: (params) =>
      params.value != null ? Number(params.value).toLocaleString() : '',
  },
  {
    headerName: t('Actual budget'),
    field: 'budget_actual_amount',
    sortable: true,
    editable: false,
    resizable: true,
    hide: true,
    filter: 'agNumberColumnFilter',
    valueFormatter: (params) =>
      params.value != null ? Number(params.value).toLocaleString() : '',
  },
]
column_complete.push(...hidden_columns)
column_open.push(...hidden_columns)
column_req.push(...hidden_columns)
column_pm.push(...hidden_columns)
if (props.type == 'completed') columnDefs.value = column_complete
else if (props.type == 'open') columnDefs.value = column_open
else if (props.type == 'request') columnDefs.value = column_req
else if (props.type == 'pm') columnDefs.value = column_pm
else columnDefs.value = column_open

async function fetchScheduleData(rowData) {
  const requests = rowData.map(async (row) => {
    const filters = {
      status: 'Active',
      work_order: row.id,
      // schedule_id: { _nnull: true },
    }

    const sch_items = await getItems({
      collection: 'Work_order_schedules',
      params: withCompanyFilter({
        filter: filters,
        meta: 'filter_count',
        fields: ['*', 'schedule_id.*'],
      }),
    })

    // console.log('sch_items', sch_items)
    if (sch_items.data) {
      return {
        row,
        schedule_names:
          sch_items.data
            ?.map((s) => (s.schedule_id ? s.schedule_id.name : s.name))
            .join(', ') || '',
      }
    }
  })

  // 🚀 Бүх хүсэлтийг зэрэг гүйцэтгэнэ
  const results = await Promise.all(requests)
  // console.log('requests results:', results)

  // 🎯 `rowData`-г шинэчлэнэ
  results.forEach(({ row, schedule_names }) => {
    row.schedule_names = schedule_names
  })
}

const onGridReady = (params) => {
  // Restore column state on grid load
  // console.log('_onGridReady_props -->', params)

  let save_state = props.type
  if (save_state == 'pm') {
    save_state = props.tab
  }

  const savedState = localStorage.getItem(save_state)
  const savedStatePageSize = localStorage.getItem(props.type + '_pagesize')

  if (savedState) {
    const state = JSON.parse(savedState)
    params.api.applyColumnState({ state: state, applyOrder: true })
  }

  if (savedStatePageSize) {
    const parsedSize = parseInt(savedStatePageSize, 10)
    windowHeight.value = pageSizeToHeight(parsedSize)
    paginationPageSize.value = parsedSize
    try {
      // Try multiple methods
      if (params.api.paginationSetPageSize) {
        params.api.paginationSetPageSize(parsedSize)
      } else if (params.api.setGridOption) {
        params.api.setGridOption('paginationPageSize', parsedSize)
      } else {
        gridOptions.paginationPageSize = parsedSize
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
      '#wo-header-checkbox',
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

      const defaultSortField =
        props.type == 'request' ? 'req_number' : 'wo_number'
      const sortField = sortModel.length ? sortModel[0].colId : defaultSortField
      const sortOrder = sortModel.length ? sortModel[0].sort : 'desc'

      let filter_user = await filterUser(filterModel)
      let filter_location = await filterLocation(filterModel)
      let filter_initial = {
        ...filterBuild(filterModel),
        ...filter_user,
        ...filter_location,
      }

      if (props.work_order_type == 'allworks') {
        filter_initial['wo_number'] = { _nnull: true }
      }

      // Дэлгэрэнгүй хайлт: Trades/Parts бүртгэгдсэн эсэхээр нэмэлт шүүлт
      const advancedIdFilters: any[] = []
      if (advancedSearch.trades !== 'any') {
        const ids = await getWorkOrderIdsWithRelation('Work_order_Tradecode')
        advancedIdFilters.push({
          id: advancedSearch.trades === 'yes' ? { _in: ids } : { _nin: ids },
        })
      }
      if (advancedSearch.parts !== 'any') {
        const ids = await getWorkOrderIdsWithRelation('Work_order_Parts')
        advancedIdFilters.push({
          id: advancedSearch.parts === 'yes' ? { _in: ids } : { _nin: ids },
        })
      }
      if (advancedIdFilters.length) {
        filter_initial._and = [
          ...(filter_initial._and || []),
          ...advancedIdFilters,
        ]
      }

      // Group type (Work_order.type) / Work type (Work_order.work_type) /
      // Department (Work_order.department)
      if (advancedSearch.groupType !== 'any') {
        filter_initial.type = { _eq: advancedSearch.groupType }
      }
      if (advancedSearch.workType !== 'any') {
        filter_initial.work_type = { _eq: advancedSearch.workType }
      }
      if (advancedSearch.department !== 'any') {
        filter_initial.department = { _eq: advancedSearch.department }
      }

      // fetchPageData дотор withCompanyFilter аль хэдийн хэрэглэгддэг тул
      // энд дахин ороогүй (давхар company_id filter үүсэхээс сэргийлнэ)
      console.log('filter_initial', filter_initial)
      // console.log('sortField', sortField)
      // console.log('sortOrder', sortOrder)

      try {
        const response = await fetchPageData({
          currentPage: Math.floor(startRow / paginationPageSize.value) + 1,
          pageSize: paginationPageSize.value,
          sortField: sortField,
          sortOrder: sortOrder,
          search: quickFilterText.value,
          searchField: 'wo_number,name',
          collection: 'Work_order',
          fields: [
            '*',
            'assigned_to.*',
            'assigned_team.*',
            'wo_status.*',
            'schedule.*',
            'type.*',
            'work_type.*',
            'location.*',
            'wo_status.code_color.*',
            'completed_user.first_name',
          ],
          filters: filter_initial,
        })

        const rowsThisPage = response.data
        const lastRow = response.totalCount

        const workOrderIds = rowsThisPage
          .map((row) => row.id)
          .filter((id) => id !== null && id !== undefined)
        const progressMap = await buildProgressMap(workOrderIds)
        const debtMap = await buildDebtMap(workOrderIds)
        const rowsWithProgress = rowsThisPage.map((row) => ({
          ...row,
          progress_value: progressMap[String(row.id)] ?? 0,
          has_debt: debtMap[String(row.id)] ?? false,
        }))

        if (props.type === 'pm') {
          let rowData = rowsWithProgress
          totalRows.value = lastRow
          fetchScheduleData(rowData).then(() => {
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
        loadedRowsForNav.value = rowsWithProgress
        params.success({
          rowData: rowsWithProgress,
          rowCount: lastRow,
        })
        if (lastRow === 0) params.api?.showNoRowsOverlay()
        else params.api?.hideOverlay()
      } catch (error) {
        console.error('Error fetching page data:', error)
        params.fail()
      }
    },
  }

  // Set the server-side datasource
  params.api.setGridOption('serverSideDatasource', dataSource.value)
}

function rowSelected(event) {
  const cars = event.api.getSelectedRows()
  console.log('cars rowSelected: ' + cars.length)
}

function updateSelectionBadge() {
  const panel = document.querySelector('.work_order_list .ag-paging-panel')
  if (!panel) return
  let el = panel.querySelector('#row-selected-count') as HTMLElement | null
  if (!el) {
    el = document.createElement('span')
    el.id = 'row-selected-count'
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

// AG Grid-ийн өөрийн баганын filter (жишээ нь action_status) өөрчлөгдөх бүрд
// өмнөх сонголтыг (тэр дундаа "select all" төлөв) цэвэрлэнэ — эс тэгвэл
// Advanced search-ээр бүгдийг чагтлаад, дараа нь баганын filter-ээр илүү
// нарийсгаход "select all" төлөв хуучин (шүүгдэхээс өмнөх) бүх мөрөнд
// хамаарсан хэвээр үлдэж, Тайлан товч дарахад буруу id-нууд авагддаг байсан
function onGridFilterChanged() {
  gridApi.value?.deselectAll()
}

function selectionChanged(event) {
  const rendered = event.api.getRenderedNodes?.() ?? []
  selectedCount.value = rendered.filter((n: any) => n.isSelected()).length
  const cb = document.querySelector(
    '#wo-header-checkbox',
  ) as HTMLInputElement | null
  if (cb) {
    const total = rendered.length
    cb.checked = selectedCount.value > 0 && selectedCount.value === total
    cb.indeterminate = selectedCount.value > 0 && selectedCount.value < total
  }
  updateSelectionBadge()
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
    clearSort: t('Clear Sort'),
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
  // Server-side row model дээр filter (жишээ нь action_status)
  // өөрчлөгдөх бүрд AG Grid row node-уудаа шинээр үүсгэдэг тул getRowId
  // зааагүй бол өмнө сонгосон (checkbox) мөрүүд буруу id-тай холбогдоод
  // getSelectedRows()/getServerSideSelectionState() буруу үр дүн өгдөг байсан
  getRowId: (params) => String(params.data.id),
  pagination: true,
  cacheBlockSize: 20, // Set fetch size to 10 rows per block
  paginationPageSize: 10, // Start with 10 rows per page
  paginationPageSizeSelector: [10, 20, 30, 50, 70, 100],
  serverSideDatasource: dataSource.value,
  rowSelection: 'multiple', // Enable multiple row selection
  suppressRowClickSelection: true, // Prevent row selection on row click
  rowMultiSelectWithClick: true, // Allow selecting multiple rows with clicks
  animateRows: false,
  tooltipShowDelay: 0,
  tooltipHideDelay: 2000,
  defaultColDef: {
    flex: props.type == 'pm' ? 1 : 0,
    // minWidth: 100,
  },

  getMainMenuItems: (params: GetMainMenuItemsParams) => {
    // console.log('menuItem->', params)
    return [
      ...params.defaultItems,
      'separator',
      {
        name: t('Click Alert Button and Close Menu'),
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
    paginationGetCurrentPage.value = params.api.paginationGetCurrentPage()
    nextTick(() => updateSelectionBadge())
    // console.log('aginationGetCurrentPage', paginationGetCurrentPage.value)
    // console.log('hihi', params)
    // console.log(
    //   'paginationGetCurrentPage',
    //   params.api.paginationGetCurrentPage(),
    // )
    // console.log('paginationGetPageSize', params.api.paginationGetPageSize())
    // console.log('paginationGetRowCount', params.api.paginationGetRowCount())
    // console.log('purgeInfiniteCache', params.api.purgeInfiniteCache())

    changePaginationSize(params.api.paginationGetPageSize())
  },
}

const saveColumnState = (params: any) => {
  let save_state = props.type
  if (save_state == 'pm') {
    save_state = props.tab
  }

  columnChangeEvents.value = !columnChangeEvents.value
  const columnState = params.api.getColumnState()

  // console.log('save_state', save_state)
  localStorage.setItem(save_state, JSON.stringify(columnState))
}

const changePaginationSize = (newSize) => {
  let save_state_pagesize = props.type + '_pagesize'
  if (newSize != paginationPageSize.value)
    localStorage.setItem(save_state_pagesize, JSON.stringify(newSize))

  windowHeight.value = pageSizeToHeight(newSize)
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

const filterLocation = async (filterModel) => {
  let filters = {}
  if (
    filterModel['location.name'] &&
    filterModel['location.name'].filter.length > 3
  ) {
    async function getUserIdsByName(locationName) {
      const response = await fetch(
        runtimeConfig.public.directus.url +
          `items/Location?filter[name][_icontains]=${locationName}`,
        {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token.value}`,
          },
        },
      )

      console.log('Locationresponse', response)
      const data = await response.json()
      return data.data.map((location) => location.id)
    }

    const locationNameFilter = filterModel['location.name'].filter

    const locationIds = await getUserIdsByName(locationNameFilter)
    filters['location'] = {
      _in: locationIds,
    }

    // console.log('userIds', userIds)
  }

  return filters
}

// Filter functions
const filterBuild = (filterModel) => {
  let filters: any = {
    active: '1',
    company_id: myCompanyId,
  }

  let wo_status_filter = wo_status

  if (props.type == 'open') {
    wo_status_filter = open_wo_status
  } else if (props.type == 'completed') {
    wo_status_filter = completed_wo_status
  }

  if (
    filterModel.wo_status &&
    filterModel.wo_status.values &&
    filterModel.wo_status.values.length > 0
  ) {
    filters['wo_status'] = { _in: filterModel.wo_status.values }
  } else {
    const hasInArray = wo_status_filter && typeof wo_status_filter === 'object'

    const hasArray =
      Array.isArray(wo_status_filter) && wo_status_filter.length > 0

    if (hasInArray || hasArray) {
      console.log('wo_status_filter', props.type, wo_status_filter)
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

  if (filterModel.created_at) {
    const createdAtt = filterModel.created_at
    if (createdAtt.dateFrom || createdAtt.dateTo) {
      if (createdAtt.type === 'inRange') {
        filters['created_at'] = {
          _between: [createdAtt.dateFrom, createdAtt.dateTo],
        }
      } else if (createdAtt.type === 'equals') {
        filters['created_at'] = {
          _in: [createdAtt.dateFrom],
        }
      } else if (createdAtt.type === 'lessThan') {
        filters['created_at'] = {
          _lte: createdAtt.dateFrom,
        }
      } else if (createdAtt.type === 'greaterThan') {
        filters['created_at'] = {
          _gte: createdAtt.dateFrom,
        }
      } else if (createdAtt.type === 'notEqual') {
        filters['created_at'] = {
          _neq: createdAtt.dateFrom,
        }
      }
    }
    // 3. Хэрэв формат танигдахгүй бол
    else {
      console.log('Unknown transaction_date format', createdAtt)
    }
  }

  if (filterModel.started_at) {
    const started_at = filterModel.started_at
    if (started_at.dateFrom || started_at.dateTo) {
      if (started_at.type === 'equals') {
        // console.log('started_at.dateFrom', started_at.dateFrom)
        const start = started_at.dateFrom.split(' ')[0] + 'T00:00:00'
        const end = started_at.dateFrom.split(' ')[0] + 'T23:59:59.999'
        filters['started_at'] = {
          _between: [start, end],
        }
      } else if (started_at.type === 'lessThan') {
        filters['started_at'] = {
          _lt: started_at.dateFrom.split(' ')[0] + 'T00:00:00',
        }
      } else if (started_at.type === 'greaterThan') {
        filters['started_at'] = {
          _gt: started_at.dateFrom.split(' ')[0] + 'T23:59:59.999',
        }
      } else if (started_at.type === 'notEqual') {
        filters['started_at'] = {
          _or: [
            { _lt: started_at.dateFrom.split(' ')[0] + 'T00:00:00' },
            { _gt: started_at.dateFrom.split(' ')[0] + 'T23:59:59.999' },
          ],
        }
      } else if (started_at.type === 'inRange') {
        const start = started_at.dateFrom.split(' ')[0] + 'T00:00:00'
        const end = started_at.dateTo.split(' ')[0] + 'T23:59:59.999'
        filters['started_at'] = {
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
      console.log('Unknown started_at format', started_at)
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

  if (props.assigned) {
    filters['assigned_to'] = props.assigned
  }

  // splitted
  // if (props.work_order_type && props.work_order_type == 'wo') {
  //   filters['type'] = {
  //     code_work_order: props.work_order_type,
  //   }
  // }

  // if (props.work_order_type != 'request') {
  //   if (props.location) {
  //     filters['_or'] = []
  //     let temp_filter = {}
  //     temp_filter['asset'] = {
  //       location: props.location,
  //     }
  //     filters['_or'].push(temp_filter)
  //     temp_filter = {}
  //     temp_filter['location'] = props.location
  //     filters['_or'].push(temp_filter)
  //   }
  //   if (props.asset) {
  //     filters['asset'] = props.asset
  //   }
  // } else {
  //   if (props.location) {
  //     filters['location'] = props.location
  //   }
  // }

  // Request list filter
  if (props.type == 'request') {
    filters.created_type = 'request'

    filters['request_user'] = { _null: false }
    if (quickFilterStatus.value == 'request') {
      filters['wo_status'] = open_status_id
      filters['action_status'] = {
        _in: [1, 6],
      }
    }
    if (quickFilterStatus.value == 'open') {
      filters['wo_status'] = filtered_open_wo_status
      filters['action_status'] = {
        _nin: [1, 6],
      }
    }
    if (quickFilterStatus.value == 'completed') {
      filters['wo_status'] = completed_wo_status
    }

    // if (quickFilterText.value) {
    //   filters['type'] = {
    //     code_work_order: { _in: ['wo', 'request'] },
    //   }
    //   delete filters['wo_status']
    // }
  }

  // Open list filter
  if (props.type == 'open') {
    // action_status :
    //   0: deleted
    //   1: created
    //   2: approved
    //   3: returned
    //   4: assigned
    //   5: accepted
    //   6: declined

    const selectedTypes = filterModel.created_type?.values || null

    if (selectedTypes && selectedTypes.length > 0) {
      const requestSelected = selectedTypes.includes('request')
      const otherSelected = selectedTypes.filter((t) => t !== 'request')

      const orBranches = []

      if (requestSelected) {
        orBranches.push({
          created_type: 'request',
          action_status: { _in: [2, 3, 4, 5] },
        })
      }

      if (otherSelected.length > 0) {
        orBranches.push({
          created_type: { _in: otherSelected },
        })
      }

      if (orBranches.length > 0) {
        filters['_or'] = orBranches
      }
    } else {
      filters['_or'] = [
        {
          created_type: 'request',
          action_status: { _in: [2, 3, 4, 5] },
        },
        {
          created_type: {
            _in: ['pm_generated', 'pdm_generated', 'ins_generated', 'open'],
          },
        },
      ]
    }
  }

  return filters
}

const do_edit = (item) => {
  open('workorderopenmore', {
    id: item.id,
    data: item,
    wo_statuses: props.wo_status_items,
    type: props.type,
    refresh: refresh,
  })
}

const do_delete = async (item) => {
  if (await hasApprovedDebt(item.id)) {
    toaster.show({
      title: t('Error'),
      message: t('Cannot delete: this work order has an approved debt'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }
  current_row.value = item
  isModalConfirmOpen.value = true
}

const do_approve = async (item) => {
  console.log('do_approve')
  actionType.value = 'do_approve'

  // Fetch latest record from backend to avoid stale grid row data
  let latestItem = null
  try {
    const latest = await getItems<any>({
      collection: 'Work_order',
      params: withCompanyFilter({
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
      }),
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
  if (latestItem.asset == null) missingFields.push(t('Asset'))
  if (latestItem.location == null) missingFields.push(t('Location'))
  if (latestItem.assigned_team == null) missingFields.push(t('Team'))
  if (latestItem.priority == null) missingFields.push(t('Priority'))
  if (latestItem.type == null) missingFields.push(t('Group Type'))
  if (latestItem.work_type == null) missingFields.push(t('Type'))
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

  const done_returned = await createItems({
    collection: 'Work_order_actions',
    items: {
      wo_id: item.id,
      first_user: myId,
      action_status: 2,
      company_id: myCompanyId,
    },
  })

  const data = {
    collection: 'Work_order',
    id: item.id,
    item: { action_status: 2 },
  }
  await updateItem(data)

  // tools
  // const allItems = await getItems({
  //   collection: 'Work_order',
  //   params: {
  //     limit: 90, // бүх мөрийг авах
  //     filter: {
  //       wo_number: {
  //         _null: true, // зөвхөн null байгаа мөр
  //       },
  //     },
  //     fields: ['id'], // зөвхөн id авахад хангалттай
  //   },
  // })

  // console.log('allItems', allItems)

  // for (const itemm of allItems) {
  //   await updateItem({
  //     collection: 'Work_order',
  //     id: itemm.id,
  //     item: {
  //       wo_number: String(itemm.id),
  //     },
  //   })
  // }

  refresh(item)
}

const do_return = async (item, type) => {
  if (await hasApprovedDebt(item.id)) {
    toaster.show({
      title: t('Error'),
      message: t('Cannot return: this work order has an approved debt'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }
  console.log('do_return fn ')

  actionType.value = 'do_return'
  const done_returned = await createItems({
    collection: 'Work_order_actions',
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
  if (type == 'completed') {
    updateData = { wo_status: 1, action_status: 3 }
  }
  if (type == 'pm') {
    updateData = { action_status: 3 }
  }

  const data = {
    collection: 'Work_order',
    id: item.id,
    item: updateData,
  }

  await updateItem(data)
  refresh(item)
}

const do_decline = async (item, type) => {
  actionType.value = 'do_decline'
  const done_returned = await createItems({
    collection: 'Work_order_actions',
    items: {
      wo_id: item.id,
      first_user: myId,
      action_status: 6,
      company_id: myCompanyId,
    },
  })

  let updateData = {
    accepted_user: null,
    // type: 3, //???
    is_accepted: false,
    action_status: 6,
  }

  const data = {
    collection: 'Work_order',
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

  // Fetch latest record from backend to avoid stale grid row data
  let latestItem = null
  try {
    const latest = await getItems<any>({
      collection: 'Work_order',
      params: withCompanyFilter({
        filter: { id: item.id },
        fields: [
          'id',
          'asset',
          'location',
          'assigned_team',
          'priority',
          'type',
          'work_type',
          'department',
        ],
        limit: 1,
      }),
    })
    latestItem = Array.isArray(latest) ? latest[0] : latest?.data?.[0]
  } catch (e) {
    console.log('accept field check error', e)
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
  if (latestItem.asset == null) missingFields.push(t('Asset'))
  if (latestItem.location == null) missingFields.push(t('Location'))
  if (latestItem.assigned_team == null) missingFields.push(t('Team'))
  if (latestItem.priority == null) missingFields.push(t('Priority'))
  if (latestItem.type == null) missingFields.push(t('Group Type'))
  if (latestItem.work_type == null) missingFields.push(t('Type'))
  if (latestItem.department == null) missingFields.push(t('Department'))

  if (missingFields.length > 0) {
    toaster.show({
      title: t('Warning'),
      message:
        t('Please fill in required fields before accepting') +
        ': ' +
        missingFields.join(', '),
      color: 'warning',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  const do_accepted = await createItems({
    collection: 'Work_order_actions',
    items: {
      wo_id: item.id,
      first_user: myId,
      action_status: 5,
      company_id: myCompanyId,
    },
  })

  const data = {
    collection: 'Work_order',
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
        user_phone: user.value?.phone ?? '',
        action_type: 'accept REQ to WO',
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

const do_make = async (item, type) => {
  if (type == 'do_approved_wo') {
    let do_approved = await createItems({
      collection: 'Work_order_actions',
      items: {
        wo_id: item.id,
        first_user: myId,
        action_status: 2, //approved
        company_id: myCompanyId,
      },
    })

    const data = {
      collection: 'Work_order',
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
    collection: 'Work_order_schedules',
    params: withCompanyFilter({
      filter: filters,
      meta: 'filter_count',
      fields: ['*', 'schedule_id.*'],
    }),
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
          if (item.schedule_id?.repeat_types === 'completed') {
            let manual_cron_completed =
              runtimeConfig.public.directus.url +
              `db/manual_cron_completed?work_id=${item.id}`

            const response = await fetch(manual_cron_completed, {
              method: 'GET',
              headers: {
                Authorization: `Bearer ${token.value}`,
              },
            })

            console.log('Completed Response:', response)
            toaster.show({
              title: t('Created public'),
              color: 'success',
              icon: 'ph:user-circle-fill',
              closable: true,
            })
          }

          if (item.schedule_id?.repeat_types === 'direct') {
            let manual_cron =
              runtimeConfig.public.directus.url +
              `db/manual_cron?work_id=${item.id}`

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
          if (item.repeat_types === 'completed') {
            let manual_cron_completed =
              runtimeConfig.public.directus.url +
              `db/manual_cron_completed?work_id=${item.work_order}`

            const response = await fetch(manual_cron_completed, {
              method: 'GET',
              headers: {
                Authorization: `Bearer ${token.value}`,
              },
            })

            console.log('Completed Response:', response)
            toaster.show({
              title: t('Created'),
              color: 'success',
              icon: 'ph:user-circle-fill',
              closable: true,
            })
          }

          if (item.repeat_types === 'direct') {
            let manual_cron =
              runtimeConfig.public.directus.url +
              `db/manual_cron?work_id=${item.work_order}`

            const response = await fetch(manual_cron, {
              method: 'GET',
              headers: {
                Authorization: `Bearer ${token.value}`,
              },
            })

            toaster.show({
              title: t('Created'),
              color: 'success',
              icon: 'ph:user-circle-fill',
              closable: true,
            })

            console.log('Direct Response:', response)
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
    collection: 'Work_order_actions',
    items: {
      wo_id: itemId,
      first_user: myId,
      action_status: 0,
      company_id: myCompanyId,
    },
  })
}
const refresh = (item) => {
  console.log('refreshed')
  if (item) {
    // const newItem = { id: 6, name: "New Item", price: 100 };
    // const updatedData = [...gridApi.value.getDisplayedRowCount(), item];
    // gridApi.value.setRowData(updatedData);
    //   const newItem = { id: 6, name: "New Item", price: 100 };
    // gridOptions.api.applyTransaction({ add: [newItem] });
  }

  // if (quickFilterText.value != '') {
  //   gridApi.value.onFilterChanged()
  //   gridApi.value.refreshServerSide()
  //   gridApi.value.refreshInfiniteCache()
  // }

  gridApi.value.purgeInfiniteCache()
  gridApi.value.refreshCells({ force: true })
  gridApi.value.refreshServerSide({ purge: false })
  gridApi.value.deselectAll()

  // gridApi.value.paginationGoToPage(paginationGetCurrentPage.value)
  // gridApi.value.refreshServerSide()
  // gridApi.value.refreshInfiniteCache()

  // gridApi.valuerefreshServerSideStore({ purge: true });
}

const clearItem = () => {
  selectedItem.value = -1
}

const setUser = async (user) => {
  if (current_row.value) {
    const assign = await createItems({
      collection: 'Work_order_actions',
      items: {
        wo_id: current_row.value.id,
        first_user: myId,
        next_user: user.id,
        action_status: 4,
        company_id: myCompanyId,
      },
    })

    const data = {
      collection: 'Work_order',
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

    sendNotification(
      ` assigned the task to you. WO #${current_row.value.id}`,
      myId,
      user.id,
      current_row.value.id,
      'assigned',
    )
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
    gridApi.value.purgeInfiniteCache()
    gridApi.value.refreshCells({ force: true })
    gridApi.value.refreshServerSide({ purge: false })
    gridApi.value.deselectAll()
  }
}

// Тэмдэглэсэн (checkbox-оор сонгосон) мөрүүдийн дэлгэрэнгүйг хэвлэнэ —
// server-side row model дээр "select all" горимд байвал зөвхөн тухайн
// хуудсанд харагдаж буй мөрүүдийг авна (бүх мөрийн жагсаалт эх сурвалжид
// шууд байдаггүй тул)
const getCurrentPagePrintRowIds = () => {
  if (!gridApi.value) return []
  const rowCount = gridApi.value.getDisplayedRowCount()
  const ids = []
  for (let i = 0; i < rowCount; i++) {
    const rowNode = gridApi.value.getDisplayedRowAtIndex(i)
    if (rowNode && rowNode.data) ids.push(rowNode.data.id)
  }
  return ids
}

const printSelectedRows = () => {
  if (!gridApi.value) return

  const ids = []
  const { selectAll } = gridApi.value.getServerSideSelectionState()
  if (!selectAll) {
    gridApi.value.getSelectedRows().forEach((row) => {
      if (!ids.includes(row.id)) ids.push(row.id)
    })
  } else {
    getCurrentPagePrintRowIds().forEach((id) => {
      if (!ids.includes(id)) ids.push(id)
    })
  }

  if (ids.length === 0) {
    toaster.show({
      title: t('No selection'),
      color: 'danger',
    })
    return
  }

  if (ids.length > 30) {
    toaster.show({
      title: t('Too many selection'),
      color: 'danger',
    })
    return
  }

  open('printWoSummary', {
    wo_ids: ref(ids),
  })
}
const loadLocations = async (type) => {
  let filters = {
    status: '1',
  }
  const locationRes = await getItems({
    collection: 'Location',
    params: withCompanyFilter({
      filter: filters,
      meta: 'filter_count',
      fields: ['*'],
    }),
  })
  locationItem.value = locationRes.data

  console.log('locationItem', locationItem.value)
}
onMounted(async () => {
  console.log('onMounted_wo_statuses')
  // await loadLocations('work_order')
  loadAdvancedSearchTypeOptions()
})

// For multi selection
defineExpose({
  gridApi,
  refresh,
  filterBuild,
  gridOptions,
  eventType,
  columnChangeEvents,
  printSelectedRows,
})
</script>

<template>
  <div
    :class="[
      'relative work_order_list_wrapper',
      props.className ? ' ' + props.className : '',
      ['open', 'pm'].includes(props.type) ? ' tabGridBody' : '',
    ]"
  >
    <!-- Grid -->
    <div
      :class="`grid-${
        $colorMode.value === 'light' ? '' : 'dark'
      } grid grid-cols-12 work_order_list`"
    >
      <div :class="`${props.type + '_list'} col-span-12 work_status`">
        <BaseInput
          icon="lucide:search"
          :placeholder="$t('Search') + '...'"
          :classes="{
            wrapper: 'w-[340px]',
          }"
          @input="onFilterTextBoxChanged"
        />

        <div class="relative inline-block ms-2">
          <button
            type="button"
            class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 hover:border-primary-400 relative flex h-10 items-center gap-1.5 rounded-lg border bg-white px-3 text-sm text-muted-500 dark:text-muted-300 transition-colors"
            @click="isAdvancedSearchOpen = !isAdvancedSearchOpen"
          >
            <Icon name="lucide:sliders-horizontal" class="h-4 w-4" />
            <!-- {{ $t('Advanced search') }} -->
            <span
              v-if="hasActiveAdvancedSearch"
              class="bg-primary-500 absolute -right-1 -top-1 h-2.5 w-2.5 rounded-full border-2 border-white dark:border-muted-800"
            />
          </button>

          <Transition
            enter-active-class="transition duration-100 ease-out"
            enter-from-class="opacity-0 scale-95"
            enter-to-class="opacity-100 scale-100"
            leave-active-class="transition duration-75 ease-in"
            leave-from-class="opacity-100 scale-100"
            leave-to-class="opacity-0 scale-95"
          >
            <div
              v-if="isAdvancedSearchOpen"
              class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 absolute start-0 top-12 z-50 w-72 rounded-lg border bg-white p-4 shadow-lg"
            >
              <div class="mb-3">
                <label class="text-muted-500 mb-1 block text-xs font-medium">
                  {{ $t('Trades') }}
                </label>
                <select
                  v-model="advancedSearch.trades"
                  class="border-muted-300 dark:border-muted-600 dark:bg-muted-900 w-full rounded-md border px-2 py-1.5 text-sm"
                >
                  <option value="any">{{ $t('All') }}</option>
                  <option value="yes">{{ $t('Registered') }}</option>
                  <option value="no">{{ $t('Not registered') }}</option>
                </select>
              </div>
              <div class="mb-3">
                <label class="text-muted-500 mb-1 block text-xs font-medium">
                  {{ $t('Parts') }}
                </label>
                <select
                  v-model="advancedSearch.parts"
                  class="border-muted-300 dark:border-muted-600 dark:bg-muted-900 w-full rounded-md border px-2 py-1.5 text-sm"
                >
                  <option value="any">{{ $t('All') }}</option>
                  <option value="yes">{{ $t('Registered') }}</option>
                  <option value="no">{{ $t('Not registered') }}</option>
                </select>
              </div>
              <div class="mb-3">
                <label class="text-muted-500 mb-1 block text-xs font-medium">
                  {{ $t('Group type') }}
                </label>
                <select
                  v-model="advancedSearch.groupType"
                  class="border-muted-300 dark:border-muted-600 dark:bg-muted-900 w-full rounded-md border px-2 py-1.5 text-sm"
                >
                  <option value="any">{{ $t('All') }}</option>
                  <option
                    v-for="opt in groupTypeOptions"
                    :key="opt.id"
                    :value="opt.id"
                  >
                    {{ opt.name }}
                  </option>
                </select>
              </div>
              <div class="mb-4">
                <label class="text-muted-500 mb-1 block text-xs font-medium">
                  {{ $t('Work Type') }}
                </label>
                <select
                  v-model="advancedSearch.workType"
                  class="border-muted-300 dark:border-muted-600 dark:bg-muted-900 w-full rounded-md border px-2 py-1.5 text-sm"
                >
                  <option value="any">{{ $t('All') }}</option>
                  <option
                    v-for="opt in workTypeOptions"
                    :key="opt.id"
                    :value="opt.id"
                  >
                    {{ opt.code }}
                  </option>
                </select>
              </div>
              <div class="mb-4">
                <label class="text-muted-500 mb-1 block text-xs font-medium">
                  {{ $t('Department') }}
                </label>
                <FormKit
                  name="advanced_department"
                  type="autocomplete2"
                  collection_name="Department"
                  :label="''"
                  item_value="id"
                  item_title="name"
                  search_field="name"
                  :placeholder="$t('All')"
                  :initial_filter="{ status: 'published' }"
                  :value="selectedDepartment"
                  :setParentValue="onAdvancedDepartmentPicked"
                />
              </div>
              <div class="flex justify-end gap-2">
                <BaseButton
                  size="sm"
                  color="muted"
                  @click="clearAdvancedSearch"
                >
                  {{ $t('Clear') }}
                </BaseButton>
                <BaseButton
                  size="sm"
                  color="primary"
                  @click="applyAdvancedSearch"
                >
                  {{ $t('Apply') }}
                </BaseButton>
              </div>
            </div>
          </Transition>
        </div>

        <!-- <button
          type="button"
          class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 hover:border-primary-400 relative flex h-10 items-center gap-1.5 rounded-lg border bg-white px-3 ms-2 text-sm text-muted-500 dark:text-muted-300 transition-colors"
          @click="printSelectedRows"
        >
          <Icon name="solar:printer-2-broken" class="h-4 w-4" />
          {{ $t('Report') }}
        </button> -->

        <div v-if="props.type == 'request'" class="ms-auto">
          <TairoContentWrapperTabbed
            :labels="Object.values(filter_modules)"
            @update:modelValue="onTabChange"
            shape="curved"
            class="!mb-0"
          />
        </div>
      </div>
      <!-- Header -->
      <div class="col-span-12">
        <ag-grid-vue
          :key="key"
          :style="{ width: '100%', height: windowHeight + 'px' }"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list ${props.type}_ag_grid`"
          :columnDefs="columnDefs"
          :gridOptions="gridOptions"
          :quickFilterText="quickFilterText"
          @grid-ready="onGridReady"
          :rowData="rowData"
          :onColumnMoved="saveColumnState"
          :onColumnPinned="saveColumnState"
          :onColumnVisible="saveColumnState"
          :onColumnResized="saveColumnState"
          @sort-changed="saveColumnState"
          @selection-changed="selectionChanged"
          @filter-changed="onGridFilterChanged"
        >
        </ag-grid-vue>
        <UserList
          :open="isModalUserListOpen"
          :close="handleModalUserListClose"
          :setUser="setUser"
        />
        <ConfirmModalForm
          :itemsValue="itemsValue"
          code="Work_order"
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
          code="Work_order"
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
.work_order_list {
  min-height: 560px !important;
}
.ag-popup {
  z-index: 9999 !important;
}
.work_order_list .ag-center-cols-container {
  overflow: visible;
  display: flex;
  flex-direction: column;
}
.work_order_list .ag-row {
  overflow: visible;
  position: relative;
  transform: none !important;
  /* width: inherit; */
}
.work_order_list .ag-row .status-cell,
.work_order_list .ag-row .priority-cell {
  border: none !important;
}
.work_order_list .ag-row .actions-cell {
  overflow: visible;
  border: none !important;
}

.work_order_list .ag-row .actions-hide {
  display: none;
}
.work_order_list .work_status {
  display: flex;
  justify-content: flex-start;
  margin-bottom: 4px;
}
.work_order_list .open_list.work_status,
.work_order_list .completed_list.work_status,
.work_order_list .allworks_list {
  margin-bottom: 24px;
}

.grid-dark .tabButton.active:focus-visible,
.work_order_list .tabButton.active:focus-visible {
  outline: 2px dashed #cbd5e1 !important;
  outline-offset: 3px;
}
.work_order_list .ag-cell.empty_action {
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
