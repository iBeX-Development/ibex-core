<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()

const props = defineProps<{
  location?: number
  parent?: number
  refreshKey?: number
}>()

const emit = defineEmits<{ (e: 'edit', id: number): void }>()

const loading = ref(true)
const records = ref<any[]>([])
const MAX_DEPTH = 5

// Build deep fields for nested children
const buildFields = () => {
  const fields: string[] = [
    'id',
    'budget_code',
    'budget_name',
    'description',
    'total_amount',
    'used_amount',
    'start_date',
    'end_date',
    'status',
    'parent',
  ]
  for (let i = 1; i <= MAX_DEPTH; i++) {
    const prefix = Array(i).fill('children').join('.')
    fields.push(
      `${prefix}.id`,
      `${prefix}.budget_code`,
      `${prefix}.budget_name`,
      `${prefix}.description`,
      `${prefix}.total_amount`,
      `${prefix}.used_amount`,
      `${prefix}.start_date`,
      `${prefix}.end_date`,
      `${prefix}.status`,
    )
  }
  return fields
}

const loadItems = async () => {
  loading.value = true
  try {
    const filter: any = {
      parent: { _null: true },
      status: { _neq: 0 },
    }
    if (props.location) filter.location = props.location
    if (props.parent) filter.parent = props.parent

    const items = await getItems<any>({
      collection: 'Budget',
      params: {
        filter,
        limit: -1,
        fields: buildFields(),
        sort: ['budget_code'],
      },
    })
    records.value = Array.isArray(items) ? items : (items as any)?.data || []
  } catch (e) {
    console.error('BudgetTree load error:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadItems)
watch(() => props.refreshKey, loadItems)
</script>

<template>
  <div class="relative">
    <BaseCard shape="rounded" class="p-4">
      <!-- Table header -->
      <div
        class="flex items-center gap-2 border-b border-gray-200 dark:border-gray-700 pb-2 pr-2 text-xs font-semibold text-muted-400 uppercase tracking-wide"
      >
        <div class="w-5 shrink-0" />
        <div class="w-28 shrink-0">{{ t('Code') }}</div>
        <div class="flex-1">{{ t('Budget Name') }}</div>
        <div class="w-32 shrink-0 text-right">{{ t('Total') }}</div>
        <div class="w-32 shrink-0 text-right">{{ t('Used') }}</div>
        <div class="w-28 shrink-0 text-center">{{ t('Progress') }}</div>
        <div class="w-24 shrink-0 text-center">{{ t('Start') }}</div>
        <div class="w-24 shrink-0 text-center">{{ t('End') }}</div>
        <div class="w-20 shrink-0 text-center">{{ t('Status') }}</div>
        <div class="w-16 shrink-0" />
      </div>

      <!-- Loading -->
      <div v-if="loading" class="flex justify-center py-10">
        <BaseButtonIcon loading size="lg" />
      </div>

      <!-- Empty -->
      <div
        v-else-if="!records.length"
        class="flex flex-col items-center justify-center py-10 gap-2"
      >
        <Icon name="mdi:cash-off" class="size-10 text-muted-300" />
        <p class="text-sm text-muted-400">{{ t('No budgets found') }}</p>
      </div>

      <!-- Tree rows -->
      <BudgetNested
        v-else
        :children="records"
        :depth="0"
        @edit="(id) => emit('edit', id)"
      />
    </BaseCard>
  </div>
</template>
