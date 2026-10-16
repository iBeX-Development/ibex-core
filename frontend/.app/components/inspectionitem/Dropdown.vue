<script setup lang="ts">
import { isProxy, toRaw } from 'vue'
import { useI18n } from 'vue-i18n'

const runtimeConfig = useRuntimeConfig()
import DocumentCommentModal from '~/components/form/DocumentCommentModal.vue'

const { t } = useI18n({ useScope: 'global' })
const { params } = useRoute()
const { getItemById, createItems, updateItem, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const props = defineProps([
  'parent',
  'refresh',
  'item',
  'code',
  'template_type',
  'template_types',
  'children',
  'freeze',
  'work_item',
  'name',
])

const loading = ref(false)
const myId = window.localStorage.getItem('myId')

//files
const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selected = ref([])
const selectAll = ref(false)
const rowData = ref([])
const uploadedFiles = ref([])
const files = ref(false)
const isOpenImg = ref(false)
const key = ref(1)

const handleAddTask = async () => {
  await createItems({
    collection: 'Work_inspection_item',
    items: [
      {
        status: 1,
        label: 'Label',
        workorder: props.code,
        parent: props.item,
        template_type: props.template_type?.id,
        name: 'Default text',
        created_type: 'user',
        company_id: myCompanyId,
      },
    ],
  }).then((addItem) => {
    let type = props.template_type
    if (isProxy(props.template_type)) {
      type = toRaw(props.template_type)
    }
    addItem[0].template_type = type

    if (props.refresh) props.refresh('add', addItem[0])
  })
}
const handleRemoveTask = async () => {
  const updateData = {
    collection: 'Work_inspection_item',
    id: props.item,
    item: {
      active: 0,
    },
  }
  await updateItem(updateData)
  if (props.refresh) props.refresh('remove')
}

const handleParentTask = async () => {
  const updateData = {
    collection: 'Work_inspection_item',
    id: props.item,
    item: {
      parent: null,
    },
  }
  await updateItem(updateData).then((item) => {
    let chosenType = props.template_types.find(
      (type) => type.id === item.template_type,
    )
    let type = chosenType
    if (isProxy(chosenType)) {
      type = toRaw(chosenType)
    }
    item.template_type = type
    if (props.refresh) props.refresh('root', item)
  })
}

const handleUploadPhoto = async () => {
  // console.log('handleUploadPhoto')
  // const updateData = {
  //   collection: 'Work_inspection_item',
  //   id: props.item,
  //   item: {
  //     parent: null,
  //   },
  // }
  // await updateItem(updateData).then((item) => {
  //   let chosenType = props.template_types.find(
  //     (type) => type.id === item.template_type,
  //   )
  //   let type = chosenType
  //   if (isProxy(chosenType)) {
  //     type = toRaw(chosenType)
  //   }
  //   item.template_type = type
  //   if (props.refresh) props.refresh('root', item)
  // })
}

//files many-to-mamy
const addFiles = async (type) => {
  isModalOpen.value = true
}

const deleteFiles = async () => {
  // await deleteItems({
  //   collection: 'Transaction_files',
  //   items: selected.value,
  // })
  // await loadComments()
}

const closeFiles = async () => {
  isModalOpen.value = false
  isOpenImg.value = false
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)

  // console.log(isModalOpen.value)
}

const closeWindow = () => {
  isModalOpen.value = false
  isOpenImg.value = false
}

const refresh = () => {
  console.log('refresh')

  // if (isRemoveAccepted.value) {
  //   if (props.successfullText) {
  //     toaster.show({
  //       title: t('Success'),
  //       message: t(`Successfully`),
  //       color: 'success',
  //       icon: 'ph:check',
  //       closable: true,
  //     })
  //   }

  //   isRemoveAccepted.value = false
  //   props.do_make(props.work_item, props.actionType)
  //   props.close()
  //   if (props.refresh) props.refresh()
  //   if (props.clear) props.clear()
  // }
}

const handleUploadRead = async (items) => {
  // console.log('handleUploadRead', items)
  // console.log('work_item', props.work_item)
  uploadedFiles.value = [...rowData.value, ...items]
  rowData.value = [...rowData.value, ...items]
  let added_items = []
  if (uploadedFiles.value.length) {
    let file_items = {
      photos: {
        create: [],
      },
    }
    uploadedFiles.value.forEach((row) => {
      added_items.push({
        Work_inspection_item_id: props.work_item.id,
        directus_files_id: row.file,
      })
      return file_items['photos']['create'].push({
        Work_inspection_item_id: props.work_item.id,
        directus_files_id: {
          id: row.file.id,
        },
      })
    })

    // console.log('file_items', file_items)
    const res = await updateItem({
      collection: 'Work_inspection_item',
      id: props.work_item.id,
      item: file_items,
    })
    if (props.refresh) props.refresh('file', added_items)

    // console.log('res', res)
  }
}

// console.log('action_photos', props.work_item)
</script>
<template>
  <BaseDropdown
    v-if="!props.freeze"
    flavor="context"
    label="Dropdown"
    orientation="end"
    condensed
    shape="curved"
    class="absolute mt-[-18px]"
  >
    <div class="">
      <BaseDropdownItem
        :title="t('Add')"
        :text="t('Add sub task')"
        @click="handleAddTask"
      >
        <template #start>
          <Icon name="ph:pencil-line-fill" class="me-2 block h-5 w-5" />
        </template>
      </BaseDropdownItem>
      <BaseDropdownDivider />
      <BaseDropdownItem
        :title="t('Make root')"
        :text="t('Makes task to root')"
        @click="handleParentTask"
      >
        <template #start>
          <Icon name="ph:pencil-line-fill" class="me-2 block h-5 w-5" />
        </template>
      </BaseDropdownItem>
      <BaseDropdownDivider />
      <BaseDropdownItem
        :title="t('Upload photo')"
        :text="t('Insert photo of your task')"
        @click="addFiles"
      >
        <template #start>
          <Icon name="ph:pencil-line-fill" class="me-2 block h-5 w-5" />
        </template>
      </BaseDropdownItem>
      <BaseDropdownDivider />
      <BaseDropdownItem
        :title="t('Remove')"
        :text="t('Remove from list')"
        @click="handleRemoveTask"
      >
        <template #start>
          <Icon name="ph:trash-duotone" class="me-2 block h-5 w-5" />
        </template>
      </BaseDropdownItem>
    </div>
  </BaseDropdown>
  <DocumentCommentModal
    size="lg"
    :key="key"
    title="File upload"
    :open="isModalOpen"
    :close="closeFiles"
    :files="files"
    :handleUploadRead="handleUploadRead"
    :row="selectedItem"
    :refresh="refresh"
    :item_id="props.work_item?.id"
  />
</template>
