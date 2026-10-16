<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { isProxy, onMounted, ref, toRaw } from 'vue'
import { useI18n } from 'vue-i18n'

import '~/assets/css/vcalendar.css'
import CostLineRevenue from '~/components/demo-chart/CostLineRevenue.vue'
import CostPanel from '~/components/demo-chart/CostPanel.vue'
import CostPie from '~/components/demo-chart/CostPie.vue'
import { completed_status_ids } from '~/components/workorder/WorkOrderStatus'

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

const { token } = useDirectusToken()
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  title: 'Cost & Revenue metrics',
  middleware: ['auth'],
  preview: {
    title: 'Cost & Revenue metrics',
    description: 'Cost and revenue performance metrics and statistics',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-analytics.png',
    srcDark: '/img/screens/dashboards-analytics-dark.png',
    order: 4,
  },
})

const props = defineProps({
  filterData: Object,
  isOpenFilter: Boolean,
  type: String,
  tab: String,
})

// Import optimization composable

// import FilterModalForm from '~/components/home/FilterModalForm.vue'
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const search = ref('')
const serverItems = ref([])
const tab1_counts = ref([])

const this_month_cnt = ref(0.0)
const last_month_cnt = ref(0.0)

const isModalOpen = ref(false)
const activeTab = ref('cost')

//tabs_count
const lineRevenue = ref(null)
const pieBar = ref(null)
const plannedActualChart = ref(null)
const breakdownChart = ref(null)
const currentDate = new Date()

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

function useLineCostsRevenue() {
  const { primary, danger, info } = useTailwindColors()
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
    colors: [primary.value, danger.value, info.value],
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
          return '' + val
        },
      },
    },
  }

  let rawData = []
  if (isProxy(tab1_counts.value)) {
    rawData = toRaw(tab1_counts.value)
  }

  const series = ref(rawData)

  return {
    type,
    height,
    options,
    series,
  }
}

function usePieBar() {
  const { primary, success, info, danger, warning, yellow } =
    useTailwindColors()
  const type = 'pie'
  const height = 240

  const labels = locationCosts.value.map((loc) => loc.label)
  const rawSeries = locationCosts.value.map((loc) => Number(loc.total) || 0)
  const series = ref(
    rawSeries.length > 0 && rawSeries.some((v) => v > 0) ? rawSeries : [],
  )

  const options = {
    chart: {
      type: 'pie',
      toolbar: {
        show: false,
      },
    },
    stroke: {
      colors: ['transparent'],
    },
    colors: [
      primary.value,
      success.value,
      info.value,
      danger.value,
      warning.value,
      yellow.value,
    ],
    labels: labels,
    legend: {
      show: false,
    },
    plotOptions: {
      pie: {
        // Remove startAngle and endAngle for full pie
        offsetY: 0, // Adjust offset as needed
        dataLabels: {
          minAngleToShowLabel: 10,
        },
      },
    },
    grid: {
      padding: {
        bottom: 0,
      },
    },
    dataLabels: {
      enabled: true,
      formatter: function (val: number) {
        return val.toFixed(0) + '%'
      },
      style: {
        fontSize: '14px',
        fontFamily: 'sans-serif',
        fontWeight: 500,
      },
      dropShadow: {
        enabled: false,
      },
    },
    tooltip: {
      enabled: true,
      y: {
        formatter: function (val: number) {
          return moneyFormat(val)
        },
      },
    },
    responsive: [
      {
        breakpoint: 480,
        options: {
          chart: {
            width: 200,
          },
        },
      },
    ],
  }

  // Series data should add up to 100% for percentages
  // const series = shallowRef([25, 20, 15, 15, 15, 10])

  return {
    type,
    height,
    options,
    series,
  }
}

function usePlannedVsActual() {
  const { primary, danger } = useTailwindColors()
  const type = 'bar'
  const height = 220
  const options = {
    chart: { type: 'bar', toolbar: { show: false } },
    plotOptions: {
      bar: { horizontal: false, columnWidth: '55%', borderRadius: 3 },
    },
    colors: [primary.value, danger.value],
    dataLabels: { enabled: false },
    xaxis: {
      categories: [t('Trades'), t('Parts'), t('Other')],
    },
    yaxis: {
      labels: {
        formatter: (v: number) =>
          v > 0 ? (v / 1000000).toFixed(1) + 'M' : '0',
      },
    },
    tooltip: {
      y: { formatter: (v: number) => v.toLocaleString('mn-MN') + ' ₮' },
    },
    legend: { position: 'top' },
  }
  const series = ref([
    {
      name: t('Planned'),
      data: [
        Number(trades_sum.value) || 0,
        Number(parts_sum.value) || 0,
        Number(other_amount.value) || 0,
      ],
    },
    {
      name: t('Actual'),
      data: [
        Number(actual_trades_sum.value) || 0,
        Number(actual_parts_sum.value) || 0,
        Number(other_actual_amount.value) || 0,
      ],
    },
  ])
  return { type, height, options, series }
}

function useCostBreakdown() {
  const { primary, danger, info } = useTailwindColors()
  const type = 'donut'
  const height = 220
  const rawSeries = [
    Number(actual_trades_sum.value) || 0,
    Number(actual_parts_sum.value) || 0,
    Number(other_actual_amount.value) || 0,
  ]
  const series = ref(rawSeries.some((v) => v > 0) ? rawSeries : [])
  const options = {
    chart: { type: 'donut', toolbar: { show: false } },
    colors: [primary.value, danger.value, info.value],
    labels: [t('Trades'), t('Parts'), t('Other')],
    legend: { position: 'bottom', fontSize: '12px' },
    dataLabels: {
      enabled: true,
      formatter: (val: number) => val.toFixed(0) + '%',
    },
    tooltip: {
      y: { formatter: (v: number) => v.toLocaleString('mn-MN') + ' ₮' },
    },
    plotOptions: {
      pie: { donut: { size: '65%' } },
    },
  }
  return { type, height, options, series }
}

// Filter section
const fromMenu = ref(false)
const toMenu = ref(false)

// FilterNewModalForm.vue, tab2.vue, tab3.vue-тэй НЭГ л эх сурвалжтай
// (useDefaultDateRange) анхны огнооны хязгаар — эс тэгвэл модал дээр
// харагдах анхны огноо болон tab-ын анхны фильтр хоорондоо зөрөх эрсдэлтэй
// байсан. tab1.vue-д customFrom/customTo нь (бусад tab-аас ялгаатай нь)
// string биш Date объект хэлбэрээр хадгалагддаг тул үүнтэй нийцүүлэв.
const defaultRange = getDefaultDateRange()
const customFrom = ref(new Date(defaultRange.from + 'T00:00:01'))
const customTo = ref(new Date(defaultRange.to + 'T23:59:59'))

const loading = ref(false)
const isDropdownOpen = ref(true)
const date_filer = ref(false)
const checked = ref(null)
const location = ref(null)
const dashboard_type = ref(null)

// Updated data structure for chart
const locationCosts = ref([
  { label: 'Location A', value: 25000, color: '#4F46E5' },
  { label: 'Location B', value: 15000, color: '#10B981' },
  { label: 'Location C', value: 20000, color: '#F59E0B' },
  { label: 'Location D', value: 10000, color: '#EF4444' },
])

const refresh = async (filterData) => {
  console.log('[Tab1] Refresh called with filters:', filterData)

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
        loadTradesSum(params.from, params.to, params.checked, params.location),
      () =>
        loadPartsSum(
          params.from,
          params.to,
          params.checked,
          params.location,
          'refresh',
        ),
      () =>
        loadCostsSum(params.from, params.to, params.checked, params.location),
      () =>
        loadCostsCount(params.from, params.to, params.checked, params.location),
      () =>
        loadTradesCount(
          params.from,
          params.to,
          params.checked,
          params.location,
        ),
      () =>
        loadPartsCount(params.from, params.to, params.checked, params.location),
      () =>
        loadLocations(params.from, params.to, params.checked, params.location),
    ]

    console.log('[Tab1] Starting batch API calls...')
    console.log('[Tab1] apiCalls', apiCalls)
    const results = await batchApiCalls(apiCalls)

    // Process results
    const [
      tradesSum,
      partsSum,
      costsSum,
      costsCount,
      tradesCount,
      partsCount,
      locations,
    ] = results

    // Generate graphics data from batch results
    tab1_counts.value = await grapicDatas({
      trades: tradesCount,
      parts: partsCount,
      others: costsCount,
      from: params.from,
      to: params.to,
    })

    // Update chart refs
    lineRevenue.value = useLineCostsRevenue()
    pieBar.value = usePieBar()
    plannedActualChart.value = usePlannedVsActual()
    breakdownChart.value = useCostBreakdown()

    console.log(
      '[pieBar] Refresh completed successfully with results:',
      pieBar.value,
    )

    console.log('[Tab1] Batch refresh completed successfully')
    return {
      tradesSum,
      partsSum,
      costsSum,
      costsCount,
      tradesCount,
      partsCount,
      tab1_counts: tab1_counts.value,
      lineRevenue: lineRevenue.value,
    }
  } catch (error) {
    console.error('[Tab1] Batch refresh failed:', error)
    throw error
  }
}

// Create debounced refresh function
const debouncedRefresh = useDebouncedTabRefresh('tab1', refresh, 500)

//tab1 counts
const parts_sum = ref(0.0)
const actual_parts_sum = ref(0.0)
const trades_sum = ref(0.0)
const actual_trades_sum = ref(0.0)
const other_amount = ref(0.0) //trade
const other_actual_amount = ref(0.0) //trade

//locations
const loc_trades_sum = ref(0.0)
const loc_actual_trades_sum = ref(0.0)
const loc_parts_sum = ref(0.0)
const loc_actual_parts_sum = ref(0.0)
const loc_other_amount = ref(0.0) //trade
const loc_other_actual_amount = ref(0.0) //trade

const route = useRoute()
const grapicData = async ({ trades, parts, others, from, to }) => {
  try {
    const { primary, info, success } = useTailwindColors()

    // 10 сарыг тодорхойлох
    const today = new Date()
    const monthsList = []
    for (let i = 9; i >= 0; i--) {
      const d = new Date(today.getFullYear(), today.getMonth() - i, 1)
      const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(
        2,
        '0',
      )}`
      monthsList.push(key)
    }

    const createEmptyGrouped = () => {
      const obj = {}
      monthsList.forEach((month) => {
        obj[month] = { total: 0, actual_total: 0 }
      })
      return obj
    }

    // TRADES
    const monthlyGrouped = createEmptyGrouped()
    trades.forEach((item) => {
      const date = new Date(item.work_order.started_at)
      const yearMonth = `${date.getFullYear()}-${String(
        date.getMonth() + 1,
      ).padStart(2, '0')}`
      if (monthlyGrouped[yearMonth]) {
        monthlyGrouped[yearMonth].total += item.total
        monthlyGrouped[yearMonth].actual_total += item.actual_total
      }
    })
    const tradesData = monthsList.map((month) => ({
      month,
      total: monthlyGrouped[month].total,
      actual_total: monthlyGrouped[month].actual_total,
    }))

    // PARTS
    const monthlyGrouped2 = createEmptyGrouped()
    parts.forEach((item) => {
      const date = new Date(item.work_order.started_at)
      const yearMonth = `${date.getFullYear()}-${String(
        date.getMonth() + 1,
      ).padStart(2, '0')}`
      if (monthlyGrouped2[yearMonth]) {
        monthlyGrouped2[yearMonth].total += item.amount
        monthlyGrouped2[yearMonth].actual_total += item.actual_amount
      }
    })
    const partsData = monthsList.map((month) => ({
      month,
      total: monthlyGrouped2[month].total,
      actual_total: monthlyGrouped2[month].actual_total,
    }))

    // OTHERS
    const monthlyGrouped3 = createEmptyGrouped()
    others.forEach((item) => {
      const date = new Date(item.started_at)
      const yearMonth = `${date.getFullYear()}-${String(
        date.getMonth() + 1,
      ).padStart(2, '0')}`
      if (monthlyGrouped3[yearMonth]) {
        monthlyGrouped3[yearMonth].total += item.other_amount
        monthlyGrouped3[yearMonth].actual_total += item.other_actual_amount
      }
    })
    const othersData = monthsList.map((month) => ({
      month,
      total: monthlyGrouped3[month].total,
      actual_total: monthlyGrouped3[month].actual_total,
    }))

    const entrySeries = [
      { name: t('Trades'), data: tradesData },
      { name: t('Parts'), data: partsData },
      { name: t('Others'), data: othersData },
    ]

    return {
      series: entrySeries,
    }
  } catch (error) {
    console.error('Error convert data:', error)
    return []
  }
}

const grapicDatas = async ({ trades, parts, others, from, to }) => {
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

    const createEmptyGrouped = () => {
      const obj = {}
      monthsList.forEach((month) => {
        obj[month] = { total: 0, actual_total: 0 }
      })
      return obj
    }

    // Trades
    const monthlyGroupedTrades = createEmptyGrouped()
    trades?.forEach((item) => {
      const date = new Date(item.work_order.started_at)
      const yearMonth = `${date.getFullYear()}-${String(
        date.getMonth() + 1,
      ).padStart(2, '0')}`
      if (monthlyGroupedTrades[yearMonth]) {
        monthlyGroupedTrades[yearMonth].actual_total += item.actual_total //?
      }
    })
    const tradesActualData = monthsList.map(
      (month) => monthlyGroupedTrades[month].actual_total,
    )

    // Parts
    const monthlyGroupedParts = createEmptyGrouped()
    parts?.forEach((item) => {
      const date = new Date(item.work_order.started_at)
      const yearMonth = `${date.getFullYear()}-${String(
        date.getMonth() + 1,
      ).padStart(2, '0')}`
      if (monthlyGroupedParts[yearMonth]) {
        monthlyGroupedParts[yearMonth].actual_total += item.actual_amount
      }
    })
    const partsActualData = monthsList.map(
      (month) => monthlyGroupedParts[month].actual_total,
    )

    // Others
    const monthlyGroupedOthers = createEmptyGrouped()
    others?.forEach((item) => {
      const date = new Date(item.started_at)
      const yearMonth = `${date.getFullYear()}-${String(
        date.getMonth() + 1,
      ).padStart(2, '0')}`
      if (monthlyGroupedOthers[yearMonth]) {
        monthlyGroupedOthers[yearMonth].actual_total += item.other_actual_amount
      }
    })
    const othersActualData = monthsList.map(
      (month) => monthlyGroupedOthers[month].actual_total,
    )

    // Final series
    const entrySeries = [
      { name: t('Trades'), data: tradesActualData },
      { name: t('Parts'), data: partsActualData },
      { name: t('Others'), data: othersActualData },
    ]

    this_month_cnt.value =
      tradesActualData[tradesActualData.length - 1] +
      partsActualData[partsActualData.length - 1] +
      othersActualData[othersActualData.length - 1]

    last_month_cnt.value =
      tradesActualData[tradesActualData.length - 2] +
      partsActualData[partsActualData.length - 2] +
      othersActualData[othersActualData.length - 2]

    return entrySeries
  } catch (error) {
    console.error('Error convert data:', error)
    return []
  }
}

//Planned
const total_amount = computed(() => {
  return parts_sum.value + trades_sum.value + other_amount.value
})

const actual_total_amount = computed(() => {
  // console.log('actual_parts_sum', actual_parts_sum)
  // console.log('actual_trades_sum', actual_trades_sum)
  // console.log('other_actual_amount', other_actual_amount)

  return (
    actual_parts_sum.value + actual_trades_sum.value + other_actual_amount.value
  )
})

const loadLocations = async (
  from = null,
  to = null,
  checked = [],
  location = [],
) => {
  // Normalize null → [] to avoid null.length TypeError
  location = location ?? []
  checked = checked ?? []

  loading.value = true
  try {
    // Get all locations first
    const filters = {
      status: '1',
      company_id: { _eq: myCompanyId },
    }

    if (location.length) {
      if (isProxy(location)) {
        location = toRaw(location)
      }
      filters.id = { _in: location }
    }

    const response = await getItems({
      collection: 'Location',
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    // console.log(
    //   '[loadLocations] Processing',
    //   response.data?.length || 0,
    //   'locations',
    // )

    // Prepare date filters — handle both string and Date object inputs
    const fromDate = toRangeStart(from, customFrom.value)
    const toDate = toRangeEnd(to, customTo.value)

    // Get all location IDs for bulk queries
    const locationIds = response.data?.map((loc) => loc.id) || []

    if (locationIds.length === 0) {
      locationCosts.value = []
      loading.value = false
      return
    }

    // console.log(
    //   '[loadLocationsIds] Fetching data for locations:',
    //   locationIds.join(', '),
    // )

    // Бусад load*Sum/load*Count функцтэй адил: хэрэглэгч тодорхой статус
    // сонгосон (checked) үед л wo_status-аар нэмж шүүнэ, эс бол зөвхөн
    // action_status=2 (Approved) байхад л хангалттай — өмнө нь энд
    // checked хоосон бол completed_status_ids руу автоматаар буцдаг байсан
    // нь бусад тооцооллуудтай (нийт дүн, багана бүрийн нийлбэр) зөрүүтэй
    // үр дүн өгдөг байсны шалтгаан
    const woStatusFilter = checked.length
      ? { _in: isProxy(checked) ? toRaw(checked) : checked }
      : null

    console.log('bulk_filters', {
      status: '1',
      work_order: {
        company_id: myCompanyId,
        location: { _in: locationIds },
        started_at: {
          _gte: toLocalIsoStr(fromDate),
          _lte: toLocalIsoStr(toDate),
        },
        ...(woStatusFilter ? { wo_status: woStatusFilter } : {}),
        action_status: { _eq: 2 },
      },
    })
    // BULK API CALLS - Get all data for all locations in 3 calls instead of 750+
    const bulkCalls = [
      // 1. Get all trades for all locations
      () =>
        getItems({
          collection: 'Work_order_Tradecode',
          params: {
            filter: {
              status: '1',
              work_order: {
                company_id: myCompanyId,
                location: { _in: locationIds },
                started_at: {
                  _gte: toLocalIsoStr(fromDate),
                  _lte: toLocalIsoStr(toDate),
                },
                ...(woStatusFilter ? { wo_status: woStatusFilter } : {}),
                action_status: { _eq: 2 },
              },
            },
            fields: [
              'actual_total',
              'work_order.location.id',
              'work_order.location.name',
              'work_order.wo_number',
            ],
          },
        }),
      // 2. Get all parts for all locations
      () =>
        getItems({
          collection: 'Work_order_Parts',
          params: {
            filter: {
              status: '1',
              work_order: {
                company_id: myCompanyId,
                location: { _in: locationIds },
                started_at: {
                  _gte: toLocalIsoStr(fromDate),
                  _lte: toLocalIsoStr(toDate),
                },
                ...(woStatusFilter ? { wo_status: woStatusFilter } : {}),
                action_status: { _eq: 2 },
              },
            },
            fields: [
              'actual_amount',
              'work_order.location.id',
              'work_order.location.name',
              'work_order.wo_number',
            ],
          },
        }),
      // 3. Get all work orders for all locations
      () =>
        getItems({
          collection: 'Work_order',
          params: {
            filter: {
              company_id: myCompanyId,
              location: { _in: locationIds },
              started_at: {
                _gte: toLocalIsoStr(fromDate),
                _lte: toLocalIsoStr(toDate),
              },
              ...(woStatusFilter ? { wo_status: woStatusFilter } : {}),
              action_status: { _eq: 2 },
            },
            fields: [
              'other_actual_amount',
              'location.id',
              'location.name',
              'wo_number',
            ],
          },
        }),
    ]

    // console.log(
    //   '[loadLocations] Making 3 bulk API calls instead of',
    //   locationIds.length * 3,
    //   'individual calls',
    // )

    // Execute bulk calls using existing batchApiCalls
    const [tradesResponse, partsResponse, workOrdersResponse] =
      await batchApiCalls(bulkCalls)

    console.log('[tradesResponse] ', tradesResponse)
    console.log('[partsResponse] ', partsResponse)
    console.log('[workOrdersResponse] ', workOrdersResponse)
    // Group data by location ID
    const locationTotals = {}

    // Initialize all locations with 0 totals
    response.data?.forEach((loc) => {
      locationTotals[loc.id] = {
        name: loc.name,
        id: loc.id,
        tradesTotal: 0,
        partsTotal: 0,
        otherTotal: 0,
      }
    })

    // Sum trades by location
    tradesResponse?.forEach((trade) => {
      const locationId = trade.work_order?.location?.id
      if (locationId && locationTotals[locationId]) {
        locationTotals[locationId].tradesTotal += trade.actual_total || 0
      }
    })

    // Sum parts by location
    partsResponse?.forEach((part) => {
      const locationId = part.work_order?.location?.id
      if (locationId && locationTotals[locationId]) {
        locationTotals[locationId].partsTotal += part.actual_amount || 0
      }
    })

    // Sum other costs by location
    workOrdersResponse?.forEach((wo) => {
      const locationId = wo.location?.id
      if (locationId && locationTotals[locationId]) {
        locationTotals[locationId].otherTotal += wo.other_actual_amount || 0
      }
    })

    // console.log(
    //   '[loadLocations] Aggregated totals for',
    //   locationTotals,
    //   'locationTotals',
    // )
    // Convert to final format
    locationCosts.value = Object.values(locationTotals).map((loc) => ({
      label: loc.name,
      id: loc.id,
      total: loc.tradesTotal + loc.partsTotal + loc.otherTotal,
    }))

    // console.log(
    //   '[locationCosts] Processed',
    //   locationCosts.value,
    //   'locations efficiently',
    // )
  } catch (error) {
    console.error('Error loading locations:', error)
  } finally {
    loading.value = false
  }
}

const loadPartsSum = async (
  from = null,
  to = null,
  checked = [],
  location = [],
  type = null,
) => {
  loading.value = true
  try {
    const today = new Date()
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах

    const fromDate = toRangeStart(from, customFrom.value)
    const toDate = toRangeEnd(to, customTo.value)

    let filters = {
      status: '1',
      work_order: {
        company_id: { _eq: myCompanyId },
        started_at: {
          _gte: toLocalIsoStr(fromDate),
          _lte: toLocalIsoStr(toDate),
        },
        action_status: { _eq: 2 },
      },
    }

    if (location.length) {
      if (isProxy(location)) {
        location = toRaw(location)
      }
      filters.work_order.location = { _in: location }
    }

    // status checked
    if (checked.length) {
      if (isProxy(checked)) {
        checked = toRaw(checked)
      }
      filters.work_order.wo_status = { _in: checked }
    }
    // console.log('loadPartsSum_filters', filters)
    console.log('Work_order_Parts_filters_tab1', filters)

    const items = await getItems({
      collection: 'Work_order_Parts',
      params: {
        filter: filters,
        aggregate: {
          sum: 'amount,actual_amount',
        },
      },
    })

    if (location.length && type == 'loadLocations') {
      loc_parts_sum.value = items[0].sum.amount ? items[0].sum.amount : 0
      loc_actual_parts_sum.value = items[0].sum.actual_amount
        ? items[0].sum.actual_amount
        : 0
    } else {
      parts_sum.value = items[0].sum.amount ? items[0].sum.amount : 0
      actual_parts_sum.value = items[0].sum.actual_amount
        ? items[0].sum.actual_amount
        : 0
    }
    loading.value = false

    // console.log('Work_order_Parts', items)
    // console.log('actual_parts_sum', actual_parts_sum)
  } catch (e) {
    loading.value = false
    console.log(e)
  }
}

const loadTradesSum = async (
  from = null,
  to = null,
  checked = [],
  location = [],
  type = null,
) => {
  loading.value = true
  try {
    const today = new Date()
    // new Date(today.getFullYear(), today.getMonth() - 9, 1, 0, 0, 1) //10month
    //  new Date(
    //       today.getFullYear(),
    //       today.getMonth(),
    //       today.getDate(),
    //       23,
    //       59,
    //       59,
    //     )
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах
    const fromDate = toRangeStart(from, customFrom.value)
    const toDate = toRangeEnd(to, customTo.value)

    // console.log('hi2=fromDate', fromDate, from)
    // console.log('hi3=toDate', toDate, to)
    // hi1=toDate 2025-05-09 2025-05-26

    let filters = {
      status: '1',
      work_order: {
        company_id: { _eq: myCompanyId },
        started_at: {
          _gte: toLocalIsoStr(fromDate),
          _lte: toLocalIsoStr(toDate),
        },
        action_status: { _eq: 2 },
      },
    }

    if (location.length) {
      if (isProxy(location)) {
        location = toRaw(location)
      }
      filters.work_order.location = { _in: location }
    }
    if (checked.length) {
      if (isProxy(checked)) {
        checked = toRaw(checked)
      }
      filters.work_order.wo_status = { _in: checked }
    }
    console.log('Work_order_Tradecode_filters_tab1', filters)

    const items = await getItems({
      collection: 'Work_order_Tradecode',
      params: {
        filter: filters,
        aggregate: {
          sum: 'total,duration,actual_total,actual_duration',
        },
      },
    })

    if (location.length && type == 'loadLocations') {
      loc_trades_sum.value = items[0].sum.total
      loc_actual_trades_sum.value = items[0].sum.actual_total
    } else {
      trades_sum.value = items[0].sum.total
      actual_trades_sum.value = items[0].sum.actual_total
    }
    loading.value = false
    // console.log('Work_order_Tradecode', items)
  } catch (e) {
    loading.value = false
    console.log(e)
  }
}

const loadCostsSum = async (
  from = null,
  to = null,
  checked = [],
  location = [],
  type = null,
) => {
  loading.value = true
  try {
    const today = new Date()
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах

    const fromDate = toRangeStart(from, customFrom.value)
    const toDate = toRangeEnd(to, customTo.value)

    let filters = {
      company_id: { _eq: myCompanyId },
      // wo_status: { _in: completed_status_ids },
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
    // console.log('_filters', filters)
    const cost_items = await getItems({
      collection: 'Work_order',
      params: {
        filter: filters,
        aggregate: {
          sum: 'other_actual_amount,other_amount',
        },
        sort: 'started_at',

        // limit: -1,
        // page: page,
        // sort: sort_array,
        // meta: 'filter_count',
        // search: search.value,
        // fields: ['*'],
      },
    })
    // console.log('cost_itemss', cost_items)

    if (location.length && type == 'loadLocations') {
      loc_other_actual_amount.value = cost_items[0].sum.other_actual_amount
      loc_other_amount.value = cost_items[0].sum.other_amount
    } else {
      other_actual_amount.value = cost_items[0].sum.other_actual_amount
      other_amount.value = cost_items[0].sum.other_amount
    }

    // totalItems.value = cost_items.meta.filter_count
    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

const loadCostsCount = async (
  from = null,
  to = null,
  checked = [],
  location = [],
) => {
  loading.value = true
  try {
    const today = new Date()
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах

    const fromDate = toRangeStart(from, customFrom.value)
    const toDate = toRangeEnd(to, customTo.value)

    const filters = {
      // wo_status: { _in: completed_status_ids },
      action_status: { _eq: 2 },
      started_at: {
        _gte: toLocalIsoStr(fromDate),
        _lte: toLocalIsoStr(toDate),
      },
    }

    // console.log('Other--filters', filters)
    if (checked.length) {
      if (isProxy(checked)) {
        checked = toRaw(checked)
      }
      filters.wo_status = { _in: checked }
    }
    if (location.length) {
      if (isProxy(location)) {
        location = toRaw(location)
      }
      filters.location = { _in: location }
    }

    const cost_items = await getItems({
      collection: 'Work_order',
      params: {
        filter: {
          ...filters,
          company_id: { _eq: myCompanyId },
        },
        meta: 'filter_count',
        sort: 'started_at',

        fields: ['other_actual_amount,other_amount,started_at'],
      },
    })
    console.log('loadCostsCount_filter_tab1', filters)
    // totalItems.value = cost_items.meta.filter_count
    loading.value = false
    return cost_items.data
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

const loadPartsCount = async (
  from = null,
  to = null,
  checked = [],
  location = [],
) => {
  loading.value = true
  try {
    const today = new Date()
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах

    const fromDate = toRangeStart(from, customFrom.value)
    const toDate = toRangeEnd(to, customTo.value)

    const filters = {
      status: '1',
      work_order: {
        company_id: { _eq: myCompanyId },
        // wo_status: { _in: completed_status_ids },
        action_status: { _eq: 2 },
        started_at: {
          _gte: toLocalIsoStr(fromDate),
          _lte: toLocalIsoStr(toDate),
        },
      },
    }

    if (checked.length) {
      if (isProxy(checked)) {
        checked = toRaw(checked)
      }
      filters.work_order.wo_status = { _in: checked }
    }

    if (location.length) {
      if (isProxy(location)) {
        location = toRaw(location)
      }
      filters.work_order.location = { _in: location }
    }
    // console.log('Parts--filters', filters)

    const items = await getItems({
      collection: 'Work_order_Parts',
      params: {
        filter: filters,
        meta: 'filter_count',
        sort: 'work_order.started_at',
        fields: ['amount,actual_amount, work_order.started_at'],
      },
    })

    loading.value = false
    // console.log('Work_order_Parts_count', items)
    return items.data
  } catch (e) {
    loading.value = false
    console.log(e)
  }
}

const loadTradesCount = async (
  from = null,
  to = null,
  checked = [],
  location = [],
) => {
  loading.value = true
  try {
    const today = new Date()
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах
    const fromDate = toRangeStart(from, customFrom.value)
    const toDate = toRangeEnd(to, customTo.value)

    const filters = {
      status: '1',
      work_order: {
        company_id: { _eq: myCompanyId },
        // wo_status: { _in: completed_status_ids },
        action_status: { _eq: 2 },
        started_at: {
          _gte: toLocalIsoStr(fromDate),
          _lte: toLocalIsoStr(toDate),
        },
      },
    }
    if (checked.length) {
      if (isProxy(checked)) {
        checked = toRaw(checked)
      }
      filters.work_order.wo_status = { _in: checked }
    }
    if (location.length) {
      if (isProxy(location)) {
        location = toRaw(location)
      }
      filters.work_order.location = { _in: location }
    }

    // console.log('Count-----filters', filters)
    const items = await getItems({
      collection: 'Work_order_Tradecode',
      params: {
        filter: filters,
        meta: 'filter_count',
        sort: 'work_order.started_at',
        fields: ['total,actual_total, work_order.started_at'],
      },
    })

    loading.value = false
    // console.log('Work_order_Tradecode_count', items)
    return items.data
  } catch (e) {
    loading.value = false
    console.log(e)
  }
}

function moneyFormat(value: number): string {
  if (isNaN(value)) return '0'
  if (!value) return '0'
  return value.toLocaleString('mn-MN') + ' ₮'
}

onMounted(async () => {
  // console.log('onMounted_OOK')

  await loadTradesSum() //actual_trades_sum
  await loadPartsSum() //actual_parts_sum
  await loadCostsSum() //other_actual_amount_sum

  let others = await loadCostsCount()
  let trades = await loadTradesCount()
  let parts = await loadPartsCount()

  tab1_counts.value = await grapicDatas({
    trades: trades,
    parts: parts,
    others: others,
    from: customFrom.value,
    to: customTo.value,
  })

  lineRevenue.value = useLineCostsRevenue()

  await loadLocations() //other_actual_amount_sum
  pieBar.value = usePieBar()
  plannedActualChart.value = usePlannedVsActual()
  breakdownChart.value = useCostBreakdown()
})

watch(
  props,
  async (newProps) => {
    // Use debounced refresh to prevent excessive API calls
    await debouncedRefresh(newProps.filterData)
  },
  { deep: true },
)
</script>

<template>
  <!-- Stat Planned Total operating cost -->
  <div class="col-span-12 md:col-span-3 cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Planned Total operation')"
      :icon="'icon-park-outline:paper-money-two'"
      :icon_class="'bg-violet-100 text-violet-500 dark:bg-violet-500/20 dark:text-violet-400 dark:border-violet-500 dark:border-2'"
      :cost="moneyFormat(total_amount)"
    />
  </div>

  <!-- Stat Planned parts cost -->
  <div class="col-span-12 md:col-span-3 cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Planned parts cost')"
      :icon="'simple-icons:steamdb'"
      :icon_class="'bg-amber-100 text-amber-500 dark:border-2 dark:border-amber-500 dark:bg-amber-500/20 dark:text-amber-400'"
      :cost="moneyFormat(parts_sum)"
    />
  </div>

  <!-- Stat Planned trades cost -->
  <div class="col-span-12 md:col-span-3 cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Planned trades cost')"
      :icon="'simple-icons:steamdb'"
      :icon_class="'bg-indigo-100 text-indigo-500 dark:bg-indigo-500/20 dark:text-indigo-400 dark:border-indigo-500 dark:border-2'"
      :cost="moneyFormat(trades_sum)"
    />
  </div>

  <!-- Stat Planned other cost -->
  <div class="col-span-12 md:col-span-3 cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Planned other cost')"
      :icon="'fluent:hexagon-three-24-regular'"
      :icon_class="'bg-cyan-100 text-cyan-500 dark:bg-cyan-500/20 dark:text-cyan-400 dark:border-cyan-500 dark:border-2'"
      :cost="moneyFormat(other_amount)"
    />
  </div>

  <!-- Stat Total operating cost -->
  <div class="col-span-12 md:col-span-3 cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Actual Total operation')"
      :icon="'icon-park-outline:paper-money-two'"
      :icon_class="'bg-success-100 text-success-500 dark:bg-success-500/20 dark:text-success-400 dark:border-success-500 dark:border-2'"
      :cost="moneyFormat(actual_total_amount)"
    />
  </div>

  <!-- Stat total part cost -->
  <div class="col-span-12 md:col-span-3 cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Actual parts cost')"
      :icon="'simple-icons:steamdb'"
      :icon_class="'bg-yellow-100 text-yellow-500 dark:border-2 dark:border-yellow-500 dark:bg-yellow-500/20 dark:text-yellow-400'"
      :cost="moneyFormat(actual_parts_sum)"
    />
  </div>

  <!-- Stat Actual trades cost -->
  <div class="col-span-12 md:col-span-3 cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Actual trades cost')"
      :icon="'simple-icons:steamdb'"
      :icon_class="'bg-primary-100 text-primary-500 dark:bg-primary-500/20 dark:text-primary-400 dark:border-primary-500 dark:border-2'"
      :cost="moneyFormat(actual_trades_sum)"
    />
  </div>

  <!-- Stat Actual other cost -->
  <div class="col-span-12 md:col-span-3 cardBox">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Actual other cost')"
      :icon="'fluent:hexagon-three-24-regular'"
      :icon_class="'bg-blue-100 text-blue-500 dark:bg-blue-500/20 dark:text-blue-400 dark:border-blue-500 dark:border-2'"
      :cost="moneyFormat(other_actual_amount)"
    />
  </div>

  <!-- Chart cost-->
  <div class="col-span-12 md:col-span-8 cardBox">
    <CostLineRevenue
      v-if="lineRevenue"
      :line-revenue="lineRevenue"
      :lastMonth="last_month_cnt.toString()"
      :thisMonth="this_month_cnt.toString()"
      :currency="true"
    />
  </div>

  <!-- Chart pie-->
  <div class="col-span-12 md:col-span-4 cardBox">
    <CostPie
      v-if="pieBar"
      :pie-bar="pieBar"
      :is-open-filter="props.isOpenFilter"
    />
  </div>

  <!-- Chart Planned vs Actual -->
  <div class="col-span-12 md:col-span-8 cardBox">
    <BaseCard v-if="plannedActualChart" class="p-6">
      <BaseHeading
        as="h3"
        size="md"
        weight="semibold"
        lead="tight"
        class="mb-4 text-muted-800 dark:text-white"
      >
        <span>{{ t('Planned vs Actual cost') }}</span>
      </BaseHeading>
      <AddonApexcharts v-bind="plannedActualChart" />
    </BaseCard>
  </div>

  <!-- Chart Cost breakdown donut -->
  <div class="col-span-12 md:col-span-4 cardBox">
    <BaseCard v-if="breakdownChart" class="p-6">
      <BaseHeading
        as="h3"
        size="md"
        weight="semibold"
        lead="tight"
        class="mb-4 text-muted-800 dark:text-white"
      >
        <span>{{ t('Cost breakdown') }}</span>
      </BaseHeading>
      <template v-if="breakdownChart.series?.some?.((v) => v > 0)">
        <AddonApexcharts v-bind="breakdownChart" />
      </template>
      <div
        v-else
        class="flex h-40 items-center justify-center text-sm text-muted-400"
      >
        {{ t('No data') }}
      </div>
    </BaseCard>
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
  box-shadow:
    0 1px 2px rgba(15, 23, 42, 0.06),
    0 8px 16px -6px rgba(15, 23, 42, 0.12),
    0 20px 32px -12px rgba(15, 23, 42, 0.18);
}

.cardBox:hover :deep(.nui-card) {
  transform: translateY(-6px) rotateX(2deg);
  box-shadow:
    0 2px 4px rgba(15, 23, 42, 0.08),
    0 16px 24px -8px rgba(15, 23, 42, 0.18),
    0 32px 48px -16px rgba(15, 23, 42, 0.28);
}

:global(.dark) .cardBox :deep(.nui-card) {
  box-shadow:
    0 1px 2px rgba(0, 0, 0, 0.4),
    0 8px 16px -6px rgba(0, 0, 0, 0.5),
    0 20px 32px -12px rgba(0, 0, 0, 0.6);
}

:global(.dark) .cardBox:hover :deep(.nui-card) {
  box-shadow:
    0 2px 4px rgba(0, 0, 0, 0.5),
    0 16px 24px -8px rgba(0, 0, 0, 0.6),
    0 32px 48px -16px rgba(0, 0, 0, 0.7);
}
</style>
