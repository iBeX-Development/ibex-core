<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { format } from 'date-fns'

import ModalItemsList from '~/components/form/ModalItemsList.vue'

const { t } = useI18n({ useScope: 'global' })

const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

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

const props = defineProps([
  'estimated_edit',
  'actual_edit',
  'work_order',
  'collection',
  'trade_collection',
  'freeze',
])

const collectionName = computed(
  () => props.collection || 'Work_order_Tradecode',
)
const tradeCollectionName = computed(
  () => props.trade_collection || 'Tradecode',
)
const trade_codes = ref<any[]>([])
const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selectedRow = ref(-1)
const detailRowAutoHeight = true

const loading = ref(true)
const gridApi = ref()
const { params } = useRoute()
const rowData = ref<any[]>([])
const key = ref<number | string>(1)

// Duration dialog state
const pendingTrade = ref<any>(null)
const totalDurationInput = ref<number>(0)
const showDurationDialog = ref(false)

const workDays = computed(() => {
  const started_at = props.work_order?.started_at
  const due = props.work_order?.due
  if (!started_at || !due) return 1
  const diffMs = new Date(due).getTime() - new Date(started_at).getTime()
  const diffDays = Math.round(diffMs / (1000 * 60 * 60 * 24))
  return diffDays > 0 ? diffDays : 1
})

const durationPerDay = computed(() => {
  const total = Number(totalDurationInput.value) || 0
  return total > 0 ? Math.round((total / workDays.value) * 100) / 100 : 0
})

const pinnedTotals = computed(() => {
  const rows = rowData.value
  if (!rows.length) return []
  return [
    {
      trade: { code: 'Нийт' },
      duration:
        Math.round(
          rows.reduce((s: number, r: any) => s + (Number(r.duration) || 0), 0) *
            100,
        ) / 100,
      total:
        Math.round(
          rows.reduce((s: number, r: any) => s + (Number(r.total) || 0), 0) *
            100,
        ) / 100,
      actual_duration:
        Math.round(
          rows.reduce(
            (s: number, r: any) => s + (Number(r.actual_duration) || 0),
            0,
          ) * 100,
        ) / 100,
      actual_total:
        Math.round(
          rows.reduce(
            (s: number, r: any) => s + (Number(r.actual_total) || 0),
            0,
          ) * 100,
        ) / 100,
      _isTotal: true,
    },
  ]
})

const autoSizeStrategy = {
  type: 'fitGridWidth',
}

const gridOptions = ref({
  domLayout: 'autoHeight' as const,
  defaultColDef: {
    sortable: true,
    filter: false,
    resizable: true,
    suppressAutoSize: true,
    autoSizeAllColumns: true,
    suppressHeaderMenuButton: true,
    autoSizeStrategy: {
      type: 'fitCellContents',
    },

    // wrapHeaderText: true, // Header name багтахгүй бол багана дотор хугалж бичих
    // autoHeaderHeight: true, // Толгойн өндөр автоматаар тохирох
    flex: 0,
  },
  rowSelection: 'multiple' as const,
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
  // suppressHorizontalScroll: true, // Хэвтээ scroll идэвхгүй болгох
})

const columnDefs = ref([
  {
    headerName: t('Planned'),
    children: [
      {
        headerName: t(''),
        checkboxSelection: true,
        headerCheckboxSelection: true,
        width: 40,
      },
      {
        headerName: t('Created'),
        field: 'created_at',
        sortable: true,
        filter: false,
        editable: false,
        width: 240,
        valueGetter: (params) => {
          if (params.data?.created_at) {
            const date = new Date(params.data.created_at)
            return format(date, 'yyyy-MM-dd HH:mm') // Format the date
          } else {
            return ''
          }
        },
      },
      {
        headerName: t('Date'),
        field: 'scheduled_date',
        sortable: true,
        sort: 'asc',
        filter: false,
        width: 160,
        editable: false,
        valueFormatter: (params: any) => {
          if (!params.value) return ''
          const d = new Date(params.value)
          return d.toLocaleString('mn-MN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
          })
        },
      },
      {
        headerName: t('Code'),
        field: 'trade.code',
        sortable: true,
        filter: false,
        width: 180,
        editable: props.work_order?.action_status === 2 ? false : true, //approved
        cellEditor: 'agRichSelectCellEditor',
        cellEditorParams: (params: any) => {
          // Extract the values (display text) from the options
          return {
            values: trade_codes.value.map((opt) => opt.name),
          }
        },
        onCellValueChanged: (params: any) => {
          console.log(params.newValue)
          const selectedOption = trade_codes.value.find(
            (opt) => opt.name === params.newValue,
          )
          if (selectedOption) {
            params.data.rate = selectedOption.rate
            params.data.trade = {
              ...params.data.trade,
              id: selectedOption.id,
              rate: selectedOption.rate,
            }
            params.data.total =
              Math.round(
                selectedOption.rate * (Number(params.data.duration) || 0) * 100,
              ) / 100
            asyncUpdateRow(params.data)
            params.node.setDataValue('rate', selectedOption.rate)
            params.node.setDataValue('total', params.data.total)
            const row = rowData.value.find((r: any) => r.id === params.data.id)
            if (row) {
              row.rate = params.data.rate
              row.total = params.data.total
              row.trade = params.data.trade
            }
          }
        },
      },
      {
        headerName: t('Name'),
        field: 'name',
        sortable: true,
        filter: false,
        width: 180,
        editable: false,
        onCellValueChanged: (params: any) => {
          params.data.name = params.newValue
          asyncUpdateRow(params.data)
        },
      },
      {
        headerName: t('Duration'),
        headerClass: () =>
          props.work_order?.action_status === 2 || props.freeze
            ? ''
            : 'edit_duration', // Динамик class тохируулах
        field: 'duration',
        sortable: true,
        filter: false,
        width: 180,
        editable:
          props.work_order?.action_status === 2 || props.freeze ? false : true, //approved
        onCellValueChanged: (params: any) => {
          console.log('onCellValueChanged', params)
          const duration = Number(params.newValue) || 0
          const rate = params.data.trade?.rate ?? params.data.rate ?? 0
          const total = Math.round(rate * duration * 100) / 100
          params.data.duration = duration
          params.data.rate = rate
          params.data.total = total
          asyncUpdateRow(params.data)
          params.node.setDataValue('rate', rate)
          params.node.setDataValue('total', total)
          // In-place mutation: only updates pinnedTotals without triggering AG Grid full re-render
          const row = rowData.value.find((r: any) => r.id === params.data.id)
          if (row) {
            row.duration = duration
            row.rate = rate
            row.total = total
          }
        },
      },
      {
        headerName: t('Rate'),
        field: 'rate',
        sortable: true,
        filter: false,
        editable: false,
        width: 180,
      },
      {
        headerName: t('Total'),
        field: 'total',
        sortable: true,
        filter: false,
        editable: false,
        width: 180,
      },
    ],
  },
  {
    headerName: t('Actual'),
    children: [
      {
        headerName: t('Duration'),
        field: 'actual_duration',
        headerClass: () => (props.actual_edit ? 'edit_duration' : ''), // Динамик class тохируулах
        sortable: true,
        filter: false,
        width: 180,
        editable: props.actual_edit,
        onCellValueChanged: ({ node, data, newValue }: any) => {
          console.log('params', data)
          const duration = Number(newValue) || 0
          const rate =
            data.actual_rate > 0
              ? data.actual_rate
              : data.trade?.rate ?? data.rate ?? 0
          const total = Math.round(rate * duration * 100) / 100
          data.actual_duration = duration
          data.actual_rate = rate
          data.actual_total = total
          asyncUpdateRow(data)
          node.setDataValue('actual_rate', rate)
          node.setDataValue('actual_total', total)
          const row = rowData.value.find((r: any) => r.id === data.id)
          if (row) {
            row.actual_duration = duration
            row.actual_rate = rate
            row.actual_total = total
          }
        },
        cellClass: props.actual_edit ? 'edit_duration' : '',
      },
      {
        headerName: t('Rate'),
        field: 'actual_rate',
        sortable: true,
        filter: false,
        width: 180,
        editable: false,
        onCellValueChanged: ({ node, data, newValue }: any) => {
          data.actual_rate = Number(newValue) || 0
          data.actual_total =
            Math.round(data.actual_duration * data.actual_rate * 100) / 100
          asyncUpdateRow(data)
          node.setDataValue('actual_total', data.actual_total)
          const row = rowData.value.find((r: any) => r.id === data.id)
          if (row) {
            row.actual_rate = data.actual_rate
            row.actual_total = data.actual_total
          }
        },
      },
      {
        headerName: t('Total'),
        field: 'actual_total',
        sortable: true,
        filter: false,
        editable: false,
        width: 180,
      },
    ],
  },
])

const loadItems = async ({
  page,
  itemsPerPage,
}: {
  page: number
  itemsPerPage: number
}) => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: props.work_order?.id,
    }

    // scheduled_date
    const items = await getItems<any>({
      collection: collectionName.value,
      params: {
        filter: filters,
        sort: 'id',
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*', 'trade.*', 'work_order.* '],
      },
    })
    rowData.value = items.data
    loading.value = false
  } catch (e) {}
}

const loadTrades = async ({
  page,
  itemsPerPage,
}: {
  page: number
  itemsPerPage: number
}) => {
  try {
    const filters = {
      status: '1',
      company_id: { _eq: myCompanyId },
    }
    const items = await getItems<any>({
      collection: tradeCollectionName.value,
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*', 'trade.*', 'work_order.* '],
      },
    })
    trade_codes.value = items.data
  } catch (e) {}
}

const onGridReady = async (grid_params: any) => {
  gridApi.value = grid_params.api
  grid_params.api.sizeColumnsToFit({
    defaultMinWidth: 600,
    columnLimits: [{ key: 'name', minWidth: 100 }],
  }) // Багануудыг дэлгэцэнд тааруулах

  grid_params.api.autoSizeAllColumns()

  // const datasource = createServerSideDatasource()
  // await gridApi.value.setGridOption('serverSideDatasource', datasource)
}

const getRowNodeId = (data: any) => {
  return data.id
}

const asyncUpdateRow = async (data: any) => {
  console.log('Update data : ', data)
  if (data && data.id) {
    const updateData = {
      collection: collectionName.value,
      id: data.id,
      item: {
        name: data.name,
        rate: data.rate,
        total: data.total,
        duration: data.duration,
        scheduled_date: data.scheduled_date,
        actual_duration: data.actual_duration,
        actual_rate: data.actual_rate,
        actual_total: data.actual_total,
        trade: data.trade?.id,
      },
    }
    updateItem(updateData)
  }
}

const asyncInsertRow = async (data: any) => {
  const insertData: any = data
  console.log(insertData)
  insertData.work_order = props.work_order?.id
  insertData.trade = getDefaultRow()?.id
  insertData.company_id = myCompanyId
  // delete insertData["work_order.id"]
  createItems({
    collection: collectionName.value,
    items: [insertData],
  }).then((response: any[]) => {
    const rowDataOverride: any = response[0]
    rowDataOverride.trade = {
      id: response[0].trade,
      name: trade_codes.value.find((opt) => opt.id === response[0].trade).name,
      rate: trade_codes.value.find((opt) => opt.id === response[0].trade).rate,
    }
    rowDataOverride.work_order = {
      id: response[0].work_order,
    }
    console.log(gridApi.value)
    gridApi.value.applyTransactionAsync({ add: [rowDataOverride] })
  })
}

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
}

const handleModalClose = () => {
  isModalOpen.value = false
  selectedItem.value = -1
  selectedRow.value = -1
  console.log(isModalOpen.value)
}

const setTrade = (obj: any) => {
  pendingTrade.value = obj
  totalDurationInput.value = 0
  showDurationDialog.value = true
  isModalOpen.value = false
}

const confirmSetTrade = async () => {
  const obj = pendingTrade.value
  if (!obj) return

  const startedAt = props.work_order?.started_at
  const due = props.work_order?.due
  const total = Number(totalDurationInput.value) || 0
  const now = new Date()

  let records: any[] = []

  if (startedAt && due && workDays.value > 0) {
    const durPerDay = durationPerDay.value
    for (let i = 0; i < workDays.value; i++) {
      const tradeDate = new Date(startedAt)
      tradeDate.setTime(tradeDate.getTime() + i * 24 * 60 * 60 * 1000)
      records.push({
        work_order: props.work_order?.id,
        trade: obj?.id,
        name: obj?.name,
        rate: obj?.rate,
        duration: durPerDay,
        total: Math.round(obj?.rate * durPerDay * 100) / 100,
        scheduled_date: toLocalDateStr(tradeDate) + 'T00:00:00',
        company_id: myCompanyId,
      })
    }
  } else {
    const tradeDate = new Date(startedAt || now)
    records.push({
      work_order: props.work_order?.id,
      trade: obj?.id,
      name: obj?.name,
      rate: obj?.rate,
      duration: total,
      total: Math.round(obj?.rate * total * 100) / 100,
      scheduled_date: toLocalDateStr(tradeDate) + 'T00:00:00',
      company_id: myCompanyId,
    })
  }

  createItems({
    collection: collectionName.value,
    items: records,
  }).then((response) => {
    response.forEach((record: any) => {
      let rowDataOverride: any = { ...record }
      rowDataOverride.trade = {
        id: record.trade,
        code: obj?.code,
        rate: obj?.rate,
        name: obj?.name,
      }
      rowDataOverride.work_order = { id: record.work_order }
      gridApi.value.applyTransactionAsync({ add: [rowDataOverride] })
    })
  })

  showDurationDialog.value = false
  pendingTrade.value = null
  totalDurationInput.value = 0
}

const confirmSetCancel = () => {
  showDurationDialog.value = false
  pendingTrade.value = null
  totalDurationInput.value = 0
}
const addEmptyRow = async () => {
  // const defaultRow = {
  //   'trade.name': getDefaultRow()?.name,
  //   'work_order.id': props.work_order?.id,
  //   name: '',
  //   duration: 0.0,
  //   rate: getDefaultRow()?.rate,
  //   total: 0.0,
  // } // Customize the default values
  // try {
  //   // Insert the row into the database asynchronously
  //   await asyncInsertRow(defaultRow)
  // } catch (error) {
  //   console.error('Error adding new row:', error)
  // }
}

const deleteRows = async () => {
  const sel = gridApi.value.getSelectedRows()
  if (sel && sel.length > 0) {
    const ids = sel.map((item: any) => item.id)
    gridApi.value.applyTransaction({ remove: sel })
    deleteItems({
      collection: collectionName.value,
      items: ids,
    })
  }
}

onMounted(async () => {
  console.log('Tradeers')
  await loadItems({ page: 1, itemsPerPage: -1 })
  // await loadTrades(1, -1)
})

const getDefaultRow = () => {
  return trade_codes.value
    ? trade_codes.value[0]
    : { id: null, name: '', rate: 0, total: 0 }
}

const refresh = (_newData: any) => {
  gridApi.value.refreshClientSideRowModel()
  // gridApi.value.applyTransaction({ add: [newData] });
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

// Local date helper — avoids UTC offset causing wrong calendar date
const toLocalDateStr = (d: Date): string => {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

// Extract local calendar date from a stored scheduled_date string
const scheduledLocalDate = (val: string | null | undefined): string | null => {
  if (!val) return null
  return toLocalDateStr(new Date(val))
}

// Auto add/remove rows when started_at or due date changes
watch(
  [() => props.work_order?.started_at, () => props.work_order?.due],
  async ([newStart, newDue], [oldStart, oldDue]) => {
    if (!newStart || !newDue) return
    if (newStart === oldStart && newDue === oldDue) return

    // Build new date set using local calendar dates
    const newDates = new Set<string>()
    const cur = new Date(newStart)
    cur.setHours(0, 0, 0, 0) // normalize to local midnight
    const newTo = new Date(newDue)
    newTo.setHours(23, 59, 59, 999)
    while (cur <= newTo) {
      newDates.add(toLocalDateStr(cur))
      cur.setDate(cur.getDate() + 1)
    }

    // Use rowData.value as source of truth
    const allRows = rowData.value

    // 1. Remove rows whose scheduled_date is outside the new range
    const rowsToRemove = allRows.filter((row: any) => {
      const d = scheduledLocalDate(row.scheduled_date)
      return d && !newDates.has(d)
    })
    const rowsToKeep = allRows.filter((row: any) => {
      const d = scheduledLocalDate(row.scheduled_date)
      return !d || newDates.has(d)
    })

    if (rowsToRemove.length > 0) {
      deleteItems({
        collection: collectionName.value,
        items: rowsToRemove.map((r: any) => r.id),
      })
    }

    // 2. Determine which local dates already have rows
    const existingDates = new Set<string>(
      rowsToKeep
        .map((row: any) => scheduledLocalDate(row.scheduled_date))
        .filter((d): d is string => d !== null),
    )

    // Dates in the new range that don't already have a row
    const addedDates = [...newDates].filter((d) => !existingDates.has(d))

    const newRows: any[] = []

    // Trade мэдээллийг БҮХ хуучин мөрөөс (устгагдах гэж буйг оролцуулан)
    // цуглуулна — эс тэгвэл шинэ хугацааны хүрээ хуучинтайгаа огт
    // давхцахгүй бол (rowsToKeep хоосон болно) trade мэдээлэл бүрмөсөн
    // алдагдаж, шинэ мөр огт үүсэхгүй болдог байсан
    if (addedDates.length > 0 && allRows.length > 0) {
      const tradeMap = new Map<number, any>()
      allRows.forEach((row: any) => {
        if (row.trade?.id) tradeMap.set(row.trade.id, row.trade)
      })

      for (const [, trade] of tradeMap) {
        const records = addedDates.map((dateStr) => ({
          work_order: props.work_order?.id,
          trade: trade?.id,
          name: trade?.name,
          rate: trade?.rate,
          duration: 0,
          total: 0,
          company_id: myCompanyId,
          scheduled_date: dateStr + 'T00:00:00', // local midnight, no Z suffix
        }))

        const response = await createItems({
          collection: collectionName.value,
          items: records,
        })

        response.forEach((record: any) => {
          const rowOverride: any = { ...record }
          rowOverride.trade = { ...trade }
          rowOverride.work_order = { id: record.work_order }
          newRows.push(rowOverride)
        })
      }
    }

    // Update rowData once — grid reacts via getRowId binding
    rowData.value = [...rowsToKeep, ...newRows]
  },
)
</script>

<template>
  <div class="relative">
    <!-- Duration Input Dialog -->
    <Teleport to="body">
      <div
        v-if="showDurationDialog"
        class="fixed inset-0 z-[200] flex items-center justify-center bg-black/50"
      >
        <div
          class="bg-white dark:bg-muted-800 rounded-xl p-6 w-96 shadow-2xl border border-muted-200 dark:border-muted-700"
        >
          <h3 class="text-base font-semibold mb-1">
            {{ $t('Total Duration (man-hours)') }}
          </h3>
          <p class="text-sm text-muted-500 dark:text-muted-400 mb-4">
            {{ pendingTrade?.name }} ({{ pendingTrade?.code }}) —
            {{ $t('Rate') }}: {{ pendingTrade?.rate?.toLocaleString() }}
          </p>

          <BaseInput
            v-model="totalDurationInput"
            type="number"
            min="0"
            step="0.5"
            :placeholder="$t('Enter total man-hours')"
            class="w-full mb-3"
          />

          <div
            v-if="props.work_order?.started_at && props.work_order?.due"
            class="text-xs text-muted-500 dark:text-muted-400 bg-muted-100 dark:bg-muted-900 rounded-lg p-3 mb-4 space-y-1"
          >
            <div>
              📅 {{ $t('Period') }}:
              {{ props.work_order.started_at?.split('T')[0] }} →
              {{ props.work_order.due?.split('T')[0] }}
            </div>
            <div>
              📆 {{ $t('Working days') }}: <strong>{{ workDays }}</strong>
            </div>
            <div v-if="totalDurationInput > 0">
              ⏱ {{ $t('Duration per day') }}:
              <strong>{{ durationPerDay }} {{ $t('hrs') }}</strong>
            </div>
          </div>

          <div class="flex gap-2 justify-end">
            <BaseButton @click="confirmSetCancel">
              {{ $t('Cancel') }}
            </BaseButton>
            <BaseButton color="primary" @click="confirmSetTrade">
              {{ $t('Confirm') }}
            </BaseButton>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <div
        v-if="!props.freeze && props.work_order?.action_status !== 2"
        class="col-span-12 flex justify-end gap-6"
      >
        <BaseButton class="float-right" @click="handleModalOpen">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Trade add') }}</span>
        </BaseButton>
        <BaseButton class="float-right" @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Trade delete') }}</span>
        </BaseButton>
      </div>
      <!-- Header -->
      <div class="col-span-12">
        <ag-grid-vue
          :key="key"
          style="width: 100%; height: auto; max-height: 560px"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list`"
          :columnDefs="columnDefs"
          :gridOptions="gridOptions"
          :autoSizeStrategy="autoSizeStrategy"
          @grid-ready="onGridReady"
          :rowData="rowData"
          :pinnedBottomRowData="pinnedTotals"
          :getRowStyle="(p: any) => p.node.rowPinned === 'bottom' ? { fontWeight: 'bold', background: 'rgba(99,102,241,0.08)' } : {}"
        >
        </ag-grid-vue>
      </div>
      <ModalItemsList
        :open="isModalOpen"
        :header="[
          { title: t('Name'), key: 'name', align: 'start' },
          {
            title: t('Code'),
            key: 'code',
            align: 'start',
            sortable: false,
          },
          {
            title: t('Rate(MNT)'),
            key: 'rate',
            align: 'start',
            sortable: false,
          },
          {
            title: t('Created'),
            key: 'user_created.first_name',
            align: 'start',
            sortable: false,
          },
          {
            title: t('Action'),
            key: 'action',
            align: 'start',
            sortable: false,
          },
        ]"
        :close="handleModalClose"
        :setItem="setTrade"
        :filter="{}"
        :title="t('Trade')"
        class="Tradecode"
        :collection="tradeCollectionName"
        fields="*,user_created.first_name, users.directus_users_id.first_name"
      />
    </div>
  </div>
</template>

<style>
.grid_ag_list .edit_duration .ag-header-cell-text {
  color: #04a504;
}
</style>
