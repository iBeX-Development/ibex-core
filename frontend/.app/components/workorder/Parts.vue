<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { ClipboardModule, RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { format } from 'date-fns'
import { ref } from 'vue'
import WorkPartsAddForm from '~/components/workorder/WorkPartsAddForm.vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
// const { getItems: getItems2 } = useDirectusItems()

const loading = ref(true)
const gridApi = ref()
const { params } = useRoute()
const rowData = ref([])
const key = ref(1)
const stateMap = ref<Record<string, string>>({})

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
ModuleRegistry.registerModules([
  ClientSideRowModelModule,
  RichSelectModule,
  ClipboardModule,
])

const props = defineProps([
  'estimated_edit',
  'actual_edit',
  'work_order',
  'loadedParts',
  'collection',
  'freeze',
])

const collectionName = computed(() => props.collection || 'Work_order_Parts')
const parts_codes = ref([])

const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selectedRow = ref(-1)
const emit = defineEmits(['update:loadedParts'])

const columnDefs = ref([
  {
    headerName: t('Planned'),
    children: [
      {
        headerName: t(''),
        checkboxSelection: true,
        headerCheckboxSelection: true,
        filter: false,
        sortable: false,
        width: 40,
      },
      {
        headerName: t('Created'),
        field: 'date_created',
        sortable: true,
        filter: false,
        editable: false,
        width: 240,
        valueGetter: (params) => {
          if (params.data?.date_created) {
            const date = new Date(params.data.date_created)
            return format(date, 'yyyy-MM-dd HH:mm') // Format the date
          } else {
            return ''
          }
        },
      },
      {
        headerName: t('Number'),
        field: 'parts.part_number',
        type: 'editableColumn',
        sortable: true,
        filter: true,
        editable: false,
        minWidth: 130,
        cellEditor: 'agRichSelectCellEditor',
        cellEditorParams: (params) => {
          // Extract the values (display text) from the options
          return {
            values: parts_codes.value.map((opt) => opt.part_number),
            allowTyping: true,
            filterList: true,
            highlightMatch: true,
            valueListMaxHeight: 220,
          }
        },
        onCellValueChanged: (params) => {
          console.log(params.newValue)
          const selectedOption = parts_codes.value.find(
            (opt) => opt.part_number === params.newValue,
          )
          // Ajax load hiine
          if (selectedOption) {
            console.log(selectedOption)
            const updateData = params.data
            updateData.name = selectedOption?.name
            updateData.price = selectedOption?.price
            updateData.parts.id = selectedOption?.id
            updateData.amount = selectedOption?.price * params.data.quantity
            asyncUpdateRow(params.data)
            params.node.setDataValue('price', selectedOption?.price)
            params.node.setDataValue(
              'parts.description',
              selectedOption?.description,
            )
            return params.node.setDataValue('amount', updateData.amount)
          }
        },
      },
      {
        headerName: t('Description'),
        field: 'parts.description',
        sortable: true,
        editable: false,
        minWidth: 150,
        cellEditor: 'agRichSelectCellEditor',
        cellEditorParams: (params) => {
          // Extract the values (display text) from the options
          return {
            values: () => {
              return parts_codes.value.map((opt) => opt.description)
            },
            allowTyping: true,
            filterList: true,
            highlightMatch: true,
            valueListMaxHeight: 220,
          }
        },
        onCellValueChanged: (params) => {
          console.log(params.newValue)

          const selectedOption = parts_codes.value.find(
            (opt) => opt.description === params.newValue,
          )
          if (selectedOption) {
            console.log(selectedOption)
            const updateData = params.data
            updateData.part_number = selectedOption?.part_number
            updateData.price = selectedOption?.price
            updateData.parts.id = selectedOption?.id
            updateData.amount = selectedOption?.price * params.data.quantity
            asyncUpdateRow(params.data)
            params.node.setDataValue('price', selectedOption?.price)
            params.node.setDataValue(
              'parts.part_number',
              selectedOption?.part_number,
            )
            return params.node.setDataValue('amount', updateData.amount)
          }
        },
      },
      {
        headerName: t('Quantity'),
        field: 'quantity',
        sortable: true,
        editable: (params) => props.work_order?.action_status !== 2,
        onCellValueChanged: (params) => {
          const updateData = params.data
          updateData.quantity = params.newValue
          updateData.amount = params.data.price * params.newValue
          asyncUpdateRow(updateData)
          return params.node.setDataValue('amount', updateData.amount)
        },
        headerClass: () =>
          props.work_order?.action_status === 2 || props.freeze
            ? ''
            : 'edit_duration', // Динамик class тохируулах
      },
      {
        headerName: t('State'),
        field: 'part_state',
        sortable: true,
        filter: false,
        editable: false,
        valueFormatter: (params) => {
          console.log('part_state_wo')
          return params.data?.part_state != null
            ? stateMap.value[String(params.data.part_state)] ??
                String(params.data.part_state)
            : '—'
        },
      },
      {
        headerName: t('Price'),
        field: 'price',
        sortable: true,
        filter: false,
        editable: (params) => props.work_order?.action_status !== 2,

        onCellValueChanged: (params) => {
          const updateData = params.data
          updateData.price = params.newValue
          updateData.amount = params.newValue * params.data.quantity
          // console.log('updateData', updateData)
          asyncUpdateRow(updateData)
          return params.node.setDataValue('amount', updateData.amount)
        },
      },
      {
        headerName: t('Amount'),
        field: 'amount',
        sortable: true,
        filter: false,
        editable: false,
      },
    ],
  },
  {
    headerName: t('Actuals'),
    children: [
      {
        headerName: t('Quantity'),
        field: 'actual_quantity',
        sortable: true,
        filter: false,
        editable: props.actual_edit,
        onCellValueChanged: (params) => {
          console.log(params)
          params.node.setDataValue('actual_price', params.data.parts.price)
          const updateData = params.data
          updateData.actual_quantity = params.newValue
          updateData.actual_amount = params.data.parts.price * params.newValue
          asyncUpdateRow(params.data)
          return params.node.setDataValue(
            'actual_amount',
            updateData.actual_amount,
          )
        },
        headerClass: () => (props.actual_edit ? 'edit_duration' : ''), // Динамик class тохируулах
      },
      {
        headerName: t('Price'),
        field: 'actual_price',
        sortable: true,
        filter: false,
        editable: false,
      },
      {
        headerName: t('Amount'),
        field: 'actual_amount',
        sortable: true,
        filter: false,
        editable: false,
      },
    ],
  },
])

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    console.log('Collection', collectionName.value)

    const filters = {
      status: '1',
      work_order: props.work_order?.id,
    }
    const items = await getItems<any>({
      collection: collectionName.value,
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*', 'parts.*', 'work_order.* '],
      },
    })
    rowData.value = items.data
    emit('update:loadedParts', items.data)

    loading.value = false
  } catch (e) {}
}

const loadParts = async ({ page, itemsPerPage }) => {
  try {
    const filters = {
      status: '1',
      location: props.work_order.location
        ? props.work_order.location
        : props.work_order.asset?.location?.id,
      asset: props.work_order.asset?.id,
    }

    const items = await getItems<any>({
      collection: 'Asset_Parts',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*', 'part.*', 'asset.*'],
      },
    })

    parts_codes.value = items.data.map((item) => item.part)
  } catch (e) {}
}

const onGridReady = async (grid_params) => {
  gridApi.value = grid_params.api
  grid_params.api.sizeColumnsToFit() // Багануудыг дэлгэцэнд тааруулах

  // const datasource = createServerSideDatasource()
  // await gridApi.value.setGridOption('serverSideDatasource', datasource)
}

const gridOptions = ref({
  defaultColDef: {
    sortable: true,
    filter: false,
    resizable: true,
    autoSizeAllColumns: true,
    suppressHeaderMenuButton: true,
    autoSizeStrategy: {
      type: 'fitCellContents',
    },
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
  flex: 1,
  enableCellTextSelection: true,
  ensureDomOrder: true,
  suppressCopyRowsToClipboard: false,
  suppressCopySingleCellRanges: false,
  copyHeadersToClipboard: true,
  // suppressHorizontalScroll: true, // Хэвтээ scroll идэвхгүй болгох

  columnTypes: {
    editableColumn: {
      editable: (params) => {
        console.log('Testing editable : ', params)
        return true
      },
    },
  },
})
const getRowNodeId = (data) => {
  return data.id
}

const asyncUpdateRow = async (data) => {
  console.log('Update data : ', data)
  if (data && data.id) {
    const updateData = {
      collection: collectionName.value,
      id: data.id,
      item: {
        name: data.name,
        price: data.price,
        amount: data.amount,
        //  logo: values.company.logo,
        quantity: data.quantity,
        actual_price: data.actual_price,
        actual_amount: data.actual_amount,
        //  logo: values.company.logo,
        actual_quantity: data.actual_quantity,

        parts: data.parts?.id,
        work_order: {
          id: props.work_order?.id,
        },
      },
    }
    updateItem(updateData)
  }
}

const asyncInsertRow = async (data) => {
  const insertData = data
  insertData.work_order = props.work_order?.id
  insertData.parts = getDefaultRow()?.id
  insertData.company_id = myCompanyId

  createItems({
    collection: collectionName.value,
    items: [insertData],
  }).then((response) => {
    const rowDataOverride = response[0]
    rowDataOverride.parts = {
      id: response[0].parts,
      part_number: parts_codes.value.find((opt) => opt.id === response[0].parts)
        .part_number,
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
    'work_order.id': props.work_order?.id,
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
      collection: collectionName.value,
      items: ids,
    })
  }
}

const refreshGrid = async () => {
  console.log('refreshGrid')
  await loadItems(1, -1)
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

onMounted(async () => {
  try {
    console.log('WOPartss')

    const res = await getItems({
      collection: 'States',
      params: {
        filter: { company_id: myCompanyId },
        fields: ['id', 'name'],
        limit: -1,
      },
    })
    const items = Array.isArray(res) ? res : (res as any)?.data ?? []
    console.log('StatesItems', items)

    const map: Record<string, string> = {}
    for (const s of items) map[String(s.id)] = s.name || String(s.id)
    console.log('map', map)

    stateMap.value = map
  } catch (e) {
    console.warn('Failed to load states:', e)
  }

  if (props.loadedParts) {
    rowData.value = props.loadedParts
    loading.value = false
    console.log('part-loaded', props.loadedParts)
  } else await loadItems(1, -1)
})

const getDefaultRow = () => {
  return parts_codes.value
    ? parts_codes.value[0]
    : { id: null, part_number: '', description: '', price: 0, amount: 0 }
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <div
        v-if="
          <!-- props.work_order?.completed_at === null && -->
          !props.freeze &&
          props.work_order?.action_status !== 2
        "
        class="col-span-12"
      >
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
        <WorkPartsAddForm
          :work_order="props.work_order"
          :row="selectedItem"
          :refreshGrid="refreshGrid"
          title="WO parts"
          module="Parts"
          code="Parts"
          :open="isModalOpen"
          :close="handleModalClose"
          size="3xl"
          :collection="collectionName"
        />
      </div>
    </div>
  </div>
</template>
<style scoped>
.grid_ag_list .edit_duration .ag-header-cell-text {
  color: #04a504;
}
</style>
