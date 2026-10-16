<script setup>
import { ref, reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { action_status } from '~/components/workorder/WorkOrderConstants'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'

// import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
// import WarningModalForm from '~/components/form/WarningModalForm.vue'

const { t } = useI18n({ useScope: 'global' })

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const toaster = useToaster()
const myCompanyId = getMyCompanyId()

const isModalPartOpen = ref(false)
const checked = ref([])
const isModalConfirmOpen = ref(false)
const isModalApproveConfirmOpen = ref(false)
const loadItem = ref('')

const getStatusLabel = (item) => t(item.status_text || item.name)

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
const filters = reactive({
  statuses: Object.fromEntries(
    wo_status_items.map((item) => [getStatusLabel(item), false]),
  ),
  dates: {
    from: false,
    to: false,
  },
})

const customFrom = ref(
  new Date(new Date().setDate(new Date().getDate() - 6))
    .toISOString()
    .split('T')[0],
)
const customTo = ref(new Date().toISOString().split('T')[0])

function onChange(event) {
  let items = {}
  let keyName = ''

  if (event.target.name == 'started_date') {
    keyName = 'started_date'
    customFrom.value = event.target.value
  } else if (event.target.name == 'end_date') {
    keyName = 'end_date'
    customTo.value = event.target.value
  }

  // console.log('onChange', filters.statuses)
  // ✅ Сонгогдсон статусуудын нэрийг авна
  const checkedStatusNames = Object.keys(filters.statuses).filter(
    (name) => filters.statuses[name] === true,
  )

  // ✅ Тэр нэртэй тохирох id-нуудыг wo_status_items дотроос авна
  const checkedIds = wo_status_items
    .filter((item) => checkedStatusNames.includes(getStatusLabel(item)))
    .map((item) => item.id)

  // console.log('checkedIds', checkedIds)

  if (props.refresh) {
    // console.log('Props refresh1...', {
    //   checked: checkedIds,
    //   customFrom: customFrom.value,
    //   customTo: customTo.value,
    //   location: props.location,
    // })

    props.refresh({
      checked: checkedIds,
      customFrom: customFrom.value,
      customTo: customTo.value,
      location: props.location,
    })
  }
  // console.log('customTo', customTo.value)
}

watch(
  () => filters.statuses,
  (newVal) => {
    // console.log('Status checkboxes changed:', newVal)
    // console.log('Status checkboxes customFrom.value:', customFrom.value)
    // console.log('Status checkboxes customTo.value:', customTo.value)

    // console.log('checkedddddd', filters.statuses)
    // ✅ Сонгогдсон статусуудын нэрийг авна
    const checkedStatusNames = Object.keys(filters.statuses).filter(
      (name) => filters.statuses[name] === true,
    )

    // ✅ Тэр нэртэй тохирох id-нуудыг wo_status_items дотроос авна
    const checkedIds = wo_status_items
      .filter((item) => checkedStatusNames.includes(getStatusLabel(item)))
      .map((item) => item.id)

    // console.log('ddsdsd', checkedIds)

    if (props.refresh) {
      // console.log('Props refresh2...', {
      //   checked: checkedIds,
      //   customFrom: customFrom.value,
      //   customTo: customTo.value,
      //   location: props.location,
      // })

      props.refresh({
        checked: checkedIds,
        customFrom: customFrom.value,
        customTo: customTo.value,
        location: props.location,
      })
    }
  },
  { deep: true },
)
</script>

<template>
  <div class="flex flex-col gap-4">
    <BaseCard rounded="md" class="p-4">
      <BaseHeading
        as="h3"
        weight="medium"
        size="md"
        class="mb-4 text-muted-900 dark:text-muted-100"
      >
        {{ $t('Dates') }}
      </BaseHeading>
      <div class="date-range-filter">
        <div>
          <FormKit
            type="date"
            :label="$t('From')"
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
            :label="$t('To')"
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
    </BaseCard>
    <BaseCard rounded="md" class="p-4">
      <BaseHeading
        as="h3"
        weight="medium"
        size="md"
        class="mb-4 text-muted-900 dark:text-muted-100"
      >
        {{ $t('Status') }}
      </BaseHeading>
      <ul class="space-y-4">
        <li
          v-for="([name, value], index) in Object.entries(filters.statuses)"
          :key="index"
          class="flex items-center justify-between"
        >
          <BaseCheckbox
            v-model="filters.statuses[name]"
            :label="name"
            variant="default"
            :classes="{ label: 'text-xs' }"
          />
        </li>
      </ul>
    </BaseCard>
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
