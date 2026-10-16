<script setup>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'

import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import WarningModalForm from '~/components/form/WarningModalForm.vue'

const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()
const { t } = useI18n({ useScope: 'global' })

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const toaster = useToaster()
const myCompanyId = getMyCompanyId()
const props = defineProps({
  open: Boolean,
  title: String,
  collection: String,
  module: String,
  close: Function,
  clear: Function,
  refresh: Function,
  row: Number,
  item: Object,
  code: String,
  last: Object,
  editRow: Object,
  work_order: Number || String,
})

// Scroll контейнерийг тодорхойлох ref
const rowsContainer = ref(null)

const isModalConfirmText = ref('')
const isModalConfirmOpen = ref(false)
const isModalApproveConfirmOpen = ref(false)

const inputNameValue = ref('')
const description = ref('')
const repeatCount = ref(1) // Анхны утга: 1
const inputScheduleTypesValue = ref('private')
const inputRepeatTypesValue = ref('direct')
const inputRepeatUnitValue = ref('daily')
const schedule_types = ['public', 'private']
const repeat_types = ['direct', 'completed']
const repeat_unit = ['daily', 'weekly', 'monthly', 'yearly']
const daysOfWeek = [
  { value: 1, label: 'Monday' },
  { value: 2, label: 'Tuesday' },
  { value: 3, label: 'Wednesday' },
  { value: 4, label: 'Thursday' },
  { value: 5, label: 'Friday' },
  { value: 6, label: 'Saturday' },
  { value: 7, label: 'Sunday' },
]

// hour
let repeatCountDailyHourMin = 1
let repeatCountDailyHourMax = 23

let repeatCountMonthlyMin = 1
let repeatCountMonthlyMax = 28

let repeatCountWeeklyMin = 1
let repeatCountWeeklyMax = 7

let repeatCountYearlyMin = 1
let repeatCountYearlyMax = 10

const repeat_counts = ref([
  {
    month: 0, //yearly
    date: 0,
    hour: 0,
    min: 0,
  },
])

const handleModalClose = () => {
  isModalApproveConfirmOpen.value = false
  isModalConfirmOpen.value = false
  setEmptyRow()
  props.clear()
  props.close()
}

const setEmptyRow = () => {
  inputNameValue.value = ''
  inputRepeatUnitValue.value = 'daily'
  inputRepeatTypesValue.value = 'direct'

  repeatCount.value = null
  repeat_counts.value = [
    {
      month: 0,
      date: 0,
      hour: 0,
      min: 0,
    },
  ]
}

const getSelectedDaysAndTimes = () => {
  // console.log('repeat_counts_items', repeat_counts)

  const selectedDaysAndTimes = repeat_counts.value.map((item) => ({
    month: parseInt(item.month) || 0,
    date: parseInt(item.date) || 0,
    hour: parseInt(item.hour) || 0,
    min: parseInt(item.min) || 0,
  }))

  return selectedDaysAndTimes
}

const submitHandler = async (values) => {
  // console.log('values ->', values)
  // console.log(' props.row ->', props.row)
  // console.log('editRow ->', props.editRow)
  // console.log('Selected Days and Times:', getSelectedDaysAndTimes())

  // console.log('Form values:', values)
  // console.log('Name:', inputNameValue.value) // For name
  // console.log('Repeat Types:', inputRepeatTypesValue.value) // For repeat types
  // console.log('Repeat Unit:', inputRepeatUnitValue.value) // For repeat unit
  // console.log('Repeat Count:', repeatCount.value) // For repeat count

  toaster.clearAll()
  let itemsValue = {}

  if (!inputNameValue.value) {
    isModalConfirmOpen.value = true
    isModalConfirmText.value = 'Please insert name!'

    return
  }

  if (!inputRepeatTypesValue.value) {
    isModalConfirmOpen.value = true
    isModalConfirmText.value = 'Please select repeat type!'
    return
  }
  if (!inputRepeatUnitValue.value) {
    isModalConfirmOpen.value = true
    isModalConfirmText.value =
      'Please repeat unit( daily, weekly, monthly ...)!'
    return
  }

  // if (!repeatCount.value) {
  //   isModalConfirmOpen.value = true
  //   isModalConfirmText.value = 'Please repeat count!'
  //   return
  // }

  itemsValue['type'] = 'private'
  itemsValue['name'] = inputNameValue.value
  itemsValue['work_order'] = props.work_order
  itemsValue['repeat_types'] = inputRepeatTypesValue.value
  itemsValue['repeat_unit'] = inputRepeatUnitValue.value
  itemsValue['repeat'] = repeatCount.value
  itemsValue['description'] = description.value

  itemsValue['schedules_date'] = getSelectedDaysAndTimes()
  itemsValue['company_id'] = myCompanyId
  // console.log('itemsValue', itemsValue)

  let items = [itemsValue]

  if (props.row === -1) {
    const res = await createItems({ collection: props.collection, items })
    if (res) {
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
      collection: props.collection,
      id: props.row,
      item: itemsValue,
    }
    await updateItem(data)

    toaster.show({
      title: t('Updated'),
      message: t(`Record updated successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }

  handleModalClose()
  props.refresh()
}
const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalApproveConfirmOpen.value = false
}

onMounted(async () => {
  if (props.row !== -1) {
    // If it's in edit mode
    inputNameValue.value = props.editRow?.name || ''
    inputRepeatUnitValue.value = props.editRow?.repeat_unit || 'daily'
    inputRepeatTypesValue.value = props.editRow?.repeat_types || 'direct'
    repeatCount.value = props.editRow?.repeat || 1
    repeat_counts.value = props.editRow?.schedules_date || [
      {
        month: 0,
        date: 0,
        hour: 0,
        min: 0,
      },
    ]
  }
})

const do_make = async (item, type) => {
  handleModalClose()
}

const askModalClose = () => {
  isModalApproveConfirmOpen.value = true
}

const onRepeatTypesChange = (value) => {
  // console.log('dad', value, inputRepeatTypesValue.value)
  if (value === 'completed') {
    repeat_counts.value = [{ date: 0, month: 0, hour: 0, min: 0 }]
  } else {
    repeat_counts.value = [
      {
        month: 0,
        date: 0,
        hour: 0,
        min: 0,
      },
    ]
  }
}

const onScheduleTypesChange = (value) => {
  console.log('onScheduleTypesChange', value, inputScheduleTypesValue.value)
  if (value === 'public') {
    console.log('ds1', value)
  } else {
    console.log('ds2', value)
  }
}

// 🔹 repeat_counts-ийг эхлүүлнэ
function updateRepeatDates() {
  // console.log('updateRepeatDates_schedule', inputRepeatUnitValue)
  // console.log('repeatCount.value ', repeatCount.value)
  // if (inputRepeatUnitValue.value == 'daily' && props.row !== -1) return

  // Check if editRow is available and has schedules_date
  if (
    props.editRow &&
    Array.isArray(props.editRow.schedules_date) &&
    props.editRow.schedules_date.length > 0
  ) {
    // If editRow.schedules_date exists and is not empty, use it
    inputNameValue.value = props.editRow.name
    inputRepeatUnitValue.value = props.editRow.repeat_unit
    inputRepeatTypesValue.value = props.editRow.repeat_types
    repeatCount.value = props.editRow.repeat
    repeat_counts.value = [...props.editRow.schedules_date] // Clone the array to avoid mutation
  } else {
    // If schedules_date is not available or is empty, generate default values
    repeat_counts.value = Array.from(
      { length: repeatCount.value }, // Length based on repeatCount
      (_, index) => ({
        month: 0,
        date: 0, // Default date
        hour: 0, // Default hour
        min: 0, // Default hour
      }),
    )
  }

  // Ensure the number of entries matches repeatCount if not set
  if (repeat_counts.value.length !== repeatCount.value) {
    let maxCnt = repeatCount.value

    if (
      inputRepeatUnitValue.value == 'daily' &&
      repeatCount.value > repeatCountDailyHourMax
    ) {
      repeatCount.value = repeatCountDailyHourMax
    }
    if (
      inputRepeatUnitValue.value == 'weekly' &&
      repeatCount.value > repeatCountWeeklyMax
    ) {
      maxCnt = repeatCountWeeklyMax
    }
    if (
      inputRepeatUnitValue.value == 'monthly' &&
      repeatCount.value > repeatCountMonthlyMax
    ) {
      maxCnt = repeatCountMonthlyMax
    }
    if (
      inputRepeatUnitValue.value == 'yearly' &&
      repeatCount.value > repeatCountYearlyMax
    ) {
      maxCnt = repeatCountYearlyMax
    }

    repeat_counts.value = Array.from({ length: maxCnt }, (_, index) => ({
      month: 0,
      date: 0,
      hour: 0,
      min: 0,
    }))
  }

  // if (inputRepeatUnitValue.value == 'daily')
  //   repeat_counts.value = [
  //     {
  //       date: 1,
  //       hour: 10,
  //     },
  //   ]

  // console.log('repeat_counts after update:', repeat_counts.value)
}

function inputRepeatUnit() {
  // Check if editRow is available and has schedules_date
  repeatCount.value = 1
  console.log('inputRepeatUnitValue:', inputRepeatUnitValue)
}

// 🔹 repeat_count өөрчлөгдөх үед шинэчлэх
watch(inputRepeatUnitValue, inputRepeatUnit, { immediate: true })
watch(repeatCount, updateRepeatDates, { immediate: true })
</script>

<template>
  <!-- New & Edit modal -->
  <TairoModal
    :classes="{ dialog: 'scheduleModal' }"
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
          {{ t(title) + `&nbsp;` }}
        </div>
        <BaseButtonClose @click="handleModalClose" />
      </div>
    </template>

    <!-- Body -->
    <div
      class="schedule rows-container flex mx-auto max-h-[700px] h-[520px] px-5"
    >
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
          class="rowsContainer overflow-auto h-[450px] font-sans text-sm text-gray-500 dark:text-gray-400"
        >
          <div
            class="flex flex-col mx-[26px] border-b border-gray-300 pb-7 items-center"
          >
            <div>
              <FormKit
                name="name"
                type="text"
                :label="t('Name')"
                :validation="'required'"
                validation-label="*"
                v-model="inputNameValue"
                :style="{
                  width: '280px',
                }"
              />
            </div>
            <!-- <div>
              <FormKit
                name="description"
                type="text"
                :label="t('Description')"
                v-model="description"
                :style="{
                  width: '280px',
                  height: '40px',
                }"
              />
            </div> -->
            <!-- <div class="flex schedule_types">
              <BaseListbox
                label="Repeat types:"
                placeholder="Select type"
                :items="schedule_types"
                :disabled="false"
                v-model="inputScheduleTypesValue"
                @update:model-value="onScheduleTypesChange"
                size="md"
                rounded="md"
                class="mb-1"
              />
            </div> -->
            <div class="flex repeat_types">
              <BaseListbox
                :label="t('Repeat types')"
                placeholder="Select type"
                :items="repeat_types"
                :disabled="false"
                v-model="inputRepeatTypesValue"
                @update:model-value="onRepeatTypesChange"
                size="md"
                rounded="md"
                class="mb-1"
              />
            </div>

            <div
              v-if="inputRepeatTypesValue == 'direct'"
              class="flex repeat_unit"
            >
              <BaseListbox
                :label="t('Repeat unit')"
                placeholder="Select unit"
                :items="repeat_unit"
                :disabled="false"
                v-model="inputRepeatUnitValue"
                size="md"
                rounded="md"
                class="mb-1"
              />
            </div>
            <div
              v-if="inputRepeatTypesValue == 'direct'"
              class="flex repeat_count"
            >
              <FormKit
                name="repeat_count"
                validation-label="*"
                type="number"
                :label="t('Repeat count')"
                v-model="repeatCount"
                :validation="
                  inputRepeatUnitValue.value == 'weeky'
                    ? 'required|min:1|max:7'
                    : inputRepeatUnitValue.value == 'monthly'
                    ? 'required|min:1|max:31'
                    : 'required|min:1'
                "
                @blur="updateRepeatDates"
                :style="{
                  width: '280px',
                  height: '34px !important',
                }"
              />
            </div>
          </div>

          <!-- dates loops -->
          <div class="dates flex flex-col mx-[26px] mt-[10px] items-center">
            <div
              v-for="(item, index) in repeat_counts"
              :key="index"
              class="flex space-x-2 mb-1 -ml-4"
            >
              <!-- 🔹 dates and cycles -->
              <div class="numbers flex items-center">
                {{ `${index + 1}. ` }}
              </div>
              <div
                v-if="
                  inputRepeatTypesValue == 'direct' &&
                  inputRepeatUnitValue == 'daily'
                "
                class="flex w-[200px] justify-evenly"
              >
                <FormKit
                  :name="'date_' + index"
                  type="number"
                  :label="index == 0 ? t('Time') : ''"
                  :validation="'required|min:1|max:24'"
                  v-model="item.hour"
                  :style="{ width: '80px', height: '34px !important' }"
                />
                <FormKit
                  :name="'date_' + index"
                  type="number"
                  :label="index == 0 ? t('Minutes') : ''"
                  :validation="'required|min:1|max:60'"
                  v-model="item.min"
                  :style="{ width: '80px', height: '34px !important' }"
                />
              </div>

              <FormKit
                v-if="
                  inputRepeatTypesValue == 'direct' &&
                  inputRepeatUnitValue == 'weekly'
                "
                :name="'date_' + index"
                type="select"
                :label="index == 0 ? t('Day of Weekly') : ''"
                v-model="item.date"
                :options="daysOfWeek"
                :validation="'required'"
                :style="{ width: '280px', height: '34px !important' }"
              />
              <FormKit
                v-if="
                  inputRepeatTypesValue == 'direct' &&
                  inputRepeatUnitValue == 'monthly'
                "
                :name="'date_' + index"
                type="number"
                :label="index == 0 ? t('Day of Month') : ''"
                v-model="item.date"
                :validation="'required|min:1|max:31'"
                :style="{ width: '280px', height: '34px !important' }"
              />
              <div
                class="yearly flex items-center"
                v-if="
                  inputRepeatTypesValue == 'direct' &&
                  inputRepeatUnitValue == 'yearly'
                "
              >
                <FormKit
                  :name="'month_' + index"
                  type="number"
                  :label="index == 0 ? t('Months') : ''"
                  v-model="item.month"
                  :validation="'required|min:1|max:12'"
                  :style="{
                    width: '140px',
                    marginRight: '10px',
                    height: '34px !important',
                  }"
                />

                <FormKit
                  :name="'days_' + index"
                  type="number"
                  :label="index == 0 ? t('Day of Month') : ''"
                  v-model="item.date"
                  :validation="'required|min:1|max:31'"
                  :style="{ width: '140px', height: '34px !important' }"
                />
              </div>
              <!-- <FormKit
                v-if="
                  inputRepeatTypesValue == 'direct' &&
                  inputRepeatUnitValue == 'yearly'
                "
                :name="'date_' + index"
                type="date"
                :label="index == 0 ? 'Day of Year:' : ''"
                v-model="item.date"
                :style="{ width: '280px', height: '34px !important' }"
              /> -->
              <FormKit
                v-if="inputRepeatTypesValue == 'completed'"
                :name="'date_' + index"
                type="number"
                :label="t('Days after Completed')"
                v-model="item.date"
                :validation="'required|min:1'"
                :style="{ width: '280px', height: '34px !important' }"
              />
            </div>
          </div>
        </div>
      </FormKit>
    </div>

    <ConfirmModalForm
      code="schedule"
      :text="$t('Do you close to this form?')"
      :successfullText="false"
      :open="isModalApproveConfirmOpen"
      :close="handleModalConfirmClose"
      :do_make="do_make"
    />
    <WarningModalForm
      :text="$t(isModalConfirmText)"
      code="Schedule"
      :open="isModalConfirmOpen"
      :close="handleModalConfirmClose"
    />
  </TairoModal>
</template>
<style>
.v-overlay {
  z-index: 10001 !important;
}
.scheduleModal {
  width: 100%;
}

.schedule .nui-listbox {
  width: 280px;
}
.schedule .nui-listbox-button-inner {
  height: 44px;
}

/* .schedule .nui-button.nui-button-medium {
  padding: 0px 10px 0px 10px !important;
  height: 28px;
}
.schedule .parts .vs__dropdown-toggle {
  height: 28px;
} */

.schedule .v-select.vs--single {
  /* width: 320px !important;
  margin-right: 10px; */
}
.schedule .vs__selected-options {
  /* width: 150px !important; */
  text-overflow: ellipsis !important;
}
.schedule .vs__selected-options {
  /* width: 150px !important; */
  text-overflow: ellipsis !important;
  font-size: 12px;
}
.schedule .vs__actions .vs__clear {
  /* position: absolute;
  margin: 0px -20px;
  z-index: 10; */
  display: none;
}
.schedule .text-danger-500 {
  width: 77px;
  /* overflow: hidden; */
  white-space: nowrap;
}
.mb-1.max-w-md:has(.submit) {
  width: 100%;
  max-width: 100%;
  /* right: 22px; */
  position: relative;
}
</style>
