<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()

const props = defineProps({
  item_data: Object, // bin_location object { id, name, ... }
})

ModuleRegistry.registerModules([ClientSideRowModelModule])

const columnDefs = ref([
  {
    headerName: '№',
    valueGetter: (params: any) => params.node.rowIndex + 1,
    checkboxSelection: true,
    headerCheckboxSelection: true,
    filter: false,
    sortable: false,
    width: 70,
    pinned: 'left',
  },
  {
    headerName: t('Part Number'),
    field: 'part.part_number',
    sortable: true,
    filter: true,
    editable: false,
    resizable: true,
  },
  {
    headerName: t('Description'),
    field: 'part.description',
    sortable: true,
    filter: true,
    editable: false,
    resizable: true,
  },
  {
    headerName: t('Income #'),
    field: 'transaction_parts.transaction_id.auto_number',
    sortable: true,
    filter: false,
    editable: false,
    resizable: true,

    valueFormatter: (params: any) => (params.value ? `#${params.value}` : '—'),
  },
  {
    headerName: t('Qty'),
    field: 'qty',
    sortable: true,
    filter: false,
    editable: false,
    resizable: true,
  },
  {
    headerName: t('State'),
    field: 'transaction_parts.part_state',
    sortable: true,
    filter: true,
    editable: false,
    resizable: true,

    valueFormatter: (params: any) => {
      console.log('BinParts')
      return params.value != null
        ? stateMap.value[String(params.value)] ?? params.value
        : '—'
    },
  },
  {
    headerName: t('Created date'),
    field: 'date_created',
    sortable: true,
    filter: false,
    editable: false,
    maxWidth: 190,
    resizable: true,

    valueFormatter: (params: any) => {
      if (!params.value) return '—'
      const d = new Date(params.value)
      return `${d.getFullYear()}/${String(d.getMonth() + 1).padStart(
        2,
        '0',
      )}/${String(d.getDate()).padStart(2, '0')}`
    },
  },
  {
    headerName: t('Updated date'),
    field: 'date_updated',
    sortable: true,
    filter: false,
    editable: false,
    maxWidth: 230,
    resizable: true,

    valueFormatter: (params: any) => {
      if (!params.value) return '—'
      const d = new Date(params.value)
      return `${d.getFullYear()}/${String(d.getMonth() + 1).padStart(
        2,
        '0',
      )}/${String(d.getDate()).padStart(2, '0')}`
    },
  },
  {
    headerName: t('Created by'),
    field: 'user_created.first_name',
    sortable: true,
    filter: false,
    editable: false,
    maxWidth: 280,
    resizable: true,
  },

  {
    headerName: t('Updated by'),
    field: 'user_updated.first_name',
    sortable: true,
    filter: false,
    editable: false,
    maxWidth: 280,
    resizable: true,
  },
])

const gridOptions = ref({
  defaultColDef: {
    sortable: true,
    filter: true,
    resizable: true,
    flex: 1,
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
})

const loading = ref(true)
const gridApi = ref()
const rowData = ref<any[]>([])
const stateMap = ref<Record<string, string>>({})
const myCompanyId = getMyCompanyId()

const loadStates = async () => {
  try {
    const res = await getItems<any>({
      collection: 'States',
      params: {
        fields: ['id', 'name'],
        limit: -1,
        company_id: myCompanyId,
      },
    })
    const items = Array.isArray(res) ? res : (res as any)?.data ?? []
    const map: Record<string, string> = {}
    for (const s of items) {
      map[String(s.id)] = s.name || String(s.id)
    }
    stateMap.value = map
  } catch (e) {
    console.error('Error loading states:', e)
  }
}

const loadItems = async () => {
  if (!props.item_data?.id) return
  loading.value = true
  try {
    const res = await getItems<any>({
      collection: 'Parts_Bin_location',
      params: {
        filter: {
          bin_location: { _eq: props.item_data.id },
          status: { _neq: 'archived' },
        },
        fields: [
          '*',
          'user_created.first_name',
          'user_created.last_name',
          'user_updated.first_name',
          'user_updated.last_name',
          'part.id',
          'part.part_number',
          'part.description',
          'transaction_parts.id',
          'transaction_parts.part_state',
          'transaction_parts.transaction_id.id',
          'transaction_parts.transaction_id.auto_number',
        ],
        sort: ['-date_created'],
        limit: -1,
      },
    })
    rowData.value = Array.isArray(res) ? res : (res as any)?.data ?? []
  } catch (e) {
    console.error('Error loading bin parts:', e)
  } finally {
    loading.value = false
  }
}

const onGridReady = (grid_params: any) => {
  gridApi.value = grid_params.api
  grid_params.api.sizeColumnsToFit()
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
        style="width: 100%; height: 400px"
        :class="`ag-theme-quartz${
          $colorMode.value === 'light' ? '' : '-dark'
        } grid_ag_list`"
        :columnDefs="columnDefs"
        :gridOptions="gridOptions"
        :rowData="rowData"
        @grid-ready="onGridReady"
      />
      <p v-if="!rowData.length" class="mt-2 text-center text-xs text-muted-400">
        No parts assigned to this bin location
      </p>
    </div>
  </div>
</template>

<style>
.part_ag .ag-center-cols-container {
  overflow: visible;
}
</style>
