<script setup>
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import WarningModalForm from '~/components/form/WarningModalForm.vue'

import ModalPartsList from '~/components/parts/ModalPartsList.vue'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()
const { params } = useRoute()

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
    qty: '',
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
  item: Object,
  code: String,
  last: Object,
  editPartRow: Object,
  refreshGrid: Function,
})

// Scroll контейнерийг тодорхойлох ref
const rowsContainer = ref(null)

const handleModalPartClose = () => {
  isModalPartOpen.value = false
}

const handleModalPartOpen = (item, index) => {
  isModalPartOpen.value = true
  rowIndex.value = index
  // setPart({ id: null, name: '' })
  loadItem.value = item
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
    qty: '',
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
    price: 0,
    qty: 0,
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
    },
  ]
}

// Parts_Amounts.asset_amount cache байхгүй боллоо — асаж хадгалдаг байсан
// updateStock()-ыг устгав. asset_amount одоо parts/location жагсаалт дээр
// Asset_Parts-аас шууд live тооцогддог тул энд синк хийх шаардлагагүй.

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

  const newParts = rows.value.map((part) => ({
    location: params.id,
    part: part.choose_part.part_number?.id,
    asset: props.asset_id,
    quantity: parseInt(part.qty),
    company_id: myCompanyId,
  }))

  console.log('newParts ->', newParts)

  // Тухайн asset дээр эдгээр part-ууд аль хэдийн байгаа эсэхийг шалгах
  const partIds = newParts.map((p) => p.part).filter((id) => id != null)
  const existingItems = partIds.length
    ? await getItems({
        collection: 'Asset_Parts',
        params: {
          filter: {
            asset: props.asset_id,
            part: { _in: partIds },
          },
          fields: ['id', 'part', 'quantity'],
        },
      })
    : { data: [] }
  const existingRows = Array.isArray(existingItems)
    ? existingItems
    : existingItems?.data ?? []
  const existingByPart = new Map(existingRows.map((row) => [row.part, row]))

  const toCreate = []

  for (const part of newParts) {
    const match = existingByPart.get(part.part)
    if (match) {
      // Байгаа part бол шинэ утгаар нь replace хийж update хийнэ
      await updateItem({
        collection: 'Asset_Parts',
        id: match.id,
        item: { quantity: part.quantity },
      })
    } else {
      toCreate.push(part)
    }
  }

  if (toCreate.length) {
    await createItems({
      collection: 'Asset_Parts',
      items: toCreate,
    })
  }

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
    @close="askModalClose"
  >
    <template #header>
      <div class="flex items-center justify-between px-5 py-3">
        <div class="flex items-center gap-2.5">
          <div
            class="h-8 w-8 rounded-lg bg-primary-500/10 dark:bg-primary-500/20 flex items-center justify-center flex-shrink-0"
          >
            <Icon name="ph:package" class="h-4 w-4 text-primary-500" />
          </div>
          <span
            class="font-heading text-base font-semibold text-muted-900 dark:text-white"
            >{{ props.title || t('Parts') }}</span
          >
        </div>
        <BaseButtonClose @click="handleModalClose" />
      </div>
    </template>

    <!-- Body -->
    <div class="asset_parts flex flex-col w-full min-h-[300px]">
      <!-- Scrollable content -->
      <div class="flex-1 overflow-y-auto px-5 pt-2 pb-0">
        <FormKit
          id="asset-part-form"
          type="form"
          :actions="false"
          :style="{ width: '100%' }"
          @submit="submitHandler"
        >
          <!-- Column headers -->
          <div
            class="flex items-center gap-1.5 mb-2 pt-2 px-3 border-b border-muted-100 dark:border-muted-700 pb-2"
          >
            <div class="w-5"></div>
            <div class="w-7"></div>
            <div
              class="w-[185px] text-[10px] font-semibold uppercase tracking-widest text-muted-400"
            >
              PARTS
            </div>
            <div class="w-7"></div>
            <div
              class="flex-1 text-[10px] font-semibold uppercase tracking-widest text-muted-400"
            >
              DESCRIPTION
            </div>
            <div
              class="w-[82px] text-[10px] font-semibold uppercase tracking-widest text-muted-400"
            >
              QTY
            </div>
            <div class="w-7"></div>
          </div>

          <div
            ref="rowsContainer"
            class="rowsContainer max-h-[380px] space-y-1.5 py-1 font-sans text-sm text-gray-500 dark:text-gray-400"
          >
            <div
              v-for="(item, index) in props.row === -1
                ? rows
                : props.editPartRow"
              :key="index"
              class="flex items-center gap-1.5 rounded-lg border border-muted-100 dark:border-muted-700 bg-white dark:bg-muted-900 px-2 py-1 hover:border-primary-200 dark:hover:border-primary-700/60 transition-colors duration-150"
            >
              <!-- Row number -->
              <div
                class="w-5 text-center text-xs font-medium text-muted-400 flex-shrink-0"
              >
                {{ index + 1 }}
              </div>

              <!-- Add row button -->
              <button
                type="button"
                class="h-6 w-7 rounded-md bg-primary-50 dark:bg-primary-900/20 text-primary-500 hover:bg-primary-100 dark:hover:bg-primary-900/40 flex items-center justify-center text-base font-bold flex-shrink-0 transition-colors"
                @click="handleAddRow('Parts', index)"
              >
                +
              </button>

              <!-- Part autocomplete -->
              <FormKit
                :name="'part' + index"
                type="autocomplete2"
                collection_name="Parts"
                :label="''"
                :change_filter="newVal"
                :initial_filter="{ status: 1, company_id: myCompanyId }"
                :initial_break="true"
                item_value="part_number"
                item_title="part_number"
                search_field="part_number"
                :validation="'required'"
                :style="{ width: '150px', minWidth: '150px' }"
                :classes="{ outer: '!w-[150px] !max-w-[150px]' }"
                v-model="item.choose_part.part_number"
                :setValue="setValue"
                :setEmplyValue="{
                  part_number: '',
                  description: '',
                }"
                :item_index="index"
              />

              <!-- Expand button -->
              <button
                type="button"
                class="h-6 w-7 rounded-md bg-muted-100 dark:bg-muted-700 text-muted-500 hover:bg-muted-200 dark:hover:bg-muted-600 flex items-center justify-center text-xs flex-shrink-0 transition-colors font-medium tracking-tight"
                @click="handleModalPartOpen('Parts', index)"
              >
                ···
              </button>

              <FormKit
                :validation="'required'"
                v-model="item.choose_part.part_number"
                :name="'part_' + index"
                type="hidden"
              />

              <!-- Description -->
              <FormKit
                :name="'description' + index"
                type="textarea"
                :label="''"
                :classes="{ outer: '!flex-1 !max-w-none !w-auto' }"
                :style="{
                  height: '36px',
                  marginTop: '5px',
                  fontSize: '12px',
                }"
                v-model="item.choose_part.part_number.description"
              />

              <!-- Qty -->
              <FormKit
                :name="'Qty' + index"
                type="number"
                :label="''"
                :validation="'required|number|min:1'"
                v-model="item.qty"
                :classes="{ message: '!hidden', messages: '!hidden' }"
                :style="{
                  width: '82px',
                  height: '36px !important',
                }"
              />
              <FormKit v-model="item.old_qty" name="Qty" type="hidden" />

              <!-- Remove row button -->
              <button
                type="button"
                class="h-6 w-7 rounded-md bg-rose-50 dark:bg-rose-900/20 text-rose-400 hover:bg-rose-100 dark:hover:bg-rose-900/40 hover:text-rose-600 flex items-center justify-center text-base font-bold flex-shrink-0 transition-colors"
                @click="handleRemoveRow(item, index)"
              >
                −
              </button>
            </div>
          </div>
        </FormKit>
      </div>

      <!-- Sticky footer -->
      <div
        class="flex-shrink-0 border-t border-muted-100 dark:border-muted-700 px-5 py-3 flex justify-end bg-white dark:bg-muted-900"
      >
        <button
          type="submit"
          form="asset-part-form"
          class="text-sm px-6 py-2 rounded bg-primary-500 hover:bg-primary-400 text-white font-medium shadow-sm hover:shadow-primary-500/40 transition-all duration-200"
        >
          {{ t('Save') }}
        </button>
      </div>

      <ModalPartsList
        :open="isModalPartOpen"
        module="Parts"
        :key="isModalPartOpen"
        :index="rowIndex"
        :close="handleModalPartClose"
        :setPart="setPart"
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
.asset_parts .nui-button.nui-button-medium {
  padding: 0px 10px 0px 10px !important;
  height: 28px;
}
.asset_parts .parts .vs__dropdown-toggle {
  height: 28px;
}

.asset_parts .v-select.vs--single {
  /* width: 320px !important;
  margin-right: 10px; */
}
.asset_parts .vs__selected-options {
  width: 150px !important;
  text-overflow: ellipsis !important;
}
.asset_parts .vs__selected-options {
  width: 150px !important;
  text-overflow: ellipsis !important;
  font-size: 12px;
}
.asset_parts .vs__actions .vs__clear {
  display: none;
}
.asset_parts [data-type='autocomplete2'] .vs__open-indicator {
  display: none !important;
}
.asset_parts .text-danger-500 {
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
