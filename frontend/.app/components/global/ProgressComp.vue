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

const loadWorkItems = async () => {
  try {
    const filters = {
      // status: 1,
      active: '1',
      project_work: props.wo_id,
    }
    let items_count = await getItems<any>({
      collection: 'Project_work_item',
      params: {
        filter: filters,
        aggregate: {
          count: '*',
        },
        groupBy: 'value',
        meta: 'filter_count',
      },
    })
    // console.log('items_count', items_count)

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
      const sumTemplateType5Value1 = progress_data?.value.data
        .filter((item) => parseInt(item.value, 0) === 1)
        .reduce((sum, item) => sum + parseInt(item.count), 0)

      completed_value = sumTemplateType5Value1
    } catch (error) {
      console.log(error)
    }
    // console.log(
    //   (completed_value / max_value) * 100,
    //   typeof (completed_value / max_value) * 100,
    // )
    if (
      typeof completed_value === 'number' &&
      typeof max_value === 'number' &&
      max_value !== 0
    ) {
      return (completed_value / max_value) * 100
    } else {
      return 0
    }
  } else {
    return 0
  }
})

onMounted(async () => {
  await loadWorkItems()
})

defineExpose({
  loadWorkItems,
})
</script>

<template>
  <div class="relative w-[100%]">
    <BaseText size="xs" class="text-muted-400 mb-2" lead="none"
      >{{ progress_value.toFixed(2) }}%
    </BaseText>
    <BaseProgress
      :title="$t('Task progress')"
      size="xs"
      :value="progress_value"
      color="success"
    />

    <!-- <div class="flex w-full mb-5 mt-3">
        <BaseProgress
          title="Task progress"
          size="xs"
          :value="progress_value"
          color="success"
        />
      </div> -->
  </div>
</template>
