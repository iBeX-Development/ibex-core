<script setup lang="ts">
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { AgGridVue } from 'ag-grid-vue3'
import { onMounted, ref } from 'vue'
import ModalItemsList from '~/components/form/ModalItemsList.vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const props = defineProps<{
  woId: number | string | null
}>()

const { getItems, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()

// ── AG Grid ──────────────────────────────────────────────────────────────────
const gridApi = ref<any>(null)
const rowData = ref<any[]>([])

const columnDefs = ref([
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
    headerName: t('Answers (summary)'),
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
      console.log('p.data', p.data)
      if (p.data.wo_id.wo_status == 3) return
      const btn = document.createElement('button')
      btn.innerHTML =
        '<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/></svg>'
      btn.className =
        'flex items-center justify-center w-7 h-7 rounded text-red-500 hover:bg-red-50 dark:hover:bg-red-950 transition-colors'
      btn.addEventListener('click', () => confirmDelete(p.data))
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

const onGridReady = (params: any) => {
  gridApi.value = params.api
}

// ── Data ─────────────────────────────────────────────────────────────────────
const loading = ref(false)

const loadFailureResults = async () => {
  loading.value = true
  try {
    const items = await getItems<any>({
      collection: 'Failure_analyze_result',
      params: {
        filter: { wo_id: { _eq: props.woId } },
        limit: -1,
        fields: [
          '*',
          'template_id.id',
          'template_id.name',
          'template_id.fields',
          'wo_id.id',
          'wo_id.wo_status',
        ],
      },
    })
    rowData.value = items?.data ?? items ?? []
  } catch (e) {
    console.error(e)
    rowData.value = []
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadFailureResults()
})

// ── Add (template picker) ─────────────────────────────────────────────────────
const isTemplateModalOpen = ref(false)
const selectedTemplate = ref<any>(null)
const isAddFormOpen = ref(false)
const addAnswers = ref<Record<string, any>>({})

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
  isAddFormOpen.value = true
}

const submitAdd = async () => {
  if (!selectedTemplate.value) return
  try {
    await createItems({
      collection: 'Failure_analyze_result',
      items: {
        wo_id: props.woId,
        template_id: selectedTemplate.value.id,
        answers: addAnswers.value,
        company_id: myCompanyId,
      },
    })
    isAddFormOpen.value = false
    selectedTemplate.value = null
    await loadFailureResults()
    toaster.show({
      title: 'Added',
      message: 'Failure analysis saved.',
      color: 'success',
      icon: 'ph:check-circle',
      closable: true,
    })
  } catch (e) {
    console.error(e)
  }
}

// ── Delete ───────────────────────────────────────────────────────────────────
const isDeleteConfirmOpen = ref(false)
const deleteTarget = ref<any>(null)

const confirmDelete = (item: any) => {
  deleteTarget.value = item
  isDeleteConfirmOpen.value = true
}

const doDelete = async () => {
  if (!deleteTarget.value) return
  try {
    // await deleteItems({
    //   collection: 'Failure_analyze_result',
    //   items: [deleteTarget.value.id],
    // })
    // isDeleteConfirmOpen.value = false
    // deleteTarget.value = null
    // await loadFailureResults()
    toaster.show({
      title: 'Deleted',
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
  <div class="font-sans text-sm space-y-3">
    <!-- Toolbar -->
    <div
      v-if="
        props.work_order?.completed_at === null &&
        props.work_order?.action_status !== 2
      "
      class="flex items-center justify-between"
    >
      <span class="text-xs text-muted-400">{{ rowData.length }} records</span>
      <BaseButton size="sm" @click="isTemplateModalOpen = true">
        <Icon name="ic:round-report-gmailerrorred" class="-ms-1 h-4 w-4" />
        <span class="text-[11px]">{{ $t('Failure Add') }}</span>
      </BaseButton>
    </div>

    <!-- AG Grid -->
    <div v-if="loading" class="py-6 space-y-3">
      <BasePlaceload class="h-8 w-full rounded" />
      <BasePlaceload class="h-8 w-3/4 rounded" />
    </div>
    <AgGridVue
      v-else
      :style="{
        height:
          rowData.length === 0
            ? '120px'
            : `${Math.min(rowData.length * 42 + 56, 480)}px`,
      }"
      :class="`ag-theme-quartz${$colorMode?.value === 'dark' ? '-dark' : ''}`"
      :columnDefs="columnDefs"
      :rowData="rowData"
      :gridOptions="gridOptions"
      @grid-ready="onGridReady"
    />

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
          <BaseButton rounded="md" @click="isAddFormOpen = false"
            >Cancel</BaseButton
          >
          <BaseButton color="primary" rounded="md" @click="submitAdd"
            >Save</BaseButton
          >
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
            Confirm Delete
          </h3>
          <BaseButtonClose @click="isDeleteConfirmOpen = false" />
        </div>
      </template>
      <div class="p-4 md:p-6">
        <p class="text-sm text-muted-600 dark:text-muted-400">
          Delete this failure analysis record?
        </p>
      </div>
      <template #footer>
        <div class="flex justify-end gap-2 p-4">
          <BaseButton rounded="md" @click="isDeleteConfirmOpen = false"
            >Cancel</BaseButton
          >
          <BaseButton color="danger" rounded="md" @click="doDelete"
            >Delete</BaseButton
          >
        </div>
      </template>
    </TairoModal>
  </div>
</template>
