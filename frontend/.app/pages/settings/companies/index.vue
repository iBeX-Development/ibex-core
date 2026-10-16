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
import CompanyActionsCell from '~/components/ag_grid/CompanyActionsCell.vue'
import CompanyNameCell from '~/components/ag_grid/CompanyNameCell.vue'
import DynamicModalForm from '~/components/form/DynamicModalForm.vue'

ModuleRegistry.registerModules([ClientSideRowModelModule])

interface Company {
  id: number | string
  com_id?: string | number
  name?: string
  db_key?: string
  registration_number?: string
  email?: string
  type?: string
  license_date?: string
  status?: number
  active_user_cnt?: number
  inactive_user_cnt?: number
}

interface CompanyFormValues {
  name: string
  registration_number?: string
  email: string
  type?: string
  license_date?: string
  status?: number
  active_user_cnt?: number
  inactive_user_cnt?: number
}

const { t } = useI18n({ useScope: 'global' })
const runtimeConfig = useRuntimeConfig()
const { token } = useDirectusToken()
const { getItems } = useDirectusItems()
const toaster = useToaster()

const companies = ref<Company[]>([])
const isLoading = ref(false)
const isCreateModalOpen = ref(false)
const selectedCompanyId = ref<number | string>(-1)
const companyToDelete = ref<Company | null>(null)
const isDeleteModalOpen = ref(false)
const isMutating = ref(false)
const packageOptions = ref<{ label: string; value: number }[]>([])

const companyFields = computed(() => [
  {
    name: 'name',
    label: 'Company Name',
    type: 'text',
    required: true,
  },
  //   {
  //     name: 'com_id',
  //     label: 'Company ID',
  //     type: 'text',
  //   },
  //   {
  //     name: 'db_key',
  //     label: 'DB Key',
  //     type: 'text',
  //   },
  {
    name: 'registration_number',
    label: 'Registration',
    type: 'text',
  },
  {
    name: 'email',
    label: 'Email',
    type: 'email',
    required: true,
  },
  //   {
  //     name: 'website',
  //     label: 'Website',
  //     type: 'text',
  //   },
  {
    name: 'type',
    label: 'Type',
    type: 'select',
    options: [
      { label: 'Small', value: 'team_member_1' },
      { label: 'Middle', value: 'team_member_2' },
      { label: 'Big', value: 'team_member_3' },
    ],
  },
  {
    name: 'license_date',
    label: 'License date',
    type: 'date',
  },
  {
    name: 'report_url',
    label: 'Report URL',
    type: 'text',
  },
  {
    name: 'report_type',
    label: 'Report type',
    type: 'select',
    options: [
      { label: 'Own dashboard', value: 'own' },
      { label: 'Shared dashboard (with company_id param)', value: 'shared' },
    ],
    value: 'own',
  },

  {
    name: 'status',
    label: 'Status',
    type: 'hidden',
    value: 1,
  },
  {
    name: 'active_user_cnt',
    label: 'Active users',
    type: 'number',
    value: 1,
  },
  {
    name: 'inactive_user_cnt',
    label: 'Inactive users',
    type: 'number',
    value: 1,
  },
  {
    name: 'package',
    label: 'Package',
    type: 'select',
    options: packageOptions.value,
  },
])

const loadPricingPackages = async () => {
  try {
    const result = await getItems({
      collection: 'Pricing_packages',
      params: {
        filter: { status: { _eq: 1 } },
        sort: ['sort', 'id'],
        fields: ['id', 'name'],
        limit: 100,
      },
    })
    const data = Array.isArray(result) ? result : (result as any)?.data ?? []

    packageOptions.value = data.map((item: any) => ({
      label: item.name,
      value: item.id,
    }))
  } catch (error) {
    console.error('Unable to load pricing packages:', error)
    packageOptions.value = []
  }
}

const columnDefs = computed<ColDef<Company>[]>(() => [
  {
    headerName: t('ID'),
    field: 'id',
    minWidth: 90,
    flex: 0.5,
    filter: 'agTextColumnFilter',
    valueGetter: (params) => `#${params.data?.id || ''}`,
  },
  {
    headerName: t('Company'),
    field: 'name',
    minWidth: 115,
    flex: 1.2,
    filter: 'agTextColumnFilter',
    valueGetter: (params) =>
      params.data?.name || params.data?.com_id || `#${params.data?.id || ''}`,
    cellRenderer: CompanyNameCell,
  },
  {
    headerName: t('Status'),
    field: 'status',
    minWidth: 120,
    filter: 'agTextColumnFilter',
    valueFormatter: (params) =>
      Number(params.value) === 1
        ? t('Active')
        : Number(params.value) === 0
        ? t('Inactive')
        : '',
  },

  //   {
  //     headerName: t('DB Key'),
  //     field: 'db_key',
  //     minWidth: 120,
  //     filter: 'agTextColumnFilter',
  //   },
  {
    headerName: t('Registration'),
    field: 'registration_number',
    minWidth: 100,
    flex: 1,
    filter: 'agTextColumnFilter',
  },
  {
    headerName: t('Email'),
    field: 'email',
    minWidth: 140,
    flex: 1.2,
    filter: 'agTextColumnFilter',
  },
  {
    headerName: t('Type'),
    field: 'type',
    minWidth: 90,
    flex: 0.8,
    filter: 'agTextColumnFilter',
    valueGetter: (params) => {
      const type = params.data?.type

      if (type === 'team_member_1') {
        return t('Small')
      }
      if (type === 'team_member_2') {
        return t('Middle')
      }
      if (type === 'team_member_3') {
        return t('Big')
      }
      return type ? t(type) : '-'
    },
  },
  {
    headerName: t('Active users'),
    field: 'active_user_cnt',
    minWidth: 85,
    flex: 0.7,
    filter: 'agNumberColumnFilter',
    cellStyle: { fontWeight: '600', textAlign: 'left' },
    valueFormatter: (params) => String(params.value || 0),
  },
  {
    headerName: t('Inactive users'),
    field: 'inactive_user_cnt',
    minWidth: 95,
    flex: 0.8,
    filter: 'agNumberColumnFilter',
    cellStyle: { color: '#9ca3af', textAlign: 'left' },
    valueFormatter: (params) => String(params.value || 0),
  },
  {
    headerName: t('Total users'),
    colId: 'total_user_cnt',
    minWidth: 85,
    flex: 0.7,
    filter: 'agNumberColumnFilter',
    valueGetter: (params) =>
      (params.data?.active_user_cnt || 0) +
      (params.data?.inactive_user_cnt || 0),
  },
  {
    headerName: t('License date'),
    field: 'license_date',
    minWidth: 100,
    flex: 0.9,
    filter: 'agTextColumnFilter',
    valueFormatter: (params) => formatDate(params.value),
  },
  {
    headerName: t('Action'),
    colId: 'actions',
    width: 126,
    minWidth: 126,
    maxWidth: 126,
    sortable: false,
    resizable: false,
    filter: false,
    floatingFilter: false,
    cellRenderer: CompanyActionsCell,
  },
])

const defaultColDef: ColDef<Company> = {
  sortable: true,
  resizable: true,
  floatingFilter: true,
}

// localeText-ыг computed property болгон шилжүүлэх
const localeText = computed(() => ({
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
}))

const gridOptions: GridOptions<Company> = {
  localeText: localeText.value, // Үүнийг reactive binding болгох
  pagination: true,
  paginationPageSize: 20,
  paginationPageSizeSelector: [10, 20, 50, 100],
  animateRows: false,
  rowHeight: 44,
  suppressHorizontalScroll: true,
  autoSizeStrategy: {
    type: 'fitGridWidth',
  },
  context: {
    openUsers: (company: Company) => openUsers(company),
    openEdit: (company: Company) => openEdit(company),
    openDelete: (company: Company) => openDelete(company),
    toggleStatus: (company: Company) => toggleStatus(company),
  },
}

const pinnedTotals = computed(() => {
  const activeUsers = companies.value.reduce(
    (total, company) => total + (company.active_user_cnt || 0),
    0,
  )
  const inactiveUsers = companies.value.reduce(
    (total, company) => total + (company.inactive_user_cnt || 0),
    0,
  )

  return [
    {
      name: t('Total'),
      active_user_cnt: activeUsers,
      inactive_user_cnt: inactiveUsers,
      total_user_cnt: activeUsers + inactiveUsers,
    },
  ]
})

const formatDate = (value?: string) => {
  if (!value) return '-'

  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? value : date.toLocaleDateString()
}

const loadCompanies = async () => {
  isLoading.value = true

  try {
    const response = await fetch(
      `${runtimeConfig.public.directus.url}items/Companies?filter[status][_in]=0,1&sort=id&limit=1000&fields=id,com_id,name,db_key,registration_number,email,type,license_date,status,active_user_cnt,inactive_user_cnt`,
      {
        headers: {
          Authorization: `Bearer ${token.value}`,
        },
      },
    )
    const result = await response.json()

    if (!response.ok || !Array.isArray(result.data)) {
      throw new Error(result.errors?.[0]?.message || 'Unable to load companies')
    }

    companies.value = result.data
  } catch (error) {
    console.error('Unable to load companies:', error)
    companies.value = []
    toaster.show({
      title: t('Unable to load companies'),
      message: t('Please try again'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
  } finally {
    isLoading.value = false
  }
}

const handleModalOpen = () => {
  toaster.show({ title: 'Creation disabled', message: 'Secure account provisioning is not configured.', color: 'warning', icon: 'lucide:lock' })
}

const openUsers = (company: Company) => {
  navigateTo({
    path: '/companies/users',
    query: {
      company_id: String(company.id),
      company_name: company.name || company.com_id || '',
    },
  })
}

const handleModalClose = () => {
  isCreateModalOpen.value = false
  selectedCompanyId.value = -1
}

const getResponseError = (result: any, fallback: string) =>
  result?.errors?.[0]?.message || result?.message || fallback

const createCompanyWithAdmin = async (values: CompanyFormValues) => {
  throw new Error('Company account creation is disabled until secure provisioning is configured.')
}

const openEdit = (company: Company) => {
  selectedCompanyId.value = company.id
  isCreateModalOpen.value = true
}

const openDelete = (company: Company) => {
  if (String(company.id) === '1') return

  companyToDelete.value = company
  isDeleteModalOpen.value = true
}

const closeDeleteModal = () => {
  isDeleteModalOpen.value = false
  companyToDelete.value = null
}

const toggleStatus = async (company: Company) => {
  if (String(company.id) === '1' || isMutating.value) return

  isMutating.value = true
  const nextStatus = Number(company.status) === 1 ? 0 : 1

  try {
    const response = await fetch(
      `${runtimeConfig.public.directus.url}items/Companies/${company.id}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token.value}`,
        },
        body: JSON.stringify({ status: nextStatus }),
      },
    )
    const result = await response.json()

    if (!response.ok) {
      throw new Error(
        getResponseError(result, 'Unable to update company status'),
      )
    }

    toaster.show({
      title: t('Updated'),
      message:
        nextStatus === 1 ? t('Company activated') : t('Company deactivated'),
      color: 'success',
      icon: 'ph:check-circle-fill',
      closable: true,
    })
    await loadCompanies()
  } catch (error) {
    toaster.show({
      title: t('Error'),
      message: error instanceof Error ? error.message : t('Please try again'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
  } finally {
    isMutating.value = false
  }
}

const deleteCompany = async () => {
  if (!companyToDelete.value || isMutating.value) return

  isMutating.value = true

  try {
    //    const response = await fetch(
    //   `${runtimeConfig.public.directus.url}items/Companies/${companyToDelete.value.id}`,
    //   {
    //     method: 'PATCH',
    //     headers: {
    //       'Content-Type': 'application/json',
    //       Authorization: `Bearer ${token.value}`,
    //     },
    //     body: JSON.stringify({ status: 'draft' }),
    //   },
    // )

    const response = await fetch(
      `${runtimeConfig.public.directus.url}items/Companies/${companyToDelete.value.id}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token.value}`,
        },
        body: JSON.stringify({ status: 0 }),
      },
    )

    if (!response.ok) {
      const result = await response.json()
      throw new Error(getResponseError(result, 'Unable to delete company'))
    }

    toaster.show({
      title: t('Updated'),
      message: t('Company moved to draft'),
      color: 'success',
      icon: 'ph:check-circle-fill',
      closable: true,
    })
    closeDeleteModal()
    await loadCompanies()
  } catch (error) {
    toaster.show({
      title: t('Error'),
      message: error instanceof Error ? error.message : t('Please try again'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
  } finally {
    isMutating.value = false
  }
}

onMounted(() => {
  if (window.localStorage.getItem('myCompanyId') === '1') {
    window.localStorage.removeItem('Companies')
  }

  loadCompanies()
  loadPricingPackages()
})

definePageMeta({
  title: 'Companies',
  showback: true,
  preview: {
    title: 'Companies',
    description: 'For viewing companies',
    categories: ['layouts', 'forms'],
    src: '/img/screens/layouts-form-1.png',
    srcDark: '/img/screens/layouts-form-1-dark.png',
    order: 47,
  },
})
</script>

<template>
  <div class="mx-auto w-full max-w-7xl">
    <div class="mb-5 flex items-center justify-between">
      <div>
        <BaseButton @click="handleModalOpen">
          <Icon
            name="streamline-ultimate:office-building-tall-2"
            class="-ms-1 h-4 w-4"
          />
          <span class="text-[11px]">{{ $t('Add') }}</span>
        </BaseButton>
      </div>
      <div class="mb-5 flex items-center justify-between">
        <div class="flex items-center gap-2">
          <BaseButtonIcon
            type="button"
            :disabled="isLoading"
            data-tooltip="Refresh"
            @click="loadCompanies"
          >
            <Icon
              name="lucide:refresh-cw"
              :class="['size-4', { 'animate-spin': isLoading }]"
            />
          </BaseButtonIcon>
        </div>
        <BaseText size="sm" class="ml-2 text-muted-500">
          {{ companies.length }} {{ $t('companies') }}
        </BaseText>
      </div>
    </div>

    <BasePlaceholderPage
      v-if="isLoading"
      title="Loading companies"
      subtitle=""
      class="min-h-96"
    />

    <BasePlaceholderPage
      v-else-if="companies.length === 0"
      title="No companies found"
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
      :row-data="companies"
      :pinned-bottom-row-data="pinnedTotals"
      :get-row-style="
        (params: any) =>
          params.node.rowPinned === 'bottom'
            ? { fontWeight: '600', background: 'rgba(59, 130, 246, 0.08)' }
            : undefined
      "
    />

    <DynamicModalForm
      v-if="isCreateModalOpen"
      :title="selectedCompanyId === -1 ? 'Add company' : 'Edit company'"
      code="Companies"
      :open="isCreateModalOpen"
      :close="handleModalClose"
      :refresh="loadCompanies"
      :fields="companyFields"
      :create="selectedCompanyId === -1 ? createCompanyWithAdmin : undefined"
      :row="selectedCompanyId"
      size="md"
      icon="streamline-ultimate:office-building-tall-2"
    />

    <TairoModal :open="isDeleteModalOpen" size="sm" @close="closeDeleteModal">
      <template #header>
        <div class="flex w-full items-center justify-between">
          <h3 class="font-heading text-lg font-medium">
            {{ $t('Delete company') }}
          </h3>
          <BaseButtonClose @click="closeDeleteModal" />
        </div>
      </template>

      <div class="px-6 py-4 text-sm text-muted-600 dark:text-muted-300">
        {{ $t('Delete') }}
        {{ companyToDelete?.name || companyToDelete?.email }}?
      </div>

      <template #footer>
        <div class="flex justify-end gap-2">
          <BaseButton :disabled="isMutating" @click="closeDeleteModal">
            {{ $t('Cancel') }}
          </BaseButton>
          <BaseButton
            color="danger"
            :disabled="isMutating"
            @click="deleteCompany"
          >
            {{ $t('Delete') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>
  </div>
</template>
