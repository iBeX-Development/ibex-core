<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const props = defineProps({
  lineRevenue: Object,
  coloredTitle: String,
  thisMonth: String,
  lastMonth: String,
  currency: Boolean,
})

function moneyFormat(value: number): string {
  if (!value || isNaN(value)) return '0 ₮'
  return value.toLocaleString('mn-MN') + ' ₮'
}

const thisMonthDisplay = computed(() => {
  const val = Number(props.thisMonth)
  return props.currency ? moneyFormat(val) : (props.thisMonth ?? '0')
})

const lastMonthDisplay = computed(() => {
  const val = Number(props.lastMonth)
  return props.currency ? moneyFormat(val) : (props.lastMonth ?? '0')
})
</script>

<template>
  <BaseCard class="p-6">
    <div class="mb-4 flex items-center justify-between">
      <div v-if="coloredTitle" class="text-sm font-medium text-muted-500" v-html="coloredTitle" />
    </div>
    <div class="mb-2 flex gap-8">
      <div>
        <span class="text-xs font-sans text-muted-400">{{ t('This month') }}</span>
        <p class="text-lg font-medium font-sans text-primary-500">{{ thisMonthDisplay }}</p>
      </div>
      <div>
        <span class="text-xs font-sans text-muted-400">{{ t('Last month') }}</span>
        <p class="text-lg font-medium font-sans text-muted-800 dark:text-muted-100">{{ lastMonthDisplay }}</p>
      </div>
    </div>
    <AddonApexcharts v-bind="lineRevenue" />
  </BaseCard>
</template>
