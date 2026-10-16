<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, toRef, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import OwnPerformanceCharts from './OwnPerformanceCharts.vue'
import { useMonitoringAlerts } from '../../composables/useMonitoringAlerts'

const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const props = defineProps({
  assetId: {
    type: [Number, String],
    required: true,
  },
  // Эцэг компонент (жишээ нь tab6.vue) өөрийн дээд түвшний огнооны filter-
  // тэй үед дамжуулна — өгөгдвөл дотоод localStorage-с сэргээхийн оронд
  // үүнийг ашиглана. Өгөгдөөгүй бол (DemoAssetMore.vue-ийн адил хуучин
  // хэрэглээ) өмнөх шигээ дотооддоо удирдана.
  from: {
    type: String,
    default: null,
  },
  to: {
    type: String,
    default: null,
  },
  // Эцэг компонент өөрийн дээд түвшний огнооны filter-тэй үед давхардсан
  // (доторх) Custom Date Inputs хэсгийг нуухад ашиглана
  hideDateControls: {
    type: Boolean,
    default: false,
  },
})

const loading = ref(true)
const error = ref<string | null>(null)
const monitoringData = ref<any[]>([])
const customFields = ref<any[]>([])
const latestData = ref<any>(null)
const autoRefresh = ref(false)
const refreshInterval = ref<number | null>(null)

// Monitoring alerts — автомат polling
const assetIdRef = toRef(props, 'assetId')
const { startPolling: startAlertPolling, stopPolling: stopAlertPolling } =
  useMonitoringAlerts(assetIdRef as Ref<string | number | null | undefined>)

// Date range filters — persist across tab switches via localStorage
const _storageKeyFrom = `monitoring_from_${props.assetId}`
const _storageKeyTo = `monitoring_to_${props.assetId}`

const _defaultFrom = new Date(new Date().setDate(new Date().getDate() - 15))
  .toISOString()
  .split('T')[0]
const _defaultTo = new Date().toISOString().split('T')[0]

const customFrom = ref(
  props.from ||
    (process.client && localStorage.getItem(_storageKeyFrom)) ||
    _defaultFrom,
)
const customTo = ref(
  props.to ||
    (process.client && localStorage.getItem(_storageKeyTo)) ||
    _defaultTo,
)
const selectedRangeText = ref('Last 15 Days')
const selectedDays = ref<number | string>(7)

watch(customFrom, (val) => {
  if (process.client) localStorage.setItem(_storageKeyFrom, val)
})
watch(customTo, (val) => {
  if (process.client) localStorage.setItem(_storageKeyTo, val)
})

const dateOptions = [
  { label: 'Last 7 Days', value: 7 },
  { label: 'Last 30 Days', value: 30 },
  { label: 'Last 60 Days', value: 60 },
  { label: 'Last 90 Days', value: 90 },
  { label: 'Last 365 Days', value: 365 },
  { label: 'All Time', value: 'all' },
]

// Apply selected date range
const applyDateRange = (days: number | string) => {
  selectedDays.value = days
  const today = new Date()

  if (days === 'all') {
    selectedRangeText.value = 'All Time'
    customFrom.value = 'all_time'
    customTo.value = 'all_time'
  } else {
    const option = dateOptions.find((o) => o.value === days)
    selectedRangeText.value = option?.label || 'Custom Range'

    const fromDate = new Date()
    fromDate.setDate(today.getDate() - Number(days) + 1)
    customFrom.value = fromDate.toISOString().split('T')[0]
    customTo.value = today.toISOString().split('T')[0]
  }

  loadMonitoringData()
}

// Chart data for Apex Charts
const chartConfig = computed(() => {
  if (
    !historyMonitoringData.value.length ||
    !historyCustomFieldsForTab.value.length
  )
    return null

  const { primary, info, success, warning, danger } = useTailwindColors()
  const colors = [
    primary.value,
    success.value,
    info.value,
    warning.value,
    danger.value,
    '#8b5cf6', // purple
    '#ec4899', // pink
  ]

  const categories = historyMonitoringData.value.map((record) => {
    const date = new Date(record.timestamp * 1000)
    return `${String(date.getMonth() + 1).padStart(2, '0')}/${String(
      date.getDate(),
    ).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(
      date.getMinutes(),
    ).padStart(2, '0')}`
  })

  const series = historyCustomFieldsForTab.value
    .filter((field) => isFieldShown(field))
    .map((field) => ({
      name: `${field.field_name_mn} (${field.unit || ''})`,
      data: historyMonitoringData.value.map(
        (record) => record[field.field_key] || 0,
      ),
    }))

  const options = {
    chart: {
      toolbar: {
        show: true,
        tools: {
          download: true,
          selection: true,
          zoom: true,
          zoomin: true,
          zoomout: true,
          pan: true,
          reset: true,
        },
      },
      zoom: {
        enabled: true,
      },
    },
    colors: colors.slice(0, series.length),
    dataLabels: {
      enabled: false,
    },
    stroke: {
      width: 2,
      curve: 'smooth',
    },
    legend: {
      position: 'top',
    },
    markers: {
      size: 0,
      hover: {
        sizeOffset: 6,
      },
    },
    xaxis: {
      categories,
      labels: {
        rotate: -45,
        rotateAlways: false,
      },
    },
    tooltip: {
      shared: true,
      intersect: false,
    },
    grid: {
      borderColor: '#f1f1f1',
    },
  }

  return {
    type: 'line',
    height: 400,
    options,
    series,
  }
})

// Format timestamp
const formatTimestamp = (timestamp: number): string => {
  const date = new Date(timestamp * 1000)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  const seconds = String(date.getSeconds()).padStart(2, '0')
  return `${year}.${month}.${day} ${hours}:${minutes}:${seconds}`
}

// Format number safely
const formatNumber = (value: any, decimals: number = 2): string => {
  if (value === null || value === undefined) return '-'
  const num = Number(value)
  if (isNaN(num)) return '-'
  return num.toFixed(decimals)
}

// Device_tracking_fields.is_show (0/1 switch) — 0 бол chart-уудад зурахгүй.
// Утга байхгүй (undefined, шинэ/виртуал sensor field) бол анхныхаараа харуулна.
// Switch UI нь OwnTracking.vue-ийн "Current status" карт дээр байрладаг.
const isFieldShown = (field: any): boolean =>
  !(field.is_show === 0 || field.is_show === '0' || field.is_show === false)

// "Raw data" tab-ын field тохиргоо (Device_tracking_fields) — sensor tab
// солигдоход дахин бичигдэхгүй байхын тулд customFields-ээс тусад нь хадгална.
// is_mode='rawdata'-аар шүүнэ — ижил field_key (жишээ "speed") is_mode='livedata'
// талд давхацсан байж болох тул ХОЛИЛГҮЙ байхын тулд
const manualCustomFields = ref<any[]>([])

// Load custom field configuration
const loadCustomFieldConfig = async () => {
  if (!props.assetId) return

  try {
    const response = await getItems<any>({
      collection: 'Device_tracking_fields',
      params: {
        filter: {
          asset: { _eq: props.assetId },
          is_active: { _eq: true },
          is_mode: { _neq: 'livedata' },
        },
        sort: ['sort_order'],
      },
    })

    const items = Array.isArray(response)
      ? response
      : (response as any)?.data || []

    manualCustomFields.value = items || []
    console.log(' Custom fields loaded:', manualCustomFields.value.length)
  } catch (err: any) {
    console.warn('⚠️ Could not load custom fields:', err.message)
    manualCustomFields.value = []
  }
}

// LiveData (AssetOwnLiveData.vue-ийн switch-ээр бүртгэгдсэн, is_mode='livedata')
// талбарын тохиргоо — sensor tab-ын dynamic field-үүдийн is_show/нэрийг
// үүнээс авна (manualCustomFields/rawdata-аас БИШ — холилгүй байхын тулд)
const liveDataCustomFields = ref<any[]>([])
const loadLiveDataCustomFieldConfig = async () => {
  if (!props.assetId) return
  try {
    const response = await getItems<any>({
      collection: 'Device_tracking_fields',
      params: {
        filter: {
          asset: { _eq: props.assetId },
          is_mode: { _eq: 'livedata' },
        },
      },
    })
    liveDataCustomFields.value = Array.isArray(response)
      ? response
      : (response as any)?.data || []
  } catch (err: any) {
    console.warn('⚠️ Could not load LiveData custom fields:', err.message)
    liveDataCustomFields.value = []
  }
}

// "Device", "device", "temperature", "Temperature" зэрэг ялгаатай нэрийг
// ижил гэж танихын тулд normalize хийнэ (жижиг үсэг, зөвхөн үсэг+тоо)
const normalizeFieldKey = (key: any): string =>
  String(key || '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '')

// LiveData (Sensors -> Sensor_reading)-ээс ирж болох, мэдэгдэж буй тоон
// талбарууд — WISE (temperature/vibration) болон SmartGPS/json_data
// (speed, fuel_level гэх мэт) хоёуланг нь хамарна. json_data.sensors.*
// дотор буй, УРЬДЧИЛАН МЭДЭГДЭЖГҮЙ (device бүрт өөр) талбаруудыг
// buildDynamicSensorFieldDefs()-д dynamic-аар (энэ dictionary-д байхгүй ч)
// нэмж танина.
const KNOWN_SENSOR_FIELD_LABELS: Record<
  string,
  { mn: string; en: string; unit: string }
> = {
  temperature: { mn: 'Температур', en: 'Temperature', unit: '°C' },
  vibration_x: { mn: 'Чичиргээ X', en: 'Vibration X', unit: 'mm/s' },
  vibration_y: { mn: 'Чичиргээ Y', en: 'Vibration Y', unit: 'mm/s' },
  vibration_z: { mn: 'Чичиргээ Z', en: 'Vibration Z', unit: 'mm/s' },
  speed: { mn: 'Хурд', en: 'Speed', unit: 'км/ц' },
  fuel_level: { mn: 'Түлш', en: 'Fuel level', unit: '%' },
  odometer_km: { mn: 'Гүйлт', en: 'Odometer', unit: 'км' },
  engine_hours_h: { mn: 'Мотор цаг', en: 'Engine hours', unit: 'ц' },
  battery_voltage: { mn: 'Батарей', en: 'Battery', unit: 'V' },
  voltage: { mn: 'Хүчдэл', en: 'Voltage', unit: 'V' },
  temperature_2: { mn: 'Температур 2', en: 'Temperature 2', unit: '°C' },
  gps_signal: { mn: 'GPS сигнал', en: 'GPS signal', unit: '' },
  brk_max: { mn: 'Тоормос (max)', en: 'Braking', unit: 'g' },
  accel_max: { mn: 'Хурдасгал (max)', en: 'Acceleration', unit: 'g' },
  ignition: { mn: 'Асаалт', en: 'Ignition', unit: '' },
}

// Идэвхтэй sensor tab-ын бодитоор ачаалагдсан бичлэгүүдээс байгаа тоон
// талбаруудын дундаас ЗӨВХӨН Device_tracking_fields дээр (is_mode='livedata',
// AssetOwnLiveData.vue-ийн switch-ээр) is_show=1 болж бүртгэгдсэн талбаруудыг
// л field def болгоно — тохируулаагүй (бүртгэгдээгүй) талбарыг chart-д
// огт нэмэхгүй
const buildDynamicSensorFieldDefs = (records: any[]): any[] => {
  // "code" баганад тухайн sensor-ын device_id хадгалагддаг тул идэвхтэй
  // tab-тай (activeSensorTab) таарсан тохиргоог л ашиглана — 2 sensor ижил
  // field_key (жишээ нь "speed") үүсгэсэн ч тус тусдаа тохиргоотой байна
  const liveByKey = new Map(
    liveDataCustomFields.value
      .filter((f: any) => f.code === activeSensorTab.value)
      .map((f: any) => [f.field_key, f]),
  )
  const defs: any[] = []
  const seen = new Set<string>()
  let sortOrder = 900

  for (const record of records) {
    for (const [key, value] of Object.entries(record)) {
      if (key === 'timestamp' || seen.has(key)) continue
      if (typeof value !== 'number') continue

      seen.add(key)
      const configured = liveByKey.get(key)
      if (!configured || configured.is_show !== 1) continue

      const known = KNOWN_SENSOR_FIELD_LABELS[key]
      defs.push({
        field_key: key,
        field_name_mn:
          configured.field_name_mn ||
          known?.mn ||
          key.replace(/^s_/, '').replace(/_/g, ' '),
        field_name_en:
          configured.field_name_en || known?.en || key.replace(/^s_/, ''),
        unit: configured.unit || known?.unit || '',
        show_in_chart: true,
        is_show: 1,
        sort_order: sortOrder++,
      })
    }
  }

  return defs
}

// Энэ asset-д харьяалагдах Sensors-ийг device_id (бодит sensor тус бүрийн
// давхцагүй ID, device_type биш — тэр нь зөвхөн MODEL) + харуулах нэрээр нь
// олно — "Raw data" + sensor тус бүрийн tab-ыг үүгээр байгуулна
const assignedSensors = ref<{ deviceId: string; deviceName: string }[]>([])
const activeSensorTab = ref('raw')
// Sensor-той таарахгүй (эсвэл Device утгагүй) manual бичлэг байгаа эсэх —
// байхгүй бол "Raw data" tab-ыг нуух
const hasRawData = ref(true)
const sensorTabs = computed(() => [
  ...(hasRawData.value ? [{ key: 'raw', label: t('Raw data') }] : []),
  ...assignedSensors.value.map((s) => ({
    key: s.deviceId,
    label: s.deviceName,
  })),
])

const loadAssignedSensors = async () => {
  if (!props.assetId) {
    assignedSensors.value = []
    return
  }
  try {
    const response = await getItems<any>({
      collection: 'Sensors',
      params: {
        filter: { asset: { _eq: props.assetId } },
        fields: ['device_id', 'device_name'],
        limit: -1,
      },
    })
    const items = Array.isArray(response)
      ? response
      : (response as any)?.data || []

    const seen = new Map<string, string>()
    for (const s of items) {
      if (s.device_id && !seen.has(s.device_id)) {
        seen.set(s.device_id, s.device_name || s.device_id)
      }
    }
    assignedSensors.value = [...seen.entries()].map(
      ([deviceId, deviceName]) => ({ deviceId, deviceName }),
    )
  } catch (err) {
    console.warn('⚠️ Could not load assigned sensors:', err)
    assignedSensors.value = []
  }
}

// Sensor_reading-ээс monitoringData-тай ижил хэлбэрт ({timestamp, ...values})
// хөрвүүлж татна — ЗӨВХӨН идэвхтэй tab-ын нэг sensor (deviceId)-ийн
// бичлэгүүдийг (өөр sensor-той холилдохгүй)
const loadSensorReadingData = async (
  deviceId: string,
  fromValue: string,
  toValue: string,
): Promise<any[]> => {
  if (!deviceId) return []

  try {
    const filter: any = { device_id: { _eq: deviceId } }
    if (fromValue !== 'all_time' && toValue !== 'all_time') {
      filter.date_created = {
        _gte: `${fromValue}T00:00:00`,
        _lte: `${toValue}T23:59:59`,
      }
    }

    const response = await getItems<any>({
      collection: 'Sensor_reading',
      params: {
        filter,
        sort: ['-date_created'],
        limit: 1000,
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
      : (response as any)?.data || []

    return items.map((reading: any) => {
      const timestamp = Math.floor(
        new Date(reading.date_created).getTime() / 1000,
      )

      // SmartGPS зэрэг шинэ integration-ууд json_data-д багц (нэг бүхэл
      // JSON) payload оруулдаг — dynamic-аар (тоон талбар бүрийг) уншина
      if (reading.json_data && typeof reading.json_data === 'object') {
        const record: any = { timestamp }
        const data = reading.json_data
        for (const key of Object.keys(KNOWN_SENSOR_FIELD_LABELS)) {
          const value = data[key]
          if (typeof value === 'number') record[key] = value
          else if (typeof value === 'boolean') record[key] = value ? 1 : 0
        }
        if (data.sensors && typeof data.sensors === 'object') {
          for (const [key, value] of Object.entries(data.sensors)) {
            // Device_tracking_fields.field_key нь json_data.sensors-ийн
            // түлхүүрийг (жишээ нь "s_speed") шууд, нэмэлт угтваргүй
            // ашигладаг тул энд ч мөн (сан хийсвэрлэлгүй) шууд хэрэглэнэ
            if (typeof value === 'number' && record[key] === undefined) {
              record[key] = value
            }
          }
        }
        return record
      }

      // Хуучин WISE (temperature/vibration_x/y/z) хэлбэр
      return {
        timestamp,
        temperature: reading.temperature,
        vibration_x: reading.vibration_x,
        vibration_y: reading.vibration_y,
        vibration_z: reading.vibration_z,
      }
    })
  } catch (err) {
    console.warn('⚠️ Could not load sensor readings:', err)
    return []
  }
}

// Идэвхтэй tab (activeSensorTab)-д тохирсон дата-г ЗААСАН огнооны мужаар
// (fromValue-toValue) татаж {fields, records, rawCount} буцаана. "Raw data"
// (Asset_field_data_json) эсвэл зөвхөн ТУХАЙН НЭГ sensor (Sensor_reading)-ийн
// бичлэгүүдийг (sensor-ууд хоорондоо холилдохгүй) — Statistics/Sparkline-ийн
// үндсэн огнооны муж, мөн Data trend/Historical chart-ийн тусдаа муж хоёулаа
// үүгээр дамжина.
const fetchTabScopedData = async (
  fromValue: string,
  toValue: string,
): Promise<{ fields: any[]; records: any[]; rawCount: number }> => {
  let timestampFilter: any = {}

  if (fromValue !== 'all_time' && toValue !== 'all_time') {
    const fromDate = new Date(fromValue + 'T00:00:00')
    const toDate = new Date(toValue + 'T23:59:59')

    timestampFilter = {
      _gte: Math.floor(fromDate.getTime() / 1000),
      _lte: Math.floor(toDate.getTime() / 1000),
    }
  }

  const filterParams: any = {
    asset: { _eq: props.assetId },
    company_id: { _eq: myCompanyId },
  }

  if (Object.keys(timestampFilter).length > 0) {
    filterParams.timestamp = timestampFilter
  }

  const response = await getItems<any>({
    collection: 'Asset_field_data_json',
    params: {
      filter: filterParams,
      sort: ['timestamp'],
      limit: 1000,
      fields: ['*'],
    },
  })

  const items = (
    Array.isArray(response) ? response : (response as any)?.data || []
  ) as any[]

  const allManualRecords = items.map((item) => {
    const fieldValues =
      typeof item.field_values === 'string'
        ? JSON.parse(item.field_values)
        : item.field_values

    return {
      timestamp: item.timestamp,
      ...fieldValues,
    }
  })

  // Excel-ийн "Device" (эсвэл ижил төстэй) утгыг мэдэгдэж буй
  // Sensors.device_id-тэй тааруулж, бичлэг бүрийг аль tab-д
  // харьяалагдахыг тодорхойлно — таарвал sensor tab, таарахгүй бол "raw"
  const deviceIdByNormalized = new Map(
    assignedSensors.value.map((s) => [
      normalizeFieldKey(s.deviceId),
      s.deviceId,
    ]),
  )
  const manualRecordsByTab = new Map<string, any[]>()
  for (const record of allManualRecords) {
    const rawDeviceValue =
      record.Device ?? record.device ?? record.Device_id ?? record.device_id
    const matchedDeviceId = rawDeviceValue
      ? deviceIdByNormalized.get(normalizeFieldKey(String(rawDeviceValue)))
      : undefined
    const tabKey = matchedDeviceId || 'raw'
    if (!manualRecordsByTab.has(tabKey)) manualRecordsByTab.set(tabKey, [])
    manualRecordsByTab.get(tabKey)!.push(record)
  }

  const rawCount = (manualRecordsByTab.get('raw') || []).length

  if (activeSensorTab.value === 'raw') {
    return {
      fields: manualCustomFields.value,
      records: manualRecordsByTab.get('raw') || [],
      rawCount,
    }
  }

  // Sensor tab дээр ЗӨВХӨН тухайн sensor-ын Sensor_reading — raw/manual
  // (Asset_field_data_json) дататай ХОЛИХГҮЙ, tab бүр өөрийн дата харуулна
  const sensorRecords = await loadSensorReadingData(
    activeSensorTab.value,
    fromValue,
    toValue,
  )

  // Идэвхтэй sensor-ийн бодит бичлэгүүдээс (WISE эсвэл SmartGPS/json_data)
  // тоон талбаруудыг dynamic-аар нэгтгэнэ
  const dynamicFields = buildDynamicSensorFieldDefs(sensorRecords)

  return { fields: dynamicFields, records: sensorRecords, rawCount }
}

// Sparkline/Statistics-ийн үндсэн (дээд талын) огнооны мужаар дата ачаална
const loadMonitoringData = async () => {
  if (!props.assetId) return

  loading.value = true
  error.value = null

  try {
    const result = await fetchTabScopedData(customFrom.value, customTo.value)
    hasRawData.value = result.rawCount > 0

    // "Raw data"-д огт бичлэг байхгүй бол tab-ыг өөрөө нуух ба, идэвхтэй
    // байсан бол эхний sensor tab руу шилжүүлнэ (хоосон tab үзүүлэхгүй)
    if (
      activeSensorTab.value === 'raw' &&
      !hasRawData.value &&
      assignedSensors.value.length > 0
    ) {
      activeSensorTab.value = assignedSensors.value[0].deviceId
      return
    }

    console.log(
      `Monitoring data loaded (${activeSensorTab.value}):`,
      result.records.length,
      'records',
    )

    customFields.value = result.fields
    monitoringData.value = result.records
    latestData.value = result.records.length
      ? result.records[result.records.length - 1]
      : null
  } catch (err: any) {
    console.error('❌ Error loading monitoring data:', err)
    error.value = err.message || t('Error loading data')
  } finally {
    loading.value = false
  }
}

// "3. Data trend" (areaCustomers)-ийн тусдаа огнооны мужийн сонголт
const areaFrom = ref(customFrom.value)
const areaTo = ref(customTo.value)
const areaMonitoringData = ref<any[]>([])
const areaCustomFieldsForTab = ref<any[]>([])
const areaLoading = ref(false)

const loadAreaData = async () => {
  if (!props.assetId) return
  areaLoading.value = true
  try {
    const result = await fetchTabScopedData(areaFrom.value, areaTo.value)
    areaCustomFieldsForTab.value = result.fields
    areaMonitoringData.value = result.records
  } catch (err) {
    console.error('❌ Error loading data trend chart data:', err)
  } finally {
    areaLoading.value = false
  }
}

// "4. Historical data chart" (chartConfig)-ийн тусдаа огнооны мужийн сонголт
const historyFrom = ref(customFrom.value)
const historyTo = ref(customTo.value)
const historyMonitoringData = ref<any[]>([])
const historyCustomFieldsForTab = ref<any[]>([])
const historyLoading = ref(false)

const loadHistoryData = async () => {
  if (!props.assetId) return
  historyLoading.value = true
  try {
    const result = await fetchTabScopedData(historyFrom.value, historyTo.value)
    historyCustomFieldsForTab.value = result.fields
    historyMonitoringData.value = result.records
  } catch (err) {
    console.error('❌ Error loading historical chart data:', err)
  } finally {
    historyLoading.value = false
  }
}

// Toggle auto-refresh
const toggleAutoRefresh = () => {
  autoRefresh.value = !autoRefresh.value

  if (autoRefresh.value) {
    // Refresh every 30 seconds
    refreshInterval.value = window.setInterval(() => {
      loadMonitoringData()
    }, 30000)
  } else {
    if (refreshInterval.value) {
      clearInterval(refreshInterval.value)
      refreshInterval.value = null
    }
  }
}

// Get field icon and color
const getFieldIcon = (
  fieldKey: string,
): {
  icon: string
  color:
    | 'default'
    | 'primary'
    | 'info'
    | 'success'
    | 'warning'
    | 'danger'
    | undefined
} => {
  const iconMap: Record<
    string,
    {
      icon: string
      color:
        | 'default'
        | 'primary'
        | 'info'
        | 'success'
        | 'warning'
        | 'danger'
        | undefined
    }
  > = {
    speed: { icon: 'ph:speedometer', color: 'primary' },
    latitude: { icon: 'ph:map-pin', color: 'info' },
    longitude: { icon: 'ph:map-pin', color: 'info' },
    fuel_level: { icon: 'ph:gas-pump', color: 'success' },
    engine_hours: { icon: 'ph:engine', color: 'warning' },
    odometer: { icon: 'ph:gauge', color: 'info' },
    altitude: { icon: 'ph:mountains', color: 'default' },
    direction: { icon: 'ph:compass', color: 'default' },
    satellites: { icon: 'ph:satellite', color: 'default' },
    temperature: { icon: 'ph:thermometer', color: 'danger' },
    worked_time: { icon: 'ph:clock', color: 'primary' },
    used_energy: { icon: 'ph:lightning', color: 'warning' },
    created_money: { icon: 'ph:currency-circle-dollar', color: 'success' },
    spend_balance: { icon: 'ph:wallet', color: 'info' },
  }
  return iconMap[fieldKey] || { icon: 'ph:chart-line', color: 'primary' }
}

// Statistics calculation
const getFieldStats = (fieldKey: string) => {
  const values = monitoringData.value
    .map((record) => record[fieldKey])
    .filter((v) => v !== undefined && v !== null && typeof v === 'number')

  if (values.length === 0) {
    return { min: null, max: null, avg: null, current: null }
  }

  const current = latestData.value?.[fieldKey]
  const min = Math.min(...values)
  const max = Math.max(...values)
  const avg = values.reduce((a, b) => a + b, 0) / values.length

  return {
    min: min.toFixed(2),
    max: max.toFixed(2),
    avg: avg.toFixed(2),
    current:
      current !== undefined && current !== null ? current.toFixed(2) : null,
  }
}

// Valid monitoring fields (excluding timestamp, respecting is_show switch)
const validMonitoringFields = computed(() =>
  customFields.value.filter(
    (f) => f.field_key !== 'timestamp' && isFieldShown(f),
  ),
)

// Analytics Charts from tab4
const sparkLineOne = computed(() => {
  const { primary } = useTailwindColors()
  const validFields = customFields.value.filter(
    (f) => f.field_key !== 'timestamp' && isFieldShown(f),
  )
  if (!monitoringData.value.length || !validFields[0]) return null

  const firstField = validFields[0]
  const data = monitoringData.value
    .slice(-10)
    .map((r) => r[firstField.field_key] || 0)

  return {
    height: 60,
    type: 'line',
    options: {
      chart: {
        id: 'sparkline1',
        sparkline: { enabled: true },
      },
      stroke: { curve: 'smooth', width: [2] },
      colors: [primary.value],
      tooltip: {
        fixed: { enabled: true, position: 'right' },
        x: { show: false },
      },
    },
    series: [{ name: firstField.field_name_mn, data }],
  }
})

const sparkLineTwo = computed(() => {
  const { success } = useTailwindColors()
  const validFields = customFields.value.filter(
    (f) => f.field_key !== 'timestamp' && isFieldShown(f),
  )
  if (!monitoringData.value.length || !validFields[1]) return null

  const secondField = validFields[1]
  const data = monitoringData.value
    .slice(-10)
    .map((r) => r[secondField.field_key] || 0)

  return {
    height: 60,
    type: 'line',
    options: {
      chart: {
        id: 'sparkline2',
        sparkline: { enabled: true },
      },
      stroke: { curve: 'smooth', width: [2] },
      colors: [success.value],
      tooltip: {
        fixed: { enabled: true, position: 'right' },
        x: { show: false },
      },
    },
    series: [{ name: secondField.field_name_mn, data }],
  }
})

const sparkLineThree = computed(() => {
  const { info } = useTailwindColors()
  const validFields = customFields.value.filter(
    (f) => f.field_key !== 'timestamp' && isFieldShown(f),
  )
  if (!monitoringData.value.length || !validFields[2]) return null

  const thirdField = validFields[2]
  const data = monitoringData.value
    .slice(-10)
    .map((r) => r[thirdField.field_key] || 0)

  return {
    height: 60,
    type: 'line',
    options: {
      chart: {
        id: 'sparkline3',
        sparkline: { enabled: true },
      },
      stroke: { curve: 'smooth', width: [2] },
      colors: [info.value],
      tooltip: {
        fixed: { enabled: true, position: 'right' },
        x: { show: false },
      },
    },
    series: [{ name: thirdField.field_name_mn, data }],
  }
})

const sparkLineFour = computed(() => {
  const { danger } = useTailwindColors()
  const validFields = customFields.value.filter(
    (f) => f.field_key !== 'timestamp' && isFieldShown(f),
  )
  if (!monitoringData.value.length || !validFields[3]) return null

  const fourthField = validFields[3]
  const data = monitoringData.value
    .slice(-10)
    .map((r) => r[fourthField.field_key] || 0)

  return {
    height: 60,
    type: 'line',
    options: {
      chart: {
        id: 'sparkline4',
        sparkline: { enabled: true },
      },
      stroke: { curve: 'smooth', width: [2] },
      colors: [danger.value],
      tooltip: {
        fixed: { enabled: true, position: 'right' },
        x: { show: false },
      },
    },
    series: [{ name: fourthField.field_name_mn, data }],
  }
})

// Pie Chart - Field Value Distribution
const pieChartData = computed(() => {
  const { primary, info, success, warning, danger } = useTailwindColors()
  const colors = [
    primary.value,
    info.value,
    success.value,
    warning.value,
    danger.value,
    '#8b5cf6',
    '#ec4899',
  ]

  const validFields = customFields.value.filter(
    (f) => f.field_key !== 'timestamp' && isFieldShown(f),
  )

  if (!monitoringData.value.length || !validFields.length) return null

  // Calculate average for each field for pie chart
  const series = validFields.slice(0, 5).map((field) => {
    const values = monitoringData.value
      .map((record) => record[field.field_key])
      .filter((v) => typeof v === 'number' && v > 0)

    if (values.length === 0) return 0
    return Math.round(values.reduce((a, b) => a + b, 0) / values.length)
  })

  const labels = validFields
    .slice(0, 5)
    .map((f) => `${f.field_name_mn} (${f.unit || ''})`)

  return {
    type: 'pie',
    height: 300,
    options: {
      chart: { toolbar: { show: true } },
      labels,
      colors: colors.slice(0, labels.length),
      legend: { position: 'bottom' },
      dataLabels: { enabled: true },
      tooltip: {
        y: { formatter: (v: number) => v + '' },
      },
    },
    series,
  }
})

// Bar Chart - Comparison Chart
const barChartData = computed(() => {
  const { primary, info, success } = useTailwindColors()
  const validFields = customFields.value.filter(
    (f) => f.field_key !== 'timestamp' && isFieldShown(f),
  )

  if (!monitoringData.value.length || !validFields.length) return null

  const categories = validFields.slice(0, 6).map((f) => f.field_name_mn)

  // Get latest values for bar chart
  const series = [
    {
      name: t('Current value'),
      data: validFields.slice(0, 6).map((field) => {
        const value = latestData.value?.[field.field_key]
        return typeof value === 'number' ? value : 0
      }),
    },
    {
      name: t('Average value'),
      data: validFields.slice(0, 6).map((field) => {
        const values = monitoringData.value
          .map((record) => record[field.field_key])
          .filter((v) => typeof v === 'number')
        return values.length
          ? Math.round(
              (values.reduce((a, b) => a + b, 0) / values.length) * 100,
            ) / 100
          : 0
      }),
    },
  ]

  return {
    type: 'bar',
    height: 350,
    options: {
      chart: {
        toolbar: { show: true },
        stacked: false,
      },
      colors: [primary.value, success.value],
      plotOptions: {
        bar: {
          horizontal: false,
          columnWidth: '55%',
          borderRadius: 4,
          dataLabels: { position: 'top' },
        },
      },
      dataLabels: { enabled: false },
      stroke: { show: true, width: 2, colors: ['transparent'] },
      xaxis: { categories },
      yaxis: { title: { text: t('Value') } },
      fill: { opacity: 0.8 },
      tooltip: {
        y: { formatter: (v: number) => Math.round(v * 100) / 100 + '' },
      },
      legend: { position: 'top', horizontalAlign: 'left' },
    },
    series,
  }
})

// Gauge Chart - Performance Status
const gaugeChartData = computed(() => {
  const { primary } = useTailwindColors()
  const validFields = customFields.value.filter(
    (f) => f.field_key !== 'timestamp' && isFieldShown(f),
  )

  if (!monitoringData.value.length || !validFields[0]) return null

  const field = validFields[0]
  const values = monitoringData.value
    .map((record) => record[field.field_key])
    .filter((v) => typeof v === 'number')

  if (values.length === 0) return null

  const currentValue = latestData.value?.[field.field_key] || 0
  const maxValue = Math.max(...values)
  const percentage = Math.round((currentValue / maxValue) * 100)

  return {
    type: 'radialBar',
    height: 350,
    options: {
      chart: { toolbar: { show: false } },
      plotOptions: {
        radialBar: {
          startAngle: -135,
          endAngle: 135,
          track: { background: '#f3f4f6' },
          dataLabels: {
            name: { fontSize: '16px' },
            value: { fontSize: '24px' },
            total: {
              show: true,
              label: t('Load'),
              fontSize: '16px',
            },
          },
        },
      },
      colors: [primary.value],
      labels: [field.field_name_mn],
    },
    series: [percentage > 100 ? 100 : percentage],
  }
})

const areaChartColors = computed(() => {
  const { primary, info, success, warning, danger } = useTailwindColors()
  return [
    primary.value,
    info.value,
    success.value,
    warning.value,
    danger.value,
    '#8b5cf6',
    '#ec4899',
  ]
})

const areaCustomers = computed(() => {
  const palette = areaChartColors.value
  const validFields = areaCustomFieldsForTab.value.filter(
    (f) => f.field_key !== 'timestamp' && isFieldShown(f),
  )
  if (!areaMonitoringData.value.length || !validFields.length) return null

  const categories = areaMonitoringData.value.map((record) => {
    const date = new Date(record.timestamp * 1000)
    return date.toISOString()
  })

  const series = validFields.map((field) => ({
    name: field.field_name_mn,
    data: areaMonitoringData.value.map(
      (record) => record[field.field_key] || 0,
    ),
  }))

  return {
    type: 'area',
    height: 258,
    options: {
      chart: {
        toolbar: { show: false },
      },
      colors: validFields.map((_, i) => palette[i % palette.length]),
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
        categories,
      },
      tooltip: {
        x: {
          format: 'dd/MM/yy HH:mm',
        },
      },
    },
    series,
  }
})

onMounted(async () => {
  console.log(' OwnMonitoring mounted, assetId:', props.assetId)
  await loadCustomFieldConfig()
  await loadLiveDataCustomFieldConfig()
  await loadAssignedSensors()
  await loadMonitoringData()
  await Promise.all([loadAreaData(), loadHistoryData()])
  // Start monitoring alerts polling (10 second interval) neeh
  // startAlertPolling()
})

// Sensor tab солигдоход бүх хэсэг (үндсэн, Data trend, Historical chart)
// тухайн tab-даа тохирсон дата дахин ачаална
watch(activeSensorTab, () => {
  loadMonitoringData()
  loadAreaData()
  loadHistoryData()
})

onUnmounted(() => {
  if (refreshInterval.value) {
    clearInterval(refreshInterval.value)
  }
  // neeh
  // stopAlertPolling()
})
</script>

<template>
  <div class="own-monitoring">
    <!-- Sensor tabs: "Raw data" + sensor тус бүр -->
    <div v-if="sensorTabs.length > 1" class="flex items-center gap-2 mb-4">
      <button
        v-for="tabItem in sensorTabs"
        :key="tabItem.key"
        type="button"
        class="rounded-lg px-3 py-1.5 text-sm font-medium transition-colors"
        :class="
          activeSensorTab === tabItem.key
            ? 'bg-primary-500 text-white'
            : 'bg-muted-100 dark:bg-muted-700 text-muted-500 dark:text-muted-300'
        "
        @click="activeSensorTab = tabItem.key"
      >
        {{ tabItem.label }}
      </button>
    </div>

    <!-- Controls -->
    <div class="mb-6 flex items-center justify-between flex-wrap gap-4">
      <div class="flex items-center gap-3 flex-wrap">
        <!-- Custom Date Inputs — эцэг компонент өөрийн дээд түвшний огнооны
             filter-тэй үед (hideDateControls) давхардуулахгүйн тулд нуух -->
        <div
          v-if="!hideDateControls"
          class="Custom_Date_Inputs flex items-center gap-2"
        >
          <BaseInput
            v-model="customFrom"
            type="date"
            size="sm"
            placeholder="From"
            class="w-36"
          />
          <span class="text-muted-400">-</span>
          <BaseInput
            v-model="customTo"
            type="date"
            size="sm"
            placeholder="To"
            class="w-36"
          />
          <BaseButton
            size="sm"
            color="primary"
            @click="
              () => {
                selectedRangeText = 'Custom Range'
                selectedDays = 0
                loadMonitoringData()
              }
            "
          >
            <Icon name="ph:funnel" class="h-4 w-4" />
          </BaseButton>
        </div>

        <!-- Refresh Button -->
        <BaseButton
          size="sm"
          color="default"
          :loading="loading"
          @click="loadMonitoringData"
        >
          <Icon name="ph:arrow-clockwise" class="h-4 w-4" />
          <span class="ml-1.5">{{ t('Refresh') }}</span>
        </BaseButton>

        <!-- Auto Refresh Toggle -->
        <!-- <BaseButton
          size="sm"
          :color="autoRefresh ? 'primary' : 'default'"
          @click="toggleAutoRefresh"
        >
          <Icon
            :name="autoRefresh ? 'ph:pause-circle-fill' : 'ph:play-circle-fill'"
            class="h-4 w-4"
          />
          <span class="ml-1.5">{{
            autoRefresh ? t('Stop') : t('Auto refresh')
          }}</span>
        </BaseButton> -->
      </div>

      <div class="text-sm text-muted-500 flex flex-wrap items-center gap-3">
        <span>
          <Icon name="ph:clock" class="h-4 w-4 inline mr-1" />
          {{ monitoringData.length }} {{ t('record') }}
        </span>
        <!-- <span v-if="latestData">
          <Icon name="ph:calendar" class="h-4 w-4 inline mr-1" />
          {{ formatTimestamp(latestData.timestamp) }}
        </span>
        <span
          v-if="
            latestData &&
            (latestData.engine_hours !== undefined ||
              latestData.worked_time !== undefined)
          "
        >
          <Icon name="ph:engine" class="h-4 w-4 inline mr-1" />
          {{ t('Engine hours') }}:
          <span class="font-semibold text-muted-800 dark:text-muted-100">
            {{
              formatNumber(
                latestData.engine_hours || latestData.worked_time || 0,
              )
            }}
            ц
          </span>
        </span>
        <span v-if="latestData && latestData.odometer !== undefined">
          <Icon name="ph:gauge" class="h-4 w-4 inline mr-1" />
          {{ t('Odometer') }}:
          <span class="font-semibold text-muted-800 dark:text-muted-100">
            {{ formatNumber(latestData.odometer || 0) }} км
          </span>
        </span> -->
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="flex items-center justify-center py-12">
      <BaseIconBox size="xl" color="primary" class="animate-pulse">
        <Icon name="svg-spinners:blocks-shuffle-3" class="h-8 w-8" />
      </BaseIconBox>
    </div>

    <!-- Error State -->
    <BaseCard v-else-if="error" class="p-6">
      <div class="flex items-center gap-4 text-danger-500">
        <Icon name="ph:warning-circle" class="h-8 w-8" />
        <div>
          <p class="font-semibold">{{ t('An error occurred') }}</p>
          <p class="text-sm">{{ error }}</p>
        </div>
      </div>
    </BaseCard>

    <!-- No Custom Fields -->
    <BaseCard
      v-else-if="customFields.length === 0"
      class="p-12 bg-warning-50 dark:bg-warning-900/20 border border-warning-200 dark:border-warning-800"
    >
      <div class="text-center space-y-4">
        <Icon
          name="ph:warning-circle"
          class="h-16 w-16 mx-auto mb-4 text-warning-500"
        />
        <div>
          <p
            class="text-warning-800 dark:text-warning-200 font-semibold text-lg mb-2"
          >
            {{ t('Settings tab fields not configured') }}
          </p>
          <p class="text-warning-600 dark:text-warning-400 text-sm">
            {{ t('Please configure Settings(Device_tracking_fields).') }}
          </p>
        </div>
      </div>
    </BaseCard>

    <!-- No Data -->
    <BaseCard
      v-else-if="monitoringData.length === 0"
      class="p-12 bg-info-50 dark:bg-info-900/20 border border-info-200 dark:border-info-800"
    >
      <div class="text-center space-y-4">
        <Icon name="ph:database" class="h-16 w-16 mx-auto mb-4 text-info-500" />
        <div>
          <p
            class="text-info-800 dark:text-info-200 font-semibold text-lg mb-2"
          >
            {{ t('No information available') }}
          </p>
          <p class="text-info-600 dark:text-info-400 text-sm">
            {{
              t(
                'No data found for the selected period or data has not been imported.',
              )
            }}
          </p>
        </div>
      </div>
    </BaseCard>

    <!-- Data_Display -->
    <div v-else class="space-y-6">
      <div class="Data_Display grid grid-cols-12 gap-6">
        <!-- Sparkline Card 1 -->
        <div
          v-if="sparkLineOne && validMonitoringFields[0]"
          class="cardBox ptablet:col-span-6 col-span-12 sm:col-span-3"
        >
          <BaseCard class="p-6">
            <div class="flex items-center justify-between">
              <BaseHeading
                as="h4"
                size="sm"
                weight="medium"
                lead="tight"
                class="text-muted-400 mb-1"
              >
                <span>{{ validMonitoringFields[0].field_name_mn }}</span>
              </BaseHeading>
            </div>
            <div class="flex items-center justify-between gap-6 pt-4">
              <div class="grow">
                <span
                  class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
                >
                  {{
                    formatNumber(
                      latestData?.[validMonitoringFields[0].field_key],
                    )
                  }}
                  <span
                    v-if="validMonitoringFields[0].unit"
                    class="text-sm font-normal ml-1"
                    >{{ validMonitoringFields[0].unit }}</span
                  >
                </span>
              </div>
              <div class="grow">
                <AddonApexcharts v-bind="sparkLineOne" />
              </div>
            </div>
          </BaseCard>
        </div>

        <!-- Sparkline Card 2 -->
        <div
          v-if="sparkLineTwo && validMonitoringFields[1]"
          class="cardBox ptablet:col-span-6 col-span-12 sm:col-span-3"
        >
          <BaseCard class="p-6">
            <div class="flex items-center justify-between">
              <BaseHeading
                as="h4"
                size="sm"
                weight="medium"
                lead="tight"
                class="text-muted-400 mb-1"
              >
                <span>{{ validMonitoringFields[1].field_name_mn }}</span>
              </BaseHeading>
            </div>
            <div class="flex items-center justify-between gap-6 pt-4">
              <div class="grow">
                <span
                  class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
                >
                  {{
                    formatNumber(
                      latestData?.[validMonitoringFields[1].field_key],
                    )
                  }}
                  <span
                    v-if="validMonitoringFields[1].unit"
                    class="text-sm font-normal ml-1"
                    >{{ validMonitoringFields[1].unit }}</span
                  >
                </span>
              </div>
              <div class="grow">
                <AddonApexcharts v-bind="sparkLineTwo" />
              </div>
            </div>
          </BaseCard>
        </div>

        <!-- Sparkline Card 3 -->
        <div
          v-if="sparkLineThree && validMonitoringFields[2]"
          class="cardBox ptablet:col-span-6 col-span-12 sm:col-span-3"
        >
          <BaseCard class="p-6">
            <div class="flex items-center justify-between">
              <BaseHeading
                as="h4"
                size="sm"
                weight="medium"
                lead="tight"
                class="text-muted-400 mb-1"
              >
                <span>{{ validMonitoringFields[2].field_name_mn }}</span>
              </BaseHeading>
            </div>
            <div class="flex items-center justify-between gap-6 pt-4">
              <div class="grow">
                <span
                  class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
                >
                  {{
                    formatNumber(
                      latestData?.[validMonitoringFields[2].field_key],
                    )
                  }}
                  <span
                    v-if="validMonitoringFields[2].unit"
                    class="text-sm font-normal ml-1"
                    >{{ validMonitoringFields[2].unit }}</span
                  >
                </span>
              </div>
              <div class="grow">
                <AddonApexcharts v-bind="sparkLineThree" />
              </div>
            </div>
          </BaseCard>
        </div>

        <!-- Sparkline Card 4 -->
        <div
          v-if="sparkLineFour && validMonitoringFields[3]"
          class="cardBox ptablet:col-span-6 col-span-12 sm:col-span-3"
        >
          <BaseCard class="p-6">
            <div class="flex items-center justify-between">
              <BaseHeading
                as="h4"
                size="sm"
                weight="medium"
                lead="tight"
                class="text-muted-400 mb-1"
              >
                <span>{{ validMonitoringFields[3].field_name_mn }}</span>
              </BaseHeading>
            </div>
            <div class="flex items-center justify-between gap-6 pt-4">
              <div class="grow">
                <span
                  class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
                >
                  {{
                    formatNumber(
                      latestData?.[validMonitoringFields[3].field_key],
                    )
                  }}
                  <span
                    v-if="validMonitoringFields[3].unit"
                    class="text-sm font-normal ml-1"
                    >{{ validMonitoringFields[3].unit }}</span
                  >
                </span>
              </div>
              <div class="grow">
                <AddonApexcharts v-bind="sparkLineFour" />
              </div>
            </div>
          </BaseCard>
        </div>

        <!-- 1,2 Line Chart -->
        <div class="col-span-12">
          <OwnPerformanceCharts
            :asset="Number(props.assetId)"
            :from="customFrom"
            :to="customTo"
            :active-sensor-tab="activeSensorTab"
            :sensor-device-ids="assignedSensors.map((s) => s.deviceId)"
            tab="monitoring"
          />
        </div>

        <!-- 3. Area Chart - Data Trend Analysis -->
        <div class="cardBox col-span-12">
          <BaseCard class="p-6">
            <div class="mb-4 flex flex-wrap items-center justify-between gap-2">
              <BaseHeading as="h4" size="md" weight="semibold" class="mb-3">
                <p
                  class="chart_title text-lg font-semibold text-gray-700 dark:text-gray-300"
                >
                  📊 3. {{ t('Data trend') }}
                </p>
              </BaseHeading>

              <div class="flex flex-wrap items-center gap-4 text-sm">
                <div
                  v-for="(field, index) in validMonitoringFields.filter(
                    (f) => f.show_in_chart !== false,
                  )"
                  :key="field.field_key"
                >
                  <span class="text-muted-400">{{ t('Current') }}:</span>
                  <span
                    class="font-medium ml-1"
                    :style="{
                      color: areaChartColors[index % areaChartColors.length],
                    }"
                  >
                    {{ field.field_name_mn }}:
                    {{ formatNumber(latestData?.[field.field_key]) }}
                    {{ field.unit }}
                  </span>
                </div>

                <div class="flex items-center gap-1.5 shrink-0">
                  <input
                    v-model="areaFrom"
                    type="date"
                    class="rounded border border-gray-300 px-1.5 py-0.5 text-xs dark:border-gray-600 dark:bg-gray-800 dark:text-white focus:outline-none focus:ring-1 focus:ring-primary-500"
                  />
                  <span class="text-gray-400 text-xs">—</span>
                  <input
                    v-model="areaTo"
                    type="date"
                    class="rounded border border-gray-300 px-1.5 py-0.5 text-xs dark:border-gray-600 dark:bg-gray-800 dark:text-white focus:outline-none focus:ring-1 focus:ring-primary-500"
                  />
                  <button
                    type="button"
                    class="rounded bg-primary-600 px-2 py-0.5 text-xs font-medium text-white hover:bg-primary-700 focus:outline-none dark:bg-primary-500 dark:hover:bg-primary-600"
                    :disabled="areaLoading"
                    @click="loadAreaData"
                  >
                    {{ t('Apply') }}
                  </button>
                </div>
              </div>
            </div>
            <AddonApexcharts v-if="areaCustomers" v-bind="areaCustomers" />
          </BaseCard>
        </div>

        <!-- 4. Historical Chart -->
        <div class="cardBox col-span-12">
          <BaseCard class="p-6">
            <div class="mb-3 flex flex-wrap items-center justify-between gap-2">
              <BaseHeading as="h4" size="md" weight="semibold">
                <p
                  class="chart_title text-lg font-semibold text-gray-700 dark:text-gray-300"
                >
                  📊 4. {{ t('Historical data chart') }}
                </p>
              </BaseHeading>

              <div class="flex items-center gap-1.5 shrink-0">
                <input
                  v-model="historyFrom"
                  type="date"
                  class="rounded border border-gray-300 px-1.5 py-0.5 text-xs dark:border-gray-600 dark:bg-gray-800 dark:text-white focus:outline-none focus:ring-1 focus:ring-primary-500"
                />
                <span class="text-gray-400 text-xs">—</span>
                <input
                  v-model="historyTo"
                  type="date"
                  class="rounded border border-gray-300 px-1.5 py-0.5 text-xs dark:border-gray-600 dark:bg-gray-800 dark:text-white focus:outline-none focus:ring-1 focus:ring-primary-500"
                />
                <button
                  type="button"
                  class="rounded bg-primary-600 px-2 py-0.5 text-xs font-medium text-white hover:bg-primary-700 focus:outline-none dark:bg-primary-500 dark:hover:bg-primary-600"
                  :disabled="historyLoading"
                  @click="loadHistoryData"
                >
                  {{ t('Apply') }}
                </button>
              </div>
            </div>
            <AddonApexcharts v-if="chartConfig" v-bind="chartConfig" />
          </BaseCard>
        </div>

        <!-- Statistics Section -->
        <div class="cardBox col-span-12">
          <BaseCard class="p-6">
            <BaseHeading as="h4" size="md" weight="semibold" class="mb-6">
              {{ t('Statistics') }}
            </BaseHeading>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <div
                v-for="field in customFields.filter(
                  (f) => f.field_key !== 'timestamp',
                )"
                :key="field.field_key"
                class="space-y-3"
              >
                <div class="flex items-center gap-3 mb-3">
                  <Icon
                    :name="getFieldIcon(field.field_key).icon"
                    :class="`text-${
                      getFieldIcon(field.field_key).color
                    }-500 size-6`"
                  />
                  <BaseHeading
                    as="h5"
                    size="sm"
                    weight="medium"
                    class="text-muted-700 dark:text-muted-200"
                  >
                    {{ field.field_name_mn }}
                  </BaseHeading>
                </div>
                <div class="space-y-2">
                  <div class="flex justify-between items-center">
                    <span class="text-muted-500 text-sm">{{
                      t('Current')
                    }}</span>
                    <span
                      class="text-muted-800 dark:text-muted-100 font-semibold"
                    >
                      {{ getFieldStats(field.field_key).current || '-' }}
                      <span class="text-xs ml-1">{{ field.unit }}</span>
                    </span>
                  </div>
                  <div class="flex justify-between items-center">
                    <span class="text-muted-500 text-sm">{{
                      t('Average')
                    }}</span>
                    <span class="text-muted-700 dark:text-muted-300">
                      {{ getFieldStats(field.field_key).avg || '-' }}
                      <span class="text-xs ml-1">{{ field.unit }}</span>
                    </span>
                  </div>
                  <div class="flex justify-between items-center">
                    <span class="text-muted-500 text-sm">{{
                      t('Minimum')
                    }}</span>
                    <span class="text-success-600 dark:text-success-400">
                      {{ getFieldStats(field.field_key).min || '-' }}
                      <span class="text-xs ml-1">{{ field.unit }}</span>
                    </span>
                  </div>
                  <div class="flex justify-between items-center">
                    <span class="text-muted-500 text-sm">{{
                      t('Maximum')
                    }}</span>
                    <span class="text-danger-600 dark:text-danger-400">
                      {{ getFieldStats(field.field_key).max || '-' }}
                      <span class="text-xs ml-1">{{ field.unit }}</span>
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </BaseCard>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.own-monitoring {
  width: 100%;
}

/* Карт бүрийг "3D" маягаар, гүн харагдахуйц сүүдэртэй, hover хийхэд дээш
   өргөгддөг болгоно (tab1.vue-ийн .cardBox-той адил). `:deep()` ашигласан
   нь BaseCard-ийн дотор бэлдсэн `.nui-card` root div рүү (child component-
   ийн markup тул) style нэвтрүүлэхийн тулд. */
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
