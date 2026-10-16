<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import PartsOfAssetImportModal from '~/components/parts/PartsOfAssetImportModal.vue'
import { usePartsOfAssetImport } from '~/composables/usePartsOfAssetImport'

const { open } = usePanels()
const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Parts of Asset',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})

const isPartsOfAssetImportModalOpen = ref(false)
const { importPartsOfAsset } = usePartsOfAssetImport()
const config = useRuntimeConfig()
const { token } = useDirectusToken()

// Import history from Directus Parts_import_history collection
interface ImportHistoryEntry {
  id?: number
  file_name: string
  date_created: string
  user_created: { first_name?: string; email?: string } | null
  created_count: number
  updated_count: number
  skipped_count: number
}

const importHistory = ref<ImportHistoryEntry[]>([])

async function loadHistory() {
  try {
    importHistory.value = await getItems({
      collection: 'Parts_import_history',
      params: {
        filter: {
          company_id: { _eq: myCompanyId },
        },
        fields: [
          'id',
          'file_name',
          'created_count',
          'updated_count',
          'skipped_count',
          'date_created',
          'user_created.first_name',
          'user_created.email',
        ],
        sort: ['-date_created'],
        limit: 50,
      },
    })
  } catch (e) {
    console.warn('Failed to load import history:', e)
  }
}

onMounted(loadHistory)

// File upload to Directus /files
async function uploadFileToDirectus(file: File): Promise<string | null> {
  const baseUrl = ((config.public.directus as any)?.url ?? '').replace(
    /\/$/,
    '',
  )
  const formData = new FormData()
  formData.append('file', file, file.name)
  try {
    const response = await $fetch<{ data: { id: string } }>(
      `${baseUrl}/files`,
      {
        method: 'POST',
        body: formData,
        headers: token.value ? { Authorization: `Bearer ${token.value}` } : {},
      },
    )
    return response?.data?.id ?? null
  } catch (e) {
    console.warn('File upload failed:', e)
    return null
  }
}

// Helpers for file_name field (stored as "fileId::originalName")
function getFileId(fileNameField: string): string | null {
  const idx = fileNameField?.indexOf('::')
  return idx > 0 ? fileNameField.slice(0, idx) : null
}
function getDisplayName(fileNameField: string): string {
  const idx = fileNameField?.indexOf('::')
  return idx > 0 ? fileNameField.slice(idx + 2) : fileNameField ?? ''
}
function getDownloadUrl(fileNameField: string): string {
  const fileId = getFileId(fileNameField)
  const baseUrl = ((config.public.directus as any)?.url ?? '').replace(
    /\/$/,
    '',
  )
  return fileId ? `${baseUrl}/assets/${fileId}?download` : '#'
}

const handleImportPartsOfAssetsClick = () => {
  isPartsOfAssetImportModalOpen.value = true
}

const handleImport = async (
  rows: any[],
  fileName: string,
  file?: File | null,
) => {
  // Upload the Excel file to Directus Files first
  let fileId: string | null = null
  if (file) {
    fileId = await uploadFileToDirectus(file)
  }

  const result = await importPartsOfAsset(rows, 0)
  if (result && result.success) {
    try {
      await createItems({
        collection: 'Parts_import_history',
        items: [
          {
            file_name: fileId
              ? `${fileId}::${fileName}`
              : fileName || 'unknown',
            created_count: result.created,
            updated_count: result.updated,
            skipped_count: result.skipped,
            company_id: myCompanyId,
          },
        ],
      })
      await loadHistory()
    } catch (e) {
      console.warn('Failed to save import history:', e)
    }
  }
  isPartsOfAssetImportModalOpen.value = false
}
</script>

<template>
  <div class="relative">
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        &nbsp;
        <BaseButton class="" @click="handleImportPartsOfAssetsClick">
          <Icon name="octicon:upload-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Import Parts Of Asset') }}</span>
        </BaseButton>
      </div>

      <!-- Import History Table -->
      <div class="col-span-12" v-if="importHistory.length > 0">
        <div
          class="rounded-lg border border-muted-200 bg-white dark:border-muted-800 dark:bg-muted-900"
        >
          <div
            class="border-b border-muted-200 px-4 py-3 dark:border-muted-800"
          >
            <h3 class="text-sm font-semibold text-muted-900 dark:text-white">
              {{ $t('Import History') }}
            </h3>
          </div>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead class="bg-muted-50 dark:bg-muted-800">
                <tr>
                  <th
                    class="px-4 py-2 text-left text-xs font-medium text-muted-500 dark:text-muted-400"
                  >
                    {{ $t('File Name') }}
                  </th>
                  <th
                    class="px-4 py-2 text-left text-xs font-medium text-muted-500 dark:text-muted-400"
                  >
                    {{ $t('Date') }}
                  </th>
                  <th
                    class="px-4 py-2 text-left text-xs font-medium text-muted-500 dark:text-muted-400"
                  >
                    {{ $t('User') }}
                  </th>
                  <th
                    class="px-4 py-2 text-center text-xs font-medium text-muted-500 dark:text-muted-400"
                  >
                    {{ $t('Created') }}
                  </th>
                  <th
                    class="px-4 py-2 text-center text-xs font-medium text-muted-500 dark:text-muted-400"
                  >
                    {{ $t('Updated') }}
                  </th>
                  <th
                    class="px-4 py-2 text-center text-xs font-medium text-muted-500 dark:text-muted-400"
                  >
                    {{ $t('Skipped') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-muted-100 dark:divide-muted-800">
                <tr
                  v-for="(entry, idx) in importHistory"
                  :key="idx"
                  class="hover:bg-muted-50 dark:hover:bg-muted-800/50"
                >
                  <td
                    class="px-4 py-2 font-mono text-xs text-muted-700 dark:text-muted-300"
                  >
                    <a
                      v-if="getFileId(entry.file_name)"
                      :href="getDownloadUrl(entry.file_name)"
                      target="_blank"
                      class="text-primary-600 hover:text-primary-700 hover:underline dark:text-primary-400"
                    >
                      <Icon
                        name="mdi:file-download-outline"
                        class="me-1 h-3.5 w-3.5"
                      />
                      {{ getDisplayName(entry.file_name) }}
                    </a>
                    <span v-else>{{ entry.file_name }}</span>
                  </td>
                  <td
                    class="px-4 py-2 text-xs text-muted-600 dark:text-muted-400"
                  >
                    {{
                      entry.date_created
                        ? new Date(entry.date_created).toLocaleString()
                        : ''
                    }}
                  </td>
                  <td
                    class="px-4 py-2 text-xs text-muted-600 dark:text-muted-400"
                  >
                    {{
                      entry.user_created?.first_name ||
                      entry.user_created?.email ||
                      '—'
                    }}
                  </td>
                  <td class="px-4 py-2 text-center">
                    <span
                      class="rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700 dark:bg-green-900/30 dark:text-green-400"
                    >
                      {{ entry.created_count }}
                    </span>
                  </td>
                  <td class="px-4 py-2 text-center">
                    <span
                      class="rounded-full bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-700 dark:bg-blue-900/30 dark:text-blue-400"
                    >
                      {{ entry.updated_count }}
                    </span>
                  </td>
                  <td class="px-4 py-2 text-center">
                    <span
                      class="rounded-full bg-yellow-100 px-2 py-0.5 text-xs font-medium text-yellow-700 dark:bg-yellow-900/30 dark:text-yellow-400"
                    >
                      {{ entry.skipped_count }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- Parts of Asset Import Modal -->
    <PartsOfAssetImportModal
      :is-open="isPartsOfAssetImportModalOpen"
      :location-id="0"
      @close="isPartsOfAssetImportModalOpen = false"
      @import="(rows, fileName, file) => handleImport(rows, fileName, file)"
    />
  </div>
</template>
