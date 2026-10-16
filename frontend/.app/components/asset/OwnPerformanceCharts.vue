<script setup>
import { useI18n } from 'vue-i18n'
// import FilterModalPinned from './FilterModalForm.vue'
// import FilterModalPinned from '../workorder/FilterModalPinned.vue'

import { computed, onMounted, reactive, ref, shallowRef, watch } from 'vue'
const props = defineProps({
  status: Object,
  trades: Array,
  wo_id: Number,
  wo_status_items: Object,
  location: String,
  work_order_type: String,
  asset: Number,
  from: String,
  to: String,
  type: String,
  tab: String,
  // Эцэг компонент (OwnMonitoring.vue)-оос sensor tab-ын сонголтыг дамжуулна:
  // 'raw' = Asset_field_data_json, эсвэл тухайн sensor-ын device_id
  activeSensorTab: {
    type: String,
    default: 'raw',
  },
  // Энэ asset-д харьяалагдах бүх Sensors.device_id — Excel raw-ийн
  // "Device" утгыг аль sensor tab-д харьяалуулахыг тодорхойлоход хэрэглэнэ
  sensorDeviceIds: {
    type: Array,
    default: () => [],
  },
})

// console.log('props_chart', props)
const emit = defineEmits(['update:from', 'update:to'])

const toaster = useToaster()
const { t } = useI18n({ useScope: 'global' })

const { getItems, createItems, updateItem, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

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
  new Date(new Date().setDate(new Date().getDate() - 15))
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
const deviceTrackingFields = ref([])
// Идэвхтэй tab-д (props.activeSensorTab) хамаарах Device_tracking_fields-ийг
// л ашиглана — "raw" tab дээр is_mode='livedata' БИШ мөрүүд, sensor tab дээр
// ЗӨВХӨН is_mode='livedata' БОЛОН code (device_id) яг таарсан мөрүүд.
// Үгүй бол өөр sensor/raw-ын тохиргоо холилдож бүх tab дээр ижил зүйл
// гарч ирнэ.
const visibleTrackingFields = computed(() =>
  deviceTrackingFields.value.filter((f) => {
    if (f.field_key === 'timestamp') return false
    if (props.activeSensorTab === 'raw') return f.is_mode !== 'livedata'
    return f.is_mode === 'livedata' && f.code === props.activeSensorTab
  }),
)
const fieldChartConfig = ref(null)
const dayCount = ref(0)
const gridColSpan = ref('col-span-2') // Default: 2 columns

// Calculate day count and update grid layout
const calculateDayCount = () => {
  const fromDate = new Date(customFrom.value)
  const toDate = new Date(customTo.value)
  const diffTime = Math.abs(toDate - fromDate)
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1

  dayCount.value = diffDays

  // Responsive grid: 1-10 days = 2 columns, 10+ days = 1 column
  gridColSpan.value = diffDays > 10 ? 'col-span-full' : 'col-span-2'

  console.log(` Date range: ${diffDays} days | Grid: ${gridColSpan.value}`)
}

// Y-axis threshold values
const thresholds = {
  value1: 0,
  value2: 98,
  value3: 110,
  value4: 129,
  value5: 132,
}

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
    name: 'Available',
    data: [1, 20, 10], // Placeholder for months
  },
  {
    name: 'Planned',
    data: [10, 20, 10], // Placeholder for months
  },
  {
    name: 'Actial',
    data: [10, 10, 10], // Placeholder for months
  },
])

const getFieldAssetId = () => {
  return props.asset || route.params?.id || null
}

const normalizeFieldKey = (key) =>
  String(key || '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '')

// Хуучин WISE (flat DB багана) талбарууд — json_data-д таарах утга олдоогүй
// үед л fallback байдлаар ашиглана
const LEGACY_SENSOR_READING_COLUMNS = [
  'temperature',
  'vibration_x',
  'vibration_y',
  'vibration_z',
]

// Sensor_reading-ээс fieldData-тай ижил хэлбэрт ({timestamp, [field_key]: value})
// хөрвүүлж татна — ЗӨВХӨН нэг sensor (deviceId)-ийн бичлэгүүдийг. SmartGPS
// зэрэг шинэ integration-уудын хувьд json_data-г (top-level талбарууд +
// sensors.* dynamic талбарууд) шууд field_key-ээр нь тааруулна — WISE
// (temperature/vibration_x/y/z) хэлбэрийн хувьд flat баганаас нь уншина
const loadSensorReadingFieldData = async (
  deviceId,
  fieldKeys,
  fromValue,
  toValue,
) => {
  if (!deviceId || !fieldKeys.length) return []

  try {
    const filter = { device_id: { _eq: deviceId } }
    if (fromValue && toValue) {
      filter.date_created = {
        _gte: `${fromValue}T00:00:00`,
        _lte: `${toValue}T23:59:59`,
      }
    }

    const response = await getItems({
      collection: 'Sensor_reading',
      params: {
        filter,
        sort: ['date_created'],
        limit: 10000,
        fields: [
          'device_id',
          'temperature',
          'vibration_x',
          'vibration_y',
          'vibration_z',
          'json_data',
          'date_created',
        ],
      },
    })
    const items = Array.isArray(response)
      ? response
      : (response && response.data) || []

    return items.map((reading) => {
      const record = { timestamp: reading.date_created }
      const data = reading.json_data

      for (const fieldKey of fieldKeys) {
        let value

        if (data && typeof data === 'object') {
          if (data[fieldKey] !== undefined && data[fieldKey] !== null) {
            value = data[fieldKey]
          } else if (
            data.sensors &&
            typeof data.sensors === 'object' &&
            data.sensors[fieldKey] !== undefined &&
            data.sensors[fieldKey] !== null
          ) {
            value = data.sensors[fieldKey]
          }
        }

        if (value === undefined) {
          const legacyColumn = LEGACY_SENSOR_READING_COLUMNS.find(
            (column) =>
              normalizeFieldKey(column) === normalizeFieldKey(fieldKey),
          )
          if (legacyColumn) value = reading[legacyColumn]
        }

        if (typeof value === 'boolean') value = value ? 1 : 0
        if (typeof value === 'number') record[fieldKey] = value
      }

      return record
    })
  } catch (err) {
    console.warn('⚠️ Could not load sensor readings:', err)
    return []
  }
}

const loadDeviceTrackingFields = async () => {
  try {
    const assetId = getFieldAssetId()
    console.log(' Loading Device_tracking_fields for asset:', assetId)

    if (!assetId) {
      console.warn('No asset id available for Device_tracking_fields')
      deviceTrackingFields.value = []
      fieldChartConfig.value = null
      return
    }

    const response = await getItems({
      collection: 'Device_tracking_fields',
      params: {
        filter: {
          asset: { _eq: assetId },
        },
        sort: ['sort_order'],
      },
    })

    const items = Array.isArray(response)
      ? response
      : (response && response.data) || []

    console.log('✅ Device_tracking_fields fetched:', items.length, 'records')

    // Display field names
    if (items.length > 0) {
      const fieldNames = items
        .map((item) => item.field_name_mn || item.field_key)
        .join(', ')
      console.log('Display Fields:', fieldNames)
    }

    deviceTrackingFields.value = items.map((item) => ({
      id: item.id,
      field_name_mn:
        item.field_name_mn ||
        fieldNameMap[item.field_key] ||
        item.field_key ||
        `Field ${item.id}`,
      field_key: item.field_key,
      unit: item.unit || '',
      is_show: item.is_show,
      is_mode: item.is_mode,
      code: item.code,
      value1: item.value1 != null ? Number(item.value1) : 0,
      value2: item.value2 != null ? Number(item.value2) : 0,
      value3: item.value3 != null ? Number(item.value3) : 0,
      value4: item.value4 != null ? Number(item.value4) : 0,
      value5: item.value5 != null ? Number(item.value5) : item.value4 || 0,
    }))

    buildFieldChart()
  } catch (error) {
    console.error('Error loading Device_tracking_fields:', error)
    deviceTrackingFields.value = []
    fieldChartConfig.value = null
  }
}

const buildFieldChart = () => {
  const fields = deviceTrackingFields.value
  if (!fields.length) {
    fieldChartConfig.value = null
    return
  }

  const categories = fields.map((field) => field.field_name_mn)
  const { primary, info, success, warning } = useTailwindColors()

  fieldChartConfig.value = {
    type: 'bar',
    height: 440,
    options: {
      chart: {
        toolbar: { show: true },
        zoom: { enabled: true },
      },
      plotOptions: {
        bar: {
          horizontal: false,
          columnWidth: '55%',
          endingShape: 'rounded',
        },
      },
      colors: [primary.value, info.value, success.value, warning.value],
      xaxis: {
        categories,
        labels: {
          rotate: -45,
          rotateAlways: false,
        },
      },
      yaxis: {
        title: {
          text: 'Value',
        },
        labels: {
          formatter: (val) => val.toFixed(0),
        },
      },
      legend: {
        position: 'top',
      },
      dataLabels: {
        enabled: true,
        formatter: (val) => val.toFixed(0),
        style: {
          colors: ['#000'],
          fontSize: '12px',
        },
      },
      tooltip: {
        y: {
          formatter: (val) => val.toFixed(2),
        },
      },
      fill: {
        opacity: 1,
      },
    },
    series: [
      {
        name: 'Value 1',
        data: fields.map((field) => field.value1 || 0),
      },
      {
        name: 'Value 2',
        data: fields.map((field) => field.value2 || 0),
      },
      {
        name: 'Value 3',
        data: fields.map((field) => field.value3 || 0),
      },
      {
        name: 'Value 4',
        data: fields.map((field) => field.value4 || 0),
      },
    ],
  }
}

function generateRandomColor() {
  const hues = [0, 30, 60, 120, 180, 210, 240, 270, 300, 330]
  const saturation = 70
  const lightness = 50
  const randomHue = hues[Math.floor(Math.random() * hues.length)]
  return `hsl(${randomHue}, ${saturation}%, ${lightness}%)`
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

// Default field name mapping
const fieldNameMap = {
  speed: 'Урпрар (км/ц)',
  fuel_level: 'Өрөргөр (L)',
  engine_hours: 'Мотор цаг',
  odometer: 'Одометр (км)',
  altitude: 'Өндрийн өндөр (м)',
  direction: 'Чиглэл (°)',
  used_fuel: 'Ашигласан түлш (L)',
  latitude: 'Latitude',
  longitude: 'Longitude',
}

onMounted(async () => {
  location.value = route.params.id

  if (props.from) {
    customFrom.value = props.from
  }

  if (props.to) {
    customTo.value = props.to
  }

  calculateDayCount()
  await loadDeviceTrackingFields()
  await loadFieldDataCharts()
  handleModalOpen()
})

// Эцэг компонентоос sensor tab солигдоход тухайн tab-даа тохирсон дата
// дахин ачаална
watch(
  () => props.activeSensorTab,
  async () => {
    await loadFieldDataCharts()
    key.value += 1
  },
)

watch(
  () => props.tab,
  async (newTab) => {
    if (newTab === 'monitoring') {
      await loadDeviceTrackingFields()
    }
  },
)

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
  datas.value = data
  checked.value = data.checked
  location.value = data.location
  customFrom.value =
    data.customFrom === undefined ? customFrom.value : data.customFrom
  customTo.value = data.customTo === undefined ? customTo.value : data.customTo

  emit('update:from', customFrom.value)
  emit('update:to', customTo.value)

  calculateDayCount()
  await loadFieldDataCharts()
  key.value += 1
}

watch(
  [customFrom, customTo],
  async () => {
    console.log('Date range changed', customFrom.value, customTo.value)
    calculateDayCount()
    await loadFieldDataCharts()
    key.value += 1
  },
  { deep: true },
)

const loadFieldDataCharts = async () => {
  try {
    loading.value = true
    const assetId = getFieldAssetId()
    console.log('🔄 Loading field data charts for asset:', assetId)

    if (!assetId) {
      console.warn('❌ No asset ID for field data')
      trades.value = []
      loading.value = false
      return
    }

    // First, try loading all records to debug
    const filterParams = {
      asset: { _eq: assetId },
      company_id: { _eq: myCompanyId },
    }

    console.log(' Date range filter:', customFrom.value, '→', customTo.value)

    const response = await getItems({
      collection: 'Asset_field_data_json',
      params: {
        filter: filterParams,
        sort: ['timestamp'],
        limit: 10000,
      },
    })

    const allItems = Array.isArray(response)
      ? response
      : (response && response.data) || []

    // Helper: parse any timestamp format (number, numeric string, ISO string)
    const parseTs = (ts) => {
      if (!ts) return null
      let d
      if (typeof ts === 'number') {
        d = new Date(ts < 10000000000 ? ts * 1000 : ts)
      } else if (typeof ts === 'string') {
        const num = Number(ts)
        if (!isNaN(num) && ts.trim() !== '') {
          d = new Date(num < 10000000000 ? num * 1000 : num)
        } else {
          d = new Date(ts)
        }
      } else {
        return null
      }
      return isNaN(d.getTime()) ? null : d
    }

    // Filter by date range in JavaScript
    const fromTs = new Date(`${customFrom.value}T00:00:00`).getTime()
    const toTs = new Date(`${customTo.value}T23:59:59`).getTime()

    const items = allItems.filter((item) => {
      if (!item.timestamp) return true
      const d = parseTs(item.timestamp)
      if (!d) return true
      return d.getTime() >= fromTs && d.getTime() <= toTs
    })

    console.log(` Records for asset ${assetId}:`, items.length, 'records')

    if (items.length > 0) {
      console.log('First record:', JSON.stringify(items[0], null, 2))
    }

    // Parse field_values and get unique field keys (гараар/Excel-ээр
    // импортолсон raw-data)
    const manualFieldData = items.map((item) => {
      const fieldValues =
        typeof item.field_values === 'string'
          ? JSON.parse(item.field_values)
          : item.field_values || {}
      return {
        timestamp: item.timestamp,
        ...fieldValues,
      }
    })

    // "Format Field"-ийн field-үүдийг raw JSON-ы бүх key-ээс биш,
    // Device_tracking_fields-ээс is_show=1 (идэвхтэй) байгаагаар авна
    const shownFieldKeys = visibleTrackingFields.value
      .filter((f) => Number(f.is_show ?? 1) === 1)
      .map((f) => f.field_key)

    console.log('📋 is_show=1 field keys:', shownFieldKeys.join(', '))

    if (shownFieldKeys.length === 0) {
      console.warn('⚠️ No is_show=1 Device_tracking_fields configured')
      trades.value = []
      loading.value = false
      return
    }

    // Excel raw-ийн "Device" (эсвэл ижил төстэй) утгыг мэдэгдэж буй
    // Sensors.device_id-тэй тааруулж, бичлэг бүрийг аль tab-д
    // харьяалагдахыг тодорхойлно — таарвал sensor tab, таарахгүй бол "raw"
    const knownDeviceIdsNormalized = new Set(
      props.sensorDeviceIds.map((d) => normalizeFieldKey(d)),
    )
    const matchDeviceId = (record) => {
      const rawDeviceValue =
        record.Device ?? record.device ?? record.Device_id ?? record.device_id
      if (!rawDeviceValue) return null
      const normalized = normalizeFieldKey(String(rawDeviceValue))
      return knownDeviceIdsNormalized.has(normalized) ? normalized : null
    }

    // Sensor тус бүрийг ТУСДАА tab-аар харуулна — "raw" tab дээр ямар ч
    // sensor-той таарахгүй (эсвэл Device утгагүй) manual бичлэгүүд, sensor
    // tab дээр ЗӨВХӨН тухайн sensor-ын Sensor_reading — raw/manual дататай
    // ХОЛИХГҮЙ
    let fieldData
    if (props.activeSensorTab === 'raw') {
      fieldData = manualFieldData.filter((record) => !matchDeviceId(record))
    } else {
      fieldData = await loadSensorReadingFieldData(
        props.activeSensorTab,
        shownFieldKeys,
        customFrom.value,
        customTo.value,
      )
    }

    console.log(
      `✅ Field data parsed (${props.activeSensorTab}):`,
      fieldData.length,
      'records',
    )

    if (fieldData.length === 0) {
      console.warn('⚠️ No data found for asset', assetId, props.activeSensorTab)
      trades.value = []
      loading.value = false
      return
    }

    // Generate date range for X-axis categories
    const DynDays = generateCustomRangeDays(
      new Date(customFrom.value),
      new Date(customTo.value),
    )
    console.log(' Generated date range:', DynDays.length, 'days')

    // Create a chart for each field
    const fieldCharts = shownFieldKeys.map((fieldKey) => {
      const fieldConfig = visibleTrackingFields.value.find(
        (f) => f.field_key === fieldKey,
      )

      // Debug: log if field config not found
      if (!fieldConfig) {
        console.warn(
          `⚠️ No fieldConfig found for fieldKey: "${fieldKey}", will use fieldNameMap`,
        )
      }

      // Helper: parse any timestamp format to Date
      const parseTs = (ts) => {
        if (!ts) return null
        let d
        if (typeof ts === 'number') {
          d = new Date(ts < 10000000000 ? ts * 1000 : ts)
        } else if (typeof ts === 'string') {
          const num = Number(ts)
          if (!isNaN(num) && ts.trim() !== '') {
            d = new Date(num < 10000000000 ? num * 1000 : num)
          } else {
            d = new Date(ts)
          }
        } else {
          return null
        }
        return isNaN(d.getTime()) ? null : d
      }

      // Use filter date range as X-axis categories
      const categories = DynDays

      // Group values by date (average per day)
      const dataByDate = {}
      DynDays.forEach((day) => {
        dataByDate[day] = []
      })

      fieldData.forEach((record) => {
        const date = parseTs(record.timestamp)
        if (!date) return
        const dayString = date.toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'short',
          day: 'numeric',
        })
        const val = Number(record[fieldKey])
        if (!isNaN(val) && val !== 0 && dataByDate[dayString] !== undefined) {
          dataByDate[dayString].push(val)
        }
      })

      const dataValues = DynDays.map((day) => {
        const vals = dataByDate[day]
        if (!vals || !vals.length) return null
        return vals.reduce((sum, v) => sum + v, 0) / vals.length
      })

      // Validate and sanitize series name - use fieldNameMap as fallback
      const seriesName = String(
        fieldConfig?.field_name_mn ||
          fieldNameMap[fieldKey] ||
          fieldKey ||
          'Unknown Field',
      ).trim()
      if (!seriesName || seriesName === 'NaN') {
        console.warn(
          '⚠️ Invalid series name for fieldKey:',
          fieldKey,
          'using default:',
          fieldNameMap[fieldKey] || fieldKey,
        )
      }

      console.log(
        `📈 Field-"${fieldKey}" (${seriesName}) - Values:`,
        dataValues.slice(0, 5),
        '...',
      )

      // Calculate Y-axis min/max and tick positions based on threshold values
      let yMin = 0
      let yMax = 100
      let tickAmount = 5
      let thresholdArray = []

      if (fieldConfig) {
        thresholdArray = [
          { value: fieldConfig.value1, label: fieldConfig.value1 },
          { value: fieldConfig.value2, label: fieldConfig.value2 },
          { value: fieldConfig.value3, label: fieldConfig.value3 },
          { value: fieldConfig.value4, label: fieldConfig.value4 },
          { value: fieldConfig.value5, label: fieldConfig.value5 },
        ].filter((item) => item.value != null && item.value !== 0)

        if (thresholdArray.length > 0) {
          const maxThreshold = Math.max(...thresholdArray.map((t) => t.value))
          const minThreshold = Math.min(...thresholdArray.map((t) => t.value))

          // Add 20% padding above max threshold
          yMax = maxThreshold * 1.2
          yMin = Math.max(0, minThreshold * 0.8)

          // Set tick amount based on number of thresholds
          tickAmount = Math.max(5, thresholdArray.length + 1)

          console.log(
            `🎯 Field "${fieldKey}" - Y-axis scaled: [${yMin.toFixed(
              2,
            )}, ${yMax.toFixed(2)}] | Thresholds: ${thresholdArray
              .map((t) => `${t.label}=${t.value}`)
              .join(', ')}`,
          )
        }
      }

      return {
        name: seriesName,
        fieldKey,
        // unit: fieldConfig?.unit || '',
        trade: seriesName,
        barSalesProfit: {
          type: 'bar',
          height: 300,
          options: {
            annotations: {
              yaxis: thresholdArray.map((t, i) => ({
                y: t.value,
                borderColor: [
                  '#FF4560',
                  '#FEB019',
                  '#00E396',
                  '#008FFB',
                  '#775DD0',
                ][i % 5],
                borderWidth: 1,
                strokeDashArray: 4,
                label: {
                  text: String(t.value),
                  style: { fontSize: '10px' },
                },
              })),
            },
            chart: {
              toolbar: { show: false },
              stacked: true,
            },
            colors: [generateRandomColor()],
            plotOptions: {
              bar: {
                horizontal: false,
                columnWidth: 10,
                dataLabels: {
                  position: 'top',
                },
              },
            },
            xaxis: {
              categories,
              labels: {
                rotate: -45,
                rotateAlways: false,
                hideOverlappingLabels: false,
                showDuplicates: false,
                style: {
                  colors: '#666',
                  fontSize: '11px',
                },
              },
              axisBorder: {
                show: true,
              },
            },
            yaxis: {
              title: { text: fieldConfig?.unit || '' },
              min: thresholdArray.length > 0 ? 0 : undefined,
              max: thresholdArray.length > 0 ? yMax : undefined,
              tickAmount:
                thresholdArray.length > 0 ? thresholdArray.length + 1 : 5,
              forceNiceScale: true,
              labels: {
                formatter: (val) => {
                  if (val === null || val === undefined || isNaN(val))
                    return '0'
                  return Number(val).toFixed(0)
                },
              },
            },
            legend: {
              show: true,
              position: 'top',
              formatter: (val) => {
                if (!val || val === 'NaN' || isNaN(val)) return 'Data'
                return String(val).trim()
              },
            },
            dataLabels: {
              enabled: false,
            },
            tooltip: {
              y: {
                formatter: (val) => {
                  if (val === null || val === undefined || isNaN(val))
                    return '0'
                  return Number(val).toFixed(1)
                },
              },
            },
            grid: {
              borderColor: '#f0f0f0',
              strokeDashArray: 3,
              xaxis: {
                lines: {
                  show: false,
                },
              },
              yaxis: {
                lines: {
                  show: true,
                },
              },
            },
          },
          series: [
            {
              name: seriesName || 'Data',
              data: dataValues.map((v) =>
                v === null || v === undefined || isNaN(v) ? 0 : v,
              ),
            },
          ],
        },
      }
    })

    console.log('✅ Field charts created:', fieldCharts.length, 'charts')
    trades.value = fieldCharts
    loading.value = false
  } catch (error) {
    console.error('Error loading field data charts:', error)
    trades.value = []
    loading.value = false
  }
}

defineExpose({
  customFrom,
  customTo,
})
</script>

<template>
  <div class="flex w-full flex-col">
    <!-- Sensor tab-ыг эцэг компонент (OwnMonitoring.vue) удирддаг тул энд
    tab UI байхгүй — зөвхөн :active-sensor-tab prop-оор дамждаг -->
    <!-- Device Tracking Fields Charts (always show when available) neeh -->

    <!-- Other Content (when tab is monitoring) -->
    <div
      v-if="props.tab === 'monitoring' && !visibleTrackingFields.length"
      class="grid gap-4 p-2 w-full grid-cols-1"
    >
      <div
        v-if="trades.length"
        v-for="(item, index) in trades"
        :key="`field-${item.fieldKey}-${key}`"
        class="w-full"
      >
        <BaseCard class="relative p-3 h-full flex flex-col">
          <div class="mb-2">
            <BaseHeading
              as="h3"
              size="sm"
              weight="semibold"
              lead="tight"
              class="text-muted-700 dark:text-white text-xs"
            >
              <span
                >{{ item.name }} {{ item.unit ? `(${item.unit})` : '' }}</span
              >
            </BaseHeading>
          </div>
          <div class="flex-1">
            <AddonApexcharts v-bind="item.barSalesProfit" />
          </div>
        </BaseCard>
      </div>

      <div
        v-if="!trades.length"
        class="col-span-full flex items-center justify-center py-12"
      >
        <div class="text-gray-600 dark:text-gray-400">
          {{ loading ? 'Loading...' : 'No data available' }}
        </div>
      </div>
    </div>

    <div v-else :class="['grid gap-4 p-2 w-full grid-cols-4']">
      <div class="chart_1 col-span-full mb-2">
        <p
          class="chart_title text-lg font-semibold text-gray-700 dark:text-gray-300 py-2"
        >
          1. 📊 {{ $t('Daily average comparison') }}
          <!-- 1. 📊 Өдөр тутмын дундаж харьцуулалт -->
          {{ customFrom.value }} {{ customTo.value }} ({{ dayCount }}
          {{ $t('day') }})
        </p>
      </div>

      <div
        v-if="trades.length"
        v-for="(item, index) in trades"
        :key="`${item.id}-${key}`"
        :class="['cardBox', dayCount > 10 ? 'col-span-full' : 'col-span-2']"
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
              <span
                >{{ item.name }} {{ item.unit ? `(${item.unit})` : '' }}</span
              >
            </BaseHeading>
          </div>
          <AddonApexcharts v-bind="item.barSalesProfit" />
        </BaseCard>
      </div>

      <div
        v-if="!trades.length"
        class="col-span-full flex items-center justify-center py-12"
      >
        <div class="text-gray-600 dark:text-gray-400">
          {{ loading ? 'Loading...' : 'No data available' }}
        </div>
      </div>
    </div>

    <div
      v-if="
        visibleTrackingFields.filter((f) => Number(f.is_show ?? 1) === 1)
          .length > 0
      "
      class="chart_2 grid gap-4 p-2 w-full grid-cols-1"
    >
      <p
        class="chart_title text-lg font-semibold text-gray-700 dark:text-gray-300 py-2"
      >
        2. 📊 {{ $t('Field detailed trend') }}
        <!-- 2. 📊 Талбар тус бүрийн дэлгэрэнгүй трэнд -->
        <!-- ({{ deviceTrackingFields.length }}) -->
      </p>
      <div
        v-for="field in visibleTrackingFields.filter(
          (f) => Number(f.is_show ?? 1) === 1,
        )"
        :key="`chart-${field.id}-${props.activeSensorTab}`"
        class="w-full"
      >
        <AssetFieldChartWithThresholds
          :asset-id="props.asset || route.params.id"
          :field-key="field.field_key"
          :field-name="field.field_name_mn"
          :unit="field.unit"
          :value1="field.value1"
          :value2="field.value2"
          :value3="field.value3"
          :value4="field.value4"
          :value5="field.value5"
          :from="customFrom"
          :to="customTo"
          :sensor-device-id="
            props.activeSensorTab === 'raw' ? null : props.activeSensorTab
          "
          :sensor-device-ids="props.sensorDeviceIds"
          @update:from="
            (val) => {
              customFrom = val
              emit('update:from', val)
            }
          "
          @update:to="
            (val) => {
              customTo = val
              emit('update:to', val)
            }
          "
        />
      </div>
    </div>
  </div>
</template>

<style>
.filter_date .date_input {
  height: 42px;
}

/* Карт бүрийг "3D" маягаар, гүн харагдахуйц сүүдэртэй, hover хийхэд дээш
   өргөгддөг болгоно (tab1.vue/OwnMonitoring.vue-ийн .cardBox-той адил).
   Энэ style block scoped биш тул :deep() шаардлагагүй — доторх BaseCard-
   ийн .nui-card руу энгийн descendant selector-оор шууд хүрнэ. */
.cardBox .nui-card {
  transition: transform 0.25s ease, box-shadow 0.25s ease;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.06),
    0 8px 16px -6px rgba(15, 23, 42, 0.12),
    0 20px 32px -12px rgba(15, 23, 42, 0.18);
}

.cardBox:hover .nui-card {
  transform: perspective(800px) translateY(-6px) rotateX(2deg);
  box-shadow: 0 2px 4px rgba(15, 23, 42, 0.08),
    0 16px 24px -8px rgba(15, 23, 42, 0.18),
    0 32px 48px -16px rgba(15, 23, 42, 0.28);
}

.dark .cardBox .nui-card {
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.4), 0 8px 16px -6px rgba(0, 0, 0, 0.5),
    0 20px 32px -12px rgba(0, 0, 0, 0.6);
}

.dark .cardBox:hover .nui-card {
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5), 0 16px 24px -8px rgba(0, 0, 0, 0.6),
    0 32px 48px -16px rgba(0, 0, 0, 0.7);
}
</style>
