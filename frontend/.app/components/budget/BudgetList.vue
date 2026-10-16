<script setup lang="ts">
import type { ColDef } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import ActionDropdownCellRenderer from '~/components/ag_grid/ActionDropdownCellRenderer.vue'
import { fetchPageData } from '~/components/ag_grid/ag_grid_directus'
import StatusCellRenderer from '~/components/ag_grid/statusCellRenderer.vue'
import BudgetModalForm from '~/components/budget/BudgetModalForm.vue'
import { sendNotification } from '../../compsables/sendNotification'

const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const { updateItem, getItems, createItems } = useDirectusItems()
const myId = window.localStorage.getItem('myId')
const router = useRouter()
const myCompanyId = getMyCompanyId()

const props = defineProps({
  gridTheme: { type: String, default: 'ag-theme-quartz' },
  isDarkMode: { type: Boolean },
})

const themeClass = computed(
  () => `${props.gridTheme}${props.isDarkMode ? '-dark' : ''}`,
)

const gridApi = ref<any>(null)
const currentPage = ref(1)
const paginationPageSize = ref(20)
const lastRow = ref(0)
const dataSource = ref({})
const quickFilterText = ref('')
const windowHeight = ref(980)
const request = ref<any>(null)
let isClickNextPage = false
let previousStartRow = 0

const current_row = ref(null)
const isModalConfirmOpen = ref(false)
const isModalUserListOpen = ref(false)
const selectedItem = ref(-1)

const isEditModalOpen = ref(false)
const editBudgetId = ref<number | null>(null)

const actualAmountsMap = ref<Record<number, number>>({})
const plannedAmountsMap = ref<Record<number, number>>({})

const loadActualAmounts = async (budgetIds: number[]) => {
  if (!budgetIds.length) return
  try {
    const resp = await getItems({
      collection: 'Work_order',
      params: withCompanyFilter({
        filter: { budget: { _in: budgetIds } },
        groupBy: ['budget'],
        aggregate: { sum: 'budget_actual_amount,budget_planned_amount' },
        limit: -1,
      }),
    })
    const data = Array.isArray(resp) ? resp : (resp as any)?.data || []
    data.forEach((r: any) => {
      actualAmountsMap.value[r.budget] = Number(
        r.sum?.budget_actual_amount ?? 0,
      )
      plannedAmountsMap.value[r.budget] = Number(
        r.sum?.budget_planned_amount ?? 0,
      )
    })
    gridApi.value?.forEachNode((node: any) => {
      if (node.data?.id != null) {
        node.data.budget_actual_amount =
          actualAmountsMap.value[node.data.id] ?? 0
        node.data.budget_planned_amount =
          plannedAmountsMap.value[node.data.id] ?? 0
      }
    })
    gridApi.value?.refreshCells({
      columns: [
        'budget_planned_amount',
        'budget_actual_amount',
        'budget_remaining',
      ],
      force: true,
    })
  } catch (e) {
    console.error('loadActualAmounts error', e)
  }
}

const MAX_DEPTH = 5

const buildFields = () => {
  const base = [
    'id',
    'budget_code',
    'budget_name',
    'total_amount',
    'used_amount',
    'start_date',
    'end_date',
    'status',
    'account_number',
    'parent',
    'location.id',
    'location.name',
  ]
  const extra: string[] = []
  for (let i = 1; i <= MAX_DEPTH; i++) {
    const prefix = Array(i).fill('children').join('.')
    base.forEach((f) => extra.push(`${prefix}.${f}`))
  }
  return [...base, ...extra]
}

const do_edit = (item: any) => {
  editBudgetId.value = item.id
  isEditModalOpen.value = true
}

const closeEditModal = () => {
  isEditModalOpen.value = false
  editBudgetId.value = null
}

const do_delete_confirm = (item: any) => {
  selectedItem.value = item.id
  isModalConfirmOpen.value = true
}

// ─── Permission flags ─────────────────────────────────────────────────────────
const doDeleted = ref(true)
const doAssigned = ref(true)
const doApproved = ref(true)
const doDeclined = ref(true)

// ─── Status actions ───────────────────────────────────────────────────────────
const do_delete = async (item: any) => {
  await createItems({
    collection: 'Budget_actions',
    items: {
      budget_id: item.id,
      first_user: myId,
      action_status: 'deleted',
      company_id: myCompanyId,
    },
  })

  await updateItem({
    collection: 'Budget',
    id: item.id,
    item: { status: 'Deleted' },
  })
  refreshGrid()
}

const setUser = async (user) => {
  console.log('setUser', user)
  console.log('current_row', current_row)
  if (current_row.value) {
    const assign = await createItems({
      collection: 'Budget_actions',
      items: {
        budget_id: current_row.value.id,
        first_user: myId,
        next_user: user.id,
        action_status: 'assigned',
        company_id: myCompanyId,
      },
    })

    const data = {
      collection: 'Budget',
      id: current_row.value.id,
      item: {
        assigned_to: user.id,
        status: 'Assigned',
      },
    }

    await updateItem(data)
    isModalUserListOpen.value = false
    refreshGrid()
    toaster.show({
      title: t('Update'),
      message: t(`Record assigned successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })

    sendNotification(
      ` assigned budget to you. #${current_row.value.id}`,
      myId,
      user.id,
      current_row.value.id,
      'assigned',
    )
  }
}

const handleModalUserListClose = () => {
  isModalUserListOpen.value = false
}

const do_assign = async (item: any) => {
  console.log('do_assign', item)

  isModalUserListOpen.value = true
  current_row.value = item
}

const do_approve = async (item: any) => {
  await createItems({
    collection: 'Budget_actions',
    items: {
      budget_id: item.id,
      first_user: myId,
      action_status: 'approved',
      company_id: myCompanyId,
    },
  })

  await updateItem({
    collection: 'Budget',
    id: item.id,
    item: { status: 'Approved', approved_user: myId },
  })
  refreshGrid()
}

const do_decline = async (item: any) => {
  await createItems({
    collection: 'Budget_actions',
    items: {
      budget_id: item.id,
      first_user: myId,
      action_status: 'declined',
      company_id: myCompanyId,
    },
  })
  await updateItem({
    collection: 'Budget',
    id: item.id,
    item: { status: 'Declined' },
  })
  refreshGrid()
}

// ─── Column definitions ───────────────────────────────────────────────────────
const columnDefs = ref<ColDef[]>([
  {
    field: 'budget_name',
    headerName: t('Budget Name'),
    minWidth: 200,
    flex: 1,
    sortable: true,
    filter: 'agTextColumnFilter',
    filterParams: {
      maxNumConditions: 1,
      filterOptions: ['contains'],
      buttons: ['reset'],
    },
  },
  {
    field: 'total_amount',
    headerName: t('Total Amount') + ' (₮)',
    minWidth: 150,
    sortable: true,
    filter: false,
    valueFormatter: ({ value }) =>
      value != null ? Number(value).toLocaleString() : '-',
    cellStyle: { textAlign: 'right' },
    headerClass: 'ag-right-aligned-header',
  },
  {
    field: 'used_amount',
    headerName: t('Used') + ' (₮)',
    minWidth: 140,
    sortable: false,
    filter: false,
    valueFormatter: ({ value }) =>
      value != null ? Number(value).toLocaleString() : '-',
    cellStyle: { textAlign: 'right' },
    headerClass: 'ag-right-aligned-header',
  },
  {
    field: 'budget_planned_amount',
    headerName: t('Planned') + ' (₮)',
    minWidth: 150,
    sortable: false,
    filter: false,
    valueFormatter: ({ value }) =>
      value != null && value !== 0 ? Number(value).toLocaleString() : '-',
    cellStyle: { textAlign: 'right' },
    headerClass: 'ag-right-aligned-header',
  },
  {
    field: 'budget_actual_amount',
    headerName: t('Actual Used') + ' (₮)',
    minWidth: 150,
    sortable: false,
    filter: false,
    valueFormatter: ({ value }) =>
      value != null && value !== 0 ? Number(value).toLocaleString() : '-',
    cellStyle: { textAlign: 'right' },
    headerClass: 'ag-right-aligned-header',
  },
  {
    field: 'budget_remaining',
    headerName: t('Remaining') + ' (₮)',
    minWidth: 150,
    sortable: false,
    filter: false,
    valueGetter: (params: any) => {
      if (!params.data) return null
      const total = Number(params.data.total_amount ?? 0)
      const actual = Number(params.data.budget_actual_amount ?? 0)
      return total > 0 || actual > 0 ? total - actual : null
    },
    valueFormatter: ({ value }: any) =>
      value != null ? Number(value).toLocaleString() : '-',
    cellStyle: (params: any) => ({
      textAlign: 'right',
      fontWeight: '600',
      color:
        params.value == null ? '' : params.value < 0 ? '#ef4444' : '#16a34a',
    }),
    headerClass: 'ag-right-aligned-header',
  },
  {
    field: 'start_date',
    headerName: t('Start Date'),
    minWidth: 120,
    sortable: true,
    filter: false,
    valueFormatter: ({ value }) => (value ? String(value).slice(0, 10) : ''),
  },
  {
    field: 'end_date',
    headerName: t('End Date'),
    minWidth: 120,
    sortable: true,
    filter: false,
    valueFormatter: ({ value }) => (value ? String(value).slice(0, 10) : ''),
  },
  {
    field: 'status',
    headerName: t('Status'),
    minWidth: 120,
    sortable: false,
    filter: 'agSetColumnFilter',
    filterParams: {
      values: [
        'Active',
        'Approved',
        'Assigned',
        'Declined',
        'Deleted',
        'Closed',
        'Inactive',
      ],
    },
    valueFormatter: ({ value }) => value ?? '',
    cellRenderer: StatusCellRenderer,
    cellRendererParams: { width: '74px' },
    cellStyle: {
      display: 'flex',
      justifyContent: 'center',
      marginTop: '8px',
    },
  },
  {
    headerName: 'Location',
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
  },
  {
    field: 'account_number',
    headerName: t('Account No'),
    minWidth: 130,
    sortable: false,
    filter: false,
    hide: true,
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

      if (['Active'].includes(params.data.status)) {
        actions.onEditClick = do_edit
        if (doDeleted.value) actions.onDeleteClick = do_delete
        if (doAssigned.value) actions.onAssignClick = do_assign
        if (doApproved.value) actions.onApproveClick = do_approve
        if (doDeclined.value) actions.onDeclinedClick = do_decline
      }

      //approved
      if (params.data.status === 'Approved') {
        if (doDeclined.value) actions.onDeclinedClick = do_decline
      }

      //assigned
      if (params.data.status === 'Assigned') {
        if (doAssigned.value) actions.onAssignClick = do_assign
        if (doApproved.value) actions.onApproveClick = do_approve
        if (doDeclined.value) actions.onDeclinedClick = do_decline
      }

      //declined
      if (params.data.status === 'Declined') {
        actions.onEditClick = do_edit
        if (doDeleted.value) actions.onDeleteClick = do_delete
        if (doAssigned.value) actions.onAssignClick = do_assign
        if (doApproved.value) actions.onApproveClick = do_approve
      }

      //deleted
      if (params.data.status === 'Deleted') {
        actions.onEditClick = do_edit
        if (doAssigned.value) actions.onAssignClick = do_assign
        if (doApproved.value) actions.onApproveClick = do_approve
      }
      return actions
    },

    // cellRendererParams: {
    //   onEditClick: do_edit,
    //   onDeleteClick: do_delete_confirm,
    // },
    cellClass: 'actions-cell',
    cellStyle: {},
  },
])

// ─── Grid options ─────────────────────────────────────────────────────────────
const gridOptions = {
  rowModelType: 'serverSide',
  paginationPageSize: 20,
  paginationPageSizeSelector: [10, 20, 50, 100],
  cacheBlockSize: 20,
  pagination: true,
  serverSideDatasource: dataSource.value,
  defaultColDef: { flex: 1 },
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

  treeData: true,
  groupDefaultExpanded: -1,
  isServerSideGroupOpenByDefault: () => false,
  isServerSideGroup: (dataItem: any) => {
    return dataItem.children?.length > 0 ? dataItem.children : false
  },
  getServerSideGroupKey: (dataItem: any) => dataItem.id,

  autoGroupColumnDef: {
    headerName: t('Code'),
    field: 'budget_code',
    minWidth: 250,
    sortable: false,
    cellRendererParams: { suppressCount: true },
    onCellClicked: (params: any) => {
      if (params.colDef.field === 'budget_code') {
        router.push(`/budgets/${params.data.id}`)
      }
    },
    filter: 'agTextColumnFilter',
    filterParams: {
      maxNumConditions: 1,
      filterOptions: ['contains', 'equals'],
      buttons: ['reset'],
    },
  },

  onPaginationChanged: (params: any) => {
    if (gridApi.value) {
      currentPage.value = gridApi.value.paginationGetCurrentPage()
      const currentStartRow = currentPage.value * paginationPageSize.value
      if (currentPage.value > 0 && currentStartRow !== previousStartRow) {
        isClickNextPage = true
        previousStartRow = currentStartRow
      }
    }
  },
}

// ─── Data fetching ────────────────────────────────────────────────────────────
async function getData(params: any, extraFilter: any = {}) {
  const { sortModel } = params.request
  const sortField = sortModel.length ? sortModel[0].colId : 'budget_code'
  const sortOrder = sortModel.length ? sortModel[0].sort : 'asc'

  const filter: any = { parent: { _null: true }, ...extraFilter }

  return fetchPageData({
    currentPage: currentPage.value + 1,
    pageSize: paginationPageSize.value,
    sortField,
    sortOrder,
    filters: filter,
    collection: 'Budget',
    fields: buildFields(),
  })
}

function mappingChildren(data: any[], params: any) {
  const result = {
    rowData: data,
    lastRow: lastRow.value,
    rowCount: lastRow.value,
  }
  setTimeout(() => {
    params.success(result)
    const groupingChildren = (route: string[], node: any) => {
      if (node.children?.length) {
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
    result.rowData.forEach((top: any) => groupingChildren([top.id], top))

    // Collect all budget IDs (top-level + nested children)
    const collectIds = (nodes: any[]): number[] => {
      const ids: number[] = []
      const traverse = (items: any[]) => {
        items.forEach((item) => {
          if (item.id) ids.push(item.id)
          if (item.children?.length) traverse(item.children)
        })
      }
      traverse(nodes)
      return ids
    }
    const allIds = collectIds(result.rowData)
    loadActualAmounts(allIds)
  }, 200)
}

const onGridReady = (params: any) => {
  const savedState = localStorage.getItem('budgetColumnState')
  if (savedState) {
    params.api.applyColumnState({
      state: JSON.parse(savedState),
      applyOrder: true,
    })
  }

  gridApi.value = params.api
  request.value = params.request

  dataSource.value = {
    getRows: async (params: any) => {
      const filterModel = gridApi.value.getFilterModel()
      const extraFilter: any = {}

      if (filterModel.budget_code?.filter)
        extraFilter.budget_code = { _icontains: filterModel.budget_code.filter }
      if (filterModel['ag-Grid-AutoColumn']?.filter) {
        const type = filterModel['ag-Grid-AutoColumn'].type
        extraFilter.budget_code =
          type === 'equals'
            ? { _eq: filterModel['ag-Grid-AutoColumn'].filter }
            : { _icontains: filterModel['ag-Grid-AutoColumn'].filter }
      }
      if (filterModel.budget_name?.filter)
        extraFilter.budget_name = { _icontains: filterModel.budget_name.filter }
      if (filterModel['location.name']?.filter)
        extraFilter.location = {
          name: { _icontains: filterModel['location.name'].filter },
        }
      if (filterModel.status?.values?.length)
        extraFilter.status = { _in: filterModel.status.values }

      currentPage.value = gridApi.value.paginationGetCurrentPage()

      const result = await getData(params, extraFilter)
      const rows = result?.data || []
      lastRow.value = result?.totalCount || 0

      if (rows.length > 0) {
        mappingChildren(rows, params)
        isClickNextPage = false
        gridApi.value.hideOverlay()
      } else {
        params.success({ rowData: [], rowCount: 0 })
        gridApi.value.showNoRowsOverlay()
      }
    },
  }
  params.api.setGridOption('serverSideDatasource', dataSource.value)
}

const refreshGrid = () => {
  isModalConfirmOpen.value = false
  selectedItem.value = -1
  gridApi.value?.refreshServerSide()
  gridApi.value?.onFilterChanged()
}

const doDelete = async () => {
  if (!selectedItem.value || selectedItem.value < 0) return
  await updateItem({
    collection: 'Budget',
    id: selectedItem.value,
    item: { status: 'Deleted' },
  })
  refreshGrid()
}

const onRowClicked = (params: any) => {
  if (params.column?.colId === 'actions') return
}

const saveColumnState = (params: any) => {
  const state = params.api.getColumnState()
  localStorage.setItem('budgetColumnState', JSON.stringify(state))
}

const onFilterChange = ({ target: { value } }: any) => {
  setTimeout(() => {
    if (value.length > 2 || value.length === 0) {
      quickFilterText.value = value
      refreshGrid()
    }
  }, 300)
}

onMounted(() => {
  // restore column state if saved
})
</script>

<template>
  <div class="relative tabGridBody">
    <div :class="themeClass">
      <TairoContentWrapper>
        <template #left>
          <BaseInput
            icon="lucide:search"
            :placeholder="t('Search...')"
            :classes="{ wrapper: 'w-[300px]' }"
            @input="onFilterChange"
          />
        </template>
      </TairoContentWrapper>

      <ag-grid-vue
        :style="{ height: `${windowHeight}px` }"
        :class="`ag-theme-quartz${
          $colorMode.value === 'light' ? '' : '-dark'
        } grid_ag_tree`"
        :columnDefs="columnDefs"
        :gridOptions="gridOptions"
        :quickFilterText="quickFilterText"
        @grid-ready="onGridReady"
        @row-clicked="onRowClicked"
        @column-moved="saveColumnState"
        @column-pinned="saveColumnState"
        @column-visible="saveColumnState"
        @column-resized="saveColumnState"
        @sort-changed="saveColumnState"
      />

      <!-- Edit modal -->
      <BudgetModalForm
        :open="isEditModalOpen"
        :budgetId="editBudgetId"
        :close="closeEditModal"
        :refresh="refreshGrid"
      />

      <!-- Delete confirm modal -->
      <TairoModal
        :open="isModalConfirmOpen"
        size="sm"
        @close="isModalConfirmOpen = false"
      >
        <template #header>
          <div class="flex w-full items-center justify-between p-4">
            <h3
              class="font-heading text-muted-900 text-base font-medium dark:text-white pl-2"
            >
              {{ t('Confirm Delete') }}
            </h3>
            <BaseButtonClose @click="isModalConfirmOpen = false" />
          </div>
        </template>
        <div class="px-6 py-4 text-sm text-muted-600 dark:text-muted-300">
          {{ t('Are you sure you want to deactivate this budget?') }}
        </div>
        <template #footer>
          <div class="p-4 flex justify-end gap-3">
            <BaseButton shape="rounded" @click="isModalConfirmOpen = false">{{
              t('Cancel')
            }}</BaseButton>
            <BaseButton color="danger" shape="rounded" @click="doDelete">{{
              t('Confirm')
            }}</BaseButton>
          </div>
        </template>
      </TairoModal>

      <UserList
        :open="isModalUserListOpen"
        :close="handleModalUserListClose"
        :setUser="setUser"
      />
    </div>
  </div>
</template>

<style>
.grid_ag_tree .ag-row {
  overflow: visible;
}
.grid_ag_tree .ag-row .actions-cell {
  overflow: visible;
}
</style>
