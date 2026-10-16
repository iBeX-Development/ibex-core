<script setup lang="ts">
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import DocumentTransactionModalForm from '~/components/form/DocumentTransactionModalForm.vue'

const { createItems, deleteItems, getItems } = useDirectusItems()
const { t } = useI18n({ useScope: 'global' })

const config = useRuntimeConfig()
const props = defineProps({
  handleUpload: Function,
  transaction_id: Number,
  uploadedFiles: Object,
  transaction_data: Object,
})

const loadItems = async () => {
  // console.log('Documents.vue', props.transaction_id)
  // console.log('Documents.vue id', props.transaction_id)
  loading.value = true
  try {
    const filters = {
      transaction_id: props.transaction_id,
    }
    const items = await getItems<any>({
      collection: 'Transaction_files',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*', 'file.*'],
      },
    })

    rowData.value = items.data
    loading.value = false
  } catch (e) {}
}

const loading = ref(false)
const selected = ref([])
const selectAll = ref(false)
const rowData = ref([])
const rowFiles = ref([])

const files = ref(false)
// const { params } = useRoute();

const isModalOpen = ref(false)
const selectedItem = ref(-1)
const key = ref(1)

const deleteRows = async () => {
  // Only pass integer Transaction_files record IDs — not UUID file IDs
  const dbIds = selected.value.filter((id) => Number.isInteger(id))
  if (dbIds.length) {
    try {
      await deleteItems({
        collection: 'Transaction_files',
        items: dbIds,
      })
    } catch (e) {
      console.error('Delete error', e)
    }
  }
  // Remove selected rows from local rowData (covers both DB and pending uploads)
  rowData.value = rowData.value.filter(
    (row) => !selected.value.includes(row.id ?? row.file?.id),
  )
  selected.value = []
  if (props.transaction_id > 0) {
    await loadItems()
  }
}

const addEmptyRow = () => {
  isModalOpen.value = true
}

onMounted(async () => {
  if (props.uploadedFiles?.length) {
    rowData.value = props.uploadedFiles
  } else if (props.transaction_id > 0) {
    await loadItems()
  }

  // console.log('onMounted_items_transaction_id', props.transaction_id)
})

const get_content_url = (file, is_path = false) => {
  if (!file?.type.includes('image') && !is_path) {
    return `/img/avatars/placeholder-file.png`
  }

  if (file?.type) {
    return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
  } else {
    return `/img/avatars/placeholder-file.png`
  }
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log(isModalOpen.value)
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleUploadRead = async (items) => {
  rowData.value = [...rowData.value, ...items]
  rowFiles.value = [...rowData.value, ...items]
  props.handleUpload(rowData.value)
}
</script>

<template>
  <div class="docs-wrap px-6 py-5">
    <!-- Action bar -->
    <div v-if="props.transaction_data?.status != 2" class="docs-toolbar">
      <span class="docs-title">
        <Icon name="ph:paperclip-duotone" class="size-4 me-1.5 opacity-70" />
        {{ t('Documents') }}
        <span v-if="rowData.length" class="docs-count">{{
          rowData.length
        }}</span>
      </span>
      <div class="flex gap-2">
        <button
          v-if="selected.length"
          type="button"
          class="docs-btn docs-btn-danger"
          @click="deleteRows"
        >
          <Icon name="ph:trash-duotone" class="size-3.5 me-1" />
          {{ t('Delete') }} ({{ selected.length }})
        </button>
        <button
          type="button"
          class="docs-btn docs-btn-primary"
          @click="addEmptyRow"
        >
          <Icon name="ph:upload-simple-bold" class="size-3.5 me-1" />
          {{ t('Add file') }}
        </button>
      </div>
    </div>

    <!-- Empty state -->
    <div v-if="rowData.length === 0" class="docs-empty">
      <Icon name="ph:files-duotone" class="size-10 opacity-30 mb-2" />
      <p class="text-sm text-muted-400">{{ t('No documents') }}</p>
    </div>

    <!-- File list -->
    <div v-else class="docs-list">
      <div
        v-for="row in rowData"
        :key="row.id"
        class="docs-row"
        :class="{ 'docs-row--selected': selected.includes(row.id) }"
      >
        <BaseCheckbox
          v-model="selected"
          :value="row.id ?? row.file?.id"
          rounded="sm"
          color="primary"
          class="shrink-0"
        />
        <div class="docs-row-thumb">
          <img
            :src="get_content_url(row.file, false)"
            :alt="row.file?.title"
            class="docs-thumb"
          />
        </div>
        <div class="docs-row-info">
          <a
            class="docs-filename"
            :href="get_content_url(row.file, true)"
            target="_blank"
            rel="noopener noreferrer"
            >{{ row.file?.title }}</a
          >
          <span class="docs-filedesc">{{ row.file?.description }}</span>
        </div>
        <div class="docs-row-tags">
          <span v-if="row.file?.tags" class="docs-tag">{{
            row.file.tags
          }}</span>
        </div>
      </div>
    </div>

    <DocumentTransactionModalForm
      title="File upload"
      :key="selectedItem"
      :open="isModalOpen"
      :files="files"
      :handleUploadRead="handleUploadRead"
      :close="handleModalClose"
      :row="selectedItem"
      :refresh="loadItems"
      size="lg"
      :transaction_id="props.transaction_id"
    />
  </div>
</template>

<style>
.docs-wrap {
  padding: 8px 4px;
}
.docs-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
  padding-bottom: 8px;
  border-bottom: 1px solid #e5e7eb;
}
.dark .docs-toolbar {
  border-bottom-color: #27272a;
}
.docs-title {
  font-size: 13px;
  font-weight: 600;
  color: #6b7280;
  display: flex;
  align-items: center;
}
.docs-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 18px;
  height: 18px;
  border-radius: 999px;
  background: #e5e7eb;
  font-size: 10px;
  font-weight: 700;
  color: #374151;
  margin-left: 6px;
}
.docs-btn {
  display: inline-flex;
  align-items: center;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: background 0.15s;
}
.docs-btn-primary {
  background: #8b5cf6;
  color: #fff;
}
.docs-btn-primary:hover {
  background: #7c3aed;
}
.docs-btn-danger {
  background: #fee2e2;
  color: #dc2626;
}
.docs-btn-danger:hover {
  background: #fecaca;
}
.docs-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px 0;
  color: #9ca3af;
}
.docs-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.docs-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 6px 8px;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
  background: #fff;
  transition: background 0.12s;
}
.dark .docs-row {
  background: #18181b;
  border-color: #27272a;
}
.docs-row--selected {
  border-color: #6366f1;
  background: #eef2ff;
}
.dark .docs-row--selected {
  background: #1e1b4b;
}
.docs-row-thumb {
  width: 36px;
  height: 36px;
  flex-shrink: 0;
}
.docs-thumb {
  width: 36px;
  height: 36px;
  object-fit: cover;
  border-radius: 6px;
  border: 1px solid #e5e7eb;
}
.docs-row-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}
.docs-filename {
  font-size: 13px;
  font-weight: 500;
  color: #0891b2;
  text-decoration: none;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.docs-filename:hover {
  text-decoration: underline;
}
.docs-filedesc {
  font-size: 11px;
  color: #9ca3af;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.docs-row-tags {
  flex-shrink: 0;
}
.docs-tag {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 999px;
  background: #fef3c7;
  color: #92400e;
  font-size: 11px;
  font-weight: 500;
}
</style>
