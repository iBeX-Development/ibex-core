<script setup>
const { updateItem, getItems } = useDirectusItems()
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const router = useRouter()
const toaster = useToaster()
const parts_sum = ref(0.0)
const trades_sum = ref(0.0)
const actual_parts_sum = ref(0.0)
const actual_trades_sum = ref(0.0)
const actual_other_amount = ref(0.0)

const loading = ref(false)
const route = useRoute()
const other_amount = ref(0.0)
//Planned
const total_amount = computed(() => {
  return parts_sum.value + trades_sum.value + other_amount.value
})

const actual_total_amount = computed(() => {
  return (
    actual_parts_sum.value + actual_trades_sum.value + actual_other_amount.value
  )
})

const props = defineProps([
  'estimated_edit',
  'actual_edit',
  'work_order',
  'loadCostsPart',
  'loadCostsTrades',
])
const emit = defineEmits(['update:loadCostsPart', 'update:loadCostsTrades'])

const loadParts = async () => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: props.work_order?.id,
    }
    const items = await getItems({
      collection: 'Work_inpection_Parts',
      params: {
        filter: filters,
        aggregate: {
          sum: 'amount,actual_amount',
        },
      },
    })
    console.log(items)
    emit('update:loadCostsPart', items[0])

    parts_sum.value = items[0].sum.amount
    actual_parts_sum.value = items[0].sum.actual_amount
    loading.value = false
    console.log(parts_sum.value)
  } catch (e) {
    console.log(e)
  }
}

const loadTrades = async () => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: props.work_order?.id,
    }
    const items = await getItems({
      collection: 'Work_inspection_Tradecode',
      params: {
        filter: filters,
        aggregate: {
          sum: 'total,duration,actual_total,actual_duration',
        },
      },
    })
    console.log(items)
    emit('update:loadCostsTrades', items[0])

    trades_sum.value = items[0].sum.total
    actual_trades_sum.value = items[0].sum.actual_total
    loading.value = false
    console.log(trades_sum.value)
  } catch (e) {
    console.log(e)
  }
}

onMounted(async () => {
  // Костс таб бүр дахин mount хийгдэх бүрдээ шинэ нийлбэрийг шууд татна —
  // эцгээс дамжсан props.loadCostsPart/loadCostsTrades-г кэш болгон ашиглавал
  // Parts.vue/Trades.vue дээр хийсэн шинэчлэл харагдахгүй байсан
  await loadParts()
  await loadTrades()
  console.log(props.work_order.other_actual_amount)
  actual_other_amount.value = props.work_order?.other_actual_amount
    ? props.work_order?.other_actual_amount
    : 0
  other_amount.value = props.work_order?.other_amount
    ? props.work_order?.other_amount
    : 0
})

const handleOtherAmount = async () => {
  setTimeout(() => {
    const updateData = {
      collection: 'Work_inspections',
      id: props.work_order?.id,
      item: {
        other_amount: other_amount.value,
      },
    }
    updateItem(updateData)
    // Эцэг компонентоос дамжсан work_order-ийг шинэчилж, tab солиход
    // (энэ component дахин mount хийгдэхэд) шинэ утгаараа эхлүүлнэ
    if (props.work_order) props.work_order.other_amount = other_amount.value
  }, 500)
}
const handleOtherActualAmount = async () => {
  setTimeout(() => {
    const updateData = {
      collection: 'Work_inspections',
      id: props.work_order?.id,
      item: {
        other_actual_amount: actual_other_amount.value,
      },
    }
    updateItem(updateData)
    if (props.work_order)
      props.work_order.other_actual_amount = actual_other_amount.value
  }, 500)
}
</script>
<template>
  <div>
    <div class="grid grid-cols-2 gap-3 mb-[50px]">
      <BaseCard class="flex h-full flex-col p-6">
        <div class="mb-4 flex items-center justify-between">
          <BaseHeading
            as="h3"
            size="md"
            weight="semibold"
            lead="tight"
            class="text-muted-800 dark:text-white"
          >
            <span>{{ t('Planned') }}</span>
          </BaseHeading>
        </div>

        <div class="mt-auto">
          <div class="space-y-3">
            <div>
              <BaseInput
                type="number"
                :classes="{ wrapper: 'grow' }"
                placeholder="0.00"
                shape="rounded"
                :label="t('Trade')"
                hide-label
                readonly="readonly"
                v-model="trades_sum"
              />
            </div>
            <div class="flex w-full gap-2">
              <BaseInput
                type="number"
                :classes="{ wrapper: 'grow' }"
                placeholder="0.00"
                shape="rounded"
                :label="t('Parts')"
                hide-label
                readonly="readonly"
                v-model="parts_sum"
              />
            </div>
            <div class="flex w-full gap-2">
              <BaseInput
                v-model.number="other_amount"
                type="number"
                :classes="{
                  wrapper: 'grow',
                  // grow: true,
                  readonlys: props.estimated_edit,
                }"
                placeholder="0.00"
                shape="rounded"
                :label="t('Other')"
                hide-label
                @change="handleOtherAmount"
                :readonly="props.estimated_edit"
              />
            </div>
            <div class="flex w-full gap-2">
              <BaseInput
                v-model.number="total_amount"
                type="number"
                :classes="{ wrapper: 'grow' }"
                placeholder="0.00"
                shape="rounded"
                :label="t('Total')"
                hide-label
                readonly="readonly"
              />
            </div>
          </div>
        </div>
      </BaseCard>

      <BaseCard class="flex h-full flex-col p-6">
        <div class="mb-4 flex items-center justify-between">
          <BaseHeading
            as="h3"
            size="md"
            weight="semibold"
            lead="tight"
            class="text-muted-800 dark:text-white"
          >
            <span>{{ t('Actual') }}</span>
          </BaseHeading>
        </div>

        <div class="mt-auto">
          <div class="space-y-3">
            <div>
              <BaseInput
                type="number"
                :classes="{ wrapper: 'grow' }"
                placeholder="0.00"
                shape="rounded"
                :label="t('Trade')"
                hide-label
                readonly="readonly"
                v-model="actual_trades_sum"
              />
            </div>
            <div class="flex w-full gap-2">
              <BaseInput
                type="number"
                :classes="{ wrapper: 'grow' }"
                placeholder="0.00"
                shape="rounded"
                :label="t('Parts')"
                hide-label
                readonly="readonly"
                v-model="actual_parts_sum"
              />
            </div>
            <div class="flex w-full gap-2">
              <BaseInput
                v-model.number="actual_other_amount"
                type="number"
                :classes="{ wrapper: 'grow' }"
                placeholder="0.00"
                shape="rounded"
                :label="t('Other')"
                hide-label
                @change="handleOtherActualAmount"
                :readonly="props.actual_edit"
              />
            </div>
            <div class="flex w-full gap-2">
              <BaseInput
                v-model.number="actual_total_amount"
                type="number"
                :classes="{ wrapper: 'grow' }"
                placeholder="0.00"
                shape="rounded"
                :label="t('Total')"
                hide-label
                readonly="readonly"
              />
            </div>
          </div>
        </div>
      </BaseCard>
    </div>
  </div>
</template>
