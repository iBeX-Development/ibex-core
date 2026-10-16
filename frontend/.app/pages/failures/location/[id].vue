<script setup lang="ts">
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { AgGridVue } from 'ag-grid-vue3'
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import ModalItemsList from '~/components/form/ModalItemsList.vue'

definePageMeta({
  middleware: ['auth'],
  title: 'Failure Analysis',
  preview: {
    title: 'Failure Analysis',
    description: 'Failure analysis records per location',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 20,
  },
})

const { t } = useI18n({ useScope: 'global' })
const { params } = useRoute()
const { getItems, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()

const locationId = computed(() => params.id)

// ── AG Grid ──────────────────────────────────────────────────────────────────
const gridApi = ref<any>(null)
const rowData = ref<any[]>([])
const loading = ref(false)
const quickFilterText = ref('')

const windowHeight = ref(560)

const columnDefs = ref([
  {
    field: 'wo_id',
    headerName: t('WO'),
    width: 140,
    cellRenderer: (params) => {
      return `
        <span>
          #${params.data?.wo_id?.wo_number ?? params.data?.wo_id}
        </span>
      `
    },
  },
  {
    field: 'template_id.name',
    headerName: t('Template'),
    flex: 1,
    valueGetter: (p: any) =>
      p.data?.template_id?.name ?? 'Template #' + p.data?.template_id,
  },
  {
    field: 'date_created',
    headerName: t('Date'),
    width: 180,
    valueFormatter: (p: any) =>
      p.value ? new Date(p.value).toLocaleString() : '',
  },
  {
    field: 'answers',
    headerName: t('Answers'),
    flex: 2,
    valueFormatter: (p: any) => {
      const a = p.value
      if (!a || typeof a !== 'object') return ''
      return Object.entries(a)
        .map(([k, v]) => `${k}: ${v}`)
        .join(' | ')
    },
  },
  {
    field: 'action',
    headerName: '',
    width: 80,
    sortable: false,
    cellRenderer: (p: any) => {
      const btn = document.createElement('button')
      btn.innerHTML =
        '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>'
      btn.className =
        'flex items-center justify-center w-7 h-7 rounded text-red-500 hover:bg-red-50 dark:hover:bg-red-950 transition-colors'
      btn.addEventListener('click', () => openDeleteConfirm(p.data))
      return btn
    },
  },
])

const gridOptions = {
  rowModelType: 'clientSide',
  animateRows: false,
  defaultColDef: { resizable: true, sortable: true },
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

const onGridReady = (p: any) => {
  gridApi.value = p.api
  const savedState = localStorage.getItem('failureAnalyzeColumnState')
  if (savedState) {
    const state = JSON.parse(savedState)
    p.api.applyColumnState({ state: state, applyOrder: true })
  } else {
    // Хэрэглэгч хараахан баганын өргөнийг өөрчлөөгүй анхны удаад л
    // дэлгэц дүүргэж тохируулна — эс тэгвэл хадгалсан өргөнийг дарж бичнэ
    p.api.sizeColumnsToFit()
  }
}

const saveColumnState = (params: any) => {
  const columnState = params.api.getColumnState()
  localStorage.setItem('failureAnalyzeColumnState', JSON.stringify(columnState))
}

// ── Load data ─────────────────────────────────────────────────────────────────
const loadData = async () => {
  loading.value = true
  try {
    const items = await getItems<any>({
      collection: 'Failure_analyze_result',
      params: {
        filter: {
          wo_id: {
            location: { _eq: locationId.value },
          },
          company_id: { _eq: myCompanyId },
        },
        limit: -1,
        fields: [
          '*',
          'wo_id.id',
          'wo_id.wo_number',
          'template_id.id',
          'template_id.name',
          'template_id.fields',
        ],
      },
    })
    rowData.value = items?.data ?? items ?? []
    windowHeight.value = Math.max(
      300,
      Math.min(rowData.value.length * 42 + 100, 800),
    )
  } catch (e) {
    console.error(e)
    rowData.value = []
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadData()
})

// ── Add ───────────────────────────────────────────────────────────────────────
const isTemplateModalOpen = ref(false)
const isAddFormOpen = ref(false)
const selectedTemplate = ref<any>(null)
const addAnswers = ref<Record<string, any>>({})
const addWoId = ref<string>('')

const parseFields = (raw: any) => {
  if (Array.isArray(raw)) return raw
  if (typeof raw === 'string') {
    try {
      return JSON.parse(raw)
    } catch {
      return []
    }
  }
  return []
}

const openAddForm = (item: any) => {
  selectedTemplate.value = item
  isTemplateModalOpen.value = false
  const answers: Record<string, any> = {}
  parseFields(item.fields).forEach((f: any) => {
    if (f.field_type === 'yes_no') answers[f.field_name] = 'Yes'
    else if (f.field_type === 'select')
      answers[f.field_name] = f.options?.[0] ?? ''
    else answers[f.field_name] = ''
  })
  addAnswers.value = answers
  addWoId.value = ''
  isAddFormOpen.value = true
}

const submitAdd = async () => {
  if (!selectedTemplate.value) return
  try {
    await createItems({
      collection: 'Failure_analyze_result',
      items: {
        wo_id: addWoId.value || null,
        template_id: selectedTemplate.value.id,
        answers: addAnswers.value,
        company_id: myCompanyId,
      },
    })
    isAddFormOpen.value = false
    selectedTemplate.value = null
    await loadData()
    toaster.show({
      title: t('Added'),
      message: 'Failure analysis saved.',
      color: 'success',
      icon: 'ph:check-circle',
      closable: true,
    })
  } catch (e) {
    console.error(e)
  }
}

// ── Delete ────────────────────────────────────────────────────────────────────
const isDeleteConfirmOpen = ref(false)
const deleteTarget = ref<any>(null)

const openDeleteConfirm = (item: any) => {
  deleteTarget.value = item
  isDeleteConfirmOpen.value = true
}

const handleExportClick = (item: any) => {
  console.log('Exporting data for location', locationId.value)
}

const doDelete = async () => {
  if (!deleteTarget.value) return
  try {
    await deleteItems({
      collection: 'Failure_analyze_result',
      items: [deleteTarget.value.id],
    })
    isDeleteConfirmOpen.value = false
    deleteTarget.value = null
    await loadData()
    toaster.show({
      title: t('Deleted'),
      message: 'Record deleted.',
      color: 'success',
      icon: 'ph:trash',
      closable: true,
    })
  } catch (e) {
    console.error(e)
  }
}
</script>

<template>
  <div class="relative">
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <!-- <BaseButton
          class="left cursor-pointer"
          @click="isTemplateModalOpen = true"
        >
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Asset add') }}</span>
        </BaseButton> -->

        <BaseButton class="left cursor-pointer ml-1" @click="handleExportClick">
          <Icon name="octicon:upload-16" class="h-4 w-4" />
          <span class="text-[11px]">{{ $t('Export excel') }}</span>
        </BaseButton>
      </div>

      <!-- GridBody -->
      <div class="col-span-12 GridBody">
        <TairoContentWrapper>
          <template #left>
            <BaseInput
              v-model="quickFilterText"
              icon="lucide:search"
              :placeholder="$t('Search')"
              :classes="{ wrapper: 'w-[340px]' }"
            />
          </template>
          <!-- <template #right>
            <BaseButton
              size="sm"
              color="primary"
              @click="isTemplateModalOpen = true"
            >
              <Icon name="lucide:plus" class="-ms-1 size-4 shrink-0" />
              <span>{{ t('Add') }}</span>
            </BaseButton>
            <BaseButton size="sm" @click="loadData" class="ml-2">
              <Icon name="lucide:refresh-cw" class="-ms-1 size-4 shrink-0" />
            </BaseButton>
          </template> -->
        </TairoContentWrapper>

        <div v-if="loading" class="py-6 space-y-3">
          <BasePlaceload class="h-8 w-full rounded" />
          <BasePlaceload class="h-8 w-3/4 rounded" />
          <BasePlaceload class="h-8 w-1/2 rounded" />
        </div>
        <AgGridVue
          v-else
          :style="{ width: '100%', height: windowHeight + 'px' }"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list`"
          :columnDefs="columnDefs"
          :rowData="rowData"
          :gridOptions="gridOptions"
          :quickFilterText="quickFilterText"
          @grid-ready="onGridReady"
          :onColumnMoved="saveColumnState"
          :onColumnPinned="saveColumnState"
          :onColumnVisible="saveColumnState"
          :onColumnResized="saveColumnState"
        />
      </div>
    </div>

    <!-- Add Form Modal -->
    <TairoModal :open="isAddFormOpen" size="md" @close="() => {}">
      <template #header>
        <div class="flex w-full items-center justify-between p-4 md:p-6">
          <h3
            class="font-heading text-muted-900 dark:text-white text-base font-medium leading-6"
          >
            {{ selectedTemplate?.name }}
          </h3>
          <BaseButtonClose @click="isAddFormOpen = false" />
        </div>
      </template>
      <div class="p-4 md:p-6 space-y-4">
        <div>
          <label
            class="block mb-1 text-xs font-medium text-muted-700 dark:text-muted-300"
          >
            WO Number (optional)
          </label>
          <BaseInput v-model="addWoId" rounded="md" placeholder="WO ID" />
        </div>
        <template
          v-if="selectedTemplate"
          v-for="field in parseFields(selectedTemplate.fields)"
          :key="field.field_name"
        >
          <div>
            <label
              class="block mb-1 text-xs font-medium text-muted-700 dark:text-muted-300"
            >
              {{ field.field_name }}
              <span
                v-if="field.description"
                class="text-muted-400 font-normal ml-1"
                >({{ field.description }})</span
              >
            </label>
            <BaseInput
              v-if="field.field_type === 'number'"
              v-model="addAnswers[field.field_name]"
              type="number"
              rounded="md"
              :placeholder="field.field_name"
            />
            <BaseTextarea
              v-else-if="field.field_type === 'text'"
              v-model="addAnswers[field.field_name]"
              rounded="md"
              :placeholder="field.field_name"
              rows="2"
            />
            <div v-else-if="field.field_type === 'yes_no'" class="flex gap-3">
              <BaseButton
                v-for="opt in field.options?.length
                  ? field.options
                  : ['Yes', 'No']"
                :key="opt"
                :color="
                  addAnswers[field.field_name] === opt ? 'primary' : 'default'
                "
                rounded="md"
                size="sm"
                @click="addAnswers[field.field_name] = opt"
                >{{ opt }}</BaseButton
              >
            </div>
            <BaseListbox
              v-else-if="field.field_type === 'select'"
              :items="field.options ?? []"
              :model-value="addAnswers[field.field_name]"
              rounded="md"
              @update:model-value="addAnswers[field.field_name] = $event"
            />
            <FormKit
              v-else-if="field.field_type === 'date_time'"
              type="datetime-local"
              v-model="addAnswers[field.field_name]"
              :classes="{
                input: 'wo_input w-full',
                outer: 'wo_wrapper',
                label: 'hidden',
              }"
            />
          </div>
        </template>
      </div>
      <template #footer>
        <div class="flex justify-end gap-2 p-4 md:p-6">
          <BaseButton rounded="md" @click="isAddFormOpen = false">
            {{ t('Cancel') }}
          </BaseButton>
          <BaseButton color="primary" rounded="md" @click="submitAdd">
            {{ t('Save') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>

    <!-- Template picker -->
    <ModalItemsList
      :open="isTemplateModalOpen"
      :header="[
        { title: 'Name', key: 'name', align: 'start', width: '35%' },
        { title: 'Description', key: 'description', align: 'start' },
        {
          title: 'Action',
          key: 'action',
          align: 'center',
          sortable: false,
          width: '15%',
        },
      ]"
      :close="
        () => {
          isTemplateModalOpen = false
        }
      "
      :setItem="(item) => openAddForm(item)"
      title="Failure Analyze Templates"
      collection="Failure_analyze_template"
      fields="id, name, description, fields"
      :filter="{ status: { _eq: 'published' } }"
    />

    <!-- Delete confirm -->
    <TairoModal
      :open="isDeleteConfirmOpen"
      size="sm"
      @close="isDeleteConfirmOpen = false"
    >
      <template #header>
        <div class="flex w-full items-center justify-between p-4">
          <h3
            class="font-heading text-muted-900 text-base font-medium dark:text-white"
          >
            {{ t('Confirm Delete') }}
          </h3>
          <BaseButtonClose @click="isDeleteConfirmOpen = false" />
        </div>
      </template>
      <div class="p-4 md:p-6">
        <p class="text-sm text-muted-600 dark:text-muted-400">
          {{ t('Delete this failure analysis record?') }}
        </p>
      </div>
      <template #footer>
        <div class="flex justify-end gap-2 p-4">
          <BaseButton rounded="md" @click="isDeleteConfirmOpen = false">
            {{ t('Cancel') }}
          </BaseButton>
          <BaseButton color="danger" rounded="md" @click="doDelete">
            {{ t('Delete') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>
  </div>
</template>
