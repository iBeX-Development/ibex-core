<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
const { updateItem, createItems, deleteItems } = useDirectusItems()
const { token } = useDirectusToken()
const runtimeConfig = useRuntimeConfig()
const myCompanyId = getMyCompanyId()
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
definePageMeta({
  middleware: ['auth'],
  title: 'Parts Listing',
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

const columnDefs = ref([
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
    // cellEditor: 'agRichSelectCellEditor',
    // cellEditorParams: (params) => {
    //   // Extract the values (display text) from the options
    //   return {
    //     values: parts_codes.value.map((opt) => opt.name),
    //   }
    // },
    // onCellValueChanged: (params) => {
    //   console.log(params.newValue)
    //   const selectedOption = parts_codes.value.find(
    //     (opt) => opt.name === params.newValue,
    //   )
    //   if (selectedOption) {
    //     const updateData = params.data
    //     updateData.price = selectedOption?.price
    //     updateData.part.id = selectedOption?.id
    //     updateData.amount = selectedOption?.price * params.data.quantity
    //     asyncUpdateRow(params.data)
    //     params.node.setDataValue('price', selectedOption?.price)
    //     return params.node.setDataValue('amount', updateData.amount)
    //   }
    // },
  },
  {
    headerName: t('Total'),
    field: 'quantity',
    sortable: true,
    filter: false,
    editable: false,
    // onCellValueChanged: (params) => {
    //   console.log(params)
    //   params.node.setDataValue('price', params.data.part.price)
    //   const updateData = params.data
    //   updateData.quantity = params.newValue
    //   updateData.amount = params.data.part.price * params.newValue
    //   asyncUpdateRow(params.data)
    //   return params.node.setDataValue('amount', updateData.amount)
    // },
  },
  // {
  //   headerName: 'Amount',
  //   field: 'amount',
  //   sortable: true,
  //   filter: true,
  //   editable: false,
  // },
  {
    headerName: t('Stock'),
    field: 'qty',
    sortable: true,
    filter: true,
    editable: false,
  },
])

const loading = ref(true)
const gridApi = ref()
const { getItems } = useDirectusItems()
const { params } = useRoute()
const rowData = ref([])
const key = ref(1)

let parts_items_all = []
const partIds = new Set() // Use a Set to avoid duplicate IDs

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    // const filters = {
    //   status: '1',
    //   location: params.id,
    // }
    // const items = await getItems<any>({
    //   collection: 'Asset_Parts',
    //   params: {
    //     filter: filters,
    //     limit: itemsPerPage,
    //     page: page,
    //     meta: 'filter_count',
    //     fields: ['*', 'part.*', 'location.*'],
    //   },
    // })

    const trans_items = await getItems({
      collection: 'Transaction',
      params: {
        filter: { location: params.id, transaction_type: 'INCOME', status: 2 },
        meta: 'filter_count',
        fields: ['*', 'location.*'],
      },
    })

    const partsRequests = trans_items.data.map(async (item) => {
      const trans_part = await getItems({
        collection: 'Transaction_parts',
        params: {
          filter: { transaction_id: item.id },
          meta: 'filter_count',
          fields: ['*', 'part.*'], // Include all part details
        },
      })

      if (trans_part.data.length) {
        // console.log('trans_part', trans_part.data)

        parts_items_all.push(...trans_part.data) // Push data directly into the array
        // Collect unique part IDs
        trans_part.data.forEach((partItem) => {
          if (partItem.part?.id) {
            partIds.add(partItem.part.id)
          }
        })
      }
    })

    const parts_items = await Promise.all(partsRequests)

    const filters = {
      part: { _in: Array.from(partIds) },
      location: params.id,
      status: '1',
    } // Filter for parts in the collected IDs

    const items = await getItems<any>({
      collection: 'Asset_Parts',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*', 'part.*', 'location.*'],
      },
    })

    // console.log('items', items)
    // console.log('parts_items_all', parts_items_all)
    // console.log('parts_items', parts_items)

    // const parts_items = await getItems({
    //   collection: 'Transaction',
    //   params: {
    //     filter: { location: params.id, transaction_type: 'INCOME', status: 2 }, //approved
    //     meta: 'filter_count',
    //     fields: [
    //       '*', // Include all fields from Transaction
    //       'location.*', // Include all fields from the related location
    //       'Transaction_parts.*', // Include all fields from related Transaction_parts
    //       'Transaction_parts.part.*', // Include all fields from related Part within Transaction_parts
    //     ],
    //     deep: {
    //       Transaction_parts: {
    //         _filter: { transaction_type: 'income' }, // Optional: Filter for related transaction parts
    //       },
    //     },
    //   },
    // })

    // console.log('hi2.datadsds ->> ', parts_items)

    // Step 1: Calculate total amount
    // const totalAmount = (parts) =>
    //   parts.reduce((sum, part) => sum + part.amount, 0)

    const mergedParts = (parts) => {
      return Object.values(
        parts.reduce((acc, current) => {
          const partId = current.part.id
          if (!acc[partId]) {
            // Initialize the first occurrence of this part
            acc[partId] = { ...current }
          } else {
            // Merge quantities and amounts
            acc[partId].quantity += current.quantity
            acc[partId].amount += current.amount
          }
          return acc
        }, {}),
      )
    }

    let merged_parts = items.data
    if (items.data.length > 0) {
      merged_parts = mergedParts(items.data)
      // console.log('merged_parts ->> ', merged_parts)
    }

    // Массивуудыг нэгтгэх
    const mergedTransactions = parts_items_all.map((mainItem) => {
      const matchedItem = merged_parts.find(
        (someItem) => someItem.part.id === mainItem.part.id,
      )
      return {
        ...mainItem,
        quantity: matchedItem ? matchedItem.quantity : 0,
      }
    })

    // console.log('mergedTransactions.data ->> ', mergedTransactions)
    // rowData.value = merged_parts
    rowData.value = mergedTransactions
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
  rowSelection: 'multiple',
})
const getRowNodeId = (data) => {
  return data.id
}

const asyncUpdateRow = async (data) => {
  console.log('Update data : ', data)
  if (data && data.id) {
    const updateData = {
      collection: 'Asset_Parts',
      id: data.id,
      item: {
        name: data.name,
        price: data.price,
        amount: data.amount,
        //  logo: values.company.logo,
        quantity: data.quantity,
        part: data.part?.id,
        location: params.id,
        max_quantity: data.max_quantity,
        min_quantity: data.min_quantity,
      },
    }
    updateItem(updateData)
  }
}

const asyncInsertRow = async (data) => {
  const insertData = data
  insertData.location = params.id
  insertData.part = getDefaultRow()?.id
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
  const defaultRow = {
    'part.name': getDefaultRow()?.name,
    'location.id': params.id,
    quantity: 0.0,
    min_quantity: 0.0,
    max_quantity: 0.0,
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
      collection: 'Asset_Parts',
      items: ids,
    })
  }
}

onMounted(async () => {
  await loadItems(1, -1)
  // await loadParts(1, -1)
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
      <!-- Header -->
      <!-- <div class="col-span-12">
        <BaseButton class="mr-4" @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts delete') }}</span>
        </BaseButton>

        <BaseButton class="mr-4" @click="addEmptyRow">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts add') }}</span>
        </BaseButton>
      </div> -->

      <!-- GridBody -->
      <div class="col-span-12 GridBody">
        <TairoContentWrapper>
          <template #left>
            <BaseInput
              icon="lucide:search"
              placeholder="Search"
              :classes="{
                wrapper: 'w-[340px]',
              }"
            />
          </template>
        </TairoContentWrapper>
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
