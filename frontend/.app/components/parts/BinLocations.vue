<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import SetBinLocationModal from './SetBinLocationModal.vue'

const { t } = useI18n({ useScope: 'global' })
const { getItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const toaster = useToaster()
const stateMap = ref<Record<string, string>>({})
const key = ref(1)

const handleChangeKey = () => {
  key.value = Math.random()
}

const loadStates = async () => {
  try {
    const res = await getItems<any>({
      collection: 'States',
      params: {
        filter: { company_id: { _eq: myCompanyId } },
        fields: ['id', 'name'],
        limit: -1,
      },
    })
    const items = Array.isArray(res) ? res : (res as any)?.data ?? []
    const map: Record<string, string> = {}
    for (const s of items) map[String(s.id)] = s.name || String(s.id)
    stateMap.value = map
    handleChangeKey()
  } catch (e) {
    console.warn('Failed to load states:', e)
  }
}

const props = defineProps({
  part: Number,
  locationId: Number,
  item_data: Object,
})

ModuleRegistry.registerModules([ClientSideRowModelModule])

const isBinModalOpen = ref(false)
const openBinModal = () => {
  isBinModalOpen.value = true
}
const closeBinModal = () => {
  isBinModalOpen.value = false
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
    checkboxSelection: true,
    headerCheckboxSelection: true,
    filter: false,
    sortable: false,
    width: 50,
    pinned: 'left',
  },
  {
    headerName: t('ID'),
    field: 'id',
    sortable: true,
    filter: false,
    editable: false,
    resizable: true,
    maxWidth: 90,
  },
  {
    headerName: t('Location'),
    field: 'location.name',
    sortable: true,
    filter: true,
    editable: false,
    resizable: true,
  },
  {
    headerName: t('Bin Location'),
    field: 'bin_location.name',
    sortable: true,
    filter: true,
    editable: false,
    resizable: true,
  },
  {
    headerName: t('Income'),
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
    // maxWidth: 100,
    resizable: true,
  },
  {
    headerName: t('State'),
    field: 'transaction_parts.part_state',
    sortable: true,
    filter: true,
    editable: false,
    // maxWidth: 120,
    resizable: true,
    valueFormatter: (params: any) =>
      params.value ? stateMap.value[String(params.value)] ?? params.value : '—',
  },
  {
    headerName: t('Created date'),
    field: 'date_created',
    sortable: true,
    filter: false,
    editable: false,
    resizable: true,
    valueFormatter: (params: any) => {
      if (!params.value) return '—'
      return formatDate(params.value)
    },
  },
  {
    headerName: t('Updated date'),
    field: 'date_updated',
    sortable: true,
    filter: false,
    resizable: true,
    editable: false,
    valueFormatter: (params: any) => {
      if (!params.value) return '—'
      return formatDate(params.value)
    },
  },
  {
    headerName: t('Created by'),
    field: 'user_created.first_name',
    sortable: true,
    filter: false,
    editable: false,
    resizable: true,
    valueFormatter: (params: any) => params.value ?? '—',
  },
  {
    headerName: t('Updated by'),
    field: 'user_updated.first_name',
    sortable: true,
    filter: false,
    editable: false,
    resizable: true,
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

const loadItems = async () => {
  loading.value = true
  console.log(
    'Loading bin locations for part',
    props.part,
    'and location',
    props.locationId,
  )
  try {
    const res = await getItems<any>({
      collection: 'Parts_Bin_location',
      params: {
        filter: {
          part: { _eq: props.part },
          bin_location: { location: { _eq: props.locationId } },
          status: { _neq: 'archived' },
        },
        fields: [
          '*',
          'user_updated.*',
          'user_created.*',
          'bin_location.id',
          'bin_location.name',
          'location.id',
          'location.name',
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
    console.error('Error loading bin locations:', e)
  } finally {
    loading.value = false
  }
}

const onGridReady = (grid_params: any) => {
  gridApi.value = grid_params.api
  grid_params.api.sizeColumnsToFit()
}

const handleDelete = async () => {
  const sel = gridApi.value?.getSelectedRows() ?? []
  if (!sel.length) {
    toaster.show({
      title: t('Warning'),
      message: t('Please select at least one row'),
      color: 'warning',
      icon: 'ph:warning-circle',
      closable: true,
    })
    return
  }
  const ids = sel.map((r: any) => r.id)
  try {
    await Promise.all(
      ids.map((id: number) =>
        updateItem({
          collection: 'Parts_Bin_location',
          id,
          item: { status: 'archived' },
        }),
      ),
    )
    gridApi.value.applyTransaction({ remove: sel })
    toaster.show({
      title: t('Deleted'),
      message: t('{count} record(s) deleted', { count: ids.length }),
      color: 'success',
      icon: 'ph:check-circle',
      closable: true,
    })
  } catch (e) {
    toaster.show({
      title: t('Error'),
      message: String(e),
      color: 'danger',
      closable: true,
    })
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
    <div v-else class="part_ag">
      <!-- Toolbar -->
      <div class="mb-2 flex justify-end gap-6">
        <BaseButton size="sm" @click="openBinModal">
          <Icon name="ph:plus" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Bin add') }}</span>
        </BaseButton>
        <BaseButton size="sm" @click="handleDelete">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Bin delete') }}</span>
        </BaseButton>
      </div>

      <ag-grid-vue
        :key="key"
        style="width: 100%; height: 320px"
        :class="`ag-theme-quartz${
          $colorMode.value === 'light' ? '' : '-dark'
        } grid_ag_list`"
        :columnDefs="columnDefs"
        :gridOptions="gridOptions"
        :rowData="rowData"
        @grid-ready="onGridReady"
      />
      <p v-if="!rowData.length" class="mt-2 text-center text-xs text-muted-400">
        {{ t('No bin location assignments found') }}
      </p>
    </div>

    <SetBinLocationModal
      :open="isBinModalOpen"
      :close="closeBinModal"
      :selected-rows="[{ part: { id: props.part } }]"
      :locationId="props.locationId"
      :refresh="loadItems"
    />
  </div>
</template>
