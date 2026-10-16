<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { ClipboardModule, RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
import PartsAdd from '~/components/transaction/PartsAdd.vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const { updateItem, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
ModuleRegistry.registerModules([
  ClientSideRowModelModule,
  RichSelectModule,
  ClipboardModule,
])
const props = defineProps({
  transaction_id: Number,
  transaction_data: Object,
  delete: Boolean,
})

const parts_codes = ref([])
const stateMap = ref<Record<string, string>>({})
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

const columnDefs = ref([
  {
    headerName: '',
    checkboxSelection: true,
    headerCheckboxSelection: true,
    filter: false,
    width: 40,
  },
  {
    headerName: t('Part Number'),
    field: 'part.part_number',
    sortable: true,
    filter: false,
    editable: false,
    onCellClicked: (params) => {
      // console.log('params', params)
      if (!params.value) return
      // Утгыг clipboard руу хуулна
      navigator.clipboard
        .writeText(params.value)
        .then(() => {
          console.log('Copied:', params.value)
        })
        .catch((err) => console.error('Failed to copy:', err))
      // Сонголтыг болиулах (unselect хийх)
      // params.api.deselectAll()
    },
  },

  {
    headerName: t('Part name'),
    field: 'part.name',
    sortable: true,
    filter: true,
    editable: false,
    cellEditor: 'agRichSelectCellEditor',
  },
  {
    headerName: t('Part State'),
    field: 'part_state',
    sortable: true,
    filter: true,
    editable: true,
    cellEditor: 'agRichSelectCellEditor',
    cellEditorParams: () => ({
      values: Object.keys(stateMap.value),
      formatValue: (val) => stateMap.value[val] ?? val,
    }),
    onCellValueChanged: (params) => {
      // if (props.transaction_data?.status === 2) return

      params.node.setDataValue('part_state', params.newValue)
      const updateData = params.data
      updateData.part_state = params.newValue
      asyncUpdateRow(params.data)
    },
    valueFormatter: (params) => {
      // console.log(
      //   'stateMap',
      //   stateMap,
      //   stateMap.value[params.value],
      //   params.value,
      // )
      if (!params.value) return '—'
      return stateMap.value[params.value] ?? params.value
    },
  },
  {
    headerName: t('Qty'),
    field: 'qty',
    sortable: true,
    filter: false,
    // editable: props.transaction_data?.status === 2 ? false : true,
    editable: false,
    maxWidth: 120,

    onCellValueChanged: (params) => {
      if (props.transaction_data?.status === 2) return

      params.node.setDataValue('price', params.data.price)
      const updateData = params.data
      updateData.qty = params.newValue
      updateData.amount = params.data.price * params.newValue
      asyncUpdateRow(params.data)
      return params.node.setDataValue('amount', updateData.amount)
    },
  },
  {
    headerName: t('Price'),
    field: 'wo_price',
    sortable: true,
    filter: true,
    editable: false,
    maxWidth: 180,
    onCellValueChanged: (params) => {
      console.log('onCellValueChanged', params)
      // oldValue, newValue, data, colDef, column, api, node, context, eGridCell
      if (props.transaction_data?.status === 2) return

      // params.node.setDataValue('price', params.data.price)
      // const updateData = params.data
      // updateData.qty = params.newValue
      // updateData.amount = params.data.price * params.newValue
      // asyncUpdateRow(params.data)
      // return params.node.setDataValue('amount', updateData.amount)
    },
  },
  {
    headerName: t('Amount'),
    field: 'wo_amount',
    sortable: true,
    filter: true,
    editable: false,
    maxWidth: 180,
    valueFormatter: (params) => {
      // Format as number with 2 decimals
      params.data.wo_amount = params.data.wo_price * params.data.wo_quantity
      return params.value ? Number(params.value) : params.data.wo_amount
    },
  },
  {
    field: 'part.description',
    headerName: t('Description'),
    headerClass: 'header-description',
    minWidth: 380,
  },
])

const loading = ref(true)
const gridApi = ref()
const { getItems } = useDirectusItems()
const { params } = useRoute()
const rowData = ref([])
const key = ref(1)
const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selectedRow = ref(-1)

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    const filters = {
      transaction_id: props.transaction_id,
      part: {
        status: 1,
      },
    }

    const items = await getItems<any>({
      collection: 'Transaction_parts',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: [
          '*',
          'part.*',
          'transaction_id.*',
          'transaction_id.work_order.*',
        ],
      },
    })

    // console.log('Transaction_parts items:', items)

    // Get work_order from transaction
    const workOrderId = props.transaction_data?.work_order?.id

    // console.log('Work order ID from transaction:', workOrderId)

    // Fetch Work_order_Parts prices for each transaction part
    const enrichedData = await Promise.all(
      items.data.map(async (item) => {
        // console.log('Processing item:', {
        //   part_id: item.part?.id,
        //   work_order_id: workOrderId,
        //   item: item,
        // })

        if (workOrderId && item.part?.id) {
          try {
            const woParts = await getItems<any>({
              collection: 'Work_order_Parts',
              params: {
                filter: {
                  work_order: workOrderId,
                  parts: item.part.id,
                  status: 1,
                },
                fields: ['price', 'quantity'],
                limit: 1,
              },
            })

            // console.log('Work_order_Parts response:', woParts)
            // console.log('woParts type:', typeof woParts)
            // console.log('woParts is array:', Array.isArray(woParts))
            // console.log('woParts.data:', woParts?.data)
            // console.log('woParts[0]:', woParts?.[0])

            // Check if woParts is the data directly (array) or has .data property
            const woData = Array.isArray(woParts) ? woParts : woParts?.data

            if (woData && woData.length > 0) {
              // console.log('Found WO price:', woData[0].price)
              const price = Number(woData[0].price) || 0
              const qty = Number(item.qty) || 0
              const amount = price * qty

              console.log(
                `Part ${item.part.part_number}: price=${price}, qty=${qty}, amount=${amount}`,
              )

              return {
                ...item,
                wo_price: price,
                wo_quantity: woData[0].quantity || 0,
                wo_amount: amount,
              }
            } else {
              console.log('No parts found for part:', item.part.id)
            }
          } catch (err) {
            console.error('Error fetching WO part price:', err)
          }
        } else {
          console.log('Missing work_order or part ID')
        }
        return {
          ...item,
          wo_price: item.price || 0,
          wo_quantity: item.qty || 0,
          wo_amount: 0,
        }
      }),
    )

    console.log('Enriched data with amounts:', enrichedData)
    rowData.value = enrichedData
    loading.value = false
  } catch (e) {
    console.error('Error loading parts:', e)
    loading.value = false
  }
}

const loadParts = async ({ page, itemsPerPage }) => {
  loading.value = true

  console.log('props', props)

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

    console.log('Parts', items)
    parts_codes.value = items.data
    loading.value = false
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
  rowSelection: 'multiple',
  enableCellTextSelection: true,
  ensureDomOrder: true,
  suppressCopyRowsToClipboard: false,
  suppressCopySingleCellRanges: false,
  copyHeadersToClipboard: true,
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
const getRowNodeId = (data) => {
  return data.id
}

const asyncUpdateRow = async (data) => {
  console.log('Update data : ', data)
  if (data && data.id) {
    const updateData = {
      collection: 'Transaction_parts',
      id: data.id,
      item: {
        name: data.name,
        price: data.price,
        qty: data.qty,
        part: data.part?.id,
        part_state: data.part_state ? Number(data.part_state) : null,

        //  logo: values.company.logo,
        // location: props.transaction_id,
        // max_qty: data.max_qty,
        // min_qty: data.min_qty,
      },
    }
    updateItem(updateData)
  }
}

const asyncInsertRow = async (data) => {
  const insertData = data
  insertData.transaction_id = props.transaction_id
  insertData.part = getDefaultRow()?.id
  insertData.company_id = myCompanyId
  console.log('insertData', insertData)

  createItems({
    collection: 'Transaction_parts',
    items: [insertData],
  }).then((response) => {
    const rowDataOverride = response[0]
    rowDataOverride.part = {
      id: response[0].part,
      name: parts_codes.value.find((opt) => opt.id === response[0].part).name,
      price: parts_codes.value.find((opt) => opt.id === response[0].part).price,
    }
    rowDataOverride.transaction_id = {
      id: response[0].transaction_id,
    }
    console.log(gridApi.value)
    gridApi.value.applyTransactionAsync({ add: [rowDataOverride] })
  })
}

const handleModalOpen = async () => {
  selectedItem.value = -1
  isModalOpen.value = true

  // Customize the default values
  // const defaultRow = {
  //   'part.name': getDefaultRow()?.name,
  //   asset: props.transaction_id,
  //   // 'asset.id': props.transaction_id,
  // }
  // try {
  //   // Insert the row into the database asynchronously
  //   await asyncInsertRow(defaultRow)
  // } catch (error) {
  //   console.error('Error adding new row:', error)
  // }
}

const handleModalClose = () => {
  isModalOpen.value = false
  selectedItem.value = -1
  selectedRow.value = -1
  console.log(isModalOpen.value)
}

const deleteRows = async () => {
  const sel = gridApi.value.getSelectedRows()
  if (sel && sel.length > 0) {
    const ids = sel.map((item) => item.id)
    gridApi.value.applyTransaction({ remove: sel })
    console.log('ids_Parts_Amounts_update_new_count', ids)

    deleteItems({
      collection: 'Transaction_parts',
      items: ids,
    })
  }
  isModalOpen.value = false
}

const loadStates = async () => {
  try {
    const res = await getItems<any>({
      collection: 'States',
      params: {
        fields: ['id', 'name'],
        limit: -1,
        filter: { company_id: myCompanyId },
      },
    })
    const items = Array.isArray(res) ? res : (res as any)?.data ?? []
    const map: Record<string, string> = {}
    for (const s of items) {
      map[String(s.id)] = s.name || String(s.id)
    }
    stateMap.value = map
    // Re-mount the grid so valueFormatter runs with the populated stateMap
    handleChangeKey()
  } catch (e) {
    console.warn('Failed to load states:', e)
  }
}

onMounted(async () => {
  await loadItems(1, -1)
  await loadParts(1, -1)
  await loadStates()
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
    <div class="grid grid-cols-6 gap-6 part_ag px-6 py-5">
      <div v-if="props.transaction_data?.status != 2" class="col-span-6">
        <BaseButton
          v-if="props.delete === true"
          class="float-right"
          @click="deleteRows"
        >
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts delete') }}</span>
        </BaseButton>
        <!-- 
        <BaseButton class="float-right mr-10" @click="handleModalOpen">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts add') }}</span>
        </BaseButton> -->
      </div>
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
      <PartsAdd
        :work_order="props.work_order"
        :row="selectedItem"
        :title="t('Incoming parts')"
        module="Parts"
        code="Parts"
        :open="isModalOpen"
        :close="handleModalClose"
        size="xl"
      />
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
