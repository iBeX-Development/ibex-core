<script setup lang="ts">
import PriorityCell from '~/components/custom/priorityCell.vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })

const props = defineProps<{
  items: any[]
  type: string
  onRowClicked: (item: any) => void
  onClickedAction: (item: any, type: string) => void
}>()

function moneyFormat(value: number): string {
  if (isNaN(value)) return '0'
  if (!value) return '0'
  return value.toLocaleString('mn-MN')
}
</script>

<template>
  <div class="px-2 md:px-4 lg:px-6 pb-20">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Task Card -->
      <div
        v-for="(course, index) in items"
        :key="index"
        class="relative col-span-12 sm:col-span-6 lg:col-span-4 cursor-pointer transition duration-200 hover:rounded-md max-w-[350px]"
        @click="onRowClicked(course)"
      >
        <BaseCard rounded="md" class="flex h-full flex-col gap-3 p-4">
          <!-- Header -->
          <div class="flex items-start justify-between gap-2">
            <span class="text-xs font-semibold text-primary-500"
              >{{ props.type }} #{{
                course.wo_number ?? course.auto_number ?? course.id
              }}</span
            >
            <PriorityCell fieldName="priority" :value="course.priority" />
          </div>

          <!-- Title & description -->
          <div>
            <h3
              class="text-sm font-semibold text-muted-800 dark:text-muted-100 line-clamp-2 leading-snug mb-1"
            >
              {{ course.name }}
            </h3>
            <p class="text-xs text-muted-400 line-clamp-2 leading-relaxed">
              {{ course.history_description || t('No description') }}
            </p>
          </div>

          <!-- Divider -->
          <div class="border-t border-muted-200 dark:border-muted-700" />

          <!-- Work costs -->
          <div>
            <p
              class="text-[11px] font-semibold uppercase tracking-wider text-muted-400 mb-2"
            >
              {{ t('Work costs') }}
            </p>
            <div class="grid grid-cols-3 gap-1 text-center">
              <div class="rounded-lg bg-muted-100 dark:bg-muted-800 px-2 py-1">
                <p class="text-[10px] text-muted-400">
                  {{ t('Trades') }}
                </p>
                <p
                  class="text-xs font-semibold text-muted-700 dark:text-muted-200"
                >
                  {{ moneyFormat(course.trades_sum) }}
                </p>
              </div>
              <div class="rounded-lg bg-muted-100 dark:bg-muted-800 px-2 py-1">
                <p class="text-[10px] text-muted-400">
                  {{ t('Parts') }}
                </p>
                <p
                  class="text-xs font-semibold text-muted-700 dark:text-muted-200"
                >
                  {{ moneyFormat(course.parts_sum) }}
                </p>
              </div>
              <div class="rounded-lg bg-muted-100 dark:bg-muted-800 px-2 py-1">
                <p class="text-[10px] text-muted-400">
                  {{ t('Others') }}
                </p>
                <p
                  class="text-xs font-semibold text-muted-700 dark:text-muted-200"
                >
                  {{ moneyFormat(course.other_amount) }}
                </p>
              </div>
            </div>
          </div>

          <!-- Work duration -->
          <div
            class="flex items-center justify-between text-xs text-muted-500 dark:text-muted-400"
          >
            <div class="flex items-center gap-1">
              <Icon name="solar:calendar-linear" class="size-4 shrink-0" />
              <span>
                {{ course.started_at ? course.started_at.split('T')[0] : '?' }}
                —
                {{ course.due ? course.due.split('T')[0] : '?' }}
              </span>
            </div>
            <div class="flex items-center gap-1 shrink-0">
              <Icon
                name="solar:watch-square-minimalistic-linear"
                class="size-4"
              />
              <span>
                {{
                  course.due && course.started_at
                    ? Math.ceil(
                        (new Date(course.due) - new Date(course.started_at)) /
                          (1000 * 60 * 60 * 24),
                      )
                    : '?'
                }}d
              </span>
            </div>
          </div>

          <!-- Divider -->
          <div class="border-t border-muted-200 dark:border-muted-700" />

          <!-- Actions -->
          <div class="flex gap-2">
            <button
              class="flex-1 rounded-lg bg-success-500/10 hover:bg-success-500/20 text-success-600 dark:text-success-400 text-xs font-medium py-1.5 transition-colors"
              @click="
                (e) => {
                  e.stopPropagation()
                  onClickedAction(course, 'Approve')
                }
              "
            >
              {{ t('Approve') }}
            </button>
            <button
              class="flex-1 rounded-lg bg-danger-500/10 hover:bg-danger-500/20 text-danger-600 dark:text-danger-400 text-xs font-medium py-1.5 transition-colors"
              @click="
                (e) => {
                  e.stopPropagation()
                  onClickedAction(course, 'Decline')
                }
              "
            >
              {{ t('Decline') }}
            </button>
            <button
              class="flex-1 rounded-lg bg-info-500/10 hover:bg-info-500/20 text-info-600 dark:text-info-400 text-xs font-medium py-1.5 transition-colors"
              @click="
                (e) => {
                  e.stopPropagation()
                  onClickedAction(course, 'Assign')
                }
              "
            >
              {{ t('Assign') }}
            </button>
          </div>
        </BaseCard>
      </div>
      <div
        v-if="!items || !items.length"
        class="col-span-12 py-10 text-center text-sm text-muted-400"
      >
        {{ t('No records') }}
      </div>
    </div>
  </div>
</template>
