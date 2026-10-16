<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import * as XLSX from 'xlsx'

const { createItems, deleteItems, getItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const { t } = useI18n({ useScope: 'global' })
const config = useRuntimeConfig()
const { token } = useDirectusToken()

definePageMeta({
  middleware: ['auth'],
  title: 'Device Field Formats',
})

// ─────────────────────────────────────────────
//  Types  (one Directus row = one field in a format)
// ─────────────────────────────────────────────
interface FieldRow {
  id?: number
  code: string
  format_name: string
  description?: string
  field_key: string
  field_name_mn?: string
  field_name_en?: string
  unit?: string
  is_active?: boolean
  sort_order?: number
  file?: string | null
}

interface FormatGroup {
  code: string
  format_name: string
  description: string
  file: string | null
  fields: FieldRow[]
}

// ─────────────────────────────────────────────
//  List — load rows, group by code
// ─────────────────────────────────────────────
const formats = ref<FormatGroup[]>([])
const listLoading = ref(false)

async function loadFormats() {
  listLoading.value = true
  try {
    const res = await getItems<FieldRow>({
      collection: 'Device_tracking_fields',
      params: {
        filter: {
          status: { _neq: 'archived' },
          is_shared_format: { _eq: true },
          company_id: { _eq: myCompanyId },
        },
        fields: [
          'id',
          'code',
          'format_name',
          'description',
          'field_key',
          'field_name_mn',
          'field_name_en',
          'unit',
          'is_active',
          'sort_order',
          'file',
        ],
        sort: ['code', 'sort_order'],
        limit: -1,
      },
    })
    const rows: FieldRow[] = Array.isArray(res) ? res : (res as any)?.data ?? []

    const map = new Map<string, FormatGroup>()
    for (const row of rows) {
      const key = row.code ?? ''
      if (!map.has(key)) {
        map.set(key, {
          code: row.code,
          format_name: row.format_name,
          description: row.description ?? '',
          file: row.file ?? null,
          fields: [],
        })
      }
      map.get(key)!.fields.push(row)
    }
    formats.value = [...map.values()]
  } catch (e) {
    console.warn('Failed to load formats:', e)
  } finally {
    listLoading.value = false
  }
}

onMounted(loadFormats)

// ─────────────────────────────────────────────
//  File helpers
// ─────────────────────────────────────────────
function getBaseUrl() {
  return ((config.public.directus as any)?.url ?? '').replace(/\/$/, '')
}

async function uploadFileToDirectus(file: File): Promise<string | null> {
  const formData = new FormData()
  formData.append('file', file, file.name)
  try {
    const res = await $fetch<{ data: { id: string } }>(
      `${getBaseUrl()}/files`,
      {
        method: 'POST',
        body: formData,
        headers: token.value ? { Authorization: `Bearer ${token.value}` } : {},
      },
    )
    return res?.data?.id ?? null
  } catch (e) {
    console.warn('File upload failed:', e)
    return null
  }
}

function getDownloadUrl(fileId: string): string {
  return `${getBaseUrl()}/assets/${fileId}?download`
}

// ─────────────────────────────────────────────
//  Modal state
// ─────────────────────────────────────────────
const isModalOpen = ref(false)
const isSaving = ref(false)
const editingCode = ref<string | null>(null)

interface ModalField {
  field_key: string
  field_name_mn: string
  field_name_en: string
  unit: string
  is_active: boolean
  sort_order: number
}

const modalForm = ref<{
  code: string
  format_name: string
  description: string
  file: File | null
  existingFileId: string | null
  fields: ModalField[]
}>({
  code: '',
  format_name: '',
  description: '',
  file: null,
  existingFileId: null,
  fields: [],
})

function openCreate() {
  editingCode.value = null
  modalForm.value = {
    code: '',
    format_name: '',
    description: '',
    file: null,
    existingFileId: null,
    fields: [],
  }
  isModalOpen.value = true
}

function openEdit(fmt: FormatGroup) {
  editingCode.value = fmt.code
  modalForm.value = {
    code: fmt.code,
    format_name: fmt.format_name,
    description: fmt.description ?? '',
    file: null,
    existingFileId: fmt.file ?? null,
    fields: fmt.fields.map((f, idx) => ({
      field_key: f.field_key ?? '',
      field_name_mn: f.field_name_mn ?? '',
      field_name_en: f.field_name_en ?? '',
      unit: f.unit ?? '',
      is_active: f.is_active ?? true,
      sort_order: f.sort_order ?? idx,
    })),
  }
  isModalOpen.value = true
}

function closeModal() {
  isModalOpen.value = false
}

// ─────────────────────────────────────────────
//  Field row helpers inside modal
// ─────────────────────────────────────────────
function addField() {
  modalForm.value.fields.push({
    field_key: '',
    field_name_mn: '',
    field_name_en: '',
    unit: '',
    is_active: true,
    sort_order: modalForm.value.fields.length,
  })
}

function removeField(idx: number) {
  modalForm.value.fields.splice(idx, 1)
}

function moveFieldUp(idx: number) {
  if (idx === 0) return
  const arr = modalForm.value.fields
  ;[arr[idx - 1], arr[idx]] = [arr[idx], arr[idx - 1]]
}

function moveFieldDown(idx: number) {
  const arr = modalForm.value.fields
  if (idx >= arr.length - 1) return
  ;[arr[idx], arr[idx + 1]] = [arr[idx + 1], arr[idx]]
}

// ─────────────────────────────────────────────
//  Excel → parse rows into fields + store file
// ─────────────────────────────────────────────
const SKIP_KEYS = new Set([
  'timestamp',
  'Timestamp',
  'dated_time',
  'dated_Time',
  'epochtime',
  'EpochTime',
  'Location_Code',
  'location_code',
  'Asset_Code',
  'asset_code',
])

function onExcelFileChange(e: Event) {
  const file = (e.target as HTMLInputElement).files?.[0]
  if (!file) return
  modalForm.value.file = file
  const reader = new FileReader()
  reader.onload = (ev) => {
    try {
      const wb = XLSX.read(ev.target?.result, { type: 'array' })
      const ws = wb.Sheets[wb.SheetNames[0]]
      const rows = XLSX.utils.sheet_to_json<any>(ws)
      modalForm.value.fields = rows
        .filter((r: any) => r.field_key && !SKIP_KEYS.has(String(r.field_key)))
        .map((r: any, idx: number) => ({
          field_key: String(r.field_key ?? ''),
          field_name_mn: String(r.field_name_mn ?? ''),
          field_name_en: String(r.field_name_en ?? r.field_key ?? ''),
          unit: String(r.unit ?? ''),
          is_active: true,
          sort_order: idx,
        }))
    } catch (err) {
      console.warn('Excel parse error:', err)
    }
  }
  reader.readAsArrayBuffer(file)
}

// ─────────────────────────────────────────────
//  Download datahub import template
// ─────────────────────────────────────────────
function downloadTemplate(fmt: FormatGroup) {
  const headers = ['timestamp', ...fmt.fields.map((f) => f.field_key)]
  const ws = XLSX.utils.aoa_to_sheet([headers])
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(
    wb,
    ws,
    (fmt.code || fmt.format_name).slice(0, 31),
  )
  XLSX.writeFile(wb, `${fmt.code}_template.xlsx`)
}

// ─────────────────────────────────────────────
//  Save — upload file, delete existing rows, recreate
// ─────────────────────────────────────────────
async function saveFormat() {
  if (!modalForm.value.code.trim() || !modalForm.value.format_name.trim())
    return
  isSaving.value = true
  try {
    const code = modalForm.value.code.trim()

    // Upload new file if selected
    let fileId: string | null = modalForm.value.existingFileId
    if (modalForm.value.file) {
      fileId = await uploadFileToDirectus(modalForm.value.file)
    }

    // Delete existing rows (edit mode)
    if (editingCode.value) {
      const existing = await getItems<FieldRow>({
        collection: 'Device_tracking_fields',
        params: {
          filter: {
            code: { _eq: editingCode.value },
            company_id: { _eq: myCompanyId },
          },
          fields: ['id'],
          limit: -1,
        },
      })
      const existingRows: FieldRow[] = Array.isArray(existing)
        ? existing
        : (existing as any)?.data ?? []
      if (existingRows.length > 0) {
        await deleteItems({
          collection: 'Device_tracking_fields',
          items: existingRows.map((r) => String(r.id)),
        })
      }
    }

    // Create one row per field
    const items = modalForm.value.fields
      .filter((f) => f.field_key.trim())
      .map((f, idx) => ({
        code,
        format_name: modalForm.value.format_name.trim(),
        description: modalForm.value.description.trim(),
        field_key: f.field_key.trim(),
        field_name_mn: f.field_name_mn,
        field_name_en: f.field_name_en,
        unit: f.unit,
        is_active: f.is_active,
        sort_order: idx,
        is_shared_format: true,
        company_id: myCompanyId,
        ...(fileId ? { file: fileId } : {}),
      }))

    if (items.length > 0) {
      await createItems({ collection: 'Device_tracking_fields', items })
    }

    closeModal()
    await loadFormats()
  } catch (e) {
    console.warn('Save failed:', e)
  } finally {
    isSaving.value = false
  }
}

// ─────────────────────────────────────────────
//  Delete entire format (all rows with same code)
// ─────────────────────────────────────────────
const deletingCode = ref<string | null>(null)

async function deleteFormat(fmt: FormatGroup) {
  if (!confirm(t('Delete?'))) return
  deletingCode.value = fmt.code
  try {
    const ids = fmt.fields.map((f) => f.id).filter(Boolean)
    if (ids.length > 0) {
      await Promise.all(
        ids.map((id) =>
          updateItem({
            collection: 'Device_tracking_fields',
            id: String(id),
            item: { status: 'archived' },
          }),
        ),
      )
    }
    await loadFormats()
  } catch (e) {
    console.warn('Archive failed:', e)
  } finally {
    deletingCode.value = null
  }
}
</script>

<template>
  <div class="relative">
    <!-- ── Header ── -->
    <div class="mb-4">
      <BaseButton size="sm" @click="openCreate">
        <Icon name="mdi:plus" class="-ms-1 h-4 w-4" />
        <span class="text-[11px]">{{ $t('New Format') }}</span>
      </BaseButton>
    </div>

    <!-- ── List ── -->
    <div
      v-if="listLoading"
      class="flex items-center justify-center py-12 text-muted-400"
    >
      <Icon name="mdi:loading" class="h-6 w-6 animate-spin" />
    </div>

    <div
      v-else-if="formats.length === 0"
      class="py-12 text-center text-sm text-muted-400"
    >
      {{ $t('No formats yet. Create one to get started.') }}
    </div>

    <div v-else class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <div
        v-for="fmt in formats"
        :key="fmt.code"
        class="rounded-xl border border-muted-200 bg-white p-4 dark:border-muted-800 dark:bg-muted-900"
      >
        <!-- Card header -->
        <div class="mb-3 flex items-start justify-between gap-2">
          <div>
            <div class="flex items-center gap-1.5">
              <span
                class="rounded bg-primary-100 px-1.5 py-0.5 font-mono text-[11px] font-bold text-primary-700 dark:bg-primary-900/40 dark:text-primary-300"
              >
                {{ fmt.code }}
              </span>
              <p class="text-sm font-semibold text-muted-900 dark:text-white">
                {{ fmt.format_name }}
              </p>
            </div>
            <p v-if="fmt.description" class="mt-0.5 text-xs text-muted-500">
              {{ fmt.description }}
            </p>
          </div>
          <div class="flex shrink-0 gap-1">
            <button
              class="rounded p-1 text-muted-400 hover:text-primary-500"
              :title="$t('Download Import Template')"
              @click="downloadTemplate(fmt)"
            >
              <Icon name="mdi:download" class="h-4 w-4" />
            </button>
            <a
              v-if="fmt.file"
              :href="getDownloadUrl(fmt.file)"
              target="_blank"
              class="rounded p-1 text-muted-400 hover:text-green-500"
              :title="$t('Download Format File')"
            >
              <Icon name="mdi:file-excel" class="h-4 w-4" />
            </a>
            <!-- <button
              class="rounded p-1 text-muted-400 hover:text-primary-600"
              :title="$t('Edit')"
              @click="openEdit(fmt)"
            >
              <Icon name="mdi:pencil" class="h-4 w-4" />
            </button> -->
            <button
              class="rounded p-1 text-muted-400 hover:text-red-500 disabled:opacity-40"
              :disabled="deletingCode === fmt.code"
              :title="$t('Delete')"
              @click="deleteFormat(fmt)"
            >
              <Icon
                :name="
                  deletingCode === fmt.code
                    ? 'mdi:loading'
                    : 'mdi:trash-can-outline'
                "
                :class="[
                  'h-4 w-4',
                  deletingCode === fmt.code && 'animate-spin',
                ]"
              />
            </button>
          </div>
        </div>

        <!-- Field table -->
        <div
          class="overflow-x-auto rounded-lg border border-muted-100 dark:border-muted-800"
        >
          <table class="w-full text-xs">
            <thead class="bg-muted-50 dark:bg-muted-800">
              <tr>
                <th class="px-2 py-1.5 text-left font-medium text-muted-500">
                  field_key
                </th>
                <th class="px-2 py-1.5 text-left font-medium text-muted-500">
                  МН нэр
                </th>
                <th class="px-2 py-1.5 text-left font-medium text-muted-500">
                  EN нэр
                </th>
                <th class="px-2 py-1.5 text-left font-medium text-muted-500">
                  unit
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-muted-100 dark:divide-muted-800">
              <tr
                v-for="f in fmt.fields"
                :key="f.id"
                class="hover:bg-muted-50 dark:hover:bg-muted-800/50"
              >
                <td
                  class="px-2 py-1 font-mono text-muted-800 dark:text-muted-200"
                >
                  {{ f.field_key }}
                </td>
                <td class="px-2 py-1 text-muted-600 dark:text-muted-400">
                  {{ f.field_name_mn }}
                </td>
                <td class="px-2 py-1 text-muted-600 dark:text-muted-400">
                  {{ f.field_name_en }}
                </td>
                <td class="px-2 py-1 text-muted-500">{{ f.unit }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <p class="mt-2 text-[10px] text-muted-400">
          {{ fmt.fields.length }} {{ $t('fields') }}
        </p>
      </div>
    </div>

    <!-- ─────── Create / Edit Modal ─────── -->
    <TairoModal :open="isModalOpen" size="lg" @close="closeModal">
      <template #header>
        <div class="flex w-full items-center justify-between p-4 md:p-6">
          <h3
            class="font-heading text-lg font-medium text-muted-900 dark:text-white"
          >
            {{ editingCode ? $t('Edit Format') : $t('New Format') }}
          </h3>
          <button
            class="ms-auto flex h-8 w-8 items-center justify-center rounded-full text-muted-400 hover:bg-muted-100 dark:hover:bg-muted-700"
            @click="closeModal"
          >
            <Icon name="lucide:x" class="h-4 w-4" />
          </button>
        </div>
      </template>

      <div class="space-y-4 px-4 pb-2 md:px-6">
        <!-- Code + Name + Description -->
        <div class="grid grid-cols-1 gap-3 sm:grid-cols-3">
          <div>
            <label
              class="mb-1 block text-xs font-medium text-muted-700 dark:text-muted-300"
            >
              {{ $t('Code') }} <span class="text-red-500">*</span>
            </label>
            <input
              v-model="modalForm.code"
              type="text"
              :disabled="!!editingCode"
              class="w-full rounded-lg border border-muted-200 bg-white px-3 py-2 text-sm text-muted-900 focus:border-primary-500 focus:outline-none disabled:bg-muted-50 disabled:text-muted-400 dark:border-muted-700 dark:bg-muted-900 dark:text-white"
              placeholder="FM001"
            />
          </div>
          <div>
            <label
              class="mb-1 block text-xs font-medium text-muted-700 dark:text-muted-300"
            >
              {{ $t('Format Name') }} <span class="text-red-500">*</span>
            </label>
            <input
              v-model="modalForm.format_name"
              type="text"
              class="w-full rounded-lg border border-muted-200 bg-white px-3 py-2 text-sm text-muted-900 focus:border-primary-500 focus:outline-none dark:border-muted-700 dark:bg-muted-900 dark:text-white"
              placeholder="GPS Tracker v1"
            />
          </div>
          <div>
            <label
              class="mb-1 block text-xs font-medium text-muted-700 dark:text-muted-300"
            >
              {{ $t('Description') }}
            </label>
            <input
              v-model="modalForm.description"
              type="text"
              class="w-full rounded-lg border border-muted-200 bg-white px-3 py-2 text-sm text-muted-900 focus:border-primary-500 focus:outline-none dark:border-muted-700 dark:bg-muted-900 dark:text-white"
              :placeholder="$t('Optional')"
            />
          </div>
        </div>

        <!-- Excel upload -->
        <div>
          <label
            class="mb-1 block text-xs font-medium text-muted-700 dark:text-muted-300"
          >
            {{ $t('Upload Format Excel') }}
          </label>
          <label
            class="flex cursor-pointer items-center gap-2 rounded-lg border-2 border-dashed border-muted-300 px-4 py-3 text-sm text-muted-500 hover:border-primary-400 hover:text-primary-500 dark:border-muted-700"
          >
            <Icon
              name="mdi:file-excel-outline"
              class="h-5 w-5 shrink-0 text-green-500"
            />
            <span class="truncate">{{
              modalForm.file
                ? modalForm.file.name
                : modalForm.existingFileId
                ? $t('File uploaded — choose new to replace')
                : $t('Choose Excel (.xlsx)')
            }}</span>
            <input
              type="file"
              accept=".xlsx,.xls"
              class="hidden"
              @change="onExcelFileChange"
            />
          </label>
          <p class="mt-1 text-[10px] text-muted-400">
            {{ $t('Rows: field_key | field_name_mn | field_name_en | unit') }}
          </p>
        </div>

        <!-- Field list -->
        <div>
          <div class="mb-2 flex items-center justify-between">
            <label
              class="text-xs font-medium text-muted-700 dark:text-muted-300"
            >
              {{ $t('Fields') }} ({{ modalForm.fields.length }})
            </label>
            <!-- <button
              class="flex items-center gap-1 rounded-lg border border-primary-500 px-2 py-1 text-[11px] text-primary-600 hover:bg-primary-50 dark:border-primary-400 dark:text-primary-400"
              type="button"
              @click="addField"
            >
              <Icon name="mdi:plus" class="h-3.5 w-3.5" />
              {{ $t('Add') }}
            </button> -->
          </div>

          <div
            v-if="modalForm.fields.length === 0"
            class="rounded-lg border border-dashed border-muted-200 py-6 text-center text-xs text-muted-400 dark:border-muted-700"
          >
            {{ $t('Upload an Excel file or add fields manually.') }}
          </div>

          <div v-else class="max-h-72 overflow-y-auto pr-1">
            <div
              class="mb-1 grid gap-1 px-1 text-[10px] font-medium uppercase text-muted-400"
              style="grid-template-columns: 20px 1fr 1fr 1fr 52px 20px"
            >
              <span />
              <span>field_key</span>
              <span>field_name_mn</span>
              <span>field_name_en</span>
              <span>unit</span>
              <span />
            </div>

            <div
              v-for="(field, idx) in modalForm.fields"
              :key="idx"
              class="mb-1 grid items-center gap-1"
              style="grid-template-columns: 20px 1fr 1fr 1fr 52px 20px"
            >
              <div class="flex flex-col items-center">
                <button
                  type="button"
                  class="text-muted-300 hover:text-muted-600"
                  @click="moveFieldUp(idx)"
                >
                  <Icon name="mdi:chevron-up" class="h-3.5 w-3.5" />
                </button>
                <button
                  type="button"
                  class="text-muted-300 hover:text-muted-600"
                  @click="moveFieldDown(idx)"
                >
                  <Icon name="mdi:chevron-down" class="h-3.5 w-3.5" />
                </button>
              </div>
              <input
                v-model="field.field_key"
                type="text"
                class="rounded border border-muted-200 bg-white px-2 py-1 text-xs text-muted-900 focus:border-primary-400 focus:outline-none dark:border-muted-700 dark:bg-muted-900 dark:text-white"
                placeholder="field_key"
              />
              <input
                v-model="field.field_name_mn"
                type="text"
                class="rounded border border-muted-200 bg-white px-2 py-1 text-xs text-muted-900 focus:border-primary-400 focus:outline-none dark:border-muted-700 dark:bg-muted-900 dark:text-white"
                placeholder="Mongolian name"
              />
              <input
                v-model="field.field_name_en"
                type="text"
                class="rounded border border-muted-200 bg-white px-2 py-1 text-xs text-muted-900 focus:border-primary-400 focus:outline-none dark:border-muted-700 dark:bg-muted-900 dark:text-white"
                placeholder="English"
              />
              <input
                v-model="field.unit"
                type="text"
                class="rounded border border-muted-200 bg-white px-2 py-1 text-xs text-muted-900 focus:border-primary-400 focus:outline-none dark:border-muted-700 dark:bg-muted-900 dark:text-white"
                placeholder="unit"
              />
              <button
                type="button"
                class="flex items-center justify-center text-muted-300 hover:text-red-500"
                @click="removeField(idx)"
              >
                <Icon name="mdi:close" class="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <template #footer>
        <div class="flex justify-end gap-2 p-4 md:p-6">
          <BaseButton color="muted" size="sm" @click="closeModal">
            {{ $t('Cancel') }}
          </BaseButton>
          <BaseButton
            color="primary"
            size="sm"
            :disabled="
              isSaving ||
              !modalForm.code.trim() ||
              !modalForm.format_name.trim()
            "
            @click="saveFormat"
          >
            <Icon
              v-if="isSaving"
              name="mdi:loading"
              class="me-1 h-4 w-4 animate-spin"
            />
            {{ isSaving ? $t('Saving...') : $t('Save') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>
  </div>
</template>
