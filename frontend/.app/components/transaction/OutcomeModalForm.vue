<script setup>
import { computed, ref } from 'vue'

import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const emit = defineEmits(['update:editPartRow'])

import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import ModalItemsList from '~/components/form/ModalItemsList.vue'
import WarningModalForm from '~/components/form/WarningModalForm.vue'
import ModalPartsList from '~/components/parts/ModalPartsList.vue'
import Documents from './Documents.vue'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()
const segment = ref('')
const family = ref('')
const _class = ref('')
const commodity = ref('')
const numbering = ref('')
const item_description = ref('')
const isModalPartOpen = ref(false)
const isModalWorkOrderOpen = ref(false)
const uploadedFiles = ref([])
const editFiles = ref([])
const chosedLocation = ref([])
const inputNameValue = ref('')
const inputDateValue = ref('')
const inputLocationValue = ref('')
const locationDisable = ref(false)

const inputWoValue = ref('')

const isModalConfirmText = ref('')
const inputSupplierValue = ref('')
const isModalConfirmOpen = ref(false)
const isError = ref(false)
const isModalOpen = ref(false)
const newVal = ref(false)
const work_order_filter = ref({ status: -1 })
const isModalApproveConfirmOpen = ref(false)
let rowParts = []
const numberItem = ref(1)
const selectedItems = ref([])
const initial_partfilter = ref({ status: -1 })
const lastLoadedWorkOrderId = ref(null)
const loadingWorkOrderId = ref(null)
const stateMap = ref({})

let _rowIdCounter = 0
const rows = ref([
  {
    _rowId: ++_rowIdCounter,
    parts: {
      part_number: '',
      description: '',
      qty: 0,
      id: null,
      price: 0,
    },
    quantity: 0,
    stock: 0,
    price: 0,
    qty: 0,
  },
])

// Helper function to ensure row has valid structure
const ensureRowStructure = (row) => {
  if (!row) return null
  if (!row.parts) {
    console.warn('Row missing parts property:', row)
    return {
      ...row,
      parts: {
        part_number: '',
        description: '',
        qty: 0,
        id: null,
      },
      quantity: row.quantity || 0,
      stock: row.stock || 0,
      price: row.price || 0,
      qty: row.qty || 0,
    }
  }
  return row
}

const serverItems = ref([])
const loading = ref(false)
const locationId = ref(1)
const loadItem = ref('')
const initialValue = ref(0)

const parts_row = reactive({
  name: '',
  mongolian_name: '',
  manufacturer: '',
  model_no: '',
  serial_no: '',
  material: '',
  technical_data: '',
  special_information: '',
  price: 0,
})

const props = defineProps({
  open: Boolean,
  title: String,
  module: String,
  close: Function,
  refresh: Function,
  row: Number,
  item: Object,
  code: String,
  last: Object,
  editPartRow: [Array, Number],
  location: Number,
})

// Scroll контейнерийг тодорхойлох ref
const rowsContainer = ref(null)

const handleModalPartClose = () => {
  isModalPartOpen.value = false
  isModalApproveConfirmOpen.value = false
}

const handleModalWorkOrderClose = () => {
  isModalWorkOrderOpen.value = false
}

const chooseBinnedIndex = ref(null)
const chooseBinnedSearch = ref('')

const handleModalPartOpen = (index) => {
  chooseBinnedIndex.value = index
  const target = props.row === -1 ? rows.value : props.editPartRow
  chooseBinnedSearch.value = target[index]?.parts?.part_number || ''
  isModalPartOpen.value = true
  loadItem.value = 'BinnedParts'
}

const handleModalClose = () => {
  isModalPartOpen.value = false
  isModalWorkOrderOpen.value = false
  locationDisable.value = false

  isError.value = false
  work_order_filter.value = { status: -1 }
  rowParts = []
  // props.row =-1
  isModalApproveConfirmOpen.value = false

  setEmptyRow()
  props.close()
}

const handleModalWorkOrderOpen = (item, filters) => {
  isModalWorkOrderOpen.value = true
  // //console.log('handleModalWorkOrderOpen', item, filters)
}

const handleAddRow = (item, index) => {
  const newRow = {
    _rowId: ++_rowIdCounter,
    parts: {
      part_number: '',
      description: '',
      qty: 0,
      id: null,
    },
    quantity: 0,
    stock: 0,
    price: 0,
    qty: 0,
  }

  if (props.row === -1) {
    rows.value.splice(index + 1, 0, newRow)
  } else {
    props.editPartRow.splice(index + 1, 0, newRow)
  }

  // Scroll-ийг доош шилжүүлэх
  setTimeout(() => {
    if (rowsContainer.value) {
      rowsContainer.value.scrollTop = rowsContainer.value.scrollHeight
    }
  }, 0) // Ачааллыг баталгаажуулахын тулд бага зэрэг хүлээлт
}

const handleRemoveRow = (item, index) => {
  if (props.row === -1) {
    if (rows.value.length > 1) {
      rows.value.splice(index, 1)
    }
  } else {
    if (props.editPartRow.length > 0) props.editPartRow.splice(index, 1)
  }
}

const setPart = (item) => {
  const index = chooseBinnedIndex.value
  if (index == null) return

  const target = props.row === -1 ? rows.value : props.editPartRow
  const existing = target[index] ?? {}

  target[index] = ensureRowStructure({
    ...existing,
    parts: {
      ...(existing.parts || {}),
      id: item.part?.id ?? null,
      part_number: item.part?.part_number ?? '',
      description: item.part?.description || existing.parts?.description || '',
    },
    bin_location: item.bin_location?.id ?? null,
    bin_location_name: item.bin_location?.name ?? '',
    part_state: item.part_state ?? existing.part_state ?? null,
    stock: item.qty ?? 0,
  })

  chooseBinnedIndex.value = null
}

const setMultipleParts = (selectedParts) => {
  const newRows = selectedParts.map((part) => ({
    _rowId: ++_rowIdCounter,
    parts: {
      id: part.id,
      part_number: part.part_number,
      description: part.name || part.description || '',
      qty: 0,
      stock: 0,
      price: part.price || 0,
    },
    quantity: 0,
    stock: 0,
    price: part.price || 0,
    qty: 1,
  }))

  const target = props.row === -1 ? rows.value : props.editPartRow
  if (target.length === 1 && !target[0].parts?.id) {
    target.splice(0, 1, ...newRows)
  } else {
    target.push(...newRows)
  }

  setTimeout(() => {
    if (rowsContainer.value) {
      rowsContainer.value.scrollTop = rowsContainer.value.scrollHeight
    }
  }, 0)
}

const setWorkOrder = (obj) => {
  inputWoValue.value = obj

  // Normalize the work order object to ensure location is an ID
  const normalizedObj = {
    ...obj,
    location:
      typeof obj.location === 'object' ? obj.location?.id : obj.location,
  }

  const workOrderId = normalizedObj?.id
  if (
    !workOrderId ||
    loadingWorkOrderId.value === workOrderId ||
    lastLoadedWorkOrderId.value === workOrderId
  ) {
    return
  }

  setParts(normalizedObj, null) // Load parts based on selected work order
}

const setEmptyRow = () => {
  locationDisable.value = false
  lastLoadedWorkOrderId.value = null
  loadingWorkOrderId.value = null

  inputNameValue.value = ''
  inputDateValue.value = ''
  inputLocationValue.value = ''
  inputSupplierValue.value = ''
  inputWoValue.value = ''
  uploadedFiles.value = ''
  rows.value = [
    {
      _rowId: ++_rowIdCounter,
      parts: {
        part_number: '',
        description: '',
        qty: 0,
        stock: 0,
        id: null,
      },
      quantity: 0,
      stock: 0,
      price: 0,
      qty: 0,
    },
  ]
}

const generateNumber = async (codec) => {
  try {
    //console.log(token.value, codec)
    let url =
      runtimeConfig.public.directus.url + `db/generate_number/?codec=${codec}`
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.value}`,
      },
    })
    const jsonData = await response.json()
    numbering.value =
      jsonData.codec + jsonData.number.toString().padStart(3, '0')
  } catch (error) {
    console.error('Error fetching data:', error)
  }
}

const setItem = async (collection) => {
  if (commodity && commodity.value && commodity?.value.codec?.length > 0) {
    const filters = {}
    if (collection === 'segment') {
      filters['codec'] = commodity?.value.codec.slice(0, 2) + '000000'
    }
    if (collection === 'family') {
      filters['codec'] = commodity?.value.codec.slice(0, 4) + '0000'
    }
    if (collection === 'class') {
      filters['codec'] = commodity?.value.codec.slice(0, 6) + '00'
    }
    const items = await getItems({
      collection: collection.charAt(0).toUpperCase() + collection.slice(1),
      params: {
        filter: filters,
        limit: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    if (collection === 'segment') {
      segment.value = items.data[0]
    }
    if (collection === 'family') {
      family.value = items.data[0]
    }
    if (collection === 'class') {
      _class.value = items.data[0]
    }
  }
}

const setCommodity = async (_commodity) => {
  //console.log(_commodity)
  commodity.value = _commodity
  await setItem('segment')
  await setItem('family')
  await setItem('class')
  await generateNumber(_commodity?.codec)
  // item_description.value = numbering.value + ' ' + segment?.value.description + ' ' +
  //  family?.value.description + ' ' + _class?.value.description + ' ' + commodity?.value.description;
}

// Parts_Amounts.outcome_amount cache байхгүй боллоо — асаж хадгалдаг байсан
// updateStock()-ыг устгав. outcome_amount одоо parts/location жагсаалт болон
// warehouse дээр Transaction_parts-аас шууд live тооцогддог тул энд синк
// хийх шаардлагагүй.

const submitHandler = async (values) => {
  // //console.log('values ->', values)
  // //console.log('rows', rows.value)
  // //console.log(' props.row ->', props.row)
  // //console.log('editPartRow ->', props.editPartRow)

  // //console.log('uploadedFiles ->', uploadedFiles)

  // //console.log('inputDateValue ->', inputDateValue.value)
  // //console.log('inputLocationValue.value ->', inputLocationValue.value)
  toaster.clearAll()
  let itemsValue = {}
  let location_id = 0

  if (!inputDateValue.value) {
    isModalConfirmOpen.value = true
    isModalConfirmText.value = 'Please insert date!'
    return
  }
  if (!inputNameValue.value) {
    isModalConfirmOpen.value = true
    isModalConfirmText.value = 'Please insert name!'

    return
  }
  if (!inputLocationValue.value) {
    isModalConfirmOpen.value = true
    isModalConfirmText.value = 'Please location name!'
    return
  }

  if (!inputWoValue.value) {
    isModalConfirmOpen.value = true
    isModalConfirmText.value = 'Please work order name!'
    return
  }

  if (props.module === 'Outcome') {
    location_id = inputLocationValue.value?.id
    itemsValue['transaction_type'] = 'OUTCOME'
    itemsValue['location'] = inputLocationValue.value?.id
    itemsValue['work_order'] = inputWoValue.value?.id
    itemsValue['name'] = inputNameValue.value
    itemsValue['transaction_date'] = inputDateValue.value
  }

  let items = [{ ...itemsValue, company_id: myCompanyId }]
  let partSums = {}

  for (const key of Object.keys(values)) {
    if (key.startsWith('part')) {
      const index = key.replace('part', '')
      const woQtyKey = `WO_Qty${index}`
      const qtyKey = `Qty${index}`
      const IncomeQty = `Stocks${index}`
      let partNumber = values[key] // part дугаар
      let OutQty = parseInt(values[qtyKey] || 0, 10) // Qty хувиргах
      if (!partSums[partNumber]) {
        partSums[partNumber] = 0
      }

      partSums[partNumber] += OutQty

      let woQty = 0
      let qty = 0
      let InQty = 0
      if (values[woQtyKey] == undefined) woQty = 0
      if (values[qtyKey] == undefined) qty = 0
      if (values[IncomeQty] == undefined) InQty = 0

      if (values[woQtyKey] !== undefined && values[qtyKey] !== undefined) {
        woQty = parseInt(values[woQtyKey], 10)
        qty = parseInt(values[qtyKey], 10)
        InQty = parseInt(values[IncomeQty], 10)

        // if (partSums[partNumber] > woQty) {
        //   isModalConfirmOpen.value = true
        //   isError.value = true
        //   isModalConfirmText.value = `Part (${values[key]} ${partSums[partNumber]} / ${woQty}): error!`
        //   break // Exit the loop early
        // }

        if (InQty === 0) {
          isModalConfirmOpen.value = true
          isError.value = true
          isModalConfirmText.value = `Part (${values[key]}): no income.`
          break // Exit the loop early
        }

        if (InQty > 0 && InQty < woQty) {
          woQty = InQty
        }

        if (InQty < woQty || woQty < qty) {
          isModalConfirmOpen.value = true
          isError.value = true
          isModalConfirmText.value = `Part (${values[key]}): WO Qty (${woQty}) < Qty (${qty})`
          break // Exit the loop early
        } else isError.value = false
      }
    }
  }

  if (isError.value) return

  if (props.row === -1) {
    const res = await createItems({ collection: props.code, items })

    if (res) {
      let Id = res[0].id
      // const newParts = rows.value
      //   .filter((part) => part.stock !== 0) // stock=0 бол хасна
      //   .map((part, index) => {
      //     const qtyKey = `Qty${index}`
      //     const partKey = `part${index}`

      //     // //console.log('part', part)

      //     return {
      //       transaction_id: Id,
      //       transaction_type: 'outcome',
      //       part: part.parts?.id,
      //       work_order: inputWoValue.value?.id,
      //       qty: parseInt(values[qtyKey] || 0),
      //       old_qty: parseInt(part.qty || 0),
      //     }
      //   })

      const newParts = rows.value
        .map((part, index) => {
          const qtyKey = `Qty${index}`
          const qty = parseInt(values[qtyKey] || 0)
          if (qty <= 0 || !part.parts?.id || !part.bin_location) return null
          return {
            transaction_id: Id,
            transaction_type: 'outcome',
            part: part.parts.id,
            bin_location: part.bin_location,
            work_order: inputWoValue.value?.id,
            qty,
            old_qty: parseInt(part.qty || 0),
            part_state: part.part_state ?? null,
            company_id: myCompanyId,
          }
        })
        .filter(Boolean)

      // //console.log('newParts', newParts)

      const Transaction_parts = await createItems({
        collection: 'Transaction_parts',
        items: newParts, // Use newParts array directly
      })

      if (uploadedFiles.value.length) {
        uploadedFiles.value.map(async (uploadedFile) => {
          const file_items = {
            transaction_id: res[0]?.id,
            file: uploadedFile.file.id,
            company_id: myCompanyId,
          }

          const file_res = await createItems({
            collection: 'Transaction_files',
            items: file_items,
          })
        })
      }
    }

    toaster.show({
      title: t('Added'),
      message: t(`Record created successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  } else {
    const data = {
      collection: props.code,
      id: props.row,
      item: itemsValue,
    }

    await updateItem(data)

    const deleted = await deleteItems({
      collection: 'Transaction_parts',
      items: {
        query: {
          filter: {
            transaction_id: props.row,
          },
        },
      },
    })

    // const newParts = props.editPartRow.map((part, index) => {
    //   const qtyKey = `Qty${index}`
    //   const partKey = `part${index}`

    //   return {
    //     transaction_id: props.row,
    //     part: part.parts?.id,
    //     transaction_type: 'outcome',
    //     work_order: inputWoValue.value?.id,
    //     qty: parseInt(values[qtyKey] || 0),
    //     old_qty: parseInt(part.qty || 0),
    //   }
    // })

    const newParts = props.editPartRow
      .map((part, index) => {
        const qtyKey = `Qty${index}`
        const qty = parseInt(values[qtyKey] || 0)
        if (qty <= 0 || !part.parts?.id || !part.bin_location) return null
        return {
          transaction_id: props.row,
          transaction_type: 'outcome',
          part: part.parts.id,
          bin_location: part.bin_location,
          work_order: inputWoValue.value?.id,
          qty,
          old_qty: parseInt(part.old_qty || 0),
          part_state: part.part_state ?? null,
          company_id: myCompanyId,
        }
      })
      .filter(Boolean)

    const Transaction_parts = await createItems({
      collection: 'Transaction_parts',
      items: newParts,
    })

    if (uploadedFiles.value.length) {
      const filteredData = uploadedFiles.value.filter(
        (item) => !item.hasOwnProperty('id'),
      )

      filteredData.map(async (uploadedFile) => {
        const file_items = {
          transaction_id: props.row,
          file: uploadedFile.file.id,
          company_id: myCompanyId,
        }

        const file_res = await createItems({
          collection: 'Transaction_files',
          items: file_items,
        })
      })
    }

    // outcome_amount live тооцогддог тул edit хийхэд Parts_Amounts синк хийх
    // шаардлагагүй болсон.

    toaster.show({
      title: t('Updated'),
      message: t(`Record updated successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }

  if (props.refresh) {
    //console.log('Props refresh 2...')
    props.refresh()
  }
  if (props.close) {
    props.close()
  }

  handleModalClose()
}

const handleUpload = async (items) => {
  uploadedFiles.value = items
}

const formInputClass = computed(() => {
  // //console.log('formInputClass', props.last)
  return 'form_inputs'
})

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalApproveConfirmOpen.value = false
}
onMounted(async () => {
  // Load state names
  try {
    const stateRes = await getItems({
      collection: 'States',
      params: {
        filter: { company_id: { _eq: myCompanyId } },
        fields: ['id', 'name'],
        limit: -1,
      },
    })
    const stateItems = Array.isArray(stateRes) ? stateRes : stateRes?.data ?? []
    const map = {}
    for (const s of stateItems) map[String(s.id)] = s.name || String(s.id)
    stateMap.value = map
  } catch (e) {
    console.warn('Failed to load states:', e)
  }

  //console.log('onMounted', props.row)
  //console.log('props.editPartRow:', props.editPartRow)
  //console.log('props.editPartRow type:', typeof props.editPartRow)
  //console.log('props.editPartRow isArray:', Array.isArray(props.editPartRow))
  if (props.editPartRow && props.editPartRow.length > 0) {
    //console.log('First editPartRow item:', props.editPartRow[0])
    //console.log('quantity (WO Qty):', props.editPartRow[0]?.quantity)
    //console.log('qty (Out Qty):', props.editPartRow[0]?.qty)
  }
  if (props.row) {
    //edit
    inputNameValue.value = props.item?.name
    inputDateValue.value = props.item?.transaction_date?.split('T')[0]
    inputLocationValue.value = props.item?.location
    inputWoValue.value = props.item?.work_order
    // Анхны ачаалалт дээр inputWoValue-г тохируулахад watch(inputWoValue)
    // асаагдаж setParts()-ийг дуудаад, do_edit-ээс аль хэдийн зөв бөглөсөн
    // props.editPartRow-ийг (bin_location зэрэг) дарж бичихээс сэргийлнэ.
    // Хэрэглэгч edit хийж байхдаа WO-г бодитоор солиход л дахин ачаална.
    lastLoadedWorkOrderId.value = props.item?.work_order?.id ?? null
    initial_partfilter.value = {
      transaction_id: {
        status: 2,
        transaction_type: 'INCOME',
        location: props.item?.location?.id,
      },
    }

    if (props.location) {
      const locationRes = await getItems({
        collection: 'Location',
        params: {
          filter: {
            status: '1',
            id: props.location,
            company_id: { _eq: myCompanyId },
          },
          meta: 'filter_count',
          fields: ['*'],
        },
      })

      inputLocationValue.value = locationRes.data[0]
      setLocation(locationRes.data[0])

      locationDisable.value = true

      //console.log('inputLocationValue', inputLocationValue)
    }

    // inputSupplierValue.value = props.item?.supplier
  } else {
    // props.row === -1 ? -1
  }
})

watch(inputWoValue, async (newValue, oldValue) => {
  // Update parts when work order changes
  if (newValue && newValue !== oldValue) {
    // //console.log('Work order changed:', newValue)
    // Handle both object and primitive values
    if (typeof newValue === 'object' && newValue && newValue.id) {
      // If it's an object with id, normalize and load parts
      const normalizedObj = {
        ...newValue,
        location:
          typeof newValue.location === 'object'
            ? newValue.location?.id
            : newValue.location,
      }
      const workOrderId = normalizedObj?.id
      if (
        !workOrderId ||
        loadingWorkOrderId.value === workOrderId ||
        lastLoadedWorkOrderId.value === workOrderId
      ) {
        return
      }
      await setParts(normalizedObj, null)
    } else if (typeof newValue === 'number' || typeof newValue === 'string') {
      // If it's just an ID, we need to handle it differently or skip
      // //console.log('Work order changed to ID:', newValue)
    }
  }
})

watch(locationDisable, async (newValue, oldValue) => {
  // Only run if locationDisable is changing to false and props.location exists
  if (newValue === false && props.location && oldValue !== newValue) {
    // //console.log('watch changed:', locationDisable.value)
    const locationRes = await getItems({
      collection: 'Location',
      params: {
        filter: {
          status: '1',
          id: props.location,
          company_id: { _eq: myCompanyId },
        },
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    inputLocationValue.value = locationRes.data[0]
    setLocation(locationRes.data[0])

    locationDisable.value = true

    //  //console.log('inputLocationValue', inputLocationValue)
  }
})

const setLocation = (obj) => {
  chosedLocation.value = obj

  newVal.value = changeFilter1(
    chosedLocation.value?.id,
    inputLocationValue.value?.id,
    'part',
  )

  work_order_filter.value = changeFilter1(
    chosedLocation.value?.id,
    inputLocationValue.value?.id,
    'work_order',
  )

  // //console.log('setLocation', work_order.value, newVal.value)
}

const quantityDifferences = async (wo_parts, transaction_parts, location) => {
  const res = await Promise.all(
    wo_parts.map(async (woPart) => {
      const matchingTransactionPart = transaction_parts.find(
        (tp) => tp.part.id === woPart.parts.id,
      )

      let stock = 0
      const [tpRes, binItems, shiftItems] = await Promise.all([
        getItems({
          collection: 'Transaction_parts',
          params: {
            filter: {
              company_id: { _eq: myCompanyId },
              part: { _eq: woPart.parts.id },
              transaction_id: {
                location: { _eq: location },
                status: { _eq: 2 },
              },
            },
            fields: ['qty', 'transaction_type'],
            limit: -1,
          },
        }),
        getItems({
          collection: 'Parts_Bin_location',
          params: {
            filter: {
              part: { _eq: woPart.parts.id },
              status: { _neq: 'archived' },
              bin_location: { location: { _eq: location } },
            },
            fields: ['qty', 'transaction_parts.part_state'],
            limit: -1,
          },
        }),
        getItems({
          collection: 'Parts_shift_history',
          params: {
            filter: {
              company_id: { _eq: myCompanyId },
              part: { _eq: woPart.parts.id },
              _or: [
                { from_location: { _eq: location } },
                { to_location: { _eq: location } },
              ],
            },
            fields: ['qty', 'from_location', 'to_location'],
            limit: -1,
          },
        }),
      ])

      // Aggregate stock by state
      const binList = Array.isArray(binItems) ? binItems : binItems?.data ?? []
      const byStateMap = {}
      for (const b of binList) {
        const sid = b.transaction_parts?.part_state ?? '__null__'
        const key = String(sid)
        byStateMap[key] = (byStateMap[key] || 0) + (b.qty || 0)
      }
      const stockByState = Object.entries(byStateMap).map(([k, qty]) => ({
        stateId: k === '__null__' ? null : Number(k),
        stateName: k === '__null__' ? '—' : stateMap.value[k] ?? k,
        qty,
      }))

      const tpList = Array.isArray(tpRes) ? tpRes : tpRes?.data ?? []
      let income_amount = 0
      let outcome_amount = 0
      for (const tp of tpList) {
        const qty = parseInt(tp.qty) || 0
        const isIncome =
          tp.transaction_type === 'income' || tp.transaction_type === 'INCOME'
        if (isIncome) income_amount += qty
        else outcome_amount += qty
      }

      const shiftList = Array.isArray(shiftItems)
        ? shiftItems
        : shiftItems?.data ?? []
      for (const sh of shiftList) {
        const qty = parseInt(sh.qty) || 0
        const toId =
          typeof sh.to_location === 'object'
            ? sh.to_location?.id
            : sh.to_location
        const fromId =
          typeof sh.from_location === 'object'
            ? sh.from_location?.id
            : sh.from_location
        if (String(toId) === String(location)) income_amount += qty
        if (String(fromId) === String(location)) outcome_amount += qty
      }

      if (income_amount - outcome_amount > 0) {
        stock = income_amount - outcome_amount
      }

      const usedQty = matchingTransactionPart?.totalQty || 0
      const quantityDifference = woPart.quantity - usedQty

      console.log(
        `Part ${woPart.parts.part_number}: Original=${woPart.quantity}, Used=${usedQty}, Remaining=${quantityDifference}, Stock=${stock}`,
      )

      if (quantityDifference > 0) {
        return {
          ...woPart,
          stock,
          stockByState,
          quantity: quantityDifference,
          quantityDifference: quantityDifference,
        }
      }
      return null
    }),
  )

  // //console.log('return ', res)
  return res.filter((woPart) => woPart !== null)
}

const mergeParts = (data) => {
  // Group by part.id and sum the quantities
  const grouped = data.reduce((acc, item) => {
    const partId = item.part.id
    if (!acc[partId]) {
      acc[partId] = {
        part: item.part, // Keep the part details
        totalQty: 0,
      }
    }
    acc[partId].totalQty += item.qty || 0
    return acc
  }, {})

  // Convert the grouped result into an array of merged parts
  return Object.values(grouped)
}

const setParts = async (obj, item_index) => {
  const workOrderId = obj?.id
  if (!workOrderId) {
    loading.value = false
    return
  }

  if (
    loadingWorkOrderId.value === workOrderId ||
    lastLoadedWorkOrderId.value === workOrderId
  ) {
    return
  }

  loadingWorkOrderId.value = workOrderId
  loading.value = true
  // //console.log('rows.amount_items obj -->  ', obj)

  if (obj && obj.id) {
    try {
      const filters = {
        transaction_id: { status: { _in: [1, 2] } },
        work_order: obj.id,
      }

      //wo=parts and debt-parts checking
      const transaction_item = await getItems({
        collection: 'Transaction_parts',
        params: {
          filter: filters,
          meta: 'filter_count',
          fields: ['*', 'work_order.*', 'part.*', 'transaction_id.*'],
        },
      })

      const wo_items = await getItems({
        collection: 'Work_order_Parts',
        params: {
          filter: { work_order: obj.id, status: 1 },
          meta: 'filter_count',
          fields: ['*', 'parts.*', 'work_order.*', 'part_state'],
        },
      })

      let diff = []
      // Check if there are existing transactions to calculate remaining quantities
      const mergedParts =
        transaction_item.data.length > 0
          ? mergeParts(transaction_item.data)
          : []

      // Тухайн debt-ийн сонгосон байршлаар (WO-ийн location биш) stock-ийг
      // хязгаарлана — эс тэгвэл бүх байршлын нийлбэрийг харуулж болзошгүй
      diff = await quantityDifferences(
        wo_items.data,
        mergedParts,
        inputLocationValue.value?.id ?? obj.location,
      )

      console.log('quantityDifferences result:', diff)
      console.log(
        'quantityDifferences result detail:',
        JSON.stringify(diff, null, 2),
      )

      if (diff.length > 0) {
        rows.value = diff.map((r) => ({ _rowId: ++_rowIdCounter, ...r }))
      } else {
        rows.value = [
          {
            _rowId: ++_rowIdCounter,
            parts: {
              part_number: '',
              description: '',
              qty: 0,
              stock: 0,
              id: null,
            },
          },
        ]
      }

      console.log('Final rows with remaining quantities:', rows.value)

      if (rows.value.length > 0) {
        console.log('First row detail:', {
          part_number: rows.value[0]?.parts?.part_number,
          quantity: rows.value[0]?.quantity,
          stock: rows.value[0]?.stock,
          full_row: rows.value[0],
        })
      }

      // Ensure all rows have proper structure
      rows.value = rows.value
        .map(ensureRowStructure)
        .filter((row) => row !== null)

      if (props.row > 0) {
        props.editPartRow = [...rows.value]
        emit('update:editPartRow', [...rows.value])
      }
      rowParts = [...rows.value] // Шинэ массив үүсгэх
      lastLoadedWorkOrderId.value = workOrderId
    } catch (e) {
      console.error('Error loading parts:', e)

      // Set default empty row on error
      rows.value = [
        {
          parts: {
            part_number: '',
            description: '',
            qty: 0,
            stock: 0,
            id: null,
          },
        },
      ]
    } finally {
      loadingWorkOrderId.value = null
      loading.value = false
    }
  } else {
    // If obj is invalid, just set loading to false
    loadingWorkOrderId.value = null
    loading.value = false
  }
}

const setValue = (obj, item_index) => {
  let index = item_index.value

  if (!obj) {
    if (rows.value[index]) {
      let newValue = {
        parts: {
          part_number: '',
          description: '',
          qty: 0,
          id: null,
        },
        quantity: 0,
        stock: 0,
        price: 0,
        qty: 0,
      }

      rows.value[index] = {
        ...rows.value[index],
        ...newValue,
      }
    }
  } else {
    // //console.log('obj.part_number1', obj)
    // //console.log('obj.part_number2', obj.part_number)
    // //console.log('obj.rowParts1', rowParts)

    const chosenRow = rowParts.filter((row) => row.parts?.id === obj.id)[0]

    if (chosenRow) {
      // Use the chosen row from rowParts
      rows.value[index] = ensureRowStructure({ ...chosenRow })
    } else {
      // If not found in rowParts, create new row with obj data
      console.warn('Part not found in rowParts, creating new entry:', obj)
      rows.value[index] = ensureRowStructure({
        parts: obj,
        quantity: 0,
        stock: 0,
        price: 0,
        qty: 0,
      })
    }
  }
}

const handleSelectedItem = (rawValue, index) => {
  // //console.log('handleSelectedItem -->:', rawValue, index)
  selectedItems.value[index] =
    rawValue?.part_number?.part_number || rawValue?.part_number || rawValue

  // //console.log('Selected item==>>', selectedItems.value)
  // //console.log('Selected newVal==>>', newVal.value)
}

const changeFilter1 = (newId, oldId, type) => {
  if (newId !== oldId) {
    // //console.log('newId changed:', newId, oldId, type)
    if (type == 'work_order') {
      return {
        action_status: 2, //approved
        location: newId,
        wo_status: { type: { _eq: 'open' } },
      }
    } else {
      //approved parts
      return {
        transaction_id: {
          status: 2,
          transaction_type: 'INCOME',
          location: newId,
        },
      }
    }
  } else {
    if (type == 'work_order') {
      return {
        action_status: 2,
        location: props.location || newId,
        wo_status: { type: { _eq: 'open' } },
      }
    } else {
      return {
        transaction_id: {
          status: 2,
          transaction_type: 'INCOME',
          location: props.location || newId,
        },
      }
    }
  }
}

const changeFilter = computed(() => {
  if (chosedLocation.value?.id) {
    return {
      status: 1,
      location: chosedLocation.value?.id,
    }
  } else {
    return false
  }
})

const askModalClose = () => {
  isModalApproveConfirmOpen.value = true
  // //console.log('askModalClose', rows.value.length)
}

const do_make = async (item, type) => {
  handleModalClose()
}

// watch(chosedLocation, () => {
//   //console.log('watch changed:', chosedLocation.value?.id)

//   return {
//     'chosedLocation.value.id': function (newId, oldId) {
//       //console.log('watch changed2:', newId, oldId)

//       if (newId !== oldId) {
//         //console.log('newId changed:', newId, oldId)
//       }
//     },
//   }
// })
</script>

<template>
  <!-- New & Edit modal -->
  <TairoModal
    :classes="{ dialog: 'OutcomeModal' }"
    :key="props.key"
    :open="props.open"
    @close="askModalClose"
  >
    <template #header>
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div
          class="addDebt flex font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white pl-8"
        >
          {{ t(title) + `&nbsp;` }}
          <p :style="{ color: 'red' }">
            #{{
              props.row === -1
                ? props.last
                  ? Number(props.last.auto_number) + 1
                  : 1
                : Number(props.item.auto_number)
            }}
          </p>
        </div>
        <BaseButtonClose @click="handleModalClose" />
      </div>
    </template>

    <!-- Body -->
    <div class="outcomePopup rows-container flex mx-auto px-5 PopupContainer">
      <FormKit
        type="form"
        :actions="true"
        :incomplete-message="false"
        :style="{ width: '100%' }"
        :submit-label="t('Save')"
        @submit="submitHandler"
        :submit-attrs="{
          inputClass:
            'text-sm px-6 py-2 mt-2 mb-4 is-button rounded-lg bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
          ignore: false,
          wrapperClass: 'submit outcome-submit-footer flex justify-end',
        }"
      >
        <BaseTabs
          justify="end"
          type="box"
          model-value="parts"
          class="tabs"
          :tabs="[
            { label: $t('Info'), value: 'parts' },
            { label: $t('Documents'), value: 'documents' },
          ]"
        >
          <template #tab="{ activeValue }">
            <div
              ref="rowsContainer"
              v-if="activeValue === 'parts'"
              class="rowsContainer font-sans text-sm pb-[35px]"
            >
              <!-- Info header -->
              <div
                class="out-header-grid flex flex-col gap-2 p-4 bg-gray-50 dark:bg-muted-900 rounded"
              >
                <!-- Row 1: Name full width -->
                <div>
                  <FormKit
                    name="outcome_name"
                    type="text"
                    :label="t('Name')"
                    :validation="'required'"
                    validation-label="*"
                    v-model="inputNameValue"
                    :classes="{
                      outer: 'out-outer',
                      label: 'out-label',
                      input: 'out-field-input',
                    }"
                  />
                </div>
                <!-- Row 2: Date + Location equal width -->
                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <FormKit
                      name="transaction_date"
                      :validation="'required'"
                      validation-label="*"
                      type="date"
                      :label="t('Date')"
                      v-model="inputDateValue"
                      :classes="{
                        outer: 'out-outer',
                        label: 'out-label',
                        input: 'out-field-input',
                      }"
                    />
                  </div>
                  <div>
                    <FormKit
                      name="location"
                      type="autocomplete2"
                      validation-label="*"
                      collection_name="Location"
                      :initial_filter="{ status: 1 }"
                      :label="t('Location')"
                      item_value="id"
                      item_title="name"
                      search_field="name"
                      :validation="'required'"
                      v-model="inputLocationValue"
                      :setParentValue="setLocation"
                      :disabled="locationDisable"
                      :classes="{ outer: 'out-outer', label: 'out-label' }"
                    />
                  </div>
                </div>
                <!-- Row 3: Work Order + ... button -->
                <div class="flex gap-2 items-end">
                  <div class="flex-1">
                    <FormKit
                      name="work_order"
                      type="autocomplete2"
                      :initial_filter="{
                        action_status: 2,
                        location: props.location,
                        wo_status: { type: { _eq: 'open' } },
                      }"
                      collection_name="Work_order"
                      :label="t('Work Order')"
                      item_value="id"
                      item_title="name"
                      item_fields="id, name, wo_number"
                      label_extra="wo_number"
                      search_field="name"
                      :validation="'required'"
                      validation-label="*"
                      v-model="inputWoValue"
                      :change_filter="work_order_filter"
                      :initial_break="true"
                      :setValue="setParts"
                      :classes="{ outer: 'out-outer', label: 'out-label' }"
                    />
                  </div>
                  <div
                    style="
                      border: 1px solid #d2d2d2;
                      border-radius: 8px;
                      padding-bottom: 2px !important;
                    "
                  >
                    <BaseButton
                      color="default"
                      class="out-wo-more-btn"
                      @click="handleModalWorkOrderOpen('WO', work_order_filter)"
                    >
                      ...
                    </BaseButton>
                  </div>
                </div>
              </div>

              <!-- Parts table -->
              <div class="px-4 pt-3">
                <!-- Table header + Add button -->
                <div class="flex items-center justify-between mb-2">
                  <span
                    class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide"
                    >{{ t('Parts') }}</span
                  >
                  <!-- <BaseButton
                    type="button"
                    color="primary"
                    size="sm"
                    class="inc-add-btn"
                    @click="handleModalPartOpen('Parts')"
                  >
                    <Icon name="ph:plus-bold" class="me-1 size-3" />
                    {{ $t('Add Parts') }}
                  </BaseButton> -->
                </div>

                <!-- Column headers -->
                <div class="inc-table-head flex gap-1 mb-1 px-1">
                  <span class="inc-col-label" style="width: 20px">#</span>
                  <span class="inc-col-label" style="flex: 1">{{
                    t('Part')
                  }}</span>
                  <span class="inc-col-label" style="width: 120px">{{
                    t('Description')
                  }}</span>
                  <span class="inc-col-label" style="width: 60px">{{
                    t('Stock')
                  }}</span>
                  <span class="inc-col-label" style="width: 80px">{{
                    t('State')
                  }}</span>
                  <span class="inc-col-label" style="width: 60px">{{
                    t('WO Qty')
                  }}</span>
                  <span class="inc-col-label" style="width: 70px">{{
                    t('Out Qty')
                  }}</span>
                  <span style="width: 50px"></span>
                </div>

                <!-- Rows -->
                <div
                  v-for="(item, index) in props.row === -1
                    ? rows
                    : props.editPartRow"
                  :key="item._rowId ?? index"
                  class="inc-row flex gap-1 items-start mb-1 px-1 py-0.5 rounded hover:bg-gray-50 dark:hover:bg-muted-800"
                >
                  <span
                    class="text-xs text-gray-400 text-right pr-1"
                    style="width: 20px"
                    >{{ index + 1 }}</span
                  >

                  <div class="out-part-outer" style="width: 150px">
                    <div
                      v-if="item.parts?.id"
                      class="text-xs mb-0.5 leading-tight"
                    >
                      <div class="font-medium truncate">
                        {{ item.parts.part_number }}
                      </div>
                      <div
                        class="text-[10px] truncate"
                        :class="
                          item.bin_location
                            ? 'text-muted-400'
                            : 'text-danger-500 font-medium'
                        "
                      >
                        {{ item.bin_location_name || t('Bin required') }}
                      </div>
                    </div>
                    <BaseButton
                      type="button"
                      size="sm"
                      :color="
                        item.parts?.id && !item.bin_location
                          ? 'default'
                          : 'default'
                      "
                      class="w-full"
                      @click="handleModalPartOpen(index)"
                    >
                      {{ item.parts?.id ? t('Change') : t('Choose') }}
                    </BaseButton>
                    <FormKit
                      :name="'part' + index"
                      type="hidden"
                      :validation="'required'"
                      v-model="item.parts.part_number"
                    />
                    <FormKit
                      :name="'bin' + index"
                      type="hidden"
                      :validation="'required'"
                      :validation-messages="{
                        required: t('Please choose a bin location'),
                      }"
                      v-model="item.bin_location"
                    />
                  </div>

                  <div style="width: 140px; flex: 1">
                    <FormKit
                      :name="'description' + index"
                      type="textarea"
                      :validation="'required'"
                      :validation-messages="{ required: '*' }"
                      :style="{
                        width: '100%',
                        height: '32px',
                        fontSize: '11px',
                      }"
                      v-model="item.parts.description"
                      :classes="{ outer: 'out-outer' }"
                    />
                  </div>

                  <div style="width: 100px">
                    <div
                      v-if="item.stockByState?.length"
                      class="text-[11px] leading-snug px-1 py-0.5 rounded bg-muted-100 dark:bg-muted-800"
                    >
                      <div
                        v-for="s in item.stockByState"
                        :key="s.stateId"
                        class="flex justify-between gap-1"
                      >
                        <span
                          class="text-muted-400 truncate"
                          style="max-width: 60px"
                          >{{ s.stateName }}</span
                        >
                        <span
                          class="font-medium text-muted-700 dark:text-muted-200"
                          >{{ s.qty }}</span
                        >
                      </div>
                    </div>
                    <FormKit
                      v-else
                      :key="'stock-' + index + '-' + (item.stock || 0)"
                      :name="'Stocks' + index"
                      :class="formInputClass"
                      type="number"
                      :value="item.stock || 0"
                      readonly="true"
                      :style="{ width: '100%', height: '32px !important' }"
                      :classes="{ outer: 'out-outer' }"
                    />
                    <!-- Hidden input so Stocks{index} is still available to submitHandler -->
                    <FormKit
                      v-if="item.stockByState?.length && props.row === -1"
                      :key="'stocks-hidden-' + index"
                      :name="'Stocks' + index"
                      type="hidden"
                      :value="item.stock || 0"
                    />
                  </div>

                  <!-- State column -->
                  <div style="width: 80px" class="flex items-center">
                    <span
                      class="text-[11px] px-1.5 py-0.5 rounded leading-snug"
                      :class="
                        item.part_state
                          ? 'bg-info-100 dark:bg-info-900/30 text-info-700 dark:text-info-300'
                          : 'text-muted-400'
                      "
                    >
                      {{
                        item.part_state
                          ? stateMap[String(item.part_state)] ??
                            String(item.part_state)
                          : '—'
                      }}
                    </span>
                  </div>

                  <div style="width: 60px">
                    <FormKit
                      :key="'wo-qty-' + index + '-' + (item.quantity || 0)"
                      :name="'WO_Qty' + index"
                      :class="formInputClass"
                      type="number"
                      :value="item.quantity || 0"
                      readonly="true"
                      :style="{ width: '100%', height: '32px !important' }"
                      :classes="{ outer: 'out-outer' }"
                    />
                  </div>

                  <div style="width: 70px">
                    <FormKit
                      :name="'Qty' + index"
                      type="number"
                      :validation="
                        'required|number|min:1|max:' + (item.stock || 0)
                      "
                      :validation-messages="{
                        required: '*',
                        min: '*',
                        max: '*',
                      }"
                      v-model="item.qty"
                      :style="{ width: '100%', height: '32px !important' }"
                      :classes="{ outer: 'out-outer' }"
                    />
                  </div>

                  <div class="flex gap-1" style="width: 50px">
                    <button
                      type="button"
                      class="inc-row-btn"
                      :title="$t('Add row')"
                      @click="handleAddRow(item, index)"
                    >
                      +
                    </button>
                    <button
                      type="button"
                      class="inc-row-btn inc-row-btn-danger"
                      :title="$t('Remove row')"
                      @click="handleRemoveRow(item, index)"
                    >
                      −
                    </button>
                  </div>
                </div>
              </div>
            </div>
            <div
              v-else-if="activeValue === 'documents'"
              class="w-[94%] font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <Documents
                :transaction_id="props.row"
                :handleUpload="handleUpload"
                :uploadedFiles="uploadedFiles"
                :editFiles="editFiles"
              />
            </div>
          </template>
        </BaseTabs>
      </FormKit>
    </div>
    <ModalPartsList
      :open="isModalPartOpen"
      :module="loadItem"
      :location="inputLocationValue?.id"
      :initialSearch="chooseBinnedSearch"
      :key="isModalPartOpen"
      :close="handleModalPartClose"
      :setPart="setPart"
      :multiSelect="false"
      :setMultipleParts="setMultipleParts"
    />

    <ModalItemsList
      :open="isModalWorkOrderOpen"
      collection="Work_order"
      title="Work Orders"
      :header="[
        { key: 'id', label: 'ID' },
        { key: 'name', label: 'Name' },
        { key: 'location.name', label: 'Location' },
        { key: 'action', label: 'Action', sortable: false },
      ]"
      :filter="work_order_filter"
      fields="*, location.name"
      :key="isModalWorkOrderOpen"
      :close="handleModalWorkOrderClose"
      :setItem="setWorkOrder"
    />
    <ConfirmModalForm
      code="Income"
      :text="$t('Do you close to this form?')"
      :successfullText="false"
      :open="isModalApproveConfirmOpen"
      :close="handleModalConfirmClose"
      :do_make="do_make"
    />
    <WarningModalForm
      :text="$t(isModalConfirmText)"
      code="Transaction"
      :open="isModalConfirmOpen"
      :close="handleModalConfirmClose"
    />
  </TairoModal>
</template>
<style>
.v-overlay {
  z-index: 10001 !important;
}
.OutcomeModal {
  width: 80%;
  max-width: 900px;
}

/* Outcome form inputs */
.outcomePopup .out-outer {
  margin-bottom: 0 !important;
}
.outcomePopup .nui-label,
.outcomePopup .out-outer [data-type] label,
.outcomePopup [class*='formkit-label'] {
  font-size: 10px !important;
  font-weight: 500;
  color: #94a3b8;
  margin-bottom: 2px !important;
  display: block;
  letter-spacing: 0.04em;
}

/* Uniform height + dashed borders on header inputs */
.outcomePopup .out-header-grid input,
.outcomePopup .out-header-grid textarea {
  height: 34px !important;
  font-size: 13px !important;
  width: 100% !important;

  box-sizing: border-box;
}
.outcomePopup .out-header-grid input:focus,
.outcomePopup .out-header-grid textarea:focus {
  border-style: solid !important;
  border-color: #8363ee !important;
  outline: none !important;
  box-shadow: none !important;
}
.outcomePopup .out-header-grid .vs__dropdown-toggle {
  height: 34px !important;
  width: 100% !important;
}
.outcomePopup .out-header-grid .vs--open .vs__dropdown-toggle {
  border-style: solid !important;
  border-color: #8363ee !important;
}
.outcomePopup .out-header-grid .mb-1.max-w-md {
  max-width: 100% !important;
  width: 100% !important;
}

/* Parts table layout (shared with income) */
.inc-table-head {
  display: flex;
  align-items: center;
}
.inc-col-label {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #9ca3af;
}
.inc-row {
  display: flex;
  align-items: flex-start;
}
.inc-add-btn {
  height: 28px !important;
  font-size: 12px !important;
  padding: 0 10px !important;
}
.inc-row-btn {
  width: 22px;
  height: 22px;
  line-height: 1;
  border-radius: 4px;
  font-size: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #e5e7eb;
  color: #374151;
  border: none;
  cursor: pointer;
  transition: background 0.15s;
}
.inc-row-btn:hover {
  background: #d1d5db;
}
.inc-row-btn-danger {
  background: #fee2e2;
  color: #dc2626;
}
.inc-row-btn-danger:hover {
  background: #fecaca;
}

/* Part autocomplete in Outcome rows */
.outcomePopup .out-part-outer .vs__dropdown-toggle {
  height: 32px;
  font-size: 12px;
}
.outcomePopup .out-part-outer {
  width: 150px !important;
}
.outcomePopup .out-part-outer .vs--open .vs__dropdown-toggle {
  border-style: solid !important;
  border-color: #8363ee !important;
}

.outcomePopup .inc-row input[type='number']:focus,
.outcomePopup .inc-row textarea:focus {
  border-style: solid !important;
  border-color: #8363ee !important;
}
.outcomePopup .inc-row input[readonly='true'] {
  background: #f8fafc !important;
  border-color: #e2e8f0 !important;
  color: #94a3b8 !important;
}
.outcomePopup .vs__selected-options {
  text-overflow: ellipsis !important;
  font-size: 12px;
}
.outcomePopup .vs__no-options,
.outcomePopup .vs__dropdown-option--disabled {
  font-size: 11px !important;
  line-height: 1.25;
  padding: 8px 10px;
}
.outcomePopup .vs__actions .vs__clear {
  display: none;
}
.outcomePopup .text-danger-500 {
  width: 90px;
  overflow: hidden;
  white-space: nowrap;
}
.outcomePopup .out-wo-more-btn {
  height: 32px !important;
  padding: 0 10px !important;
  font-size: 13px;
}
.outcomePopup .nui-button.nui-button-medium {
  padding: 0px 10px 0px 10px !important;
  height: 28px;
}
.mb-1.max-w-md:has(.outcome-submit-footer) {
  width: 100%;
  max-width: 100%;
}
.outcomePopup .outcome-submit-footer {
  position: sticky;
  bottom: 0;
  z-index: 5;
  padding-top: 10px;
  background: linear-gradient(to top, #ffffff 70%, rgba(255, 255, 255, 0));
}
.dark .outcomePopup .outcome-submit-footer {
  background: linear-gradient(to top, #111827 70%, rgba(17, 24, 39, 0));
}
</style>
