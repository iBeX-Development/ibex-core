<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

import { useForm } from 'vee-validate'
import { statuses } from '~/components/workorder/ProjectConstants'
import Documents from './Documents.vue'

const config = useRuntimeConfig()
const { deleteUsers } = useDirectusUsers()
const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const { token } = useDirectusToken()
const myCompanyId = getMyCompanyId()

const type = ref('')
const uploadedFiles = ref([])
const editFiles = ref([])
let updateData = ref({})

const contract_amount = ref('')
const tax_rate = ref('')
const contract_name = ref('')
const contract_code = ref('')
const start_date = ref('')
const due_date = ref('')
const project_leaders = ref([])
const description = ref('')
const delegate = ref('')
const agreement = ref(1)
const agreement_options = ref([
  { value: 1, text: 'CPA -Contract Purchase Agreement' },
  { value: 2, text: 'BPA -Blanket Purchase Agreement' },
])

const currency = ref()
const currency_options = ref([
  { value: 1, text: 'MNT' },
  { value: 2, text: 'USD' },
  { value: 3, text: 'CNY' },
])

const payment = ref()
const payment_options = ref([])

const income = ref()
const income_options = ref([])

const isModalLeaderOpen = ref(false)
const isModalMemberOpen = ref(false)
const isModalConfirmText = ref('')
const isModalConfirmOpen = ref(false)
const isError = ref(false)

const props = defineProps({
  open: Boolean,
  company: Number,
  code: String,
  close: Function,
  refresh: Function,
  clear: Function,
  editRow: Object,
  row: Object,
})
const success = ref(false)
const rows = ref([
  {
    meeting: {
      title: '',
      type: '',
      position: '',
      colorCode: '',
    },
  },
])
const stateValue = ref({
  value: 0,
  text: 'New',
  icon: 'mdi:progress-clock',
})

// Scroll контейнерийг тодорхойлох ref
const rowsContainer = ref(null)

// Modify initial values to handle dynamic rows
const initialValues = computed(() => ({
  module: props.editRow
    ? [
        {
          id: 1,
          name: 'Work order',
          text: 'Your location work order',
          icon: 'ph:buildings-duotone',
          module_key: 'work_order',
        },
      ]
    : '',
  rows: rows.value.map((row) => ({
    meeting: {
      title: row.meeting.title,
      position: row.meeting.position,
      type: row.meeting.type,
      colorCode: row.meeting.colorCode,
    },
  })),
}))

const {
  handleSubmit,
  isSubmitting,
  setFieldError,
  meta,
  values,
  errors,
  resetForm,
  setFieldValue,
  setErrors,
} = useForm({
  initialValues,
})

const emits = defineEmits<{
  (event: 'reset'): void
}>()

function onClick(item, type) {
  updateData.value = {
    ...updateData.value,
    [type]: item.value,
  }
  // console.log('updateData', updateData)
  // if (type == 'category') {
  //   updateData.value = { category: item.value }
  // } else if (type == 'wo_status') {
  //   updateData.value = { status: item.value }
  // } else if (type == 'type') {
  //   updateData.value = { type: item.value }
  // } else if (type == 'currency') {
  //   updateData.value = { currency: item.value }
  // } else if (type == 'payment') {
  //   updateData.value = { payment: item.value }
  // } else if (type == 'income') {
  //   updateData.value = { income: item.value }
  // }
}

const onSubmit = handleSubmit(async (values) => {
  success.value = false
  let error = false
  let errorMsg = ''
  console.log('Submit хийх боломжтой!', values)
  // console.log('stateValue!', updateData)

  let items = {
    active: 1,
    name: contract_name.value,
    status: updateData.value?.status,
    payment: updateData.value?.payment,
    income: updateData.value?.income,
    currency: updateData.value?.currency,
    code: contract_code.value,
    company: props.company,
    start_date: start_date.value,
    due_date: due_date.value,
    description: description.value,
    amount: contract_amount.value,
    tax_rate: tax_rate.value,
    agreement: agreement.value?.value,
    company_id: myCompanyId,
  }

  // if (uploadedFiles.value.length) {
  //     uploadedFiles.value.map(async (uploadedFile) => {
  //       const file_items = {
  //         transaction_id: res[0]?.id,
  //         file: uploadedFile.file.id,
  //       }

  //   }

  // console.log('edit_items.value.length', items)

  if (props.editRow != -1) {
    // console.log('edit_items', items)

    const res = await updateItem({
      collection: 'Contracts',
      id: props.editRow.id,
      item: items,
    })

    if (res) {
      let Id = res.id

      if (uploadedFiles.value.length) {
        uploadedFiles.value.map(async (uploadedFile) => {
          const file_items = {
            contract_id: res?.id,
            file: uploadedFile.file.id,
            company_id: myCompanyId,
          }

          const file_res = await createItems({
            collection: 'contracts_files',
            items: file_items,
          })

          // const deleted = await deleteItems({
          //   collection: 'contracts_files',
          //   items: {
          //     query: {
          //       filter: {
          //         transaction_id: props.row,
          //       },
          //     },
          //   },
          // })
        })
      }

      toaster.show({
        title: t('Updated'),
        message: t(`Record updated`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
    }

    resetModal()
  } else {
    // console.log('create', items)

    const res = await createItems({
      collection: 'Contracts',
      items: items,
    })

    if (res) {
      let Id = res.id

      if (uploadedFiles.value.length) {
        uploadedFiles.value.map(async (uploadedFile) => {
          const file_items = {
            contract_id: res?.id,
            file: uploadedFile.file.id,
            company_id: myCompanyId,
          }

          const file_res = await createItems({
            collection: 'contracts_files',
            items: file_items,
          })
        })
      }

      toaster.show({
        title: t('Added'),
        message: t(`Record created`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
    }

    resetModal()
    toaster.clearAll()
    toaster.show({
      title: t('Success'),
      message: t('Record has been created'),
      color: 'success',
      icon: 'ph:check',
      closable: true,
    })
  }
})

const resetModal = () => {
  // Reset rows to initial state
  contract_name.value = ''
  contract_code.value = ''
  start_date.value = ''
  due_date.value = ''
  description.value = ''
  delegate.value = ''
  uploadedFiles.value = []

  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''

  // Reset form
  resetForm()
  success.value = false
  setErrors({})

  // Reset scroll position if needed
  if (rowsContainer.value) {
    rowsContainer.value.scrollTop = 0
  }

  // Close modal
  props.close()
  props.refresh()
}

const handleUpload = async (items) => {
  // console.log('items', items)
  uploadedFiles.value = items
}

const transformType = (items) => {
  // console.log(items)
  const transformed_types = items.map((item) => ({
    text: item.code,
    value: item.id,
  }))

  return transformed_types
}

const loadCurrency = async () => {
  try {
    const filters = {}
    const items1 = await getItems<any>({
      collection: 'Currency',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    // currency.value = items.data
    currency_options.value = transformType(items1.data)
  } catch (e) {
    console.log(e)
  }
}

const loadPayment = async () => {
  try {
    const filters = {}
    const items2 = await getItems<any>({
      collection: 'Payment_term',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    // payment.value = items.data
    payment_options.value = transformType(items2.data)
  } catch (e) {
    console.log(e)
  }
}

const loadIncome = async () => {
  try {
    const filters = {}
    const items3 = await getItems<any>({
      collection: 'Income_term',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    // income.value = items.data
    income_options.value = transformType(items3.data)
  } catch (e) {
    console.log(e)
  }
}

onMounted(async () => {
  // console.log('props-edited', props)
  await loadCurrency()
  await loadPayment()
  await loadIncome()

  if (props.editRow) {
    contract_name.value = props.editRow.name
    contract_code.value = props.editRow.code
    contract_amount.value = props.editRow.amount
    tax_rate.value = props.editRow.tax_rate

    start_date.value = props.editRow.start_date?.split('T')[0]
    due_date.value = props.editRow.due_date?.split('T')[0]
    description.value = props.editRow.description
    if (props.editRow.agreement) {
      agreement.value = agreement_options.value.find(
        (p) => p.value == props.editRow.agreement,
      )
    }
    if (props.editRow.currency) {
      currency.value = currency_options.value.find(
        (p) => p.value == props.editRow.currency,
      )
    }
    if (props.editRow.income) {
      income.value = income_options.value.find(
        (p) => p.value == props.editRow.income,
      )
    }
    if (props.editRow.payment) {
      payment.value = payment_options.value.find(
        (p) => p.value == props.editRow.payment,
      )
    }

    let stateItem = statuses.find(
      (p) =>
        p.value == props.editRow.status || p.__original == props.editRow.status,
    )

    stateValue.value = {
      value: stateItem?.value,
      text: stateItem?.text,
      icon: stateItem?.icon,
    }
  }
})

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  isError.value = false
}

const handleModalLeaderClose = () => {
  isModalLeaderOpen.value = false
}

const handleModalMemberClose = () => {
  isModalMemberOpen.value = false
}
</script>

<template>
  <form
    action=""
    method="POST"
    @submit.prevent="onSubmit"
    class="mx-auto w-full max-w-3xl"
  >
    <TairoModal :open="props.open" size="2xl" @close="resetModal">
      <template #header>
        <!-- Header -->
        <div class="flex w-full items-center justify-between">
          <h3
            class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
          >
            &nbsp;
          </h3>

          <BaseButtonClose @click="resetModal" />
        </div>
      </template>

      <BaseTabs
        justify="end"
        type="box"
        model-value="info"
        class="tabs"
        :tabs="[
          { label: $t('Info'), value: 'info' },
          { label: $t('Documents'), value: 'documents' },
        ]"
      >
        <template #tab="{ activeValue }">
          <div
            ref="rowsContainer"
            v-if="activeValue === 'info'"
            class="rowsContainer Contract_about overflow-auto h-[440px] font-sans text-sm text-gray-500 dark:text-gray-400"
          >
            <div
              class="rowsContainer body w-[580px] h-[440px] grid mx-auto"
              ref="rowsContainer"
            >
              <div class="flex">
                <BaseListbox
                  :label="$t('State')"
                  size="sm"
                  class="status_item w-[280px]"
                  :items="statuses"
                  :properties="{
                    value: 'value',
                    label: 'text',
                    icon: 'icon', //baazaas awdag bolsonoos hoish zuraggui bolson
                  }"
                  :model-value="stateValue"
                  @update:model-value="onClick($event, 'status')"
                  rounded="md"
                  :disabled="false"
                />
                <BaseListbox
                  :label="$t('Agreement type')"
                  style="width: 285px; margin-left: 15px"
                  v-model="agreement"
                  :items="agreement_options"
                  :properties="{
                    value: 'value',
                    label: 'text',
                  }"
                  @update:model-value="onClick($event, 'currency')"
                  rounded="none"
                  size="sm"
                />
              </div>

              <BaseInput
                v-model="contract_name"
                :label="$t('Contract Name')"
                size="sm"
                rounded="none"
                type="string"
                class="border border-slate-300 rounded-[7px]"
              />

              <div class="flex">
                <BaseInput
                  v-model="contract_amount"
                  style="width: 280px"
                  class="border border-slate-300 rounded-[7px]"
                  :label="$t('Amount')"
                  size="sm"
                  rounded="none"
                  type="number"
                />
                <BaseListbox
                  :label="$t('Currency')"
                  style="width: 280px; margin-left: 15px"
                  v-model="currency"
                  :items="currency_options"
                  :properties="{
                    value: 'value',
                    label: 'text',
                  }"
                  @update:model-value="onClick($event, 'currency')"
                  rounded="none"
                  size="sm"
                />
              </div>

              <div class="flex">
                <BaseInput
                  style="width: 280px"
                  v-model="tax_rate"
                  :label="$t('Tax rate %')"
                  size="sm"
                  rounded="none"
                  type="number"
                  class="border border-slate-300 rounded-[7px]"
                />
                <BaseInput
                  v-model="contract_code"
                  style="width: 280px"
                  :label="$t('Contract Code')"
                  size="sm"
                  rounded="none"
                  type="string"
                  class="border border-slate-300 rounded-[7px]"
                  :classes="{
                    wrapper: 'w-full sm:w-auto ml-4',
                  }"
                />
              </div>

              <div class="flex">
                <BaseListbox
                  :label="$t('Payment term')"
                  size="sm"
                  class="status_item w-[280px]"
                  :items="payment_options"
                  :properties="{
                    value: 'value',
                    label: 'text',
                  }"
                  :model-value="payment"
                  @update:model-value="onClick($event, 'payment')"
                  rounded="md"
                  :disabled="false"
                />
                <BaseListbox
                  :label="$t('Income term')"
                  style="width: 280px; margin-left: 15px"
                  v-model="income"
                  @update:model-value="onClick($event, 'income')"
                  :items="income_options"
                  :properties="{
                    value: 'value',
                    label: 'text',
                  }"
                  rounded="none"
                  size="sm"
                />
              </div>

              <div class="flex items-center w-full max-w-md mb-1">
                <div class="w-full">
                  <BaseInput
                    v-model="start_date"
                    :label="$t('Start date')"
                    size="sm"
                    rounded="none"
                    type="date"
                    :classes="{
                      wrapper: 'w-[280px]',
                    }"
                  />
                </div>
                <div class="w-full ml-4">
                  <BaseInput
                    v-model="due_date"
                    :label="$t('Due date')"
                    size="sm"
                    rounded="none"
                    type="date"
                    :classes="{
                      wrapper: 'w-[280px]',
                    }"
                  />
                </div>
              </div>
              <div class="project_description flex mb-5">
                <BaseTextarea
                  v-model="description"
                  class="description h-[44px]"
                  contrast="default-contrast"
                  size="sm"
                  :label="$t('Description')"
                  rounded="md"
                  :placeholder="$t('Write a description...')"
                  color-focus
                />
              </div>
            </div>
          </div>
          <div
            v-else-if="activeValue === 'documents'"
            class="h-[440px] w-[94%] p-2.5 m-auto overflow-auto font-sans text-sm text-gray-500 dark:text-gray-400"
          >
            <Documents
              :item_id="props.editRow?.id"
              :handleUpload="handleUpload"
              :uploadedFiles="uploadedFiles"
              :editFiles="editFiles"
            />
          </div>

          <!-- Modal Footer -->
          <div
            class="shadow-muted-300/30 dark:shadow-muted-800/30 flex items-center justify-end gap-2 m-[25px]"
          >
            <BaseButton type="reset" shape="rounded" @click="resetModal">
              <span>{{ $t('Close') }}</span>
            </BaseButton>
            <BaseButton
              type="submit"
              shape="rounded"
              color="primary"
              @click="
                () => {
                  onSubmit()
                }
              "
            >
              <span>{{ $t('Save') }}</span>
            </BaseButton>
          </div>
        </template>
      </BaseTabs>
    </TairoModal>
  </form>
</template>

<style>
.rowsContainer .templates,
.rowsContainer .options {
  margin-top: 10px;
}

.rowsContainer .templates .nui-radio {
  margin-bottom: 8px;
}
.rowsContainer .options {
  /* border-left: 1px solid gray; */
}
.rowsContainer .options .InputBox {
  width: 80%;
  margin: auto;
}

.rowsContainer .snackBox {
  width: 360px;
  border: 1px solid #cdd5e0;
  height: auto;
  min-height: 38px;
  max-height: 120px;
  overflow-y: auto;
  overflow-x: hidden;
  border-radius: 0.375rem;
  align-items: center;
  padding: 10px;
}
.rowsContainer .placeholder-leader {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}

.rowsContainer .placeholder-leader:empty::before {
  content: 'Project leader';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}

.rowsContainer .placeholder-members {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}
.rowsContainer .placeholder-members:empty::before {
  content: 'Project members';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}
.rowsContainer .snackBox .nui-snack {
  border: 1px solid #c1bebe;
}

.rowsContainer .snackBox .nui-button-close {
  height: 24px !important;
}

.project_description .nui-textarea-wrapper {
  width: 100%;
}
</style>
