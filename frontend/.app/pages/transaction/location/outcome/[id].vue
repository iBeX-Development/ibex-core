<script setup lang="ts">
import { nextTick, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { fetchPageData } from '~/components/ag_grid/ag_grid_directus'
import StatusCellRenderer from '~/components/ag_grid/statusCellRenderer.vue'
import LocationCell from './locationCell.vue'
const runtimeConfig = useRuntimeConfig()

const router = useRouter()
const { t } = useI18n({ useScope: 'global' })
const { open } = usePanels()
const { getItems, updateItem, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const { params } = useRoute()

const myId = window.localStorage.getItem('myId')
const locations = ref(null)
const locationId = params.id
console.log('params->', locationId)

definePageMeta({
  middleware: ['auth'],
  title: 'Debt',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})

// Modal start
import type { ColDef } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import ActionDropdownCellRenderer from '~/components/ag_grid/ActionDropdownCellRenderer.vue'
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import DeletionModalForm from '~/components/form/DeletionModalForm.vue'
import OutcomeModalForm from '~/components/transaction/OutcomeModalForm.vue'

const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const isModalApproveConfirmOpen = ref(false)
const props = defineProps({
  status: Object,
  location: Number,
  work_order_type: Number,
  asset: Number,
  class: String,
})

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

const selectedItem = ref(-1)
const itemsValue = ref(-1)
const selectedRow = ref(-1)
const editPartRow = ref([])

const key = ref(1)
const key_update_modal = ref(2)
const last_row = ref(null)
const actionType = ref(null)

const toaster = useToaster()

const isModalUserListOpen = ref(false)
const currentRecord = ref(null)

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
  selectedRow.value = editItem

  const filters = {
    status: 1,
    work_order: editItem.work_order.id,
  }

  const wo_items = await getItems({
    collection: 'Work_order_Parts',
    params: {
      filter: filters,
      meta: 'filter_count',
      fields: ['*', 'parts.*', 'work_order.* '],
    },
  })

  console.log('wo_items:', wo_items)
  console.log('wo_items.data:', wo_items.data)

  const items = await getItems({
    collection: 'Transaction_parts',
    params: {
      filter: { transaction_id: editItem.id },
      meta: 'filter_count',
      fields: ['*', 'part.*', 'bin_location.id', 'bin_location.name'],
    },
  })

  console.log('items', items)
  if (items.data.length > 0) {
    editPartRow.value = items.data.map((item, index) => {
      let wo_qty = 0
      if (wo_items.data.length > 0) {
        const matchingWoPart = wo_items.data.find(
          (woPart) => item.part.id === woPart.parts.id,
        )
        wo_qty = matchingWoPart?.quantity || 0
        console.log(
          `Part ${item.part.part_number}: WO Qty = ${wo_qty}, Transaction quantity = ${item.quantity}, Transaction qty = ${item.qty}`,
        )
      }

      // Exclude 'quantity' from Transaction_parts to avoid conflict
      const { part, quantity, bin_location, ...rest } = item

      return {
        ...rest,
        quantity: wo_qty, // Use Work_order_Parts quantity for WO Qty
        parts: part,
        bin_location: bin_location?.id ?? null,
        bin_location_name: bin_location?.name ?? '',
        // Хадгалагдсан анхны qty — Out Qty талбар v-model-ээр item.qty-г
        // өөрчлөх тул submit хийхэд delta тооцоход энэ хөдлөшгүй хувилбарыг ашиглана.
        old_qty: item.qty || 0,
      }
    })

    // Tухайн bin дээр одоо байгаа боломжит үлдэгдэл (Out Qty-ийн max
    // validation-д ашиглана) — OutcomeModalForm-ийн шинэ бин сонголтын
    // урсгалтай ижил утга байх ёстой тул Parts_Bin_location-оос авна.
    const binPairs = editPartRow.value.filter(
      (row) => row.parts?.id && row.bin_location,
    )
    if (binPairs.length > 0) {
      const binQtyRes = await getItems({
        collection: 'Parts_Bin_location',
        params: {
          filter: {
            part: { _in: binPairs.map((row) => row.parts.id) },
            bin_location: { _in: binPairs.map((row) => row.bin_location) },
          },
          fields: ['part', 'bin_location', 'qty'],
          limit: -1,
        },
      })
      const binQtyList = Array.isArray(binQtyRes)
        ? binQtyRes
        : binQtyRes?.data ?? []
      const qtyMap: Record<string, number> = {}
      for (const b of binQtyList) {
        qtyMap[`${b.part}_${b.bin_location}`] = b.qty ?? 0
      }
      editPartRow.value.forEach((row) => {
        row.stock = qtyMap[`${row.parts?.id}_${row.bin_location}`] ?? 0
      })
    }

    console.log('Final editPartRow:', editPartRow.value)
  }

  // Set selectedItem AFTER editPartRow is ready (changes component key)
  selectedItem.value = editItem.id

  // Wait for Vue to update before opening modal
  await nextTick()
  isModalOpen.value = true
}

const do_approve = (item) => {
  isModalApproveConfirmOpen.value = true
  actionType.value = 'do_approve'
  itemsValue.value = item
  selectedItem.value = item.id

  console.log('do_approve_transacrion')
}

const do_return = async (item) => {
  actionType.value = 'do_return'
  // console.log('real_fn')

  const items = await getItems({
    collection: 'Transaction_parts',
    params: {
      filter: { transaction_id: item.id },
      meta: 'filter_count',
      fields: ['*', 'part.*'],
    },
  })

  if (items.data.length > 0) {
    //wrile_log_action
    const do_returned = await createItems({
      collection: 'Transaction_assign',
      items: {
        transaction_id: item.id,
        first_user: myId,
        status: 3,
        company_id: myCompanyId,
      },
    })

    const newParts = items.data.map((item) => ({
      trans_partId: item.id,
      part: item.part.id,
      part_state: item.part_state ?? null,
      wo_id: item.work_order,
      price: parseInt(item.price),
      qty: parseInt(item.qty),
    }))

    wo_parts_counter(newParts, item.location.id, 'return')
    await Promise.all(
      items.data
        .filter((tp) => tp.bin_location)
        .map((tp) =>
          adjustBinQty(
            tp.part.id,
            tp.bin_location,
            parseInt(tp.qty) || 0,
            tp.part_state,
          ),
        ),
    )
  }

  const data = {
    collection: 'Transaction',
    id: item.id,
    item: { status: 3 },
  }

  await updateItem(data)
  refreshGrid()
  console.log('do_returns_transacrion')
}

const do_assign = (item) => {
  console.log('do_assign')
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
    refreshGrid()
    handleChangeKey()
    toaster.show({
      title: t('Update'),
      message: t(`Record updated successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }
}

// Debt батлагдах/буцах үед тухайн bin-ийн Parts_Bin_location.qty-г бодит
// байдалтай нь тааруулна (батлахад хасна, буцаахад/устгахад сэргээнэ) —
// эс тэгвэл нэг bin-ээс бодит байгаагаас олон удаа зарлага гаргах боломжтой болно.
const adjustBinQty = async (partId, binLocationId, delta, partState = null) => {
  if (!partId || !binLocationId || !delta) return
  // Нэг (part, bin_location) хос дор State тус бүрээр (Шинэ/Хуучин г.м)
  // ХЭД ХЭДЭН тусдаа Parts_Bin_location мөр байж болдог тул зөвхөн
  // part+bin_location-оор шүүвэл буруу (өөр state-ийн) мөрийг олж, түүнийг
  // 0 хүртэл хасаад, жинхэнэ мөрийг нь огт хөндөхгүй байх эрсдэлтэй.
  // Тиймээс яг тухайн гүйлгээнд бичигдсэн part_state-тэй тохирох мөрийг л
  // (transaction_parts холбоосоор нь) олж тохируулна.
  const filter =
    partState != null
      ? {
          part: { _eq: partId },
          bin_location: { _eq: binLocationId },
          transaction_parts: { part_state: { _eq: partState } },
        }
      : {
          part: { _eq: partId },
          bin_location: { _eq: binLocationId },
          transaction_parts: { part_state: { _null: true } },
        }

  const res = await getItems({
    collection: 'Parts_Bin_location',
    params: {
      filter,
      fields: ['id', 'qty'],
      limit: 1,
    },
  })
  const list = Array.isArray(res) ? res : res?.data ?? []
  if (!list.length) return
  const current = parseInt(list[0].qty) || 0

  await updateItem({
    collection: 'Parts_Bin_location',
    id: list[0].id,
    item: { qty: Math.max(0, current + delta) },
  })
}

// Parts_Amounts.outcome_amount cache байхгүй боллоо — асаж хадгалдаг байсан
// updateStock()-ыг устгав. outcome_amount одоо parts/location жагсаалт болон
// warehouse дээр Transaction_parts-аас шууд live тооцогддог тул энд синк
// хийх шаардлагагүй.

// Work_order_Parts counter
const wo_parts_counter = async (parts, location_id, type) => {
  console.log('wocounter', parts)

  const { token } = useDirectusToken()
  const url = runtimeConfig.public.directus.url + `items/Work_order_Parts`

  // Aggregate by (part, part_state, wo_id) to avoid race conditions
  type WoKey = string
  const aggregated: Record<
    WoKey,
    { part: number; part_state: any; wo_id: any; price: number; qty: number }
  > = {}
  for (const item of parts) {
    const key = `${item.part}__${item.part_state ?? 'null'}__${item.wo_id}`
    if (!aggregated[key]) {
      aggregated[key] = {
        part: item.part,
        part_state: item.part_state ?? null,
        wo_id: item.wo_id,
        price: item.price ? parseInt(item.price) : 0,
        qty: 0,
      }
    }
    aggregated[key].qty += parseInt(item.qty) || 0
  }

  for (const item of Object.values(aggregated)) {
    const filters: any = {
      parts: item.part,
      work_order: item.wo_id,
    }
    if (item.part_state != null) {
      filters['part_state'] = { _eq: item.part_state }
    }

    const wo_parts = await getItems({
      collection: 'Work_order_Parts',
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    if (!wo_parts.data.length) continue

    const wo_part_id = wo_parts.data[0].id
    let actual_quantity = 0
    let actual_price = 0
    let actual_amount = 0

    if (type == 'approve') {
      actual_quantity = item.qty
      actual_price = item.price
      actual_amount = item.qty * item.price
    }
    // return: stays 0

    const response = await fetch(`${url}/${wo_part_id}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.value}`,
      },
      body: JSON.stringify({ actual_quantity, actual_price, actual_amount }),
    })
    if (!response.ok) {
      console.error(`wo_parts_counter update failed: ${response.statusText}`)
    }
  }
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
      await Promise.all(
        items.data
          .filter((tp) => tp.bin_location)
          .map((tp) =>
            adjustBinQty(
              tp.part.id,
              tp.bin_location,
              parseInt(tp.qty) || 0,
              tp.part_state,
            ),
          ),
      )
    }
  } else if (type == 'do_approve') {
    statuss = 2

    console.log('do_approved_item')
    const items = await getItems({
      collection: 'Transaction_parts',
      params: {
        filter: { transaction_id: item.id },
        meta: 'filter_count',
        fields: ['*', 'part.*'],
      },
    })

    if (items.data.length > 0) {
      //wrile_log_action
      const approved = await createItems({
        collection: 'Transaction_assign',
        items: {
          transaction_id: item.id,
          first_user: myId,
          status: statuss,
          company_id: myCompanyId,
        },
      })

      const newParts = items.data.map((tp) => ({
        part: tp.part.id,
        part_state: tp.part_state ?? null,
        trans_partId: tp.id,
        wo_id: tp.work_order,
        price: parseInt(tp.price),
        qty: parseInt(tp.qty),
      }))

      wo_parts_counter(newParts, item.location.id, 'approve')
      await Promise.all(
        items.data
          .filter((tp) => tp.bin_location)
          .map((tp) =>
            adjustBinQty(
              tp.part.id,
              tp.bin_location,
              -(parseInt(tp.qty) || 0),
              tp.part_state,
            ),
          ),
      )
    }
  } else if (type == 'do_return') {
    statuss = 3
    console.log('do_returned_item')
    const items = await getItems({
      collection: 'Transaction_parts',
      params: {
        filter: { transaction_id: item.id },
        meta: 'filter_count',
        fields: ['*', 'part.*'],
      },
    })

    if (items.data.length > 0) {
      //wrile_log_action
      const returned = await createItems({
        collection: 'Transaction_assign',
        items: {
          transaction_id: item.id,
          first_user: myId,
          status: statuss,
          company_id: myCompanyId,
        },
      })

      const newParts = items.data.map((item) => ({
        part: item.part.id,
        part_state: item.part_state ?? null,
        trans_partId: item.id,
        wo_id: item.work_order,
        price: parseInt(item.price),
        qty: parseInt(item.qty),
      }))

      wo_parts_counter(newParts, item.location.id, 'return')
      await Promise.all(
        items.data
          .filter((tp) => tp.bin_location)
          .map((tp) =>
            adjustBinQty(
              tp.part.id,
              tp.bin_location,
              parseInt(tp.qty) || 0,
              tp.part_state,
            ),
          ),
      )
    }
  }
  // else if (type == 'do_assign') statuss = 4

  // console.log('type', type, statuss)

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
  isModalConfirmOpen.value = true
  itemsValue.value = item

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
  resizable: true,
}

const onGridReady = (params) => {
  // Grid api
  gridApi.value = params.api
  gridOptions.api = params.api

  const savedState = localStorage.getItem('outcomes')
  if (savedState) {
    const state = JSON.parse(savedState)
    params.api.applyColumnState({ state: state, applyOrder: true })
  }

  dataSource.value = {
    getRows: async (params) => {
      // console.log('dataSource-params', params)
      const { startRow, endRow, sortModel, filterModel } = params.request
      const filterModels = gridApi.value.getFilterModel()
      // console.log('dataSource-filterModels', filterModels)
      let filters = {
        transaction_type: 'OUTCOME',
        status: { _in: [1, 2, 3] },
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
          transaction_type: 'outcome',
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
      // console.log('dataSource-filterModels', filters)

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
          'work_order.*',
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
    if (!localStorage.getItem('outcomes')) {
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

  // defaultColDef: {
  //   flex: 1,
  //   minWidth: 150,
  //   filter: true,
  //   floatingFilter: true,
  // },
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
  // console.log('onRowClickedparams', params)
  open('transaction', {
    id: params.data.id,
    data: params.data,
    module: 'outcome',

    // refresh: refreshGrid(),
  })
}

const onClickedLocation = (params) => {
  // router.push(`/parts/location/${params.data.location?.id}`)
}

const onClickedWo = (params) => {
  let item = params.data.work_order
  if (item.status == 1 || item.status == 2) {
    open('workorderopenmore', {
      id: item.id,
      data: item,
      // refresh: refreshGrid(),
    })
  } else if (item.status == 3) {
    open('workordercompletedmore', {
      id: item.id,
      data: item,
      // refresh: refreshGrid(),
    })
  }
}

// Filter functions
const filterBuild = (filterModel) => {
  let filters = {
    active: 1,
  }
  if (props.status) {
    // console.log('filterModel', filterModel)
    // Status override
    if (
      filterModel.status &&
      filterModel.status.values &&
      filterModel.status.values.length > 0
    ) {
      filters['status'] = { _in: filterModel.status.values }
    } else {
      filters['status'] = props.status
    }
  }
  if (props.work_order_type) {
    filters['type'] = {
      code_work_order: props.work_order_type,
    }
  }
  if (props.work_order_type != 'request') {
    if (props.location) {
      filters['_or'] = []
      let temp_filter = {}
      temp_filter['asset'] = {
        location: props.location,
      }
      filters['_or'].push(temp_filter)
      temp_filter = {}
      temp_filter['location'] = props.location
      filters['_or'].push(temp_filter)
    }
    if (props.asset) {
      filters['asset'] = props.asset
    }
  } else {
    if (props.location) {
      filters['location'] = props.location
    }
  }
  return filters
}

const statusFormatter = ({ value }) => {
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
    filter: false,
    sortable: false,
    cellStyle: { margin: '5px 0px 0px -10px' },
    cellClassRules: {
      'status-approved': ({ value }) => value === 2,
    },
    cellClass: 'status-cell',
    filter: 'agSetColumnFilter', // Enable set filter
    filterParams: {
      values: (params) => {
        // console.log('params.values -> ', params)
        const status_s = ref({
          _in: [1, 2, 3],
        })
        const { _in } = status_s
        const filter_statuses = statuses
          .filter((status) => [1, 2, 3].includes(status.value))
          .map((status) => status.value)
        params.success(filter_statuses)
      }, // Provide numeric values for the filter
      valueFormatter: (params) => {
        // console.log('valueFormatter.value -> ', params)
        const status = statuses.find((s) => s.value === params.value)
        return status ? status.text : params.value // Map numeric value to text
      },
      suppressRemoveAll: true, // Disable "Remove All" button
      checkbox: true, // Enable checkboxes in the filter
    },
  },
  {
    field: 'location.name',
    headerName: t('Location'),
    headerClass: 'header-location',
    // maxWidth: 180,
    resizable: true,
    cellClass: 'locations-name',
    cellStyle: { cursor: 'pointer', margin: '11px 0px 0px -14px' },
    onCellClicked: (params) => {
      onClickedLocation(params)
    },
    filter: 'agSetColumnFilter', // Enable set filter
    filterParams: {
      values: (params) => {
        const filter_statuses = locations.value.map((item) => item.id)
        params.success(filter_statuses)
      },
      valueFormatter: (params) => {
        const status = locations.value.find((s) => s.id === params.value)
        return status ? status.name : params.value // Map numeric value to text
      },
      suppressRemoveAll: true, // Disable "Remove All" button
      checkbox: true, // Enable checkboxes in the filter
    },
    // cellRenderer: LocationCell,
  },
  {
    field: 'work_order',
    headerName: t('Work order'),
    headerClass: 'header-work',
    // maxWidth: 150,
    resizable: true,
    cellClass: 'status-cell',
    cellStyle: { cursor: 'pointer', margin: '4px 0px 0px -14px' },
    onCellClicked: (params) => {
      onClickedWo(params)
    },
    cellRenderer: LocationCell,
  },

  {
    field: 'assign_user.first_name',
    headerName: t('Assign to'),
    headerClass: 'header-assign',
    // maxWidth: 150,
    resizable: true,
  },
  {
    headerName: t('Transaction Date'),
    field: 'transaction_date',
    headerClass: 'header-transaction-date',
    maxWidth: 260,
    valueFormatter: dayFormatter,
    // cellStyle: { fontSize: '11px' },
    filter: 'agDateColumnFilter',
    filterParams: filterDateParams,
  },
  {
    field: 'date_created',
    headerName: t('Created'),
    headerClass: 'header-date',
    // maxWidth: 260,
    minWidth: 90,

    valueFormatter: dateFormatter,
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
  if (last_row.value)
    last_row.value.auto_number = Number(last_row.value.auto_number) + 1
}

const saveColumnState = (params: any) => {
  // console.log(params)
  const columnState = params.api.getColumnState()
  localStorage.setItem('outcomes', JSON.stringify(columnState))
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
      transaction_type: 'OUTCOME',
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
    <div class="outcome_order_list grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="left" @click="handleModalOpen">
          <Icon
            name="material-symbols-light:output-circle-rounded"
            class="-ms-1 h-4 w-4"
          />
          <span class="text-[11px]">{{ $t('Debt add') }}</span>
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
        <OutcomeModalForm
          :key="selectedItem"
          :location="locationId"
          :row="selectedItem"
          :editPartRow="editPartRow"
          @update:editPartRow="editPartRow = $event"
          :item="selectedRow"
          :last="last_row"
          title="Debt"
          module="Outcome"
          code="Transaction"
          :open="isModalOpen"
          :close="handleModalClose"
          :refresh="refreshGrid"
          size="3xl"
        />
        <DeletionModalForm
          :key="selectedItem"
          code="Transaction"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :itemsValue="itemsValue"
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
.outcome_order_list .grid_ag {
  min-height: 560px !important;
}
.outcome_order_list .ag-center-cols-container {
  overflow: visible;
  display: flex;
  flex-direction: column;
}
.outcome_order_list .ag-row {
  overflow: visible;
  position: relative;
  transform: none !important;
  /* width: inherit; */
}
.outcome_order_list .ag-row .status-cell {
  border: none !important;
}
.outcome_order_list .ag-row .locations-name {
  line-height: 1.5;
  font-size: 13px;
  justify-content: center;
  align-items: center;
  font-weight: 500;
  border: none !important;
}
.outcome_order_list .ag-row .actions-cell {
  overflow: visible;
}
/* .ag-row:has(> .status-approved) .actions-cell {
  display: none;
} */
</style>
