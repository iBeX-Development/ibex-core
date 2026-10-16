<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    task?: any
    project?: any
    reloadItem?: any
    do_make?: any
  }>(),
  {
    task: undefined,
    project: undefined,
    reloadItem: undefined,
    do_make: undefined,
  },
)

const { close } = usePanels()
import { useI18n } from 'vue-i18n'
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import { statuses } from '~/components/workorder/ProjectConstants'
import EditWorkModalForm from '../../pages/projects/add/EditWorkModalForm.vue'
import AddDocuments from '../../pages/projects/details/AddDocuments.vue'
import AddTaskModalForm from '../../pages/projects/details/AddTaskModalForm.vue'
const toaster = useToaster()
const { t } = useI18n({ useScope: 'global' })
const route = useRoute()
const router = useRouter()

// import ProgressComp from '~/components/global/ProgressComp.vue'
// import WarningModalForm from '~/components/form/WarningModalForm.vue'

const { getItems, updateItem, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const key = ref(1)
const user = useDirectusUser()
const config = useRuntimeConfig()

const commentArea = ref('')
const commentAreaEdit = ref('')
const isEditCommentArea = ref(false)
const isModalNewFile = ref(false)
const isModalEditWork = ref(false)
const isModalNewTask = ref(false)
const isModalEditTask = ref(false)
const isModalEditTaskId = ref(-1)
const editTask = ref([])
const isModalApproveConfirmOpen = ref(false)
const itemsValue = ref(-1)
const progressComponent = ref(null)
const uploadedFiles = ref([])
const editFiles = ref([])

const myId = window.localStorage.getItem('myId')
const userImgId = ref(null)
const task_id = ref(-1)
const project_id = ref(-1)
const my_name = ref('')
const my_id = ref('')
const userImgUrl = ref(null)

// ---------- files section  -------------
const loading = ref(false)
const selected = ref([])
const selectAll = ref(false)
const rowData = ref([])
const rowFiles = ref([])
const fileName = ref('')
const selectedItem = ref(-1)

const statusValue = ref({
  id: 1,
  text: 'Status',
  icon: 'mdi:progress-clock',
})
// const { params } = useRoute();

const loadFiles = async () => {
  // console.log('Documents.vue', task_id)
  // console.log('Documents.vue id', task_id)
  loading.value = true
  try {
    const filters = {
      project_work: task_id.value,
    }

    // console.log('filters.vue id', filters)

    const items = await getItems<any>({
      collection: 'Project_work_files',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: [
          '*',
          'file.*',
          'user_created.*',
          'user_created.avatar.*',
          'user_created.role.*',
        ],
      },
    })

    rowData.value = items.data
    // console.log('loadFiles', rowData.value)

    if (items.data.length) {
      let filesList = items.data.map((item) => {
        const file = item.file || {}
        const user = item.user_created || {}

        // Convert file size from bytes to KB/MB/GB for readability
        const fileSizeInKB = file.filesize / 1024 // Convert bytes to KB
        let fileSize = fileSizeInKB.toFixed(2) + ' KB' // Default size in KB
        if (fileSizeInKB > 1024) {
          const fileSizeInMB = fileSizeInKB / 1024 // Convert to MB
          fileSize = fileSizeInMB.toFixed(2) + ' MB'
        }
        if (fileSizeInKB > 1024 * 1024) {
          const fileSizeInGB = fileSizeInKB / (1024 * 1024) // Convert to GB
          fileSize = fileSizeInGB.toFixed(2) + ' GB'
        }

        return {
          row_id: item.id,
          id: file.id,
          file_name: item.file_name,
          type: file.type,
          filename_disk: file.filename_disk || 'filename_disk',
          name: file.filename_disk || 'Unnamed File', // Default fallback for missing name
          icon: get_file_type(file), // Ensure get_file_type() is defined correctly
          size: fileSize,
          version: '1.8.2', // Static version, could be dynamic if needed
          uploaded: file.uploaded_on || 'N/A', // Fallback if 'uploaded_on' is missing
          author: {
            id: user.id || 'Unknown', // Fallback for missing author id
            name: user.first_name || 'Unknown', // Fallback for missing author name
            picture: get_content_url(user.avatar) || '', // Ensure URL is valid
          },
        }
      })
      // console.log('filesList', filesList)
      if (props.task) {
        props.task.files = filesList
      }
    }

    loading.value = false
  } catch (e) {}
}

const addFiles = (type) => {
  isModalNewFile.value = true
  uploadedFiles.value = ''
}

const addFilesClose = (type) => {
  isModalNewFile.value = false
  uploadedFiles.value = ''
}

const downloadFile = async (item) => {
  let path = get_content_url(item)
  window.open(path, '_blank')
}

const deleteFile = async (item) => {
  // console.log('deleteFile', item)

  await deleteItems({
    collection: 'Project_work_files',
    items: {
      query: {
        filter: {
          id: item.row_id,
        },
      },
    },
  })
  await loadFiles()

  let files_del = {
    collection: 'Projects',
    id: project_id.value,
    item: {
      files_cnt: props.project?.files?.length - 1,
    },
  }
  updateItem(files_del)
}

const get_content_url = (file, type = 'avatar') => {
  // if (!file?.type.includes('image') && !is_path) {
  //   return `/img/avatars/placeholder-file.png`
  // }

  // console.log('get_content_url', file)
  if (file?.type) {
    return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
  } else {
    return `/img/avatars/16.svg`
  }
}

const get_file_type = (file) => {
  let type = ''
  if (file?.type.includes('image')) {
    type = '/img/icons/files/ai.svg'
  } else if (file?.type.includes('video')) {
    type = '/img/icons/files/video.svg'
  } else if (file?.type.includes('doc')) {
    type = '/img/icons/files/doc-2.svg'
  } else if (file?.type.includes('pdf')) {
    type = '/img/icons/files/pdf.svg'
  } else if (file?.type.includes('xlsx')) {
    type = '/img/icons/files/sheet.svg'
  } else if (file?.type.includes('pptx')) {
    type = '/img/icons/files/ppt.svg'
  }

  return type
}

const saveUpload = async (items, file_name) => {
  uploadedFiles.value = items

  if (uploadedFiles.value.length) {
    uploadedFiles.value.map(async (uploadedFile) => {
      const file_items = {
        project: project_id.value,
        project_work: task_id.value,
        file: uploadedFile.file.id,
        file_name,
        company_id: myCompanyId,
      }

      const file_res = await createItems({
        collection: 'Project_work_files',
        items: file_items,
      })

      await loadFiles()

      // console.log('file_res-saved', file_res)
    })

    let files_cnt = uploadedFiles.value.length + props.project?.files?.length
    const files_items = {
      collection: 'Projects',
      id: project_id.value,
      item: {
        files_cnt: files_cnt,
      },
    }
    updateItem(files_items)
    //   let updateItemss = {
    //   collection: 'Projects',
    //   id: project_id.value,
    //   item: {
    //     files_cnt: uploadedFiles.value.length,
    //   },
    // }

    // updateItem(updateItemss).then((res) => {
    //   console.log('done', res)
    // })
  }

  // console.log('uploadedFiles-saved', uploadedFiles)
}

const handleUploadRead = async (items, file_name) => {
  // console.log('handleUploadRead-uploadedFiles', items)
  rowData.value = [...rowData.value, ...items]
  rowFiles.value = [...rowData.value, ...items]
  saveUpload(items, file_name)
}

// ------------ edit work sections   --------------------------
const editInfo = (type) => {
  if (type == 'edit') {
    isModalEditWork.value = true
  }
}

const handleModalClose = () => {
  isModalEditWork.value = false
  itemsValue.value = -1
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

// ------------ task sections   --------------------------

const createTask = async (type, template_type = 5) => {
  // console.log('createTask', type, template_type)

  createItems({
    collection: 'Project_work_item',
    items: [
      {
        // status: 1,
        active: '1',
        workorder: props.task?.id,
        parent: null,
        name: 'Default text',
        template_type: template_type,
        company_id: myCompanyId,
      },
    ],
  }).then((addItem) => {
    // let type = typeItem.value
    // if (isProxy(typeItem.value)) {
    //   type = toRaw(typeItem.value)
    // }
    // addItem[0].template_type = type
    // records.value.push(addItem[0])
    // console.log('records', addItem)
    // if (props.refresh) props.refresh()
  })
}

const addTask = async (type) => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
  itemsValue.value = -1

  if (type == 'new') {
    isModalNewTask.value = true
  } else {
    isModalNewTask.value = false
  }
}

const addTaskClose = () => {
  isModalNewTask.value = false
  isModalEditTask.value = false
  itemsValue.value = -1
}

const reloadItems = (id) => {
  // console.log('reloadItem', id)
  itemsValue.value = -1
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)

  if (props.reloadItem) props.reloadItem(id)
  close()
}

const reloadTaskItems = (type) => {
  // console.log('reloadTaskItems', type)
  itemsValue.value = -1
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
  loadTask()
  // if (props.reloadItem) props.reloadItem(id)
  // close()
}

const loadTask = async () => {
  loading.value = true
  try {
    const filters = {
      // status: 1,
      active: '1',
      project_work: task_id.value,
    }

    // console.log('filters.vue id', filters)

    const tsk_items = await getItems<any>({
      collection: 'Project_work_item',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: [
          '*',
          'user_created.*',
          'user_created.avatar.*',
          'user_created.role.*',
        ],
      },
    })

    console.log('tsk_items', tsk_items)

    if (tsk_items.data.length) {
      let checkList = tsk_items.data.map((item) => {
        return {
          id: item.id,
          text: item.name,
          done: parseInt(item.value) == 1 ? true : false,
          author: {
            id: item.user_created.id,
            name: item.user_created.first_name,
            last_name: item.user_created.last_name,
            picture: item.user_created.avatar
              ? `${config.public.directus.url}assets/${item.user_created.avatar?.filename_disk}`
              : null,
          },
        }
      })
      // console.log('filesList', filesList)
      if (props.task) {
        props.task.checklist = checkList
      }
    }

    loading.value = false
  } catch (e) {}
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

onMounted(async () => {
  try {
    const userInfo = JSON.parse(window.localStorage.getItem('userInfo') || '{}')
    if (userInfo?.avatar) {
      userImgId.value = userInfo.avatar
    }

    my_id.value = userInfo?.id
    my_name.value = userInfo?.first_name
    if (props.task) {
      task_id.value = props.task?.id
      project_id.value = props.project?.id

      const statusesItems = statuses.find(
        (p) =>
          p?.__original == props.task?.status || p.value == props.task?.status,
      )

      statusValue.value = {
        id: statusesItems?.id,
        text: t(statusesItems?.text),
        icon: statusesItems?.icon,
      }
    }

    await loadFiles()
    await loadComments()

    // if (props.uploadedFiles?.length) {
    //   rowData.value = props.uploadedFiles
    // } else if (task_id > 0) {
    //   await loadFiles()
    // }
  } catch (error) {
    console.error('Error parsing userInfo:', error)
  }
})

const previewUrl = computed(() => {
  return userImgId.value
    ? `${config.public.directus.url}assets/${userImgId.value}`
    : '/img/avatars/2.svg'
})
const onEditClick = (id) => {
  // console.log('onEditClick', id)
  // console.log('onEditClick', props.task)
  isModalEditTask.value = true
  isModalEditTaskId.value = id
  editTask.value = props.task.checklist.filter((item) => item.id === id)
  // console.log('editTask', editTask)
}

const onDeleteClick = (item) => {
  console.log('onDeleteClick', item)
  isModalApproveConfirmOpen.value = true
  itemsValue.value = item
}
const handleModalConfirmClose = () => {
  isModalApproveConfirmOpen.value = false
  itemsValue.value = -1
}

const do_make = async (item, type) => {
  // console.log('do_make', item)
  isModalApproveConfirmOpen.value = false
  itemsValue.value = -1

  let items = {
    // status: 0,
    active: '0',
  }

  const data = {
    collection: 'Project_work_item',
    id: item.id,
    item: items,
  }

  let deleted = await updateItem(data)
  await loadTask()

  console.log('deleted', deleted)

  // const deleted = await deleteItems({
  //   collection: 'Project_work_item',
  //   items: {
  //     query: {
  //       filter: {
  //         id: item.id,
  //       },
  //     },
  //   },
  // })
}

const do_check = async (item, event: Event) => {
  // console.log('do_check', item)
  // console.log('value', event)
  // console.log('value', !value)
  const value = (event.target as HTMLInputElement)._modelValue
  let items = {
    // status: 1,
    value: !value === false ? 0 : 1,
  }

  const data = {
    collection: 'Project_work_item',
    id: item.id,
    item: items,
  }

  let done = await updateItem(data)
  handleProgress()
  // console.log('done', done)
}

const handleProgress = async () => {
  progressComponent?.value?.loadWorkItems()
}

function onClick(item, type, rowId) {
  // console.log('onClick', item)
  // console.log('rowId', rowId)
  let updateData = {}
  if (type == 'category') {
    updateData = {
      collection: 'Project_works',
      id: item.id,
      item: { category: item.value },
    }
  } else if (type == 'wo_status') {
    updateData = {
      collection: 'Project_works',
      id: rowId,
      item: { status: item.value },
    }
  } else if (type == 'type') {
    updateData = {
      collection: 'Project_works',
      id: item.id,
      item: { type: item.value },
    }
  }

  updateItem(updateData).then((res) => {
    console.log('done')
    // toaster.show({
    //   title: t('Updated'),
    //   message: t('Record updated successfully!'),
    //   color: 'success',
    //   icon: 'ph:user-circle-fill',
    //   closable: true,
    // })

    // if (props.reloadItem) props.reloadItem(project_id.value)
    reloadItems(project_id.value)
    // console.log('updateData', `/projects/board/${project_id.value}`)

    // router.push(`/projects/board/${project_id.value}`)
    // refresh() loadinProject_works details.slug
    // window.location.reload()
  })
}

// ------------ comments sections   --------------------------

const addComment = async (type) => {
  console.log('addComment', commentArea.value)
  createItems({
    collection: 'Project_work_comments',
    items: [
      {
        status: 1,
        project_work: task_id.value,
        text: commentArea.value,
        company_id: myCompanyId,
      },
    ],
  }).then(async (addItem) => {
    commentArea.value = ''
    key.value =
      Math.random().toString(36).substring(2) + Date.now().toString(36)

    console.log('records', addItem)
    await loadComments()

    // if (props.refresh) props.refresh()
  })
}

const editComment = (item) => {
  console.log('onEditClick', item)
  isEditCommentArea.value = true
}

const deleteComment = async (item) => {
  // console.log('deleteComment', item)

  let items = {
    status: '0',
  }

  const data = {
    collection: 'Project_work_comments',
    id: item.id,
    item: items,
  }

  let deleted = await updateItem(data)
  // console.log('deleted', deleted)
  await loadComments()

  // const deleted = await deleteItems({
  //   collection: 'Project_work_item',
  //   items: {
  //     query: {
  //       filter: {
  //         id: item.id,
  //       },
  //     },
  //   },
  // })
}
const loadComments = async () => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      project_work: task_id.value,
    }

    const comment_items = await getItems<any>({
      collection: 'Project_work_comments',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: [
          '*',
          'user_created.*',
          'user_created.avatar.*',
          'user_created.role.*',
        ],
      },
    })
    // console.log('comment_items', comment_items)

    if (comment_items.data.length) {
      let commentist = comment_items.data.map((comment) => {
        return {
          id: comment.id,
          text: comment.text,
          author: {
            id: comment.user_created.id,
            name: comment.user_created.first_name,
            last_name: comment.user_created.last_name,
            posted: formatToLocalDateTime(comment.date_created),
            picture: comment.user_created.avatar
              ? `${config.public.directus.url}assets/${comment.user_created.avatar?.filename_disk}`
              : null,
          },
        }
      })
      // console.log('commentist', commentist)
      if (props.task) {
        props.task.comments = commentist
      }
    }
    loading.value = false
  } catch (e) {}
}

function formatToLocalDateTime(isoString) {
  const date = new Date(isoString)

  const year = date.getFullYear()
  const month = (date.getMonth() + 1).toString().padStart(2, '0') // months are 0-indexed
  const day = date.getDate().toString().padStart(2, '0')

  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')

  return `${year}-${month}-${day} ${hours}:${minutes}`
}

// const myName = computed(() => {
//   return my_name.value ? my_name.value : ''
// })
</script>

<template>
  <div
    class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 border bg-white"
  >
    <div class="taskPanel flex h-16 w-full items-center justify-between px-10">
      <BaseParagraph size="xs" class="text-muted-400">
        {{ t('Contractor') }}
        {{
          props.task?.task_company
            ?.map((tc) => tc.Contractors_id?.name)
            .filter(Boolean) // null эсвэл undefined устгах
            .join(', ')
        }}
      </BaseParagraph>
      <button
        type="button"
        class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300 dark:hover:text-white"
        @click="close"
      >
        <Icon name="feather:chevron-right" class="h-6 w-6" />
      </button>
    </div>

    <div
      class="slimscroll relative h-[calc(100%_-_64px)] w-full overflow-y-auto px-10 py-5"
    >
      <div>
        <div class="mb-4 flex items-center justify-between">
          <div class="flex items-center gap-2">
            <BaseButtonIcon
              shape="full"
              size="sm"
              data-tooltip="Edit task"
              condensed
              @click="editInfo('edit')"
            >
              <Icon name="lucide:edit-3" />
            </BaseButtonIcon>
            <h4
              class="text-muted-400 font-sans text-xs font-semibold uppercase"
            >
              {{ t('Overview') }}
            </h4>
          </div>

          <BaseTag
            shape="full"
            flavor="pastel"
            color="muted"
            class="m-0 -ms-1 inline-flex h-6 scale-90 items-center gap-1 py-0 text-xs font-semibold"
          >
            <span
              class="block h-2 w-2 rounded-full"
              :class="[
                props.task?.status === 0 && 'bg-info-500',
                props.task?.status === 1 && 'bg-primary-500',
                props.task?.status === 2 && 'bg-danger-500',
                props.task?.status === 3 && 'bg-warning-500',
                props.task?.status === 4 && 'bg-yellow-400',
                props.task?.status === 5 && 'bg-success-500',
              ]"
            ></span>
            <span>{{ t('Task') }} #{{ props.task?.id }}</span>
          </BaseTag>
        </div>

        <div class="flex items-center gap-2 mb-[12px]">
          <BaseListbox
            class="status_item mt-[2px]"
            :items="statuses"
            :properties="{
              value: 'id',
              label: 'text',
              icon: 'icon',
            }"
            :model-value="statusValue"
            size="xs"
            rounded="md"
            @update:model-value="onClick($event, 'wo_status', props.task?.id)"
            :disabled="false"
          />
        </div>

        <div class="border-muted-200 dark:border-muted-700 border-b pb-6">
          <BaseHeading as="h3" size="md" weight="medium" class="mb-2">
            {{ props.task?.name }}
          </BaseHeading>
          <BaseParagraph size="xs" class="text-muted-500 dark:text-muted-400">
            {{ props.task?.description }}
          </BaseParagraph>
          <div class="mt-4 flex items-center justify-between">
            <div class="flex shrink-0 items-center gap-2">
              <BaseAvatar
                :src="props.task?.assignee.src"
                size="xs"
                class="shrink-0"
              />
              <div>
                <BaseText size="xs" class="text-muted-400" lead="none">{{
                  t('Assigned to')
                }}</BaseText>
                <BaseHeading as="h4" size="sm" weight="medium">
                  {{ props.task?.assignee.tooltip }}
                </BaseHeading>
              </div>
            </div>
            <div class="max-w-[120px] grow">
              <ProgressComp ref="progressComponent" :wo_id="props.task?.id" />
            </div>
          </div>
        </div>
        <div class="border-muted-200 dark:border-muted-700 border-b py-6">
          <div class="flex justify-between">
            <h4
              class="text-muted-400 font-sans text-xs font-semibold uppercase"
            >
              {{ t('Checklist') }}
            </h4>
            <BaseButtonIcon
              muted
              size="sm"
              class="mt-[-10px]"
              @click="addTask('new')"
            >
              <Icon name="lucide:plus" />
            </BaseButtonIcon>
          </div>

          <div v-if="props.task?.checklist.length === 0">
            <div class="text-muted-400 mt-10 flex items-center justify-center">
              <Icon name="ph:file-thin" class="h-10 w-10" />
            </div>
            <div class="mb-6 mt-2 text-center">
              <BaseHeading as="h4" size="md" weight="light" class="mb-1">
                <span>{{ t('Nothing to show') }}</span>
              </BaseHeading>
              <BaseParagraph
                size="xs"
                lead="tight"
                class="text-muted-500 dark:text-muted-400 mx-auto max-w-[200px] !font-sans"
              >
                <span>{{ t('No checklist to show') }}</span>
              </BaseParagraph>
            </div>
          </div>
          <div v-else class="mt-6 space-y-4">
            <div
              v-for="(item, index) in props.task?.checklist"
              :key="index"
              shape="curved"
            >
              <div class="flex justify-between w-full items-center gap-2">
                <BaseCheckbox
                  v-model="item.done"
                  @click="do_check(item, $event)"
                  class="shrink-0"
                  color="primary"
                  :label="item.text"
                  :classes="{
                    wrapper: '!items-start max-w-[240px]',
                    label:
                      'text-[0.85rem] text-muted-500 dark:text-muted-300 leading-snug',
                  }"
                ></BaseCheckbox>
                <div class="flex buttonCell">
                  <div
                    @click="onEditClick(item.id)"
                    class="hover:text-[#532fcb] cursor-pointer"
                  >
                    <Icon name="tabler:edit" />
                  </div>
                  <div
                    @click="onDeleteClick(item)"
                    class="hover:text-[#532fcb] cursor-pointer"
                  >
                    <Icon name="mdi-light:delete" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="border-muted-200 dark:border-muted-700 border-b py-6">
          <div class="flex justify-between">
            <h4
              class="text-muted-400 font-sans text-xs font-semibold uppercase"
            >
              {{ t('Attached Files') }} ({{ props.task?.files.length }})
            </h4>
            <BaseButtonIcon
              muted
              size="sm"
              class="mt-[-10px]"
              @click="addFiles('new')"
            >
              <Icon name="lucide:plus" />
            </BaseButtonIcon>
          </div>

          <div v-if="props.task?.files.length === 0">
            <div class="text-muted-400 mt-10 flex items-center justify-center">
              <Icon name="ph:file-thin" class="h-10 w-10" />
            </div>
            <div class="mb-6 mt-2 text-center">
              <BaseHeading as="h4" size="md" weight="light" class="mb-1">
                <span>{{ t('Nothing to show') }}</span>
              </BaseHeading>
              <BaseParagraph
                size="xs"
                lead="tight"
                class="text-muted-500 dark:text-muted-400 mx-auto max-w-[200px] !font-sans"
              >
                <span>{{ t('No attached files to show') }}</span>
              </BaseParagraph>
            </div>
          </div>
          <div v-else class="mt-6 space-y-4">
            <div
              v-for="(file, index) in props.task?.files"
              :key="index"
              shape="curved"
            >
              <div class="flex w-full items-center gap-2">
                <img :src="file.icon" :alt="file.name" class="max-w-[40px]" />
                <div>
                  <BaseHeading
                    tag="h3"
                    size="sm"
                    weight="medium"
                    class="max-h-[42px] overflow-hidden"
                  >
                    {{ file.file_name }}
                  </BaseHeading>
                  <BaseParagraph size="xs" class="text-muted-400">
                    <span>{{ file.size }}</span>
                    <span class="px-1 text-base leading-tight"> &middot; </span>
                    <span>v{{ file.version }}</span>
                  </BaseParagraph>
                </div>
                <div class="flex filesCell absolute right-[40px]">
                  <div
                    @click="downloadFile(file)"
                    class="hover:text-[#532fcb] cursor-pointer"
                  >
                    <Icon name="material-symbols:download" />
                  </div>
                  <div
                    @click="deleteFile(file)"
                    class="hover:text-[#532fcb] cursor-pointer"
                  >
                    <Icon name="mdi-light:delete" />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div class="py-6">
          <h4 class="text-muted-400 font-sans text-xs font-semibold uppercase">
            {{ t('Comments') }} ({{ props.task?.comments.length }})
          </h4>
          <div v-if="props.task?.comments.length === 0">
            <div class="text-muted-400 mt-10 flex items-center justify-center">
              <Icon name="ph:chat-circle-thin" class="h-10 w-10" />
            </div>
            <div class="mb-6 mt-2 text-center">
              <BaseHeading as="h4" size="md" weight="light" class="mb-1">
                <span>{{ t('Nothing to show') }}</span>
              </BaseHeading>
              <BaseParagraph
                size="xs"
                lead="tight"
                class="text-muted-500 dark:text-muted-400 mx-auto max-w-[200px] !font-sans"
              >
                <span>{{ t('No comments') }}</span>
              </BaseParagraph>
            </div>
          </div>
          <div v-else class="mt-6 flex flex-col gap-8">
            <div
              v-for="(comment, c) in props.task?.comments"
              :key="c"
              class="flex gap-3"
            >
              <BaseAvatar :src="comment.author.picture" size="xs" />
              <div>
                <BaseHeading as="h3" size="sm" weight="medium">
                  {{ comment.author.name }}
                </BaseHeading>
                <BaseText size="xs" class="text-muted-400 mb-2" lead="none">
                  {{ t('posted') }} {{ comment.author.posted }}
                </BaseText>
                <BaseParagraph
                  size="xs"
                  class="text-muted-500 dark:text-muted-400"
                >
                  {{ comment.text }}
                </BaseParagraph>
                <!-- <BaseTextarea
                  v-if="isEditCommentArea == true"
                  v-model="commentAreaEdit"
                  shape="rounded"
                  placeholder="Write a comment..."
                  :rows="4"
                  addon
                >
                  <template #addon>
                    <div class="flex items-center gap-2">
                      <BaseButtonAction
                        color="primary"
                        :my_id="myId"
                        @click="addComment"
                      >
                        Done
                      </BaseButtonAction>
                    </div>
                  </template>
                </BaseTextarea> -->
              </div>
              <div class="flex commentCell absolute right-10">
                <!-- <div
                  @click="editComment(comment)"
                  class="hover:text-[#532fcb] cursor-pointer"
                >
                  <Icon name="tabler:edit" />
                </div> -->
                <div
                  v-if="comment.author.id == myId"
                  @click="deleteComment(comment)"
                  class="hover:text-[#532fcb] cursor-pointer"
                >
                  <Icon name="mdi-light:delete" />
                </div>
              </div>
            </div>
          </div>
        </div>
        <div>
          <BaseTextarea
            v-model="commentArea"
            shape="rounded"
            :placeholder="t('Write a comment...')"
            :rows="4"
            addon
            class="write_comments"
          >
            <template #addon>
              <div class="flex items-center gap-2">
                <BaseAvatar :src="previewUrl" class="me-1" size="xs" />
                <BaseHeading
                  as="h4"
                  size="sm"
                  weight="semibold"
                  class="text-muted-800 dark:text-white"
                >
                  {{ my_name }}
                </BaseHeading>
              </div>
              <div class="flex items-center gap-2">
                <BaseButtonAction
                  color="primary"
                  :my_id="myId"
                  @click="addComment"
                >
                  {{ t('Publish') }}
                </BaseButtonAction>
              </div>
            </template>
          </BaseTextarea>
        </div>
      </div>
    </div>

    <AddDocuments
      :project_work="task_id"
      :uploadedFiles="uploadedFiles"
      :editFiles="editFiles"
      :title="t('File upload')"
      :key="selectedItem"
      :open="isModalNewFile"
      :fileName="fileName"
      :handleUploadRead="handleUploadRead"
      :close="addFilesClose"
      :row="selectedItem"
      :refresh="loadFiles"
      size="lg"
    />

    <AddTaskModalForm
      :key="key"
      :title="t('Edit Task')"
      code="Project_work_item"
      :open="isModalEditTask"
      :close="addTaskClose"
      :task="editTask"
      :project="props.project"
      :rowId="isModalEditTaskId"
      :refresh="reloadTaskItems"
    />

    <AddTaskModalForm
      :key="key"
      :title="t('Add task')"
      code="Project_work_item"
      :open="isModalNewTask"
      :close="addTaskClose"
      :task="props.task"
      :project="props.project"
      :rowId="-1"
      :refresh="reloadTaskItems"
    />
    <EditWorkModalForm
      :key="key"
      :title="t('Edit Task')"
      code="Project_works"
      :open="isModalEditWork"
      :close="handleModalClose"
      :editTask="props.task"
      :editRow="props.project"
      :refresh="reloadItems"
    />
    <ConfirmModalForm
      code="Task"
      actionType="delete"
      :itemsValue="itemsValue"
      :text="t('Are you sure delete task?')"
      :successfullText="false"
      :open="isModalApproveConfirmOpen"
      :close="handleModalConfirmClose"
      :do_make="do_make"
      :refresh="reloadTaskItems"
    />
  </div>
</template>

<style>
.status_item .nui-listbox .nui-listbox-option {
  padding: 0px !important;
}
</style>
