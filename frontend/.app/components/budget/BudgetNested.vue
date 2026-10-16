<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'

const { t } = useI18n({ useScope: 'global' })
const router = useRouter()

const props = defineProps<{
  children: any[]
  depth?: number
}>()

const emit = defineEmits<{ (e: 'edit', id: number): void }>()

const expanded = ref<Record<number, boolean>>({})

const toggle = (id: number) => {
  expanded.value[id] = !expanded.value[id]
}

const formatAmount = (val: any) =>
  val != null ? Number(val).toLocaleString() : '-'

const usedPercent = (used: number, total: number) => {
  if (!total) return 0
  return Math.min(100, Math.round((used / total) * 100))
}

const statusColor = (status: any) => {
  if (status == 2) return 'success'
  if (status == 3) return 'warning'
  if (status == 0) return 'danger'
  return 'info'
}

const statusLabel = (status: any) => {
  if (status == 2) return t('Approved')
  if (status == 3) return t('Closed')
  if (status == 0) return t('Inactive')
  return t('Active')
}
</script>

<template>
  <div>
    <div
      v-for="item in children"
      :key="item.id"
      :style="{ paddingLeft: `${(depth ?? 0) * 20}px` }"
    >
      <!-- Row -->
      <div
        class="group flex items-center gap-2 border-b border-gray-100 py-2 pr-2 hover:bg-muted-50 dark:border-gray-700 dark:hover:bg-muted-800 cursor-pointer"
        @click="toggle(item.id)"
      >
        <!-- Expand toggle -->
        <div class="w-5 shrink-0 text-center text-gray-400">
          <Icon
            v-if="item.children?.length"
            :name="expanded[item.id] ? 'mdi:chevron-down' : 'mdi:chevron-right'"
            class="size-4"
          />
          <span v-else class="inline-block size-4" />
        </div>

        <!-- Budget code -->
        <div class="w-28 shrink-0">
          <BaseTag
            shape="rounded"
            variant="pastel"
            color="primary"
            class="text-xs font-mono cursor-pointer"
            @click.stop="router.push(`/budgets/${item.id}`)"
          >
            {{ item.budget_code || '-' }}
          </BaseTag>
        </div>

        <!-- Name -->
        <div class="flex-1 min-w-0">
          <span
            class="text-sm font-medium text-muted-800 dark:text-muted-100 truncate block"
          >
            {{ item.budget_name }}
          </span>
          <span
            v-if="item.description"
            class="text-xs text-muted-400 truncate block"
          >
            {{ item.description }}
          </span>
        </div>

        <!-- Total amount -->
        <div class="w-32 shrink-0 text-right">
          <span
            class="text-sm font-semibold text-muted-700 dark:text-muted-200"
          >
            {{ formatAmount(item.total_amount) }}₮
          </span>
        </div>

        <!-- Used amount -->
        <div class="w-32 shrink-0 text-right">
          <span class="text-sm text-muted-500 dark:text-muted-400">
            {{ formatAmount(item.used_amount) }}₮
          </span>
        </div>

        <!-- Progress bar -->
        <div class="w-28 shrink-0">
          <div class="flex items-center gap-1">
            <div
              class="flex-1 h-1.5 rounded-full bg-gray-200 dark:bg-gray-700 overflow-hidden"
            >
              <div
                class="h-full rounded-full transition-all"
                :class="
                  usedPercent(item.used_amount, item.total_amount) > 90
                    ? 'bg-red-500'
                    : usedPercent(item.used_amount, item.total_amount) > 70
                    ? 'bg-amber-500'
                    : 'bg-primary-500'
                "
                :style="{
                  width: `${usedPercent(item.used_amount, item.total_amount)}%`,
                }"
              />
            </div>
            <span class="text-xs text-muted-400 w-8 text-right">
              {{ usedPercent(item.used_amount, item.total_amount) }}%
            </span>
          </div>
        </div>

        <!-- Dates -->
        <div class="w-24 shrink-0 text-center text-xs text-muted-400">
          {{ item.start_date }}
        </div>
        <div class="w-24 shrink-0 text-center text-xs text-muted-400">
          {{ item.end_date }}
        </div>

        <!-- Status -->
        <div class="w-20 shrink-0 text-center">
          <BaseTag
            shape="rounded"
            variant="pastel"
            :color="statusColor(item.status)"
            class="text-xs"
          >
            {{ statusLabel(item.status) }}
          </BaseTag>
        </div>

        <!-- Actions -->
        <div class="w-16 shrink-0 flex justify-end items-center gap-1">
          <NuxtLink
            :to="`/budgets/${item.id}/edit`"
            class="opacity-0 group-hover:opacity-100 transition-opacity p-1 rounded hover:bg-primary-50 dark:hover:bg-primary-900/30"
            :title="t('Edit')"
            @click.stop
          >
            <Icon name="mdi:pencil" class="size-4 text-primary-500" />
          </NuxtLink>
          <NuxtLink
            :to="`/budgets/${item.id}`"
            class="opacity-0 group-hover:opacity-100 transition-opacity p-1"
            @click.stop
          >
            <Icon name="mdi:chevron-right" class="size-4 text-primary-500" />
          </NuxtLink>
        </div>
      </div>

      <!-- Recursive children -->
      <BudgetNested
        v-if="item.children?.length && expanded[item.id]"
        :children="item.children"
        :depth="(depth ?? 0) + 1"
        @edit="(id) => emit('edit', id)"
      />
    </div>
  </div>
</template>
