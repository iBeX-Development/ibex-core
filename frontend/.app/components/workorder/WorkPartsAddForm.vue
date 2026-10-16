<script setup>
import { computed, onMounted, onUnmounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'

import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import WarningModalForm from '~/components/form/WarningModalForm.vue'

import ModalPartsList from '~/components/parts/ModalPartsList.vue'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()
const { params } = useRoute()
const { t } = useI18n({ useScope: 'global' })

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()
const isModalPartOpen = ref(false)
const chosedLocation = ref([])

const inputLocationValue = ref('')
const isModalConfirmText = ref('')
const isModalConfirmOpen = ref(false)
const isModalOpen = ref(false)
const newVal = ref(false)
const isModalApproveConfirmOpen = ref(false)

const choose_part = ref({
  id: null,
  name: { description: '' },
  part_number: { description: '', part_number: '' },
})

const rows = ref([
  {
    choose_part: {
      part_number: { part_number: '', description: '' },
      id: null,
    },
    price: 0,
    qty: 0,
    state: null,
  },
])

const serverItems = ref([])
const loading = ref(false)
const locationId = ref(1)
const loadItem = ref('')
const rowIndex = ref(0)

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
  asset_id: Number,
  work_order: Object,
  item: Object,
  code: String,
  last: Object,
  editPartRow: Object,
  refreshGrid: Function,
  collection: String,
})

const collectionName = computed(() => props.collection || 'Work_order_Parts')

const stateOptions = computed(() => [
  { value: '', label: '—' },
  ...Object.entries(stateMap.value).map(([id, name]) => ({
    value: Number(id),
    label: name,
  })),
])

const stateMap = ref({})
const stockInfoMap = ref({}) // { [partId]: { total, byState: [{name, qty}] } }
const _stockLoadingSet = new Set() // non-reactive, tracks in-progress fetches

const loadStates = async () => {
  try {
    const res = await getItems({
      collection: 'States',
      params: {
        filter: { company_id: { _eq: myCompanyId } },
        fields: ['id', 'name'],
        limit: -1,
      },
    })
    if (!isMounted) return
    const items = Array.isArray(res) ? res : res?.data ?? []
    const map = {}
    for (const s of items) map[String(s.id)] = s.name || String(s.id)
    stateMap.value = map
  } catch (e) {
    console.warn('Failed to load states:', e)
  }
}

const loadStockForPart = async (partId) => {
  if (!partId || partId in stockInfoMap.value || _stockLoadingSet.has(partId))
    return
  if (!isMounted) return
  const locId = modalLocationId.value
  if (!locId) return

  _stockLoadingSet.add(partId)

  try {
    const [tpRes, binRes, shiftRes] = await Promise.all([
      getItems({
        collection: 'Transaction_parts',
        params: {
          filter: {
            company_id: { _eq: myCompanyId },
            part: { _eq: partId },
            transaction_id: { location: { _eq: locId }, status: { _eq: 2 } },
          },
          fields: ['qty', 'transaction_type'],
          limit: -1,
        },
      }),
      getItems({
        collection: 'Parts_Bin_location',
        params: {
          filter: {
            part: { _eq: partId },
            status: { _neq: 'archived' },
            bin_location: { location: { _eq: locId } },
            company_id: { _eq: myCompanyId },
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
            part: { _eq: partId },
            _or: [
              { from_location: { _eq: locId } },
              { to_location: { _eq: locId } },
            ],
          },
          fields: ['qty', 'from_location', 'to_location'],
          limit: -1,
        },
      }),
    ])

    if (!isMounted) return

    const tpList = Array.isArray(tpRes) ? tpRes : tpRes?.data ?? []
    let income = 0
    let outcome = 0
    for (const tp of tpList) {
      const qty = parseInt(tp.qty) || 0
      const isIncome =
        tp.transaction_type === 'income' || tp.transaction_type === 'INCOME'
      if (isIncome) income += qty
      else outcome += qty
    }
    const shiftList = Array.isArray(shiftRes) ? shiftRes : shiftRes?.data ?? []
    for (const sh of shiftList) {
      const qty = parseInt(sh.qty) || 0
      const toId =
        typeof sh.to_location === 'object' ? sh.to_location?.id : sh.to_location
      const fromId =
        typeof sh.from_location === 'object'
          ? sh.from_location?.id
          : sh.from_location
      if (String(toId) === String(locId)) income += qty
      if (String(fromId) === String(locId)) outcome += qty
    }
    const total = income - outcome

    const binList = Array.isArray(binRes) ? binRes : binRes?.data ?? []
    const byStateMap = {} // { [sid]: { name, qty } }
    console.log('binList', binList)
    for (const b of binList) {
      const sid = String(b.transaction_parts?.part_state ?? '')
      const sname = stateMap.value[sid] || sid || '—'
      if (!byStateMap[sid]) byStateMap[sid] = { name: sname, qty: 0 }
      byStateMap[sid].qty += b.qty || 0
    }

    stockInfoMap.value[partId] = {
      total,
      byState: Object.entries(byStateMap).map(([sid, { name, qty }]) => ({
        id: sid ? Number(sid) : null,
        name,
        qty,
      })),
    }
    console.log('stockInfoMap', stockInfoMap)
  } catch (e) {
    console.warn('loadStockForPart error:', e)
    if (isMounted) stockInfoMap.value[partId] = { total: 0, byState: [] }
  } finally {
    _stockLoadingSet.delete(partId)
  }
}

let isMounted = false

onMounted(async () => {
  isMounted = true
  await loadStates()
})

onUnmounted(() => {
  isMounted = false
})

// Scroll контейнерийг тодорхойлох ref
const rowsContainer = ref(null)

const handleModalPartClose = () => {
  isModalPartOpen.value = false
}

const handleModalPartOpen = (item, index) => {
  isModalPartOpen.value = true
  rowIndex.value = typeof index === 'number' ? index : -1
  // setPart({ id: null, name: '' })
  loadItem.value = item
}

const setMultipleParts = (selectedParts) => {
  const newRows = selectedParts.map((part) => ({
    choose_part: {
      part_number: {
        id: part.id,
        part_number: part.part_number,
        description: part.name || part.description || '',
        price: part.price || 0,
      },
      id: part.id,
    },
    price: part.price || 0,
    qty: 1,
    state: null,
  }))

  const target = props.row === -1 ? rows.value : props.editPartRow

  if (
    target.length === 1 &&
    !target[0]?.choose_part?.part_number?.part_number
  ) {
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

  setEmptyRow()
  props.close()
}

const askModalClose = () => {
  isModalApproveConfirmOpen.value = true
  console.log('askModalClose', rows.value.length)
}

const handleAddRow = (item, index) => {
  const newRow = {
    choose_part: {
      part_number: { part_number: '', description: '' },
      id: null,
    },
    price: 0,
    qty: 0,
    state: null,
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

const setPart = (obj, index) => {
  let newValue = {
    choose_part: {
      part_number: obj,
      id: obj.id,
    },
    price: obj?.price || 0,
    qty: 0,
    state: null,
  }

  rows.value[index] = {
    ...newValue,
  }

  choose_part.value = obj
}

const setEmptyRow = () => {
  rows.value = [
    {
      choose_part: {
        part_number: { part_number: '', description: '' },
        id: null,
      },
      price: 0,
      qty: 0,
      state: null,
    },
  ]
}

const getRows = () => {
  return props.row === -1 ? rows.value : props.editPartRow || []
}

watch(
  () => getRows().map((r) => r.choose_part?.part_number?.id),
  (ids) => {
    for (const id of ids) {
      if (id) loadStockForPart(id)
    }
  },
)

const modalLocationId = computed(() => {
  const rawLocation =
    props.work_order?.location || props.work_order?.asset?.location

  if (!rawLocation) {
    return null
  }

  return typeof rawLocation === 'object' ? rawLocation.id : rawLocation
})

const handleAddPartRow = () => {
  handleModalPartOpen('Parts')
}

const getMaxIncomePrice = async (partId, state) => {
  if (!partId) return null
  try {
    const filter = {
      company_id: { _eq: myCompanyId },
      part: { _eq: partId },
      transaction_type: { _eq: 'income' },
    }
    if (state !== null && state !== undefined) {
      filter.part_state = { _eq: state }
    }

    const res = await getItems({
      collection: 'Transaction_parts',
      params: {
        filter,
        fields: ['price'],
        limit: -1,
      },
    })

    const list = Array.isArray(res) ? res : res?.data ?? []
    const prices = list
      .map((r) => Number(r.price))
      .filter((n) => !Number.isNaN(n))

    return prices.length ? Math.max(...prices) : null
  } catch (e) {
    console.warn('getMaxIncomePrice error:', e)
    return null
  }
}

const getPartPrice = async (partId) => {
  if (!partId) return 0
  try {
    const res = await getItems({
      collection: 'Parts',
      params: {
        filter: { id: { _eq: partId } },
        fields: ['price'],
        limit: 1,
      },
    })
    const list = Array.isArray(res) ? res : res?.data ?? []
    return Number(list[0]?.price) || 0
  } catch (e) {
    console.warn('getPartPrice error:', e)
    return 0
  }
}

const submitHandler = async (values) => {
  console.log('values ->', values)
  console.log('rows', rows.value)
  console.log('asset', props.row)
  // console.log(' props.row ->', props.row)
  console.log('editPartRow ->', props.editPartRow)
  // console.log('uploadedFiles ->', uploadedFiles)

  // console.log('inputLocationValue.value ->', inputLocationValue.value)

  toaster.clearAll()
  let itemsValue = {}
  let location_id = 0

  const woParts = await Promise.all(
    rows.value.map(async (part) => {
      const partId = part.choose_part.part_number?.id
      const state = part.state ? Number(part.state) : null

      const maxIncomePrice = await getMaxIncomePrice(partId, state)
      const price =
        maxIncomePrice !== null ? maxIncomePrice : await getPartPrice(partId)

      return {
        // location: params.id,
        parts: partId,
        work_order: props.work_order?.id,
        quantity: parseInt(part.qty),
        part_state: state,
        price,
        company_id: myCompanyId,
      }
    }),
  )

  console.log('woParts ->', woParts)

  const Work_order_Parts = await createItems({
    collection: collectionName.value,
    items: woParts,
  })

  toaster.show({
    title: t('Added'),
    message: t(`Record created successfully`) + '!',
    color: 'success',
    icon: 'ph:user-circle-fill',
    closable: true,
  })

  if (props.refreshGrid) {
    console.log('Props refreshGrid 2...')
    props.refreshGrid()
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

const formInputClass = computed(() => {
  console.log('formInputClass', props.last)
  return 'form_inputs'
})

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalApproveConfirmOpen.value = false
}

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
      status: 1,
      location: newId,
    }
  } else {
    return false
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
      status: 1,
      location: chosedLocation.value?.id,
    }
  } else {
    return false
  }
})

const do_make = async (item, type) => {
  handleModalClose()
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
    :classes="{ dialog: 'Part' }"
    :key="props.key"
    :open="props.open"
    size="2xl"
    @close="askModalClose"
  >
    <template #header>
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div
          class="flex font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white pl-2"
        >
          <Icon name="ph:gear-six" class="size-4 text-primary-500 m-1" />
          {{ t(props.title) || t('Parts') }}
        </div>
        <BaseButtonClose @click="handleModalClose" />
      </div>
    </template>

    <!-- Body -->
    <div class="PartModal rows-container flex mx-auto h-[350px] px-3">
      <FormKit
        type="form"
        :actions="true"
        :style="{ width: '100%' }"
        :submit-label="t('Save')"
        @submit="submitHandler"
        :submit-attrs="{
          inputClass:
            'text-sm px-5 mt-2 mb-5 py-2 is-button rounded bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
          ignore: false,
          wrapperClass: 'submit flex justify-end',
        }"
      >
        <div
          ref="rowsContainer"
          class="rowsContainer overflow-x-auto overflow-y-auto h-[280px] font-sans text-sm text-gray-500 dark:text-gray-400"
        >
          <div class="pt-3 parts">
            <div class="mb-2 flex items-center justify-between px-1">
              <h4 class="text-xs font-semibold tracking-wide text-muted-500">
                {{ t('PARTS') }}
              </h4>
              <BaseButton
                color="primary"
                class="h-8 px-3 text-xs"
                @click="handleAddPartRow"
              >
                <Icon name="ph:plus-bold" class="me-1 h-3 w-3" />
                {{ t('Add Parts') }}
              </BaseButton>
            </div>

            <div
              class="parts-grid-header mb-2 grid w-full max-w-full grid-cols-[28px_minmax(0,1.2fr)_minmax(0,1.4fr)_minmax(0,0.9fr)_minmax(0,0.8fr)_72px_56px] gap-1 rounded-md bg-muted-100 px-2 py-2 text-[11px] font-semibold uppercase tracking-wide text-muted-500 dark:bg-muted-800"
            >
              <div>#</div>
              <div>{{ t('Part') }}</div>
              <div>{{ t('Description') }}</div>
              <div class="text-center">{{ t('Stock') }}</div>
              <div>{{ t('State') }}</div>
              <div>{{ t('Qty') }}</div>
              <div>{{ t('') }}</div>
            </div>

            <div
              v-for="(item, index) in getRows()"
              :key="index"
              class="parts-grid-row mb-2 grid w-full max-w-full grid-cols-[28px_minmax(0,1.2fr)_minmax(0,1.4fr)_minmax(0,0.9fr)_minmax(0,0.8fr)_72px_56px] items-start gap-1 rounded-md border border-muted-200 p-2 dark:border-muted-700"
            >
              <div class="pt-1 text-center text-sm text-muted-500">
                {{ index + 1 }}
              </div>

              <div class="flex items-start gap-1">
                <FormKit
                  :name="'part' + index"
                  type="autocomplete2"
                  collection_name="Parts_Amounts"
                  :label="''"
                  :change_filter="newVal"
                  :initial_filter="{
                    location: params.id,
                  }"
                  :style="{
                    width: '100%',
                    height: '32px',
                    fontSize: '12px',
                  }"
                  :initial_break="true"
                  item_fields="part.*"
                  item_value="part_number"
                  item_title="part_number"
                  search_field="part_number"
                  search_collection="part"
                  :validation="'required'"
                  :validation-messages="{ required: '*' }"
                  v-model="item.choose_part.part_number"
                  :setValue="setValue"
                  :setEmplyValue="{
                    part_number: '',
                    description: '',
                  }"
                  :item_index="index"
                />

                <FormKit
                  :validation="'required'"
                  v-model="item.choose_part.part_number"
                  :name="'part_' + index"
                  type="hidden"
                />
              </div>

              <FormKit
                :name="'description' + index"
                type="textarea"
                :label="''"
                :validation="'required'"
                :validation-messages="{ required: '*' }"
                :style="{
                  width: '100%',
                  height: '32px',
                  fontSize: '12px',
                }"
                v-model="item.choose_part.part_number.description"
              />

              <!-- Stock column -->
              <div class="pt-1 text-center text-xs leading-tight">
                <template v-if="item.choose_part?.part_number?.id">
                  <template
                    v-if="stockInfoMap[item.choose_part.part_number.id]"
                  >
                    <div
                      class="font-semibold text-muted-700 dark:text-muted-300"
                    >
                      {{ stockInfoMap[item.choose_part.part_number.id].total }}
                    </div>
                    <div
                      v-if="
                        stockInfoMap[item.choose_part.part_number.id].byState
                          .length
                      "
                      class="text-[10px] font-medium uppercase tracking-wide text-primary-400"
                    >
                      {{ t('binned') }}
                    </div>
                    <div
                      v-for="s in stockInfoMap[item.choose_part.part_number.id]
                        .byState"
                      :key="s.name"
                      class="text-[10px] text-muted-400"
                    >
                      {{ s.name }}: {{ s.qty }}
                    </div>
                  </template>
                  <span v-else class="text-muted-300">—</span>
                </template>
                <span v-else class="text-muted-300">—</span>
              </div>

              <!-- State column -->
              <div>
                <select
                  v-model="item.state"
                  class="w-full rounded border border-muted-200 bg-white px-1 py-1 text-xs text-muted-700 focus:border-primary-400 focus:outline-none dark:border-muted-600 dark:bg-muted-800 dark:text-muted-200"
                  style="height: 32px"
                >
                  <option :value="null">—</option>
                  <template
                    v-if="
                      item.choose_part?.part_number?.id &&
                      stockInfoMap[item.choose_part.part_number.id]?.byState
                        ?.length
                    "
                  >
                    <option
                      v-for="s in stockInfoMap[item.choose_part.part_number.id]
                        .byState"
                      :key="s.id"
                      :value="s.id"
                    >
                      {{ s.name }} ({{ s.qty }})
                    </option>
                  </template>
                  <template v-else>
                    <option
                      v-for="opt in stateOptions"
                      :key="opt.value"
                      :value="opt.value || null"
                    >
                      {{ opt.label }}
                    </option>
                  </template>
                </select>
              </div>

              <FormKit
                :name="'Qty' + index"
                type="number"
                :label="''"
                :validation="'required|number|min:1'"
                :validation-messages="{
                  required: '*',
                  min: '*',
                }"
                v-model="item.qty"
                :style="{
                  width: '100%',
                  height: '32px !important',
                }"
              />

              <FormKit v-model="item.old_qty" name="Qty" type="hidden" />

              <div class="flex items-center gap-1">
                <BaseButton
                  class="inc-row-btn"
                  @click="handleAddRow('Parts', index)"
                >
                  +
                </BaseButton>
                <BaseButton
                  class="inc-row-btn inc-row-btn-danger"
                  @click="handleRemoveRow(item, index)"
                >
                  −
                </BaseButton>
              </div>
            </div>
          </div>
        </div>
      </FormKit>

      <ModalPartsList
        :open="isModalPartOpen"
        module="Parts"
        :key="isModalPartOpen"
        :index="rowIndex"
        :close="handleModalPartClose"
        :setPart="setPart"
        :location="modalLocationId"
        :multiSelect="true"
        :setMultipleParts="setMultipleParts"
      />
    </div>
    <WarningModalForm
      :text="$t(isModalConfirmText)"
      code="Transaction"
      :open="isModalConfirmOpen"
      :close="handleModalConfirmClose"
    />
    <ConfirmModalForm
      code="Parts"
      :text="$t('Do you close to this form?')"
      :successfullText="false"
      :open="isModalApproveConfirmOpen"
      :close="handleModalConfirmClose"
      :do_make="do_make"
    />
  </TairoModal>
</template>
<style>
.v-overlay {
  z-index: 10001 !important;
}
.transactionModal {
  width: 68%;
}
.PartModal .nui-button.nui-button-medium {
  padding: 4px !important;
  height: 32px;
}
.PartModal .parts .nui-input {
  min-height: 32px;
}
.PartModal .parts .vs__dropdown-toggle {
  height: 32px;
}

.PartModal .parts-grid-row .text-danger-500,
.PartModal .parts-grid-header .text-danger-500 {
  width: auto;
}

@media (max-width: 1024px) {
  .PartModal .parts-grid-header,
  .PartModal .parts-grid-row {
    grid-template-columns:
      24px minmax(0, 1.15fr) minmax(0, 1.35fr) minmax(0, 0.85fr)
      64px 52px;
  }
}

.PartModal .vs__selected-options {
  width: 100% !important;
  min-width: 0 !important;
  text-overflow: ellipsis !important;
}
.PartModal .vs__selected-options {
  width: 100% !important;
  min-width: 0 !important;
  text-overflow: ellipsis !important;
  font-size: 12px;
}
.PartModal .vs__actions .vs__clear {
  /* position: absolute;
  margin: 0px -20px;
  z-index: 10; */
  display: none;
}
.PartModal .text-danger-500 {
  width: 80px;
  overflow: hidden;
  white-space: nowrap;
}

/* Row +/- buttons */
.PartModal .parts-grid-row .inc-row-btn {
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
.PartModal .parts-grid-row .inc-row-btn:hover {
  background: #d1d5db;
}
.PartModal .parts-grid-row .inc-row-btn-danger {
  background: #fee2e2;
  color: #dc2626;
}
.PartModal .parts-grid-row .inc-row-btn-danger:hover {
  background: #fecaca;
}

.mb-1.max-w-md:has(.submit) {
  width: 100%;
  max-width: 100%;
  right: 0;
  position: static;
}
</style>
