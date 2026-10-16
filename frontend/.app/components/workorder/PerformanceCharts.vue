<script setup>
import { useI18n } from 'vue-i18n'
// import FilterModalPinned from './FilterModalForm.vue'
import FilterModalPinned from './FilterModalPinned.vue'

import { ref } from 'vue'
const props = defineProps({
  status: Object,
  trades: Array,
  wo_id: Number,
  wo_status_items: Object,
  location: Number,
  work_order_type: String,
  asset: Number,
  from: String,
  to: String,
  type: String,
  tab: String,
})

// console.log('props_chart', props)
const emit = defineEmits(['update:from', 'update:to'])

const toaster = useToaster()
const { t } = useI18n({ useScope: 'global' })

const { getItems, createItems, updateItem, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const { getUsers } = useDirectusUsers()

// Одоо байгаа сар болон жил
const currentDate = new Date()
const year = currentDate.getFullYear()
const month = currentDate.getMonth() // 0-based: Jan = 0
const isNewTrade = ref(false)
const loading = ref(true)
const key = ref(1)

//charts
const assetId = ref(-1)
const location = ref(-1)
const checked = ref([])
const datas = ref([])
const trades = ref([])
const customFrom = ref(
  new Date(new Date().setDate(new Date().getDate() - 6))
    .toISOString()
    .split('T')[0],
)
const customTo = ref(new Date().toISOString().split('T')[0])
const isDropdownOpen = ref(true)
const date_filer = ref(false)

const user = useDirectusUser()
const router = useRouter()
const route = useRoute()
const status = ref([''])

const search = ref('')
const isOneRow = ref(false)
const barSalesProfit = ref([])
const serverItems = ref([])
const totalItems = ref(0)
const selectedRangeText = ref('Filter')

const options = reactive({
  first: '',
  second: '',
  third: '',
  fourth: '',
  fifth: '',
})

let today = new Date()
let dateStr =
  today.getFullYear() +
  '-' +
  String(today.getMonth() + 1).padStart(2, '0') +
  '-' +
  String(today.getDate()).padStart(2, '0')

const series = shallowRef([
  {
    name: t('Available'),
    data: [1, 20, 10], // Placeholder for months
  },
  {
    name: t('Planned'),
    data: [10, 20, 10], // Placeholder for months
  },
  {
    name: t('Actual'),
    data: [10, 10, 10], // Placeholder for months
  },
])

// const grapicData = async ({ ...items }) => {
//   try {
//     const { primary, info, success } = useTailwindColors()
//     console.log('items', items)

//     let today = new Date()
//     let sevenDaysAgo = new Date()
//     sevenDaysAgo.setDate(today.getDate() - 6)
//     let startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1)

//     let isEmpty = (val) => !val || val === ''

//     let fromDate = isEmpty(items.from) ? sevenDaysAgo : new Date(items.from)
//     let toDate = isEmpty(items.to) ? today : new Date(items.to)

//     let DynDays = generateCustomRangeDays(fromDate, toDate)

//     // Update whether to show one row based on number of days
//     isOneRow.value = DynDays.length > 15

//     return items.trades.map((entry) => {
//       // Calculate data for each day, mapping day of month to entry.values
//       let availableData = DynDays.map((dayStr) => {
//         // Extract the day number from the date string (e.g., "May 1, 2025" -> "1")
//         const dayMatch = dayStr.match(/(\d+),/)
//         const dayNumber = dayMatch ? dayMatch[1] : null
//         // console.log(
//         //   'dayStr',
//         //   dayStr,
//         //   'dayNumber',
//         //   dayNumber,
//         //   'value',
//         //   entry.values?.[dayNumber],
//         // )

//         // Return the value for that day or 0 if not found
//         return dayNumber && entry.values?.[dayNumber]
//           ? parseInt(entry.values[dayNumber])
//           : 0
//       })
//       let plannedData = DynDays.map(() => 20)
//       let actualData = DynDays.map(() => 10)

//       // Create a new series specifically for this entry
//       const entrySeries = [
//         { name: 'Available', data: availableData },
//         { name: 'Planned', data: plannedData },
//         { name: 'Actual', data: actualData },
//       ]

//       // Create a new chart options object with correct categories
//       const chartOptions = {
//         chart: { toolbar: { show: false } },
//         colors: [primary.value, info.value, success.value],
//         legend: { position: 'top' },
//         plotOptions: {
//           bar: {
//             horizontal: false,
//             endingShape: 'rounded',
//             columnWidth: '55%',
//           },
//         },
//         dataLabels: { enabled: false },
//         stroke: {
//           show: true,
//           width: 2,
//           colors: ['transparent'],
//         },
//         xaxis: {
//           categories: DynDays,
//         },
//         yaxis: {
//           labels: {
//             formatter: (val) => val,
//           },
//         },
//         fill: { opacity: 1 },
//         tooltip: {
//           y: {
//             formatter: (val) => val,
//           },
//         },
//       }

//       // Create a new barSalesProfit object for this entry
//       const entryBarSalesProfit = {
//         type: 'bar',
//         height: 250,
//         options: chartOptions,
//         series: entrySeries,
//       }

//       // Return the entry with all properties
//       return {
//         ...entry,
//         series: entrySeries,
//         barSalesProfit: entryBarSalesProfit,
//       }
//     })
//   } catch (error) {
//     console.error('Error convert data:', error)
//     return []
//   }
// }

const grapicData = async ({ trades, used_trades, from, to }) => {
  try {
    const { primary, info, success } = useTailwindColors()

    let today = new Date()
    let sevenDaysAgo = new Date()
    sevenDaysAgo.setDate(today.getDate() - 6)

    const isEmpty = (val) => !val || val === ''

    // Parse dates as local time
    let fromDate
    let toDate

    if (!isEmpty(from)) {
      const [y, m, d] = from.split('-').map(Number)
      fromDate = new Date(y, m - 1, d, 0, 0, 0)
    } else {
      fromDate = sevenDaysAgo
    }

    if (!isEmpty(to)) {
      const [y, m, d] = to.split('-').map(Number)
      toDate = new Date(y, m - 1, d, 23, 59, 59)
    } else {
      toDate = today
    }

    // ISO date utility: Date객jectоос "YYYY-MM-DD" гаргах (local time)
    function toISO(d) {
      const y = d.getFullYear()
      const m = String(d.getMonth() + 1).padStart(2, '0')
      const day = String(d.getDate()).padStart(2, '0')
      return `${y}-${m}-${day}`
    }

    // ISO date array + display label array хоёуланг нь нэн дараалалтай үүсгэнэ
    const isoDays = [] // ["2026-05-13", "2026-05-14", ...]  → matching
    const displayDays = [] // ["May 13, 2026", ...]              → X-axis
    const cur = new Date(fromDate)
    while (cur <= toDate) {
      isoDays.push(toISO(new Date(cur)))
      displayDays.push(
        cur.toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'short',
          day: 'numeric',
        }),
      )
      cur.setDate(cur.getDate() + 1)
    }

    isOneRow.value = isoDays.length > 15

    // Work_order_perform-аас available утга хайх (month+day key ашиглана)
    function getAvailable(perfEntry, isoDate) {
      if (!perfEntry) return 0
      const [, mm, dd] = isoDate.split('-')
      const monthNumber = parseInt(mm)
      const dayNumber = String(parseInt(dd))
      if (
        dayNumber &&
        perfEntry.values?.[dayNumber] &&
        perfEntry.month == monthNumber
      ) {
        const val = parseInt(perfEntry.values[dayNumber])
        return !isNaN(val) ? val : 0
      }
      return 0
    }

    // used_trades-аас өвөрмөц trade-уудыг цуглуулна
    const uniqueTradesMap = {}
    used_trades.forEach((ut) => {
      if (!uniqueTradesMap[ut.tradeId]) {
        uniqueTradesMap[ut.tradeId] = {
          tradeId: ut.tradeId,
          tradeName: ut.trade,
        }
      }
    })

    // Work_order_perform-д байгаа ч used_trades-д үгүй trade-уудыг нэмнэ
    trades.forEach((entry) => {
      const tradeId = entry.trade?.id
      if (tradeId && !uniqueTradesMap[tradeId]) {
        uniqueTradesMap[tradeId] = {
          tradeId,
          tradeName: entry.trade?.name || 'Unknown',
        }
      }
    })

    const uniqueTrades = Object.values(uniqueTradesMap)

    return uniqueTrades.map(({ tradeId, tradeName }) => {
      const perfEntry = trades.find((t) => t.trade?.id === tradeId)

      const availableData = isoDays.map((iso) => getAvailable(perfEntry, iso))

      // Planned: used_trades-н iso date-тай шууд харьцуулна
      const plannedData = isoDays.map((iso) => {
        const found = used_trades.find(
          (ut) => ut.tradeId === tradeId && ut.date === iso,
        )
        const val = found?.duration
        return val !== undefined && !isNaN(Number(val)) ? Number(val) : 0
      })

      // Actual: work_order completed status-тай тохирох утга
      const actualData = isoDays.map((iso) => {
        const found = used_trades.find(
          (ut) => ut.tradeId === tradeId && ut.date === iso,
        )
        const val = found?.actual_duration
        return val !== undefined && !isNaN(Number(val)) ? Number(val) : 0
      })

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
            columnWidth: '65%',
          },
        },
        dataLabels: { enabled: false },
        stroke: { show: true, width: 0.2, colors: ['transparent'] },
        xaxis: { categories: displayDays },
        yaxis: {
          labels: {
            formatter: (val) => {
              if (val === null || val === undefined || isNaN(val)) return '0'
              return Number(val).toFixed(0)
            },
          },
        },
        fill: { opacity: 1 },
        tooltip: {
          y: {
            formatter: (val) => {
              if (val === null || val === undefined || isNaN(val)) return '0'
              return Number(val).toFixed(1)
            },
          },
        },
      }

      const entryBarSalesProfit = {
        type: 'bar',
        height: 250,
        options: chartOptions,
        series: entrySeries,
      }

      return {
        trade: { id: tradeId, name: tradeName },
        series: entrySeries,
        barSalesProfit: entryBarSalesProfit,
      }
    })
  } catch (error) {
    console.error('Error convert data:', error)
    return []
  }
}

function generateCustomRangeDays(from, to) {
  const isEmpty = (val) => !val || val === ''

  // Хэрвээ хоосон бол default range тохируулна
  const today = new Date()
  const sevenDaysAgo = new Date()
  sevenDaysAgo.setDate(today.getDate() - 6)

  const fromDate = new Date(isEmpty(from) ? sevenDaysAgo : from)
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

onMounted(async () => {
  location.value = route.params.id
  // console.log('PerformanceCharts_location', location.value)

  // props-оос огноог эхлээд тохируулна, дараа нь loadParts дуудна
  if (props.from) {
    customFrom.value = props.from
  }
  if (props.to) {
    customTo.value = props.to
  }

  let items_trades = await loadItems(null, null, null, 'onMounted')
  let used_trades = await loadParts(customFrom.value, customTo.value)

  trades.value = await grapicData({
    trades: items_trades,
    used_trades: used_trades,
    from: customFrom.value,
    to: customTo.value,
  })
  handleModalOpen()
})

//filter
const isModalOpen = ref(false)
const handleModalOpen = () => {
  isModalOpen.value = !isModalOpen.value
}

const handleModalClose = () => {
  isModalOpen.value = false
  // console.log('handleModalClose', isModalOpen.value)
}

const refresh = async (data) => {
  // console.log('refreshed', data)
  datas.value = data
  checked.value = data.checked
  location.value = data.location
  customFrom.value =
    data.customFrom === undefined ? customFrom.value : data.customFrom
  customTo.value = data.customTo === undefined ? customTo.value : data.customTo
  const items_trades = await loadItems(null, null, null, 'refresh')
  let used_trades = await loadParts(
    customFrom.value,
    customTo.value,
    checked.value,
  )

  emit('update:from', customFrom.value)
  emit('update:to', customTo.value)

  trades.value = await grapicData({
    trades: items_trades,
    used_trades: used_trades,
    from: customFrom.value,
    to: customTo.value,
  })
  // Force component refresh by updating the key
  key.value += 1
}

// Update the watch section to properly respond to date changes
// checked.value (Filter modal-с сонгосон wo_status id-ууд)-г ашиглана,
// эс тэгвэл refresh()-ийн дараа энэ watch дахин ажиллаж, статусын
// шүүлтгүйгээр дахин дуудаад filter-т тохирсон үр дүнг дарж бичдэг байсан
watch(
  [customFrom, customTo],
  async () => {
    // console.log('Date range changed', customFrom.value, customTo.value)
    const items_trades = await loadItems(null, null, null, 'watch')
    const used_trades = await loadParts(
      customFrom.value,
      customTo.value,
      checked.value,
    )

    trades.value = await grapicData({
      trades: items_trades,
      used_trades: used_trades,
      from: customFrom.value,
      to: customTo.value,
    })

    // Force component refresh by updating the key
    key.value += 1
  },
  { deep: true },
)

const loadItems = async (
  y = null,
  m = null,
  checked = null,
  type = 'onMounted',
) => {
  try {
    loading.value = true

    let seleted_date = customFrom.value.split('-')
    const filters = {
      status: '1',
      location: location.value,
      company_id: myCompanyId,
      year: seleted_date[0],
      month: seleted_date[1],
    }
    // console.log('checked-> ', type)

    //  хоосон утгуудыг шүүхгүй болгоно
    // Object.keys(filters).forEach((key) => {
    //   if (filters[key] === undefined || filters[key] === null) {
    //     delete filters[key]
    //   }
    // })
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

const convertByTrade = (items) => {
  const groupedResult = {}

  items.forEach((item) => {
    // console.log('convertByTrade', item)
    const tradeId = item.trade?.id || 0
    const tradeName = item.trade?.name || 'Unknown'
    const dateKey = (() => {
      const raw = item.scheduled_date || item.work_order?.started_at
      if (!raw) return 'Unknown'
      // Plain date field (YYYY-MM-DD) — use directly, no timezone conversion needed
      if (/^\d{4}-\d{2}-\d{2}$/.test(raw)) return raw
      // Datetime string — parse as UTC and extract local date components
      const utcStr = raw.endsWith('Z') || raw.includes('+') ? raw : raw + 'Z'
      const d = new Date(utcStr)
      if (isNaN(d.getTime())) return raw.slice(0, 10)
      const y = d.getFullYear()
      const mo = String(d.getMonth() + 1).padStart(2, '0')
      const day = String(d.getDate()).padStart(2, '0')
      return `${y}-${mo}-${day}`
    })()
    const woId = item.work_order?.id
    const work_status = item.work_order?.wo_status

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
        work_status: work_status,
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
const loadParts = async (from = null, to = null, checked = null) => {
  try {
    loading.value = true

    const today = new Date()
    const defaultFrom = new Date(
      today.getFullYear(),
      today.getMonth(),
      today.getDate() - 6,
    )
    const fromStr =
      from ||
      `${defaultFrom.getFullYear()}-${String(
        defaultFrom.getMonth() + 1,
      ).padStart(2, '0')}-${String(defaultFrom.getDate()).padStart(2, '0')}`
    const toStr =
      to ||
      `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(
        2,
        '0',
      )}-${String(today.getDate()).padStart(2, '0')}`

    const filters = {
      // company_id: myCompanyId,
      work_order: {
        location: location.value,
      },
      scheduled_date: {
        // Expand 1 day each side: scheduled_date is stored as UTC ISO string,
        // so local midnight (e.g. Apr 21 00:00 UTC+8) = Apr 20 16:00 UTC.
        // Without expand, _gte:"2026-04-21" would exclude "2026-04-20T16:00:00" records.
        _gte: (() => {
          const [y, m, d] = fromStr.split('-').map(Number)
          const dt = new Date(y, m - 1, d - 1)
          return `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(
            2,
            '0',
          )}-${String(dt.getDate()).padStart(2, '0')}`
        })(),
        _lte: (() => {
          const [y, m, d] = toStr.split('-').map(Number)
          const dt = new Date(y, m - 1, d + 1)
          return `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(
            2,
            '0',
          )}-${String(dt.getDate()).padStart(2, '0')}`
        })(),
      },
    }

    // FilterModalPinned-с сонгосон wo_status id-ууд (checked) байвал
    // тэдгээр статустай Work_order-той тохирох мөрүүдийг л шүүнэ
    if (Array.isArray(checked) && checked.length) {
      filters.work_order = {
        wo_status: { _in: checked },
      }
    }

    // console.log('PerformanceChart_filters_Work_order_Tradecode', filters)

    const trades_items = await getItems({
      collection: 'Work_order_Tradecode',
      params: {
        filter: filters,
        limit: -1,
        meta: 'filter_count',
        fields: ['*', 'trade.*', 'work_order.*'],
      },
    })

    // console.log('PerformanceChart_Work_order_Tradecode', trades_items)

    const convertedData = convertByTrade(trades_items.data)

    return convertedData
  } catch (e) {
    console.log('loadParts error', e)
    loading.value = false
  }
}
defineExpose({
  customFrom,
  customTo,
})
</script>

<template>
  <!-- filter -->
  <div class="filter h-[48px] ml-2">
    <BaseButton class="" @click="handleModalOpen">
      <Icon name="circum:filter" class="-ms-1 h-4 w-4" />
      <span class="text-[11px]">{{ $t('Filter') }}</span>
    </BaseButton>
  </div>

  <div class="flex">
    <!-- filter -->
    <div v-if="isModalOpen == true" class="p-2">
      <FilterModalPinned
        title="Filters"
        :open="isModalOpen"
        :close="handleModalClose"
        :refresh="refresh"
        :datas="datas"
        :location="location"
        :from="customFrom"
        :to="customTo"
        size="3xl"
      />
    </div>

    <div
      :class="[
        isModalOpen ? 'md:grid-cols-4' : 'md:grid-cols-4',
        ' grid gap-4  p-2  w-full',
      ]"
    >
      <div
        v-if="trades.length"
        :class="isOneRow === true ? 'col-span-4  w-full' : 'col-span-2'"
        v-for="(item, index) in trades"
        :key="`${item.trade?.id ?? index}-${key}`"
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
              <span> {{ item.trade.name }}</span>
            </BaseHeading>
          </div>
          <AddonApexcharts v-bind="item.barSalesProfit" />
        </BaseCard>
      </div>
    </div>
  </div>
</template>

<style>
.filter_date .date_input {
  height: 42px;
}
</style>
