<script setup lang="ts">
import { ref } from 'vue'

definePageMeta({
  middleware: ['auth'],
  title: 'Preview asset',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})

const props = defineProps({
  progressData: Object,
  loadIem: Boolean,
  location: String,
  work_order_type: String,
  wo_id: Number,
  class: String,
  type: String,
})

const { getItems } = useDirectusItems()
const { params } = useRoute()
const progress_data = ref({})

const loadWorkOrderItems = async () => {
  try {
    const filters = {
      active: 1,
      workorder: props.wo_id,
    }
    let items_count = await getItems<any>({
      collection: 'Work_inspection_item',
      params: {
        filter: filters,
        aggregate: {
          count: '*',
        },
        groupBy: 'template_type, value',
        meta: 'filter_count',
      },
    })

    progress_data.value = items_count
  } catch (e) {
    console.log(e)
  }
}

const progress_value = computed(() => {
  if (progress_data?.value && progress_data?.value.data) {
    const max_value = progress_data?.value.meta.filter_count
    let completed_value = 0
    try {
      // 1. Get the sum for template_type = 5 and value = "1"
      const sumTemplateType5Value1 = progress_data?.value.data
        .filter((item) => item.template_type === 5 && item.value === '1')
        .reduce((sum, item) => sum + parseInt(item.count), 0)

      console.log(
        'Sum for template_type = 5, value = 1:',
        sumTemplateType5Value1,
      )

      // 2. Get the sum for template_type = 7 where value is not null or empty
      const sumTemplateType7NotNull = progress_data?.value.data
        .filter(
          (item) =>
            item.template_type === 7 &&
            item.value !== null &&
            item.value !== '',
        )
        .reduce((sum, item) => sum + parseInt(item.count), 0)
      console.log('Sum for template_type = 7, value:', sumTemplateType7NotNull)
      completed_value = sumTemplateType7NotNull + sumTemplateType5Value1
    } catch (error) {
      console.log(error)
    }
    if (isNaN((completed_value / max_value) * 100)) return 0
    return (completed_value / max_value) * 100
  } else {
    return 0
  }
})

onMounted(async () => {
  await loadWorkOrderItems()
})

defineExpose({
  loadWorkOrderItems,
  progress_value,
  progress_data,
})
</script>

<template>
  <div class="relative">
    <BaseCard shape="rounded" class="p-2 md:p-4">
      <div class="flex w-full">
        <BaseHeading
          as="h4"
          size="lg"
          weight="semibold"
          class="text-muted-800 dark:text-white"
        >
          {{ $t('Task progress') }} {{ progress_value.toFixed(2) }}%
        </BaseHeading>
      </div>
      <div class="flex w-full mb-5 mt-3">
        <BaseProgress
          :title="$t('Task progress')"
          size="xs"
          :value="progress_value"
          color="success"
        />
      </div>
    </BaseCard>
  </div>
</template>
