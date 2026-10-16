<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const props = defineProps({
  item_data: Object, // bin_location object { id, name, ... }
})

ModuleRegistry.registerModules([ClientSideRowModelModule])

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
    headerName: t('Name'),
    field: 'name',
    sortable: true,
    filter: true,
    editable: false,
  },
  {
    headerName: t('Date'),
    field: 'date_created',
    sortable: true,
    filter: false,
    editable: false,
    minWidth: 140,
    valueFormatter: (params: any) => {
      if (!params.value) return '—'
      const d = new Date(params.value)
      return (
        `${d.getFullYear()}/${String(d.getMonth() + 1).padStart(
          2,
          '0',
        )}/${String(d.getDate()).padStart(2, '0')} ` +
        `${String(d.getHours()).padStart(2, '0')}:${String(
          d.getMinutes(),
        ).padStart(2, '0')}`
      )
    },
  },
  {
    headerName: t('Updated date'),
    field: 'date_updated',
    sortable: true,
    filter: false,
    editable: false,
    minWidth: 140,
    valueFormatter: (params: any) => {
      if (!params.value) return '—'
      const d = new Date(params.value)
      return (
        `${d.getFullYear()}/${String(d.getMonth() + 1).padStart(
          2,
          '0',
        )}/${String(d.getDate()).padStart(2, '0')} ` +
        `${String(d.getHours()).padStart(2, '0')}:${String(
          d.getMinutes(),
        ).padStart(2, '0')}`
      )
    },
  },
  {
    headerName: t('Created by'),
    field: 'user_created.first_name',
    sortable: true,
    filter: false,
    editable: false,
    minWidth: 180,
  },

  {
    headerName: t('Updated by'),
    field: 'user_updated.first_name',
    sortable: true,
    filter: false,
    editable: false,
    minWidth: 180,
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

const loadItems = async () => {
  if (!props.item_data?.id) return
  loading.value = true
  try {
    const res = await getItems<any>({
      collection: 'Bin_location',
      params: {
        filter: {
          id: { _eq: props.item_data.id },
          company_id: { _eq: myCompanyId },
        },
        fields: [
          'id',
          'name',
          'date_created',
          'date_updated',
          'user_created.first_name',
          'user_created.last_name',
          'user_updated.first_name',
          'user_updated.last_name',
        ],
        sort: ['-date_created'],
        limit: -1,
      },
    })
    rowData.value = Array.isArray(res) ? res : (res as any)?.data ?? []
  } catch (e) {
    console.error('Error loading bin location history:', e)
  } finally {
    loading.value = false
  }
}

const onGridReady = (grid_params: any) => {
  gridApi.value = grid_params.api
  grid_params.api.sizeColumnsToFit()
}

onMounted(async () => {
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
        No history found for this bin location
      </p>
    </div>
  </div>
</template>
