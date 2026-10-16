<script setup>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { action_status } from '~/components/workorder/WorkOrderConstants'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'

// import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
// import WarningModalForm from '~/components/form/WarningModalForm.vue'

const { t } = useI18n({ useScope: 'global' })

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const toaster = useToaster()

const isModalPartOpen = ref(false)
const checked = ref([])
const isModalConfirmOpen = ref(false)
const isModalApproveConfirmOpen = ref(false)
const loadItem = ref('')

const open_statuses = wo_status_items.filter(
  (item) => item?.type?.toLowerCase() === 'open',
)

const actions_status = action_status.filter(
  (item) => item?.name?.toLowerCase() !== 'deleted',
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
  getData: Function,
  refresh: Function,
  row: Number,
  location: Number,
  item: Object,
  code: String,
  last: Object,
  datas: Object,
  editPartRow: Object,
})

// FilterDate section
const fromMenu = ref(false)
const toMenu = ref(false)
const customFrom = ref(
  new Date(new Date().setDate(new Date().getDate() - 6))
    .toISOString()
    .split('T')[0],
)
const customTo = ref(new Date().toISOString().split('T')[0])

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
}

const handleFilter = async (values) => {
  // console.log('handleFilter:', checked.value)
  // console.log('handleFilter ->', customFrom.value, customTo.value)
  // console.log('uploadedFiles ->', uploadedFiles)

  if (props.close) {
    props.close()
  }

  if (props.refresh) {
    console.log('Props refresh...')
    // props.refresh({
    //   checked: checked.value,
    //   customFrom: customFrom.value,
    //   customTo: customTo.value,
    //   location: props.location,
    // })
  }
  handleModalClose()
}

onMounted(async () => {
  if (props.datas) {
    // console.log('onMounted', props)
    checked.value = props.datas.checked
    customFrom.value = props.datas.customFrom
    customTo.value = props.datas.customTo
  }
})

function onChange(event) {
  let items = {}
  let keyName = ''
  console.log('onChange_dates', event.target.name)

  if (event.target.name == 'started_date') {
    keyName = 'started_date'
    customFrom.value = event.target.value
  } else if (event.target.name == 'end_date') {
    keyName = 'end_date'
    customTo.value = event.target.value
  }

  // console.log('customFrom', customFrom.value)
  // console.log('customTo', customTo.value)
}

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
  <div class="filterHomeModal">
    <FormKit type="form" :actions="true" :style="{ width: '100%' }">
      <div class="w-[100%] font-sans text-sm text-gray-500 dark:text-gray-400">
        <div class="items">
          <div v-for="item in wo_status_items" :key="item.id">
            <BaseCheckbox
              v-model="checked"
              color="primary"
              :label="item.name"
              :value="item.id"
            />
          </div>
        </div>
      </div>
      <div class="date-range-filter py-4">
        <div>
          <FormKit
            type="date"
            label="From"
            name="started_date"
            @change="onChange"
            v-model="customFrom"
            validation-visibility="live"
            :classes="{
              input: 'date_input',
              outer: 'sdate_wrapper',
              label: 'sdate_label',
            }"
          />
        </div>
        <div class="end_date">
          <FormKit
            type="date"
            label="To"
            name="end_date"
            @change="onChange"
            v-model="customTo"
            validation-visibility="live"
            :classes="{
              input: 'date_input',
              outer: 'edate_wrapper',
              label: 'edate_label',
            }"
          />
        </div>
      </div>

      <div class="bttns flex justify-end">
        <BaseButton @click="handleModalClose" class="bttn">
          {{ $t('Clear') }}
        </BaseButton>
        <BaseButton @click="handleFilter" class="bttn">
          {{ $t('Filter') }}
        </BaseButton>
      </div>
    </FormKit>
  </div>
</template>
<style>
.filterHomeModal {
  display: flex;
  width: 225px;
  height: 'fit-content';
  padding: 20px;
  background: white;
  z-index: 10001 !important;
  border-radius: 16px;
  right: 0px;
  position: absolute;
  border: 1px solid #d7d6d6;
  box-shadow: 0 3px 5px rgba(0, 0, 0.1, 0.2);
}
.filterHomeModal .nui-button.nui-button-medium {
  display: flex;
  flex-direction: column;
}
.filterHomeModal .tabs.tabs.nui-tabs.nui-tabs-end {
  display: flex;
  height: 185px;
  /* flex-direction: column; */
}
.filterHomeModal .nui-tabs-inner {
  flex-direction: column;
  border-right: 1px solid gray;
  padding-right: 10px;
  margin-right: 30px;
  justify-content: start !important;
}

.filterHomeModal .nui-tabs .nui-pill-item:not(.nui-has-icon) {
  align-items: start;
}

.filterHomeModal .v-select.vs--single {
  /* width: 320px !important;
  margin-right: 10px; */
}
.filterHomeModal .vs__selected-options {
  width: 150px !important;
  text-overflow: ellipsis !important;
}
.filterHomeModal .vs__selected-options {
  width: 150px !important;
  text-overflow: ellipsis !important;
  font-size: 12px;
}
.filterHomeModal .vs__actions .vs__clear {
  /* position: absolute;
  margin: 0px -20px;
  z-index: 10; */
  display: none;
}

.filterHomeModal .date_label,
.filterHomeModal .sdate_label,
.filterHomeModal .edate_label {
  font-size: 12px;
}

.filterHomeModal .date_input,
.filterHomeModal .sdate_input,
.filterHomeModal .edate_input {
  font-size: 12px;
  width: 152px;
  height: 34px;
}

.filterHomeModal .nui-button.bttn {
  height: 24px;
  margin-right: 10px;
  font-size: 12px;
  width: 60px;
}
.filterHomeModal .nui-button.bttn:hover {
  background-color: #8363ee !important;
  cursor: pointer;
  color: white;
}

.filterHomeModal .bttn.nui-button:focus-within {
  outline-style: none !important;
}
.filterHomeModal .text-danger-500 {
  width: 80px;
  overflow: hidden;
  white-space: nowrap;
}
.filterHomeModal .mb-1.max-w-md:has(.submit) {
  width: 100%;
  max-width: 100%;
  right: 22px;
  position: relative;
}
.filterHomeModal .mb-1.max-w-md button {
  display: none;
}
</style>
