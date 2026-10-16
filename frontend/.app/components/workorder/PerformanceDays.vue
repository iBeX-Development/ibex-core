<script setup>
import { useI18n } from 'vue-i18n'

import { computed, ref } from 'vue'
import ModalItemsList from '~/components/form/ModalItemsList.vue'
const props = defineProps({
  status: Object,
  wo_id: Number,
  wo_status_items: Object,
  location: String,
  work_order_type: String,
  asset: Number,
  className: String, // энэ мөрийг дараах байдлаар өөрчлөх
  type: String,
  tab: String,
})
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
const textInputValue = ref(0)
const trades = ref([])
const valuess = ref({})

//charts

const assetId = ref(-1)
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

const search = ref('')
const serverItems = ref([])
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
    name: 'Available',
    data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // Placeholder for months
  },
  {
    name: 'Planned',
    data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // Placeholder for months
  },
  {
    name: 'Actial',
    data: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // Placeholder for months
  },
])

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
  const currentDate = new Date()
  const dynamicMonths = []

  for (let i = 11; i >= 0; i--) {
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

const barSalesProfit = reactive(useBarSalesProfit())

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
      categories: generatePast12Months(), // Одоо үүсгэгдсэн динамик сарын жагсаалт
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
    let DynMonths = generatePast12Months()

    // liner
    for (let i = 0; i < DynMonths.length; i++) {
      series.value[2].data[i] = 0 // Reset each month index to 0
      series.value[1].data[i] = 0 // Reset each month index to 0
      series.value[0].data[i] = 0 // Reset each month index to 0
    }

    for (const wo_trade of combinedTradesItems) {
      const orderDate = new Date(wo_trade.work_order.due)
      const formattedDate = wo_trade.work_order.due
        ? wo_trade.work_order.due.split('T')[0]
        : null

      for (const [index, timeDuration] of DynMonths.entries()) {
        const range = getDateRange(timeDuration)

        if (formattedDate >= range.firstDay && formattedDate <= range.lastDay) {
          series.value[0].data[index]++
        }
      }
    }

    for (const order_parts of combinedItems) {
      const orderDate = new Date(order_parts.work_order.due)
      const formattedDate = order_parts.work_order.due
        ? order_parts.work_order.due.split('T')[0]
        : null

      for (const [index, timeDuration] of DynMonths.entries()) {
        const range = getDateRange(timeDuration)

        if (formattedDate >= range.firstDay && formattedDate <= range.lastDay) {
          series.value[1].data[index]++
        }
      }
    }

    for (const order_parts of combinedItems) {
      const orderDate = new Date(order_parts.work_order.due)
      const formattedDate = order_parts.work_order.due
        ? order_parts.work_order.due.split('T')[0]
        : null

      for (const [index, timeDuration] of DynMonths.entries()) {
        const range = getDateRange(timeDuration)

        if (formattedDate >= range.firstDay && formattedDate <= range.lastDay) {
          series.value[2].data[index]++
        }
      }
    }

    series.value = [...series.value]

    // console.log(
    //   'Updated series data:',
    //   series.value[0].data,
    //   series.value[1].data,
    //   series.value[2].data,
    // )
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

//-------------------tables
const year_options = [
  { value: 2024, label: '2024' },
  { value: 2025, label: '2025' },
  { value: 2026, label: '2026' },
  { value: 2027, label: '2027' },
  { value: 2028, label: '2028' },
  { value: 2029, label: '2029' },
  { value: 2030, label: '2030' },
  { value: 2031, label: '2031' },
]

const month_options = [
  { value: 1, label: '1' },
  { value: 2, label: '2' },
  { value: 3, label: '3' },
  { value: 4, label: '4' },
  { value: 5, label: '5' },
  { value: 6, label: '6' },
  { value: 7, label: '7' },
  { value: 8, label: '8' },
  { value: 9, label: '9' },
  { value: 10, label: '10' },
  { value: 11, label: '11' },
  { value: 12, label: '12' },
]

// Одоогийн сар, жилээр анхны утга онооно
const sel_year = ref({
  value: new Date().getFullYear(),
  label: new Date().getFullYear(),
})
const sel_month = ref({
  value: new Date().getMonth() + 1,
  label: new Date().getMonth() + 1,
})

// Тухайн сард хэдэн өдөр байгааг тооцоолно
const daysInMonth = computed(() => {
  const lastDay = new Date(
    sel_year.value.value,
    sel_month.value.value,
    0,
  ).getDate()
  return Array.from({ length: lastDay }, (_, i) => i + 1)
})

function onClick(item, type) {
  if (type === 'year') sel_year.value = item
  if (type === 'month') sel_month.value = item
}

// console.log('sel_year', sel_year)
// console.log('sel_month', sel_month)

const addTrade = async (type) => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)

  if (type == 'new') {
    isNewTrade.value = true
  } else {
    isNewTrade.value = false
  }
}

const saveItem = async (type) => {
  try {
    console.log('saveItem called, valuess:', valuess.value)
    console.log('trades:', trades.value)

    for (const tradeId in valuess.value) {
      const dayValues = valuess.value[tradeId]
      const existingTrade = trades.value.find(
        (t) => String(t.trade.id) === String(tradeId),
      )

      console.log(`Processing trade ${tradeId}:`, { dayValues, existingTrade })

      const payload = {
        location: props.location,
        trade: parseInt(tradeId),
        values: {
          date: `${sel_year.value.value}-${sel_month.value.value}`,
          ...dayValues,
        },
        company_id: myCompanyId,
      }

      // Only add work_order if it exists and is valid
      if (props.wo_id && props.wo_id > 0) {
        payload.work_order = props.wo_id
      }

      console.log('Payload:', payload)

      if (existingTrade) {
        // Update existing item
        console.log('Updating item:', existingTrade.id)
        await updateItem({
          collection: 'Work_order_perform',
          id: existingTrade.id,
          item: payload,
        })
      } else {
        // Create new item if not exist
        console.log('Creating new item')
        await createItems({
          collection: 'Work_order_perform',
          items: payload,
        })
      }
    }

    toaster.show({
      title: t('Updated'),
      message: t('Record done'),
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })

    await loadItems()
  } catch (error) {
    console.error('Error in saveItem:', error)
    console.error('Error details:', error.errors || error.message)

    toaster.show({
      title: t('Error'),
      message: error.message || 'Failed to save',
      color: 'danger',
      icon: 'ph:warning-circle',
      closable: true,
    })
  }
}

const handleRemoveClick = async (item) => {
  const deleted = await deleteItems({
    collection: 'Work_order_perform',
    items: {
      query: {
        filter: {
          id: item.id,
        },
      },
    },
  })
  // console.log('handleRemoveClick  values', deleted)

  await loadItems()
}

const closeTrade = () => {
  isNewTrade.value = false
}

const handleOnSave = async (val, day, index, tradeId) => {
  try {
    // Convert to number and validate
    let numValue = val === '' || val === null ? null : parseFloat(val)

    // If not a valid number, skip save
    if (numValue !== null && isNaN(numValue)) {
      console.warn('Invalid number:', val)
      return
    }

    // Update local state first
    if (!valuess.value[tradeId]) {
      valuess.value[tradeId] = {}
    }
    valuess.value[tradeId][day] = numValue

    // Find the existing trade
    const existingTrade = trades.value.find(
      (t) => String(t.trade.id) === String(tradeId),
    )

    if (!existingTrade) {
      console.warn('Trade not found:', tradeId)
      return
    }

    // Build payload with updated values
    const payload = {
      location: props.location,
      trade: parseInt(tradeId),
      values: {
        date: `${sel_year.value.value}-${sel_month.value.value}`,
        ...valuess.value[tradeId],
      },
    }

    // Only add work_order if it exists and is valid
    if (props.wo_id && props.wo_id > 0) {
      payload.work_order = props.wo_id
    }

    console.log('Auto-saving day', day, 'for trade', tradeId, ':', numValue)

    // Immediately update in database
    await updateItem({
      collection: 'Work_order_perform',
      id: existingTrade.id,
      item: payload,
    })

    console.log('Auto-save successful')
  } catch (error) {
    console.error('Error auto-saving:', error)
    toaster.show({
      title: t('Error'),
      message: t('Failed to save. Please try again.'),
      color: 'danger',
      icon: 'ph:warning-circle',
      closable: true,
    })
  }
}

const setTrade = (obj) => {
  let json_data = {
    date: sel_year.value.value + '-' + sel_month.value.value,
    day1: '1',
    day2: '2',
  }

  console.log('setTrade  values', json_data)
  let setValues = {
    work_order: 1,
    location: props.location,
    trade: obj.id,
    values: json_data,
  }

  createItems({
    collection: 'Work_order_perform',
    items: setValues,
  }).then((response) => {
    closeTrade()
    loadItems()
  })
}
const loadItems = async () => {
  try {
    loading.value = true

    const filters = {
      location: props.location,
    }
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
    trades.value = items.data
    // console.log('trades', trades)
    // valuess-г дахин тохируулах
    valuess.value = {}
    trades.value.forEach((item) => {
      valuess.value[item.trade.id] = item.values || {}
    })
    loading.value = false
  } catch (e) {
    console.log(e)
  }
}

onMounted(async () => {
  await loadItems()
  assetId.value = route.params.id
  grapicData({ date_range: { from: customFrom.value, to: customTo.value } })
})

function onChange(event) {
  // const value = (event.target as HTMLInputElement).value
  let items = {}
  console.log('onChange_dates', event.target.name)

  if (event.target.name == 'started_date') keyName = 'started_at'
  else if (event.target.name == 'end_date') keyName = 'end_date'
  else if (event.target.name == 'completed_at') keyName = 'completed_at'

  items = { ...items, [keyName]: event.target.value }
}
</script>

<template>
  <div>
    <!-- GridBody -->
    <div class="col-span-12">
      <TairoContentWrapperTabbed
        :labels="[$t('Days'), $t('Charts')]"
        reverse
        shape="curved"
      >
        <template #tab-1>
          <div class="flex w-[304px] mb-[20px]">
            <BaseListbox
              :label="t('Year')"
              :items="year_options"
              :model-value="sel_year"
              :properties="{
                value: 'value',
                label: 'label',
              }"
              size="md"
              rounded="md"
              @update:model-value="onClick($event, 'year')"
            />
            <BaseListbox
              :label="t('Month')"
              class="ml-[10px]"
              :items="month_options"
              :model-value="sel_month"
              :properties="{
                value: 'value',
                label: 'label',
              }"
              size="md"
              rounded="md"
              @update:model-value="onClick($event, 'month')"
            />
            <div class="saveDays3 ml-[10px] mt-[22px]">
              <BaseButtonIcon muted size="md" @click="addTrade('new')">
                <Icon name="lucide:plus" />
              </BaseButtonIcon>
            </div>

            <div v-if="trades.length > 0" class="saveDays4 ml-[10px] mt-[22px]">
              <BaseButtonIcon muted size="md" @click="saveItem('save')">
                <Icon name="el:ok-circle" />
              </BaseButtonIcon>
            </div>
          </div>
          <div class="overflow-x-auto">
            <table class="border">
              <thead>
                <tr>
                  <th
                    class="border px-2 py-1 text-center text-xs font-semibold text-gray-500"
                  >
                    {{ t('Days') }}
                  </th>
                  <th
                    v-for="trade in trades"
                    :key="trade.id"
                    class="border p-5 text-center text-xs font-semibold text-gray-500"
                  >
                    <div class="flex">
                      <BaseButtonIcon
                        @click="handleRemoveClick(trade)"
                        muted
                        size="sx"
                        id="{{trade.id}}"
                      >
                        <Icon name="lucide:minus" />
                      </BaseButtonIcon>
                      <div class="ml-[10px]">
                        {{ trade.trade.name }}
                      </div>
                    </div>
                  </th>
                </tr>
              </thead>

              <tbody>
                <tr v-for="(day, ind) in daysInMonth" :key="day">
                  <th
                    class="border px-2 py-1 text-center text-sm font-semibold"
                  >
                    {{ day }}
                  </th>

                  <td
                    v-for="trade in trades"
                    :key="trade.id"
                    class="border px-2 py-1 text-center"
                  >
                    <input
                      type="number"
                      class="border rounded-md w-12 text-center text-gray-500 text-[13px] h-[26px] focus:outline-none focus:border-indigo-500"
                      v-model="(valuess[trade.trade.id] ||= {})[day]"
                      @input="
                        handleOnSave(
                          $event.target.value,
                          day,
                          ind,
                          trade.trade.id,
                        )
                      "
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </template>
        <template #tab-2>
          <div class="filter_date flex pl-8 mt-[-76px]">
            <div>
              <FormKit
                type="date"
                :label="t('From')"
                name="started_date"
                @change="onChange"
                v-model="customFrom"
                validation-visibility="live"
                :classes="{
                  input: 'sdate_input',
                  outer: 'sdate_wrapper',
                  label: 'sdate_label',
                }"
              />
            </div>
            <div class="ml-2">
              <FormKit
                type="date"
                :label="t('To')"
                name="end_date"
                @change="onChange"
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
          <div class="grid gap-4 md:grid-cols-4 p-8">
            <div class="col-span-2" v-for="item in trades" :key="item.id">
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
                <AddonApexcharts v-bind="barSalesProfit" />
              </BaseCard>
            </div>
          </div>
        </template>
      </TairoContentWrapperTabbed>
    </div>

    <ModalItemsList
      :open="isNewTrade"
      :header="[
        { title: 'Name', key: 'name', align: 'start', width: '20%' },
        { title: 'Code', key: 'code', align: 'start', width: '20%' },
        {
          title: 'Description',
          key: 'description',
          align: 'start',
          width: '30%',
        },
        { title: 'Rate', key: 'rate', align: 'start' },
        { title: 'Action', key: 'action', align: 'start', sortable: false },
      ]"
      :close="closeTrade"
      :setItem="setTrade"
      title="Trades"
      class="Trades"
      collection="Tradecode"
      fields="*"
    />
  </div>
</template>
