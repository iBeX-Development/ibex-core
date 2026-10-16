<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
import PriorityCellRenderer from '~/components/ag_grid/priorityCellRenderer.vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const { updateItem, createItems, deleteItems } = useDirectusItems()
ModuleRegistry.registerModules([ClientSideRowModelModule, RichSelectModule])
const props = defineProps({
  work_order: Object,
  delete: Boolean,
})

const loading = ref(true)
const gridApi = ref()
const { getItems } = useDirectusItems()
const { params } = useRoute()
const rowData = ref([])
const key = ref(1)

const gridOptions = ref({
  defaultColDef: {
    sortable: true,
    filter: true,
    resizable: true,
    flex: 1,
  },
  rowSelection: 'multiple',
  suppressHorizontalScroll: true, // Хэвтээ scroll идэвхгүй болгох
})

const statusFormatter = ({ value }) => {
  if (value === 1) return 'created'
  else if (value === 2) return 'approved'
  else if (value === 3) return 'returned'
  else if (value === 4) return 'assigned'
}

const dateFormatter = ({ value }) => {
  const localTime = new Date(value)
  const formattedTime =
    `${localTime.getFullYear()}/` +
    `${String(localTime.getMonth() + 1).padStart(2, '0')}/` +
    `${String(localTime.getDate()).padStart(2, '0')}, ` +
    `${String(localTime.getHours()).padStart(2, '0')}:` +
    `${String(localTime.getMinutes()).padStart(2, '0')}`

  return formattedTime
}

const columnDefs = ref([
  {
    headerName: t('From'),
    field: 'first_user.first_name',
    sortable: true,
    headerClass: 'header-first_user',
    filter: true,
    editable: false,
  },
  {
    headerName: t('To'),
    field: 'next_user.first_name',
    sortable: true,
    filter: false,
    editable: false,
    headerClass: 'header-next_user',
  },
  {
    headerName: t('Date'),
    field: 'date_created',
    sortable: true,
    filter: true,
    editable: false,
    valueFormatter: dateFormatter,
  },
  {
    headerName: t('Action'),
    field: 'action_status',
    headerClass: 'header-status',
    valueFormatter: statusFormatter,
    cellRenderer: PriorityCellRenderer,
    filter: false,
    sortable: false,
    cellClassRules: {
      'status-approved': ({ value }) => value === 2,
    },
    cellClass: 'status-cell',
    maxWidth: 120,
  },
])

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    const filters = {
      wo_id: props.work_order?.id,
    }

    const items = await getItems({
      collection: 'Work_order_actions',
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*', 'first_user.*', 'next_user.*'],
      },
    })

    // console.log('items_opop', items)
    rowData.value = items.data
    loading.value = false
  } catch (e) {}
}

const onGridReady = async (grid_params) => {
  gridApi.value = grid_params.api
  // const datasource = createServerSideDatasource()
  // await gridApi.value.setGridOption('serverSideDatasource', datasource)
}

const getRowNodeId = (data) => {
  return data.id
}

onMounted(async () => {
  await loadItems(1, -1)
})

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-6 gap-6 wo_actions">
      <!-- Header -->
      <div class="col-span-6">
        <ag-grid-vue
          :key="key"
          style="width: 100%; height: 560px"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list`"
          :columnDefs="columnDefs"
          :gridOptions="gridOptions"
          @grid-ready="onGridReady"
          :rowData="rowData"
        >
        </ag-grid-vue>
      </div>
    </div>
  </div>
</template>
<style>
.wo_actions .grid_ag {
  min-height: 560px !important;
}
.wo_actions .ag-center-cols-container {
  overflow: visible;
}
.wo_actions .ag-row {
  overflow: visible;
  /* position: relative; */
}
.wo_actions .ag-row .actions-cell {
  overflow: visible;
}
</style>
