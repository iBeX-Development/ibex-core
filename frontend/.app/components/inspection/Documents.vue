<script setup lang="ts">
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import DocumentModalForm from '~/components/form/DocumentModalForm.vue'

const { createItems, deleteItems, getItems } = useDirectusItems()
const { t } = useI18n({ useScope: 'global' })

const config = useRuntimeConfig()
const props = defineProps(['work_order', 'loadDocs', 'active_tab'])

const loading = ref(false)
const selected = ref([])
const selectAll = ref(false)
const rowData = ref([])
// const { params } = useRoute();

const isModalOpen = ref(false)
const selectedItem = ref(-1)
const key = ref(1)

const emit = defineEmits(['update:loadDocs'])

const deleteRows = async () => {
  await deleteItems({
    collection: 'Work_inspection_files',
    items: selected.value,
  })
  await loadItems()
}

const addEmptyRow = () => {
  isModalOpen.value = true
}

const loadItems = async () => {
  // console.log('Documents.vue', props.work_order)
  // console.log('Documents.vue id', props.work_order?.completed_at)
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: props.work_order?.id,
    }
    const items = await getItems<any>({
      collection: 'Work_inspection_files',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*', 'file.*', 'work_order.* '],
      },
    })
    rowData.value = items.data
    emit('update:loadDocs', items.data)

    // console.log('Documents.vue', items.data)
    loading.value = false
  } catch (e) {}
}

onMounted(async () => {
  if (props.loadDocs) {
    rowData.value = props.loadDocs
    loading.value = false
    console.log('docs-loaded', props.loadDocs)
  } else await loadItems()
})

const get_content_url = (file) => {
  //http://localhost:3001/_nuxt/img/avatars/placeholder-file.png
  if (file?.type.includes('image')) {
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
</script>

<template>
  <div class="relative">
    <!-- Grid props.work_order?.wo_status.id !== 3 -->
    <div class="grid grid-cols-12 gap-6">
      <div
        v-if="
          props.work_order?.action_status !== 2 &&
          props.active_tab == 'inspection_templates'
        "
        class="col-span-12"
      >
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
      <div class="col-span-12 min-h-[450px]">
        <TairoTable rounded="sm">
          <template #header>
            <TairoTableHeading uppercase class="p-4">
              <div class="flex items-center"></div>
            </TairoTableHeading>

            <TairoTableHeading uppercase>
              {{ t('File name') }}
            </TairoTableHeading>

            <TairoTableHeading uppercase>
              {{ t('File description') }}
            </TairoTableHeading>

            <TairoTableHeading uppercase>
              {{ t('File tag') }}
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

            <TairoTableCell v-if="row.file">
              <div class="flex items-center">
                <BaseAvatar :src="get_content_url(row.file)" size="sm" />

                <div class="ms-3 leading-none">
                  <h4 class="font-sans text-sm font-medium">
                    <a
                      class="no-underline hover:underline text-cyan-600 dark:text-cyan-400"
                      target="_blank"
                      rel="noopener noreferrer"
                      :href="get_content_url(row.file)"
                      >{{ row.file?.title }}</a
                    >
                  </h4>

                  <p class="text-muted-400 font-sans text-xs font-normal">
                    {{ row.file?.description }}
                  </p>
                </div>
              </div>
            </TairoTableCell>

            <TairoTableCell light>
              {{ row.file?.description }}
            </TairoTableCell>

            <TairoTableCell>{{ row.file?.tags }}</TairoTableCell>
          </TairoTableRow>
        </TairoTable>
      </div>
      <DocumentModalForm
        :title="$t('File upload')"
        collection="Work_inspection_files"
        :key="selectedItem"
        :open="isModalOpen"
        :close="handleModalClose"
        :row="selectedItem"
        :refresh="loadItems"
        size="lg"
        :work_order_id="props.work_order?.id"
      />
    </div>
  </div>
</template>
