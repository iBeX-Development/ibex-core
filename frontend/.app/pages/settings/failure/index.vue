<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Failure Analyze Templates',
  showback: true,
})

const { getItems, createItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()

// ─── Table ────────────────────────────────────────────────────────────────────
const itemsPerPage = ref(25)
const search = ref('')
const serverItems = ref<any[]>([])
const loading = ref(true)
const totalItems = ref(0)
const tableKey = ref(1)

const tableHeaders = computed(() => [
  { title: t('Name'), key: 'name', align: 'start' as const, width: '25%' },
  {
    title: t('Description'),
    key: 'description',
    align: 'start' as const,
    width: '40%',
  },
  {
    title: t('Fields'),
    key: 'fields_count',
    align: 'start' as const,
    width: '15%',
    sortable: false,
  },
  {
    title: t('Action'),
    key: 'action',
    align: 'start' as const,
    sortable: false,
  },
])

const loadItems = async ({ page, itemsPerPage: limit, sortBy }: any) => {
  loading.value = true
  const sort_array = sortBy.map(
    (s: any) => (s.order === 'asc' ? '' : '-') + s.key,
  )
  try {
    const res = await getItems<any>({
      collection: 'Failure_analyze_template',
      params: {
        filter: { status: { _eq: 'published' }, company_id: myCompanyId },
        limit,
        page,
        sort: sort_array.length ? sort_array : ['-date_created'],
        meta: 'filter_count',
        search: search.value,
        fields: ['id', 'name', 'description', 'fields'],
      },
    })
    serverItems.value = res.data.map((item: any) => ({
      ...item,
      fields_count: Array.isArray(item.fields) ? item.fields.length : 0,
    }))
    totalItems.value = Number(res.meta?.filter_count ?? 0)
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

const refreshTable = () => {
  tableKey.value = Math.random()
}

// ─── Field types ──────────────────────────────────────────────────────────────
const FIELD_TYPES = [
  { value: 'number', label: 'Number (утга)' },
  { value: 'text', label: 'Text (бичвэр)' },
  { value: 'yes_no', label: 'Yes / No (сонголт)' },
  { value: 'select', label: 'Select (өөрийн сонголт)' },
  { value: 'date_time', label: 'Date & Time (огноо)' },
]

// ─── Modal – Create / Edit ─────────────────────────────────────────────────────
const isModalOpen = ref(false)
const isSaving = ref(false)
const editId = ref<string | number | null>(null)

const form = reactive({
  name: '',
  description: '',
})

interface FieldRow {
  field_name: string
  field_type: string
  options: string[] // yes_no сонголтууд
  newOption: string // шинэ option оруулах input
  description: string
}

const fieldRows = ref<FieldRow[]>([])

const addFieldRow = () => {
  fieldRows.value.push({
    field_name: '',
    field_type: 'number',
    options: [],
    newOption: '',
    description: '',
  })
}

const addOption = (idx: number) => {
  const row = fieldRows.value[idx]
  const val = row.newOption.trim()
  if (val && !row.options.includes(val)) {
    row.options.push(val)
  }
  row.newOption = ''
}

const removeOption = (idx: number, oi: number) => {
  fieldRows.value[idx].options.splice(oi, 1)
}

const onFieldTypeChange = (idx: number) => {
  const row = fieldRows.value[idx]
  if (row.field_type === 'yes_no' && row.options.length === 0) {
    row.options = ['Yes', 'No']
  }
}

const removeFieldRow = (idx: number) => {
  fieldRows.value.splice(idx, 1)
}

const openCreate = () => {
  editId.value = null
  form.name = ''
  form.description = ''
  fieldRows.value = []
  isModalOpen.value = true
}

const openEdit = (item: any) => {
  editId.value = item.id
  form.name = item.name ?? ''
  form.description = item.description ?? ''
  const raw: any[] = Array.isArray(item.fields) ? item.fields : []
  fieldRows.value = raw.map((f) => ({
    field_name: f.field_name ?? '',
    field_type: f.field_type ?? 'number',
    options:
      Array.isArray(f.options) && f.options.length > 0
        ? [...f.options]
        : f.field_type === 'yes_no'
        ? ['Yes', 'No']
        : [],
    newOption: '',
    description: f.description ?? '',
  }))
  isModalOpen.value = true
}

const closeModal = () => {
  isModalOpen.value = false
}

const handleSave = async () => {
  if (!form.name.trim()) {
    toaster.show({
      title: t('Error'),
      message: t('Name is required'),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
    return
  }

  const fields = fieldRows.value
    .filter((r) => r.field_name.trim())
    .map((r) => ({
      field_name: r.field_name.trim(),
      field_type: r.field_type,
      options:
        r.field_type === 'yes_no' || r.field_type === 'select'
          ? [...r.options]
          : [],
      description: r.description.trim(),
    }))

  const payload = {
    name: form.name.trim(),
    description: form.description.trim(),
    fields,
    status: 'published',
  }

  isSaving.value = true
  try {
    if (editId.value) {
      await updateItem({
        collection: 'Failure_analyze_template',
        id: String(editId.value),
        item: payload,
      })
    } else {
      await createItems({
        collection: 'Failure_analyze_template',
        items: [{ ...payload, company_id: myCompanyId }],
      })
    }
    toaster.show({
      title: t('Success'),
      message: t('Saved successfully'),
      color: 'success',
      icon: 'ph:check',
      closable: true,
    })
    closeModal()
    refreshTable()
  } catch (e) {
    console.error(e)
    toaster.show({
      title: t('Error'),
      message: t('Save failed'),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  } finally {
    isSaving.value = false
  }
}

// ─── Delete ───────────────────────────────────────────────────────────────────
const isDeleteOpen = ref(false)
const deleteId = ref<string | number | null>(null)
const isDeleting = ref(false)

const openDelete = (item: any) => {
  deleteId.value = item.id
  isDeleteOpen.value = true
}

const confirmDelete = async () => {
  if (!deleteId.value) return
  isDeleting.value = true
  try {
    await updateItem({
      collection: 'Failure_analyze_template',
      id: String(deleteId.value),
      item: { status: 'archived' },
    })
    toaster.show({
      title: t('Success'),
      message: t('Deleted'),
      color: 'success',
      icon: 'ph:check',
      closable: true,
    })
    isDeleteOpen.value = false
    refreshTable()
  } catch (e) {
    console.error(e)
  } finally {
    isDeleting.value = false
  }
}
</script>

<template>
  <div class="relative Failure-analyze">
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12 flex items-center justify-between">
        <BaseButton @click="openCreate">
          <Icon name="ph:plus-bold" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Add Template') }}</span>
        </BaseButton>
      </div>

      <!-- Table -->
      <div class="col-span-12">
        <BaseInput
          v-model="search"
          icon="lucide:search"
          :placeholder="$t('Search')"
          :classes="{ wrapper: 'w-full sm:w-auto Searching' }"
        />
        <v-data-table-server
          :key="tableKey"
          v-model:items-per-page="itemsPerPage"
          :headers="tableHeaders"
          :items-length="totalItems"
          :items="serverItems"
          :loading="loading"
          :search="search"
          item-value="id"
          class="elevation-1 failure-analyze-table"
          :theme="$colorMode.value"
          :page-text="t('{0}-{1} of {2}', ['{0}', '{1}', '{2}'])"
          :items-per-page-options="[
            { value: 10, title: '10' },
            { value: 25, title: '25' },
            { value: 50, title: '50' },
            { value: -1, title: t('All') },
          ]"
          :items-per-page-text="t('Item per page')"
          :loading-text="t('loading')"
          :no-data-text="t('No records')"
          @update:options="loadItems"
        >
          <!-- Fields count badge -->
          <template #item.fields_count="{ item }">
            <span
              class="inline-flex items-center rounded-full bg-primary-100 px-2 py-0.5 text-xs font-medium text-primary-700 dark:bg-primary-900/30 dark:text-primary-300"
            >
              {{ item.fields_count }} {{ $t('fields') }}
            </span>
          </template>

          <!-- Actions -->
          <template #item.action="{ item }">
            <BaseDropdown
              flavor="context"
              orientation="end"
              condensed
              shape="curved"
              class="absolute mt-[-18px]"
            >
              <div>
                <BaseDropdownItem
                  :title="t('Edit')"
                  :text="t('Edit template')"
                  @click="openEdit(item)"
                >
                  <template #start>
                    <Icon
                      name="ph:pencil-line-fill"
                      class="me-2 block h-5 w-5"
                    />
                  </template>
                </BaseDropdownItem>
                <BaseDropdownDivider />
                <BaseDropdownItem
                  :title="t('Delete')"
                  :text="t('Remove template')"
                  @click="openDelete(item)"
                >
                  <template #start>
                    <Icon
                      name="ph:trash-duotone"
                      class="me-2 block h-5 w-5 text-danger-500"
                    />
                  </template>
                </BaseDropdownItem>
              </div>
            </BaseDropdown>
          </template>
        </v-data-table-server>
      </div>
    </div>

    <!-- ── Create / Edit Modal ─────────────────────────────────────────────── -->
    <TairoModal :open="isModalOpen" size="2xl" @close="closeModal">
      <template #header>
        <!-- Header -->
        <div class="flex w-full items-center justify-between">
          <div class="flex items-center gap-2">
            <div
              class="flex size-8 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-900/30"
            >
              <Icon
                name="material-symbols:running-with-errors"
                class="size-4 text-primary-500"
              />
            </div>
            <div class="flex items-center gap-2">
              <h3
                class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
              >
                {{
                  editId
                    ? t('Edit Template')
                    : t('New Failure Analyze Template')
                }}
              </h3>
            </div>
          </div>
          <BaseButtonClose @click="closeModal" />
        </div>
      </template>

      <div class="p-4 md:p-6 space-y-6">
        <!-- Template info -->
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <label
              class="mb-1 block text-xs text-muted-500 dark:text-muted-400"
            >
              {{ $t('Template Name') }} <span class="text-danger-500">*</span>
            </label>
            <BaseInput
              v-model="form.name"
              :placeholder="$t('e.g. Engine Failure Analysis')"
              style="
                border-radius: 0.375rem;
                border-width: 1px;
                border-style: solid;
              "
            />
          </div>
          <div>
            <label
              class="mb-1 block text-xs text-muted-500 dark:text-muted-400"
            >
              {{ $t('Description') }}
            </label>
            <BaseInput
              v-model="form.description"
              :placeholder="$t('Short description')"
              class="input-description"
              style="
                border-radius: 0.375rem;
                border-width: 1px;
                border-style: solid;
              "
            />
          </div>
        </div>

        <!-- Field builder -->
        <div>
          <div class="mb-3 flex items-center justify-between">
            <label class="text-xs text-muted-500 dark:text-muted-400">
              {{ $t('Fields') }}
            </label>
            <BaseButton size="sm" color="primary" @click="addFieldRow">
              <Icon name="ph:plus-bold" class="h-3.5 w-3.5 me-1" />
              {{ $t('Add Field') }}
            </BaseButton>
          </div>

          <!-- Column headers -->
          <div
            v-if="fieldRows.length"
            class="mb-1 hidden sm:grid sm:grid-cols-12 gap-2 px-1"
          >
            <div class="col-span-3 text-xs text-muted-400">
              {{ $t('Field Name') }}
            </div>
            <div class="col-span-3 text-xs text-muted-400">
              {{ $t('Type') }}
            </div>
            <div class="col-span-3 text-xs text-muted-400">
              {{ $t('Options') }}
              <span class="text-muted-300">(yes_no / select)</span>
            </div>
            <div class="col-span-2 text-xs text-muted-400">
              {{ $t('Description') }}
            </div>
            <div class="col-span-1"></div>
          </div>

          <!-- Field rows -->
          <div class="space-y-2">
            <div
              v-for="(row, idx) in fieldRows"
              :key="idx"
              class="grid grid-cols-12 gap-2 items-center rounded-lg border border-muted-200 dark:border-muted-700 bg-muted-50 dark:bg-muted-800/50 p-2"
            >
              <!-- field_name -->
              <div class="col-span-12 sm:col-span-3">
                <BaseInput
                  v-model="row.field_name"
                  size="sm"
                  :placeholder="$t('e.g. temperature')"
                />
              </div>

              <!-- field_type -->
              <div class="col-span-12 sm:col-span-3">
                <select
                  v-model="row.field_type"
                  class="w-full rounded-lg border border-muted-300 dark:border-muted-600 bg-white dark:bg-muted-800 px-3 py-2 text-sm text-muted-800 dark:text-muted-100 focus:outline-none focus:ring-2 focus:ring-primary-500"
                  @change="onFieldTypeChange(idx)"
                >
                  <option
                    v-for="ft in FIELD_TYPES"
                    :key="ft.value"
                    :value="ft.value"
                  >
                    {{ ft.label }}
                  </option>
                </select>
              </div>

              <!-- options (yes_no / select) -->
              <div class="col-span-12 sm:col-span-3">
                <div
                  v-if="
                    row.field_type === 'yes_no' || row.field_type === 'select'
                  "
                  class="space-y-1"
                >
                  <!-- existing option tags -->
                  <div class="flex flex-wrap gap-1">
                    <span
                      v-for="(opt, oi) in row.options"
                      :key="oi"
                      class="inline-flex items-center gap-1 rounded-full bg-primary-100 dark:bg-primary-900/40 px-2 py-0.5 text-xs font-medium text-primary-700 dark:text-primary-300"
                    >
                      {{ opt }}
                      <button
                        type="button"
                        class="text-primary-400 hover:text-danger-500 transition-colors"
                        @click="removeOption(idx, oi)"
                      >
                        <Icon name="ph:x-bold" class="h-2.5 w-2.5" />
                      </button>
                    </span>
                  </div>
                  <!-- add new option input -->
                  <div class="flex gap-1">
                    <input
                      v-model="row.newOption"
                      type="text"
                      :placeholder="$t('New option...')"
                      class="flex-1 min-w-0 rounded-lg border border-muted-300 dark:border-muted-600 bg-white dark:bg-muted-800 px-2 py-1.5 text-sm text-muted-800 dark:text-muted-100 placeholder-muted-400 focus:outline-none focus:ring-2 focus:ring-primary-500"
                      @keydown.enter.prevent="addOption(idx)"
                    />
                    <button
                      type="button"
                      class="shrink-0 rounded border border-primary-400 px-2 text-primary-500 hover:bg-primary-50 dark:hover:bg-primary-900/30 transition-colors"
                      @click="addOption(idx)"
                    >
                      <Icon name="ph:plus-bold" class="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>
                <span v-else class="block text-xs text-muted-400 px-2 py-1.5"
                  >—</span
                >
              </div>

              <!-- description -->
              <div class="col-span-11 sm:col-span-2">
                <BaseInput
                  v-model="row.description"
                  size="sm"
                  :placeholder="$t('Description')"
                />
              </div>

              <!-- remove -->
              <div class="col-span-1 flex justify-center">
                <button
                  type="button"
                  class="text-danger-400 hover:text-danger-600 transition-colors"
                  @click="removeFieldRow(idx)"
                >
                  <Icon name="ph:trash-duotone" class="h-4 w-4" />
                </button>
              </div>
            </div>
          </div>

          <!-- Empty state -->
          <div
            v-if="!fieldRows.length"
            class="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-muted-200 dark:border-muted-700 py-8 text-center"
          >
            <Icon name="ph:list-plus" class="mb-2 h-8 w-8 text-muted-300" />
            <p class="text-sm text-muted-400">
              {{ $t('No fields yet. Click "Add Field" to start.') }}
            </p>
          </div>
        </div>

        <!-- JSON preview -->
        <details
          class="rounded-lg border border-muted-200 dark:border-muted-700"
        >
          <summary
            class="cursor-pointer px-3 py-2 text-xs text-muted-500 dark:text-muted-400 select-none"
          >
            {{ $t('JSON Preview') }}
          </summary>
          <pre
            class="overflow-x-auto bg-muted-900 text-green-400 text-xs p-3 rounded-b-lg leading-5"
            >{{
              JSON.stringify(
                fieldRows
                  .filter((r) => r.field_name.trim())
                  .map((r) => ({
                    field_name: r.field_name.trim(),
                    field_type: r.field_type,
                    options:
                      r.field_type === 'yes_no' || r.field_type === 'select'
                        ? [...r.options]
                        : [],
                    description: r.description.trim(),
                  })),
                null,
                2,
              )
            }}</pre
          >
        </details>
      </div>

      <template #footer>
        <div class="flex items-center justify-end gap-3 p-4 md:p-6">
          <BaseButton @click="closeModal">{{ $t('Cancel') }}</BaseButton>
          <BaseButton color="primary" :loading="isSaving" @click="handleSave">
            {{ $t('Save') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>

    <!-- ── Delete Confirmation ─────────────────────────────────────────────── -->
    <TairoModal :open="isDeleteOpen" size="sm" @close="isDeleteOpen = false">
      <template #header>
        <div class="flex w-full items-center justify-between p-4 md:p-6">
          <h3 class="font-heading text-base text-danger-600">
            {{ $t('Delete Template') }}
          </h3>
          <BaseButtonClose @click="isDeleteOpen = false" />
        </div>
      </template>
      <div class="p-4 md:p-6 text-sm text-muted-600 dark:text-muted-400">
        {{
          $t(
            'Are you sure you want to delete this template? This action cannot be undone.',
          )
        }}
      </div>
      <template #footer>
        <div class="flex items-center justify-end gap-3 p-4 md:p-6">
          <BaseButton @click="isDeleteOpen = false">{{
            $t('Cancel')
          }}</BaseButton>
          <BaseButton
            color="danger"
            :loading="isDeleting"
            @click="confirmDelete"
          >
            <Icon name="ph:trash-duotone" class="me-1 h-4 w-4" />
            {{ $t('Delete') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>
  </div>
</template>

<style scoped>
.Failure-analyze .input-name,
.Failure-analyze .input-description {
  border-style: solid !important;
}
/* Or style all headers */
.failure-analyze-table {
  margin-top: 1px;
  border-radius: 4px;
}
.failure-analyze-table .v-table {
  border-radius: 7px;
}

.failure-analyze-table .v-data-table__th {
  height: 40px !important;
}

.failure-analyze-table .v-data-table thead th {
  white-space: nowrap;
}

.failure-analyze-table .v-data-table .v-data-table__td .wo_name {
  cursor: pointer;
  margin-right: 5px;
}

.failure-analyze-table .statusCell {
  padding: 4px;
  width: 125px;
  border-radius: 100px;
  line-height: 1.5;
  font-size: 11px;
  border: 2px solid rgba(91, 91, 91, 0.1);
  display: flex;
  justify-content: center;
  align-items: center;
}
.v-data-table-footer {
  margin-top: 70px;
}
</style>
