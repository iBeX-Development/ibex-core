<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { priorities } from '~/components/workorder/WorkOrderConstants'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'

const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const { close, currentProps } = usePanels()

// wo_ids нь plain array эсвэл ref(array) хэлбэрээр ирж болно (Vue панелийн
// currentProps дундаас дамждаг тул аль ч хэлбэрийг барина)
const rawIds = currentProps?.value?.wo_ids
const wo_ids: (number | string)[] = Array.isArray(rawIds)
  ? rawIds
  : (rawIds as any)?.value ?? []

const loading = ref(true)
const workOrders = ref<any[]>([])

const asList = (res: any) => (Array.isArray(res) ? res : res?.data ?? [])

const formatMoney = (v: any) =>
  v === null || v === undefined || v === '' ? '0' : Number(v).toLocaleString()

const formatDate = (v: any) => {
  if (!v) return '-'
  const d = new Date(v)
  return isNaN(d.getTime()) ? v : d.toLocaleDateString()
}

const priorityLabel = (v: any) => {
  const found = priorities.find((p) => p.value === v)
  return found ? t(found.text) : '-'
}

const statusLabel = (v: any) => {
  const items: any[] = Array.isArray(wo_status_items) ? wo_status_items : []
  const found = items.find((s) => s.id === v)
  return found ? t(found.name) : '-'
}

const sumField = (rows: any[], key: string) =>
  rows.reduce((total, row) => total + (Number(row[key]) || 0), 0)

onMounted(async () => {
  loading.value = true
  try {
    const ids = [...new Set(wo_ids)]

    const results = await Promise.all(
      ids.map(async (id) => {
        try {
          const workOrderRes = await getItems<any>({
            collection: 'Work_order',
            params: {
              filter: { id: { _eq: id } },
              limit: 1,
              fields: [
                '*',
                'location.name',
                'asset.name',
                'assigned_to.first_name',
                'assigned_to.last_name',
                'request_user.first_name',
                'request_user.last_name',
              ],
            },
          })
          const work_order = asList(workOrderRes)[0]
          if (!work_order) return null

          const [tradesRes, partsRes] = await Promise.all([
            getItems<any>({
              collection: 'Work_order_Tradecode',
              params: {
                filter: { work_order: { _eq: id } },
                fields: ['*', 'trade.code', 'trade.name'],
              },
            }),
            getItems<any>({
              collection: 'Work_order_Parts',
              params: {
                filter: { work_order: { _eq: id } },
                fields: ['*', 'parts.part_number', 'parts.description'],
              },
            }),
          ])

          const trades = asList(tradesRes)
          const parts = asList(partsRes)

          return {
            work_order,
            trades,
            parts,
            trades_sum: sumField(trades, 'total'),
            actual_trades_sum: sumField(trades, 'actual_total'),
            parts_sum: sumField(parts, 'amount'),
            actual_parts_sum: sumField(parts, 'actual_amount'),
          }
        } catch (e) {
          console.error('Print summary: unable to load work order', id, e)
          return null
        }
      }),
    )

    workOrders.value = results.filter((r) => r !== null)
  } finally {
    loading.value = false
  }
})

// Тухайн WO бүрийн "Бусад" зардал болон нийт (Trade+Parts+Бусад) дүнг нэмнэ
const withTotals = computed(() =>
  workOrders.value.map((wo) => {
    const other_amount = Number(wo.work_order.other_amount) || 0
    const actual_other_amount = Number(wo.work_order.other_actual_amount) || 0
    return {
      ...wo,
      other_amount,
      actual_other_amount,
      total_planned: wo.trades_sum + wo.parts_sum + other_amount,
      total_actual: wo.actual_trades_sum + wo.actual_parts_sum + actual_other_amount,
    }
  }),
)

// Сонгосон бүх WO дээрх нийлбэр (олон WO сонгосон үед л харуулна)
const grandTotals = computed(() =>
  withTotals.value.reduce(
    (acc, wo) => ({
      trades_sum: acc.trades_sum + wo.trades_sum,
      parts_sum: acc.parts_sum + wo.parts_sum,
      other_amount: acc.other_amount + wo.other_amount,
      total_planned: acc.total_planned + wo.total_planned,
      actual_trades_sum: acc.actual_trades_sum + wo.actual_trades_sum,
      actual_parts_sum: acc.actual_parts_sum + wo.actual_parts_sum,
      actual_other_amount: acc.actual_other_amount + wo.actual_other_amount,
      total_actual: acc.total_actual + wo.total_actual,
    }),
    {
      trades_sum: 0,
      parts_sum: 0,
      other_amount: 0,
      total_planned: 0,
      actual_trades_sum: 0,
      actual_parts_sum: 0,
      actual_other_amount: 0,
      total_actual: 0,
    },
  ),
)

const doPrint = () => {
  window.print()
}
</script>

<template>
  <div
    class="wo-print-summary border-muted-200 dark:border-muted-700 dark:bg-muted-800 border bg-white w-[80%] overflow-y-scroll"
  >
    <div
      class="no-print flex h-16 w-full items-center justify-between px-10"
    >
      <div class="flex items-center gap-2">
        <button
          type="button"
          class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300 dark:hover:text-white"
          @click="close"
        >
          <Icon name="line-md:close" class="h-5 w-5" />
        </button>
        <span class="text-muted-800 dark:text-white font-medium">
          {{ t('Work order') }} — {{ t('Print') }}
        </span>
      </div>
      <BaseButton color="primary" :disabled="loading" @click="doPrint">
        <Icon name="solar:printer-2-broken" class="me-1 h-4 w-4" />
        {{ t('Print') }}
      </BaseButton>
    </div>

    <div
      v-if="loading"
      class="text-muted-400 flex h-32 w-full items-center justify-center text-sm"
    >
      {{ t('Loading') }}...
    </div>

    <div v-else id="wo-print-area" class="px-10 pb-10">
      <div v-if="!withTotals.length" class="text-muted-400 text-sm">
        {{ t('No data') }}
      </div>

      <template v-for="(wo, idx) in withTotals" :key="wo.work_order.id">
        <hr
          v-if="idx > 0"
          class="border-muted-300 dark:border-muted-600 my-8 border-t-2 border-dashed"
        />

        <div class="wo-print-block" :class="idx < withTotals.length - 1 ? 'mb-2' : ''">
          <div class="border-muted-200 dark:border-muted-700 mb-4 border-b pb-2">
            <h2 class="text-muted-800 text-lg font-semibold dark:text-white">
              {{ idx + 1 }}. WO #{{ wo.work_order.wo_number || wo.work_order.id }} —
              {{ wo.work_order.name }}
            </h2>
          </div>

        <div class="mb-4 grid grid-cols-2 gap-x-6 gap-y-1 text-sm">
          <div>
            <span class="text-muted-400">{{ t('Location') }}:</span>
            {{ wo.work_order.location?.name || '-' }}
          </div>
          <div>
            <span class="text-muted-400">{{ t('Asset') }}:</span>
            {{ wo.work_order.asset?.name || '-' }}
          </div>
          <div>
            <span class="text-muted-400">{{ t('Priority') }}:</span>
            {{ priorityLabel(wo.work_order.priority) }}
          </div>
          <div>
            <span class="text-muted-400">{{ t('Status') }}:</span>
            {{ statusLabel(wo.work_order.wo_status) }}
          </div>
          <div>
            <span class="text-muted-400">{{ t('Assigned to') }}:</span>
            {{ wo.work_order.assigned_to?.first_name || '-' }}
          </div>
          <div>
            <span class="text-muted-400">{{ t('Requested by') }}:</span>
            {{ wo.work_order.request_user?.first_name || '-' }}
          </div>
          <div>
            <span class="text-muted-400">{{ t('Created') }}:</span>
            {{ formatDate(wo.work_order.date_created) }}
          </div>
          <div>
            <span class="text-muted-400">{{ t('Due') }}:</span>
            {{ formatDate(wo.work_order.due) }}
          </div>
        </div>

        <div v-if="wo.trades.length" class="mb-4">
          <h3 class="text-muted-800 mb-1 text-sm font-semibold dark:text-white">
            {{ t('Trades') }}
          </h3>
          <table class="w-full border-collapse text-xs">
            <thead>
              <tr
                class="border-muted-200 dark:border-muted-700 border-b text-left"
              >
                <th class="py-1 pe-2">{{ t('Code') }}</th>
                <th class="py-1 pe-2">{{ t('Name') }}</th>
                <th class="py-1 pe-2 text-right">{{ t('Duration') }}</th>
                <th class="py-1 pe-2 text-right">{{ t('Rate') }}</th>
                <th class="py-1 text-right">{{ t('Total') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="row in wo.trades"
                :key="row.id"
                class="border-muted-100 dark:border-muted-800 border-b"
              >
                <td class="py-1 pe-2">{{ row.trade?.code || '-' }}</td>
                <td class="py-1 pe-2">{{ row.name || row.trade?.name || '-' }}</td>
                <td class="py-1 pe-2 text-right">{{ row.duration ?? '-' }}</td>
                <td class="py-1 pe-2 text-right">{{ formatMoney(row.rate) }}</td>
                <td class="py-1 text-right">{{ formatMoney(row.total) }}</td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="font-semibold">
                <td colspan="4" class="py-1 pe-2 text-right">{{ t('Total') }}</td>
                <td class="py-1 text-right">{{ formatMoney(wo.trades_sum) }}</td>
              </tr>
            </tfoot>
          </table>
        </div>

        <div v-if="wo.parts.length" class="mb-4">
          <h3 class="text-muted-800 mb-1 text-sm font-semibold dark:text-white">
            {{ t('Parts') }}
          </h3>
          <table class="w-full border-collapse text-xs">
            <thead>
              <tr
                class="border-muted-200 dark:border-muted-700 border-b text-left"
              >
                <th class="py-1 pe-2">{{ t('Number') }}</th>
                <th class="py-1 pe-2">{{ t('Description') }}</th>
                <th class="py-1 pe-2 text-right">{{ t('Quantity') }}</th>
                <th class="py-1 pe-2 text-right">{{ t('Price') }}</th>
                <th class="py-1 text-right">{{ t('Amount') }}</th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="row in wo.parts"
                :key="row.id"
                class="border-muted-100 dark:border-muted-800 border-b"
              >
                <td class="py-1 pe-2">{{ row.parts?.part_number || '-' }}</td>
                <td class="py-1 pe-2">{{ row.parts?.description || '-' }}</td>
                <td class="py-1 pe-2 text-right">{{ row.quantity ?? '-' }}</td>
                <td class="py-1 pe-2 text-right">{{ formatMoney(row.price) }}</td>
                <td class="py-1 text-right">{{ formatMoney(row.amount) }}</td>
              </tr>
            </tbody>
            <tfoot>
              <tr class="font-semibold">
                <td colspan="4" class="py-1 pe-2 text-right">{{ t('Total') }}</td>
                <td class="py-1 text-right">{{ formatMoney(wo.parts_sum) }}</td>
              </tr>
            </tfoot>
          </table>
        </div>

        <div class="mt-2 grid grid-cols-2 gap-4 text-sm">
          <div class="border-muted-200 dark:border-muted-700 rounded-lg border p-3">
            <div class="mb-1 font-semibold">{{ t('Planned') }}</div>
            <div class="flex justify-between">
              <span>{{ t('Trade') }}</span>
              <span>{{ formatMoney(wo.trades_sum) }}</span>
            </div>
            <div class="flex justify-between">
              <span>{{ t('Parts') }}</span>
              <span>{{ formatMoney(wo.parts_sum) }}</span>
            </div>
            <div class="flex justify-between">
              <span>{{ t('Other') }}</span>
              <span>{{ formatMoney(wo.other_amount) }}</span>
            </div>
            <div
              class="border-muted-200 dark:border-muted-700 mt-1 flex justify-between border-t pt-1 font-bold"
            >
              <span>{{ t('Total') }}</span>
              <span>{{ formatMoney(wo.total_planned) }}</span>
            </div>
          </div>
          <div class="border-muted-200 dark:border-muted-700 rounded-lg border p-3">
            <div class="mb-1 font-semibold">{{ t('Actual') }}</div>
            <div class="flex justify-between">
              <span>{{ t('Trade') }}</span>
              <span>{{ formatMoney(wo.actual_trades_sum) }}</span>
            </div>
            <div class="flex justify-between">
              <span>{{ t('Parts') }}</span>
              <span>{{ formatMoney(wo.actual_parts_sum) }}</span>
            </div>
            <div class="flex justify-between">
              <span>{{ t('Other') }}</span>
              <span>{{ formatMoney(wo.actual_other_amount) }}</span>
            </div>
            <div
              class="border-muted-200 dark:border-muted-700 mt-1 flex justify-between border-t pt-1 font-bold"
            >
              <span>{{ t('Total') }}</span>
              <span>{{ formatMoney(wo.total_actual) }}</span>
            </div>
          </div>
        </div>
        </div>
      </template>

      <div
        v-if="withTotals.length > 1"
        class="border-muted-300 dark:border-muted-600 mt-8 border-t-2 pt-4"
      >
        <h3 class="text-muted-800 mb-2 text-base font-semibold dark:text-white">
          {{ t('Grand total') }}
        </h3>
        <div class="grid grid-cols-2 gap-4 text-sm">
          <div class="border-muted-200 dark:border-muted-700 rounded-lg border p-3">
            <div class="mb-1 font-semibold">{{ t('Planned') }}</div>
            <div class="flex justify-between">
              <span>{{ t('Trade') }}</span>
              <span>{{ formatMoney(grandTotals.trades_sum) }}</span>
            </div>
            <div class="flex justify-between">
              <span>{{ t('Parts') }}</span>
              <span>{{ formatMoney(grandTotals.parts_sum) }}</span>
            </div>
            <div class="flex justify-between">
              <span>{{ t('Other') }}</span>
              <span>{{ formatMoney(grandTotals.other_amount) }}</span>
            </div>
            <div
              class="border-muted-200 dark:border-muted-700 mt-1 flex justify-between border-t pt-1 font-bold"
            >
              <span>{{ t('Total') }}</span>
              <span>{{ formatMoney(grandTotals.total_planned) }}</span>
            </div>
          </div>
          <div class="border-muted-200 dark:border-muted-700 rounded-lg border p-3">
            <div class="mb-1 font-semibold">{{ t('Actual') }}</div>
            <div class="flex justify-between">
              <span>{{ t('Trade') }}</span>
              <span>{{ formatMoney(grandTotals.actual_trades_sum) }}</span>
            </div>
            <div class="flex justify-between">
              <span>{{ t('Parts') }}</span>
              <span>{{ formatMoney(grandTotals.actual_parts_sum) }}</span>
            </div>
            <div class="flex justify-between">
              <span>{{ t('Other') }}</span>
              <span>{{ formatMoney(grandTotals.actual_other_amount) }}</span>
            </div>
            <div
              class="border-muted-200 dark:border-muted-700 mt-1 flex justify-between border-t pt-1 font-bold"
            >
              <span>{{ t('Total') }}</span>
              <span>{{ formatMoney(grandTotals.total_actual) }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@media print {
  .no-print {
    display: none !important;
  }
  .wo-print-summary {
    width: 100% !important;
    overflow: visible !important;
  }
  .wo-print-block {
    page-break-after: always;
  }
  .wo-print-block:last-child {
    page-break-after: auto;
  }
}
</style>
