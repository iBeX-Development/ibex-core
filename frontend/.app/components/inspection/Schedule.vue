<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const { updateItem, createItems, deleteItems } = useDirectusItems()
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

const parts_codes = ref([])

const dateFormatter = ({ value }) => {
  if (!value) return '-'
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
    headerName: '',
    checkboxSelection: true,
    headerCheckboxSelection: true,
  },
  {
    headerName: t('Part name'),
    field: 'parts.name',
    sortable: true,
    filter: true,
    editable: true,
    cellEditor: 'agRichSelectCellEditor',
    cellEditorParams: (params) => {
      // Extract the values (display text) from the options
      return {
        values: parts_codes.value.map((opt) => opt.name),
      }
    },
    onCellValueChanged: (params) => {
      console.log(params.newValue)
      const selectedOption = parts_codes.value.find(
        (opt) => opt.name === params.newValue,
      )
      if (selectedOption) {
        const updateData = params.data
        updateData.price = selectedOption?.price
        updateData.parts.id = selectedOption?.id
        updateData.amount = selectedOption?.price * params.data.quantity
        asyncUpdateRow(params.data)
        params.node.setDataValue('price', selectedOption?.price)
        return params.node.setDataValue('amount', updateData.amount)
      }
    },
  },
  {
    headerName: t('Quantity'),
    field: 'quantity',
    sortable: true,
    filter: false,
    editable: true,
    onCellValueChanged: (params) => {
      console.log(params)
      params.node.setDataValue('price', params.data.parts.price)
      const updateData = params.data
      updateData.quantity = params.newValue
      updateData.amount = params.data.parts.price * params.newValue
      asyncUpdateRow(params.data)
      return params.node.setDataValue('amount', updateData.amount)
    },
  },
  {
    headerName: t('Price'),
    field: 'price',
    sortable: true,
    filter: true,
    editable: false,
  },
  {
    headerName: t('Amount'),
    field: 'amount',
    sortable: true,
    filter: true,
    editable: false,
  },
  {
    headerName: t('Created'),
    field: 'date_created',
    sortable: true,
    filter: true,
    editable: false,
    valueFormatter: dateFormatter,
  },
])

const loading = ref(true)
const gridApi = ref()
const { getItems } = useDirectusItems()
const { params } = useRoute()
const rowData = ref([])
const key = ref(1)

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: params.id,
    }
    const items = await getItems<any>({
      collection: 'Work_inpection_Parts',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*', 'parts.*', 'work_order.* '],
      },
    })
    rowData.value = items.data
    loading.value = false
  } catch (e) {}
}

const loadParts = async ({ page, itemsPerPage }) => {
  try {
    const filters = {
      status: '1',
    }
    const items = await getItems<any>({
      collection: 'Parts',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    parts_codes.value = items.data
  } catch (e) {}
}

const onGridReady = async (grid_params) => {
  gridApi.value = grid_params.api
  // const datasource = createServerSideDatasource()
  // await gridApi.value.setGridOption('serverSideDatasource', datasource)
}

const gridOptions = ref({
  defaultColDef: {
    sortable: true,
    filter: true,
    resizable: true,
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
  rowSelection: 'multiple',
})
const getRowNodeId = (data) => {
  return data.id
}

const asyncUpdateRow = async (data) => {
  console.log('Update data : ', data)
  if (data && data.id) {
    const updateData = {
      collection: 'Work_inpection_Parts',
      id: data.id,
      item: {
        name: data.name,
        price: data.price,
        amount: data.amount,
        //  logo: values.company.logo,
        quantity: data.quantity,
        parts: data.parts?.id,
        work_order: params.id,
      },
    }
    updateItem(updateData)
  }
}

const asyncInsertRow = async (data) => {
  const insertData = data
  insertData.work_order = params.id
  insertData.parts = getDefaultRow()?.id
  insertData.company_id = myCompanyId
  createItems({
    collection: 'Work_inpection_Parts',
    items: [insertData],
  }).then((response) => {
    const rowDataOverride = response[0]
    rowDataOverride.parts = {
      id: response[0].parts,
      name: parts_codes.value.find((opt) => opt.id === response[0].parts).name,
      price: parts_codes.value.find((opt) => opt.id === response[0].parts)
        .price,
    }
    rowDataOverride.work_order = {
      id: response[0].work_order,
    }
    console.log(gridApi.value)
    gridApi.value.applyTransactionAsync({ add: [rowDataOverride] })
  })
}
const addEmptyRow = async () => {
  const defaultRow = {
    'parts.name': getDefaultRow()?.name,
    'work_order.id': params.id,
    quantity: 0.0,
    price: getDefaultRow()?.price,
    amount: 0.0,
  } // Customize the default values
  try {
    // Insert the row into the database asynchronously
    await asyncInsertRow(defaultRow)
  } catch (error) {
    console.error('Error adding new row:', error)
  }
}

const deleteRows = async () => {
  const sel = gridApi.value.getSelectedRows()
  if (sel && sel.length > 0) {
    const ids = sel.map((item) => item.id)
    gridApi.value.applyTransaction({ remove: sel })
    deleteItems({
      collection: 'Work_inpection_Parts',
      items: ids,
    })
  }
}

onMounted(async () => {
  await loadItems(1, -1)
  await loadParts(1, -1)
})

const getDefaultRow = () => {
  return parts_codes.value
    ? parts_codes.value[0]
    : { id: null, name: '', price: 0, amount: 0 }
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <div class="col-span-12">
        <BaseButton class="float-right" @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts delete') }}</span>
        </BaseButton>

        <BaseButton class="float-right mr-10" @click="addEmptyRow">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts add') }}</span>
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
          @grid-ready="onGridReady"
          :rowData="rowData"
        >
        </ag-grid-vue>
      </div>
    </div>
  </div>
</template>
