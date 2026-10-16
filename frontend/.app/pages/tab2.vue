<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { onMounted, ref } from 'vue'

import '~/assets/css/vcalendar.css'
import { completed_status_ids } from '~/components/workorder/WorkOrderStatus'
const { token } = useDirectusToken()

const props = defineProps({
  filterData: Object,
  statYear: Number,
  statMonth: Number,
  type: String,
  tab: String,
})

import { useI18n } from 'vue-i18n'
import CostLineRevenue from '~/components/demo-chart/CostLineRevenue.vue'
import CostPanel from '~/components/demo-chart/CostPanel.vue'
import CostVsPanel from '~/components/demo-chart/CostVsPanel.vue'
// Import optimization composable
import {
  batchApiCalls,
  useDebouncedTabRefresh,
} from '~/composables/useTabOptimization'
import {
  getDefaultDateRange,
  toLocalIsoStr,
  toRangeEnd,
  toRangeStart,
} from '~/composables/useDefaultDateRange'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  title: 'Works metrics',
  middleware: ['auth'],
  preview: {
    title: 'Works metrics',
    description: 'Works performance metrics and statistics',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-analytics.png',
    srcDark: '/img/screens/dashboards-analytics-dark.png',
    order: 4,
  },
})

// import FilterModalForm from '~/components/home/FilterModalForm.vue'
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const key = ref(1)
const search = ref('')
const serverItems = ref([])
const tab_counts = ref([])
const loading = ref(false)

const isModalOpen = ref(false)
const activeTab = ref('cost')

//tabs_count
const lineRevenue = ref(null)
const pieBar = ref(null)

// filters
const currentDate = new Date()
const checked = ref(null)
const location = ref(null)

function generateCustomRangeDays(from, to) {
  const isEmpty = (val) => !val || val === ''

  // Хэрвээ хоосон бол default range тохируулна
  const today = new Date()
  const tenMonthsAgo = new Date(today.getTime())
  tenMonthsAgo.setMonth(today.getMonth() - 9) // Өнөөдрөөс 9 сарын өмнө (өнөө сарыг багтаагаад 10 сар)

  const fromDate = new Date(isEmpty(from) ? tenMonthsAgo : from)
  const toDate = new Date(isEmpty(to) ? today : to)

  const result = []
  while (fromDate <= toDate) {
    const dayString = fromDate.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    })
    result.push(dayString)

    fromDate.setDate(fromDate.getDate() + 1) // дараагийн өдөр рүү шилжинэ
  }

  return result
}

// одоогийн сараас өмнөх 12 сарыг
function generatePast12Months() {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ]
  const dynamicMonths = []

  for (let i = 8; i >= 0; i--) {
    const date = new Date(
      currentDate.getFullYear(),
      currentDate.getMonth() - i,
      1,
    )
    const monthName = months[date.getMonth()]
    const year = date.getFullYear()
    dynamicMonths.push(`${monthName}, ${year}`)
  }

  return dynamicMonths
}

// Filter section
const fromMenu = ref(false)
const toMenu = ref(false)

// FilterNewModalForm.vue-тэй НЭГ л эх сурвалжтай (useDefaultDateRange) анхны
// огнооны хязгаар — эс тэгвэл модал дээр харагдах анхны огноо болон tab-ын
// анхны фильтр хоорондоо зөрөх эрсдэлтэй байсан
const defaultRange = getDefaultDateRange()
const customFrom = ref(defaultRange.from)
const customTo = ref(defaultRange.to)

const isDropdownOpen = ref(true)
const date_filer = ref(false)
const dashboard_type = ref(null)

// Updated data structure for chart
const locationCosts = ref([
  { label: 'Location A', value: 25000, color: '#4F46E5' },
  { label: 'Location B', value: 15000, color: '#10B981' },
  { label: 'Location C', value: 20000, color: '#F59E0B' },
  { label: 'Location D', value: 10000, color: '#EF4444' },
])

//counts
const parts_sum = ref(0.0)
const actual_parts_sum = ref(0.0)
const trades_sum = ref(0.0)
const actual_trades_sum = ref(0.0)
const other_amount = ref(0.0) //trade
const other_actual_amount = ref(0.0) //trade

const planned_cnt = ref(0.0)
const unplanned_cnt = ref(0.0)
const request_cnt = ref(0.0)
const total_cnt = ref(0.0)
const this_month_cnt = ref(0.0)
const last_month_cnt = ref(0.0)

const route = useRoute()

const grapicDatas = async ({ data, from, to }) => {
  try {
    const today = new Date()
    const monthsList = []
    for (let i = 8; i >= 0; i--) {
      const d = new Date(today.getFullYear(), today.getMonth() - i, 1)
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(
        2,
        '0',
      )}`
      monthsList.push(key)
    }

    // Хоосон бүтэц үүсгэнэ
    const createEmptyGrouped = () => {
      const obj = {}
      monthsList.forEach((month) => {
        obj[month] = { planned: 0, unplanned: 0 }
      })
      return obj
    }

    const monthlyGrouped = createEmptyGrouped()

    data.forEach((item) => {
      const date = new Date(item.started_at)
      const yearMonth = `${date.getFullYear()}-${String(
        date.getMonth() + 1,
      ).padStart(2, '0')}`

      if (monthlyGrouped[yearMonth]) {
        if (item.type?.code_plan === 'planned') {
          monthlyGrouped[yearMonth].planned += 1
        } else if (item.type?.code_plan === 'unplanned') {
          monthlyGrouped[yearMonth].unplanned += 1
        }
      }
    })

    const plannedData = monthsList.map((month) => monthlyGrouped[month].planned)
    const unplannedData = monthsList.map(
      (month) => monthlyGrouped[month].unplanned,
    )

    this_month_cnt.value =
      unplannedData[unplannedData.length - 1] +
      plannedData[plannedData.length - 1]

    last_month_cnt.value =
      unplannedData[unplannedData.length - 2] +
      plannedData[plannedData.length - 2]

    // console.log('this_month_cnt', this_month_cnt)
    // console.log('last_month_cnt', last_month_cnt)

    const entrySeries = [
      {
        name: t('Unplanned'),
        data: unplannedData,
      },
      {
        name: t('Planned'),
        data: plannedData,
      },
    ]

    return entrySeries
  } catch (error) {
    console.error('Error converting data:', error)
    return []
  }
}
//tab2 chart datas
function useLinePlanned() {
  const { success, danger } = useTailwindColors()
  const type = 'line'
  const height = 250

  const options = {
    chart: {
      zoom: {
        enabled: false,
      },
      toolbar: {
        show: false,
      },
    },
    colors: [success.value, danger.value],
    dataLabels: {
      enabled: false,
    },
    stroke: {
      width: [2, 2, 2],
      curve: 'smooth',
    },
    grid: {
      row: {
        colors: ['transparent', 'transparent'], // takes an array which will be repeated on columns
        opacity: 0.5,
      },
    },
    xaxis: {
      categories: generatePast12Months(), //9
    },
    tooltip: {
      y: {
        formatter: function (val: string) {
          return val
        },
      },
    },
  }

  const series = ref(tab_counts.value ?? [])

  return {
    type,
    height,
    options,
    series,
  }
}

const linePlanned = ref(null)

//Planned
const total_amount = computed(() => {
  return parts_sum.value + trades_sum.value + other_amount.value
})

const actual_total_amount = computed(() => {
  return (
    actual_parts_sum.value + actual_trades_sum.value + other_actual_amount.value
  )
})

const loadLocations = async () => {
  if (loading.value) return

  loading.value = true
  try {
    const filters = {
      status: '1',
      company_id: { _eq: myCompanyId },
    }

    const response = await getItems({
      collection: 'Location',
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    // console.log('response', response)

    locationCosts.value = []

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

const loadWorkOrderSum = async (
  type = null,
  from = null,
  to = null,
  checked = [],
  location = [],
) => {
  loading.value = true
  try {
    // Хэрэглэгчээс ирсэн `from`/`to`-г Date объект болгож хөрвүүлнэ;
    // өгөгдөөгүй бол customFrom.value/customTo.value (нэг эх сурвалж) руу
    // fallback хийнэ
    const fromDate = toRangeStart(from, customFrom.value)
    const toDate = toRangeEnd(to, customTo.value)

    let filters = {
      active: '1',
      company_id: { _eq: myCompanyId },
      action_status: { _eq: 2 },
      started_at: {
        _gte: toLocalIsoStr(fromDate),
        _lte: toLocalIsoStr(toDate),
      },
    }

    if (location.length) {
      if (isProxy(location)) {
        location = toRaw(location)
      }
      filters.location = { _in: location }
    }
    if (checked.length) {
      if (isProxy(checked)) {
        checked = toRaw(checked)
      }
      filters.wo_status = { _in: checked }
    }

    if (type == 'unplanned') {
      filters.type = { code_plan: { _eq: 'unplanned' } }
    }
    if (type == 'planned') {
      filters.type = { code_plan: { _eq: 'planned' } }
    }
    if (type == 'request') {
      filters.created_type = 'request'
    }
    // console.log('lloadWorkOrderSumfilters', filters)

    console.log('filters-', type, filters)
    const cost_items = await getItems({
      collection: 'Work_order',
      params: {
        filter: filters,
        aggregate: {
          count: '*',
        },
        // sort: 'started_at',
        // limit: -1,
        // page: page,
        // sort: sort_array,
        // meta: 'filter_count',
        // search: search.value,
        // fields: ['*'],
      },
    })
    console.log('type-', type, cost_items)

    if (type == 'unplanned') {
      unplanned_cnt.value = cost_items[0].count
    } else if (type == 'planned') {
      planned_cnt.value = cost_items[0].count
    } else if (type == 'request') {
      request_cnt.value = cost_items[0].count
    }

    total_cnt.value =
      parseInt(planned_cnt.value, 0) + parseInt(unplanned_cnt.value, 0)
    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

const loadWorkOrderItems = async (
  from = null,
  to = null,
  checked = [],
  location = [],
) => {
  loading.value = true
  try {
    // Хэрэглэгчээс ирсэн `from`/`to`-г Date объект болгож хөрвүүлнэ;
    // өгөгдөөгүй бол customFrom.value/customTo.value (нэг эх сурвалж) руу
    // fallback хийнэ
    const fromDate = toRangeStart(from, customFrom.value)
    const toDate = toRangeEnd(to, customTo.value)

    const filters = {
      active: '1',
      company_id: { _eq: myCompanyId },
      action_status: { _eq: 2 },
      started_at: {
        _gte: toLocalIsoStr(fromDate),
        _lte: toLocalIsoStr(toDate),
      },
    }
    if (location.length) {
      if (isProxy(location)) {
        location = toRaw(location)
      }
      filters.location = { _in: location }
    }
    if (checked.length) {
      if (isProxy(checked)) {
        checked = toRaw(checked)
      }
      filters.wo_status = { _in: checked }
    }

    // console.log('Other--filters', filters)

    const cost_items = await getItems({
      collection: 'Work_order',
      params: {
        filter: filters,
        meta: 'filter_count',
        sort: 'started_at',
        limit: 20,
        fields: ['id,created_type,started_at', 'type.code_plan'],
      },
    })
    // console.log('cost_itemss_counts', cost_items)
    // totalItems.value = cost_items.meta.filter_count
    loading.value = false
    return cost_items.data
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

function moneyFormat(value: number): string {
  if (isNaN(value)) return '0'
  if (!value) return '0'
  return value.toLocaleString('mn-MN') + ' ₮'
}

function numberFormat(value: number): string {
  if (isNaN(value)) return '0'
  if (!value) return '0'
  return value.toLocaleString()
}

function percentFormat(cnt, total) {
  if (!total || isNaN(cnt) || isNaN(total) || Number(total) === 0) return '0'
  return ((cnt / total) * 100).toFixed(2)
}

const refresh = async (filterData) => {
  console.log('[Tab2] Refresh called with filters:', filterData)

  // Update local refs
  checked.value = filterData.checked
  location.value = filterData.location
  customFrom.value =
    filterData.customFrom === undefined
      ? customFrom.value
      : filterData.customFrom
  customTo.value =
    filterData.customTo === undefined ? customTo.value : filterData.customTo

  const params = {
    from: customFrom.value,
    to: customTo.value,
    checked: checked.value ?? [],
    location: location.value ?? [],
  }

  try {
    // Batch all API calls to reduce network congestion
    const apiCalls = [
      () =>
        loadWorkOrderSum(
          'unplanned',
          params.from,
          params.to,
          params.checked,
          params.location,
        ),
      () =>
        loadWorkOrderSum(
          'planned',
          params.from,
          params.to,
          params.checked,
          params.location,
        ),
      () =>
        loadWorkOrderSum(
          'request',
          params.from,
          params.to,
          params.checked,
          params.location,
        ),
      () =>
        loadWorkOrderItems(
          params.from,
          params.to,
          params.checked,
          params.location,
        ),
    ]

    console.log('[Tab2] Starting batch API calls...')
    const results = await batchApiCalls(apiCalls)

    // Process results
    const [unplannedSum, plannedSum, requestSum, workOrderData] = results

    // Generate graphics data from batch results
    tab_counts.value = await grapicDatas({
      data: workOrderData,
      from: params.from,
      to: params.to,
    })

    linePlanned.value = useLinePlanned()
    console.log('[Tab2] Batch refresh completed successfully')
    return {
      unplannedSum,
      plannedSum,
      requestSum,
      workOrderData,
      tab_counts: tab_counts.value,
    }
  } catch (error) {
    console.error('[Tab2] Batch refresh failed:', error)
    throw error
  }
}

// Create debounced refresh function
const debouncedRefresh = useDebouncedTabRefresh('tab2', refresh, 500)

onMounted(async () => {
  // customFrom.value/customTo.value-г тодорхой дамжуулна — эс тэгвэл эдгээр
  // load* функцууд аргументгүй дуудагдахад өөрсдийн доторх тусдаа
  // hardcode-логдсон "9 сарын өмнөх" fallback-аа ашиглаж, useDefaultDateRange
  // (FilterNewModalForm-той нэг эх сурвалжтай) утгаас зөрдөг байсан
  await loadWorkOrderSum('unplanned', customFrom.value, customTo.value)
  await loadWorkOrderSum('planned', customFrom.value, customTo.value)
  await loadWorkOrderSum('request', customFrom.value, customTo.value)

  let data = await loadWorkOrderItems(customFrom.value, customTo.value)

  tab_counts.value = await grapicDatas({
    data: data,
    from: customFrom.value,
    to: customTo.value,
  })

  lineRevenue.value = null
  linePlanned.value = useLinePlanned()
  // console.log('tab_counts', tab_counts)
  // await loadLocations()
})
watch(
  props,
  async (newProps) => {
    // Use debounced refresh to prevent excessive API calls
    await debouncedRefresh(newProps.filterData)
    key.value += 1
  },
  { deep: true },
)
</script>

<template>
  <!-- Stat Total operating cost -->
  <div class="col-span-12 md:col-span-3 h-full cardBox">
    <CostVsPanel
      :title="t('Planned vs unplanned')"
      :icon="'twemoji:hammer-and-wrench'"
      :icon_class="''"
      :cost="total_cnt.toString()"
      :percentage="parseFloat(percentFormat(planned_cnt, total_cnt))"
      :compare-percentage="parseFloat(percentFormat(unplanned_cnt, total_cnt))"
      :symbol="'%'"
    />
  </div>
  <!-- Stat total part cost -->
  <div class="col-span-12 md:col-span-3 h-full cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Planned maintenance')"
      :icon="'fluent:wrench-screwdriver-24-filled'"
      :icon_class="'bg-yellow-100 text-yellow-500 dark:border-2 dark:border-yellow-500 dark:bg-yellow-500/20 dark:text-yellow-400'"
      :cost="numberFormat(planned_cnt)"
    />
  </div>
  <!-- Stat Actual trades cost -->
  <div class="col-span-12 md:col-span-3 h-full cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Unplanned maintenance')"
      :icon="'fluent:wrench-settings-24-regular'"
      :icon_class="'bg-red-100 text-red-500 dark:border-2 dark:border-red-500 dark:bg-yellow-500/20 dark:text-red-400'"
      :cost="numberFormat(unplanned_cnt)"
    />
  </div>
  <!-- Stat Actual other cost -->
  <div class="col-span-12 md:col-span-3 h-full cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Work request')"
      :icon="'carbon:pull-request'"
      :icon_class="'bg-blue-100 text-blue-500 dark:bg-blue-500/20 dark:text-blue-400 dark:border-blue-500 dark:border-2'"
      :cost="numberFormat(request_cnt)"
    />
  </div>
  <div class="col-span-12 md:col-span-3 h-full cardBox">
    <CostPanel
      :font_size="'2xl'"
      :title="t('MTBF')"
      :icon="'material-symbols:nest-clock-farsight-analog-outline'"
      :icon_class="'bg-blue-100 text-blue-500 dark:bg-blue-500/20 dark:text-blue-400 dark:border-blue-500 dark:border-2'"
      :cost="'23001 hours'"
    />
  </div>
  <div class="col-span-12 md:col-span-3 h-full cardBox">
    <CostPanel
      :font_size="'2xl'"
      :title="t('MTTR')"
      :icon="'material-symbols:nest-clock-farsight-analog-outline'"
      :icon_class="'bg-blue-100 text-blue-500 dark:bg-blue-500/20 dark:text-blue-400 dark:border-blue-500 dark:border-2'"
      :cost="'2.18 hours'"
    />
  </div>
  <div class="col-span-12 md:col-span-3 h-full cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Task caused down time')"
      :icon="'hugeicons:sad-dizzy'"
      :icon_class="'bg-mute-100 text-mute-500 dark:bg-mute-500/20 dark:text-mute-400 dark:border-mute-500 dark:border-2'"
      :cost="'2.18 hours'"
    />
  </div>
  <div class="col-span-12 md:col-span-3 h-full cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Average task time in Status \'Open\'')"
      :icon="'material-symbols:nest-clock-farsight-analog-outline'"
      :icon_class="'bg-mute-100 text-mute-500 dark:bg-mute-500/20 dark:text-mute-400 dark:border-mute-500 dark:border-2'"
      :cost="'2.18 hours'"
    />
  </div>
  <div class="col-span-12 cardBox">
    <CostLineRevenue
      v-if="linePlanned"
      :line-revenue="linePlanned"
      :lastMonth="last_month_cnt.toString()"
      :thisMonth="this_month_cnt.toString()"
      :colored-title="
        t('Planned vs unplanned') +
        ' - <b class=\'text-success-500\'>' +
        t('Planned') +
        '</b>, <b class=\'text-danger-500\'>' +
        t('Unplanned') +
        '</b>'
      "
    />
  </div>
</template>

<style scoped>
/* Карт бүрийг "3D" маягаар, гүн харагдахуйц сүүдэртэй, hover хийхэд дээш
   өргөгддөг болгоно. `:deep()` ашигласан нь BaseCard/CostPanel-ийн дотор
   бэлдсэн `.nui-card` root div рүү (child component-ийн markup тул) style
   нэвтрүүлэхийн тулд. */
.cardBox {
  perspective: 800px;
}

.cardBox :deep(.nui-card) {
  transition: transform 0.25s ease, box-shadow 0.25s ease;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.06),
    0 8px 16px -6px rgba(15, 23, 42, 0.12),
    0 20px 32px -12px rgba(15, 23, 42, 0.18);
}

.cardBox:hover :deep(.nui-card) {
  transform: translateY(-6px) rotateX(2deg);
  box-shadow: 0 2px 4px rgba(15, 23, 42, 0.08),
    0 16px 24px -8px rgba(15, 23, 42, 0.18),
    0 32px 48px -16px rgba(15, 23, 42, 0.28);
}

:global(.dark) .cardBox :deep(.nui-card) {
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.4), 0 8px 16px -6px rgba(0, 0, 0, 0.5),
    0 20px 32px -12px rgba(0, 0, 0, 0.6);
}

:global(.dark) .cardBox:hover :deep(.nui-card) {
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5), 0 16px 24px -8px rgba(0, 0, 0, 0.6),
    0 32px 48px -16px rgba(0, 0, 0, 0.7);
}
</style>
