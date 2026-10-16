<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { AgGridVue } from 'ag-grid-vue3'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const props = defineProps({
  part: [Number, String],
  locationId: [Number, String],
  item_data: Object,
})

ModuleRegistry.registerModules([ClientSideRowModelModule])

const { params } = useRoute()
const currentLocationId = computed(() => props.locationId ?? params.id)

const stateMap = ref<Record<string, string>>({})

const stateName = (code: any) =>
  code != null ? stateMap.value[String(code)] ?? String(code) : '—'

// true = came into current location (in), false = went out
const isIncoming = (row: any) => {
  const toId = row?.to_location?.id ?? row?.to_location
  return String(toId) === String(currentLocationId.value)
}

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

const columnDefs = ref([
  {
    headerName: '№',
    valueGetter: (params: any) => params.node.rowIndex + 1,
    filter: false,
    sortable: false,
    width: 60,
    pinned: 'left',
  },
  {
    headerName: t('Date'),
    field: 'date_created',
    sortable: true,
    filter: false,
    minWidth: 140,
    valueFormatter: (params: any) => formatDate(params.value),
  },
  {
    headerName: t('Part Number'),
    field: 'part.part_number',
    sortable: true,
    filter: true,
    minWidth: 130,
    valueFormatter: (params: any) => params.value ?? '—',
  },
  {
    headerName: t('State'),
    field: 'part_state',
    sortable: true,
    filter: true,
    minWidth: 120,
    valueFormatter: (params: any) => stateName(params.value),
  },
  {
    headerName: t('Qty'),
    field: 'qty',
    sortable: true,
    filter: false,
    maxWidth: 90,
    cellStyle: (params: any) => ({
      fontWeight: 600,
      color: isIncoming(params.data) ? '#54b5a6' : '#e24f62',
    }),
    valueFormatter: (params: any) => {
      const q = parseInt(params.value) || 0
      return isIncoming(params.data) ? `+${q}` : `-${q}`
    },
  },
  {
    headerName: t('From Location'),
    field: 'from_location.name',
    sortable: true,
    filter: true,
    minWidth: 150,
    valueFormatter: (params: any) => params.value ?? '—',
  },
  {
    headerName: t('To Location'),
    field: 'to_location.name',
    sortable: true,
    filter: true,
    minWidth: 150,
    valueFormatter: (params: any) => params.value ?? '—',
  },
  // {
  //   headerName: 'Qty',
  //   field: 'qty',
  //   sortable: true,
  //   filter: false,
  //   maxWidth: 90,
  //   valueFormatter: (params: any) => params.value ?? '—',
  // },
  {
    headerName: t('Shifted By'),
    field: 'user_created.first_name',
    sortable: true,
    filter: true,
    minWidth: 120,
    valueFormatter: (params: any) => params.value ?? '—',
  },
])

const gridOptions = ref({
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

const loading = ref(true)
const gridApi = ref()
const rowData = ref<any[]>([])

// Totals: incoming (+), outgoing (-) and net
const totals = computed(() => {
  let incoming = 0
  let outgoing = 0
  for (const row of rowData.value) {
    const q = parseInt(row?.qty) || 0
    if (isIncoming(row)) incoming += q
    else outgoing += q
  }
  return { incoming, outgoing, net: incoming - outgoing }
})

const loadItems = async () => {
  loading.value = true
  try {
    const filter: any = { company_id: { _eq: myCompanyId } }
    if (currentLocationId.value) {
      filter._or = [
        { from_location: { _eq: currentLocationId.value } },
        { to_location: { _eq: currentLocationId.value } },
      ]
    }
    if (props.part) {
      filter.part = { _eq: props.part }
    }

    const res = await getItems<any>({
      collection: 'Parts_shift_history',
      params: {
        filter,
        fields: [
          'id',
          'date_created',
          'qty',
          'part_state',
          'part.id',
          'part.part_number',
          'from_location.id',
          'from_location.name',
          'to_location.id',
          'to_location.name',
          'parts_amounts.id',
          'user_created.first_name',
          'user_created.last_name',
        ],
        sort: ['-date_created'],
        limit: -1,
      },
    })
    rowData.value = Array.isArray(res) ? res : (res as any)?.data ?? []
  } catch (e) {
    console.error('Error loading shift history:', e)
  } finally {
    loading.value = false
  }
}

const onGridReady = (grid_params: any) => {
  gridApi.value = grid_params.api
  grid_params.api.sizeColumnsToFit()
}

const loadStates = async () => {
  try {
    const res = await getItems<any>({
      collection: 'States',
      params: {
        filter: { company_id: myCompanyId },
        fields: ['id', 'name'],
        limit: -1,
      },
    })
    const items = Array.isArray(res) ? res : (res as any)?.data ?? []
    const map: Record<string, string> = {}
    for (const s of items) map[String(s.id)] = s.name || String(s.id)
    stateMap.value = map
  } catch (e) {
    console.warn('Failed to load states:', e)
  }
}

onMounted(async () => {
  await loadStates()
  await loadItems()
})

defineExpose({ refreshGrid: loadItems })
</script>

<template>
  <div class="relative">
    <div v-if="loading" class="flex items-center justify-center py-6">
      <Icon name="mdi:loading" class="h-6 w-6 animate-spin text-primary-500" />
    </div>
    <div v-else>
      <ag-grid-vue
        style="width: 100%; height: 370px"
        :class="`ag-theme-quartz${
          $colorMode.value === 'light' ? '' : '-dark'
        } grid_ag_list`"
        :columnDefs="columnDefs"
        :gridOptions="gridOptions"
        :rowData="rowData"
        @grid-ready="onGridReady"
      />
      <p v-if="!rowData.length" class="mt-2 text-center text-xs text-muted-400">
        No shift history found
      </p>
      <div
        v-else
        class="mt-3 flex flex-wrap items-center justify-end gap-4 border-t border-muted-200 pt-2 text-sm dark:border-muted-700"
      >
        <span class="text-muted-500">
          {{ $t('Incoming') }}:
          <span class="font-semibold text-success-500"
            >+{{ totals.incoming }}</span
          >
        </span>
        <span class="text-muted-500">
          {{ $t('Outgoing') }}:
          <span class="font-semibold text-danger-500"
            >-{{ totals.outgoing }}</span
          >
        </span>
        <span class="text-muted-500">
          {{ $t('Net') }}:
          <span
            class="font-bold"
            :class="totals.net >= 0 ? 'text-success-500' : 'text-danger-500'"
          >
            {{ totals.net >= 0 ? '+' : '' }}{{ totals.net }}
          </span>
        </span>
      </div>
    </div>
  </div>
</template>
