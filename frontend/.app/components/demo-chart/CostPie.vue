<script setup lang="ts">
import { computed, ref } from 'vue'
import { useResizeObserver } from '@vueuse/core'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const props = defineProps({
  pieBar: Object,
  barConfig: Object,
  isOpenFilter: Boolean,
})

const PIE_THRESHOLD = 8

const seriesArr = computed<number[]>(() => {
  const s = props.pieBar?.series
  return (Array.isArray(s) ? s : (s as any)?.value) ?? []
})

console.log(
  '[CostPie] seriesArr:',
  seriesArr.value,
  'props.pieBar:',
  props.pieBar,
)

const labelsArr = computed<string[]>(() => props.pieBar?.options?.labels ?? [])

const hasData = computed(
  () => seriesArr.value.length > 0 && seriesArr.value.some((v) => v > 0),
)

// Auto-detect: use bar when locations > threshold OR any has 0 cost
const autoBarMode = computed(
  () =>
    seriesArr.value.length > PIE_THRESHOLD ||
    seriesArr.value.some((v) => v === 0),
)

// Manual toggle: 'auto' | 'bar' | 'pie'
const manualMode = ref<'auto' | 'bar' | 'pie'>('auto')
const chartContainer = ref<HTMLElement | null>(null)
const isNarrowChart = ref(false)

useResizeObserver(chartContainer, ([entry]) => {
  isNarrowChart.value = entry.contentRect.width < 520
})

const isBarMode = computed(() => {
  if (manualMode.value === 'bar') return true
  if (manualMode.value === 'pie') return false
  return autoBarMode.value
})

console.log(
  '[CostPie] hasData:',
  hasData.value,
  'autoBarMode:',
  autoBarMode.value,
  'isBarMode:',
  isBarMode.value,
)
// Horizontal bar config: top 15 sorted by cost desc
const barConfig = computed(() => {
  const { primary } = useTailwindColors()

  const paired = labelsArr.value.map((label, i) => ({
    label,
    val: seriesArr.value[i] || 0,
  }))
  paired.sort((a, b) => b.val - a.val)
  const top = paired.slice(0, 15)

  return {
    type: 'bar',
    height: Math.max(280, top.length * 36),
    options: {
      chart: { type: 'bar', toolbar: { show: false } },
      plotOptions: {
        bar: { horizontal: true, borderRadius: 3, barHeight: '55%' },
      },
      colors: [primary.value],
      dataLabels: {
        enabled: true,
        formatter: (v: number) =>
          v > 0 ? v.toLocaleString('mn-MN') + ' ₮' : '',
        style: { fontSize: '11px', fontWeight: 700, colors: ['#1e293b'] },
        offsetX: 4,
      },
      xaxis: {
        categories: top.map((p) => p.label),
        labels: { show: false },
        axisBorder: { show: false },
        axisTicks: { show: false },
      },
      yaxis: {
        labels: {
          show: !(props.isOpenFilter && isNarrowChart.value),
          style: { fontSize: '12px' },
        },
      },
      tooltip: {
        y: { formatter: (v: number) => v.toLocaleString('mn-MN') + ' ₮' },
      },
      grid: {
        padding: { left: 0, right: isNarrowChart.value ? 12 : 60 },
        xaxis: { lines: { show: false } },
      },
    },
    series: [{ name: t('Cost'), data: top.map((p) => p.val) }],
  }
})
</script>

<template>
  <BaseCard class="flex h-full flex-col p-6">
    <div class="mb-6 flex items-center justify-between">
      <BaseHeading
        as="h3"
        size="md"
        weight="semibold"
        lead="tight"
        class="text-muted-800 dark:text-white"
      >
        <span>{{ t('Cost by location') }}</span>
      </BaseHeading>

      <!-- Toggle buttons -->
      <div v-if="hasData" class="flex items-center gap-1">
        <button
          :class="[
            'flex h-7 w-7 items-center justify-center rounded transition-colors',
            !isBarMode
              ? 'bg-primary-500 text-white'
              : 'text-muted-400 hover:bg-muted-100 dark:hover:bg-muted-700',
          ]"
          :title="t('Pie chart')"
          @click="manualMode = manualMode === 'pie' ? 'auto' : 'pie'"
        >
          <Icon name="ph:chart-pie-slice" class="h-4 w-4" />
        </button>
        <button
          :class="[
            'flex h-7 w-7 items-center justify-center rounded transition-colors',
            isBarMode
              ? 'bg-primary-500 text-white'
              : 'text-muted-400 hover:bg-muted-100 dark:hover:bg-muted-700',
          ]"
          :title="t('Bar chart')"
          @click="manualMode = manualMode === 'bar' ? 'auto' : 'bar'"
        >
          <Icon name="ph:chart-bar-horizontal" class="h-4 w-4" />
        </button>
      </div>
    </div>

    <div ref="chartContainer" class="flex-1">
      <template v-if="hasData">
        <AddonApexcharts v-if="isBarMode" v-bind="barConfig" />
        <AddonApexcharts v-else v-bind="props.pieBar" />
      </template>
      <div
        v-else
        class="flex h-40 items-center justify-center text-sm text-muted-400"
      >
        {{ t('No data') }}
      </div>
    </div>
  </BaseCard>
</template>

<style scoped>
:deep(.apexcharts-bar-series .apexcharts-datalabels text),
:deep(.apexcharts-rangebar-series .apexcharts-datalabels text) {
  fill: #1e293b !important;
  color: #1e293b !important;
}
</style>
