<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import ModalItemsList from '~/components/form/ModalItemsList.vue'

const { t } = useI18n({ useScope: 'global' })

const { params } = useRoute()
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

const props = defineProps(['estimated_edit', 'actual_edit', 'work_order'])
const trade_codes = ref([])
const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selectedRow = ref(-1)
const detailRowAutoHeight = true

const loading = ref(true)
const gridApi = ref()
const rowData = ref([])
const key = ref(1)

const autoSizeStrategy = {
  type: 'fitGridWidth',
}

const gridOptions = ref({
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
  rowSelection: 'multiple',
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
        headerName: t('Code'),
        field: 'trade.code',
        sortable: true,
        filter: false,
        width: 180,
        editable: props.work_order?.action_status === 2 ? false : true, //approved
        cellEditor: 'agRichSelectCellEditor',
        cellEditorParams: (params) => {
          // Extract the values (display text) from the options
          return {
            values: trade_codes.value.map((opt) => opt.name),
          }
        },
        onCellValueChanged: (params) => {
          console.log(params.newValue)
          const selectedOption = trade_codes.value.find(
            (opt) => opt.name === params.newValue,
          )
          if (selectedOption) {
            const updateData = params.data
            updateData.rate = selectedOption?.rate
            updateData.trade.id = selectedOption?.id
            updateData.total = selectedOption?.rate * params.data.duration
            asyncUpdateRow(params.data)
            params.node.setDataValue('rate', selectedOption?.rate)
            return params.node.setDataValue('total', updateData.total)
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
        onCellValueChanged: (params) => {
          const updateData = params.data
          updateData.name = params.newValue
          asyncUpdateRow(params.data)
          return params.node.setDataValue('name', params.newValue)
        },
      },
      {
        headerName: t('Duration'),
        headerClass: () =>
          props.work_order?.action_status === 2 ? '' : 'edit_duration', // Динамик class тохируулах
        field: 'duration',
        sortable: true,
        filter: false,
        width: 180,
        editable: props.work_order?.action_status === 2 ? false : true, //approved
        onCellValueChanged: (params) => {
          console.log(params)
          params.node.setDataValue('rate', params.data.trade.rate)
          const updateData = params.data
          updateData.duration = params.newValue
          updateData.total = params.data.trade.rate * params.newValue
          asyncUpdateRow(params.data)
          return params.node.setDataValue('total', updateData.total)
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
        onCellValueChanged: ({ node, data, newValue }) => {
          console.log('params', data)
          data.actual_duration = newValue
          data.actual_total =
            (data.actual_rate > 0 ? data.actual_rate : data.trade.rate) *
            newValue
          asyncUpdateRow(data)

          node.setDataValue(
            'actual_rate',
            data.actual_rate > 0 ? data.actual_rate : data.trade.rate,
          )
          node.setDataValue('actual_total', data.actual_total)
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
        onCellValueChanged: ({ node, data, newValue }) => {
          data.actual_rate = newValue
          data.actual_total = data.actual_duration * newValue
          asyncUpdateRow(data)
          node.setDataValue('actual_total', data.actual_total)
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

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: props.work_order?.id,
    }
    const items = await getItems<any>({
      collection: 'Work_inspection_Tradecode',
      params: {
        filter: filters,
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

const loadTrades = async ({ page, itemsPerPage }) => {
  try {
    const filters = {
      status: '1',
    }
    const items = await getItems<any>({
      collection: 'Tradecode',
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

const onGridReady = async (grid_params) => {
  gridApi.value = grid_params.api
  grid_params.api.sizeColumnsToFit({
    defaultMinWidth: 600,
    columnLimits: [{ key: 'name', minWidth: 100 }],
  }) // Багануудыг дэлгэцэнд тааруулах

  grid_params.api.autoSizeAllColumns()

  // const datasource = createServerSideDatasource()
  // await gridApi.value.setGridOption('serverSideDatasource', datasource)
}

const getRowNodeId = (data) => {
  return data.id
}

const asyncUpdateRow = async (data) => {
  console.log('Update data : ', data)
  if (data && data.id) {
    const updateData = {
      collection: 'Work_inspection_Tradecode',
      id: data.id,
      item: {
        name: data.name,
        rate: data.rate,
        total: data.total,
        //  logo: values.company.logo,
        duration: data.duration,
        actual_duration: data.actual_duration,
        actual_rate: data.actual_rate,
        actual_total: data.actual_total,
        trade: data.trade?.id,
      },
    }
    updateItem(updateData)
  }
}

const asyncInsertRow = async (data) => {
  const insertData = data
  console.log(insertData)
  insertData.work_order = props.work_order?.id
  insertData.trade = getDefaultRow()?.id
  insertData.company_id = myCompanyId
  // delete insertData["work_order.id"]
  createItems({
    collection: 'Work_inspection_Tradecode',
    items: [insertData],
  }).then((response) => {
    const rowDataOverride = response[0]
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
  let insertData: any = {
    work_order: props.work_order?.id,
    trade: obj?.id,
    name: obj?.name,
    rate: obj?.rate,
  }
  createItems({
    collection: 'Work_inspection_Tradecode',
    items: [insertData],
  }).then((response) => {
    let rowDataOverride: any = response[0]
    rowDataOverride.trade = {
      id: response[0].trade,
      code: obj?.code,
      rate: obj?.rate,
      name: obj?.name,
    }
    rowDataOverride.work_order = {
      id: response[0].work_order,
    }
    gridApi.value.applyTransactionAsync({ add: [rowDataOverride] })
  })
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
    const ids = sel.map((item) => item.id)
    gridApi.value.applyTransaction({ remove: sel })
    deleteItems({
      collection: 'Work_inspection_Tradecode',
      items: ids,
    })
  }
}

onMounted(async () => {
  await loadItems(1, -1)
  // await loadTrades(1, -1)
})

const getDefaultRow = () => {
  return trade_codes.value
    ? trade_codes.value[0]
    : { id: null, name: '', rate: 0, total: 0 }
}

const refresh = (newData) => {
  gridApi.value.refreshClientSideRowModel()
  // gridApi.value.applyTransaction({ add: [newData] });
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <div
        v-if="
          props.work_order?.completed_at === null &&
          props.work_order?.action_status !== 2
        "
        class="col-span-12 flex justify-end gap-6"
      >
        <BaseButton class="float-right" @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Trade delete') }}</span>
        </BaseButton>

        <BaseButton class="float-right" @click="handleModalOpen">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Trade add') }}</span>
        </BaseButton>
      </div>
      <!-- Header -->
      <div class="col-span-12">
        <ag-grid-vue
          :key="key"
          style="width: 100%; height: 560px"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list`"
          :columnDefs="columnDefs"
          :gridOptions="gridOptions"
          :autoSizeStrategy="autoSizeStrategy"
          @grid-ready="onGridReady"
          :rowData="rowData"
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
        collection="Tradecode"
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
