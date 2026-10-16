<script setup>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { action_status } from '~/components/workorder/WorkOrderConstants'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'
import { getDefaultDateRange } from '~/composables/useDefaultDateRange'

// import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
// import WarningModalForm from '~/components/form/WarningModalForm.vue'

const { t } = useI18n({ useScope: 'global' })

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()

const permissions = JSON.parse(
  window.localStorage.getItem('app_permissions') || '{}',
)

const isModalPartOpen = ref(false)
const loading = ref(false)

const location_keys = ref([])

const checkedLocationId = ref([]) // Vue 3 Composition API
const checked = ref([])
const locations = ref([])
const isModalConfirmOpen = ref(false)
const isModalApproveConfirmOpen = ref(false)
const loadItem = ref('')

// Сүүлийн 9 сарын өмнөх сар (энэ сар багтсан) — tab1/tab2/tab3.vue-тэй НЭГ
// л эх сурвалжтай (useDefaultDateRange), эс тэгвэл модал дээр харагдах анхны
// огноо болон tab-уудын анхны фильтр хоорондоо зөрөх эрсдэлтэй байсан. Мөн
// өмнө нь `.toISOString()` ашигладаг байсан нь UTC руу хөрвүүлж (Монгол
// UTC+8) шөнийн цагт өдрийг буруу шилжүүлдэг байв.
const defaultRange = getDefaultDateRange()
const customFrom = ref(defaultRange.from)
const customTo = ref(defaultRange.to)

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
  publication: {
    new: false,
    updated: false,
    upvoted: false,
  },
  topics: {
    engineering: false,
    software: false,
    business: false,
    management: false,
    hr: false,
  },
  type: {
    members: false,
    projects: false,
    files: false,
  },
  statuses: Object.fromEntries(
    wo_status_items.map((item) => [item.name, false]),
  ),
  dates: {
    from: false,
    to: false,
  },
})

// filters.statuses бол сонгогдсон статусуудын цорын ганц эх сурвалж (single
// source of truth) — checkedStatusIds гэдэг тусдаа ref байсан нь энд хэзээ ч
// шинэчлэгддэггүй (status checkbox-ууд v-model="filters.statuses[name]"-ээр
// шууд filters.statuses рүү бичдэг байсан) тул location/date солигдох бүрт
// checked: [] явуулж, идэвхтэй байсан статус шүүлтийг дарж бичдэг байсан.
function getCheckedStatusIds() {
  const checkedStatusNames = Object.keys(filters.statuses).filter(
    (name) => filters.statuses[name] === true,
  )

  return wo_status_items
    .filter((item) => checkedStatusNames.includes(item.name))
    .map((item) => item.id)
}

function emitRefresh() {
  if (!props.refresh) return

  const payload = {
    checked: getCheckedStatusIds(),
    customFrom: customFrom.value,
    customTo: customTo.value,
    location: checkedLocationId.value,
  }
  console.log('[FilterNewModalForm] refresh payload:', payload)

  props.refresh(payload)
}

function onChange(type, event) {
  if (type == 'started_date' || type == 'end_date') {
    if (event.target.name == 'started_date') {
      customFrom.value = event.target.value
    } else if (event.target.name == 'end_date') {
      customTo.value = event.target.value
    }
  } else if (type === 'location') {
    const value = event.id
    const index = checkedLocationId.value.indexOf(value)

    if (index === -1) {
      checkedLocationId.value.push(value)
    } else {
      checkedLocationId.value.splice(index, 1)
    }
  }

  emitRefresh()
}

watch(() => filters.statuses, emitRefresh, { deep: true })

onMounted(async () => {
  if (permissions && permissions[1] && permissions[1].includes('admin')) {
    console.log('all tabs')
  } else {
    // console.log('versions', permissions)
    location_keys.value = Object.keys(permissions)
  }
  await loadLocations()
})

const loadLocations = async () => {
  if (loading.value) return

  loading.value = true
  try {
    const filters = {
      status: '1',
      company_id: { _eq: myCompanyId },
    }

    // location_keys.value нь Object.keys(permissions)-ээс аль хэдийн array
    // хэлбэрээр гарсан (жишээ: ["27","28"]) тул дахин Object.keys хийвэл
    // индексүүд ("0","1") гарч ирдэг байсан алдааг засав
    const keys = location_keys.value
    if (keys.length > 0) {
      filters.id = { _in: keys }
    }

    console.log('filters_modals', filters)
    const response = await getItems({
      collection: 'Location',
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    locations.value = response.data

    // locationCosts.value = []
    // for (const loc of response.data ?? []) {
    //   await loadTradesSum(null, null, null, loc.id)
    //   await loadPartsSum(null, null, null, loc.id)
    //   await loadCostsSum(null, null, null, loc.id)

    //   const item = {
    //     label: loc.name,
    //     id: loc.id,
    //     total:
    //       loc_actual_parts_sum.value +
    //       loc_actual_trades_sum.value +
    //       loc_other_actual_amount.value,
    //   }

    //   locationCosts.value.push(item)
    // }
    // console.log('locationCosts', locationCosts)

    // totalCost.value = locationCosts.value.reduce(
    //   (sum, item) => sum + item.value,
    //   0,
    // )
  } catch (error) {
    console.error('Error loading data:', error)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="flex flex-col gap-4 ml-4">
    <BaseCard rounded="md" class="p-4">
      <BaseHeading
        as="h3"
        weight="medium"
        size="md"
        class="mb-4 text-muted-900 dark:text-muted-100"
      >
        {{ t('Dates') }}
      </BaseHeading>
      <div class="date-range-filter">
        <div>
          <FormKit
            type="date"
            :label="t('From')"
            name="started_date"
            @change="onChange('started_date', $event)"
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
            :label="t('To')"
            name="end_date"
            @change="onChange('end_date', $event)"
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

    <BaseCard
      rounded="md"
      class="p-4 max-h-[520px] nui-slimscroll overflow-x-hidden overflow-y-auto"
    >
      <BaseHeading
        as="h3"
        weight="medium"
        size="md"
        class="mb-4 text-muted-900 dark:text-muted-100"
      >
        {{ t('Locations') }}
      </BaseHeading>
      <ul class="space-y-4">
        <li
          v-for="(item, index) in locations"
          :key="index"
          class="flex items-center justify-between"
        >
          <BaseCheckbox
            :label="item.name"
            variant="default"
            :classes="{ label: 'text-xs' }"
            :modelValue="checkedLocationId.includes(item.id)"
            @update:modelValue="onChange('location', item)"
          />
        </li>
      </ul>
    </BaseCard>
    <BaseCard rounded="md" class="p-4">
      <BaseHeading
        as="h3"
        weight="medium"
        size="md"
        class="mb-4 text-muted-900 dark:text-muted-100"
      >
        {{ t('Status') }}
      </BaseHeading>
      <ul class="space-y-4">
        <li
          v-for="([name, value], index) in Object.entries(filters.statuses)"
          :key="index"
          class="flex items-center justify-between"
        >
          <BaseCheckbox
            v-model="filters.statuses[name]"
            :label="t(name)"
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
