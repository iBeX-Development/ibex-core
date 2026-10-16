<script setup>
const { updateItem, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import ModalItemsList from '~/components/form/ModalItemsList.vue'

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

// ── Budget ────────────────────────────────────────────────────────────────────
const budgetOptions = ref([])
const selectedBudgetId = ref(null)
const selectedBudget = ref(null)
const budgetSaving = ref(false)
const budgetSearch = ref('')
const showBudgetDropdown = ref(false)

const filteredBudgets = computed(() => {
  const q = budgetSearch.value.toLowerCase().trim()
  if (!q) return budgetOptions.value
  return budgetOptions.value.filter(
    (b) =>
      b.budget_code?.toLowerCase().includes(q) ||
      b.budget_name?.toLowerCase().includes(q),
  )
})

const loadBudgets = async () => {
  const resp = await getItems({
    collection: 'Budget',
    params: {
      filter: {
        status: { _in: ['Active', 'Approved'] },
        company_id: { _eq: myCompanyId },
      },
      limit: -1,
      fields: [
        'id',
        'budget_code',
        'budget_name',
        'total_amount',
        'used_amount',
        'status',
      ],
      sort: ['budget_code'],
    },
  })
  const list = Array.isArray(resp) ? resp : resp?.data || []
  budgetOptions.value = list
}

const onBudgetChange = async () => {
  if (!selectedBudgetId.value) {
    selectedBudget.value = null
    budgetSearch.value = ''
    await saveBudget(null)
    return
  }
  selectedBudget.value =
    budgetOptions.value.find((b) => b.id === selectedBudgetId.value) ?? null
  if (selectedBudget.value) {
    budgetSearch.value = `${selectedBudget.value.budget_code} — ${selectedBudget.value.budget_name}`
  }
  await saveBudget(selectedBudgetId.value)
}

const chooseBudget = (b) => {
  selectedBudgetId.value = b.id
  selectedBudget.value = b
  budgetSearch.value = `${b.budget_code} — ${b.budget_name}`
  showBudgetDropdown.value = false
  saveBudget(b.id)
}

const hideBudgetDropdown = () => {
  setTimeout(() => {
    showBudgetDropdown.value = false
  }, 200)
}

const toggleBudgetDropdown = () => {
  showBudgetDropdown.value = !showBudgetDropdown.value
  budgetSearch.value = ''
}

const isBudgetModalOpen = ref(false)

const budgetHeaders = [
  { title: 'Code', key: 'budget_code', sortable: true },
  { title: 'Name', key: 'budget_name', sortable: true },
  { title: 'Total', key: 'total_amount', sortable: true },
  { title: 'Status', key: 'status', sortable: false },
  { title: 'Action', key: 'action', sortable: false },
]

const setBudgetFromModal = (item) => {
  selectedBudgetId.value = item.id
  selectedBudget.value = item
  budgetSearch.value = `${item.budget_code} — ${item.budget_name}`
  saveBudget(item.id)
}

const clearBudget = async () => {
  selectedBudgetId.value = null
  selectedBudget.value = null
  budgetSearch.value = ''
  showBudgetDropdown.value = false
  await saveBudget(null)
}

const saveBudget = async (budgetId) => {
  const id = budgetId ? Number(budgetId) : null
  budgetSaving.value = true
  try {
    const plannedAmount = id ? Number(total_amount.value) : null
    const actualAmount = id ? Number(actual_total_amount.value) : null
    await updateItem({
      collection: woCollectionName.value,
      id: props.work_order?.id,
      item: {
        budget: id,
        budget_planned_amount: plannedAmount,
        budget_actual_amount: actualAmount,
      },
    })
    // Эцэг компонентоос дамжсан work_order-ийг шинэчилж, tab солиход
    // (энэ component дахин mount хийгдэхэд) шинэ утгаараа эхлүүлнэ
    if (props.work_order) {
      props.work_order.budget = id
      props.work_order.budget_planned_amount = plannedAmount
      props.work_order.budget_actual_amount = actualAmount
    }
    toaster.show({
      title: t('Saved'),
      message: t('Budget linked to work order'),
      color: 'success',
      icon: 'ph:check-circle-fill',
      closable: true,
    })
  } catch (e) {
    console.error('Budget save error', e)
  } finally {
    budgetSaving.value = false
  }
}

const budgetRemaining = computed(() => {
  if (!selectedBudget.value) return null
  return (
    Number(selectedBudget.value.total_amount ?? 0) -
    Number(selectedBudget.value.used_amount ?? 0)
  )
})
const afterPlanned = computed(() => {
  if (!selectedBudget.value) return null
  return Number(selectedBudget.value.total_amount ?? 0) - total_amount.value
})
const afterDeduction = computed(() => {
  if (!selectedBudget.value) return null
  return budgetRemaining.value - total_amount.value
})

const formatMoney = (v) => (v != null ? Number(v).toLocaleString() : '-')

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
  'parts_collection',
  'trades_collection',
  'wo_collection',
  'freeze',
  'action_status',
  'show_budget',
])

const shouldShowBudget = computed(() => props.show_budget !== false)

// Computed property to check if we should disable/lock everything
const isLocked = computed(() => {
  return props.action_status === 2 || props.freeze
})

const partsCollectionName = computed(
  () => props.parts_collection || 'Work_order_Parts',
)
const tradesCollectionName = computed(
  () => props.trades_collection || 'Work_order_Tradecode',
)
const woCollectionName = computed(() => props.wo_collection || 'Work_order')
const emit = defineEmits(['update:loadCostsPart', 'update:loadCostsTrades'])

const loadParts = async () => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: props.work_order?.id,
      company_id: { _eq: myCompanyId },
    }
    const items = await getItems({
      collection: partsCollectionName.value,
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
      // company_id: { _eq: myCompanyId },
    }

    // console.log('filters', filters)
    // console.log('tradesCollectionName', tradesCollectionName.value)
    const items = await getItems({
      collection: tradesCollectionName.value,
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
  if (shouldShowBudget.value) {
    await loadBudgets()

    // Restore linked budget from work_order
    if (props.work_order?.budget) {
      const budgetId =
        typeof props.work_order.budget === 'object'
          ? props.work_order.budget.id
          : props.work_order.budget
      selectedBudgetId.value = Number(budgetId)
      // Try to find in already loaded options
      let found =
        budgetOptions.value.find((b) => b.id === Number(budgetId)) ?? null
      // If not found (e.g. Closed/Inactive budget), fetch directly
      if (!found) {
        try {
          const resp = await getItems({
            collection: 'Budget',
            params: {
              filter: {
                id: { _eq: budgetId },
                company_id: { _eq: myCompanyId },
              },
              limit: 1,
              fields: [
                'id',
                'budget_code',
                'budget_name',
                'total_amount',
                'used_amount',
                'status',
              ],
            },
          })
          const list = Array.isArray(resp) ? resp : resp?.data || []
          found = list[0] ?? null
        } catch (e) {
          console.error('Budget fetch error', e)
        }
      }
      selectedBudget.value = found
      if (found) {
        budgetSearch.value = `${found.budget_code} — ${found.budget_name}`
      }
    }
  }

  // Костс таб бүр дахин mount хийгдэх бүрдээ (жишээ нь Parts/Trades tab-аас
  // солиход) Work_order_Parts/Tradecode-оос шинэ нийлбэрийг шууд татна —
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
      collection: woCollectionName.value,
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
      collection: woCollectionName.value,
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
    <!-- ── Budget Section ─────────────────────────────────────── -->
    <BaseCard v-if="shouldShowBudget" class="p-5 mb-4">
      <div class="flex items-center gap-2 mb-3">
        <Icon name="mdi:cash-multiple" class="size-5 text-primary-500" />
        <span class="font-semibold text-sm text-muted-800 dark:text-white">{{
          t('Budget')
        }}</span>
        <span v-if="budgetSaving" class="ml-2 text-xs text-muted-400">{{
          t('Saving...')
        }}</span>
      </div>
      <div class="flex flex-wrap gap-4 items-start">
        <!-- Budget selector -->
        <div class="w-1/2 relative">
          <div class="flex gap-2">
            <div class="relative flex-1">
              <input
                v-model="budgetSearch"
                type="text"
                class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full pr-8 cursor-pointer"
                style="
                  padding: 10px;
                  border: 1px solid #d1d5db;
                  border-radius: 6px;
                "
                :placeholder="t('Search budget...')"
                :disabled="budgetSaving || isLocked"
                autocomplete="off"
                @focus="showBudgetDropdown = true"
                @input="showBudgetDropdown = true"
                @blur="hideBudgetDropdown"
              />
              <button
                v-if="selectedBudget"
                class="absolute right-2 top-1/2 -translate-y-1/2 text-muted-400 hover:text-red-500"
                type="button"
                :disabled="isLocked"
                @mousedown.prevent="clearBudget"
              >
                <Icon name="ph:x" class="size-3.5" />
              </button>
            </div>
            <BaseButton
              size="sm"
              shape="rounded"
              color="muted"
              type="button"
              :disabled="budgetSaving || isLocked"
              @click="toggleBudgetDropdown"
            >
              <Icon name="ph:arrow-clockwise" class="h-4 w-4" />
            </BaseButton>
            <BaseButton
              size="sm"
              shape="rounded"
              color="muted"
              type="button"
              class="moreList"
              :disabled="budgetSaving || isLocked"
              @click="isBudgetModalOpen = true"
            >
              <Icon name="ph:list" class="size-4 mr-1" />
            </BaseButton>
            <BaseButton
              size="sm"
              shape="rounded"
              color="muted"
              type="button"
              class="moreList"
              :disabled="budgetSaving || isLocked"
              @click="saveBudget(selectedBudgetId)"
            >
              <Icon name="material-symbols:download-done" class="size-4 mr-1" />
            </BaseButton>
          </div>
          <!-- Dropdown -->
          <div
            v-if="showBudgetDropdown"
            class="absolute z-50 mt-1 w-full max-h-56 overflow-y-auto bg-white dark:bg-muted-900 border border-muted-200 dark:border-muted-700 rounded-lg shadow-xl"
          >
            <div
              v-for="b in filteredBudgets"
              :key="b.id"
              class="flex items-center justify-between px-3 py-2 hover:bg-muted-50 dark:hover:bg-muted-800 cursor-pointer text-sm"
              @mousedown.prevent="chooseBudget(b)"
            >
              <div>
                <span
                  class="font-mono font-medium text-primary-600 text-xs mr-2"
                  >{{ b.budget_code }}</span
                >
                <span class="text-muted-700 dark:text-muted-200">{{
                  b.budget_name
                }}</span>
              </div>
              <span class="text-xs text-muted-400 ml-2 shrink-0"
                >{{ formatMoney(b.total_amount) }}₮</span
              >
            </div>
            <div
              v-if="!filteredBudgets.length"
              class="px-3 py-2 text-xs text-muted-400"
            >
              {{ t('No results') }}
            </div>
          </div>
        </div>
        <!-- Budget info cards -->
        <div v-if="selectedBudget" class="flex gap-4 flex-wrap text-sm">
          <div
            class="bg-muted-50 dark:bg-muted-800 rounded-lg px-4 py-2 text-center min-w-[120px]"
          >
            <p class="text-xs text-muted-400 mb-0.5">{{ t('Total Budget') }}</p>
            <p class="font-bold text-muted-800 dark:text-muted-100">
              {{ formatMoney(selectedBudget.total_amount) }}₮
            </p>
          </div>
          <div
            class="bg-muted-50 dark:bg-muted-800 rounded-lg px-4 py-2 text-center min-w-[120px]"
          >
            <p class="text-xs text-muted-400 mb-0.5">{{ t('Remaining') }}</p>
            <p
              class="font-bold"
              :class="budgetRemaining < 0 ? 'text-red-500' : 'text-green-600'"
            >
              {{ formatMoney(budgetRemaining) }}₮
            </p>
          </div>
          <div
            class="bg-amber-50 dark:bg-amber-900/20 rounded-lg px-4 py-2 text-center min-w-[140px] border border-amber-200 dark:border-amber-700"
          >
            <p class="text-xs text-muted-400 mb-0.5">
              {{ t('After Planned') }}
            </p>
            <p
              class="font-bold"
              :class="afterPlanned < 0 ? 'text-red-500' : 'text-amber-600'"
            >
              {{ formatMoney(afterPlanned) }}₮
            </p>
          </div>
          <div
            class="bg-primary-50 dark:bg-primary-900/20 rounded-lg px-4 py-2 text-center min-w-[140px] border border-primary-200 dark:border-primary-700"
          >
            <p class="text-xs text-muted-400 mb-0.5">
              {{ t('After Actual') }}
            </p>
            <p
              class="font-bold"
              :class="afterDeduction < 0 ? 'text-red-500' : 'text-primary-600'"
            >
              {{ formatMoney(afterDeduction) }}₮
            </p>
          </div>
        </div>
      </div>
    </BaseCard>

    <!-- Budget modal -->
    <ModalItemsList
      v-if="shouldShowBudget"
      :open="isBudgetModalOpen"
      :close="
        () => {
          isBudgetModalOpen = false
        }
      "
      :set-item="setBudgetFromModal"
      :title="t('Budget')"
      collection="Budget"
      fields="id, budget_code, budget_name, total_amount, used_amount, status"
      :header="budgetHeaders"
      :filter="{ status: { _in: ['Active', 'Approved'] } }"
      size="xl"
    />

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
                  input:
                    props.estimated_edit || isLocked
                      ? ''
                      : '!border-primary-500 dark:!border-primary-400',
                }"
                placeholder="0.00"
                shape="rounded"
                :label="t('Other')"
                hide-label
                @change="handleOtherAmount"
                :readonly="props.estimated_edit || isLocked"
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
                :classes="{
                  wrapper: 'grow',
                  input: props.actual_edit
                    ? ''
                    : '!border-primary-500 dark:!border-primary-400',
                }"
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
<style scoped>
:deep(.nui-input) {
  border-style: solid;
  border-radius: 6px;
}
</style>
