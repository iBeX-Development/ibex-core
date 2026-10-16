<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import { AgGridVue } from 'ag-grid-vue3'
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import * as XLSX from 'xlsx'
import AssetOwnLiveDataColumnHeader from './AssetOwnLiveDataColumnHeader.vue'

ModuleRegistry.registerModules([ClientSideRowModelModule])

const { t } = useI18n({ useScope: 'global' })
const { getItems, updateItem, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()

const props = defineProps<{
  assetId: number | string | null
}>()

const loadingSensors = ref(true)
const loadingReadings = ref(true)
const assignedSensors = ref<any[]>([])
const readings = ref<any[]>([])
const isPickerOpen = ref(false)
const pickedSensor = ref(null)
const readingsPerPage = ref(25)
const totalReadings = ref(0)
const totalAllReadings = ref(0)
const fromDate = ref('')
const toDate = ref('')

// SmartGPS зэрэг шинэ integration-ууд Sensor_reading.json_data-д багц
// (нэг бүхэл JSON) payload оруулдаг — доор мэдэгдэж буй GPS талбаруудад
// монгол нэр/нэгж заана, мэдэгдээгүй (шинэ) талбар бол түлхүүрээс нь
// автоматаар нэр гаргана — json_data доторх БҮХ талбарыг харуулна
const GPS_FIELD_LABELS: Record<string, { label: string; unit: string }> = {
  speed: { label: 'Хурд', unit: 'км/ц' },
  movement_status: { label: 'Хөдөлгөөн', unit: '' },
  fuel_level: { label: 'Түлш', unit: '%' },
  odometer_km: { label: 'Гүйлт', unit: 'км' },
  engine_hours_h: { label: 'Мотор цаг', unit: 'ц' },
  battery_voltage: { label: 'Батарей', unit: 'V' },
  voltage: { label: 'Хүчдэл', unit: 'V' },
  temperature: { label: 'Температур', unit: '°C' },
  temperature_2: { label: 'Температур 2', unit: '°C' },
  gps_signal: { label: 'GPS сигнал', unit: '' },
  brk_max: { label: 'Тоормос (max)', unit: 'g' },
  accel_max: { label: 'Хурдасгал (max)', unit: 'g' },
  ignition: { label: 'Асаалт', unit: '' },
  lat: { label: 'Өргөрөг', unit: '' },
  lon: { label: 'Уртраг', unit: '' },
  gpstime: { label: 'GPS цаг', unit: '' },
  trackingTime: { label: 'Мөшгөлтийн цаг', unit: '' },
  last_message_ago_seconds: { label: 'Сүүлийн мессежээс хойш', unit: 'сек' },
  imei: { label: 'IMEI', unit: '' },
  plate: { label: 'Улсын дугаар', unit: '' },
  name: { label: 'Нэр', unit: '' },
}

interface DynamicColumn {
  key: string
  label: string
  unit: string
  source: 'top' | 'sensors'
}

// Ирсэн бичлэгүүдийн json_data доторх БҮХ талбарыг (утга нь хоосон/null ч
// хамаагүй) баганад оруулна — зөвхөн `sensors` nested объектыг өөрийг нь
// (доторх талбарууд тусдаа sensors.* багана болно) болон бусад
// объект/массив төрлийн утгыг (өөр мөрөнд нь бодит утгаараа гарч ирж болно
// тул түлхүүр давхцсан бол алгасна) орхино. Жагсаалт болон excel экспорт
// хоёуланд нь ашиглана.
const buildDynamicColumns = (rows: any[]): DynamicColumn[] => {
  const columns: DynamicColumn[] = []
  const seenKeys = new Set<string>()

  const humanize = (key: string) => key.replace(/^s_/, '').replace(/_/g, ' ')

  for (const reading of rows) {
    const data = reading.json_data
    if (!data || typeof data !== 'object') continue

    for (const [key, value] of Object.entries(data)) {
      if (key === 'sensors' || seenKeys.has(key)) continue
      if (value !== null && typeof value === 'object') continue // nested объект (жишээ profile_fields)

      seenKeys.add(key)
      const known = GPS_FIELD_LABELS[key]
      columns.push({
        key,
        label: known?.label || humanize(key),
        unit: known?.unit || '',
        source: 'top',
      })
    }

    if (data.sensors && typeof data.sensors === 'object') {
      for (const [key, value] of Object.entries(data.sensors)) {
        const colKey = `sensors.${key}`
        if (seenKeys.has(colKey)) continue
        if (value !== null && typeof value === 'object') continue

        seenKeys.add(colKey)
        columns.push({
          key: colKey,
          label: humanize(key),
          unit: '',
          source: 'sensors',
        })
      }
    }
  }

  return columns
}

// Одоо ачаалагдсан хуудасны бичлэгүүдээс json_data агуулсан эсэхийг олно
const hasJsonData = computed(() => readings.value.some((r) => r.json_data))
const rawDynamicColumns = computed<DynamicColumn[]>(() =>
  hasJsonData.value ? buildDynamicColumns(readings.value) : [],
)

// ── Баганын байрлал хадгалах ──────────────────────────────────────────────
// columnDefs нь readings шинэчлэгдэх бүрд шинэ array/object-оор дахин
// үүсдэг тул ag-grid-д "багана өөрчлөгдлөө" гэж харагдаад анхны дараалал
// руугаа буцдаг байсан — тиймээс эрэмбийг ag-grid-ийн API-аар дараа нь
// сэргээхийн оронд, colDefs-ийг ҮҮСГЭХ мөчид нь шууд хадгалсан дараалалтай
// нь тааруулж угаас нь эрэмбэлнэ (race condition-гүй, найдвартай)
const columnOrderStorageKey = computed(
  () => `liveDataColumnOrder_${props.assetId}_${activeSensorTab.value}`,
)

const getSavedColumnOrder = (): string[] => {
  if (typeof window === 'undefined') return []
  try {
    const raw = window.localStorage.getItem(columnOrderStorageKey.value)
    const parsed = raw ? JSON.parse(raw) : []
    return Array.isArray(parsed) ? parsed : []
  } catch (_e) {
    return []
  }
}

const dynamicColumns = computed<DynamicColumn[]>(() => {
  const cols = rawDynamicColumns.value
  const savedOrder = getSavedColumnOrder()
  if (!savedOrder.length) return cols

  const byKey = new Map(cols.map((c) => [c.key, c]))
  const ordered: DynamicColumn[] = []
  for (const key of savedOrder) {
    const col = byKey.get(key)
    if (col) {
      ordered.push(col)
      byKey.delete(key)
    }
  }
  // хадгалагдсаны дараа шинээр нэмэгдсэн (order-д ороогүй) баганууд төгсгөлд орно
  return [...ordered, ...byKey.values()]
})

const gridApi = ref<any>(null)

const saveColumnOrder = () => {
  if (!gridApi.value || typeof window === 'undefined') return
  try {
    const order = gridApi.value
      .getColumnState()
      .map((s: any) => s.colId as string)
      .filter((id: string) => id.startsWith('json_data.'))
      .map((id: string) => id.slice('json_data.'.length))
    window.localStorage.setItem(
      columnOrderStorageKey.value,
      JSON.stringify(order),
    )
  } catch (_e) {}
}

// ── Толгой дээрх давхар хэвтээ scroll ─────────────────────────────────────
// Хулганаар ажиллах үед доош бүхэлд нь очиж scroll хийхээс сэргийлэхийн
// тулд, доод (жинхэнэ) хэвтээ scroll-той синхрон "phantom" scrollbar-ыг
// толгойн яг дээр харуулна — ag-grid-ийн бодит агуулгын өргөнийг
// ResizeObserver-оор ажиглаад, хоёр scrollbar-ыг хооронд нь холбоно
const topScrollRef = ref<HTMLElement | null>(null)
const bottomScrollRef = ref<HTMLElement | null>(null)
const gridInnerRef = ref<HTMLElement | null>(null)
const gridContentWidth = ref(0)
let widthObserver: ResizeObserver | null = null
let isSyncingScroll = false

const setupWidthObserver = () => {
  if (typeof window === 'undefined' || !gridInnerRef.value) return
  widthObserver?.disconnect()
  widthObserver = new ResizeObserver((entries) => {
    for (const entry of entries) {
      gridContentWidth.value = entry.contentRect.width
    }
  })
  widthObserver.observe(gridInnerRef.value)
}

// ag-grid өөрөө suppress-horizontal-scroll=true үед container-аасаа гарч
// (overflow хийж) өргөсдөггүй — багана дутуу орсон хэсгээ дотроо тасалж
// үзүүлдэг (scroll хийх зүйлгүй тул дээрх phantom scrollbar ч харагдахгүй
// болдог шалтгаан). Тиймээс баганын бодит нийт өргөнийг API-аар тооцоод,
// gridInnerRef-д шууд style="width" болгож өгснөөр бодит overflow үүсгэж,
// гадна bottomScrollRef/topScrollRef-ийн scroll ажиллах боломжтой болно.
const gridTotalWidth = ref(0)
const updateGridTotalWidth = () => {
  if (!gridApi.value) return
  const cols = gridApi.value.getAllDisplayedColumns?.() ?? []
  const total = cols.reduce(
    (sum: number, col: any) => sum + col.getActualWidth(),
    0,
  )
  gridTotalWidth.value = total
}

const handleTopScroll = () => {
  if (isSyncingScroll || !topScrollRef.value || !bottomScrollRef.value) return
  isSyncingScroll = true
  bottomScrollRef.value.scrollLeft = topScrollRef.value.scrollLeft
  isSyncingScroll = false
}

const handleBottomScroll = () => {
  if (isSyncingScroll || !topScrollRef.value || !bottomScrollRef.value) return
  isSyncingScroll = true
  topScrollRef.value.scrollLeft = bottomScrollRef.value.scrollLeft
  isSyncingScroll = false
}

// Column header дээр хулганы дугуйгаар хөндлөн scroll хийх боломж (шат
// шатлан доош гулсаад бодит scrollbar руу очих шаардлагагүй) — зөвхөн
// header дээр хулгана байхад л ажиллана, мөр/эсийн дээр байвал ердийн
// босоо scroll хэвээр үлдэнэ
const handleHeaderWheel = (event: WheelEvent) => {
  const headerEl = (event.target as HTMLElement).closest?.('.ag-header')
  if (!headerEl || !bottomScrollRef.value) return
  event.preventDefault()
  const delta = Math.abs(event.deltaX) > Math.abs(event.deltaY)
    ? event.deltaX
    : event.deltaY
  bottomScrollRef.value.scrollLeft += delta
}

onUnmounted(() => widthObserver?.disconnect())

const onGridReady = (params: any) => {
  gridApi.value = params.api
  nextTick(setupWidthObserver)
}

const onFirstDataRendered = () => {
  nextTick(updateGridTotalWidth)
}

const onColumnMoved = (event: any) => {
  if (event.finished) saveColumnOrder()
}

const onColumnResized = (event: any) => {
  if (event.finished) updateGridTotalWidth()
}

// Sensors.* багана дотоод key нь "sensors." угтвартай (жишээ нь
// "sensors.s_speed") — Device_tracking_fields.field_key рүү бичихдээ угтвар
// хассан бодит нэрийг (жишээ нь "s_speed") ашиглана
const getDeviceTrackingFieldKey = (column: DynamicColumn) =>
  column.source === 'sensors' ? column.key.slice(8) : column.key

// Энэ asset дээр Device_tracking_fields-д is_mode='livedata'-аар аль хэдийн
// бүртгэгдсэн талбаруудын is_show төлөв — switch-ийн анхны утга үүнээс
// тодорхойлогдоно. is_mode='rawdata' (Asset_field_data_json-той холбоотой)
// талбарыг энд оруулахгүй — ижил field_key (жишээ нь "speed") хоёр эх
// сурвалжид давхцаж болох тул LiveData/Raw data-г холихгүй байхын тулд.
// "code" баганад тухайн sensor-ын device_id-г хадгална — 2 sensor ижил
// field_key (жишээ нь "speed") үүсгэвэл code (device_id)-аар нь ялгаж,
// sensor тус бүр өөрийн ТУСДАА мөр/тохиргоотой байна.
// Бүртгэгдээгүй (шинэ) талбар бол анхныхаараа OFF (is_show=0/байхгүй) байна.
const deviceTrackingFields = ref<any[]>([])
const loadDeviceTrackingFieldsConfig = async () => {
  if (!props.assetId) return
  try {
    const response = await getItems<any>({
      collection: 'Device_tracking_fields',
      params: {
        filter: {
          asset: { _eq: props.assetId },
          is_mode: { _eq: 'livedata' },
        },
        fields: ['id', 'field_key', 'code', 'is_show'],
        limit: -1,
      },
    })
    deviceTrackingFields.value = Array.isArray(response)
      ? response
      : (response as any)?.data ?? []
  } catch (error) {
    console.error('Unable to load Device_tracking_fields config:', error)
    deviceTrackingFields.value = []
  }
}

const isColumnVisible = (column: DynamicColumn) => {
  const fieldKey = getDeviceTrackingFieldKey(column)
  const existing = deviceTrackingFields.value.find(
    (f: any) => f.field_key === fieldKey && f.code === activeSensorTab.value,
  )
  return existing?.is_show === 1
}

// Switch дарахад Device_tracking_fields рүү шууд бичнэ: ON бол
// is_show=1 (мөр байхгүй бол шинээр, code=идэвхтэй sensor-ын device_id-тай
// үүсгэнэ), OFF бол is_show=0
const toggleColumn = async (column: DynamicColumn) => {
  if (!props.assetId || !activeSensorTab.value) return
  const fieldKey = getDeviceTrackingFieldKey(column)
  const deviceId = activeSensorTab.value
  const existing = deviceTrackingFields.value.find(
    (f: any) => f.field_key === fieldKey && f.code === deviceId,
  )
  const newValue = existing?.is_show === 1 ? 0 : 1

  try {
    if (existing) {
      await updateItem({
        collection: 'Device_tracking_fields',
        id: existing.id,
        item: { is_show: newValue },
      })
      existing.is_show = newValue
    } else {
      const created = await createItems({
        collection: 'Device_tracking_fields',
        items: [
          {
            asset: parseInt(String(props.assetId)),
            field_key: fieldKey,
            field_name_mn: column.label,
            field_name_en: column.label,
            unit: column.unit,
            is_active: true,
            is_show: newValue,
            company_id: myCompanyId,
            is_mode: 'livedata',
            code: deviceId,
          },
        ],
      })
      const createdItem = Array.isArray(created)
        ? created[0]
        : (created as any)?.data?.[0]
      deviceTrackingFields.value.push({
        id: createdItem?.id,
        field_key: fieldKey,
        code: deviceId,
        is_show: newValue,
      })
    }
  } catch (error) {
    console.error('Unable to update is_show for field:', fieldKey, error)
  }
}

const getDynamicValue = (reading: any, column: DynamicColumn) => {
  const data = reading.json_data
  if (!data) return '-'
  const raw =
    column.source === 'sensors'
      ? data.sensors?.[column.key.slice(8)]
      : data[column.key]
  if (raw === null || raw === undefined || raw === '') return '-'
  if (typeof raw === 'boolean') return raw ? 'Тийм' : 'Үгүй'
  return raw
}

// ag-grid-ийн багана тодорхойлолт (dynamic JSON эсвэл legacy WISE загвар).
// Dynamic багана бүр `AssetOwnLiveDataColumnHeader`-ээр "Show in charts"
// switch-ийг толгойдоо шууд харуулна (deviceTrackingFields/activeSensorTab
// солигдох бүрд ижил ref-үүдийг уншдаг тул автоматаар reactive шинэчлэгдэнэ)
const columnDefs = computed(() => {
  if (!hasJsonData.value) {
    return [
      { headerName: t('Device'), field: 'device_id', minWidth: 120 },
      {
        headerName: t('Temperature'),
        field: 'temperature',
        valueFormatter: (p: any) =>
          p.value === null || p.value === undefined || p.value === ''
            ? '-'
            : `${p.value}${p.data?.temperature_unit || ''}`,
      },
      {
        headerName: t('Vibration X'),
        field: 'vibration_x',
        valueFormatter: (p: any) =>
          p.value === null || p.value === undefined || p.value === ''
            ? '-'
            : `${p.value}${p.data?.vibration_unit || ''}`,
      },
      {
        headerName: t('Vibration Y'),
        field: 'vibration_y',
        valueFormatter: (p: any) =>
          p.value === null || p.value === undefined || p.value === ''
            ? '-'
            : `${p.value}${p.data?.vibration_unit || ''}`,
      },
      {
        headerName: t('Vibration Z'),
        field: 'vibration_z',
        valueFormatter: (p: any) =>
          p.value === null || p.value === undefined || p.value === ''
            ? '-'
            : `${p.value}${p.data?.vibration_unit || ''}`,
      },
      {
        headerName: t('Time'),
        field: 'date_created',
        valueFormatter: (p: any) => formatDate(p.value),
        minWidth: 160,
      },
    ]
  }

  const dynamicDefs = dynamicColumns.value.map((column) => ({
    headerName: column.label,
    field: `json_data.${column.key}`,
    minWidth: 150,
    headerComponent: AssetOwnLiveDataColumnHeader,
    headerComponentParams: {
      label: column.label,
      isVisible: () => isColumnVisible(column),
      onToggle: () => toggleColumn(column),
    },
    valueFormatter: (p: any) => {
      const raw = p.value
      if (raw === null || raw === undefined || raw === '') return '-'
      if (typeof raw === 'boolean') return raw ? 'Тийм' : 'Үгүй'
      return `${raw}${column.unit}`
    },
  }))

  return [
    {
      headerName: t('Device'),
      field: 'device_id',
      minWidth: 120,
      pinned: 'left',
    },
    ...dynamicDefs,
    {
      headerName: t('Time'),
      field: 'date_created',
      valueFormatter: (p: any) => formatDate(p.value),
      minWidth: 160,
    },
  ]
})

watch(columnDefs, () => nextTick(updateGridTotalWidth))

const defaultColDef = {
  sortable: true,
  filter: false,
  resizable: true,
  suppressHeaderMenuButton: true,
}

// Холбогдсон sensor тус бүрийг tab болгож, идэвхтэй tab-ын device_id-аар нь
// доорх "Recent readings" хүснэгтийг тусад нь шүүнэ (sensor-ууд хоорондоо
// холилдохгүй)
const activeSensorTab = ref<string | null>(null)
const sensorTabs = computed(() =>
  assignedSensors.value
    .filter((s) => s.device_id)
    .map((s) => ({
      key: s.device_id as string,
      label: s.device_name || s.device_id,
    })),
)

const loadAssignedSensors = async () => {
  if (!props.assetId) return
  loadingSensors.value = true
  try {
    const result = await getItems({
      collection: 'Sensors',
      params: {
        filter: { asset: { _eq: props.assetId } },
        fields: [
          'id',
          'device_name',
          'device_id',
          'device_type',
          'connection_status',
          'vibration_status',
          'temperature_status',
          'battery_status',
        ],
        limit: -1,
      },
    })
    assignedSensors.value = Array.isArray(result)
      ? result
      : (result as any)?.data ?? []

    // Идэвхтэй tab тохируулаагүй, эсвэл салгасан sensor руу заасан бол
    // эхний холбогдсон sensor руу шилжинэ
    const validKeys = new Set(sensorTabs.value.map((t) => t.key))
    if (!activeSensorTab.value || !validKeys.has(activeSensorTab.value)) {
      activeSensorTab.value = sensorTabs.value[0]?.key ?? null
    }
  } catch (error) {
    console.error('Unable to load assigned sensors:', error)
    assignedSensors.value = []
  } finally {
    loadingSensors.value = false
  }
}

const loadReadings = async () => {
  if (!activeSensorTab.value) {
    readings.value = []
    totalReadings.value = 0
    totalAllReadings.value = 0
    loadingReadings.value = false
    return
  }
  loadingReadings.value = true
  try {
    const baseFilter: Record<string, any> = {
      device_id: { _eq: activeSensorTab.value },
    }
    const filter: Record<string, any> = { ...baseFilter }
    if (fromDate.value || toDate.value) {
      filter.date_created = {}
      if (fromDate.value)
        filter.date_created._gte = `${fromDate.value}T00:00:00`
      if (toDate.value) filter.date_created._lte = `${toDate.value}T23:59:59`
    }

    const [result, totalResult] = await Promise.all([
      getItems({
        collection: 'Sensor_reading',
        params: {
          filter,
          sort: ['-date_created'],
          limit: -1,
          fields: [
            'id',
            'device_type',
            'device_id',
            'temperature',
            'temperature_unit',
            'vibration_x',
            'vibration_y',
            'vibration_z',
            'vibration_unit',
            'json_data',
            'date_created',
          ],
        },
      }),
      // Огнооны шүүлтгүй, зөвхөн энэ asset-ийн sensor-уудын НИЙТ тоо
      // (шүүлт бодитоор ажиллаж байгааг харьцуулж баталгаажуулахад хэрэгтэй)
      getItems({
        collection: 'Sensor_reading',
        params: {
          filter: baseFilter,
          limit: 0,
          meta: 'filter_count',
        },
      }),
    ])

    readings.value = Array.isArray(result)
      ? result
      : (result as any)?.data ?? []
    totalReadings.value = readings.value.length
    totalAllReadings.value = Array.isArray(totalResult)
      ? totalResult.length
      : (totalResult as any)?.meta?.filter_count ?? 0

    // ag-grid-ийн built-in pager-ийг эхний хуудас руу буцаана
    gridApi.value?.paginationGoToFirstPage()
  } catch (error) {
    console.error('Unable to load sensor readings:', error)
    readings.value = []
    totalReadings.value = 0
    totalAllReadings.value = 0
  } finally {
    loadingReadings.value = false
  }
}

// Sensor tab солигдоход дахин ачаална
watch(activeSensorTab, loadReadings)

const applyDateFilter = () => {
  loadReadings()
}

const clearDateFilter = () => {
  fromDate.value = ''
  toDate.value = ''
  applyDateFilter()
}

const refreshAll = async () => {
  await Promise.all([loadAssignedSensors(), loadDeviceTrackingFieldsConfig()])
  await loadReadings()
}

const isExporting = ref(false)

const exportToExcel = async () => {
  if (!activeSensorTab.value) {
    toaster.show({
      title: t('Error'),
      message: t('No sensor data yet'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  isExporting.value = true
  try {
    // Одоогийн огнооны шүүлтийг хадгалж, хуудаслалтгүй (бүх мөр) татна
    const filter: Record<string, any> = {
      device_id: { _eq: activeSensorTab.value },
    }
    if (fromDate.value || toDate.value) {
      filter.date_created = {}
      if (fromDate.value)
        filter.date_created._gte = `${fromDate.value}T00:00:00`
      if (toDate.value) filter.date_created._lte = `${toDate.value}T23:59:59`
    }

    const result = await getItems({
      collection: 'Sensor_reading',
      params: {
        filter,
        sort: ['-date_created'],
        limit: -1,
        fields: [
          'device_type',
          'device_id',
          'temperature',
          'temperature_unit',
          'vibration_x',
          'vibration_y',
          'vibration_z',
          'vibration_unit',
          'json_data',
          'date_created',
        ],
      },
    })
    const rows = Array.isArray(result) ? result : (result as any)?.data ?? []

    if (!rows.length) {
      toaster.show({
        title: t('Error'),
        message: t('No sensor data yet'),
        color: 'danger',
        icon: 'ph:warning-circle-fill',
        closable: true,
      })
      return
    }

    const exportHasJsonData = rows.some((r: any) => r.json_data)
    const exportColumns = exportHasJsonData ? buildDynamicColumns(rows) : []

    const exportData = rows.map((reading: any) => {
      if (exportHasJsonData) {
        const row: Record<string, any> = {
          [t('Device')]: reading.device_id,
          [t('Time')]: formatDate(reading.date_created),
        }
        for (const column of exportColumns) {
          row[column.label] = getDynamicValue(reading, column)
        }
        return row
      }
      return {
        [t('Device')]: reading.device_id,
        [t('Temperature')]: reading.temperature,
        [t('Vibration X')]: reading.vibration_x,
        [t('Vibration Y')]: reading.vibration_y,
        [t('Vibration Z')]: reading.vibration_z,
        [t('Time')]: formatDate(reading.date_created),
      }
    })

    const worksheet = XLSX.utils.json_to_sheet(exportData)
    const workbook = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Sensor Readings')

    const fileName = `sensor_readings_${props.assetId}_${
      new Date().toISOString().split('T')[0]
    }.xlsx`
    XLSX.writeFile(workbook, fileName)
  } catch (error) {
    console.error('Unable to export sensor readings:', error)
  } finally {
    isExporting.value = false
  }
}

const assignSensor = async (sensor: any) => {
  if (!sensor?.id || !props.assetId) return
  try {
    await updateItem({
      collection: 'Sensors',
      id: sensor.id,
      item: { asset: props.assetId },
    })
    pickedSensor.value = null
    isPickerOpen.value = false
    toaster.show({
      title: t('Added'),
      message: t('Sensor connected to this asset') + '!',
      color: 'success',
      icon: 'ph:check-circle-fill',
      closable: true,
    })
    await refreshAll()
  } catch (error) {
    console.error('Unable to assign sensor:', error)
  }
}

const unassignSensor = async (sensor: any) => {
  try {
    await updateItem({
      collection: 'Sensors',
      id: sensor.id,
      item: { asset: null },
    })

    // Тухайн sensor-той холбоотой Settings-ийн (is_mode='livedata',
    // code=device_id) талбаруудыг мөн устгана — эс тэгвэл asset салгасны
    // дараа ч хогорсон тохиргоо Settings/Alert хэсэгт үлдэж хоцордог байсан
    if (props.assetId && sensor.device_id) {
      try {
        const staleFields = await getItems<any>({
          collection: 'Device_tracking_fields',
          params: {
            filter: {
              asset: { _eq: props.assetId },
              is_mode: { _eq: 'livedata' },
              code: { _eq: sensor.device_id },
            },
            fields: ['id'],
            limit: -1,
          },
        })
        const rows = Array.isArray(staleFields)
          ? staleFields
          : (staleFields as any)?.data ?? []
        if (rows.length) {
          await deleteItems({
            collection: 'Device_tracking_fields',
            items: rows.map((r: any) => String(r.id)),
          })
        }

        //   const rows = Array.isArray(staleFields)
        //   ? staleFields
        //   : (staleFields as any)?.data ?? []
        // if (rows.length) {
        //   await Promise.all(
        //     rows.map((r: any) =>
        //       updateItem({
        //         collection: 'Device_tracking_fields',
        //         id: String(r.id),
        //         item: { is_show: 0 },
        //       }),
        //     ),
        //   )
        // }
      } catch (error) {
        console.error('Unable to remove stale tracking fields:', error)
      }
    }

    await refreshAll()
  } catch (error) {
    console.error('Unable to unassign sensor:', error)
  }
}

const formatDate = (value: string) => {
  if (!value) return '-'
  const d = new Date(value)
  if (isNaN(d.getTime())) return value
  return d.toLocaleString()
}

const statusColor = (value: string) => {
  if (!value) return 'text-muted-400'
  const v = value.toLowerCase()
  if (['online', 'normal', 'good'].includes(v)) return 'text-success-500'
  if (['offline', 'critical', 'low'].includes(v)) return 'text-danger-500'
  return 'text-warning-500'
}

onMounted(refreshAll)
</script>

<template>
  <div class="live-data">
    <!-- Холбогдсон мэдрэгчид -->
    <div class="mb-6">
      <div class="mb-3 flex items-center justify-between">
        <BaseHeading
          as="h4"
          size="sm"
          weight="medium"
          class="text-muted-800 dark:text-white"
        >
          {{ t('Connected sensors') }}
        </BaseHeading>
        <BaseButton
          size="sm"
          color="primary"
          @click="isPickerOpen = !isPickerOpen"
        >
          <Icon name="ph:plus-bold" class="me-1 h-3 w-3" />
          {{ t('Add sensor') }}
        </BaseButton>
      </div>

      <div v-if="isPickerOpen" class="mb-3">
        <FormKit
          name="sensor_picker"
          type="autocomplete2"
          collection_name="Sensors"
          :label="''"
          item_value="id"
          item_title="device_name"
          search_field="device_name"
          :placeholder="t('Choose a sensor')"
          :value="pickedSensor"
          :initial_filter="{ company_id: myCompanyId }"
          :setParentValue="assignSensor"
        />
      </div>

      <div v-if="loadingSensors" class="text-muted-400 text-sm">
        {{ t('Loading') }}...
      </div>
      <div v-else-if="!assignedSensors.length" class="text-muted-400 text-sm">
        {{ t('No sensors connected to this asset yet') }}
      </div>
      <div v-else class="flex flex-wrap gap-2">
        <div
          v-for="sensor in assignedSensors"
          :key="sensor.id"
          class="border-muted-200 dark:border-muted-700 flex items-center gap-3 rounded-lg border px-3 py-2"
        >
          <div>
            <div class="text-muted-800 text-sm font-medium dark:text-white">
              {{ sensor.device_name || sensor.device_id }}
            </div>
            <div class="text-muted-400 flex gap-2 text-xs">
              <span :class="statusColor(sensor.connection_status)">
                {{ sensor.connection_status || t('unknown') }}
              </span>
              <span
                v-if="sensor.temperature_status"
                :class="statusColor(sensor.temperature_status)"
              >
                {{ sensor.temperature_status }}
              </span>
              <span
                v-if="sensor.vibration_status"
                :class="statusColor(sensor.vibration_status)"
              >
                {{ sensor.vibration_status }}
              </span>
            </div>
          </div>
          <button
            type="button"
            class="text-muted-400 hover:text-danger-500"
            :title="t('Disconnect')"
            @click="unassignSensor(sensor)"
          >
            <Icon name="ph:x-bold" class="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- Live data table -->
    <div>
      <!-- Sensor tabs: холбогдсон sensor тус бүр -->
      <div
        v-if="sensorTabs.length > 1"
        class="flex flex-wrap items-center gap-2 mb-4"
      >
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

      <div class="mb-3 flex items-center justify-between">
        <BaseHeading
          as="h4"
          size="sm"
          weight="medium"
          class="text-muted-800 dark:text-white"
        >
          {{ t('') }}
        </BaseHeading>
        <span class="text-muted-400 text-xs">
          {{ t('Showing') }} {{ totalReadings }} / {{ totalAllReadings }}
          {{ t('total') }}
        </span>
      </div>

      <div class="mb-3 flex flex-wrap items-end gap-2">
        <div>
          <label class="text-muted-400 mb-1 block text-xs">{{
            t('From')
          }}</label>
          <input
            v-model="fromDate"
            type="date"
            class="nui-focus border-muted-300 dark:border-muted-700 dark:bg-muted-900 rounded border px-2 py-1 text-sm"
          />
        </div>
        <div>
          <label class="text-muted-400 mb-1 block text-xs">{{ t('To') }}</label>
          <input
            v-model="toDate"
            type="date"
            class="nui-focus border-muted-300 dark:border-muted-700 dark:bg-muted-900 rounded border px-2 py-1 text-sm"
          />
        </div>
        <BaseButton size="sm" color="primary" @click="applyDateFilter">
          <Icon name="ph:funnel-bold" class="me-1 h-3 w-3" />
          {{ t('Filter') }}
        </BaseButton>
        <BaseButton
          v-if="fromDate || toDate"
          size="sm"
          color="muted"
          @click="clearDateFilter"
        >
          {{ t('Clear') }}
        </BaseButton>
        <BaseButton
          size="sm"
          color="muted"
          class="ms-auto"
          :loading="isExporting"
          :disabled="isExporting"
          @click="exportToExcel"
        >
          <Icon name="ph:download-simple-bold" class="me-1 h-3 w-3" />
          {{ t('Download Excel') }}
        </BaseButton>
      </div>

      <div v-if="loadingReadings" class="text-muted-400 text-sm">
        {{ t('Loading') }}...
      </div>
      <div v-else-if="!readings.length" class="text-muted-400 text-sm">
        {{ t('No sensor data yet') }}
      </div>
      <div v-else>
        <!-- Толгойн яг дээрх phantom хэвтээ scroll — доод scroll-той sync-тэй -->
        <div
          ref="topScrollRef"
          class="nui-slimscroll overflow-x-auto"
          style="height: 14px"
          @scroll="handleTopScroll"
        >
          <div :style="{ width: gridContentWidth + 'px', height: '1px' }" />
        </div>

        <div
          ref="bottomScrollRef"
          class="nui-slimscroll overflow-x-auto"
          @scroll="handleBottomScroll"
          @wheel="handleHeaderWheel"
        >
          <div
            ref="gridInnerRef"
            :style="{
              width: gridTotalWidth ? gridTotalWidth + 'px' : '100%',
              minWidth: '100%',
            }"
          >
            <ag-grid-vue
              :class="`ag-theme-quartz${
                $colorMode.value === 'light' ? '' : '-dark'
              }`"
              style="height: auto"
              dom-layout="autoHeight"
              :suppress-horizontal-scroll="true"
              :header-height="hasJsonData ? 64 : undefined"
              :column-defs="columnDefs"
              :default-col-def="defaultColDef"
              :row-data="readings"
              :pagination="true"
              :pagination-page-size="readingsPerPage"
              :suppress-cell-focus="true"
              @grid-ready="onGridReady"
              @first-data-rendered="onFirstDataRendered"
              @column-moved="onColumnMoved"
              @column-resized="onColumnResized"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
