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
  completed: String,
  wo_ids: Array,
  project_id: Number,
  class: String,
  type: String,
})

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()

const { params } = useRoute()
const progress_data = ref({})
const completed_data = ref({})

const loadWorkItems = async () => {
  try {
    if (props.wo_ids?.length > 0) {
      const filters = {
        // status: 1,
        active: '1',
        project_work: { _in: props.wo_ids },
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
    }
  } catch (e) {
    console.log(e)
  }
}

const loadPercent = async () => {
  try {
    const filters = {
      // status: 1,
      active: '1',
      id: { _in: props.project_id },
    }
    let items = await getItems<any>({
      collection: 'Projects',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['completed'],
      },
    })
    console.log('items_count', items)
    completed_data.value = items
  } catch (e) {
    console.log(e)
  }
}

const updateProgress = async () => {
  try {
    console.log('updateProgress', progress_value)

    let updateItemss = {
      collection: 'Projects',
      id: props.project_id,
      item: {
        completed: Number(progress_value.value).toFixed(2),
      },
    }

    updateItem(updateItemss).then((res) => {
      console.log('done', res)
    })
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

  if (Number(progress_value.value).toFixed(2) !== props.completed) {
    // console.log('newVal !== oldVal', progress_value.value, props.completed)
    await updateProgress()
  }
})

defineExpose({
  loadWorkItems,
})
</script>

<template>
  <div class="relative w-[100%]">
    <div class="relative flex items-center w-[160px]">
      <BaseProgressCircle
        :value="progress_value"
        :thickness="1"
        :size="160"
        class="text-success-500 flex items-center"
      />
      <div
        class="absolute start-1/2 top-1/2 z-10 ms-0.5 -translate-x-1/2 -translate-y-1/2 font-sans text-[1.5rem] font-semibold rtl:me-0.5 rtl:ms-0 rtl:translate-x-1/2"
      >
        {{ progress_value.toFixed(2) }}%
      </div>
    </div>
  </div>
</template>
