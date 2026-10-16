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
// Import optimization composable
import {
  batchApiCalls,
  useDebouncedTabRefresh,
} from '~/composables/useTabOptimization'
const { t } = useI18n({ useScope: 'global' })
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

definePageMeta({
  title: 'Safety metrics',
  middleware: ['auth'],
  preview: {
    title: 'Safety metrics',
    description: 'Safety performance metrics and statistics',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-analytics.png',
    srcDark: '/img/screens/dashboards-analytics-dark.png',
    order: 4,
  },
})

const search = ref('')
const serverItems = ref([])
const tab1_counts = ref([])
const isModalOpen = ref(false)
const activeTab = ref('cost')

//tabs_count
const lineRevenue = ref(null)
const pieBar = ref(null)
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

// Filter section
const fromMenu = ref(false)
const toMenu = ref(false)
const today = new Date()

// Сүүлийн 10 сарын өмнөх сар (энэ сар багтсан)
const fromDate = new Date(today.getFullYear(), today.getMonth() - 9, 1)
const toDate = today
const customFrom = ref(fromDate.toISOString().split('T')[0])
const customTo = ref(toDate.toISOString().split('T')[0])

const isDropdownOpen = ref(true)
const date_filer = ref(false)
const location = ref(null)
const dashboard_type = ref(null)

const loading = ref(false)

// Updated data structure for chart
const locationCosts = ref([
  { label: 'Location A', value: 25000, color: '#4F46E5' },
  { label: 'Location B', value: 15000, color: '#10B981' },
  { label: 'Location C', value: 20000, color: '#F59E0B' },
  { label: 'Location D', value: 10000, color: '#EF4444' },
])

const refresh = async (filterData = {}) => {
  console.log('[Tab4] Refresh called with filters:', filterData)

  const params = {
    from: filterData.customFrom || null,
    to: filterData.customTo || null,
    checked: filterData.checked || null,
    location: filterData.location || null,
  }

  try {
    // Batch all API calls to reduce network congestion
    const apiCalls = [
      () =>
        loadTradesSum(params.from, params.to, params.checked, params.location),
      () =>
        loadPartsSum(params.from, params.to, params.checked, params.location),
      () =>
        loadCostsSum(params.from, params.to, params.checked, params.location),
      () => loadCostsCount(params.from, params.to, params.checked),
      () => loadTradesCount(params.from, params.to, params.checked),
      () => loadPartsCount(params.from, params.to, params.checked),
    ]

    console.log('[Tab4] Starting batch API calls...')
    const results = await batchApiCalls(apiCalls)

    // Process results
    const [tradesSum, partsSum, costsSum, costsCount, tradesCount, partsCount] =
      results

    console.log('[Tab4] Batch refresh completed successfully')
    return {
      tradesSum,
      partsSum,
      costsSum,
      costsCount,
      tradesCount,
      partsCount,
    }
  } catch (error) {
    console.error('[Tab4] Batch refresh failed:', error)
    throw error
  }
}

// Create debounced refresh function
const debouncedRefresh = useDebouncedTabRefresh('tab4', refresh, 500)

//counts
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
      { name: 'Trades', data: tradesData },
      { name: 'Parts', data: partsData },
      { name: 'Others', data: othersData },
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
    trades.forEach((item) => {
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
    parts.forEach((item) => {
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
    others.forEach((item) => {
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
      { name: 'Trades', data: tradesActualData },
      { name: 'Parts', data: partsActualData },
      { name: 'Others', data: othersActualData },
    ]

    return entrySeries
  } catch (error) {
    console.error('Error convert data:', error)
    return []
  }
}

//tab4 funcdtions
const sparkLineOne = reactive(useSparkLineOne())
const sparkLineTwo = reactive(useSparkLineTwo())

const sparkLineThree = reactive(useSparkLineThree())
const sparkLineFour = reactive(useSparkLineFour())
const areaCustomers = reactive(useAreaCustomers())
const radialSalesRevenue = reactive(useRadialSalesRevenue())
const radialSmallOne = reactive(useRadialSmallOne())
const radialSmallTwo = reactive(useRadialSmallTwo())
const radialSmallThree = reactive(useRadialSmallThree())
const gaugePersonal = reactive(useGaugePersonal())
const barOrders = reactive(useBarOrders())

function useSparkLineOne() {
  const { primary } = useTailwindColors()
  const height = 60
  const type = 'line'

  const options = {
    chart: {
      id: 'sparkline1',
      sparkline: {
        enabled: true,
      },
      group: 'sparklines',
    },
    grid: {
      padding: {
        top: 10,
        right: 0,
        bottom: 0,
        left: 0,
      },
    },
    stroke: {
      curve: 'smooth',
      width: [2],
    },
    markers: {
      size: 0,
    },
    yaxis: {
      min: 0,
      labels: {
        minWidth: 100,
      },
    },
    tooltip: {
      fixed: {
        enabled: true,
        position: 'right',
      },
      x: {
        show: false,
      },
    },
    colors: [primary.value],
  } as const

  const series = shallowRef([
    {
      name: 'Sales',
      data: [2565, 6126, 4271, 5249, 2245, 4424, 1752, 3996, 976, 2157],
    },
  ])

  return { height, type, options, series }
}

function useSparkLineTwo() {
  const { success } = useTailwindColors()
  const type = 'line'
  const height = 60

  const options = {
    chart: {
      id: 'sparkline2',
      sparkline: {
        enabled: true,
      },
      group: 'sparklines',
    },
    grid: {
      padding: {
        top: 10,
        right: 0,
        bottom: 0,
        left: 0,
      },
    },
    stroke: {
      curve: 'smooth',
      width: [2],
    },
    markers: {
      size: 0,
    },
    yaxis: {
      min: 0,
      labels: {
        minWidth: 100,
      },
    },
    tooltip: {
      fixed: {
        enabled: true,
        position: 'right',
      },
      x: {
        show: false,
      },
      y: {
        formatter: asKDollar,
      },
    },
    colors: [success.value],
  } as const

  const series = shallowRef([
    {
      name: 'Income',
      data: [12.2, 14.5, 2.5, 47.5, 32.5, 44.5, 14.8, 55.5, 41.3, 69.7],
    },
  ])

  return { height, type, options, series }
}

function useSparkLineThree() {
  const { info } = useTailwindColors()
  const height = 60
  const type = 'line'

  const options = {
    chart: {
      id: 'sparkline3',
      sparkline: {
        enabled: true,
      },
      group: 'sparklines',
    },
    grid: {
      padding: {
        top: 10,
        right: 0,
        bottom: 0,
        left: 0,
      },
    },
    stroke: {
      curve: 'smooth',
      width: [2],
    },
    markers: {
      size: 0,
    },
    tooltip: {
      fixed: {
        enabled: true,
        position: 'right',
      },
      x: {
        show: false,
      },
    },
    colors: [info.value],
    xaxis: {
      crosshairs: {
        width: 1,
      },
    },
    yaxis: {
      min: 0,
      labels: {
        minWidth: 100,
      },
    },
  } as const

  const series = shallowRef([
    {
      name: 'New Orders',
      data: [4457, 4533, 7274, 3272, 5876, 3271, 4614, 3553, 4835, 1579],
    },
  ])

  return { height, type, options, series }
}

function useSparkLineFour() {
  const { danger } = useTailwindColors()
  const type = 'line'
  const height = 60

  const options = {
    chart: {
      id: 'sparkline4',
      sparkline: {
        enabled: true,
      },
      group: 'sparklines',
    },
    grid: {
      padding: {
        top: 10,
        right: 0,
        bottom: 0,
        left: 0,
      },
    },
    stroke: {
      curve: 'smooth',
      width: [2],
    },
    markers: {
      size: 0,
    },
    tooltip: {
      fixed: {
        enabled: true,
        position: 'right',
      },
      x: {
        show: false,
      },
    },
    colors: [danger.value],
    xaxis: {
      crosshairs: {
        width: 1,
      },
    },
    yaxis: {
      min: 0,
      labels: {
        minWidth: 100,
      },
    },
  } as const

  const series = shallowRef([
    {
      name: 'Abandonned',
      data: [1412, 725, 427, 655, 145, 325, 197, 584, 424, 651],
    },
  ])

  return { height, type, options, series }
}

function useAreaCustomers() {
  const { primary, info, success } = useTailwindColors()
  const type = 'area'
  const height = 258

  const options = {
    chart: {
      toolbar: {
        show: false,
      },
    },
    colors: [primary.value, info.value, success.value],
    title: {
      show: false,
      text: undefined,
      align: 'left',
    },
    legend: {
      show: true,
      position: 'top',
    },
    dataLabels: {
      enabled: false,
    },
    stroke: {
      width: [2, 2, 2],
      curve: 'smooth',
    },
    xaxis: {
      type: 'datetime',
      categories: [
        '2020-09-19T00:00:00.000Z',
        '2020-09-20T01:30:00.000Z',
        '2020-09-21T02:30:00.000Z',
        '2020-09-22T03:30:00.000Z',
        '2020-09-23T04:30:00.000Z',
        '2020-09-24T05:30:00.000Z',
        '2020-09-25T06:30:00.000Z',
      ],
    },
    tooltip: {
      x: {
        format: 'dd/MM/yy HH:mm',
      },
    },
  }

  const series = shallowRef([
    {
      name: t('Returning'),
      data: [31, 40, 28, 51, 42, 109, 100],
    },
    {
      name: t('Newcomers'),
      data: [11, 32, 45, 32, 34, 52, 41],
    },
    {
      name: t('Abandonned'),
      data: [78, 53, 36, 10, 14, 5, 2],
    },
  ])

  return {
    type,
    height,
    options,
    series,
  }
}

function useRadialSalesRevenue() {
  const { primary } = useTailwindColors()
  const type = 'radialBar'
  const height = 155

  const options = {
    chart: {
      toolbar: {
        show: false,
      },
    },
    colors: [primary.value],
    plotOptions: {
      radialBar: {
        hollow: {
          size: '75%',
        },
        dataLabels: {
          show: true,
          name: {
            show: false,
            fontSize: '12px',
            fontFamily: 'Roboto, sans-serif',
            fontWeight: 400,
            offsetY: 5,
          },
          value: {
            show: true,
            fontWeight: 600,
            fontFamily: 'Roboto, sans-serif',
            fontSize: '16px',
            offsetY: 5,
          },
        },
      },
    },
    labels: ['Progress'],
  }

  const series = shallowRef([65])

  return {
    type,
    height,
    options,
    series,
  }
}

function useRadialSmallOne() {
  const { primary } = useTailwindColors()
  const type = 'radialBar'
  const height = 100

  const options = {
    chart: {
      height: 100,
      type: 'radialBar',
      offsetY: -10,
      toolbar: {
        show: false,
      },
    },
    colors: [primary.value],
    plotOptions: {
      radialBar: {
        hollow: {
          size: '35%',
        },
        dataLabels: {
          show: false,
        },
      },
    },
    labels: [''],
  }

  const series = shallowRef([31])

  return {
    type,
    height,
    options,
    series,
  }
}

function useRadialSmallTwo() {
  const { success } = useTailwindColors()
  const type = 'radialBar'
  const height = 100

  const options = {
    chart: {
      height: 100,
      type: 'radialBar',
      offsetY: -10,
      toolbar: {
        show: false,
      },
    },
    colors: [success.value],
    plotOptions: {
      radialBar: {
        hollow: {
          size: '35%',
        },
        dataLabels: {
          show: false,
        },
      },
    },
    labels: [''],
  }

  const series = shallowRef([53])

  return {
    type,
    height,
    options,
    series,
  }
}

function useRadialSmallThree() {
  const { danger } = useTailwindColors()
  const type = 'radialBar'
  const height = 100

  const options = {
    chart: {
      height: 100,
      type: 'radialBar',
      offsetY: -10,
      toolbar: {
        show: false,
      },
    },
    colors: [danger.value],
    plotOptions: {
      radialBar: {
        hollow: {
          size: '35%',
        },
        dataLabels: {
          show: false,
        },
      },
    },
    labels: [''],
  }

  const series = shallowRef([84])

  return {
    type,
    height,
    options,
    series,
  }
}

function useGaugePersonal() {
  const { primary } = useTailwindColors()
  const type = 'radialBar'
  const height = 220

  const options = {
    title: {
      text: undefined,
    },
    chart: {
      sparkline: {
        enabled: true,
      },
      toolbar: {
        show: false,
      },
    },
    colors: [primary.value],
    plotOptions: {
      radialBar: {
        startAngle: -90,
        endAngle: 90,
        track: {
          background: '#e7e7e7',
          strokeWidth: '97%',
          margin: 5, // margin is in pixels
          dropShadow: {
            enabled: false,
            top: 2,
            left: 0,
            color: '#999',
            opacity: 1,
            blur: 2,
          },
        },
        hollow: {
          margin: 0,
          size: '35%',
        },
        dataLabels: {
          name: {
            show: false,
          },
          value: {
            offsetY: -2,
            fontSize: '22px',
          },
        },
      },
    },
    fill: {
      type: 'gradient',
      gradient: {
        shade: 'light',
        shadeIntensity: 0.1,
        inverseColors: false,
        opacityFrom: 1,
        opacityTo: 1,
        stops: [0, 50, 53, 91],
      },
    },
    labels: ['Average Results'],
  }

  const series = shallowRef([76])

  return {
    type,
    height,
    options,
    series,
  }
}

function useBarOrders() {
  const { primary, success } = useTailwindColors()
  const type = 'bar'
  const height = 210

  const series = shallowRef<any[]>([])

  const options = {
    chart: {
      toolbar: {
        show: false,
      },
    },
    colors: [primary.value, success.value],
    dataLabels: {
      enabled: false,
    },
    noData: {
      text: 'Loading...',
    },
    xaxis: {
      type: 'category',
      tickPlacement: 'on',
      labels: {
        rotate: -45,
        rotateAlways: true,
      },
    },
  } as const

  // delay the data loading
  let timeout: any
  let timeout2: any

  onMounted(() => {
    timeout = setTimeout(() => {
      series.value.push({
        name: 'Orders',
        data: [
          {
            x: 'Jan',
            y: 322,
          },
          {
            x: 'Feb',
            y: 459,
          },
          {
            x: 'Mar',
            y: 212,
          },
          {
            x: 'Apr',
            y: 345,
          },
          {
            x: 'May',
            y: 111,
          },
          {
            x: 'Jun',
            y: 189,
          },
          {
            x: 'Jul',
            y: 498,
          },
          {
            x: 'Aug',
            y: 612,
          },
          {
            x: 'Sep',
            y: 451,
          },
          {
            x: 'Oct',
            y: 248,
          },
          {
            x: 'Nov',
            y: 306,
          },
          {
            x: 'Dec',
            y: 366,
          },
        ],
      })
    }, 1500)

    timeout2 = setTimeout(() => {
      series.value.push({
        name: 'Abandonned',
        data: [
          {
            x: 'Jan',
            y: 25,
          },
          {
            x: 'Feb',
            y: 49,
          },
          {
            x: 'Mar',
            y: 36,
          },
          {
            x: 'Apr',
            y: 84,
          },
          {
            x: 'May',
            y: 64,
          },
          {
            x: 'Jun',
            y: 131,
          },
          {
            x: 'Jul',
            y: 48,
          },
          {
            x: 'Aug',
            y: 144,
          },
          {
            x: 'Sep',
            y: 96,
          },
          {
            x: 'Oct',
            y: 11,
          },
          {
            x: 'Nov',
            y: 31,
          },
          {
            x: 'Dec',
            y: 8,
          },
        ],
      })
    }, 2500)
  })
  onBeforeUnmount(() => {
    clearTimeout(timeout)
    clearTimeout(timeout2)
  })

  return {
    height,
    type,
    series,
    options,
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

// console.log('actual_total_amount', actual_total_amount)
// console.log('total_amount', total_amount)

const loadLocations = async () => {
  if (loading.value) return

  loading.value = true
  try {
    // Get all locations first
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

    console.log(
      '[Tab4 loadLocations] Processing',
      response.data?.length || 0,
      'locations',
    )

    // Prepare date filters for bulk queries - handle string date values
    const today = new Date()
    const fromDateObj = customFrom.value
      ? new Date(customFrom.value)
      : new Date(today.getFullYear(), today.getMonth() - 9, 1)
    const toDateObj = customTo.value ? new Date(customTo.value) : today

    const fromDate = new Date(
      fromDateObj.getFullYear(),
      fromDateObj.getMonth() - 9,
      1,
      0,
      0,
      1,
    ) // 10month
    const toDate = new Date(
      toDateObj.getFullYear(),
      toDateObj.getMonth(),
      toDateObj.getDate(),
      23,
      59,
      59,
    )

    // Get all location IDs for bulk queries
    const locationIds = response.data?.map((loc) => loc.id) || []

    if (locationIds.length === 0) {
      locationCosts.value = []
      loading.value = false
      return
    }

    // BULK API CALLS - Get all data for all locations in 3 calls instead of N*3
    const bulkCalls = [
      // 1. Get all trades for all locations
      () =>
        getItems({
          collection: 'Work_order_Tradecode',
          params: {
            filter: {
              status: '1',
              work_order: {
                company_id: { _eq: myCompanyId },
                location: { _in: locationIds },
                started_at: {
                  _gte: fromDate.toISOString(),
                  _lte: toDate.toISOString(),
                },
                wo_status: { _in: completed_status_ids },
              },
            },
            fields: [
              'actual_total',
              'work_order.location.id',
              'work_order.location.name',
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
                company_id: { _eq: myCompanyId },
                location: { _in: locationIds },
                started_at: {
                  _gte: fromDate.toISOString(),
                  _lte: toDate.toISOString(),
                },
                wo_status: { _in: completed_status_ids },
              },
            },
            fields: [
              'actual_amount',
              'work_order.location.id',
              'work_order.location.name',
            ],
          },
        }),
      // 3. Get all work orders for all locations
      () =>
        getItems({
          collection: 'Work_order',
          params: {
            filter: {
              company_id: { _eq: myCompanyId },
              location: { _in: locationIds },
              started_at: {
                _gte: fromDate.toISOString(),
                _lte: toDate.toISOString(),
              },
              wo_status: { _in: completed_status_ids },
            },
            fields: ['other_actual_amount', 'location.id', 'location.name'],
          },
        }),
    ]

    console.log(
      '[Tab4 loadLocations] Making 3 bulk API calls instead of',
      locationIds.length * 3,
      'individual calls',
    )

    // Execute bulk calls using existing batchApiCalls
    const [tradesResponse, partsResponse, workOrdersResponse] =
      await batchApiCalls(bulkCalls)

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
    tradesResponse?.data?.forEach((trade) => {
      const locationId = trade.work_order?.location?.id
      if (locationId && locationTotals[locationId]) {
        locationTotals[locationId].tradesTotal += trade.actual_total || 0
      }
    })

    // Sum parts by location
    partsResponse?.data?.forEach((part) => {
      const locationId = part.work_order?.location?.id
      if (locationId && locationTotals[locationId]) {
        locationTotals[locationId].partsTotal += part.actual_amount || 0
      }
    })

    // Sum other costs by location
    workOrdersResponse?.data?.forEach((wo) => {
      const locationId = wo.location?.id
      if (locationId && locationTotals[locationId]) {
        locationTotals[locationId].otherTotal += wo.other_actual_amount || 0
      }
    })

    // Convert to final format
    locationCosts.value = Object.values(locationTotals).map((loc) => ({
      label: loc.name,
      id: loc.id,
      total: loc.tradesTotal + loc.partsTotal + loc.otherTotal,
    }))

    console.log(
      '[Tab4 loadLocations] Processed',
      locationCosts.value.length,
      'locations efficiently',
    )
  } catch (error) {
    console.error('Error loading locations:', error)
  } finally {
    loading.value = false
  }
}

const loadPartsSum = async (
  from = null,
  to = null,
  checked = null,
  location = null,
) => {
  loading.value = true
  try {
    const today = new Date()
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах

    const fromDate = from
      ? new Date(from + 'T00:00:01')
      : new Date(today.getFullYear(), today.getMonth() - 9, 1, 0, 0, 1) //10month

    const toDate = to
      ? new Date(to + 'T23:59:59')
      : new Date(
          today.getFullYear(),
          today.getMonth(),
          today.getDate(),
          23,
          59,
          59,
        )

    let filters = {
      status: '1',
      work_order: {
        company_id: { _eq: myCompanyId },
        started_at: {
          _gte: fromDate.toISOString(),
          _lte: toDate.toISOString(),
        },
        wo_status: { _in: completed_status_ids },
      },
    }

    if (location) {
      filters.work_order.location = location
    }
    console.log('loadPartsSum_filters', filters)

    console.log('Partsfilters', filters)

    const items = await getItems({
      collection: 'Work_order_Parts',
      params: {
        filter: filters,
        aggregate: {
          sum: 'amount,actual_amount',
        },
      },
    })

    if (location) {
      loc_parts_sum.value = items[0].sum.amount
      loc_actual_parts_sum.value = items[0].sum.actual_amount
    } else {
      parts_sum.value = items[0].sum.amount
      actual_parts_sum.value = items[0].sum.actual_amount
    }
    loading.value = false

    console.log('Work_order_Parts', items)
  } catch (e) {
    console.log(e)
  }
}

const loadTradesSum = async (
  from = null,
  to = null,
  checked = null,
  location = null,
) => {
  loading.value = true
  try {
    const today = new Date()
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах

    const fromDate = from
      ? new Date(from + 'T00:00:01')
      : new Date(today.getFullYear(), today.getMonth() - 9, 1, 0, 0, 1) //10month

    const toDate = to
      ? new Date(to + 'T23:59:59')
      : new Date(
          today.getFullYear(),
          today.getMonth(),
          today.getDate(),
          23,
          59,
          59,
        )

    let filters = {
      status: '1',
      work_order: {
        company_id: { _eq: myCompanyId },
        started_at: {
          _gte: fromDate.toISOString(),
          _lte: toDate.toISOString(),
        },
        wo_status: { _in: completed_status_ids },
      },
    }

    if (location) {
      filters.work_order.location = location
    }
    filters.work_order.company_id = myCompanyId

    console.log('Work_order_Tradecode_filters', filters)

    const items = await getItems({
      collection: 'Work_order_Tradecode',
      params: {
        filter: filters,
        aggregate: {
          sum: 'total,duration,actual_total,actual_duration',
        },
      },
    })

    if (location) {
      loc_trades_sum.value = items[0].sum.total
      loc_actual_trades_sum.value = items[0].sum.actual_total
    } else {
      trades_sum.value = items[0].sum.total
      actual_trades_sum.value = items[0].sum.actual_total
    }
    loading.value = false
    console.log('Work_order_Tradecode', items)
  } catch (e) {
    console.log(e)
  }
}
const loadCostsSum = async (
  from = null,
  to = null,
  checked = null,
  location = null,
) => {
  loading.value = true
  try {
    const today = new Date()
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах

    const fromDate = from
      ? new Date(from + 'T00:00:01')
      : new Date(today.getFullYear(), today.getMonth() - 9, 1, 0, 0, 1) //10month

    const toDate = to
      ? new Date(to + 'T23:59:59')
      : new Date(
          today.getFullYear(),
          today.getMonth(),
          today.getDate(),
          23,
          59,
          59,
        )

    let filters = {
      company_id: { _eq: myCompanyId },
      wo_status: { _in: completed_status_ids },
      started_at: {
        _gte: fromDate.toISOString(),
        _lte: toDate.toISOString(),
      },
    }

    if (location) {
      filters.location = location
    }
    console.log('loadCostsSum_filters', filters)

    // console.log('filters', filters)
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

    if (location) {
      loc_other_amount.value = cost_items[0].sum.other_amount
      loc_other_actual_amount.value = cost_items[0].sum.other_actual_amount
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

const loadCostsCount = async (from = null, to = null, checked = null) => {
  loading.value = true
  try {
    const today = new Date()
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах

    const fromDate = from
      ? new Date(from + 'T00:00:01')
      : new Date(today.getFullYear(), today.getMonth() - 9, 1, 0, 0, 1) //10month

    const toDate = to
      ? new Date(to + 'T23:59:59')
      : new Date(
          today.getFullYear(),
          today.getMonth(),
          today.getDate(),
          23,
          59,
          59,
        )

    const filters = {
      wo_status: { _in: completed_status_ids },
      company_id: { _eq: myCompanyId },
      started_at: {
        _gte: fromDate.toISOString(),
        _lte: toDate.toISOString(),
      },
    }

    // console.log('Other--filters', filters)

    const cost_items = await getItems({
      collection: 'Work_order',
      params: {
        filter: filters,
        meta: 'filter_count',
        sort: 'started_at',

        fields: ['other_actual_amount,other_amount,started_at'],
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

const loadPartsCount = async (from = null, to = null, checked = null) => {
  loading.value = true
  try {
    const today = new Date()
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах

    const fromDate = from
      ? new Date(from + 'T00:00:01')
      : new Date(today.getFullYear(), today.getMonth() - 9, 1, 0, 0, 1) //10month

    const toDate = to
      ? new Date(to + 'T23:59:59')
      : new Date(
          today.getFullYear(),
          today.getMonth(),
          today.getDate(),
          23,
          59,
          59,
        )

    const filters = {
      status: '1',
      work_order: {
        wo_status: { _in: completed_status_ids },
        company_id: { _eq: myCompanyId },
        started_at: {
          _gte: fromDate.toISOString(),
          _lte: toDate.toISOString(),
        },
      },
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
    console.log(e)
  }
}

const loadTradesCount = async (from = null, to = null, checked = null) => {
  loading.value = true
  try {
    const today = new Date()
    // Хэрэглэгчээс ирсэн `from` болон `to`-г форматлах

    const fromDate = from
      ? new Date(from + 'T00:00:01')
      : new Date(today.getFullYear(), today.getMonth() - 9, 1, 0, 0, 1) //10month

    const toDate = to
      ? new Date(to + 'T23:59:59')
      : new Date(
          today.getFullYear(),
          today.getMonth(),
          today.getDate(),
          23,
          59,
          59,
        )

    const filters = {
      status: '1',
      work_order: {
        company_id: { _eq: myCompanyId },
        wo_status: { _in: completed_status_ids },
        started_at: {
          _gte: fromDate.toISOString(),
          _lte: toDate.toISOString(),
        },
      },
    }
    // console.log('Trades-----filters', filters)

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
    console.log(e)
  }
}

function moneyFormat(value: number): string {
  if (isNaN(value)) return ''
  return value.toLocaleString('mn-MN') + ' ₮'
}

onMounted(async () => {
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

  await loadLocations() //other_actual_amount_sum
})
</script>

<template>
  <div>
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Tile -->
      <div class="ptablet:col-span-6 col-span-12 sm:col-span-3">
        <BaseCard class="p-6">
          <div class="flex items-center justify-between">
            <BaseHeading
              as="h4"
              size="sm"
              weight="medium"
              lead="tight"
              class="text-muted-400 mb-1"
            >
              <span>{{ t('Inductions') }}</span>
            </BaseHeading>
            <Icon
              name="ph:shopping-cart-duotone"
              class="text-primary-500 size-7"
            />
          </div>
          <div class="flex items-center justify-between gap-6 pt-4">
            <div class="grow">
              <span
                class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
              >
                641.4k
              </span>
            </div>
            <div class="grow">
              <AddonApexcharts v-bind="sparkLineOne" />
            </div>
          </div>
        </BaseCard>
      </div>
      <!-- Tile -->
      <div class="ptablet:col-span-6 col-span-12 sm:col-span-3">
        <BaseCard class="p-6">
          <div class="flex items-center justify-between">
            <BaseHeading
              as="h4"
              size="sm"
              weight="medium"
              lead="tight"
              class="text-muted-400 mb-1"
            >
              <span>{{ t('Accident Report') }}</span>
            </BaseHeading>
            <Icon name="ph:money-duotone" class="text-success-500 size-7" />
          </div>
          <div class="flex items-center justify-between gap-6 pt-4">
            <div class="grow">
              <span
                class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
              >
                $389.9k
              </span>
            </div>
            <div class="grow">
              <AddonApexcharts v-bind="sparkLineTwo" />
            </div>
          </div>
        </BaseCard>
      </div>
      <!-- Tile -->
      <div class="ptablet:col-span-6 col-span-12 sm:col-span-3">
        <BaseCard class="p-6">
          <div class="flex items-center justify-between">
            <BaseHeading
              as="h4"
              size="sm"
              weight="medium"
              lead="tight"
              class="text-muted-400 mb-1"
            >
              <span>{{ t('Incompatibility') }}</span>
            </BaseHeading>
            <Icon name="ph:package-duotone" class="text-info-500 size-7" />
          </div>
          <div class="flex items-center justify-between gap-6 pt-4">
            <div class="grow">
              <span
                class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
              >
                981
              </span>
            </div>
            <div class="grow">
              <AddonApexcharts v-bind="sparkLineThree" />
            </div>
          </div>
        </BaseCard>
      </div>
      <!-- Tile -->
      <div class="ptablet:col-span-6 col-span-12 sm:col-span-3">
        <BaseCard class="p-6">
          <div class="flex items-center justify-between">
            <BaseHeading
              as="h4"
              size="sm"
              weight="medium"
              lead="tight"
              class="text-muted-400 mb-1"
            >
              <span>{{ t('Safety working hours') }}</span>
            </BaseHeading>
            <Icon name="ph:timer-duotone" class="text-danger-500 size-7" />
          </div>
          <div class="flex items-center justify-between gap-6 pt-4">
            <div class="grow">
              <span
                class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
              >
                43
              </span>
            </div>
            <div class="grow">
              <AddonApexcharts v-bind="sparkLineFour" />
            </div>
          </div>
        </BaseCard>
      </div>
      <!-- Chart -->
      <div class="relative col-span-12 md:col-span-7">
        <BaseCard class="p-6">
          <div class="flex gap-8 hidden">
            <div>
              <span class="text-muted-400 font-sans text-xs">{{
                t('This month')
              }}</span>
              <p class="text-primary-500 font-sans text-lg font-medium">
                $75,690
              </p>
            </div>
            <div>
              <span class="text-muted-400 font-sans text-xs">{{
                t('Last month')
              }}</span>
              <p
                class="text-muted-800 dark:text-muted-100 font-sans text-lg font-medium"
              >
                $59,724
              </p>
            </div>
            <div>
              <span class="text-muted-400 font-sans text-xs">{{
                t('Average')
              }}</span>
              <p
                class="text-muted-800 dark:text-muted-100 font-sans text-lg font-medium"
              >
                $66,561
              </p>
            </div>
          </div>
          <AddonApexcharts v-bind="areaCustomers" />
        </BaseCard>
      </div>
      <!-- Column -->
      <div class="relative col-span-12 md:col-span-5">
        <div class="flex h-full flex-col gap-6">
          <!-- Chart -->
          <BaseCard class="flex-1 p-6">
            <div class="flex items-center justify-center">
              <div class="flex-1">
                <BaseHeading
                  as="h3"
                  size="md"
                  weight="semibold"
                  lead="tight"
                  class="text-muted-800 mb-4 dark:text-white"
                >
                  <span>{{ t('HSE cost') }}</span>
                </BaseHeading>
                <BaseHeading
                  as="h4"
                  size="lg"
                  weight="light"
                  lead="tight"
                  class="text-muted-800 mb-2 dark:text-white"
                >
                  <span>$8,641.26</span>
                </BaseHeading>
                <BaseParagraph size="xs">
                  <span class="text-muted-400">
                    {{ t('Panels') }}, {{ t('Measuring instruments') }},
                    {{ t('Personal protective equipment') }}
                  </span>
                </BaseParagraph>
              </div>
              <div class="flex-1">
                <AddonApexcharts v-bind="radialSalesRevenue" />
              </div>
            </div>
          </BaseCard>
          <!-- Charts -->
          <BaseCard class="flex-1 p-6">
            <div class="mb-6 flex items-center justify-between">
              <BaseHeading
                as="h3"
                size="md"
                weight="semibold"
                lead="tight"
                class="text-muted-800 dark:text-white"
              >
                <span>{{ t('Additional Stats') }}</span>
              </BaseHeading>
            </div>
            <div class="flex justify-between gap-2">
              <div class="flex flex-1 flex-col gap-2 text-center">
                <AddonApexcharts v-bind="radialSmallOne" />
                <div class="-mt-6">
                  <BaseHeading
                    as="h5"
                    size="md"
                    weight="semibold"
                    lead="tight"
                    class="text-muted-800 dark:text-white"
                  >
                    <span>278</span>
                  </BaseHeading>
                  <BaseParagraph size="xs">
                    <span class="text-muted-400">{{
                      t('Permit to work')
                    }}</span>
                  </BaseParagraph>
                </div>
              </div>
              <div class="flex flex-1 flex-col gap-2 text-center">
                <AddonApexcharts v-bind="radialSmallTwo" />
                <div class="-mt-6">
                  <BaseHeading
                    as="h5"
                    size="md"
                    weight="semibold"
                    lead="tight"
                    class="text-muted-800 dark:text-white"
                  >
                    <span>1,519</span>
                  </BaseHeading>
                  <BaseParagraph size="xs">
                    <span class="text-muted-400">{{ t('Safety cards') }}</span>
                  </BaseParagraph>
                </div>
              </div>
              <div class="flex flex-1 flex-col gap-2 text-center">
                <AddonApexcharts v-bind="radialSmallThree" />
                <div class="-mt-6">
                  <BaseHeading
                    as="h5"
                    size="md"
                    weight="semibold"
                    lead="tight"
                    class="text-muted-800 dark:text-white"
                  >
                    <span>3,214</span>
                  </BaseHeading>
                  <BaseParagraph size="xs">
                    <span class="text-muted-400">{{ t('Tool box') }}</span>
                  </BaseParagraph>
                </div>
              </div>
            </div>
          </BaseCard>
        </div>
      </div>
      <!-- Column -->
      <div
        class="ltablet:col-span-6 relative col-span-12 md:col-span-6 lg:col-span-6"
      >
        <BaseCard class="flex flex-col p-6">
          <div class="mb-6 flex items-center justify-between">
            <BaseHeading
              as="h3"
              size="md"
              weight="semibold"
              lead="tight"
              class="text-muted-800 dark:text-white"
            >
              <span>{{ t('Personal Score') }}</span>
            </BaseHeading>
          </div>
          <div class="py-16">
            <AddonApexcharts v-bind="gaugePersonal" class="-mt-14" />
          </div>
          <div class="mt-auto text-center">
            <BaseParagraph size="sm">
              <span class="text-muted-400">
                {{
                  t(
                    'Your score has been calculated based on the latest metrics',
                  )
                }}
              </span>
            </BaseParagraph>
          </div>
        </BaseCard>
      </div>
      <!-- Column -->
      <div
        class="ltablet:col-span-6 relative col-span-12 md:col-span-6 lg:col-span-6"
      >
        <BaseCard class="relative p-6">
          <div class="mb-6">
            <BaseHeading
              as="h3"
              size="md"
              weight="semibold"
              lead="tight"
              class="text-muted-800 dark:text-white"
            >
              <span>{{ t('Orders Summary') }}</span>
            </BaseHeading>
          </div>
          <AddonApexcharts v-bind="barOrders" />
        </BaseCard>
      </div>
      <!-- Column Calendar -->
      <!-- <div
                      class="ltablet:col-span-4 relative col-span-12 md:col-span-6 lg:col-span-3"
                    >
                      <BaseCard class="p-2">
                        <Calendar
                          :attributes="[
                            {
                              key: 'today',
                              highlight: true,
                              order: 0,
                              dates: [new Date()],
                            },
                          ]"
                          title-position="left"
                          expanded
                          borderless
                          transparent
                          trim-weeks
                          class="max-w-full rounded-md"
                        />
                      </BaseCard>
                    </div> -->
    </div>
  </div>
</template>
