<script setup lang="ts">
import {
  ClientSideRowModelModule,
  ModuleRegistry,
  type ColDef,
  type GridOptions,
} from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { AgGridVue } from 'ag-grid-vue3'
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

ModuleRegistry.registerModules([ClientSideRowModelModule])

interface CompanyUser {
  id: string
  first_name?: string
  last_name?: string
  email?: string
  active?: number | boolean
  active_user_cnt?: number
  inactive_user_cnt?: number
  _isTotal?: boolean
  role?: { name?: string }
  location?: string
}

const { t } = useI18n({ useScope: 'global' })
const route = useRoute()
const router = useRouter()
const runtimeConfig = useRuntimeConfig()
const { token } = useDirectusToken()
const toaster = useToaster()

const users = ref<CompanyUser[]>([])
const isLoading = ref(false)
const companyId = computed(() => String(route.query.company_id || ''))
const companyName = computed(() => String(route.query.company_name || ''))
const activeUserCount = computed(
  () => users.value.filter((user) => Number(user.active) === 1).length,
)
const inactiveUserCount = computed(
  () => users.value.filter((user) => Number(user.active) !== 1).length,
)
const pinnedTotals = computed(() => [
  {
    _isTotal: true,
    first_name: t('Total'),
    active_user_cnt: activeUserCount.value,
    inactive_user_cnt: inactiveUserCount.value,
  },
])

const columnDefs = computed<ColDef<CompanyUser>[]>(() => [
  {
    headerName: t('First name'),
    field: 'first_name',
    minWidth: 150,
    flex: 1,
    filter: 'agTextColumnFilter',
  },
  {
    headerName: t('Last name'),
    field: 'last_name',
    minWidth: 130,
    flex: 1,
    filter: 'agTextColumnFilter',
  },
  {
    headerName: t('Email'),
    field: 'email',
    minWidth: 220,
    flex: 1.5,
    filter: 'agTextColumnFilter',
  },
  {
    headerName: t('Role'),
    colId: 'role',
    minWidth: 150,
    flex: 1,
    filter: 'agTextColumnFilter',
    valueGetter: (params) => params.data?.role?.name || '-',
  },
  {
    headerName: t('Location'),
    field: 'location',
    minWidth: 150,
    flex: 1,
    filter: 'agTextColumnFilter',
    valueFormatter: (params) =>
      params.value == 'all'
        ? t('All')
        : params.value != 'all'
        ? params.value
        : '-',
  },
  {
    headerName: t('Status'),
    field: 'active',
    minWidth: 110,
    filter: 'agTextColumnFilter',
    valueFormatter: (params) =>
      params.data?._isTotal
        ? ''
        : typeof params.value === 'string'
        ? params.value
        : Number(params.value) === 1 || params.value === true
        ? t('Active')
        : t('Inactive'),
  },
  {
    headerName: t('Active users'),
    field: 'active_user_cnt',
    minWidth: 110,
    filter: 'agNumberColumnFilter',
    valueGetter: (params) =>
      params.node.rowPinned ? Number(params.data?.active_user_cnt || 0) : '',
  },
  {
    headerName: t('Inactive users'),
    field: 'inactive_user_cnt',
    minWidth: 120,
    filter: 'agNumberColumnFilter',
    valueGetter: (params) =>
      params.node.rowPinned ? Number(params.data?.inactive_user_cnt || 0) : '',
  },
])

const defaultColDef: ColDef<CompanyUser> = {
  sortable: true,
  resizable: true,
  floatingFilter: true,
}

const gridOptions: GridOptions<CompanyUser> = {
  pagination: true,
  paginationPageSize: 20,
  paginationPageSizeSelector: [10, 20, 50, 100],
  animateRows: false,
  rowHeight: 44,
  suppressHorizontalScroll: false,
  autoSizeStrategy: { type: 'fitGridWidth' },
  localeText: {
    noRowsToShow: t('No Rows To Show'),
    page: t('Page'),
    to: t('to'),
    of: t('of'),
    pageSizeSelectorLabel: t('Page Size:'),
    sortAscending: t('Sort Ascending'),
    sortDescending: t('Sort Descending'),
    clearSort: t('Clear Sort'),
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

const loadUsers = async () => {
  if (!companyId.value) {
    users.value = []
    return
  }

  isLoading.value = true

  try {
    const response = await fetch(
      `${
        runtimeConfig.public.directus.url
      }users?filter[company_id][_eq]=${encodeURIComponent(
        companyId.value,
      )}&sort=first_name&limit=1000&fields=id,first_name,last_name,email,active,role.name,location`,
      { headers: { Authorization: `Bearer ${token.value}` } },
    )
    const result = await response.json()

    if (!response.ok || !Array.isArray(result.data)) {
      throw new Error(result.errors?.[0]?.message || 'Unable to load users')
    }

    users.value = result.data
  } catch (error) {
    console.error('Unable to load company users:', error)
    users.value = []
    toaster.show({
      title: t('Unable to load users'),
      message: t('Please try again'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
  } finally {
    isLoading.value = false
  }
}

onMounted(loadUsers)

definePageMeta({
  middleware: ['auth'],
  title: 'Company users',
  showback: true,
})
</script>

<template>
  <div class="mx-auto w-full max-w-7xl">
    <div class="mb-5 flex items-center justify-between">
      <div>
        <BaseButtonIcon
          type="button"
          data-tooltip="Back"
          @click="router.push('/companies')"
        >
          <Icon name="lucide:arrow-left" class="size-4" />
        </BaseButtonIcon>
        <BaseText tag="span" size="lg" class="ml-3 font-medium">
          {{ companyName || $t('Company users') }}
        </BaseText>
      </div>
      <div class="flex items-center gap-2">
        <BaseButtonIcon
          type="button"
          :disabled="isLoading"
          data-tooltip="Refresh"
          @click="loadUsers"
        >
          <Icon
            name="lucide:refresh-cw"
            :class="['size-4', { 'animate-spin': isLoading }]"
          />
        </BaseButtonIcon>
        <BaseText size="sm" class="text-muted-500">
          {{ users.length }} {{ $t('users') }} | {{ $t('Active') }}:
          {{ activeUserCount }} | {{ $t('Inactive') }}: {{ inactiveUserCount }}
        </BaseText>
      </div>
    </div>

    <BasePlaceholderPage
      v-if="isLoading"
      title="Loading users"
      subtitle=""
      class="min-h-96"
    />
    <BasePlaceholderPage
      v-else-if="!companyId || users.length === 0"
      title="No users found"
      subtitle=""
      class="min-h-96"
    />
    <AgGridVue
      v-else
      :class="`h-[620px] ag-theme-quartz${
        $colorMode.value === 'light' ? '' : '-dark'
      }`"
      :column-defs="columnDefs"
      :default-col-def="defaultColDef"
      :grid-options="gridOptions"
      :row-data="users"
      :pinned-bottom-row-data="pinnedTotals"
      :get-row-style="
        (params: any) =>
          params.node.rowPinned === 'bottom'
            ? { fontWeight: '600', background: 'rgba(59, 130, 246, 0.08)' }
            : undefined
      "
    />
  </div>
</template>
