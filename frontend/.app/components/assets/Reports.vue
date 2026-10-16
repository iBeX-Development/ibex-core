<script setup>
import { subDays } from 'date-fns'
import { useI18n } from 'vue-i18n'

import 'v-calendar/dist/style.css'
import '~/assets/css/vcalendar.css'

const { t } = useI18n({ useScope: 'global' })

const menu = ref(false)
const fromMenu = ref(false)
const toMenu = ref(false)
const customFrom = ref('all_time')
const customTo = ref('all_time')
const isDropdownOpen = ref(true)
const date_filer = ref(false)

const selectedRangeText = ref('Filter')
const dateOptions = ref([
  { label: 'Last 7 Days', value: 7 },
  { label: 'Last 30 Days', value: 30 },
  { label: 'Last 60 Days', value: 60 },
  { label: 'Last 90 Days', value: 90 },
  { label: 'Last 365 Days', value: 365 },
  { label: 'All Time', value: 'all' },
])

const user = useDirectusUser()
const router = useRouter()
const route = useRoute()

const assetId = ref(-1)

const { getItems } = useDirectusItems()

const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const series2 = shallowRef([0, 0, 0])

const options = reactive({
  first: '',
  second: '',
  third: '',
  fourth: '',
  fifth: '',
})

let status1Count = 0
let status2Count = 0
let status3Count = 0
let today = new Date()
let dateStr =
  today.getFullYear() +
  '-' +
  String(today.getMonth() + 1).padStart(2, '0') +
  '-' +
  String(today.getDate()).padStart(2, '0')

const series = shallowRef([
  {
    name: 'Trades',
    data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // Placeholder for months
  },
  {
    name: 'Parts',
    data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // Placeholder for months
  },
])

const filterItems = async ({ ...props }) => {
  loading.value = true

  try {
    let filters = {
      active: 1,
    }

    if (props.status) {
      filters['status'] = props.status
    }
    if (props.work_order_type) {
      filters['type'] = {
        code_work_order: props.work_order_type,
      }
    }
    if (props.location) {
      filters['location'] = {
        location: props.location,
      }
    }
    if (props.asset) {
      filters['asset'] = props.asset
    }
    if (props.code_plan) {
      filters['type'] = {
        code_plan: props.code_plan,
      }
    }
    if (props.date_range) {
      if (
        props.date_range.from !== 'all_time' ||
        props.date_range.to !== 'all_time'
      ) {
        filters['due'] = {
          _gte: new Date(props.date_range.from).toISOString(),
          _lte: new Date(props.date_range.to).toISOString(),
        }
      }
    }

    if (props.code_plan_all) {
      filters['type'] = {
        code_plan: {
          _in: ['planned', 'unplanned'],
        },
      }
    }

    if (props.collection == 'Work_order_Tradecode') {
      let filters = {}
      filters['work_order'] = {
        asset: assetId.value,
      }

      let filters1 = {
        work_order: {
          asset: assetId.value,
        },
      }
      let filters2 = {
        work_order: {
          asset: assetId.value,
        },
      }

      if (props.date_range) {
        if (
          props.date_range.from !== 'all_time' &&
          props.date_range.to !== 'all_time'
        ) {
          const datefromObject = new Date(props.date_range.from + 'T00:00:00')
          const isoFromString = datefromObject.toISOString()

          const datetoObject = new Date(props.date_range.to + 'T23:59:59')
          const isoToString = datetoObject.toISOString()

          filters1.work_order = {
            due: {
              _gte: isoFromString,
            },
            asset: assetId.value,
          }

          filters2.work_order = {
            due: {
              _lte: isoToString,
            },
            asset: assetId.value,
          }
        }
      }

      const [items1, items2] = await Promise.all([
        getItems({
          collection: 'Work_order_Tradecode',
          params: {
            filter: filters1,
            meta: 'filter_count',
            fields: ['*', 'trade.*', 'work_order.*'],
          },
        }),
        getItems({
          collection: 'Work_order_Tradecode',
          params: {
            filter: filters2,
            meta: 'filter_count',
            fields: ['*', 'trade.*', 'work_order.*'],
          },
        }),
      ])

      const combinedItems = [...items1.data, ...items2.data]

      serverItems.value = combinedItems
      items.value = updateItemCount(props.id, 0, combinedItems)
    }

    if (props.collection == 'Work_order_Parts') {
      let partsFilters = {
        work_order: {
          asset: assetId.value, // Keep the asset filter
        },
      }

      let filters1 = {
        work_order: {
          asset: assetId.value,
        },
      }
      let filters2 = {
        work_order: {
          asset: assetId.value,
        },
      }

      if (props.date_range) {
        if (
          props.date_range.from !== 'all_time' &&
          props.date_range.to !== 'all_time'
        ) {
          const datefromObject = new Date(props.date_range.from + 'T00:00:00')
          const isoFromString = datefromObject.toISOString()

          const datetoObject = new Date(props.date_range.to + 'T23:59:59')
          const isoToString = datetoObject.toISOString()

          filters1.work_order = {
            due: {
              _gte: isoFromString,
            },
            asset: assetId.value,
          }

          filters2.work_order = {
            due: {
              _lte: isoToString,
            },
            asset: assetId.value,
          }
        }
      }
      const [items1, items2] = await Promise.all([
        getItems({
          collection: 'Work_order_Parts',
          params: {
            filter: filters1,
            meta: 'filter_count',
            fields: ['*', 'parts.*', 'work_order.*'],
          },
        }),
        getItems({
          collection: 'Work_order_Parts',
          params: {
            filter: filters2,
            meta: 'filter_count',
            fields: ['*', 'parts.*', 'work_order.*'],
          },
        }),
      ])

      const combinedItems = [...items1.data, ...items2.data]

      serverItems.value = combinedItems
      items.value = updateItemCount(props.id, 0, combinedItems)
    }

    if (props.collection == 'Work_order') {
      const res_items = await getItems({
        collection: 'Work_order',
        params: {
          filter: filters,
          meta: 'filter_count',
          search: search.value,
          fields: [
            '*',
            'assigned_to.first_name',
            'assigned_team.name',
            'asset.*',
            'type.code_work_order',
            'type.code_plan',
          ],
        },
      })

      serverItems.value = res_items.data
      totalItems.value = res_items.meta.filter_count
      items.value = updateItemCount(
        props.id,
        res_items.meta.filter_count,
        res_items.data,
      )
    }

    loading.value = false
  } catch (e) {
    console.log(e)
  }
}

const updateItemCount = (itemId, newCount, workOrders) => {
  let plannedCount = 0
  let unplannedCount = 0

  const updatedItems = items.value.map((item) => {
    if (item.id === itemId) {
      if (itemId == 3) {
        for (const order of workOrders) {
          if (order.type.code_plan === 'planned') {
            plannedCount++
          } else if (order.type.code_plan === 'unplanned') {
            unplannedCount++
          }
        }

        newCount = plannedCount
      }
      if (itemId == 4) {
        for (const order of workOrders) {
          newCount += order.duration
        }
      }
      if (itemId == 8) {
        for (const order of workOrders) {
          newCount += order.quantity
        }
      }
      return { ...item, count: newCount, uncount: unplannedCount }
    }
    return item
  })

  return updatedItems
}

const items = ref([
  {
    id: 1,
    count: 1,
    title: 'Completed Planned Work',
    filter: ({ ...date_range }) => {
      filterItems({
        id: 1,
        status: 3,
        code_plan: 'planned',
        collection: 'Work_order',
        date_range,
        asset: assetId.value,
      })
    },
  },
  {
    id: 2,
    count: 2,
    title: 'Completed Unplanned Work',
    filter: ({ ...date_range }) => {
      filterItems({
        id: 2,
        status: 3,
        code_plan: 'unplanned',
        collection: 'Work_order',
        date_range,
        asset: assetId.value,
      })
    },
  },
  {
    id: 3,
    count: 1,
    uncount: 1,
    title: 'Planned vs Unplanned',
    filter: ({ ...date_range }) => {
      filterItems({
        id: 3,
        code_plan_all: 'all',
        collection: 'Work_order',
        date_range,
        asset: assetId.value,
      })
    },
  },
  {
    id: 4,
    count: 0,
    title: 'Time Spent (hours)',
    filter: ({ ...date_range }) => {
      filterItems({
        id: 4,
        collection: 'Work_order_Tradecode',
        date_range,
      })
    },
  },
  {
    id: 5,
    count: 0,
    title: 'In Progress Planned Work',
    filter: ({ ...date_range }) => {
      filterItems({
        id: 5,
        status: 2,
        code_plan: 'planned',
        collection: 'Work_order',
        date_range,
        asset: assetId.value,
      })
    },
  },
  {
    id: 6,
    count: 0,
    title: 'In Progress Unplanned Work',
    filter: ({ ...date_range }) => {
      filterItems({
        id: 6,
        status: 2,
        code_plan: 'unplanned',
        collection: 'Work_order',
        date_range,
        asset: assetId.value,
      })
    },
  },
  {
    id: 7,
    count: 0,
    title: 'Downtime',
    filter: ({ ...date_range }) => {
      // filterItems({ downtime: 3 })
    },
  },
  {
    id: 8,
    count: 0,
    title: 'Parts Used (quantity)',
    filter: ({ ...date_range }) => {
      filterItems({
        id: 8,
        collection: 'Work_order_Parts',
        date_range,
      })
    },
  },
])

const radialGoal = reactive(useRadialGoal())
const barSalesProfit = reactive(useBarSalesProfit())

function useRadialGoal() {
  const { yellow, primary, success } = useTailwindColors()
  const type = 'radialBar'
  const height = 320

  const options1 = {
    chart: {
      offsetY: -10,
    },
    colors: [yellow.value, primary.value, success.value],
    plotOptions: {
      radialBar: {
        startAngle: -135,
        endAngle: 135,
        inverseOrder: true,
        dataLabels: {
          show: true,
          name: {
            show: true,
            fontSize: '14px',
            fontWeight: 500,
            offsetY: -10,
          },
          value: {
            show: true,
            fontWeight: 600,
            fontSize: '16px',
            offsetY: -5,
            formatter: (value) => Math.round(value), // Show the count here
          },
          total: {
            show: true,
            fontSize: '14px',
            fontWeight: 500,
            label: 'Total', // Optional: Change label if needed
            formatter: () =>
              Math.round(series2.value.reduce((acc, val) => acc + val, 0)),
          },
        },
        hollow: {
          margin: 15,
          size: '60%',
        },
        track: {
          strokeWidth: '20%',
        },
      },
    },

    stroke: {
      lineCap: 'round',
      width: 10, // Increase stroke width for a thicker radial stroke
    },
    labels: ['Open', 'In Progress', 'Completed'],
  }

  return {
    type,
    height,
    options: options1,
    series: series2,
  }
}
// Одоогийн сараас эхлэн 12 сар үүсгэх функц
function generateDynamicMonths() {
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
  const currentDate = new Date()
  const currentMonth = currentDate.getMonth()
  const currentYear = currentDate.getFullYear()

  // Одооны сараас эхлэн 12 сар үүсгэх
  const dynamicMonths = []
  for (let i = 0; i < 12; i++) {
    const monthIndex = (currentMonth + i) % 12
    const year = currentYear + Math.floor((currentMonth + i) / 12)
    dynamicMonths.push(`${months[monthIndex]}, ${year}`)
  }
  return dynamicMonths
}

function useBarSalesProfit() {
  const { primary, info, success } = useTailwindColors()
  const type = 'bar'
  const height = 250

  const options3 = {
    chart: {
      toolbar: {
        show: false,
      },
    },
    colors: [primary.value, info.value, success.value],
    legend: {
      position: 'top',
    },
    plotOptions: {
      bar: {
        horizontal: false,
        endingShape: 'rounded',
        columnWidth: '55%',
      },
    },
    dataLabels: {
      enabled: false,
    },
    stroke: {
      show: true,
      width: 2,
      colors: ['transparent'],
    },
    xaxis: {
      categories: generateDynamicMonths(), // Одоо үүсгэгдсэн динамик сарын жагсаалт
    },
    yaxis: {
      labels: {
        formatter: function (val) {
          return val
        },
      },
    },
    fill: {
      opacity: 1,
    },
    tooltip: {
      y: {
        formatter: function (val) {
          return val
        },
      },
    },
  }

  return {
    type,
    height,
    options: options3,
    series,
  }
}

function getDateRange(monthYear) {
  const [month, year] = monthYear.split(', ').map((item) => item.trim())
  const months = {
    Jan: '01',
    Feb: '02',
    Mar: '03',
    Apr: '04',
    May: '05',
    Jun: '06',
    Jul: '07',
    Aug: '08',
    Sep: '09',
    Oct: '10',
    Nov: '11',
    Dec: '12',
  }

  const monthNumber = months[month]
  const firstDay = `${year}-${monthNumber}-01`
  const lastDay = `${year}-${monthNumber}-31`

  return { firstDay, lastDay }
}

const grapicData = async ({ ...props }) => {
  try {
    status1Count = 0
    status2Count = 0
    status3Count = 0

    let parts_filters = {
      work_order: {
        asset: assetId.value, // Keep the asset filter
      },
    }

    let filters1 = {
      work_order: {
        asset: assetId.value,
      },
    }
    let filters2 = {
      work_order: {
        asset: assetId.value,
      },
    }

    if (props.date_range) {
      if (
        props.date_range.from !== 'all_time' &&
        props.date_range.to !== 'all_time'
      ) {
        const datefromObject = new Date(props.date_range.from + 'T00:00:00')
        const isoFromString = datefromObject.toISOString()

        const datetoObject = new Date(props.date_range.to + 'T23:59:59')
        const isoToString = datetoObject.toISOString()

        filters1.work_order = {
          due: {
            _gte: isoFromString,
          },
          asset: assetId.value,
        }

        filters2.work_order = {
          due: {
            _lte: isoToString,
          },
          asset: assetId.value,
        }
      }
    }

    const [items1, items2] = await Promise.all([
      getItems({
        collection: 'Work_order_Parts',
        params: {
          filter: filters1,
          meta: 'filter_count',
          fields: ['*', 'parts.*', 'work_order.*'],
        },
      }),
      getItems({
        collection: 'Work_order_Parts',
        params: {
          filter: filters2,
          meta: 'filter_count',
          fields: ['*', 'parts.*', 'work_order.*'],
        },
      }),
    ])

    const [items3, items4] = await Promise.all([
      getItems({
        collection: 'Work_order_Tradecode',
        params: {
          filter: filters1,
          meta: 'filter_count',
          fields: ['*', 'trade.*', 'work_order.*'],
        },
      }),
      getItems({
        collection: 'Work_order_Tradecode',
        params: {
          filter: filters2,
          meta: 'filter_count',
          fields: ['*', 'trade.*', 'work_order.*'],
        },
      }),
    ])

    const combinedTradesItems = [...items3.data, ...items4.data]
    const combinedItems = [...items1.data, ...items2.data]
    let wo_filters = {
      asset: assetId.value,
    }

    if (props.date_range) {
      if (
        props.date_range.from !== 'all_time' ||
        props.date_range.to !== 'all_time'
      ) {
        wo_filters['due'] = {
          _gte: new Date(props.date_range.from).toISOString(),
          _lte: new Date(props.date_range.to).toISOString(),
        }
      }
    }

    const wo_items = await getItems({
      collection: 'Work_order',
      params: {
        filter: wo_filters,
        meta: 'filter_count',
        search: search.value,
        fields: [
          '*',
          'assigned_to.first_name',
          'assigned_team.name',
          'asset.*',
          'type.code_work_order',
          'type.code_plan',
        ],
      },
    })
    let DynMonths = generateDynamicMonths()

    // liner
    for (let i = 0; i < DynMonths.length; i++) {
      series.value[1].data[i] = 0 // Reset each month index to 0
      series.value[0].data[i] = 0 // Reset each month index to 0
    }

    for (const wo_trade of combinedTradesItems) {
      const orderDate = new Date(wo_trade.work_order?.due)
      const formattedDate = wo_trade.work_order?.due
        ? wo_trade.work_order.due?.split('T')[0]
        : null

      for (const [index, timeDuration] of DynMonths.entries()) {
        const range = getDateRange(timeDuration)

        if (formattedDate >= range.firstDay && formattedDate <= range.lastDay) {
          series.value[0].data[index]++
        }
      }
    }

    for (const order_parts of combinedItems) {
      const orderDate = new Date(order_parts.work_order?.due)
      const formattedDate = order_parts.work_order?.due
        ? order_parts.work_order.due?.split('T')[0]
        : null

      for (const [index, timeDuration] of DynMonths.entries()) {
        const range = getDateRange(timeDuration)

        if (formattedDate >= range.firstDay && formattedDate <= range.lastDay) {
          series.value[1].data[index]++
        }
      }
    }

    series.value = [...series.value]

    console.log(
      'Updated series data:',
      series.value[0].data,
      series.value[1].data,
    )

    // circle
    for (const item of wo_items.data) {
      if (item.wo_status === 1) status1Count++
      if (item.wo_status === 2) status2Count++
      if (item.wo_status === 3) status3Count++
    }

    series2.value = [status1Count, status2Count, status3Count]
  } catch (error) {
    console.error('Error convert data:', error)
  }
}

const toggleDropdown = () => {
  setTimeout(() => {
    customFrom.value = 'all_time'
    customFrom.value = 'all_time'
    isDropdownOpen.value = true
    selectedRangeText.value = 'Filter'
    grapicData({ date_range: { from: 'all_time', to: 'all_time' } })

    items.value.forEach((item) => {
      item.filter({ from: 'all_time', to: 'all_time' })
    })
  }, 500)
}

const applyCustomRange = () => {
  fromMenu.value = false // Close the from menu
  toMenu.value = false // Close the to menu
  selectedRangeText.value = 'Filter'
  isDropdownOpen.value = false
  date_filer.value = true

  selectedRangeText.value = ` ${customFrom.value} - ${customTo.value}`

  grapicData({ date_range: { from: customFrom.value, to: customTo.value } })
  items.value.forEach((item) => {
    item.filter({ from: customFrom.value, to: customTo.value })
  })
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

  grapicData({ date_range: { from: customFrom.value, to: customTo.value } })
  items.value.forEach((item) => {
    item.filter({ from: customFrom.value, to: customTo.value })
  })
}

onMounted(() => {
  assetId.value = route.params.id
  items.value.forEach((item) => {
    item.filter({ from: 'all_time', to: 'all_time' })
  })

  grapicData({ date_range: { from: customFrom.value, to: customTo.value } })
})
</script>

<template>
  <BaseCard>
    <div class="grid gap-4 mt-4 mb-4 ml-8">
      <div class="flex w-full justify-start">
        <div
          @click="toggleDropdown"
          class="p-2.5 hover:text-sky-400 cursor-pointer"
        >
          clear
        </div>
        <BaseDropdown
          variant="button"
          :label="selectedRangeText"
          placement="bottom-start"
          class="dadad"
          ref="isDropdownOpen"
          :close-on-content-click="false"
        >
          <div v-show="isDropdownOpen">
            <BaseDropdownItem
              v-for="(option, index) in dateOptions"
              :key="index"
              :title="$t(option.label)"
              rounded="sm"
              @click="handleItemClick(option.value)"
            >
            </BaseDropdownItem>
            <BaseDropdownDivider />

            <div class="date-range-filter p-2">
              <p class="subtitle-2">Select Date Range</p>
              <div>
                <div>
                  <FormKit
                    type="date"
                    label="From"
                    v-model="customFrom"
                    validation-visibility="live"
                  />
                </div>
                <div>
                  <FormKit
                    type="date"
                    label="To"
                    v-model="customTo"
                    validation-visibility="live"
                  />
                </div>
              </div>

              <v-btn color="success" @click="applyCustomRange">{{
                $t('Set Date Range')
              }}</v-btn>
            </div>
          </div>
        </BaseDropdown>
      </div>
    </div>
    <div style="height: 1px; border: 1px solid #d3cece"></div>
    <div class="grid gap-4 md:grid-cols-4 p-8">
      <!-- Grid item -->
      <div
        v-for="(item, index) in items"
        :key="index"
        class="bg-muted-100/80 dark:bg-muted-700 flex items-center gap-2 rounded-md px-5 py-10"
      >
        <div>
          <BaseHeading
            as="h2"
            size="md"
            weight="semibold"
            lead="tight"
            class="text-muted-800 dark:text-white"
          >
            <span>{{ item.count }}</span>
            <span>{{ item?.uncount ? ' vs ' + item.uncount : '' }}</span>
          </BaseHeading>
          <BaseParagraph size="sm">
            <span class="text-muted-500 dark:text-muted-400">
              {{ item.title }}
            </span>
          </BaseParagraph>
        </div>
      </div>
    </div>

    <div class="grid gap-4 md:grid-cols-4 p-8">
      <div class="col-span-2">
        <BaseCard class="flex h-full flex-col p-4">
          <div class="flex items-center justify-between">
            <BaseHeading
              as="h3"
              size="md"
              weight="semibold"
              lead="tight"
              class="text-muted-800 dark:text-white"
            >
              <span>{{ $t('Goal Overview') }}</span>
            </BaseHeading>
          </div>
          <div class="">
            <AddonApexcharts v-bind="radialGoal" />
          </div>
          <div class="mt-auto">
            <div
              class="border-muted-200 dark:border-muted-700 flex w-full border-t pt-4 text-center"
            >
              <div
                class="border-muted-200 dark:border-muted-700 flex-1 border-r px-2"
              >
                <span
                  class="apexcharts-legend-marker"
                  rel="1"
                  data:collapsed="false"
                  style="
                    background: #f3d263 !important;
                    color: #f3d263;
                    height: 12px;
                    width: 12px;
                    border-width: 0px;
                    border-color: rgb(255, 255, 255);
                    border-radius: 2px;
                  "
                ></span>
                <span class="text-muted-400 font-sans text-xs"> Open </span>
                <p
                  class="text-muted-800 dark:text-muted-100 font-sans text-lg font-medium"
                >
                  {{ status1Count }}
                </p>
              </div>
              <div
                class="border-muted-200 dark:border-muted-700 border-r flex-1 px-2"
              >
                <span
                  class="apexcharts-legend-marker"
                  rel="1"
                  data:collapsed="false"
                  style="
                    background: rgb(139, 92, 246) !important;
                    color: rgb(139, 92, 246);
                    height: 12px;
                    width: 12px;
                    border-width: 0px;
                    border-color: rgb(255, 255, 255);
                    border-radius: 2px;
                  "
                ></span>
                <span class="text-muted-400 font-sans text-xs">
                  {{ $t('In Progress') }}
                </span>
                <p
                  class="text-muted-800 dark:text-muted-100 font-sans text-lg font-medium"
                >
                  {{ status2Count }}
                </p>
              </div>
              <div class="flex-1 px-2">
                <span
                  class="apexcharts-legend-marker"
                  rel="1"
                  data:collapsed="false"
                  style="
                    background: #6dc0b4 !important;
                    color: #6dc0b4;
                    height: 12px;
                    width: 12px;
                    border-width: 0px;
                    border-color: rgb(255, 255, 255);
                    border-radius: 2px;
                  "
                ></span>
                <span class="text-muted-400 font-sans text-xs">
                  {{ $t('Completed') }}
                </span>
                <p
                  class="text-muted-800 dark:text-muted-100 font-sans text-lg font-medium"
                >
                  {{ status3Count }}
                </p>
              </div>
            </div>
          </div>
        </BaseCard>
      </div>
      <div class="col-span-2">
        <BaseCard class="relative p-6">
          <div class="mb-6">
            <BaseHeading
              as="h3"
              size="md"
              weight="semibold"
              lead="tight"
              class="text-muted-800 dark:text-white"
            >
              <span>{{ $t('Future Planned Costs : Labor | Parts') }}</span>
            </BaseHeading>
          </div>
          <AddonApexcharts v-bind="barSalesProfit" />
        </BaseCard>
      </div>
    </div>
  </BaseCard>
</template>

<style>
/* .date-range-filter {
  padding: 10px;
}

.date-inputs {
  display: flex;
  gap: 10px;
}

.calendar-icon {
  cursor: pointer;
}

.quick-actions {
  margin: 10px 0;
} */

.v-picker-title {
  display: none !important;
}

.v-picker__header {
  display: none !important;
}

.date-input {
  flex-grow: 1; /* Allow input to grow in available space */
}
.v-overlay__content {
  left: 391px;
  top: 200px;
}
</style>
