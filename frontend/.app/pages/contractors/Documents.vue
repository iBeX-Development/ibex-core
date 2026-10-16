<script setup lang="ts">
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import DocumentsModalForm from '~/components/form/DocumentsModalForm.vue'

const { createItems, deleteItems, getItems } = useDirectusItems()
const { t } = useI18n({ useScope: 'global' })

const config = useRuntimeConfig()
const props = defineProps({
  handleUpload: Function,
  item_id: Number,
  uploadedFiles: Object,
  transaction_data: Object,
})

const loadItems = async () => {
  // console.log('Documents.vue', props.item_id)
  // console.log('Documents.vue id', props.item_id)
  loading.value = true
  try {
    const filters = {
      contract_id: props.item_id,
    }
    const items = await getItems<any>({
      collection: 'contracts_files',
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
  await deleteItems({
    collection: 'contracts_files',
    items: selected.value,
  })
  await loadItems()
}

const addEmptyRow = () => {
  isModalOpen.value = true
}

onMounted(async () => {
  if (props.uploadedFiles?.length) {
    rowData.value = props.uploadedFiles
  } else if (props.item_id > 0) {
    await loadItems()
  }

  // console.log('onMounted_items_item_id', props.item_id)
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
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <div class="col-span-12">
        <BaseButton class="float-right" @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Document delete') }}</span>
        </BaseButton>

        <BaseButton class="float-right mr-10" @click="addEmptyRow">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Document add') }}</span>
        </BaseButton>
      </div>
      <!-- Header -->
      <div class="col-span-12">
        <TairoTable rounded="sm">
          <template #header>
            <TairoTableHeading class="p-4">
              <div class="flex items-center"></div>
            </TairoTableHeading>

            <TairoTableHeading>
              {{ t('File name') }}
            </TairoTableHeading>

            <TairoTableHeading>
              {{ t('File description') }}
            </TairoTableHeading>
          </template>
          <TairoTableRow v-if="rowData.length == 0">
            <TairoTableCell class="p-4">
              <div class="flex items-center">
                <BaseCheckbox
                  v-model="selected"
                  :value="`table-4`"
                  rounded="sm"
                  color="primary"
                />
              </div>
            </TairoTableCell>

            <TairoTableCell>
              {{ t('No documents') }}
            </TairoTableCell>

            <TairoTableCell light> </TairoTableCell>

            <TairoTableCell> </TairoTableCell>
          </TairoTableRow>
          <TairoTableRow v-for="row in rowData" :key="row.id">
            <TairoTableCell class="p-4">
              <div class="flex items-center">
                <BaseCheckbox
                  v-model="selected"
                  :value="row.id"
                  rounded="sm"
                  color="primary"
                />
              </div>
            </TairoTableCell>

            <TairoTableCell>
              <div class="flex items-center">
                <BaseAvatar :src="get_content_url(row.file, false)" size="sm" />

                <div class="ms-3 leading-none">
                  <h4 class="font-sans text-sm font-medium">
                    <a
                      class="no-underline hover:underline text-cyan-600 dark:text-cyan-400"
                      :href="get_content_url(row.file, true)"
                      target="_blank"
                      rel="noopener noreferrer"
                      >{{ row.file.title }}</a
                    >
                  </h4>

                  <p class="text-muted-400 font-sans text-xs font-normal">
                    {{ row.file.description }}
                  </p>
                </div>
              </div>
            </TairoTableCell>

            <TairoTableCell light>
              {{ row.file.description }}
            </TairoTableCell>

            <TairoTableCell>{{ row.file.tags }}</TairoTableCell>
          </TairoTableRow>
        </TairoTable>
      </div>
      <DocumentsModalForm
        title="File upload"
        :key="selectedItem"
        :open="isModalOpen"
        :files="files"
        :handleUploadRead="handleUploadRead"
        :close="handleModalClose"
        :row="selectedItem"
        :refresh="loadItems"
        size="lg"
        class="Contract"
        :item_id="props.item_id"
      />
    </div>
  </div>
</template>
