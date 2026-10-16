<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
import PartsAddForm from '~/components/assets/PartsAddForm.vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const loading = ref(true)
const gridApi = ref()
const { params } = useRoute()
const rowData = ref([])
const key = ref(1)

const props = defineProps({
  open: Boolean,
  title: String,
  asset_id: Number,
  location_id: Number,
})

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

const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selectedRow = ref(-1)
const editPartRow = ref(-1)
const toaster = useToaster()

const parts_codes = ref([])
const do_edit = (item) => {
  // selectedItem.value = item.id
  // isModalOpen.value = true
  console.log('do_edit')
}

const do_delete = (item) => {
  // isModalConfirmOpen.value = true
  // selectedItem.value = item.id
  console.log('do_delete')
}

const gridOptions = ref({
  defaultColDef: {
    sortable: true,
    filter: true,
    resizable: true,
    flex: 1,
  },
  rowSelection: 'multiple',
  suppressHorizontalScroll: false, // Хэвтээ scroll идэвхгүй болгох
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

const dateFormatter = ({ value }) => {
  if (!value) return ''
  const localTime = new Date(value)
  if (isNaN(localTime.getTime())) return ''

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
    filter: false,
    width: 40,
    flex: 0,
  },
  {
    headerName: t('Part number'),
    field: 'part.part_number',
    sortable: true,
    filter: false,
    editable: false,
  },
  {
    headerName: t('Part name'),
    field: 'part.name',
    sortable: true,
    filter: true,
    editable: false,
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
        updateData.part.id = selectedOption?.id
        updateData.amount = selectedOption?.price * params.data.quantity
        asyncUpdateRow(params.data)
        params.node.setDataValue('price', selectedOption?.price)
        return params.node.setDataValue('amount', updateData.amount)
      }
    },
  },
  {
    field: 'part.description',
    headerName: t('Description'),
    headerClass: 'header-description',
    minWidth: 280,
  },
  {
    headerName: t('Quantity'),
    field: 'quantity',
    sortable: true,
    filter: false,
    editable: true,
    onCellValueChanged: (params) => {
      params.node.setDataValue('price', params.data?.price)
      const updateData = params.data
      updateData.quantity = params.newValue
      updateData.amount = params.data?.price * params.newValue
      asyncUpdateRow(params.data)
      return params.node.setDataValue('amount', updateData.amount)
    },
  },
  // {
  //   headerName: 'State',
  //   field: 'part_state',
  //   sortable: true,
  //   filter: false,
  //   editable: true,
  //   onCellValueChanged: (params) => {
  //     const updateData = params.data
  //     updateData.part_state = params.newValue
  //     asyncUpdateRow(params.data)
  //     return params.node.setDataValue('part_state', updateData.part_state)
  //   },
  // },
  {
    headerName: t('Price'),
    field: 'price',
    sortable: true,
    filter: true,
    editable: false,
    onCellValueChanged: (params) => {
      params.node.setDataValue('price', params.data?.price)
      const updateData = params.data
      updateData.price = params.newValue
      asyncUpdateRow(params.data)
    },
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
    minWidth: 180,
    valueFormatter: dateFormatter,
  },

  {
    headerName: t('Updated'),
    field: 'date_updated',
    sortable: true,
    filter: true,
    editable: false,
    minWidth: 180,
    valueFormatter: dateFormatter,
  },

  // {
  //   field: 'actions',
  //   headerName: 'Actions',
  //   minWidth: 108,
  //   sortable: false,
  //   filter: false,
  //   cellEditorPopup: true,
  //   cellRenderer: ActionDropdownCellRenderer,
  //   cellRendererParams: {
  //     onEditClick: do_edit,
  //     onDeleteClick: do_delete,
  //   },
  //   cellClass: 'actions-cell',
  //   cellStyle: {
  //     // 'background-color': 'green',
  //   },
  // },
])

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    const filters = {
      asset: props.asset_id,
      part: {
        status: 1,
      },
    }

    const items = await getItems<any>({
      collection: 'Asset_Parts',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*', 'part.*', 'asset.* '],
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
      company_id: myCompanyId,
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
  grid_params.api.sizeColumnsToFit() // Багануудыг дэлгэцэнд тааруулах
  console.log('hello')
  // gridOptions.api = params.api
  // const datasource = createServerSideDatasource()
  // await gridApi.value.setGridOption('serverSideDatasource', datasource)
}

const getRowNodeId = (data) => {
  return data.id
}

// Parts_Amounts.asset_amount cache байхгүй боллоо — асаж хадгалдаг байсан
// updateStock()-ыг устгав. asset_amount одоо parts/location жагсаалт дээр
// Asset_Parts-аас шууд live тооцогддог тул энд синк хийх шаардлагагүй.

const asyncUpdateRow = async (data) => {
  console.log('Update data : ', data)
  if (data && data.id) {
    const old_items = await getItems<any>({
      collection: 'Asset_Parts',
      params: {
        filter: { id: data.id },
        meta: 'filter_count',
        fields: ['*', 'part.*', 'asset.* '],
      },
    })

    console.log('old_items data : ', old_items)

    const updateData = {
      collection: 'Asset_Parts',
      id: data.id,
      item: {
        name: data.name,
        price: data.price,
        amount: data.amount,
        quantity: data.quantity,
        part: data.part?.id,
        // part_state: data.part_state,
      },
    }
    updateItem(updateData)
  }
}

const asyncInsertRow = async (data) => {
  const insertData = data
  insertData.location = params.id
  insertData.part = getDefaultRow()?.id
  console.log('asyncInsertRow -> ', insertData)
  // Asset_Parts create
  createItems({
    collection: 'Asset_Parts',
    items: [{ ...insertData, company_id: myCompanyId }],
  }).then((response) => {
    const rowDataOverride = response[0]
    rowDataOverride.part = {
      id: response[0].part,
      name: parts_codes.value.find((opt) => opt.id === response[0].part).name,
      price: parts_codes.value.find((opt) => opt.id === response[0].part).price,
    }
    rowDataOverride.location = {
      id: response[0].location,
    }
    console.log(gridApi.value)
    gridApi.value.applyTransactionAsync({ add: [rowDataOverride] })
  })
}
const addEmptyRow = async () => {
  // Customize the default values
  const defaultRow = {
    'part.name': getDefaultRow()?.name,
    asset: props.asset_id,
    // location: params.id,
  }

  try {
    // Insert the row into the database asynchronously
    await asyncInsertRow(defaultRow)
  } catch (error) {
    console.error('Error adding new row:', error)
  }
}

const deleteRows = async () => {
  console.log('gridApi.value.id', gridApi.value)

  const sel = gridApi.value.getSelectedRows()
  if (sel && sel.length > 0) {
    const ids = sel.map((item) => item.id)

    gridApi.value.applyTransaction({ remove: sel })

    deleteItems({
      collection: 'Asset_Parts',
      items: ids,
    })
  }
}

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
}

const handleModalClose = () => {
  isModalOpen.value = false
  selectedItem.value = -1
  selectedRow.value = -1
  editPartRow.value = -1
  console.log(isModalOpen.value)
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

const refreshGrid = async () => {
  console.log('refreshGrid')
  // gridApi.value.refreshServerSide()
  // gridApi.value.onFilterChanged()
  // gridApi.value.refreshInfiniteCache()
  await loadItems(1, -1)
  await loadParts(1, -1)
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6 part_ag">
      <div class="col-span-12">
        <BaseButton class="float-right" @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts delete') }}</span>
        </BaseButton>

        <BaseButton class="float-right mr-10" @click="handleModalOpen">
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
        <PartsAddForm
          :key="selectedItem"
          :asset_id="props.asset_id"
          :row="selectedItem"
          :editPartRow="editPartRow"
          :item="selectedRow"
          :refreshGrid="refreshGrid"
          :title="$t('Asset parts')"
          module="Parts"
          code="Parts"
          :open="isModalOpen"
          :close="handleModalClose"
          size="xl"
        />
      </div>
    </div>
  </div>
</template>
<style>
.part_ag .grid_ag {
  min-height: 560px !important;
}
.part_ag .ag-center-cols-container {
  overflow: visible;
}
.part_ag .ag-row {
  overflow: visible;
  /* position: relative; */
}
.part_ag .ag-row .actions-cell {
  overflow: visible;
}
</style>
