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
    qty: 0,
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
  work_order: Object,
  item: Object,
  code: String,
  last: Object,
  editPartRow: Object,
  refreshGrid: Function,
})

console.log('230', props.work_order)

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

  const woParts = rows.value.map((part) => ({
    // location: params.id,
    parts: part.choose_part.part_number?.id,
    work_order: props.work_order?.id,
    quantity: parseInt(part.qty),
    company_id: myCompanyId,
  }))

  console.log('woParts ->', woParts)

  const Work_order_Parts = await createItems({
    collection: 'Work_inpection_Parts',
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
    @close="askModalClose"
  >
    <template #header>
      <!-- Header -->
      <div class="flex items-center justify-between p-2 md:p-2">
        <div
          class="flex font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white pl-8"
        >
          {{ `Parts` }}
        </div>
        <BaseButtonClose @click="handleModalClose" />
      </div>
    </template>

    <!-- Body -->
    <div class="income rows-container flex mx-auto h-[350px] px-5">
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
          class="rowsContainer overflow-auto h-[280px] font-sans text-sm text-gray-500 dark:text-gray-400"
        >
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
                <BaseButton
                  color="default"
                  :class="index > 0 ? 'mr-1' : 'mt-6 mr-1'"
                  @click="handleAddRow('Parts', index)"
                >
                  +
                </BaseButton>

                <FormKit
                  :name="'part' + index"
                  type="autocomplete2"
                  collection_name="Asset_Parts"
                  :label="index > 0 ? '' : 'Parts:'"
                  :change_filter="newVal"
                  :initial_filter="{
                    location: params.id,
                    asset: props.work_order?.asset?.id,
                  }"
                  :initial_break="true"
                  item_fields="part.*"
                  item_value="part_number"
                  item_title="part_number"
                  search_field="part_number"
                  search_collection="part"
                  :validation="'required'"
                  :validation-messages="{ required: '*' }"
                  :style="{ width: '180px' }"
                  v-model="item.choose_part.part_number"
                  :setValue="setValue"
                  :setEmplyValue="{
                    part_number: '',
                    description: '',
                  }"
                  :item_index="index"
                />
                <BaseButton
                  color="default"
                  :class="index > 0 ? 'ml-1' : 'mt-6 ml-1'"
                  @click="handleModalPartOpen('Parts', index)"
                >
                  ...
                </BaseButton>
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
                :label="index > 0 ? '' : 'Description:'"
                :validation="'required'"
                :validation-messages="{ required: '*' }"
                :style="{
                  width: '150px',
                  maxWidth: '180px',
                  height: '28px',
                  marginRight: '5px',
                  fontSize: '12px',
                }"
                v-model="item.choose_part.part_number.description"
              />
              <FormKit
                :name="'Qty' + index"
                type="number"
                :label="index > 0 ? '' : 'Qty:'"
                :validation="'required|number|min:1'"
                :validation-messages="{
                  required: '*',
                  min: '*',
                }"
                v-model="item.qty"
                :style="{
                  width: '80px',
                  height: '28px !important',
                }"
              />
              <FormKit v-model="item.old_qty" name="Qty" type="hidden" />
              <BaseButton
                color="default"
                :class="index > 0 ? ' ml-1' : 'mt-6  ml-1'"
                @click="handleRemoveRow(item, index)"
              >
                -
              </BaseButton>
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
.income .nui-button.nui-button-medium {
  padding: 0px 10px 0px 10px !important;
  height: 28px;
}
.income .parts .vs__dropdown-toggle {
  height: 28px;
}

.income .v-select.vs--single {
  /* width: 320px !important;
  margin-right: 10px; */
}
.income .vs__selected-options {
  width: 150px !important;
  text-overflow: ellipsis !important;
}
.income .vs__selected-options {
  width: 150px !important;
  text-overflow: ellipsis !important;
  font-size: 12px;
}
.income .vs__actions .vs__clear {
  /* position: absolute;
  margin: 0px -20px;
  z-index: 10; */
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
