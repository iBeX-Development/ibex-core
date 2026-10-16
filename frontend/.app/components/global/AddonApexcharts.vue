<script setup lang="ts">
import 'assets/css/apexcharts.css'
import { useLazyApexCharts } from '~/compsables/apexcharts'

const props = defineProps<{
  type: string
  height: number
  width?: number
  series: any[]
  /**
   * ApexCharts options - Without `series`, `chart.type` / `chart.height` / `chart.width`  properties
   * @see https://apexcharts.com/docs/options/
   */
  options?: Record<string, any>
}>()
const { LazyApexCharts, isLoaded } = useLazyApexCharts()
const target = ref(null)
const targetIsVisible = ref(false)

// When the target is visible on viewport, load the chart
const { stop } = useIntersectionObserver(target, ([{ isIntersecting }]) => {
  if (isIntersecting) {
    targetIsVisible.value = isIntersecting
    stop()
  }
})

// Sidebar/filter panel нээгдэх зэргээр эзэлж буй баганы өргөн нарийсахад
// window.resize event шатахгүй тул ApexCharts SVG хуучин (өргөн)
// хэмжээгээрээ үлдэж box-оосоо хальдаг. ResizeObserver-оор контейнерийн
// хэмжээ өөрчлөгдөх бүрд synthetic resize event шатаж, ApexCharts-ийг
// шинэ хэмжээндээ тааруулан дахин зурна.
let resizeObserver: ResizeObserver | null = null
let resizeTimeout: ReturnType<typeof setTimeout> | null = null

onMounted(() => {
  if (typeof ResizeObserver === 'undefined' || !target.value) return

  resizeObserver = new ResizeObserver(() => {
    if (resizeTimeout) clearTimeout(resizeTimeout)
    resizeTimeout = setTimeout(() => {
      window.dispatchEvent(new Event('resize'))
    }, 100)
  })
  resizeObserver.observe(target.value)
})

onBeforeUnmount(() => {
  resizeObserver?.disconnect()
  if (resizeTimeout) clearTimeout(resizeTimeout)
})
</script>

<template>
  <div ref="target" class="w-full overflow-hidden">
    <BasePlaceload
      v-if="!isLoaded && !targetIsVisible"
      class="m-4 w-[calc(100%-32px)]"
      :style="{ height: `${height - 32}px` }"
    />
    <ClientOnly>
      <LazyApexCharts v-if="targetIsVisible" v-show="isLoaded" v-bind="props" />
      <BasePlaceload
        v-else
        class="m-4 w-[calc(100%-32px)]"
        :style="{ height: `${height - 32}px` }"
      />
    </ClientOnly>
  </div>
</template>
