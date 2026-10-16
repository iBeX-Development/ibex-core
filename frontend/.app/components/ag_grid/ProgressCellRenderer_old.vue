<script setup lang="ts">
const { params } = defineProps(['params'])
const { value, data } = params
const items = ref({
  completed: 86,
})
const wo_id = ref(null)
const selectedItem = ref(null)
const isOpenImg = ref(false)

// console.log('params ->', params)
// console.log('data ->', data)

if (data && 'id' in data) {
  wo_id.value = data.id
}

const { getItems } = useDirectusItems()
// const { params } = useRoute()
const progress_data = ref({})

const loadWorkOrderItems = async () => {
  try {
    const filters = {
      active: 1,
      workorder: wo_id.value,
    }
    let items_count = await getItems<any>({
      collection: 'Work_order_item',
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
    // console.log('wo_id.value', progress_data)
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

      // console.log(
      //   'Sum for template_type = 5, value = 1:',
      //   sumTemplateType5Value1,
      // )

      // 2. Get the sum for template_type = 7 where value is not null or empty
      const sumTemplateType7NotNull = progress_data?.value.data
        .filter(
          (item) =>
            item.template_type === 7 &&
            item.value !== null &&
            item.value !== '',
        )
        .reduce((sum, item) => sum + parseInt(item.count), 0)
      // console.log('Sum ', sumTemplateType7NotNull)
      completed_value = sumTemplateType7NotNull + sumTemplateType5Value1
    } catch (error) {
      console.log(error)
    }

    return parseInt((completed_value / max_value) * 100, 0)
  } else {
    return 0
  }
})

onMounted(async () => {
  await loadWorkOrderItems()
})
</script>

<template>
  <div class="progress">
    <div class="flex items-center">
      <div class="relative">
        <BaseProgressCircle
          :value="progress_value"
          :thickness="1"
          :size="50"
          class="text-success-500"
        />
        <span
          class="absolute start-1/2 top-1/2 z-10 ms-0.5 -translate-x-1/2 -translate-y-1/2 font-sans text-[0.65rem] font-semibold rtl:me-0.5 rtl:ms-0 rtl:translate-x-1/2"
        >
          {{ progress_value }}%
        </span>
      </div>
    </div>
  </div>
</template>

<style>
.progress {
  height: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: start;
}

.image {
  max-width: 100%;
  max-height: 100px;
  background-color: rgba(201, 201, 201, 0.2);
  border-radius: 8px;
  /* margin: 8px; */
}

.image img {
  width: 37px;
  height: 37px;
}

.progress div:first-child {
  font-weight: 500;
}

.progress div {
  padding-bottom: 0;
  line-height: 1.5;
}

.progress img {
  border-radius: 8px;
}

.stockCell {
  background-color: var(--color-bg-secondary);
  color: var(--color-text-secondary);
  width: fit-content;
  padding-top: 2px;
  margin-top: 4px;
  padding-right: 4px;
  padding-left: 4px;
  font-size: 12px;
}
</style>
