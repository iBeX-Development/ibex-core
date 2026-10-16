<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { fetchPageData } from '~/components/ag_grid/ag_grid_directus'
import StatusCellRenderer from '~/components/ag_grid/statusCellRenderer.vue'

const { t } = useI18n({ useScope: 'global' })
const { open } = usePanels()
const { getItems, updateItem, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

import { useRouter } from 'vue-router'
const router = useRouter()
const { params } = useRoute()

const myId = window.localStorage.getItem('myId')
const runtimeConfig = useRuntimeConfig()
const locationId = Number(params.id)
console.log('params->', locationId)

// Modal start
import type { ColDef } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import ActionDropdownCellRenderer from '~/components/ag_grid/ActionDropdownCellRenderer.vue'
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import DeletionModalForm from '~/components/form/DeletionModalForm.vue'
import IncomeModalForm from '~/components/transaction/IncomeModalForm.vue'
definePageMeta({
  middleware: ['auth'],
  title: 'Income',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})

const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const isModalApproveConfirmOpen = ref(false)

const selectedItem = ref(-1)
const itemsValue = ref(-1)
const selectedRow = ref(-1)
const editPartRow = ref(-1)
const actionType = ref(null)

const key = ref(1)
const key_update_modal = ref(2)
const last_row = ref(null)

const toaster = useToaster()

const isModalUserListOpen = ref(false)
const currentRecord = ref(null)
const locations = ref(null)

const statuses = [
  {
    text: 'Active',
    value: 1,
    color: '#4CAF50',
  },
  {
    text: 'Approved',
    value: 2,
    color: '#0F87BC',
  },
  {
    text: 'Returned',
    value: 3,
    color: '#FF9800',
  },
]

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

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalApproveConfirmOpen.value = false
}

const do_edit = async (editItem) => {
  // Perform your action here
  selectedItem.value = editItem.id
  selectedRow.value = editItem
  actionType.value = 'do_edit'

  const items = await getItems({
    collection: 'Transaction_parts',
    params: {
      filter: { transaction_id: editItem.id },
      meta: 'filter_count',
      fields: ['*', 'part.*'],
    },
  })

  // console.log('do_edit')

  editPartRow.value = items.data?.map((item) => {
    return {
      choose_part: {
        id: item.part?.id,
        name: { description: item.part?.name || '' },
        part_number: {
          description: item.part?.description || '',
          id: item.part?.id || '',
          part_number: item.part?.part_number || '',
        },
      },
      description: item.part?.description || '',
      price: Number(item.price) || 0,
      qty: item.qty || 0,
      old_qty: item.qty || 0,
    }
  })

  isModalOpen.value = true
}

const do_approve = (item) => {
  actionType.value = 'do_approve'

  isModalApproveConfirmOpen.value = true
  itemsValue.value = item
  selectedItem.value = item.id
}

const do_return = async (item) => {
  actionType.value = 'do_return'

  const items = await getItems({
    collection: 'Transaction_parts',
    params: {
      filter: { transaction_id: item.id },
      meta: 'filter_count',
      fields: ['*', 'part.*'],
    },
  })

  if (items.data.length > 0) {
    const do_returned = await createItems({
      collection: 'Transaction_assign',
      items: {
        transaction_id: item.id,
        first_user: myId,
        status: 3,
        company_id: myCompanyId,
      },
    })
  }

  const data = {
    collection: 'Transaction',
    id: item.id,
    item: { status: 3 },
  }

  await updateItem(data)
  refreshGrid()
}

const do_assign = (item) => {
  actionType.value = 'do_assign'

  isModalUserListOpen.value = true
  currentRecord.value = item
}

const handleModalUserListClose = () => {
  isModalUserListOpen.value = false
}

const setUser = async (user) => {
  if (currentRecord.value) {
    const assign = await createItems({
      collection: 'Transaction_assign',
      items: {
        transaction_id: currentRecord.value.id,
        first_user: myId,
        next_user: user.id,
        status: currentRecord.value.status,
        company_id: myCompanyId,
      },
    })

    const data = {
      collection: 'Transaction',
      id: currentRecord.value.id,
      item: {
        assign_user: user.id,
      },
    }
    await updateItem(data)

    isModalUserListOpen.value = false
    handleChangeKey()
    refreshGrid()

    toaster.show({
      title: t('Update'),
      message: t(`Record updated successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }
}

// Parts_Amounts.income_amount cache байхгүй боллоо — асаж хадгалдаг байсан
// updateStock()-ыг устгав. income_amount одоо parts/location жагсаалт болон
// warehouse дээр Transaction_parts-аас шууд live тооцогддог тул энд синк
// хийх шаардлагагүй.

// Work_order_Parts counter
const wo_parts_counter = async (parts, location_id, type) => {
  console.log('innncome_wocounter', parts)

  const { token } = useDirectusToken()
  const url = runtimeConfig.public.directus.url + `items/Work_order_Parts`

  // бүх parts-ийг зэрэг update хийх
  const updates = parts.map(async (item) => {
    let price = item.price ? parseInt(item.price) : 0
    let qty = item.qty ? parseInt(item.qty) : 0
    let wo_part_id = 0
    let actual_price = 0
    let actual_quantity = 0

    let filters = {
      parts: item.part,
    }

    const wo_parts = await getItems({
      collection: 'Work_order_Parts',
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    console.log('wo_parts', wo_parts)
    if (wo_parts.data.length) {
      console.log('updatedQty', wo_parts)
      wo_part_id = wo_parts.data[0].id
      actual_quantity = wo_parts.data[0].actual_quantity
      actual_price = wo_parts.data[0].actual_price

      if (type == 'approve') {
        actual_quantity = actual_quantity + qty
        actual_price = actual_price + price
      }

      if (type == 'return') {
        actual_quantity = actual_quantity - qty
        actual_price = actual_price - price
      }

      // const response = await fetch(`${url}/${wo_part_id}`, {
      //   method: 'PATCH',
      //   headers: {
      //     'Content-Type': 'application/json',
      //     Authorization: `Bearer ${token.value}`,
      //   },
      //   body: JSON.stringify({
      //     actual_quantity: actual_quantity,
      //     actual_price: actual_price,
      //   }),
      // })
      // if (!response.ok) {
      //   throw new Error(`Update failed: ${response.statusText}`)
      // }
      return { id: wo_part_id, status: 'updated', actual_price: qty }
    }
  })

  // const results = await Promise.all(updates)
  // console.log('income qty updated', results)
  // return results
}

const do_make = async (item, type) => {
  let statuss = 1

  if (type == 'do_delete') {
    statuss = 0

    const items = await getItems({
      collection: 'Transaction_parts',
      params: {
        filter: { transaction_id: item.id },
        meta: 'filter_count',
        fields: ['*', 'part.*'],
      },
    })

    if (items.data.length > 0) {
    }
  } else if (type == 'do_approve') {
    statuss = 2
    // console.log('do_approve', item)

    const items = await getItems({
      collection: 'Transaction_parts',
      params: {
        filter: { transaction_id: item.id },
        meta: 'filter_count',
        fields: ['*', 'part.*'],
      },
    })

    if (items.data.length > 0) {
      const do_approved = await createItems({
        collection: 'Transaction_assign',
        items: {
          transaction_id: item.id,
          first_user: myId,
          status: statuss,
          company_id: myCompanyId,
        },
      })

      // wo_parts_counter(newParts, item.location.id, 'approve')
    }
  } else if (type == 'do_return') {
    statuss = 3

    // return
    const items = await getItems({
      collection: 'Transaction_parts',
      params: {
        filter: { transaction_id: item.id },
        meta: 'filter_count',
        fields: ['*', 'part.*'],
      },
    })

    if (items.data.length > 0) {
      const do_returned = await createItems({
        collection: 'Transaction_assign',
        items: {
          transaction_id: item.id,
          first_user: myId,
          status: statuss,
          company_id: myCompanyId,
        },
      })
      // wo_parts_counter(newParts, item.location.id, 'return')
    }
  }
  // else if (type == 'do_assign') statuss = 4
  const data = {
    collection: 'Transaction',
    id: item.id,
    item: {
      status: statuss,
      ...(statuss === 2 ? { approved_user: myId } : {}),
    },
  }
  await updateItem(data)
  refreshGrid()
}

const do_delete = (item) => {
  actionType.value = 'do_delete'
  itemsValue.value = item

  isModalConfirmOpen.value = true
  selectedItem.value = item.id
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const clearItem = () => {
  selectedItem.value = -1
}
// Modal end

// Grid functions

const gridApi = ref(null) // For storing ag-Grid API instance
const totalRows = ref(0) // Total rows from the backend
const paginationPageSize = ref(25) // Default page size
const rowModelType = ref('serverSide')
const dataSource = ref({})
const quickFilterText = ref('')
const defaultColDef = {
  resizable: false,
}

const onGridReady = (params) => {
  // Grid api
  gridApi.value = params.api
  gridOptions.api = params.api

  const savedState = localStorage.getItem('incomes')
  if (savedState) {
    const state = JSON.parse(savedState)
    params.api.applyColumnState({ state: state, applyOrder: true })
  }

  dataSource.value = {
    getRows: async (params) => {
      const { startRow, endRow, sortModel } = params.request
      const filterModels = gridApi.value.getFilterModel()
      let filters = {
        transaction_type: 'INCOME',
        status: {
          _in: [1, 2, 3, 4],
        },
        location: locationId ? locationId : undefined,
      }

      if (filterModels.transaction_date) {
        const transactionDate = filterModels.transaction_date
        if (transactionDate.dateFrom || transactionDate.dateTo) {
          if (transactionDate.type === 'inRange') {
            filters['transaction_date'] = {
              _between: [transactionDate.dateFrom, transactionDate.dateTo],
            }
          } else if (transactionDate.type === 'equals') {
            filters['transaction_date'] = {
              _in: [transactionDate.dateFrom],
            }
          } else if (transactionDate.type === 'lessThan') {
            filters['transaction_date'] = {
              _lte: transactionDate.dateFrom,
            }
          } else if (transactionDate.type === 'greaterThan') {
            filters['transaction_date'] = {
              _gte: transactionDate.dateFrom,
            }
          } else if (transactionDate.type === 'notEqual') {
            filters['transaction_date'] = {
              _neq: transactionDate.dateFrom,
            }
          }
        }
        // 3. Хэрэв формат танигдахгүй бол
        else {
          console.log('Unknown transaction_date format', transactionDate)
        }
      }

      if (filterModels?.status?.values) {
        filters['status'] = {
          _in: filterModels?.status?.values,
        }
      }

      if (filterModels?.['location.name']?.values) {
        filters['location'] = {
          _in: filterModels['location.name'].values,
        }
      }

      if (quickFilterText.value) {
        let searchFilter = {
          transaction_type: 'income',
          part: { part_number: { _contains: quickFilterText.value } },
        }

        const search_items = await getItems({
          collection: 'Transaction_parts',
          params: {
            filter: searchFilter,
            meta: 'filter_count',
            fields: ['*', 'part.*'],
          },
        })

        let ids = []
        if (search_items.data.length) {
          ids = search_items.data.map((item) => item.transaction_id)
        }
        if (ids.length) {
          filters['id'] = { _in: ids }
        } else filters['id'] = { _in: -1 }
      }

      const sortField = sortModel.length ? sortModel[0].colId : null
      const sortOrder = sortModel.length ? sortModel[0].sort : null

      fetchPageData({
        currentPage: startRow / paginationPageSize.value + 1,
        pageSize: paginationPageSize.value,
        sortField: sortField,
        sortOrder: sortOrder,
        filters: filters,
        // search: quickFilterText.value,
        // searchField: 'name',
        collection: 'Transaction',
        fields: [
          '*',
          'supplier.*',
          'location.*',
          'user_created.*',
          'assign_user.*',
          'date_created.*',
        ],
      })
        .then((response) => {
          // console.log('response', response)
          const rowsThisPage = response.data
          const lastRow = response.totalCount

          params.success({
            rowData: rowsThisPage,
            rowCount: lastRow,
          })
        })
        .catch((error) => {
          console.error('Error fetching page data:', error)
          params.fail()
        })
    },
  }

  // Set the server-side datasource
  params.api.setGridOption('serverSideDatasource', dataSource.value)

  // Хэрэглэгч хараахан баганын өргөнийг өөрчлөөгүй анхны удаад л дэлгэц
  // дүүргэж тохируулна — эс тэгвэл хадгалсан өргөнийг дарж бичнэ
  if (!savedState) {
    params.api.sizeColumnsToFit()
  }
}

const gridOptions = {
  rowModelType: 'serverSide', // Important for server-side pagination
  paginationPageSize: 25, // Start with 25 rows per page
  cacheBlockSize: 25, // Set fetch size to 25 rows per block
  pagination: true,
  paginationPageSizeSelector: false,
  serverSideDatasource: dataSource.value,
  animateRows: false,
  onGridSizeChanged: (params) => {
    if (!localStorage.getItem('incomes')) {
      params.api.sizeColumnsToFit()
    }
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

const actionFormatter = ({ value }) => {
  console.log('actionFormatter', value)
}

const dayFormatter = ({ value }) => {
  const localTime = new Date(value)
  const formattedTime =
    `${localTime.getFullYear()}/` +
    `${String(localTime.getMonth() + 1).padStart(2, '0')}/` +
    `${String(localTime.getDate()).padStart(2, '0')}`

  return formattedTime
}

const onRowClicked = (params) => {
  console.log('onRowClicked')
  open('transaction', {
    id: params.data.id,
    data: params.data,
    module: 'income',
    // refresh: refreshGrid(),
  })
}

const onClickedLocation = (params) => {
  router.push(`/parts/location/${params.data.location?.id}`)
}

const statusFormatter: ValueFormatterFunc = ({ value }) => {
  if (value === 1) return 'active'
  else if (value === 2) return 'approved'
  else if (value === 3) return 'returned'
}

const filterDateParams = {
  comparator: (filterLocalDateAtMidnight: Date, cellValue: string) => {
    const dateAsString = cellValue
    if (dateAsString == null) return -1
    const dateParts = dateAsString.split('/')
    const cellDate = new Date(
      Number(dateParts[2]),
      Number(dateParts[1]) - 1,
      Number(dateParts[0]),
    )

    if (filterLocalDateAtMidnight.getTime() === cellDate.getTime()) {
      return 0
    }

    if (cellDate < filterLocalDateAtMidnight) {
      return -1
    }

    if (cellDate > filterLocalDateAtMidnight) {
      return 1
    }
    return 0
  },
  minValidYear: 2000,
  maxValidYear: 2050,
  buttons: ['reset', 'apply'],
  maxNumConditions: 1,
  // closeOnApply: true,
  inRangeFloatingFilterDateFormat: 'Do MMM YYYY',
}

const columnDefs: ColDef[] = ref([
  {
    field: 'auto_number',
    headerName: t('Number'),
    headerClass: 'header-code',
    // flex: 1,
    width: 120,
    resizable: true,
    pinned: 'left',
    onCellClicked: (params) => {
      onRowClicked(params)
    },
    cellStyle: { cursor: 'pointer' },
  },
  {
    field: 'name',
    headerName: t('Name'),
    headerClass: 'header-name',
    // maxWidth: 160,
    resizable: true,
    onCellClicked: (params) => {
      onRowClicked(params)
    },
    cellStyle: { cursor: 'pointer' },
  },
  {
    field: 'status',
    headerName: t('Status'),
    headerClass: 'header-status',
    // maxWidth: 120,
    resizable: true,
    valueFormatter: statusFormatter,
    cellRenderer: StatusCellRenderer,
    sortable: false,
    cellStyle: { margin: '5px 0px 0px -10px' },
    cellClassRules: {
      'status-approved': ({ value }) => value === 2,
    },
    cellClass: 'status-cell',
    filter: 'agSetColumnFilter', // Enable set filter
    filterParams: {
      values: (params) => {
        // console.log('params.value -> ', params)

        const filter_statuses = statuses.map((status) => status.value)
        params.success(filter_statuses)
      }, // Provide numeric values for the filter
      valueFormatter: (params) => {
        const status = statuses.find((s) => s.value === params.value)
        return status ? status.text : params.value // Map numeric value to text
      },
      suppressRemoveAll: true, // Disable "Remove All" button
      checkbox: true, // Enable checkboxes in the filter
    },
  },
  {
    field: 'supplier.name',
    headerName: t('Supplier'),
    headerClass: 'header-supplier',
    // maxWidth: 150,
    resizable: true,
  },

  {
    field: 'location.name',
    headerName: t('Location'),
    headerClass: 'header-location',
    // maxWidth: 160,
    resizable: true,
    cellClass: 'locations-name',
    cellStyle: { cursor: 'pointer', margin: '11px 0px 0px -14px' },
    filter: 'agSetColumnFilter', // Enable set filter
    onCellClicked: (params) => {
      onClickedLocation(params)
    },
    filterParams: {
      values: (params) => {
        // console.log('params.value -> ', params)
        // console.log('locations.value -> ', locations)
        const filter_statuses = locations.value.map((item) => item.id)
        params.success(filter_statuses)
      },
      valueFormatter: (params) => {
        // console.log('valueFormatter.value -> ', params)
        const status = locations.value.find((s) => s.id === params.value)
        return status ? status.name : params.value // Map numeric value to text
      },
      suppressRemoveAll: true, // Disable "Remove All" button
      checkbox: true, // Enable checkboxes in the filter
    },
  },
  {
    field: 'assign_user.first_name',
    headerName: t('Assign to'),
    headerClass: 'header-assign',
    // maxWidth: 150,
    resizable: true,
  },
  {
    field: 'transaction_date',
    headerName: t('Date'),
    headerClass: 'header-transaction-date',
    maxWidth: 140,
    valueFormatter: dayFormatter,
    // cellStyle: { fontSize: '11px' },
    filter: 'agDateColumnFilter',
    filterParams: filterDateParams,
    resizable: true,
  },
  {
    field: 'date_created',
    headerName: t('Created'),
    headerClass: 'header-date',
    maxWidth: 140,
    valueFormatter: dateFormatter,
    resizable: true,

    // cellStyle: { fontSize: '11px' },
  },
  {
    field: 'actions',
    headerName: t('Actions'),
    maxWidth: 108,
    sortable: false,
    filter: false,
    cellEditorPopup: true,
    cellRenderer: ActionDropdownCellRenderer,
    // cellRenderer: (params) => {
    //   console.log('paramsparams', params)

    //   if (params.data.status === 2) {
    //     return
    //   }
    //   return ActionDropdownCellRenderer
    // },
    cellRendererParams: (params) => {
      if (params.data.status === 2) {
        return {
          onReturnClick: do_return,
          onEditClick: false,
          onDeleteClick: false,
        }
      }
      if (params.data.status === 1 || params.data.status === 3) {
        //is_admin
        return {
          onEditClick: do_edit,
          onDeleteClick: do_delete,
          onApproveClick: do_approve,
          onAssignClick: do_assign,
        }
      }
    },
    cellClass: 'actions-cell',
    cellStyle: {
      // 'background-color': 'green',
    },
  },
])

const onFilterTextBoxChanged = ({ target: { value } }) => {
  quickFilterText.value = value
  refreshGrid()
}

const saveColumnState = (params: any) => {
  // console.log(params)
  const columnState = params.api.getColumnState()
  localStorage.setItem('incomes', JSON.stringify(columnState))
}

const refreshGrid = () => {
  gridApi.value.refreshServerSide()
  gridApi.value.onFilterChanged()
  gridApi.value.refreshInfiniteCache()
  if (last_row.value)
    last_row.value.auto_number = Number(last_row.value.auto_number) + 1
}

onMounted(async () => {
  const locationRes = await getItems({
    collection: 'Location',
    params: {
      filter: { status: '1' },
      meta: 'filter_count',
      fields: ['*'],
    },
  })

  locations.value = locationRes.data

  fetchPageData({
    pageSize: 1,
    sortField: 'id',
    sortOrder: 'desc',
    filters: {
      transaction_type: 'INCOME',
      status: {
        _in: [1, 2, 3],
      },
      location: locationId ? locationId : undefined,
    },
    collection: 'Transaction',
    fields: ['*'],
  })
    .then((response) => {
      last_row.value = response?.data[0]
    })
    .catch((error) => {
      console.error('Error response_last_one page data:', error)
    })
})
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="incom_order_list grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="left" @click="handleModalOpen">
          <Icon
            name="material-symbols-light:input-circle-rounded"
            class="-ms-1 h-4 w-4"
          />
          <span class="text-[11px]">{{ $t('Income add') }}</span>
        </BaseButton>
      </div>
      <!-- Grid -->

      <div
        class="grid_ag col-span-12 GridBody"
        :class="`ag-theme-quartz${$colorMode.value === 'light' ? '' : '-dark'}`"
      >
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
          style="width: 100%; height: 560px"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list`"
          @grid-ready="onGridReady"
          :onColumnMoved="saveColumnState"
          :onColumnPinned="saveColumnState"
          :onColumnVisible="saveColumnState"
          :onColumnResized="saveColumnState"
          :gridOptions="gridOptions"
          :columnDefs="columnDefs"
          :defaultColDef="defaultColDef"
          :quickFilterText="quickFilterText"
        >
        </ag-grid-vue>
        <IncomeModalForm
          :key="selectedItem"
          :location="locationId"
          :row="selectedItem"
          :editPartRow="editPartRow"
          :item="selectedRow"
          :last="last_row"
          title="Income"
          module="Income"
          code="Transaction"
          :open="isModalOpen"
          :close="handleModalClose"
          :refresh="refreshGrid"
          size="3xl"
        />
        <DeletionModalForm
          :key="selectedItem"
          :itemsValue="itemsValue"
          code="Transaction"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :do_make="do_make"
          :actionType="actionType"
          :row="selectedItem"
          :refresh="refreshGrid"
          :clear="clearItem"
        />
        <ConfirmModalForm
          :itemsValue="itemsValue"
          code="Transaction"
          text="Do you agree to this action?"
          :open="isModalApproveConfirmOpen"
          :close="handleModalConfirmClose"
          :do_make="do_make"
          :actionType="actionType"
          :row="selectedItem"
          :refresh="refreshGrid"
          :clear="clearItem"
        />
        <UserList
          :open="isModalUserListOpen"
          :close="handleModalUserListClose"
          :setUser="setUser"
        />
      </div>
    </div>
  </div>
</template>
<style>
.incom_order_list .grid_ag {
  min-height: 560px !important;
}
.incom_order_list .ag-center-cols-container {
  overflow: visible;
  display: flex;
  flex-direction: column;
}
.incom_order_list .ag-row .locations-name {
  line-height: 1.5;
  font-size: 13px;
  justify-content: center;
  align-items: center;
  /* font-weight: 500; */
  border: none !important;
}
.incom_order_list .ag-row .locations-name:hover {
  font-weight: 500;
}
.incom_order_list .ag-row {
  overflow: visible;
  position: relative;
  transform: none !important;
  /* width: inherit; */
}
.incom_order_list .ag-row .status-cell {
  border: none !important;
}
.incom_order_list .ag-row .actions-cell {
  overflow: visible;
}
/* .ag-row:has(> .status-approved) .actions-cell {
  display: none;
} */
</style>
