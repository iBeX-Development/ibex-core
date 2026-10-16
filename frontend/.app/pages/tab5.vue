<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { onMounted, ref } from 'vue'
import {
  completed_status_ids,
  completed_wo_status,
  open_wo_status,
  wo_status,
} from '~/components/workorder/WorkOrderStatus'

import '~/assets/css/vcalendar.css'
const { token } = useDirectusToken()

const props = defineProps({
  filterData: Object,
  statYear: Number,
  statMonth: Number,
  type: String,
  tab: String,
})

import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

import CostPanel from '~/components/demo-chart/CostPanel.vue'
// import FilterModalForm from '~/components/home/FilterModalForm.vue'
import {
  getDefaultDateRange,
  toLocalDateStr,
  toLocalIsoStr,
  toRangeEnd,
  toRangeStart,
} from '~/composables/useDefaultDateRange'
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

definePageMeta({
  title: 'Private metrics',
  middleware: ['auth'],
  preview: {
    title: 'Private metrics',
    description: 'Private performance metrics and statistics',
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

//tabs_count
const lineRevenue = ref(null)
const pieBar = ref(null)
const currentDate = new Date()

// Filter section
const fromMenu = ref(false)
const toMenu = ref(false)
const today = new Date()

//counts

const unplanned_cnt = ref(0.0)
const wo_cnt_percent = ref(0.0) //1box
const request_cnt = ref(0.0) //2box
const planned_trades_sum = ref(0.0) //3box
const actual_trades_sum = ref(0.0) //4box
const oc_count_sum = ref(0.0) //5box
const wo_count_sum = ref(0.0) //6box
const completed_count_sum = ref(0.0) //5box
const progressing_count_sum = ref(0.0) //6box

const total_cnt = ref(0.0)
const this_month_cnt = ref(0.0)
const last_month_cnt = ref(0.0)

//locations
const loc_planned_trades_sum = ref(0.0)
const loc_actual_trades_sum = ref(0.0)

// FilterNewModalForm.vue, tab1/tab2/tab3.vue-тэй НЭГ л эх сурвалжтай
// (useDefaultDateRange) анхны огнооны хязгаар — эс тэгвэл модал дээр
// харагдах анхны огноо болон tab-ын анхны фильтр хоорондоо зөрөх эрсдэлтэй
// байсан
const defaultRange = getDefaultDateRange()
const customFrom = ref(defaultRange.from)
const customTo = ref(defaultRange.to)

const isDropdownOpen = ref(true)
const date_filer = ref(false)
const dashboard_type = ref(null)
const loading = ref(false)

const year = currentDate.getFullYear()
const month = currentDate.getMonth() // 0-based: Jan = 0
const isNewTrade = ref(false)
const key = ref(1)

//charts
const checked = ref([])
const location = ref([])
const datas = ref([])
const trades = ref([])
const user = useDirectusUser()
const router = useRouter()
const route = useRoute()
const status = ref([''])

const isOneRow = ref(false)
const barSalesProfit = ref([])
const totalItems = ref(0)
const selectedRangeText = ref('Filter')

const options = reactive({
  first: '',
  second: '',
  third: '',
  fourth: '',
  fifth: '',
})

let dateStr =
  today.getFullYear() +
  '-' +
  String(today.getMonth() + 1).padStart(2, '0') +
  '-' +
  String(today.getDate()).padStart(2, '0')

const MONTH_NAMES = [
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

// Сарын bucket бүрийг НЭГ УДАА бэлдэнэ: X тэнхлэгийн шошго (label), Work_order_
// perform-ийн "YYYY-M" түлхүүр (key), Work_order_Tradecode-ийн огноотой
// харьцуулах сарын эхлэл/төгсгөл (start/end). tab3.vue-тэй адил зассан.
function buildMonthBuckets(fromDate, toDate) {
  const buckets = []
  const cursor = new Date(fromDate.getFullYear(), fromDate.getMonth(), 1)
  const last = new Date(toDate.getFullYear(), toDate.getMonth(), 1)

  while (cursor <= last) {
    const y = cursor.getFullYear()
    const m = cursor.getMonth() + 1
    const mm = String(m).padStart(2, '0')
    const lastDay = new Date(y, m, 0).getDate()

    buckets.push({
      key: `${y}-${m}`,
      label: `${MONTH_NAMES[cursor.getMonth()]}, ${y}`,
      start: `${y}-${mm}-01`,
      end: `${y}-${mm}-${String(lastDay).padStart(2, '0')}`,
    })

    cursor.setMonth(cursor.getMonth() + 1)
  }

  return buckets
}

// Work_order_perform-ийн түүхий мөрүүдийг trade тус бүрээр бүлэглэнэ (нэг
// trade нэг сард олон байршилд бичлэгтэй байж болно — тэдгээрийг зөвхөн
// нэгтгэнэ, аль нь "төлөөлөгч" мөр болохыг сонгох шаардлагагүй).
function groupPerformByTrade(items) {
  const byTrade = new Map()

  for (const item of items ?? []) {
    const tradeId = item.trade?.id
    if (tradeId == null) continue

    if (!byTrade.has(tradeId)) {
      byTrade.set(tradeId, {
        tradeName: item.trade?.name || 'Unknown',
        valuesList: [],
      })
    }
    byTrade.get(tradeId).valuesList.push(item.values)
  }

  return byTrade
}

// Тухайн сарын bucket-т таарах бүх Work_order_perform.values блокийн (date-
// с бусад бүх талбарын) нийлбэрийг буцаана.
function sumAvailable(valuesList, monthKey) {
  let total = 0
  for (const values of valuesList ?? []) {
    if (values?.date !== monthKey) continue
    for (const [field, value] of Object.entries(values)) {
      if (field !== 'date') total += Number(value) || 0
    }
  }
  return total
}

// Тухайн trade + сарын bucket-т таарах бүх Work_order_Tradecode мөрийн
// `field`-ийн нийлбэрийг буцаана (нэг сард олон өдөр ажил хийгдсэн байж
// болох тул НЭГ мөр биш, тохирох БҮХ мөрийг нийлбэрлэнэ).
function sumWoTrades(woTrades, tradeId, month, field) {
  let total = 0
  for (const ut of woTrades ?? []) {
    if (ut.tradeId !== tradeId) continue
    if (ut.date < month.start || ut.date > month.end) continue
    total += Number(ut[field]) || 0
  }
  return total
}

// Гурван эх сурвалж: `performItems` (Work_order_perform — "Available" багана),
// `woTrades` (convertByTrade-ээр цэгцэлсэн Work_order_Tradecode — "Planned"/
// "Actual" багана). Аль нэгэнд нь л гарч ирсэн trade болгонд график үүсгэнэ.
const grapicData = async ({ performItems, woTrades, from, to }) => {
  try {
    const { primary, info, success } = useTailwindColors()

    const fromDate = toRangeStart(from, customFrom.value)
    const toDate = toRangeEnd(to, customTo.value)

    const months = buildMonthBuckets(fromDate, toDate)
    isOneRow.value = months.length > 6

    const performByTrade = groupPerformByTrade(performItems)
    const tradeIds = new Set([
      ...performByTrade.keys(),
      ...(woTrades ?? []).map((ut) => ut.tradeId),
    ])

    return Array.from(tradeIds).map((tradeId) => {
      const perform = performByTrade.get(tradeId)
      const tradeName =
        perform?.tradeName ??
        woTrades.find((ut) => ut.tradeId === tradeId)?.trade ??
        'Unknown'

      const availableData = months.map((month) =>
        sumAvailable(perform?.valuesList, month.key),
      )
      const plannedData = months.map((month) =>
        sumWoTrades(woTrades, tradeId, month, 'duration'),
      )
      const actualData = months.map((month) =>
        sumWoTrades(woTrades, tradeId, month, 'actual_duration'),
      )

      const entrySeries = [
        { name: t('Available'), data: availableData },
        { name: t('Planned'), data: plannedData },
        { name: t('Actual'), data: actualData },
      ]

      const chartOptions = {
        chart: { toolbar: { show: false } },
        colors: [primary.value, info.value, success.value],
        legend: { position: 'top' },
        plotOptions: {
          bar: {
            horizontal: false,
            endingShape: 'rounded',
            columnWidth: '55%',
          },
        },
        dataLabels: { enabled: false },
        stroke: {
          show: true,
          width: 2,
          colors: ['transparent'],
        },
        xaxis: {
          categories: months.map((month) => month.label),
        },
        yaxis: {
          labels: {
            formatter: (val) => val,
          },
        },
        fill: { opacity: 1 },
        tooltip: {
          y: {
            formatter: (val) => val,
          },
        },
      }

      return {
        trade: { id: tradeId, name: tradeName },
        series: entrySeries,
        barSalesProfit: {
          type: 'bar',
          height: 250,
          options: chartOptions,
          series: entrySeries,
        },
      }
    })
  } catch (error) {
    console.error('Error convert data:', error)
    return []
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
const convertByTrade = (items) => {
  const groupedResult = {}

  items.forEach((item) => {
    const tradeId = item.trade?.id || 0
    const tradeName = item.trade?.name || 'Unknown'
    // loadTrades scheduled_date-аар шүүдэг тул бүлэглэх key ч яг тэр л
    // талбараас гарах ёстой (started_at биш) — tab3.vue-тэй адил зассан
    const dateKey = (() => {
      const raw = item.scheduled_date || item.work_order?.started_at
      if (!raw) return 'Unknown'
      if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) return raw
      const utcStr = raw.endsWith('Z') || raw.includes('+') ? raw : raw + 'Z'
      const d = new Date(utcStr)
      if (isNaN(d.getTime())) return raw.slice(0, 10)
      const y = d.getFullYear()
      const mo = String(d.getMonth() + 1).padStart(2, '0')
      const day = String(d.getDate()).padStart(2, '0')
      return `${y}-${mo}-${day}`
    })()
    const woId = item.work_order?.id

    if (!groupedResult[tradeName]) {
      groupedResult[tradeName] = {}
    }

    if (!groupedResult[tradeName][dateKey]) {
      groupedResult[tradeName][dateKey] = {
        tradeId: tradeId,
        trade: tradeName,
        date: dateKey,
        woId: woId,
        total: 0,
        actual_total: 0,
        duration: 0,
        actual_duration: 0,
        count: 0,
      }
    }

    groupedResult[tradeName][dateKey].total += item.total || 0
    groupedResult[tradeName][dateKey].actual_total += item.actual_total || 0
    groupedResult[tradeName][dateKey].duration += item.duration || 0
    groupedResult[tradeName][dateKey].actual_duration +=
      item.actual_duration || 0
    groupedResult[tradeName][dateKey].count += 1
  })

  // Хэрвээ хүсвэл массив болгож буцаах:
  const res = []

  for (const trade in groupedResult) {
    for (const date in groupedResult[trade]) {
      res.push(groupedResult[trade][date])
    }
  }

  return res
}

const loadItems = async (y = null, m = null, checked = [], location = []) => {
  try {
    loading.value = true

    let from_date = customFrom.value.split('-')
    let to_date = customTo.value.split('-')

    let from_year = Number(from_date[0])
    let from_month = Number(from_date[1])
    let to_year = Number(to_date[0])
    let to_month = Number(to_date[1])

    let filters = {
      status: { _eq: '1' },
      _or: [],
      work_order: {
        company_id: { _eq: myCompanyId },
      },
    }

    filters._or = [
      {
        year: { _eq: from_year },
        month: { _gte: from_month },
      },
      {
        year: { _gt: from_year, _lt: to_year },
      },
      {
        year: { _eq: to_year },
        month: { _lte: to_month },
      },
    ]

    if (location.length) {
      if (isProxy(location)) {
        location = toRaw(location)
      }
      filters.location = { _in: location }
    }
    // if (checked.length) {
    //   if (isProxy(checked)) {
    //     checked = toRaw(checked)
    //   }
    //   filters.wo_status = { _in: checked }
    // }

    // console.log('filters-> ', filters)

    const items = await getItems({
      collection: 'Work_order_perform',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*', 'trade.*'],
      },
    })
    // trades.value = items.data
    // console.log('trades', items)
    loading.value = false

    return items.data
  } catch (e) {
    console.log(e)
  }
}
const loadTrades = async (
  from = null,
  to = null,
  checked = [],
  location = [],
) => {
  try {
    loading.value = true

    // Хэрэглэгчээс ирсэн `from`/`to`-г Date объект болгож хөрвүүлнэ;
    // өгөгдөөгүй бол customFrom.value/customTo.value (нэг эх сурвалж) руу
    // fallback хийнэ
    const fromDate = toRangeStart(from, customFrom.value)
    const toDate = toRangeEnd(to, customTo.value)

    // PerformanceCharts.vue/tab3.vue-тэй адил: график scheduled_date-аар
    // (trade-ийн ажил хэзээ товлогдсон) шүүнэ, эцэг ажлын захиалгын
    // started_at биш — тэдгээр өөр өдөр байж болно. scheduled_date UTC ISO
    // string хэлбэрээр хадгалагддаг тул (Монгол UTC+8) local шөнийн цагийн
    // бичлэгүүд зэргэлдээ өдөр рүү шилждэг — тал бүрт нь 1 өдрөөр тэлж
    // хасагдахаас сэргийлнэ.
    const fromStr = toLocalDateStr(fromDate)
    const toStr = toLocalDateStr(toDate)
    const expandDate = (dateStr, deltaDays) => {
      const [y, m, d] = dateStr.split('-').map(Number)
      return toLocalDateStr(new Date(y, m - 1, d + deltaDays))
    }

    const filters = {
      work_order: {
        company_id: { _eq: myCompanyId },
        wo_status: { _in: completed_status_ids },
      },
      scheduled_date: {
        _gte: expandDate(fromStr, -1),
        _lte: expandDate(toStr, 1),
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

    const trades_items = await getItems({
      collection: 'Work_order_Tradecode',
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*', 'trade.*', 'work_order.*'],
      },
    })

    // console.log('trades_items', trades_items)

    const convertedData = convertByTrade(trades_items.data)

    return convertedData
  } catch (e) {
    console.log('loadTrades error', e)
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
      wo_status: { _in: completed_status_ids },
      company_id: { _eq: myCompanyId },
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
      filters.type = { _in: [1] }
    }
    if (type == 'planned') {
      filters.type = { _in: [2] }
    }
    if (type == 'request') {
      filters.created_type = 'request'
    }
    // console.log('load-filters', filters)

    const cost_items = await getItems({
      collection: 'Work_order',
      params: {
        filter: filters,
        aggregate: {
          sum: 'wo_percent',
        },
        meta: 'filter_count',
        // sort: 'started_at',
        // limit: -1,
        // page: page,
        // sort: sort_array,
        // search: search.value,
        // fields: ['*'],
      },
    })
    // console.log('type-', type, cost_items)

    if (type == 'all') {
      wo_cnt_percent.value = (
        cost_items.data[0].sum.wo_percent / cost_items.meta.filter_count
      ).toFixed(2)
    } else if (type == 'planned') {
      unplanned_cnt.value = cost_items[0].count
    } else if (type == 'request') {
      request_cnt.value = (
        cost_items.data[0].sum.wo_percent / cost_items.meta.filter_count
      ).toFixed(2)
    }

    // console.log('wo_cnt_percent-', wo_cnt_percent)

    // total_cnt.value =
    //   parseInt(planned_cnt.value, 0) + parseInt(unplanned_cnt.value, 0)
    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}
const loadTradesSum = async (
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
      status: '1',
      work_order: {
        wo_status: { _in: completed_status_ids },
        company_id: { _eq: myCompanyId },
        started_at: {
          _gte: toLocalIsoStr(fromDate),
          _lte: toLocalIsoStr(toDate),
        },
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
    // console.log('Work_order_Tradecode_filters', filters)

    const items = await getItems({
      collection: 'Work_order_Tradecode',
      params: {
        filter: filters,
        aggregate: {
          sum: 'total,actual_total',
        },
      },
    })

    planned_trades_sum.value = items[0].sum.total
    actual_trades_sum.value = items[0].sum.actual_total

    // if (location.length) {
    //   loc_planned_trades_sum.value = items[0].sum.total
    //   loc_actual_trades_sum.value = items[0].sum.actual_total
    // } else {
    //   planned_trades_sum.value = items[0].sum.total
    //   actual_trades_sum.value = items[0].sum.actual_total
    // }
    loading.value = false
    // console.log('Work_order_Tradecode', items)
  } catch (e) {
    console.log(e)
  }
}

const loadWorksCount = async (
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

    const filters = {
      wo_status: { _in: completed_status_ids },
      company_id: { _eq: myCompanyId },
      started_at: {
        _gte: toLocalIsoStr(fromDate),
        _lte: toLocalIsoStr(toDate),
      },
    }
    // console.log('Other--wo_status', wo_status)
    // console.log('Other--open_wo_status', open_wo_status)
    // console.log('Other--completed_status_ids', completed_status_ids)
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

    //5box
    if (type == 'open_completed') {
      filters.wo_status = {
        _in: [...open_wo_status._in, ...completed_wo_status._in],
      }
    }

    //6box
    else if (type == 'all') {
      filters.wo_status = { _in: wo_status }
    }
    //7box
    else if (type == 'completed') {
      filters.wo_status = { _in: [3] }
    }
    //8box
    else if (type == 'in_progressing') {
      filters.wo_status = { _in: [2] }
    }

    // console.log('Other--filters', filters)

    const cost_items = await getItems({
      collection: 'Work_order',
      params: {
        filter: filters,
        aggregate: {
          count: '*',
        },
        // meta: 'filter_count',
      },
    })

    //5box
    if (type == 'open_completed') {
      oc_count_sum.value = cost_items[0].count
    }
    //6box
    else if (type == 'all') {
      wo_count_sum.value = cost_items[0].count
    }
    //7box
    else if (type == 'completed') {
      completed_count_sum.value = cost_items[0].count
    }
    //8box
    else if (type == 'in_progressing') {
      progressing_count_sum.value = cost_items[0].count
    }

    // console.log('cost_itemss_counts', cost_items)
    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

const refresh = async (filterData) => {
  console.log('refresh')
  checked.value = filterData.checked
  location.value = filterData.location
  customFrom.value =
    filterData.customFrom === undefined
      ? customFrom.value
      : filterData.customFrom
  customTo.value =
    filterData.customTo === undefined ? customTo.value : filterData.customTo
  await loadWorkOrderSum(
    'all',
    customFrom.value,
    customTo.value,
    checked.value,
    location.value,
  )
  await loadWorkOrderSum(
    'request',
    customFrom.value,
    customTo.value,
    checked.value,
    location.value,
  )
  await loadWorksCount(
    'open_completed',
    customFrom.value,
    customTo.value,
    checked.value,
    location.value,
  )
  await loadWorksCount(
    'all',
    customFrom.value,
    customTo.value,
    checked.value,
    location.value,
  )
  await loadWorksCount(
    'completed',
    customFrom.value,
    customTo.value,
    checked.value,
    location.value,
  )
  await loadWorksCount(
    'in_progressing',
    customFrom.value,
    customTo.value,
    checked.value,
    location.value,
  )

  const available_trades = await loadItems(
    customFrom.value,
    customTo.value,
    checked.value,
    location.value,
  )
  const wo_trades = await loadTrades(
    customFrom.value,
    customTo.value,
    checked.value,
    location.value,
  )

  await loadTradesSum(
    customFrom.value,
    customTo.value,
    checked.value,
    location.value,
  )

  trades.value = await grapicData({
    performItems: available_trades,
    woTrades: wo_trades,
    from: customFrom.value,
    to: customTo.value,
  })
}

onMounted(async () => {
  // customFrom.value/customTo.value-г тодорхой дамжуулна — эс тэгвэл эдгээр
  // load* функцууд аргументгүй дуудагдахад өөрсдийн доторх тусдаа
  // hardcode-логдсон fallback-аа ашиглаж, useDefaultDateRange (FilterNew
  // ModalForm-той нэг эх сурвалжтай) утгаас зөрдөг байсан
  await loadWorkOrderSum('all', customFrom.value, customTo.value)
  await loadWorkOrderSum('request', customFrom.value, customTo.value)
  await loadWorksCount('open_completed', customFrom.value, customTo.value)
  await loadWorksCount('all', customFrom.value, customTo.value)
  await loadWorksCount('completed', customFrom.value, customTo.value)
  await loadWorksCount('in_progressing', customFrom.value, customTo.value)
  await loadTradesSum(customFrom.value, customTo.value)

  const available_trades = await loadItems()
  const wo_trades = await loadTrades(customFrom.value, customTo.value)

  trades.value = await grapicData({
    performItems: available_trades,
    woTrades: wo_trades,
    from: customFrom.value,
    to: customTo.value,
  })
})
watch(
  props,
  async () => {
    // `{ deep: true }`-гүй бол props.filterData доторх утга солигдоход
    // (props объект өөрөө шинэ reference болж солигдохгүй тул) энэ watcher
    // огт ажиллахгүй байсан — filter солиход дата шинэчлэгдэхгүй байх
    // шалтгаан. `refresh`-г `await` хийхгүй байсныг ч засав.
    await refresh(props.filterData)
    key.value += 1
  },
  { deep: true },
)
</script>

<template>
  <div class="col-span-12 md:col-span-3">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Work order average %')"
      :icon="'hugeicons:wrench-01'"
      :icon_class="'bg-orange-100 text-orange-500 dark:bg-orange-500/20 dark:text-orange-400 dark:border-orange-500 dark:border-2'"
      :cost="`${wo_cnt_percent} %`"
    />
  </div>
  <div class="col-span-12 md:col-span-3">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Requested work average %')"
      :icon="'solar:watch-square-minimalistic-charge-broken'"
      :icon_class="'bg-purple-100 text-purple-500 dark:bg-purple-500/20 dark:text-purple-400 dark:border-purple-500 dark:border-2'"
      :cost="`${request_cnt} %`"
    />
  </div>
  <div class="col-span-12 md:col-span-3">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Planned trades total')"
      :icon="'material-symbols:calendar-clock'"
      :icon_class="'bg-danger-100 text-danger-500 dark:bg-danger-500/20 dark:text-danger-400 dark:border-danger-500 dark:border-2'"
      :cost="moneyFormat(planned_trades_sum)"
    />
  </div>
  <div class="col-span-12 md:col-span-3">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Actial trades total')"
      :icon="'icon-park-outline:worker'"
      :icon_class="'bg-fuchsia-100 text-fuchsia-500 dark:bg-fuchsia-500/20 dark:text-fuchsia-400 dark:border-fuchsia-500 dark:border-2'"
      :cost="moneyFormat(actual_trades_sum)"
    />
  </div>
  <div class="col-span-12 md:col-span-3">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Open, Completed counts')"
      :icon="'material-symbols:settings-outline'"
      :icon_class="'bg-info-100 text-info-500 dark:bg-info-500/20 dark:text-info-400 dark:border-info-500 dark:border-2'"
      :cost="numberFormat(oc_count_sum)"
    />
  </div>

  <div class="col-span-12 md:col-span-3">
    <CostPanel
      :font_size="'3xl'"
      :title="t('All works counts')"
      :icon="'material-symbols-light:reset-wrench'"
      :icon_class="'bg-green-100 text-green-500 dark:bg-green-500/20 dark:text-green-400 dark:border-green-500 dark:border-2'"
      :cost="numberFormat(wo_count_sum)"
    />
  </div>
  <div class="col-span-12 md:col-span-3">
    <CostPanel
      :font_size="'3xl'"
      :title="t('In progress counts')"
      :icon="'material-symbols:schedule-send'"
      :icon_class="'bg-green-100 text-green-500 dark:bg-green-500/20 dark:text-green-400 dark:border-green-500 dark:border-2'"
      :cost="numberFormat(progressing_count_sum)"
    />
  </div>
  <div class="col-span-12 md:col-span-3">
    <CostPanel
      :font_size="'3xl'"
      :title="t('Completed works counts')"
      :icon="'mdi:wrench-clock'"
      :icon_class="'bg-yellow-100 text-yellow-500 dark:bg-yellow-500/20 dark:text-yellow-400 dark:border-yellow-500 dark:border-2'"
      :cost="numberFormat(completed_count_sum)"
    />
  </div>
</template>
