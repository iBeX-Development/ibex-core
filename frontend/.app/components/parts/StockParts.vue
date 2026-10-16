<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { AgGridVue } from 'ag-grid-vue3'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const { getItems: getStates } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const props = defineProps({
  open: Boolean,
  title: String,
  asset_id: Number,
  location_id: Number,
  part: Number,
  item_data: Object,
})

ModuleRegistry.registerModules([ClientSideRowModelModule])

const stateMap = ref<Record<string, string>>({})
const loading = ref(true)
// Summary rows (grouped by state)
const summaryRows = ref<any[]>([])
// Detail rows (all movements)
const detailRows = ref<any[]>([])
const partInfo = ref<any>(null)
const summaryGridApi = ref()
const detailGridApi = ref()
const { params } = useRoute()

// Net shift for this part at current location (in - out)
const netShift = ref(0)

const totalRemaining = computed(() =>
  summaryRows.value.reduce((s, r) => s + (r.remaining || 0), 0),
)

// ── Summary total (pinned bottom) ────────────────────────────────
const summaryPinnedBottom = computed(() => [
  {
    stateName: 'Нийт',
    income: summaryRows.value.reduce((s, r) => s + (r.income || 0), 0),
    outcome: summaryRows.value.reduce((s, r) => s + (r.outcome || 0), 0),
    shift: summaryRows.value.reduce((s, r) => s + (r.shift || 0), 0),
    remaining: summaryRows.value.reduce((s, r) => s + (r.remaining || 0), 0),
  },
])

// ── Detail total (pinned bottom) ─────────────────────────────────
const detailPinnedBottom = computed(() => {
  const total = detailRows.value.reduce((s, r) => {
    const q = r.qty || 0
    return r.type === 'Outcome' || r.type === 'Shift Out' ? s - q : s + q
  }, 0)
  return [
    {
      transactionName: 'Нийт',
      type: '',
      stateName: '',
      qty: total,
      user: '',
    },
  ]
})

// ── Summary grid columns ─────────────────────────────────────────
const summaryColumnDefs = ref([
  {
    headerName: '№',
    valueGetter: (p: any) => (p.node.rowPinned ? '' : p.node.rowIndex + 1),
    filter: false,
    sortable: false,
    width: 55,
    maxWidth: 80,
    resizable: false,
    pinned: 'left',
  },
  {
    headerName: t('State'),
    field: 'stateName',
    sortable: true,
    filter: true,
    minWidth: 120,
    resizable: true,
    cellStyle: (p: any) => (p.node.rowPinned ? { fontWeight: 700 } : null),
  },
  {
    headerName: t('Income'),
    field: 'income',
    sortable: true,
    filter: false,
    // maxWidth: 110,
    resizable: true,

    cellStyle: { color: '#54b5a6', fontWeight: 500 },
  },
  {
    headerName: t('Debt'),
    field: 'outcome',
    sortable: true,
    filter: false,
    resizable: true,
    // maxWidth: 110,
    cellStyle: { color: '#e24f62', fontWeight: 500 },
  },

  {
    headerName: t('Shift'),
    field: 'shift',
    sortable: true,
    filter: false,
    resizable: true,
    // maxWidth: 110,
    cellStyle: (p: any) => ({
      fontWeight: p.node.rowPinned ? 700 : 500,
      color:
        (p.value ?? 0) > 0
          ? '#54b5a6'
          : (p.value ?? 0) < 0
          ? '#e24f62'
          : '#888',
    }),
    valueFormatter: (p: any) => {
      const v = p.value ?? 0
      return v > 0 ? `+${v}` : `${v}`
    },
  },
  {
    headerName: t('Remaining'),
    field: 'remaining',
    sortable: true,
    resizable: true,
    filter: false,
    // maxWidth: 120,
    cellStyle: (p: any) => ({
      fontWeight: 700,
      color: p.value > 0 ? '#4e6bb5' : '#e24f62',
    }),
  },
])

const formatDate = (val: any) => {
  if (!val) return '—'
  const d = new Date(val)
  return (
    `${d.getFullYear()}/${String(d.getMonth() + 1).padStart(2, '0')}/${String(
      d.getDate(),
    ).padStart(2, '0')} ` +
    `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(
      2,
      '0',
    )}`
  )
}

// ── Detail grid columns ──────────────────────────────────────────
const detailColumnDefs = ref([
  {
    headerName: '№',
    valueGetter: (p: any) => p.node.rowIndex + 1,
    filter: false,
    sortable: false,
    width: 55,
    pinned: 'left',
  },
  {
    headerName: t('Date'),
    field: 'date',
    sortable: true,
    filter: false,
    minWidth: 130,
    resizable: true,
    valueFormatter: (p: any) => formatDate(p.value),
  },
  {
    headerName: t('Number'),
    field: 'transactionId',
    sortable: true,
    filter: false,
    // maxWidth: 110,
    resizable: true,
    valueFormatter: (p: any) => (p.value ? `#${p.value}` : '—'),
  },
  {
    headerName: t('Name'),
    field: 'transactionName',
    sortable: true,
    filter: false,
    resizable: true,
    minWidth: 120,
    cellStyle: (p: any) => (p.node.rowPinned ? { fontWeight: 700 } : null),
  },
  {
    headerName: t('Type'),
    field: 'type',
    sortable: true,
    filter: true,
    resizable: true,
    // maxWidth: 110,
    cellStyle: (p: any) => ({
      fontWeight: 600,
      color:
        p.value === 'Income' || p.value === 'Shift In'
          ? '#54b5a6'
          : p.value === 'Outcome' || p.value === 'Shift Out'
          ? '#e24f62'
          : '#888',
    }),
  },
  {
    headerName: t('State'),
    field: 'stateName',
    sortable: true,
    filter: true,
    resizable: true,
    // maxWidth: 120,
  },
  {
    headerName: t('Qty'),
    field: 'qty',
    sortable: true,
    filter: false,
    resizable: true,
    // maxWidth: 90,
    cellStyle: (p: any) => ({
      fontWeight: p.node.rowPinned ? 700 : 600,
      color:
        p.data?.type === 'Income' || p.data?.type === 'Shift In'
          ? '#54b5a6'
          : p.data?.type === 'Outcome' || p.data?.type === 'Shift Out'
          ? '#e24f62'
          : '#888',
    }),
    valueFormatter: (p: any) => {
      if (p.node.rowPinned) return `${p.value}`
      return p.data?.type === 'Outcome' || p.data?.type === 'Shift Out'
        ? `-${p.value}`
        : `+${p.value}`
    },
  },
  {
    headerName: t('User'),
    field: 'user',
    sortable: true,
    filter: true,
    resizable: true,
    minWidth: 120,
  },
])

const gridOptions = ref({
  domLayout: 'autoHeight',
  defaultColDef: {
    sortable: true,
    filter: true,
    resizable: true,
    flex: 1,
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
})

const loadItems = async () => {
  loading.value = true
  try {
    const locationId = props.location_id ?? params.id

    const res = await getItems<any>({
      collection: 'Transaction_parts',
      params: {
        filter: {
          part: { _eq: props.part },
          transaction_id: {
            status: { _eq: 2 },
            ...(locationId ? { location: { _eq: locationId } } : {}),
          },
        },
        fields: [
          'id',
          'qty',
          'part_state',
          'transaction_type',
          'part.id',
          'part.part_number',
          'part.name',
          'transaction_id.id',
          'transaction_id.auto_number',
          'transaction_id.name',
          'transaction_id.transaction_date',
          'transaction_id.date_created',
          'transaction_id.date_updated',
          'transaction_id.approved_user.first_name',
          'transaction_id.approved_user.last_name',
          'transaction_id.user_created.first_name',
          'transaction_id.user_created.last_name',
          'transaction_id.assign_user.first_name',
          'transaction_id.assign_user.last_name',
        ],
        sort: ['transaction_id.transaction_date'],
        limit: -1,
      },
    })

    const list: any[] = Array.isArray(res) ? res : (res as any)?.data ?? []

    if (list.length && list[0].part) partInfo.value = list[0].part

    // ── Net shift for this part at current location (per state) ──
    let shiftIn = 0
    let shiftOut = 0
    let shiftList: any[] = []
    const shiftByState: Record<string, number> = {}
    if (locationId) {
      const shiftRes = await getItems<any>({
        collection: 'Parts_shift_history',
        params: {
          filter: {
            company_id: { _eq: myCompanyId },
            part: { _eq: props.part },
            _or: [
              { from_location: { _eq: locationId } },
              { to_location: { _eq: locationId } },
            ],
          },
          fields: [
            'id',
            'qty',
            'part_state',
            'date_created',
            'from_location.id',
            'from_location.name',
            'to_location.id',
            'to_location.name',
            'user_created.first_name',
            'user_created.last_name',
          ],
          limit: -1,
        },
      })
      shiftList = Array.isArray(shiftRes)
        ? shiftRes
        : (shiftRes as any)?.data ?? []
      for (const sh of shiftList) {
        const qty = parseInt(sh.qty) || 0
        const toId = sh.to_location?.id ?? sh.to_location
        const fromId = sh.from_location?.id ?? sh.from_location
        const key = sh.part_state != null ? String(sh.part_state) : '__none__'
        let net = 0
        if (String(toId) === String(locationId)) {
          shiftIn += qty
          net += qty
        }
        if (String(fromId) === String(locationId)) {
          shiftOut += qty
          net -= qty
        }
        shiftByState[key] = (shiftByState[key] || 0) + net
      }
    }
    netShift.value = shiftIn - shiftOut

    // ── Summary aggregation ──────────────────────────────────────
    const map: Record<
      string,
      { stateId: any; income: number; outcome: number }
    > = {}
    for (const tp of list) {
      const key = tp.part_state != null ? String(tp.part_state) : '__none__'
      if (!map[key])
        map[key] = { stateId: tp.part_state, income: 0, outcome: 0 }
      const qty = parseInt(tp.qty) || 0
      const isIncome =
        tp.transaction_type === 'income' || tp.transaction_type === 'INCOME'
      if (isIncome) map[key].income += qty
      else map[key].outcome += qty
    }
    // Include states that only have shift movements
    for (const key of Object.keys(shiftByState)) {
      if (!map[key])
        map[key] = {
          stateId: key === '__none__' ? null : key,
          income: 0,
          outcome: 0,
        }
    }
    summaryRows.value = Object.entries(map).map(([key, v]) => ({
      stateId: v.stateId,
      stateName:
        v.stateId != null
          ? stateMap.value[String(v.stateId)] ?? String(v.stateId)
          : '—',
      income: v.income,
      outcome: v.outcome,
      shift: shiftByState[key] || 0,
      remaining: v.income - v.outcome + (shiftByState[key] || 0),
    }))

    // ── Detail rows ──────────────────────────────────────────────
    detailRows.value = list.map((tp) => {
      const isIncome =
        tp.transaction_type === 'income' || tp.transaction_type === 'INCOME'
      const tx = tp.transaction_id ?? {}
      const approvedUser = tx.approved_user
        ? `${tx.approved_user.first_name ?? ''} ${
            tx.approved_user.last_name ?? ''
          }`.trim()
        : null
      const createdUser = tx.user_created
        ? `${tx.user_created.first_name ?? ''} ${
            tx.user_created.last_name ?? ''
          }`.trim()
        : null
      const assignUser = tx.assign_user
        ? `${tx.assign_user.first_name ?? ''} ${
            tx.assign_user.last_name ?? ''
          }`.trim()
        : null
      return {
        id: tp.id,
        date: tx.date_created ?? tx.date_updated ?? null,
        transactionId: tx.auto_number ?? tx.id,
        transactionName: tx.name ?? '—',
        type: isIncome ? 'Income' : 'Outcome',
        stateName:
          tp.part_state != null
            ? stateMap.value[String(tp.part_state)] ?? String(tp.part_state)
            : '—',
        qty: parseInt(tp.qty) || 0,
        user: approvedUser || assignUser || createdUser || '—',
      }
    })

    // ── Append shift history rows into detail ────────────────────
    const shiftDetailRows = shiftList.map((sh) => {
      const qty = parseInt(sh.qty) || 0
      const toId = sh.to_location?.id ?? sh.to_location
      const isIn = String(toId) === String(locationId)
      const shiftUser = sh.user_created
        ? `${sh.user_created.first_name ?? ''} ${
            sh.user_created.last_name ?? ''
          }`.trim()
        : null
      return {
        id: `shift-${sh.id}`,
        date: sh.date_created ?? null,
        transactionId: null,
        transactionName: `${sh.from_location?.name ?? '—'} → ${
          sh.to_location?.name ?? '—'
        }`,
        type: isIn ? t('Shift In') : t('Shift Out'),
        stateName:
          sh.part_state != null
            ? stateMap.value[String(sh.part_state)] ?? String(sh.part_state)
            : '—',
        qty,
        user: shiftUser || '—',
      }
    })

    detailRows.value = [...detailRows.value, ...shiftDetailRows].sort(
      (a, b) =>
        new Date(a.date ?? 0).getTime() - new Date(b.date ?? 0).getTime(),
    )
  } catch (e) {
    console.error('StockParts loadItems error:', e)
  } finally {
    loading.value = false
  }
}

const onSummaryGridReady = (p: any) => {
  summaryGridApi.value = p.api
  p.api.sizeColumnsToFit()
}
const onDetailGridReady = (p: any) => {
  detailGridApi.value = p.api
  p.api.sizeColumnsToFit()
}

onMounted(async () => {
  const statesRes = await getStates({
    collection: 'States',
    params: {
      filter: { company_id: myCompanyId },
      fields: ['id', 'name'],
      limit: -1,
    },
  })
  const statesList = Array.isArray(statesRes)
    ? statesRes
    : (statesRes as any)?.data ?? []
  statesList.forEach((s: any) => {
    stateMap.value[String(s.id)] = s.name
  })
  await loadItems()
})

const refreshGrid = async () => {
  await loadItems()
}
defineExpose({ refreshGrid })
</script>

<template>
  <div class="relative">
    <!-- Part info -->
    <div v-if="partInfo" class="mb-3 flex items-center gap-2">
      <span
        class="rounded bg-muted-100 px-2 py-0.5 font-mono text-xs font-semibold text-muted-600 dark:bg-muted-700 dark:text-muted-300"
      >
        {{ partInfo.part_number }}
      </span>
      <span class="text-sm font-medium text-muted-700 dark:text-muted-200">{{
        partInfo.name
      }}</span>
    </div>

    <div v-if="loading" class="flex items-center justify-center py-10">
      <Icon name="mdi:loading" class="h-6 w-6 animate-spin text-primary-500" />
    </div>
    <template v-else>
      <!-- Summary cards -->
      <div class="mb-4 flex flex-wrap gap-3">
        <div
          class="flex min-w-[130px] flex-col items-center rounded-xl border border-muted-200 bg-white px-4 py-3 shadow-sm dark:border-muted-700 dark:bg-muted-800"
        >
          <span class="text-xs text-muted-400">{{ $t('Total balance') }}</span>
          <span class="mt-1 text-2xl font-bold text-primary-600">{{
            totalRemaining
          }}</span>
        </div>
        <div
          v-for="row in summaryRows"
          :key="row.stateName"
          class="flex min-w-[130px] flex-col items-center rounded-xl border border-info-200 bg-info-50 px-4 py-3 shadow-sm dark:border-info-700 dark:bg-info-900/20"
        >
          <span class="text-xs text-info-500">{{ row.stateName }}</span>
          <span
            class="mt-1 text-2xl font-bold"
            :class="
              row.remaining > 0
                ? 'text-info-700 dark:text-info-300'
                : 'text-danger-500'
            "
          >
            {{ row.remaining }}
          </span>
          <span class="mt-0.5 text-[10px] text-muted-400">
            ↑{{ row.income }} ↓{{ row.outcome }}
          </span>
        </div>
      </div>

      <!-- Summary grid -->
      <ag-grid-vue
        style="width: 100%"
        :class="`ag-theme-quartz${
          $colorMode.value === 'light' ? '' : '-dark'
        } grid_ag_list`"
        :columnDefs="summaryColumnDefs"
        :gridOptions="gridOptions"
        :rowData="summaryRows"
        :pinnedBottomRowData="summaryPinnedBottom"
        @grid-ready="onSummaryGridReady"
      />

      <!-- Detail title -->
      <div class="mb-1 mt-5 flex items-center gap-2">
        <span
          class="text-sm font-semibold text-muted-600 dark:text-muted-300"
          >{{ $t('Movement breakdown') }}</span
        >
        <span
          class="rounded-full bg-muted-100 px-2 py-0.5 text-xs text-muted-400 dark:bg-muted-700"
          >{{ detailRows.length }} {{ $t('record') }}</span
        >
      </div>

      <!-- Detail grid -->
      <ag-grid-vue
        style="width: 100%"
        :class="`ag-theme-quartz${
          $colorMode.value === 'light' ? '' : '-dark'
        } grid_ag_list`"
        :columnDefs="detailColumnDefs"
        :gridOptions="gridOptions"
        :rowData="detailRows"
        :pinnedBottomRowData="detailPinnedBottom"
        @grid-ready="onDetailGridReady"
      />
      <p
        v-if="!detailRows.length"
        class="mt-2 text-center text-xs text-muted-400"
      >
        {{ $t('No balance') }}
      </p>
    </template>
  </div>
</template>
