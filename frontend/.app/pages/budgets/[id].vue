<script setup lang="ts">
import type { ColDef } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'
import PriorityCellRenderer from '~/components/ag_grid/priorityCellRenderer.vue'

import WoStatusCellRenderer from '~/components/ag_grid/wo_statusCellRenderer.vue'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'
const { open } = usePanels()
const { t } = useI18n({ useScope: 'global' })
const route = useRoute()
const { getItems } = useDirectusItems()

import {
  action_status,
  priorities,
  statuses,
} from '~/components/workorder/WorkOrderConstants'

definePageMeta({
  middleware: ['auth'],
  title: 'Budget Detail',
})

const budgetId = Number(route.params.id)
const budget = ref<any>(null)
const workOrders = ref<any[]>([])
const loading = ref(true)
const expandedWO = ref<Record<number, boolean>>({})
const expandedTask = ref<Record<number, boolean>>({})

const formatAmount = (val: any) =>
  val != null ? Number(val).toLocaleString() : '-'

const usedPercent = (used: number, total: number) => {
  if (!total) return 0
  return Math.min(100, Math.round((used / total) * 100))
}

const barColor = (pct: number) =>
  pct > 90 ? 'bg-red-500' : pct > 70 ? 'bg-amber-500' : 'bg-primary-500'

const statusLabel = (s: any) => {
  const map: Record<number, string> = {
    1: t('Open'),
    2: t('Approved'),
    3: t('Completed'),
    4: t('Cancelled'),
  }
  return map[s] || t('Unknown')
}
const statusColor = (s: any) => {
  const map: Record<number, string> = {
    1: 'info',
    2: 'success',
    3: 'primary',
    4: 'danger',
  }
  return map[s] || 'muted'
}

// Summary computed
const totalPlanned = computed(() =>
  workOrders.value.reduce(
    (sum, wo) => sum + (Number(wo.budget_planned_amount) || 0),
    0,
  ),
)
const totalUsed = computed(() =>
  workOrders.value.reduce(
    (sum, wo) => sum + (Number(woActual.value[wo.id]) || 0),
    0,
  ),
)

const woActual = ref<Record<number, number>>({})
const woTasks = ref<Record<number, any[]>>({})
const moduleStatuses = ref<any[]>([])

// ─── AG Grid ──────────────────────────────────────────────────────────────────
const woGridApi = ref<any>(null)

const woRowData = computed(() =>
  workOrders.value.map((wo, idx) => ({
    ...wo,
    _index: idx + 1,
    _actual: woActual.value[wo.id] ?? 0,
    _remaining:
      (Number(budget.value?.total_amount) || 0) -
      (Number(wo.budget_actual_amount) || 0),
  })),
)

const woStatusLabel = (id: number): string => {
  const found = moduleStatuses.value.find((s: any) => s.id === id)
  return found?.status_text ?? '-'
}

const onRowClicked = (params) => {
  console.log('params_data', params)
  open('workorderopenmore', {
    id: params.data.id,
    data: params.data,
    wo_statuses: wo_status_items,
    type: 'open',
    refresh: null,
    onClose: (message: any) => {
      // console.log('onMessagess')
      // console.log(message)
      // close()
    },
  })
}

const woColumnDefs: ColDef[] = [
  {
    field: '_index',
    headerName: '#',
    width: 56,
    sortable: false,
    filter: false,
    cellStyle: { textAlign: 'center', color: '#9ca3af', fontSize: '12px' },
  },
  {
    field: 'wo_number',
    headerName: t('Code'),
    width: 100,
    sortable: true,
    filter: false,
    valueFormatter: ({ value }) => `WO-${value}`,
    onCellClicked: (params) => {
      onRowClicked(params)
    },
    cellStyle: {
      fontFamily: 'monospace',
      fontSize: '12px',
      color: '#6366f1',
      cursor: 'pointer',
    },
  },
  {
    field: 'name',
    headerName: t('Name'),
    flex: 1,
    minWidth: 150,
    sortable: true,
    filter: 'agTextColumnFilter',
    filterParams: {
      maxNumConditions: 1,
      filterOptions: ['contains'],
      buttons: ['reset'],
    },
  },
  {
    field: 'wo_status',
    headerName: t('Status'),
    width: 130,
    sortable: false,
    filter: false,
    valueGetter: (params: any) => {
      const id = params.data?.wo_status
      return moduleStatuses.value.find((s: any) => s.id === id) ?? null
    },
    valueFormatter: (params: any) => params.value?.status_text ?? '-',
    cellRenderer: WoStatusCellRenderer,
    cellRendererParams: { width: '90px', height: '30px' },
    cellStyle: { display: 'flex', justifyContent: 'start', marginTop: '4px' },
  },
  {
    field: 'action_status',
    headerName: t('Accept'),
    width: 130,
    sortable: false,
    filter: false,

    valueFormatter: (params) => {
      let aaction = action_status.find((s) => s.id === params.value)
      return aaction ? t(aaction.name) : ''
    },
    cellRenderer: PriorityCellRenderer,
    cellRendererParams: { width: '90px', height: '30px' },
    cellStyle: { display: 'flex', justifyContent: 'start', marginTop: '4px' },
  },
  {
    field: 'started_at',
    headerName: t('Start'),
    width: 140,
    sortable: true,
    filter: false,
    valueFormatter: ({ value }) => (value ? String(value).slice(0, 10) : '-'),
  },
  {
    field: 'due',
    headerName: t('Due'),
    width: 140,
    sortable: true,
    filter: false,
    valueFormatter: ({ value }) => (value ? String(value).slice(0, 10) : '-'),
  },
  {
    field: 'budget_planned_amount',
    headerName: t('Planned') + ' (₮)',
    width: 140,
    sortable: true,
    filter: false,
    valueFormatter: ({ value }) =>
      value != null ? Number(value).toLocaleString() : '-',
    cellStyle: { textAlign: 'right' },
    headerClass: 'ag-right-aligned-header',
  },
  {
    field: '_actual',
    headerName: t('Actual Used') + ' (₮)',
    width: 140,
    sortable: false,
    filter: false,
    valueFormatter: ({ value }) =>
      value != null ? Number(value).toLocaleString() : '-',
    cellStyle: { textAlign: 'right', color: '#d97706', fontWeight: '500' },
    headerClass: 'ag-right-aligned-header',
  },
  {
    field: '_remaining',
    headerName: t('Remaining') + ' (₮)',
    width: 140,
    sortable: false,
    filter: false,
    valueFormatter: ({ value }) =>
      value != null ? Number(value).toLocaleString() : '-',
    cellStyle: (params: any) => ({
      textAlign: 'right',
      fontWeight: '600',
      color: params.value < 0 ? '#ef4444' : '#16a34a',
    }),
    headerClass: 'ag-right-aligned-header',
  },
]

const woGridOptions = {
  pagination: false,
  defaultColDef: { resizable: true },
  domLayout: 'autoHeight' as const,
  onRowClicked: (params: any) => {
    if (params.data?.id) {
      console.log('Row clicked, WO ID:', params.data.id)
      //   useRouter().push(`/workorder/view/${params.data.id}`)
    }
  },
  localeText: {
    noRowsToShow: t('No Rows To Show'),
    page: t('Page'),
    to: t('to'),
    of: t('of'),
    pageSizeSelectorLabel: t('Page Size:'),
    sortAscending: t('Sort Ascending'),
    sortDescending: t('Sort Descending'),
    clearColumn: t('Clear Sort'),
    pinColumn: t('Pin Column'),
    pinLeft: t('Pin Left'),
    pinRight: t('Pin Right'),
    noPin: t('No Pin'),
    autosizeThisColumn: t('Autosize This Column'),
    autosizeAllColumns: t('Autosize All Columns'),
    columnChooser: t('Choose Columns'),
    resetColumns: t('Reset Columns'),
    alertButton: t('Click Alert Button and Close Menu'),
  },
}

const onWoGridReady = (params: any) => {
  woGridApi.value = params.api
}

const loadWOTasks = async (woId: number) => {
  if (woTasks.value[woId]) return
  try {
    const resp = await getItems<any>({
      collection: 'Work_order_item',
      params: {
        filter: { workorder: { _eq: woId }, active: { _eq: 1 } },
        limit: -1,
        fields: ['id', 'name', 'description', 'task_cost', 'status'],
      },
    })
    woTasks.value[woId] = Array.isArray(resp) ? resp : (resp as any)?.data || []
  } catch (e) {
    woTasks.value[woId] = []
  }
}

const toggleWO = (woId: number) => {
  expandedWO.value[woId] = !expandedWO.value[woId]
  loadWOTasks(woId)
}

const loadData = async () => {
  loading.value = true
  try {
    // Load Module_status for WO status renderer
    const msResp = await getItems<any>({
      collection: 'Module_status',
      params: {
        sort: ['position'],
        limit: -1,
        fields: ['*', 'code_color.*'],
      },
    })
    moduleStatuses.value = Array.isArray(msResp)
      ? msResp
      : (msResp as any)?.data || []

    // Load budget
    const bResp = await getItems<any>({
      collection: 'Budget',
      params: {
        filter: { id: { _eq: budgetId } },
        limit: 1,
        fields: ['*', 'assigned_to.first_name', 'approved_user.first_name'],
      },
    })
    const bList = Array.isArray(bResp) ? bResp : (bResp as any)?.data || []
    budget.value = bList[0] ?? null

    // Load work orders linked to this budget
    const woResp = await getItems<any>({
      collection: 'Work_order',
      params: {
        filter: { budget: { id: { _eq: budgetId } } },
        limit: -1,
        meta: 'filter_count',
        fields: [
          'id',
          'wo_number',
          'name',
          'budget_planned_amount',
          'budget_actual_amount',
          'other_actual_amount',
          'other_amount',
          'wo_status',
          'action_status',
          'status',
          'started_at',
          'due',
        ],
      },
    })
    console.log('[Budget WO] response:', woResp)
    workOrders.value = Array.isArray(woResp)
      ? woResp
      : (woResp as any)?.data || []
    console.log('[Budget WO] count:', workOrders.value.length)

    // Calculate actual cost per WO
    if (workOrders.value.length) {
      const woIds = workOrders.value.map((w) => w.id)

      // Parts actual
      const partsResp = await getItems<any>({
        collection: 'Work_order_Parts',
        params: {
          filter: { work_order: { _in: woIds }, status: '1' },
          groupBy: ['work_order'],
          aggregate: { sum: 'actual_amount' },
          limit: -1,
        },
      })
      const partsData = Array.isArray(partsResp)
        ? partsResp
        : (partsResp as any)?.data || []
      const partsMap: Record<number, number> = {}
      partsData.forEach((r: any) => {
        partsMap[r.work_order] = Number(r.sum?.actual_amount ?? 0)
      })

      // Trades actual
      const tradesResp = await getItems<any>({
        collection: 'Work_order_Tradecode',
        params: {
          filter: { work_order: { _in: woIds }, status: '1' },
          groupBy: ['work_order'],
          aggregate: { sum: 'actual_total' },
          limit: -1,
        },
      })
      const tradesData = Array.isArray(tradesResp)
        ? tradesResp
        : (tradesResp as any)?.data || []
      const tradesMap: Record<number, number> = {}
      tradesData.forEach((r: any) => {
        tradesMap[r.work_order] = Number(r.sum?.actual_total ?? 0)
      })

      const actuals: Record<number, number> = {}
      workOrders.value.forEach((wo) => {
        actuals[wo.id] =
          (partsMap[wo.id] || 0) +
          (tradesMap[wo.id] || 0) +
          (Number(wo.other_actual_amount) || 0)
      })
      woActual.value = actuals

      // Budget-ийн budget_actual_amount-ийг шинэчил
      const totalActual = Object.values(actuals).reduce((s, v) => s + v, 0)
      if (budget.value) {
        budget.value = { ...budget.value, budget_actual_amount: totalActual }
      }
    }
  } catch (e) {
    console.error('Budget detail load error:', e)
  } finally {
    loading.value = false
  }
}

onMounted(loadData)
</script>

<template>
  <div class="relative space-y-6">
    <!-- Header -->
    <TairoContentWrapper>
      <template #left>
        <div class="flex items-center gap-3">
          <NuxtLink to="/budgets">
            <BaseButtonIcon shape="rounded" size="sm">
              <Icon name="mdi:arrow-left" class="size-4" />
            </BaseButtonIcon>
          </NuxtLink>
          <div>
            <BaseHeading
              tag="h1"
              size="lg"
              weight="semibold"
              class="text-muted-800 dark:text-muted-100"
            >
              <Icon
                name="mdi:cash-multiple"
                class="size-6 text-primary-500 mr-2"
              />
              {{ budget?.budget_name || t('Budget Detail') }}
            </BaseHeading>
            <p class="text-sm text-muted-400 mt-0.5">
              {{ budget?.budget_code }}
              <span v-if="budget?.description" class="ml-2"
                >— {{ budget.description }}</span
              >
            </p>
          </div>
        </div>
      </template>
    </TairoContentWrapper>

    <!-- Loading -->
    <div v-if="loading" class="flex justify-center py-20">
      <BaseButtonIcon loading size="xl" />
    </div>

    <template v-else>
      <!-- Summary cards -->
      <div class="grid grid-cols-2 gap-4 md:grid-cols-4">
        <BaseCard shape="rounded" class="p-4">
          <p class="text-xs text-muted-400 mb-1">{{ t('Total Budget') }}</p>
          <p class="text-xl font-bold text-muted-800 dark:text-muted-100">
            {{ formatAmount(budget?.total_amount) }}₮
          </p>
        </BaseCard>
        <BaseCard shape="rounded" class="p-4">
          <p class="text-xs text-muted-400 mb-1">
            {{ t('Planned to Works') }}
          </p>
          <p class="text-xl font-bold text-primary-500">
            {{ formatAmount(totalPlanned) }}₮
          </p>
        </BaseCard>
        <BaseCard shape="rounded" class="p-4">
          <p class="text-xs text-muted-400 mb-1">{{ t('Used (Actual)') }}</p>
          <p class="text-xl font-bold text-amber-500">
            {{ formatAmount(totalUsed) }}₮
          </p>
        </BaseCard>
        <BaseCard shape="rounded" class="p-4">
          <p class="text-xs text-muted-400 mb-1">{{ t('Remaining') }}</p>
          <p
            class="text-xl font-bold"
            :class="
              (budget?.total_amount ?? 0) -
                (budget?.budget_actual_amount ?? 0) <
              0
                ? 'text-red-500'
                : 'text-green-500'
            "
          >
            {{
              formatAmount(
                (budget?.total_amount ?? 0) -
                  (budget?.budget_actual_amount ?? 0),
              )
            }}₮
          </p>
        </BaseCard>
      </div>

      <!-- Dates & status row -->
      <BaseCard
        shape="rounded"
        class="p-4 flex flex-wrap gap-6 items-center text-sm"
      >
        <div>
          <span class="text-muted-400 mr-1">{{ t('Period') }}:</span>
          <span class="font-medium text-muted-700 dark:text-muted-200">
            {{
              budget?.start_date ? String(budget.start_date).slice(0, 10) : '-'
            }}
            →
            {{ budget?.end_date ? String(budget.end_date).slice(0, 10) : '-' }}
          </span>
        </div>
        <div>
          <span class="text-muted-400 mr-1">{{ t('Status') }}:</span>
          <BaseTag
            shape="rounded"
            variant="pastel"
            color="info"
            class="text-xs"
          >
            {{ t(budget?.status) }}
          </BaseTag>
        </div>
        <div v-if="budget?.assigned_to">
          <span class="text-muted-400 mr-1">{{ t('Assigned To') }}:</span>
          <BaseTag
            shape="rounded"
            variant="pastel"
            color="info"
            class="text-xs"
          >
            {{ budget?.assigned_to?.first_name || '-' }}
          </BaseTag>
        </div>
        <div v-if="budget?.approved_user">
          <span class="text-muted-400 mr-1">{{ t('Approved') }}:</span>
          <BaseTag
            shape="rounded"
            variant="pastel"
            color="info"
            class="text-xs"
          >
            {{ budget?.approved_user?.first_name || '-' }}
          </BaseTag>
        </div>
        <div v-if="budget?.description">
          <span class="text-muted-400 mr-1">{{ t('Description') }}:</span>
          <span class="text-muted-600 dark:text-muted-300">{{
            budget.description
          }}</span>
        </div>
      </BaseCard>

      <!-- Work Orders AG Grid -->
      <BaseCard shape="rounded" class="p-4">
        <div class="flex items-center gap-2 mb-3">
          <Icon name="octicon:tasklist-16" class="size-4 text-primary-500" />
          <BaseHeading
            tag="h3"
            size="sm"
            weight="semibold"
            class="text-muted-700 dark:text-muted-200"
          >
            {{ t('Work Orders') }}
          </BaseHeading>
          <BaseTag
            shape="rounded"
            variant="pastel"
            color="primary"
            class="text-xs ml-1"
          >
            {{ workOrders.length }}
          </BaseTag>
        </div>

        <div v-if="workOrders.length">
          <ag-grid-vue
            :class="`ag-theme-quartz${
              $colorMode.value === 'light' ? '' : '-dark'
            }`"
            style="width: 100%"
            :columnDefs="woColumnDefs"
            :rowData="woRowData"
            :gridOptions="woGridOptions"
            @grid-ready="onWoGridReady"
          />

          <!-- Totals footer -->
          <div
            class="flex justify-end gap-8 mt-2 pt-2 border-t border-muted-200 dark:border-muted-700 text-sm font-bold"
          >
            <span class="text-muted-400">{{ t('Total') }}:</span>
            <span class="text-primary-600 min-w-[130px] text-right"
              >{{ t('Planned') }}: {{ formatAmount(totalPlanned) }}₮</span
            >
            <span class="text-amber-600 min-w-[130px] text-right"
              >{{ t('Actual') }}: {{ formatAmount(totalUsed) }}₮</span
            >
            <span
              class="min-w-[130px] text-right"
              :class="
                (budget?.total_amount ?? 0) - totalUsed < 0
                  ? 'text-red-500'
                  : 'text-green-600'
              "
              >{{ t('Remaining') }}:
              {{ formatAmount((budget?.total_amount ?? 0) - totalUsed) }}₮</span
            >
          </div>
        </div>

        <div
          v-else
          class="flex flex-col items-center py-8 text-muted-400 gap-2"
        >
          <Icon name="octicon:tasklist-16" class="size-8 text-muted-300" />
          <p class="text-sm">{{ t('No work orders linked to this budget') }}</p>
        </div>
      </BaseCard>
    </template>
  </div>
</template>
