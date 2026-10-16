<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import PicCellRenderer from '~/components/ag_grid/PictureCellRenderer.vue'

import { AgGridVue } from 'ag-grid-vue3'
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
const { updateItem, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const { token } = useDirectusToken()
const runtimeConfig = useRuntimeConfig()
const { open } = usePanels()
const quickFilterText = ref('')

definePageMeta({
  middleware: ['auth'],
  title: 'Warehouse',
  showback: true,
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
    onCellClicked: (params) => {
      if (!params.value) return
      // Утгыг clipboard руу хуулна
      navigator.clipboard
        .writeText(params.value)
        .then(() => {
          console.log('Copied:', params.value)
        })
        .catch((err) => console.error('Failed to copy:', err))
    },
    onCellClicked: (params) => {
      onRowClicked(params)
    },
  },
  {
    headerName: t('Description'),
    field: 'part.description',
    sortable: true,
    filter: true,
    editable: false,
    minWidth: 220,
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
    headerName: t('Asset'),
    field: 'asset_amount',
    sortable: true,
    filter: false,
    editable: false, // Disabled editing since this is aggregated data
    maxWidth: 140,
    cellClass: 'asset_amount counts',
    cellStyle: {
      color: '#5f5b5b',
    },
  },
  {
    headerName: t('Income'),
    field: 'income_amount',
    sortable: true,
    filter: true,
    editable: false,
    maxWidth: 140,
    cellClass: 'income_amount counts',
    cellStyle: {
      color: '#54b5a6',
    },
  },
  {
    headerName: t('Outcome'),
    field: 'outcome_amount',
    sortable: true,
    filter: true,
    editable: false,
    maxWidth: 140,
    cellClass: 'outcome_amount counts',
    cellStyle: {
      color: '#e24f62',
    },
  },
  {
    headerName: t('Stock'),
    valueGetter: (params) => {
      const income = params.data?.income_amount || 0
      const outcome = params.data?.outcome_amount || 0
      return income - outcome // Example: You can return any computed value
    },
    sortable: true,
    filter: true,
    editable: false,
    cellClass: 'stock_amount counts',
    cellStyle: {
      color: '#51aacf',
    },
  },
  {
    field: 'picture',
    headerName: t('Picture'),
    headerClass: 'header-picture',
    cellRenderer: PicCellRenderer,
    cellRendererParams: (params) => {
      // console.log('cellRendererParams', params)
    },
    // maxWidth: 150,
    width: 150,
    hide: true,
  },
  {
    field: 'part.mongolian_name',
    headerName: t('Mongolian Name'),
    headerClass: 'header-name-mn',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'part.model_no',
    headerName: t('Model No'),
    headerClass: 'header-model',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'part.serial_no',
    headerName: t('Serial No'),
    headerClass: 'header-serial',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'part.material',
    headerName: t('Material'),
    headerClass: 'header-material',
    minWidth: 150,
    hide: true,
  },
  {
    field: 'part.technical_data',
    headerName: t('Technical Data'),
    headerClass: 'header-technical',
    minWidth: 200,
    hide: true,
  },
  {
    field: 'part.special_information',
    headerName: t('Special Info'),
    headerClass: 'header-special',
    minWidth: 200,
    hide: true,
  },
  {
    field: 'user_created.first_name',
    headerName: t('Created by'),
    headerClass: 'header-user',
    minWidth: 120,
    hide: true,
  },
  {
    field: 'date_created',
    headerName: t('Created date'),
    headerClass: 'header-date',
    minWidth: 120,
    hide: true,
  },
  // {
  //   field: 'segment.description',
  //   headerName: 'Segment',
  //   headerClass: 'header-segment',
  //   minWidth: 120,
  // },
  // {
  //   field: 'family.description',
  //   headerName: 'Family',
  //   headerClass: 'header-family',
  //   minWidth: 120,
  // },
  // {
  //   field: 'class.description',
  //   headerName: 'Class',
  //   headerClass: 'header-class',
  //   minWidth: 100,
  // },
  // {
  //   field: 'commodity.description',
  //   headerName: 'Commodity',
  //   headerClass: 'header-commodity',
  //   minWidth: 120,
  // },
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
    const filters = {
      // location: params.id,
      company_id: myCompanyId,
    }
    const items = await getItems<any>({
      collection: 'Parts_Amounts',
      params: {
        filter: filters,
        limit: -1, // Get all items to aggregate
        page: page,
        search: quickFilterText.value,
        searchField: 'part.part_number',
        meta: 'filter_count',
        fields: ['*', 'part.*', 'part.picture.*', 'location.*'],
      },
    })

    // Aggregate parts across all locations
    const aggregatedParts = {}

    items.data.forEach((item) => {
      const partId = item.part?.id
      if (!partId) return

      if (!aggregatedParts[partId]) {
        // First occurrence of this part
        aggregatedParts[partId] = {
          ...item,
          asset_amount: 0,
          income_amount: 0,
          outcome_amount: 0,
          locations: [],
        }
      }

      // asset_amount/income_amount/outcome_amount-ыг доор live тооцоод дарж
      // бичнэ тул энд Parts_Amounts-ийн cache утгыг нэмэхгүй.

      // Track locations (optional - for reference)
      if (item.location) {
        aggregatedParts[partId].locations.push(item.location)
      }
    })

    // Convert aggregated object to array
    rowData.value = Object.values(aggregatedParts)
    console.log('rowData (aggregated)', rowData)

    // asset_amount/income_amount/outcome_amount цаашид Parts_Amounts дээр
    // cache хийгддэггүй — компанийн бүх байршлаар нэгтгэн Asset_Parts болон
    // батлагдсан (status=2) Transaction_parts-аас шууд live тооцно.
    try {
      const partIds = rowData.value.map((r: any) => r.part?.id).filter(Boolean)
      if (partIds.length) {
        const [assetRes, tpRes] = await Promise.all([
          getItems<any>({
            collection: 'Asset_Parts',
            params: {
              filter: {
                company_id: { _eq: myCompanyId },
                part: { _in: partIds },
              },
              fields: ['part', 'quantity'],
              limit: -1,
            },
          }),
          getItems<any>({
            collection: 'Transaction_parts',
            params: {
              filter: {
                company_id: { _eq: myCompanyId },
                part: { _in: partIds },
                transaction_id: { status: { _eq: 2 } },
              },
              fields: ['part', 'qty', 'transaction_type'],
              limit: -1,
            },
          }),
        ])

        const assetList = Array.isArray(assetRes)
          ? assetRes
          : assetRes?.data ?? []
        const assetMap: Record<number, number> = {}
        for (const ap of assetList) {
          const pid = typeof ap.part === 'object' ? ap.part?.id : ap.part
          assetMap[pid] = (assetMap[pid] ?? 0) + (parseInt(ap.quantity) || 0)
        }

        const tpList = Array.isArray(tpRes) ? tpRes : tpRes?.data ?? []
        const incomeMap: Record<number, number> = {}
        const outcomeMap: Record<number, number> = {}
        for (const tp of tpList) {
          const pid = typeof tp.part === 'object' ? tp.part?.id : tp.part
          const qty = parseInt(tp.qty) || 0
          const isIncome =
            tp.transaction_type === 'income' || tp.transaction_type === 'INCOME'
          if (isIncome) incomeMap[pid] = (incomeMap[pid] ?? 0) + qty
          else outcomeMap[pid] = (outcomeMap[pid] ?? 0) + qty
        }

        rowData.value = rowData.value.map((r: any) => ({
          ...r,
          asset_amount: assetMap[r.part?.id] ?? 0,
          income_amount: incomeMap[r.part?.id] ?? 0,
          outcome_amount: outcomeMap[r.part?.id] ?? 0,
        }))
      }
    } catch (e) {
      console.warn('Failed to load live amounts:', e)
    }

    loading.value = false
  } catch (e) {
    console.error('Error loading items:', e)
    loading.value = false
  }
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
  gridOptions.api = grid_params.api
  const savedState = localStorage.getItem('wareHouseColumnState')
  if (savedState) {
    const state = JSON.parse(savedState)
    grid_params.api.applyColumnState({ state: state, applyOrder: true })
  } else {
    // Хэрэглэгч хараахан баганын өргөнийг өөрчлөөгүй анхны удаад л
    // дэлгэц дүүргэж тохируулна — эс тэгвэл хадгалсан өргөнийг дарж бичнэ
    grid_params.api.sizeColumnsToFit()
  }

  // const datasource = createServerSideDatasource()
  // await gridApi.value.setGridOption('serverSideDatasource', datasource)
}

const saveColumnState = (params: any) => {
  console.log(params)
  const columnState = params.api.getColumnState()
  localStorage.setItem('wareHouseColumnState', JSON.stringify(columnState))
}

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
        location: params.id ? params.id : null,
        max_quantity: data.max_quantity,
        min_quantity: data.min_quantity,
      },
    }
    updateItem(updateData)
  }
}

const asyncUpdateCount = async (data) => {
  console.log('Update data : ', data)
  if (data && data.id) {
    const updateData = {
      collection: 'Parts_Amounts',
      id: data.id,
      item: {
        asset_amount: data.asset_amount,
      },
    }
    updateItem(updateData)
  }
}

const asyncInsertRow = async (data) => {
  const insertData = data
  insertData.location = params.id ? params.id : null
  insertData.part = getDefaultRow()?.id
  insertData.company_id = myCompanyId
  createItems({
    collection: 'Asset_Parts',
    items: [insertData],
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
    'location.id': params.id ? params.id : null,
    quantity: 0.0,
    min_quantity: 0.0,
    max_quantity: 0.0,
    price: getDefaultRow()?.price,
    amount: 0.0,
  } // Customize the default values
  try {
    // Asset_Parts create
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

  // Add resize listener to fit columns on window resize
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  // Cleanup resize listener
  window.removeEventListener('resize', handleResize)
})

const handleResize = () => {
  // Хэрэглэгч аль хэдийн баганын өргөнийг гараар тохируулсан бол цонхны
  // хэмжээ өөрчлөгдөх бүрд түүнийг дахин дарж бичихгүй
  const savedState = localStorage.getItem('wareHouseColumnState')
  if (gridApi.value && !savedState) {
    gridApi.value.sizeColumnsToFit()
  }
}

const getDefaultRow = () => {
  return parts_codes.value
    ? parts_codes.value[0]
    : { id: null, name: '', price: 0, amount: 0 }
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const onFilterTextBoxChanged = ({
  target: { value },
}: ChangeEvent<HTMLInputElement>) => {
  quickFilterText.value = value
  refreshGrid()
}

const refreshGrid = () => {
  gridApi.value.refreshServerSide()
  gridApi.value.onFilterChanged()
  gridApi.value.refreshInfiniteCache()
}

const onRowClicked = (params) => {
  open('transaction', {
    id: params.data.part.id,
    data: params.data.part,
    module: 'parts',
    type: 'total',
    // refresh: refreshGrid(),
  })
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12 h-[2.5rem]">
        <!-- <BaseButton class="mr-4" @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts delete') }}</span>
        </BaseButton> -->

        <!-- <BaseButton class="mr-4" @click="addEmptyRow">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Parts add') }}</span>
        </BaseButton> -->
      </div>

      <!-- GridBody -->
      <div class="col-span-12 GridBody">
        <TairoContentWrapper>
          <template #left>
            <BaseInput
              icon="lucide:search"
              :placeholder="$t('Part number')"
              :classes="{
                wrapper: 'w-[340px]',
              }"
              @input="onFilterTextBoxChanged"
            />
          </template>
        </TairoContentWrapper>
        <ag-grid-vue
          :key="key"
          style="width: 100%; height: 560px"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list pars_section`"
          :columnDefs="columnDefs"
          :gridOptions="gridOptions"
          @grid-ready="onGridReady"
          :quickFilterText="quickFilterText"
          :rowData="rowData"
          :onColumnMoved="saveColumnState"
          :onColumnPinned="saveColumnState"
          :onColumnVisible="saveColumnState"
          :onColumnResized="saveColumnState"
        >
        </ag-grid-vue>
      </div>
    </div>
  </div>
</template>

<style>
.pars_section .counts {
  font-weight: 500;
}
</style>
