<script setup>
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const { open } = usePanels()

const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()
const stateMap = ref({})
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
const inputWoValue = ref('')

const isModalConfirmText = ref('')
const inputSupplierValue = ref('')
const isModalConfirmOpen = ref(false)
const isModalOpen = ref(false)
const newVal = ref(false)
const work_order = ref(false)
const rowParts = ref([])

const rows = ref([
  {
    parts: {
      part_number: '',
      description: '',
      qty: 0,
      id: null,
      price: 0,
    },
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
  item: Object,
  code: String,
  last: Object,
  editPartRow: Object,
})

// Scroll контейнерийг тодорхойлох ref
const rowsContainer = ref(null)

const handleAddRow = (item, index) => {
  const newRow = {
    parts: {
      part_number: '',
      description: '',
      qty: 0,
      id: null,
    },
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

const setEmptyRow = () => {
  inputNameValue.value = ''
  inputDateValue.value = ''
  inputLocationValue.value = ''
  inputSupplierValue.value = ''
  inputWoValue.value = ''
  uploadedFiles.value = ''
  rows.value = [
    {
      parts: {
        part_number: '',
        description: '',
        qty: 0,
        id: null,
      },
      price: 0,
      qty: 0,
    },
  ]
}

const handleUpload = async (items) => {
  uploadedFiles.value = items
}

const formInputClass = computed(() => {
  //console.log('formInputClass', props.last)
  return 'form_inputs'
})

const stateName = (code) =>
  code != null ? stateMap.value[String(code)] ?? String(code) : '—'

// Work_order_Parts дээрх тухайн part-ын төлөвлөсөн (анхны) state:
// { [partId]: part_state }
const woPartStateMap = ref({})

const woStateFor = (item) => {
  const pid = item?.part?.id
  if (pid == null) return null
  return woPartStateMap.value[String(pid)] ?? null
}

// Work_order дээрх анхны state, transaction дээр бодитоор сонгосон state
// хоёр зөрж байгаа эсэх
const hasStateMismatch = (item) => {
  const woState = woStateFor(item)
  return (
    woState != null &&
    item?.part_state != null &&
    String(woState) !== String(item.part_state)
  )
}

onMounted(async () => {
  // Load state names
  try {
    const stateRes = await getItems({
      collection: 'States',
      params: {
        filter: { company_id: myCompanyId },
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

  //console.log('part_number', props.row)
  //console.log('editPartRow', props.editPartRow)
  //console.log('editPartRow structure:')
  if (props.editPartRow && props.editPartRow.length > 0) {
    //console.log('First editPartRow item:', props.editPartRow[0])
    //console.log('quantity:', props.editPartRow[0]?.quantity)
    //console.log('qty:', props.editPartRow[0]?.qty)
    //console.log('part:', props.editPartRow[0]?.part)
  }

  if (props.row) {
    inputNameValue.value = props.item?.name
    inputDateValue.value = props.item?.transaction_date?.split('T')[0]
    inputLocationValue.value = props.item?.location
    inputWoValue.value =
      ' #' +
      props.item?.work_order?.wo_number +
      '-' +
      props.item?.work_order?.name
    inputSupplierValue.value = props.item?.supplier
  }
  // Supplier only came as an id (not expanded) → fetch it so name shows
  const sup = props.item?.supplier
  if (sup != null && (typeof sup !== 'object' || sup.name == null)) {
    const supId = typeof sup === 'object' ? sup.id : sup
    if (supId != null) {
      try {
        const supRes = await getItems({
          collection: 'Supplier',
          params: { filter: { id: { _eq: supId } }, fields: ['*'], limit: 1 },
        })
        const supList = Array.isArray(supRes) ? supRes : supRes?.data ?? []
        if (supList.length) inputSupplierValue.value = supList[0]
      } catch (e) {
        console.warn('Failed to load supplier:', e)
      }
    }
  }

  // Work_order_Parts дээрх part тус бүрийн анхны (төлөвлөсөн) state-ийг татаж,
  // transaction дээр бодитоор сонгосон state-тэй харьцуулахад бэлдэнэ
  const woId =
    typeof props.item?.work_order === 'object'
      ? props.item?.work_order?.id
      : props.item?.work_order
  const partIds = (props.editPartRow || [])
    .map((r) => r.part?.id)
    .filter(Boolean)

  if (woId && partIds.length) {
    try {
      const woPartsRes = await getItems({
        collection: 'Work_order_Parts',
        params: {
          filter: {
            work_order: { _eq: woId },
            parts: { _in: partIds },
          },
          fields: ['parts', 'part_state'],
          limit: -1,
        },
      })
      const list = Array.isArray(woPartsRes)
        ? woPartsRes
        : woPartsRes?.data ?? []
      const map = {}
      for (const row of list) {
        const pid = typeof row.parts === 'object' ? row.parts?.id : row.parts
        if (pid != null) map[String(pid)] = row.part_state ?? null
      }
      woPartStateMap.value = map
    } catch (e) {
      console.warn('Failed to load Work_order_Parts states:', e)
    }
  }
})

const setLocation = (obj) => {
  chosedLocation.value = obj

  newVal.value = changeFilter1(
    chosedLocation.value?.id,
    inputLocationValue.value?.id,
    'part',
  )

  work_order.value = changeFilter1(
    chosedLocation.value?.id,
    inputLocationValue.value?.id,
    'work_order',
  )

  //console.log('setLocation', work_order.value, newVal.value)
}

const setParts = async (obj, item_index) => {
  //console.log('setParts', obj, item_index)
  loading.value = true

  if (obj) {
    try {
      const filters = {
        status: '1',
        work_order: obj.id,
      }
      const items = await getItems({
        collection: 'Work_order_Parts',
        params: {
          filter: filters,
          // limit: itemsPerPage,
          // page: page,
          meta: 'filter_count',
          fields: ['*', 'parts.*', 'work_order.* '],
        },
      })
      rows.value = items.data

      //console.log('rows', rows)
      //console.log('rows.value structure:', rows.value)
      if (rows.value.length > 0) {
        //console.log('First row sample:', rows.value[0])
        //console.log('quantity field:', rows.value[0]?.quantity)
      }
      loading.value = false
    } catch (e) {
      //console.log(e)
    }
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
  } else {
    let newValue = {
      parts: obj,
    }
    rows.value[index] = {
      ...rows.value[index],
      ...newValue,
    }
  }
}

const changeFilter1 = (newId, oldId, type) => {
  // //console.log('changeFilter1', newId, oldId)

  if (newId !== oldId) {
    if (type == 'work_order') {
      return {
        status: 1,
        location: newId,
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
    return false
  }
}

const changeFilter = computed(() => {
  //console.log(
  //   'changeFilter_fn',
  //   chosedLocation.value?.id,
  //   inputLocationValue.value?.id,
  // )

  if (chosedLocation.value?.id) {
    return {
      status: 1,
      location: chosedLocation.value?.id,
    }
  } else {
    return false
  }
})

const onClickedWo = () => {
  const item = props.item?.work_order
  if (!item?.id) return
  open('workorderopenmore', {
    id: item.id,
    data: item,
    // refresh: refreshGrid(),
  })
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
  <div
    v-if="module === 'Outcome'"
    class="outcome rows-container flex mx-auto max-h-[700px] px-6 py-5"
  >
    <FormKit
      type="form"
      :style="{ width: '100%' }"
      :actions="false"
      :submit-attrs="{
        wrapperClass: 'submit flex justify-end ',
      }"
    >
      <div
        ref="rowsContainer"
        class="rowsContainer overflow-auto h-[380px] font-sans text-sm text-gray-500 dark:text-gray-400"
      >
        <div class="">
          <div class="flex flex-col mx-[26px] border-b border-gray-500 pb-7">
            <div>
              <FormKit
                name="outcome_name"
                type="text"
                readonly="true"
                :label="t('Outcome name')"
                :validation="'required'"
                v-model="inputNameValue"
                :style="{
                  width: '582px',
                  height: '40px',
                }"
              />
            </div>

            <div class="flex">
              <div class="w-[400px] mr-2.5 location">
                <FormKit
                  name="location"
                  type="autocomplete2"
                  collection_name="Location"
                  :disabled="true"
                  :initial_filter="{
                    status: 1,
                  }"
                  :label="t('Location')"
                  item_value="id"
                  item_title="name"
                  search_field="name"
                  :validation="'required'"
                  v-model="inputLocationValue"
                  :setParentValue="setLocation"
                />
              </div>
              <FormKit
                name="transaction_date"
                :validation="'required'"
                type="date"
                :label="t('Transaction date')"
                :disabled="props.item?.status == 2 ? true : false"
                :style="{
                  width: '140px',
                  height: '36px',
                  marginRight: '10px',
                }"
                v-model="inputDateValue"
              />
            </div>

            <div class="flex work_order_select">
              <div class="work_order mr-2.5 cursor-pointer">
                <FormKit
                  name="work_order"
                  type="autocomplete2"
                  :disabled="true"
                  collection_name="Work_order"
                  :label="t('Work order')"
                  item_value="id"
                  item_title="name"
                  search_field="name"
                  :validation="'required'"
                  v-model="inputWoValue"
                  :change_filter="work_order"
                  :initial_break="true"
                  :setValue="setParts"
                />
              </div>
            </div>
          </div>
          <div class="pt-3 parts">
            <div
              v-for="(item, index) in props.row === -1
                ? rows
                : props.editPartRow"
              :key="index"
              class="row flex ml-1"
            >
              <div class="flex mr-3">
                <div
                  :class="
                    index > 0 ? 'w-[20px] mt-2 mr-1' : 'w-[20px] mt-8 mr-1'
                  "
                >
                  {{ `${index + 1}.` }}
                </div>
                <FormKit
                  :name="'part' + index"
                  readonly="true"
                  type="text"
                  collection_name="Transaction_parts"
                  :label="index > 0 ? '' : t('Part')"
                  :change_filter="newVal"
                  :initial_break="true"
                  item_fields="*, part.*, transaction_id.*"
                  item_value="id"
                  :value="item.part?.part_number || 0"
                  :item_index="index"
                  :style="{
                    width: '180px',
                    height: '28px',
                    marginRight: '5px',
                    fontSize: '12px',
                  }"
                />
              </div>

              <FormKit
                :name="'description' + index"
                readonly="true"
                type="textarea"
                :label="index > 0 ? '' : t('Description')"
                :validation="'required'"
                :value="item.part?.description || 0"
                :style="{
                  width: '280px',
                  maxWidth: ' 280px',
                  height: '28px',
                  marginRight: '5px',
                  fontSize: '12px',
                }"
              />
              <!-- WO Qty Work_order_Parts collection-оос ирсэн quantity field -->
              <FormKit
                :name="'WO Qty' + index"
                :class="formInputClass"
                type="number"
                :label="index > 0 ? '' : t('WO Qty')"
                :value="item?.quantity || 0"
                readonly="true"
                :style="{
                  width: '80px',
                  height: '28px !important',
                  marginRight: '5px',
                }"
              />
              <!-- Out Qty: гэдэг нь үнэхээр гаргаж өгсөн тоо ширхэгийг харуулна - transaction дээр хичнээн ширхэг гаргасныг заана. -->
              <FormKit
                :name="'Qty' + index"
                type="number"
                :label="index > 0 ? '' : t('Out Qty')"
                :value="item?.qty || 0"
                :validation="'required|number|min:1'"
                readonly="true"
                :style="{
                  width: '80px',
                  height: '28px !important',
                }"
              />
              <!-- State -->
              <div
                :class="index > 0 ? '' : ''"
                style="width: full; margin-left: 5px"
              >
                <label
                  v-if="index === 0"
                  class="text-[14px] text-[#94a3b8] font-medium text-muted-700 dark:text-muted-200 block mb-1"
                >
                  {{ t('State') }}
                </label>
                <div
                  v-if="hasStateMismatch(item)"
                  class="flex items-center gap-1"
                >
                  <span
                    class="text-[10px] px-1 py-0.5 rounded leading-snug line-through text-muted-400 bg-muted-100 dark:bg-muted-800"
                    :title="
                      t('Planned state') + ': ' + stateName(woStateFor(item))
                    "
                  >
                    {{ stateName(woStateFor(item)) }}
                  </span>
                  <Icon name="ph:arrow-right" class="h-3 w-3 text-muted-400" />
                  <span
                    class="text-[11px] px-1.5 py-0.5 rounded leading-snug bg-warning-100 dark:bg-warning-900/30 text-warning-700 dark:text-warning-300"
                    :title="
                      t('Actual state used') + ': ' + stateName(item.part_state)
                    "
                  >
                    {{ stateName(item.part_state) }}
                  </span>
                </div>
                <span
                  v-else
                  class="part_state text-[11px] px-1.5 py-0.5 rounded leading-snug truncate inline-block max-w-full align-bottom"
                  :title="stateName(item.part_state)"
                  :class="
                    item.part_state
                      ? 'bg-info-100 dark:bg-info-900/30 text-info-700 dark:text-info-300'
                      : 'text-muted-400'
                  "
                >
                  {{ stateName(item.part_state) }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </FormKit>
  </div>

  <div v-else-if="module === 'Income'" class="px-6 py-5">
    <div
      class="rounded-2xl border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 shadow-sm overflow-hidden"
    >
      <!-- Card header -->
      <div
        class="flex items-center gap-3 px-5 py-4 bg-gradient-to-r from-primary-50 to-violet-50 dark:from-primary-900/20 dark:to-violet-900/20 border-b border-muted-100 dark:border-muted-700"
      >
        <div
          class="h-10 w-10 rounded-xl bg-primary-500/15 dark:bg-primary-500/25 flex items-center justify-center flex-shrink-0"
        >
          <Icon name="ph:arrow-circle-down" class="h-5 w-5 text-primary-500" />
        </div>
        <div>
          <p
            class="text-[10px] font-semibold uppercase tracking-widest text-muted-400"
          >
            {{ t('Income name') }}
          </p>
          <p
            class="text-base font-bold text-muted-900 dark:text-white leading-tight"
          >
            {{ inputNameValue || '—' }}
          </p>
        </div>
      </div>

      <!-- Fields grid -->
      <div
        class="grid grid-cols-2 gap-0 divide-x divide-muted-100 dark:divide-muted-700"
      >
        <!-- Supplier -->
        <div class="flex items-start gap-3 p-5">
          <div
            class="h-9 w-9 rounded-lg bg-violet-500/10 dark:bg-violet-500/20 flex items-center justify-center flex-shrink-0 mt-0.5"
          >
            <Icon name="ph:buildings" class="h-4 w-4 text-violet-500" />
          </div>
          <div>
            <p
              class="text-[10px] font-semibold uppercase tracking-widest text-muted-400 mb-1"
            >
              {{ t('Supplier') }}
            </p>
            <span
              class="inline-flex items-center rounded-full bg-violet-100 dark:bg-violet-900/30 px-2.5 py-0.5 text-xs font-semibold text-violet-700 dark:text-violet-300"
            >
              {{ inputSupplierValue?.name || '—' }}
            </span>
          </div>
        </div>

        <!-- Transaction Date -->
        <div class="flex items-start gap-3 p-5">
          <div
            class="h-9 w-9 rounded-lg bg-sky-500/10 dark:bg-sky-500/20 flex items-center justify-center flex-shrink-0 mt-0.5"
          >
            <Icon name="ph:calendar-check" class="h-4 w-4 text-sky-500" />
          </div>
          <div>
            <p
              class="text-[10px] font-semibold uppercase tracking-widest text-muted-400 mb-1"
            >
              {{ t('Transaction Date') }}
            </p>
            <p class="text-sm font-semibold text-muted-900 dark:text-white">
              {{ inputDateValue || '—' }}
            </p>
          </div>
        </div>

        <!-- Location (full row) -->
        <div
          class="col-span-2 flex items-start gap-3 px-5 py-4 border-t border-muted-100 dark:border-muted-700 bg-muted-50/50 dark:bg-muted-800/30"
        >
          <div
            class="h-9 w-9 rounded-lg bg-emerald-500/10 dark:bg-emerald-500/20 flex items-center justify-center flex-shrink-0 mt-0.5"
          >
            <Icon name="ph:map-pin-area" class="h-4 w-4 text-emerald-500" />
          </div>
          <div>
            <p
              class="text-[10px] font-semibold uppercase tracking-widest text-muted-400 mb-1"
            >
              {{ t('Location') }}
            </p>
            <p class="text-sm font-semibold text-muted-900 dark:text-white">
              {{ inputLocationValue?.name || '—' }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<style>
.v-overlay {
  z-index: 10001 !important;
}

.outcome .nui-button.nui-button-medium {
  padding: 0px 10px 0px 10px !important;
  height: 28px;
}
.outcome .parts .vs__dropdown-toggle {
  height: 28px;
}

.outcome .v-select.vs--single {
  /* width: 320px !important;
  margin-right: 10px; */
}
.outcome .vs__selected-options {
  width: 150px !important;
  text-overflow: ellipsis !important;
  font-size: 12px;
}
.outcome .work_order_select,
.outcome .supp_select,
.outcome .location {
  width: 435px !important;
}

.outcome .dark span {
  color: white;
}

.outcome .dark .vs--disabled .vs__dropdown-toggle,
.outcome .dark .vs--disabled .vs__clear,
.outcome .dark .vs--disabled .vs__search,
.outcome .dark .vs--disabled .vs__selected,
.outcome .dark .vs--disabled .vs__open-indicator {
  background-color: unset !important;
}

.outcome .location .vs--disabled.dark .vs__dropdown-toggle,
.outcome .location .vs--disabled.dark .vs__search {
  background-color: unset !important;
}
.outcome .work_order_select .vs__selected-options,
.outcome .supp_select .vs__selected-options,
.outcome .location .vs__selected-options {
  width: 400px !important;
  text-overflow: ellipsis !important;
}
.outcome .work_order_select .mb-1.max-w-md,
.outcome .supp_select .mb-1.max-w-md,
.outcome .location .mb-1.max-w-md {
  width: 100%;
  max-width: 100%;
}
.outcome .vs__actions .vs__clear {
  /* position: absolute;
  margin: 0px -20px;
  z-index: 10; */
  display: none;
}
.outcome .text-danger-500 {
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
