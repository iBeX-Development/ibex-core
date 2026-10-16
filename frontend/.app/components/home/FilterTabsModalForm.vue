<script setup>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'

// import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
// import WarningModalForm from '~/components/form/WarningModalForm.vue'

const { t } = useI18n({ useScope: 'global' })

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
const isModalConfirmOpen = ref(false)
const newVal = ref(false)
const isModalApproveConfirmOpen = ref(false)
const loadItem = ref('')
const open_statuses = wo_status_items.filter(
  (item) => item?.type?.toLowerCase() === 'open',
)

const objectValue = ref({
  id: 1,
  name: 'Status',
  icon: 'mdi:progress-clock',
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

// FilterDate section
const fromMenu = ref(false)
const toMenu = ref(false)
const customFrom = ref('all_time')
const customTo = ref('all_time')
const isDropdownOpen = ref(true)
const date_filer = ref(false)
const location = ref(null)
const dashboard_type = ref(null)

const selectedRangeText = ref('Filter')
const dateOptions = ref([
  { label: 'Last 7 Days', value: 7 },
  { label: 'Last 30 Days', value: 30 },
  { label: 'Last 60 Days', value: 60 },
  { label: 'Last 90 Days', value: 90 },
  { label: 'Last 365 Days', value: 365 },
  { label: 'All Time', value: 'all' },
])

const selected_date = ref('')
const loading = ref(false)

const toggleDropdown = () => {
  setTimeout(() => {
    customFrom.value = 'all_time'
    customFrom.value = 'all_time'
    isDropdownOpen.value = true
    selectedRangeText.value = 'Filter'
  }, 500)
}

const handleItemClick = (days) => {
  date_filer.value = true

  if (days === 'all') {
    selectedRangeText.value = 'All Time'
    customFrom.value = 'all_time'
    customTo.value = 'all_time'
  } else {
    selectedRangeText.value = `Last ${days} Days`
    let fromDate = subDays(new Date(), days)
    customFrom.value = fromDate.toISOString().split('T')[0]
    let toDate = new Date()
    customTo.value = toDate.toISOString().split('T')[0]
  }
}

const loadTotals = async ({}) => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      company_id: { _eq: myCompanyId },
    }

    const items = await getItems({
      collection: 'Work_order',
      params: {
        filter: filters,
        limit: -1,
        meta: 'filter_count',
        fields: ['*', ''],
      },
    })
    serverItems.value = items.data
    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {}
}

// Scroll контейнерийг тодорхойлох ref
const filterContainer = ref(null)

const handleModalPartClose = () => {
  isModalPartOpen.value = false
}

const handleModalPartOpen = (item) => {
  isModalPartOpen.value = true
  // setPart({ id: null, name: '' })
  loadItem.value = item
}

const handleModalClose = () => {
  isModalPartOpen.value = false
  isModalApproveConfirmOpen.value = false
  props.close()
  setEmptyRow()
}

const setEmptyRow = () => {
  inputNameValue.value = ''
  inputDateValue.value = ''
  inputLocationValue.value = ''
  inputSupplierValue.value = ''
}

const submitHandler = async (values) => {
  console.log('values ->', values)
  console.log('rows', rows.value)
  // console.log(' props.row ->', props.row)
  // console.log('uploadedFiles ->', uploadedFiles)

  if (props.close) {
    props.close()
  }

  if (props.refresh) {
    console.log('Props refresh 2...')
    props.refresh()
  }
  handleModalClose()
}

onMounted(async () => {
  // if (props.row) {
  //   inputNameValue.value = props.item?.name
  //   inputDateValue.value = props.item?.transaction_date?.split('T')[0]
  //   inputLocationValue.value = props.item?.location
  //   inputSupplierValue.value = props.item?.supplier
  // }
})

const askModalClose = () => {
  isModalApproveConfirmOpen.value = true
  console.log('askModalClose', rows.value.length)
}
function onClick(item, type) {
  let updateData = {}
  console.log('item', item, type)
}
</script>

<template>
  <!-- Body -->
  <div class="filterModal">
    <FormKit type="form" :actions="true" :style="{ width: '100%' }">
      <BaseTabs
        justify="end"
        type="box"
        model-value="date_filter"
        class="tabs"
        :tabs="[
          { label: $t('Date filter'), value: 'date_filter' },
          { label: $t('Status'), value: 'status_filter' },
          // { label: $t('Payment'), value: 'payment_filter' },
        ]"
      >
        <template #tab="{ activeValue }">
          <div
            ref="filterContainer"
            v-if="activeValue === 'date_filter'"
            class="FilterDate w-[100%] overflow-hide font-sans text-sm text-gray-500 dark:text-gray-400"
          >
            <!-- <FormKit
              name="type"
              type="select"
              :options="dateOptions"
              v-model="selected_date"
              @change="handleItemClick(option.value)"
              outer-class=""
              :classes="{
                input: 'date_input',
                outer: 'date_wrapper',
                label: 'date_label',
              }"
            /> -->

            <div class="date-range-filter">
              <div>
                <div>
                  <FormKit
                    type="date"
                    label="From"
                    v-model="customFrom"
                    validation-visibility="live"
                    :classes="{
                      input: 'sdate_input',
                      outer: 'sdate_wrapper',
                      label: 'sdate_label',
                    }"
                  />
                </div>
                <div>
                  <FormKit
                    type="date"
                    label="To"
                    v-model="customTo"
                    validation-visibility="live"
                    :classes="{
                      input: 'edate_input',
                      outer: 'edate_wrapper',
                      label: 'edate_label',
                    }"
                  />
                </div>
              </div>
            </div>
          </div>
          <div
            v-else-if="activeValue === 'status_filter'"
            class="w-[100%] font-sans text-sm text-gray-500 dark:text-gray-400"
          >
            <div class="w-[240px] button-wrapper mt-[3px] ml-[10px]">
              <BaseListbox
                label="Status"
                :items="open_statuses"
                :properties="{
                  value: 'id',
                  label: 'name',
                  icon: 'icon', //baazaas awdag bolsonoos hoish zuraggui bolson
                }"
                :model-value="objectValue"
                size="md"
                rounded="md"
                @update:model-value="onClick($event, 'wo_status')"
              />
            </div>
          </div>
          <!-- <div
            v-else-if="activeValue === 'payment_filter'"
            class="w-[100%] overflow-auto font-sans text-sm text-gray-500 dark:text-gray-400"
          >
            hi3
          </div> -->
        </template>
      </BaseTabs>
      <div class="bttns flex justify-end">
        <BaseButton @click="handleModalClose" class="bttn">
          {{ $t('Close') }}
        </BaseButton>
        <BaseButton @click="submitHandler" class="bttn">
          {{ $t('Search') }}
        </BaseButton>
      </div>
    </FormKit>
  </div>
</template>
<style>
.filterModal {
  display: flex;
  width: 450px;
  height: 254px;
  padding: 20px;
  background: white;
  z-index: 10001 !important;
  border-radius: 16px;
  right: 0px;
  position: absolute;
  border: 1px solid #d7d6d6;
  box-shadow: 0 3px 5px rgba(0, 0, 0.1, 0.2);
}
.filterModal .nui-button.nui-button-medium {
  display: flex;
  flex-direction: column;
}
.filterModal .tabs.tabs.nui-tabs.nui-tabs-end {
  display: flex;
  height: 185px;
  /* flex-direction: column; */
}
.filterModal .nui-tabs-inner {
  flex-direction: column;
  border-right: 1px solid gray;
  padding-right: 10px;
  margin-right: 30px;
  justify-content: start !important;
}

.filterModal .nui-tabs .nui-pill-item:not(.nui-has-icon) {
  align-items: start;
}

.filterModal .v-select.vs--single {
  /* width: 320px !important;
  margin-right: 10px; */
}
.filterModal .vs__selected-options {
  width: 150px !important;
  text-overflow: ellipsis !important;
}
.filterModal .vs__selected-options {
  width: 150px !important;
  text-overflow: ellipsis !important;
  font-size: 12px;
}
.filterModal .vs__actions .vs__clear {
  /* position: absolute;
  margin: 0px -20px;
  z-index: 10; */
  display: none;
}

.filterModal .date_label,
.filterModal .sdate_label,
.filterModal .edate_label {
  font-size: 12px;
}

.filterModal .date_input,
.filterModal .sdate_input,
.filterModal .edate_input {
  font-size: 12px;
  width: 240px;
  height: 34px;
}

.filterModal .nui-button.bttn {
  height: 24px;
  margin-right: 10px;
  font-size: 12px;
  width: 60px;
}
.filterModal .nui-button.bttn:hover {
  background-color: #8363ee !important;
  cursor: pointer;
  color: white;
}

.filterModal .bttn.nui-button:focus-within {
  outline-style: none !important;
}
.filterModal .text-danger-500 {
  width: 80px;
  overflow: hidden;
  white-space: nowrap;
}
.filterModal .mb-1.max-w-md:has(.submit) {
  width: 100%;
  max-width: 100%;
  right: 22px;
  position: relative;
}
.filterModal .mb-1.max-w-md button {
  display: none;
}
</style>
