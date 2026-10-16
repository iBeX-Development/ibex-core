<script setup lang="ts">
import { onMounted, ref, shallowRef } from 'vue'
import { useI18n } from 'vue-i18n'

interface FieldDataRecord {
  timestamp: string | number
  [key: string]: any
}

const props = defineProps({
  assetId: {
    type: Number,
    required: true,
  },
  fieldKey: {
    type: String,
    required: true,
  },
  fieldName: {
    type: String,
    default: 'Field Data',
  },
  unit: {
    type: String,
    default: 'Value',
  },
  from: String,
  to: String,
  // null/undefined = "raw" tab (зөвхөн Asset_field_data_json). Утга өгвөл
  // ЗӨВХӨН тухайн нэг sensor (device_id)-ийн Sensor_reading л ашиглана
  sensorDeviceId: {
    type: String,
    default: null,
  },
  // Энэ asset-д харьяалагдах бүх Sensors.device_id — Excel raw-ийн
  // "Device" утгыг аль tab-д харьяалуулахыг тодорхойлоход хэрэглэнэ
  sensorDeviceIds: {
    type: Array as () => string[],
    default: () => [],
  },
  // Threshold values
  value1: { type: Number, default: 0 },
  value2: { type: Number, default: 98 },
  value3: { type: Number, default: 110 },
  value4: { type: Number, default: 129 },
  value5: { type: Number, default: 132 },
})

const emit = defineEmits(['update:from', 'update:to'])

const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const loading = ref(true)
const error = ref<string | null>(null)
const chartConfig = shallowRef<any>(null)

const customFrom = ref(
  props.from ||
    new Date(new Date().setDate(new Date().getDate() - 15))
      .toISOString()
      .split('T')[0],
)
const customTo = ref(props.to || new Date().toISOString().split('T')[0])

const applyFilter = () => {
  emit('update:from', customFrom.value)
  emit('update:to', customTo.value)
  loadChartData()
}

// Хуучин WISE (flat DB багана) талбарууд — json_data-д таарах утга олдоогүй
// үед л fallback байдлаар ашиглана
const LEGACY_SENSOR_READING_COLUMNS = [
  'temperature',
  'vibration_x',
  'vibration_y',
  'vibration_z',
]
const normalizeFieldKey = (key: string): string =>
  String(key || '')
    .toLowerCase()
    .replace(/[^a-z0-9]/g, '')

// props.sensorDeviceId заасан үед ЗӨВХӨН тухайн ганц sensor-ын
// Sensor_reading-ийг л ашиглана (өөр sensor-той холилдохгүй). SmartGPS зэрэг
// шинэ integration-уудын хувьд json_data (top-level + sensors.*)-г
// props.fieldKey-ээр нь шууд тааруулна — WISE хэлбэрийн хувьд flat
// баганаас нь уншина
const loadSensorFieldData = async (): Promise<FieldDataRecord[]> => {
  if (!props.sensorDeviceId) return []

  try {
    const readingResponse = await getItems<any>({
      collection: 'Sensor_reading',
      params: {
        filter: {
          device_id: { _eq: props.sensorDeviceId },
          date_created: {
            _gte: `${customFrom.value}T00:00:00`,
            _lte: `${customTo.value}T23:59:59`,
          },
        },
        sort: ['date_created'],
        limit: 10000,
        fields: [
          'temperature',
          'vibration_x',
          'vibration_y',
          'vibration_z',
          'json_data',
          'date_created',
        ],
      },
    })
    const readingItems = Array.isArray(readingResponse)
      ? readingResponse
      : (readingResponse as any)?.data || []

    return readingItems
      .map((reading: any) => {
        const data = reading.json_data
        let value: any

        if (data && typeof data === 'object') {
          if (
            data[props.fieldKey] !== undefined &&
            data[props.fieldKey] !== null
          ) {
            value = data[props.fieldKey]
          } else if (
            data.sensors &&
            typeof data.sensors === 'object' &&
            data.sensors[props.fieldKey] !== undefined &&
            data.sensors[props.fieldKey] !== null
          ) {
            value = data.sensors[props.fieldKey]
          }
        }

        if (value === undefined) {
          const legacyColumn = LEGACY_SENSOR_READING_COLUMNS.find(
            (column) =>
              normalizeFieldKey(column) === normalizeFieldKey(props.fieldKey),
          )
          if (legacyColumn) value = reading[legacyColumn]
        }

        if (typeof value === 'boolean') value = value ? 1 : 0
        if (typeof value !== 'number') return null

        return {
          timestamp: reading.date_created,
          [props.fieldKey]: value,
        }
      })
      .filter((record: any): record is FieldDataRecord => record !== null)
  } catch (err) {
    console.warn('⚠️ Could not load sensor readings:', err)
    return []
  }
}

const loadChartData = async () => {
  if (!props.assetId) {
    error.value = 'Asset ID is required'
    return
  }

  try {
    loading.value = true
    error.value = null

    console.log(
      `📊 Loading field data for asset ${props.assetId}, field: ${
        props.fieldKey
      }, source: ${props.sensorDeviceId || 'raw'}`,
    )

    // Asset_field_data_json-оос бүгдийг татна — sensor tab дээр ч энэ дундаас
    // тухайн Device-тэй таарсан мөрийг олж, Sensor_reading-тэй нэгтгэнэ
    const allItems: any[] = (await getItems<any>({
      collection: 'Asset_field_data_json',
      params: {
        filter: {
          asset: { _eq: props.assetId },
          company_id: { _eq: myCompanyId },
        },
        sort: ['timestamp'],
        limit: 10000,
      },
    }).then((response: any) =>
      Array.isArray(response) ? response : response?.data || [],
    )) as any[]

    console.log(`✅ Fetched ${allItems.length} records`)

    // Helper: parse any timestamp format
    const parseTs = (ts: any): Date | null => {
      if (!ts) return null
      let d: Date
      if (typeof ts === 'number') {
        d = new Date(ts < 10000000000 ? ts * 1000 : ts)
      } else if (typeof ts === 'string') {
        const str = ts.trim()
        const num = Number(str)
        if (!isNaN(num) && str !== '') {
          d = new Date(num < 10000000000 ? num * 1000 : num)
        } else {
          // Normalize "2026.04.02 13:30:00" or "2026.04.02" (dots) → ISO
          const normalized = str
            .replace(/^(\d{4})\.(\d{2})\.(\d{2})/, '$1-$2-$3')
            .replace(' ', 'T')
          d = new Date(normalized)
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

    console.log(`📅 After date filter: ${items.length} records`)

    // Parse field_values (гараар/Excel-ээр импортолсон raw-data)
    const allManualFieldData: FieldDataRecord[] = items.map((item) => {
      const fieldValues =
        typeof item.field_values === 'string'
          ? JSON.parse(item.field_values)
          : item.field_values || {}
      return {
        timestamp: item.timestamp,
        ...fieldValues,
      }
    })

    // Excel raw-ийн "Device" утгыг мэдэгдэж буй Sensors.device_id-тэй
    // тааруулж, аль tab-д харьяалагдахыг тодорхойлно
    const knownDeviceIdsNormalized = new Set(
      props.sensorDeviceIds.map((d) => normalizeFieldKey(d)),
    )
    const matchDeviceId = (record: FieldDataRecord): string | null => {
      const rawDeviceValue =
        record.Device ?? record.device ?? record.Device_id ?? record.device_id
      if (!rawDeviceValue) return null
      const normalized = normalizeFieldKey(String(rawDeviceValue))
      return knownDeviceIdsNormalized.has(normalized) ? normalized : null
    }

    // Sensor tab дээр ЗӨВХӨН тухайн sensor-ын Sensor_reading — raw/manual
    // дататай ХОЛИХГҮЙ. "raw" tab дээр ямар ч sensor-той таарахгүй
    // (эсвэл Device утгагүй) manual бичлэгүүд
    const fieldData: FieldDataRecord[] = props.sensorDeviceId
      ? await loadSensorFieldData()
      : allManualFieldData.filter((record) => !matchDeviceId(record))

    console.log(
      `📈 Found ${fieldData.length} records with field "${
        props.fieldKey
      }" (source: ${props.sensorDeviceId || 'raw'})`,
    )

    if (fieldData.length === 0) {
      console.warn('No data found')
      buildChart([])
      return
    }

    buildChart(fieldData)
  } catch (err: any) {
    console.error('Error loading chart data:', err)
    error.value = err.message || 'Failed to load chart data'
    loading.value = false
  }
}

const buildChart = (data: FieldDataRecord[]) => {
  const { primary } = useTailwindColors()

  // Helper: parse timestamp to ms
  const tsToMs = (ts: any): number | null => {
    if (!ts) return null
    let ms: number
    if (typeof ts === 'number') {
      ms = ts < 10000000000 ? ts * 1000 : ts
    } else {
      const str = String(ts).trim()
      const num = Number(str)
      if (!isNaN(num) && str !== '') {
        ms = num < 10000000000 ? num * 1000 : num
      } else {
        // Normalize "2026.04.02 13:30:00" or "2026.04.02" (dots) → ISO format
        // Replace dots then space → T for strict ISO 8601
        const normalized = str
          .replace(/^(\d{4})\.(\d{2})\.(\d{2})/, '$1-$2-$3')
          .replace(' ', 'T')
        ms = new Date(normalized).getTime()
      }
    }
    return isNaN(ms) ? null : ms
  }

  // Build {x: timestamp_ms, y: value} series for datetime x-axis
  const seriesData = data
    .map((item) => {
      const ms = tsToMs(item.timestamp)
      const val = Number(item[props.fieldKey])
      return { x: ms, y: isNaN(val) ? 0 : val }
    })
    .filter((d) => d.x !== null) as { x: number; y: number }[]

  console.log(`📊 Chart data points: ${seriesData.length}`)

  // Build Y-axis threshold values
  const thresholdValues = [
    props.value1,
    props.value2,
    props.value3,
    props.value4,
    props.value5,
  ].filter((v) => v !== null && v !== undefined)

  // Get min and max from data and thresholds
  const fieldValues = seriesData.map((d) => d.y)
  const allValues = [...fieldValues, ...thresholdValues]
  const minValue = allValues.length ? Math.min(...allValues) : 0
  const maxValue = allValues.length ? Math.max(...allValues) : 100
  const padding = (maxValue - minValue) * 0.1

  // From/To timestamp boundaries for x-axis annotations
  const fromTs = new Date(`${customFrom.value}T00:00:00`).getTime()
  const toTs = new Date(`${customTo.value}T23:59:59`).getTime()

  const chartOptions = {
    chart: {
      toolbar: { show: true },
      zoom: { enabled: true },
    },
    colors: [primary.value],
    stroke: {
      width: 2.5,
      curve: 'smooth',
    },
    plotOptions: {
      line: {
        dataLabels: { enabled: false },
      },
    },
    xaxis: {
      type: 'datetime',
      min: fromTs,
      max: toTs,
      tickAmount: Math.round((toTs - fromTs) / (1000 * 60 * 60 * 24)),
      labels: {
        datetimeUTC: false,
        rotate: -45,
        hideOverlappingLabels: true,
        style: { fontSize: '11px' },
        datetimeFormatter: {
          year: 'yyyy',
          month: 'MMM yyyy',
          day: 'MMM dd',
          hour: 'MMM dd',
        },
      },
    },
    yaxis: {
      min: Math.floor(minValue - padding),
      max: Math.ceil(maxValue + padding),
      tickAmount: Math.max(5, thresholdValues.length + 2),
      title: {
        text: props.unit,
        style: {
          color: '#6b7280',
          fontSize: '14px',
        },
      },
      labels: {
        formatter: (val: number) => {
          if (thresholdValues.includes(Math.round(val))) {
            return `${Math.round(val)} ✓`
          }
          return val.toFixed(0)
        },
        style: {
          colors: '#6b7280',
          fontSize: '12px',
        },
      },
    },
    legend: {
      position: 'top',
      fontSize: 12,
    },
    dataLabels: {
      enabled: false,
    },
    tooltip: {
      shared: true,
      intersect: false,
      x: {
        format: 'yyyy/MM/dd HH:mm',
      },
      y: {
        formatter: (val: number | null) =>
          val == null ? '' : Number(val).toFixed(2),
      },
    },
    grid: {
      borderColor: '#e5e7eb',
      strokeDashArray: 3,
    },
    annotations: {
      xaxis: [
        {
          x: fromTs,
          borderColor: '#6366f1',
          strokeDashArray: 4,
          label: {
            borderColor: '#6366f1',
            style: { color: '#fff', background: '#6366f1', fontSize: '11px' },
            text: customFrom.value,
            orientation: 'horizontal',
          },
        },
        {
          x: toTs,
          borderColor: '#f43f5e',
          strokeDashArray: 4,
          label: {
            borderColor: '#f43f5e',
            style: { color: '#fff', background: '#f43f5e', fontSize: '11px' },
            text: customTo.value,
            orientation: 'horizontal',
          },
        },
      ],
      yaxis: [
        props.value1 && {
          y: props.value1,
          borderColor: '#3b82f6',
          strokeDashArray: 5,
          label: {
            borderColor: '#3b82f6',
            style: { color: '#fff', background: '#3b82f6' },
            text: `${props.value1}`,
          },
        },
        props.value2 && {
          y: props.value2,
          borderColor: '#10b981',
          strokeDashArray: 5,
          label: {
            borderColor: '#10b981',
            style: { color: '#fff', background: '#10b981' },
            text: `${props.value2}`,
          },
        },
        props.value3 && {
          y: props.value3,
          borderColor: '#f59e0b',
          strokeDashArray: 5,
          label: {
            borderColor: '#f59e0b',
            style: { color: '#fff', background: '#f59e0b' },
            text: `${props.value3}`,
          },
        },
        props.value4 && {
          y: props.value4,
          borderColor: '#ef4444',
          strokeDashArray: 5,
          label: {
            borderColor: '#ef4444',
            style: { color: '#fff', background: '#ef4444' },
            text: `${props.value4}`,
          },
        },
        props.value5 && {
          y: props.value5,
          borderColor: '#8b5cf6',
          strokeDashArray: 5,
          label: {
            borderColor: '#8b5cf6',
            style: { color: '#fff', background: '#8b5cf6' },
            text: `${props.value5}`,
          },
        },
      ].filter(Boolean),
    },
  }

  const series = [
    {
      name: props.fieldName,
      data: seriesData,
    },
  ]

  chartConfig.value = {
    type: 'line',
    height: 280,
    options: chartOptions,
    series,
  }

  loading.value = false
}

onMounted(async () => {
  await loadChartData()
})
</script>

<template>
  <div class="space-y-1.5">
    <!-- Header + Date Filter in one row -->
    <div class="flex flex-wrap items-center justify-between gap-2">
      <div class="flex items-center gap-2 min-w-0">
        <span
          class="text-sm font-semibold text-gray-900 dark:text-white truncate"
        >
          {{ fieldName }} ({{ unit }})
        </span>
        <span class="text-xs text-gray-400 shrink-0">{{ fieldKey }}</span>
      </div>

      <!-- Date inputs inline -->
      <div class="flex items-center gap-1.5 shrink-0">
        <input
          v-model="customFrom"
          type="date"
          class="rounded border border-gray-300 px-1.5 py-0.5 text-xs dark:border-gray-600 dark:bg-gray-800 dark:text-white focus:outline-none focus:ring-1 focus:ring-primary-500"
        />
        <span class="text-gray-400 text-xs">—</span>
        <input
          v-model="customTo"
          type="date"
          class="rounded border border-gray-300 px-1.5 py-0.5 text-xs dark:border-gray-600 dark:bg-gray-800 dark:text-white focus:outline-none focus:ring-1 focus:ring-primary-500"
        />
        <button
          type="button"
          class="rounded bg-primary-600 px-2 py-0.5 text-xs font-medium text-white hover:bg-primary-700 focus:outline-none dark:bg-primary-500 dark:hover:bg-primary-600"
          @click="applyFilter"
        >
          {{ t('Apply') }}
        </button>
      </div>
    </div>

    <!-- Threshold Values Info -->
    <div class="flex flex-wrap gap-1">
      <div
        v-if="value1"
        class="flex items-center gap-1 rounded bg-blue-50 px-2 py-0.5 dark:bg-blue-900/20"
      >
        <span class="text-xs font-semibold text-blue-600 dark:text-blue-400">{{
          value1
        }}</span>
        <span class="text-xs text-gray-400">V1</span>
      </div>
      <div
        v-if="value2"
        class="flex items-center gap-1 rounded bg-green-50 px-2 py-0.5 dark:bg-green-900/20"
      >
        <span
          class="text-xs font-semibold text-green-600 dark:text-green-400"
          >{{ value2 }}</span
        >
        <span class="text-xs text-gray-400">V2</span>
      </div>
      <div
        v-if="value3"
        class="flex items-center gap-1 rounded bg-amber-50 px-2 py-0.5 dark:bg-amber-900/20"
      >
        <span
          class="text-xs font-semibold text-amber-600 dark:text-amber-400"
          >{{ value3 }}</span
        >
        <span class="text-xs text-gray-400">V3</span>
      </div>
      <div
        v-if="value4"
        class="flex items-center gap-1 rounded bg-red-50 px-2 py-0.5 dark:bg-red-900/20"
      >
        <span class="text-xs font-semibold text-red-600 dark:text-red-400">{{
          value4
        }}</span>
        <span class="text-xs text-gray-400">V4</span>
      </div>
      <div
        v-if="value5"
        class="flex items-center gap-1 rounded bg-purple-50 px-2 py-0.5 dark:bg-purple-900/20"
      >
        <span
          class="text-xs font-semibold text-purple-600 dark:text-purple-400"
          >{{ value5 }}</span
        >
        <span class="text-xs text-gray-400">V5</span>
      </div>
    </div>

    <!-- Chart -->
    <div
      class="cardBox relative p-6 rounded-lg border border-gray-200 bg-white dark:border-gray-700 dark:bg-gray-900"
    >
      <div v-if="loading" class="flex items-center justify-center py-20">
        <div class="text-center">
          <div
            class="mb-4 inline-block h-8 w-8 animate-spin rounded-full border-4 border-gray-300 border-t-blue-600"
          ></div>
          <p class="text-gray-600 dark:text-gray-400">Loading...</p>
        </div>
      </div>

      <div
        v-else-if="error"
        class="rounded-lg bg-red-50 p-4 text-red-800 dark:bg-red-900/20 dark:text-red-300"
      >
        <p class="font-medium">Error:</p>
        <p class="text-sm">{{ error }}</p>
      </div>

      <div v-else-if="chartConfig">
        <AddonApexcharts v-bind="chartConfig" />
      </div>

      <div v-else class="flex items-center justify-center py-20">
        <p class="text-gray-600 dark:text-gray-400">No data available</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* "3D" карт — энд `cardBox` нь BaseCard биш, энгийн div дээр шууд class
   хэлбэрээр байгаа (border/bg аль хэдийн тодорхойлогдсон) тул `.nui-card`
   заах шаардлагагүй. tab6.vue-ийн ижил pattern-тай (`perspective()`-г
   transform-ийн дотор өөрт нь оруулав). */
.cardBox {
  transition: transform 0.25s ease, box-shadow 0.25s ease;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.06),
    0 8px 16px -6px rgba(15, 23, 42, 0.12),
    0 20px 32px -12px rgba(15, 23, 42, 0.18);
}

.cardBox:hover {
  transform: perspective(800px) translateY(-6px) rotateX(2deg);
  box-shadow: 0 2px 4px rgba(15, 23, 42, 0.08),
    0 16px 24px -8px rgba(15, 23, 42, 0.18),
    0 32px 48px -16px rgba(15, 23, 42, 0.28);
}

:global(.dark) .cardBox {
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.4), 0 8px 16px -6px rgba(0, 0, 0, 0.5),
    0 20px 32px -12px rgba(0, 0, 0, 0.6);
}

:global(.dark) .cardBox:hover {
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5), 0 16px 24px -8px rgba(0, 0, 0, 0.6),
    0 32px 48px -16px rgba(0, 0, 0, 0.7);
}
</style>
