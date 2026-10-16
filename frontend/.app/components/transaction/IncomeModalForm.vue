<script setup>
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
const { t } = useI18n({ useScope: 'global' })

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
const uploadedFiles = ref([])
const editFiles = ref([])
const chosedLocation = ref([])
const inputNameValue = ref('')
const inputDateValue = ref('')
const inputLocationValue = ref('')
const isModalConfirmText = ref('')
const inputSupplierValue = ref('')
const locationDisable = ref(false)
const isModalConfirmOpen = ref(false)
const isModalOpen = ref(false)
const newVal = ref(false)
const isModalApproveConfirmOpen = ref(false)

const stateOptions = ref([])

const rows = ref([
  {
    choose_part: {
      part_number: { part_number: '', description: '' },
      id: null,
    },
    price: 0,
    qty: 0,
    part_state: '',
  },
])

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
  location: Number,
  item: [Object, Number],
  code: String,
  last: Object,
  editPartRow: [Array, Number],
})

// Scroll контейнерийг тодорхойлох ref
const rowsContainer = ref(null)

const handleModalPartClose = () => {
  isModalPartOpen.value = false
}

const handleModalPartOpen = (item) => {
  isModalPartOpen.value = true
  loadItem.value = item
}

const setMultipleParts = (selectedParts) => {
  const newRows = selectedParts.map((part) => ({
    choose_part: {
      part_number: {
        id: part.id,
        part_number: part.part_number,
        description: part.name || part.description || '',
      },
      id: part.id,
    },
    price: part.price || 0,
    qty: 1,
    part_state: '',
  }))

  const target = props.row === -1 ? rows.value : props.editPartRow
  // Replace empty placeholder row if only one empty row exists
  if (target.length === 1 && !target[0].choose_part.part_number.part_number) {
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

const handleModalClose = () => {
  isModalPartOpen.value = false
  isModalApproveConfirmOpen.value = false
  locationDisable.value = false

  setEmptyRow()
  props.close()
}

const handleAddRow = (item, index) => {
  const newRow = {
    choose_part: {
      part_number: { part_number: '', description: '' },
      id: null,
    },
    price: 0,
    qty: 0,
    part_state: '',
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
    if (props.editPartRow.length > 1) props.editPartRow.splice(index, 1)
  }
}

const setPart = (obj) => {
  choose_part.value = obj
}

const updateDescription = (index) => {
  const part = rows.value[index]?.choose_part

  if (part && part.name) {
    rows.value[index].description = part.name.description
    return part.name.description
  }
}

const setEmptyRow = () => {
  inputNameValue.value = ''
  inputDateValue.value = ''
  inputLocationValue.value = ''
  inputSupplierValue.value = ''
  uploadedFiles.value = ''
  locationDisable.value = false

  rows.value = [
    {
      choose_part: {
        part_number: { part_number: '', description: '' },
        id: null,
      },
      price: 0,
      qty: 0,
      part_state: '',
    },
  ]
}

const generateNumber = async (codec) => {
  try {
    console.log(token.value, codec)
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
  console.log(_commodity)
  commodity.value = _commodity
  await setItem('segment')
  await setItem('family')
  await setItem('class')
  await generateNumber(_commodity?.codec)
  // item_description.value = numbering.value + ' ' + segment?.value.description + ' ' +
  //  family?.value.description + ' ' + _class?.value.description + ' ' + commodity?.value.description;
}

// Parts_Amounts.income_amount cache байхгүй боллоо — асаж хадгалдаг байсан
// updateStock()-ыг устгав. income_amount одоо parts/location жагсаалт болон
// warehouse дээр Transaction_parts-аас шууд live тооцогддог тул энд синк
// хийх шаардлагагүй.

const submitHandler = async (values) => {
  console.log('values ->', values)
  console.log('rows', rows.value)
  // console.log(' props.row ->', props.row)
  console.log('editPartRow ->', props.editPartRow)
  // console.log('uploadedFiles ->', uploadedFiles)

  // console.log('inputDateValue ->', inputDateValue.value)
  // console.log('inputLocationValue.value ->', inputLocationValue.value)
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
  if (!inputSupplierValue.value) {
    isModalConfirmOpen.value = true
    isModalConfirmText.value = 'Please supplier name!'
    return
  }

  if (props.module === 'Income') {
    location_id = inputLocationValue.value?.id
    itemsValue['transaction_type'] = 'INCOME'
    itemsValue['location'] = inputLocationValue.value?.id
    itemsValue['supplier'] = inputSupplierValue.value?.id
    itemsValue['name'] = inputNameValue.value
    itemsValue['transaction_date'] = inputDateValue.value
  } else {
    return
  }

  let items = [{ ...itemsValue, company_id: myCompanyId }]

  if (props.row === -1) {
    const res = await createItems({ collection: props.code, items })

    if (res) {
      let Id = res[0].id
      const newParts = rows.value.map((part) => ({
        transaction_id: Id,
        part: part.choose_part.part_number?.id,
        transaction_type: 'income',
        price: parseInt(part.price),
        qty: parseInt(part.qty),
        part_state: part.part_state ? Number(part.part_state) : null,
        company_id: myCompanyId,
      }))

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

      toaster.show({
        title: t('Added'),
        message: t(`Record created successfully`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
    }
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

    console.log('editPartRow ->', props.editPartRow)
    const newParts = props.editPartRow.map((part) => ({
      transaction_id: props.row,
      transaction_type: 'income',
      part: part.choose_part.part_number?.id,
      price: parseInt(part.price),
      qty: parseInt(part.qty),
      old_qty: parseInt(part.old_qty),
      part_state: part.part_state ? Number(part.part_state) : null,
      company_id: myCompanyId,
    }))

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

    toaster.show({
      title: t('Updated'),
      message: t(`Record updated successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })

    // income_amount live тооцогддог тул edit хийхэд Parts_Amounts синк хийх
    // шаардлагагүй болсон.
  }

  if (props.refresh) {
    console.log('Props refresh 2...')
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
  console.log('formInputClass', props.last)
  return 'form_inputs'
})

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalApproveConfirmOpen.value = false
}

onMounted(async () => {
  // Load Part_state options
  try {
    const stateRes = await getItems({
      collection: 'States',
      params: {
        filter: { company_id: { _eq: myCompanyId } },
        fields: ['id', 'name'],
        sort: ['name'],
        limit: -1,
      },
    })
    const stateList = Array.isArray(stateRes) ? stateRes : stateRes?.data ?? []
    stateOptions.value = [
      { value: '', label: '—' },
      ...stateList.map((s) => ({ value: s.id, label: s.name })),
    ]
  } catch (e) {
    console.warn('Failed to load States:', e)
  }

  if (props.row) {
    inputNameValue.value = props.item?.name
    inputDateValue.value = props.item?.transaction_date?.split('T')[0]
    inputLocationValue.value = props.item?.location
    inputSupplierValue.value = props.item?.supplier
  }
  console.log('props.location', props.location)
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

    console.log('inputLocationValue', inputLocationValue)
  }
})

watch(locationDisable, async () => {
  console.log('watch changed:', locationDisable.value)
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

  console.log('inputLocationValue', inputLocationValue)
})

const setLocation = (obj) => {
  chosedLocation.value = obj

  console.log(
    'setLocationsdsdsdsd',
    chosedLocation.value,
    inputLocationValue.value?.id,
  )

  newVal.value = changeFilter1(
    chosedLocation.value?.id,
    inputLocationValue.value?.id,
  )
}

const setValue = (obj, item_index) => {
  console.log('setValue', obj, item_index)
  if (!obj) {
    let index = item_index.value

    if (rows.value[index]) {
      let newValue = {
        choose_part: {
          part_number: {
            part_number: '',
            description: '',
          },
          id: 1,
        },
        price: 0,
        qty: 0,
      }

      rows.value[index] = {
        ...rows.value[index],
        ...newValue,
      }
    }
  }
}

const changeFilter1 = (newId, oldId) => {
  console.log('changeFilter1', newId, oldId)

  if (newId !== oldId) {
    return {
      status: '1',
      location: newId,
    }
  } else {
    if (props.location) {
      return {
        status: '1',
        location: props.location,
      }
    } else return false
  }
}

const changeFilter = computed(() => {
  console.log(
    'changeFilter_fn',
    chosedLocation.value?.id,
    inputLocationValue.value?.id,
  )

  if (chosedLocation.value?.id) {
    return {
      status: '1',
      location: chosedLocation.value?.id,
    }
  } else {
    return false
  }
})

const do_make = async (item, type) => {
  handleModalClose()
}

const askModalClose = () => {
  isModalApproveConfirmOpen.value = true
  console.log('askModalClose', rows.value.length)
}

// watch(chosedLocation, () => {
//   console.log('watch changed:', chosedLocation.value?.id)

//   return {
//     'chosedLocation.value.id': function (newId, oldId) {
//       console.log('watch changed2:', newId, oldId)

//       if (newId !== oldId) {
//         console.log('newId changed:', newId, oldId)
//       }
//     },
//   }
// })
</script>

<template>
  <!-- New & Edit modal -->
  <TairoModal
    :classes="{ dialog: 'transactionModal' }"
    :key="props.key"
    :open="props.open"
    @close="askModalClose"
  >
    <template #header>
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div
          class="addIncome flex font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white pl-8"
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
    <div
      class="income rows-container flex mx-auto max-h-[700px] h-[560px] px-5"
    >
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
          wrapperClass: 'submit flex justify-end',
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
              class="rowsContainer overflow-auto h-[420px] font-sans text-sm"
            >
              <!-- Info header -->
              <div
                class="grid grid-cols-4 gap-3 p-4 bg-gray-50 dark:bg-muted-900 rounded"
              >
                <div class="col-span-4">
                  <FormKit
                    name="income_name"
                    type="text"
                    :label="t('Income name')"
                    :validation="'required'"
                    validation-label="*"
                    v-model="inputNameValue"
                    :classes="{
                      input: 'inc-input',
                      outer: 'inc-outer',
                      label: 'inc-label',
                    }"
                  />
                </div>
                <div>
                  <FormKit
                    name="transaction_date"
                    :validation="'required'"
                    validation-label="*"
                    type="date"
                    :label="t('Date')"
                    v-model="inputDateValue"
                    :classes="{
                      input: 'inc-input',
                      outer: 'inc-outer',
                      label: 'inc-label',
                    }"
                    style="height: 36px"
                  />
                </div>
                <div class="col-span-2">
                  <FormKit
                    name="location"
                    type="autocomplete2"
                    collection_name="Location"
                    :initial_filter="{ status: 1 }"
                    :label="t('Location')"
                    item_value="id"
                    item_title="name"
                    search_field="name"
                    :validation="'required'"
                    validation-label="*"
                    v-model="inputLocationValue"
                    :setParentValue="setLocation"
                    :disabled="locationDisable"
                    :classes="{ outer: 'inc-outer', label: 'inc-label' }"
                  />
                </div>
                <div>
                  <FormKit
                    name="supplier"
                    type="autocomplete2"
                    collection_name="Supplier"
                    className="supplier"
                    :label="t('Supplier')"
                    item_value="id"
                    item_title="name"
                    search_field="name"
                    :validation="'required'"
                    validation-label="*"
                    v-model="inputSupplierValue"
                    :classes="{ outer: 'inc-outer', label: 'inc-label' }"
                  />
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
                  <BaseButton
                    size="sm"
                    class="inc-add-btn"
                    @click="handleModalPartOpen('Parts')"
                  >
                    <Icon name="ph:plus-bold" class="me-1 size-3" />
                    {{ t('Add Parts') }}
                  </BaseButton>
                </div>

                <!-- Column headers -->
                <div class="inc-table-head flex gap-1 mb-1 px-1">
                  <span class="inc-col-label" style="width: 20px">#</span>
                  <span class="inc-col-label" style="flex: 1">{{
                    t('Part')
                  }}</span>
                  <span class="inc-col-label" style="width: 110px">{{
                    t('State')
                  }}</span>
                  <span class="inc-col-label" style="width: 160px">{{
                    t('Description')
                  }}</span>
                  <span class="inc-col-label" style="width: 80px">{{
                    t('Price')
                  }}</span>
                  <span class="inc-col-label" style="width: 56px">{{
                    t('Qty')
                  }}</span>
                  <span style="width: 50px"></span>
                </div>

                <!-- Rows -->
                <div
                  v-for="(item, index) in props.row === -1
                    ? rows
                    : props.editPartRow"
                  :key="index"
                  class="inc-row flex gap-1 items-start mb-1 px-1 py-0.5 rounded hover:bg-gray-50 dark:hover:bg-muted-800"
                >
                  <span
                    class="text-xs text-gray-400 text-right pr-1"
                    style="width: 20px"
                    >{{ index + 1 }}</span
                  >

                  <div>
                    <FormKit
                      :name="'part' + index"
                      type="autocomplete2"
                      collection_name="Asset_Parts"
                      :change_filter="newVal"
                      :initial_break="true"
                      :initial_filter="{ status: '1' }"
                      item_fields="part.*"
                      item_value="part_number"
                      item_title="part_number"
                      search_field="part_number"
                      search_collection="part"
                      :validation="'required'"
                      :validation-messages="{ required: '*' }"
                      v-model="item.choose_part.part_number"
                      :setValue="setValue"
                      :setEmplyValue="{ part_number: '', description: '' }"
                      :item_index="index"
                      :classes="{ outer: 'inc-outer inc-part-outer' }"
                    />
                  </div>

                  <div style="width: 110px">
                    <FormKit
                      :name="'part_state' + index"
                      type="select"
                      :options="stateOptions"
                      v-model="item.part_state"
                      :style="{
                        width: '100%',
                        height: '32px',
                        fontSize: '11px',
                      }"
                      :classes="{ outer: 'inc-outer' }"
                    />
                  </div>

                  <div style="width: 210px; flex: 1">
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
                      v-model="item.choose_part.part_number.description"
                      :classes="{ outer: 'inc-outer' }"
                    />
                  </div>

                  <div style="width: 80px">
                    <FormKit
                      :name="'price' + index"
                      type="number"
                      :validation="'required|number|min:1'"
                      :validation-messages="{ required: '*', min: '*' }"
                      v-model="item.price"
                      :style="{ width: '100%', height: '32px !important' }"
                      :classes="{ outer: 'inc-outer' }"
                    />
                  </div>

                  <div style="width: 56px">
                    <FormKit
                      :name="'Qty' + index"
                      type="number"
                      :validation="'required|number|min:1'"
                      :validation-messages="{ required: '*', min: '*' }"
                      v-model="item.qty"
                      :style="{ width: '100%', height: '32px !important' }"
                      :classes="{ outer: 'inc-outer' }"
                    />
                  </div>
                  <FormKit v-model="item.old_qty" name="Qty" type="hidden" />

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
              class="h-[420px] w-[94%] overflow-auto font-sans text-sm text-gray-500 dark:text-gray-400"
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

      <ModalPartsList
        :open="isModalPartOpen"
        :module="loadItem"
        :key="isModalPartOpen"
        :close="handleModalPartClose"
        :setPart="setPart"
        :multiSelect="true"
        :setMultipleParts="setMultipleParts"
      />
    </div>
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
.transactionModal {
  width: 70%;
  max-width: 860px;
}

/* Income form inputs */
.income .inc-outer {
  margin-bottom: 0 !important;
}
.income .inc-part-outer {
  width: 150px !important;
}
.income .inc-label label,
.income .inc-outer [data-type] label,
.income [class*='formkit-label'] {
  font-size: 11px !important;
  font-weight: 500;
  margin-bottom: 2px !important;
}
.income .inc-input input,
.income .inc-input textarea {
  height: 32px;
  font-size: 12px;
}

/* Parts table layout */
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

/* Row +/- buttons */
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

/* Part autocomplete in row */
.income .inc-part-outer .vs__dropdown-toggle {
  height: 32px;
  font-size: 12px;
}
.income .vs__selected-options {
  text-overflow: ellipsis !important;
  font-size: 12px;
}
.income .vs__actions .vs__clear,
.income .vs__actions {
  display: none;
}
.income .text-danger-500 {
  width: 80px;
  overflow: hidden;
  white-space: nowrap;
}
.mb-1.max-w-md:has(.submit) {
  width: 100%;
  max-width: 100%;
  right: 22px;
  position: relative;
}
</style>
