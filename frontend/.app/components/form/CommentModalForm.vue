<script setup lang="ts">
// import { Icon } from '@iconify/vue'
import { defineProps } from 'vue'
import { useI18n } from 'vue-i18n'
import DocumentCommentModal from '~/components/form/DocumentCommentModal.vue'
import ImageViewerModal from '~/components/form/ImageViewerModal.vue'
import { sendNotification } from '~/compsables/sendNotification'

const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const config = useRuntimeConfig()
const loading = ref(false)

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const my_teams_users = ref([])

// comments
const myId = window.localStorage.getItem('myId')
const userImgId = ref(null)
const task_id = ref(-1)
const project_id = ref(-1)
const my_name = ref('')
const my_id = ref('')
const userImgUrl = ref(null)
const commentArea = ref('')
const key = ref(1)
const comments = ref([])

//files
const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selected = ref([])
const selectAll = ref(false)
const rowData = ref([])
const uploadedFiles = ref([])
const files = ref(false)
const isOpenImg = ref(false)

const isRemoveAccepted = ref(false)

const props = defineProps({
  itemsValue: Object,
  open: Boolean,
  code: String,
  collection: String,
  actionType: String,
  text: String,
  successfullText: Boolean,
  row: Number,
  do_make: Function,
  close: Function,
  refresh: Function,
  clear: Function,
})

const loadMyTeamsUsers = async () => {
  loading.value = true

  try {
    const filters_member = {
      id: { _in: [props.itemsValue?.assigned_team.users] },
    }

    const filters_leader = {
      id: {
        _in: [props.itemsValue?.assigned_team.team_leaders],
      },
    }

    const member_items = await getItems({
      collection: 'Teams_directus_users',
      params: {
        filter: filters_member,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    const leaders_items = await getItems({
      collection: 'Teams_directus_users_1',
      params: {
        filter: filters_leader,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    my_teams_users.value = [
      ...new Set([
        ...(member_items.data?.map((item) => item.directus_users_id) || []),
        ...(leaders_items.data?.map((item) => item.directus_users_id) || []),
      ]),
    ]

    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

const row = computed({
  get: () => {
    return props.row
  },
  set: (value) => {
    console.log(value)
  },
})

const get_content_url = (file) => {
  // console.log('file ->', file)

  if (file && file.type.includes('image')) {
    return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
  } else {
    return ``
  }
}

const do_make = () => {
  if (isRemoveAccepted.value) {
    if (props.successfullText) {
      toaster.show({
        title: t('Success'),
        message: t(`Successfully`),
        color: 'success',
        icon: 'ph:check',
        closable: true,
      })
    }

    isRemoveAccepted.value = false
    props.do_make(props.itemsValue, props.actionType)
    props.close()
    // if (props.refresh) props.refresh()
    // if (props.clear) props.clear()
  }
}

const do_close = () => {
  props.close()
  // isRemoveAccepted.value = false

  // if (props.refresh) props.refresh()
  // if (props.clear) props.clear()
}

const previewUrl = computed(() => {
  return userImgId.value
    ? `${config.public.directus.url}assets/${userImgId.value}`
    : '/img/avatars/2.svg'
})

const setCommentCnt = async (type) => {
  let cnt = 0
  if (type == 'add') {
    cnt = props.itemsValue?.comment_cnt + 1
  } else if (type == 'delete') {
    cnt = props.itemsValue?.comment_cnt - 1
  }

  const updateData = {
    collection: 'Work_order',
    id: props.itemsValue?.id,
    item: { comment_cnt: cnt },
  }
  await updateItem(updateData)
  if (props.refresh) props.refresh()
}

const addComment = async (type) => {
  console.log('addComment', commentArea.value)
  createItems({
    collection: props.collection,
    items: [
      {
        status: '1',
        work_order: props.itemsValue?.id,
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
    setCommentCnt('add')

    // if (props.refresh) props.refresh()
  })

  my_teams_users.value
    .filter((user) => user.id !== myId)
    .map(async (user) => {
      try {
        await sendNotification(
          `New comment on Task #${props.itemsValue?.id}`,
          myId,
          user,
          props.itemsValue?.id,
          'comment',
        )
      } catch (error) {
        console.error(`Failed to send notification to user ${user.id}:`, error)
      }
    })
}

const editComment = (item) => {
  console.log('onEditClick', item)
  // isEditCommentArea.value = true
}

const deleteComment = async (item) => {
  // console.log('deleteComment', item)

  let items = {
    status: '0',
  }

  const data = {
    collection: props.collection,
    id: item.id,
    item: items,
  }

  let deleted = await updateItem(data)
  // console.log('deleted', deleted)
  await loadComments()
  setCommentCnt('delete')

  // const deleted = await deleteItems({
  //   collection: props.collection,
  //   items: {
  //     query: {
  //       filter: {
  //         id: item.id,
  //       },
  //     },
  //   },
  // })
}

//files many-to-mamy

const showImg = (file) => {
  // console.log('file ->', file)
  isOpenImg.value = true
  selectedItem.value = file
}

const get_file_type = (file) => {
  let type = ''
  if (file?.type.includes('image')) {
    type = `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
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
  setCommentCnt('add')

  // console.log(isModalOpen.value)
}

const closeWindow = () => {
  isModalOpen.value = false
  isOpenImg.value = false
}

const handleUploadRead = async (items) => {
  // console.log('handleUploadRead', items)
  uploadedFiles.value = [...rowData.value, ...items]
  rowData.value = [...rowData.value, ...items]
  // console.log('rowData', rowData)

  if (uploadedFiles.value.length) {
    let file_items = {
      work_order: props.itemsValue.id,
      company_id: myCompanyId,
      file: {
        create: [],
      },
    }

    uploadedFiles.value.forEach((row) => {
      return file_items['file']['create'].push({
        Work_order_comments_id: '+',
        directus_files_id: {
          id: row.file.id,
        },
      })
    })

    // console.log('file_items', file_items)

    const file_res = await createItems({
      collection: props.collection,
      items: file_items,
    })

    await loadComments()

    my_teams_users.value
      .filter((user) => user.id !== myId)
      .map(async (user) => {
        try {
          await sendNotification(
            `New file uploaded on Task #${props.itemsValue?.id}`,
            myId,
            user,
            props.itemsValue?.id,
            'comment',
          )
        } catch (error) {
          console.error(
            `Failed to send notification1 to user ${user.id}:`,
            error,
          )
        }
      })

    // console.log('file_res', file_res)
    // uploadedFiles.value.map(async (uploadedFile) => {
    //   file_items.file.push(uploadedFile.file.id)

    // const file_items = {
    //   work_order: uploadedFile.item_id,
    //   file: uploadedFile.file.id,
    // }
    // console.log('file_items', file_items)

    // const file_res = await createItems({
    //   collection: props.collection,
    //   items: file_items,
    // })

    // const items = await getItems<any>({
    //   collection: 'Transaction_files',
    //   params: {
    //     filter: file_items,
    //     limit: -1,
    //     page: 1,
    //     meta: 'filter_count',
    //     fields: ['*', 'file.*'],
    //   },
    // })

    // if (items.data.length == 0) {
    //   const file_res = await createItems({
    //     collection: 'Transaction_files',
    //     items: file_items,
    //   })
    // }
    // })
  }
}

const loadComments = async () => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: props.itemsValue?.id,
    }

    const comment_items = await getItems({
      collection: props.collection,
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: [
          '*',
          'file.*',
          'file.directus_files_id.*',
          'user_created.*',
          'user_created.avatar.*',
          'user_created.role.*',
        ],
      },
    })

    if (comment_items.data.length) {
      let commentist = comment_items.data.map((comment) => {
        let files = comment.file?.map((item) => item.directus_files_id)

        return {
          id: comment.id,
          text: comment.text,
          file: files,
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
      comments.value = commentist
    }

    loading.value = false
  } catch (e) {
    console.log('err', e)
  }
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

const initModal = () => {
  const userInfo = JSON.parse(window.localStorage.getItem('userInfo') || '{}')
  if (userInfo?.avatar) {
    userImgId.value = userInfo.avatar
  }

  my_id.value = userInfo?.id
  my_name.value = userInfo?.first_name
}

// watch(
//   () => props.open,
//   async (val) => {
//     console.log('watch', props)

//     if (val) {
//       initModal()
//       await loadComments()
//     }
//   },
// )

onMounted(async () => {
  // console.log('onMounted_comm', props)
  initModal()
  await loadComments()

  if (props.itemsValue?.assigned_team) {
    await loadMyTeamsUsers()
  }
})
</script>

<template>
  <TairoModal :open="props.open" size="xl" @close="do_close()">
    <template #header>
      <!-- Header -->
      <div class="flex w-full items-center justify-between p-4">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
        >
          &nbsp;
        </h3>

        <BaseButtonClose @click="do_close()" />
      </div>
    </template>

    <!-- Body -->
    <div class="px-5 md:p-6 overflow-scroll max-h-[546px]">
      <BaseCard class="p-8">
        <div class="pb-6">
          <h4 class="text-muted-400 font-sans text-xs font-semibold uppercase">
            {{ t('Comments') }} ({{ comments.length }})
          </h4>
          <div v-if="comments.length === 0">
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
            <div v-for="(comment, c) in comments" :key="c" class="flex gap-3">
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
              </div>

              <div class="w-10 h-10 productCell">
                <div
                  v-for="(file, c) in comment.file"
                  :key="c"
                  class="image cursor-pointer ml-2 rounded-lg"
                  @click="showImg(file)"
                >
                  <img
                    :src="get_file_type(file)"
                    alt="part"
                    class="rounded-lg"
                  />
                </div>
              </div>
              <div class="flex commentCell absolute right-10">
                <!-- <div
                  @click="editComment(comment)"
                  class="hover:text-[#532fcb] cursor-pointer"
                >
                  <Icon name="tabler:edit" />
                    <svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24"><g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5"><path d="M19.09 14.441v4.44a2.37 2.37 0 0 1-2.369 2.369H5.12a2.37 2.37 0 0 1-2.369-2.383V7.279a2.356 2.356 0 0 1 2.37-2.37H9.56"/><path d="M6.835 15.803v-2.165c.002-.357.144-.7.395-.953l9.532-9.532a1.36 1.36 0 0 1 1.934 0l2.151 2.151a1.36 1.36 0 0 1 0 1.934l-9.532 9.532a1.36 1.36 0 0 1-.953.395H8.197a1.36 1.36 0 0 1-1.362-1.362M19.09 8.995l-4.085-4.086"/></g></svg>
                </div> -->
                <div
                  v-if="comment.author.id == myId"
                  @click="deleteComment(comment)"
                  class="hover:text-[#532fcb] cursor-pointer"
                >
                  <!-- <Icon name="mdi-light:delete" /> -->
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="1em"
                    height="1em"
                    viewBox="0 0 24 24"
                  >
                    <path
                      fill="currentColor"
                      d="M18 19a3 3 0 0 1-3 3H8a3 3 0 0 1-3-3V7H4V4h4.5l1-1h4l1 1H19v3h-1zM6 7v12a2 2 0 0 0 2 2h7a2 2 0 0 0 2-2V7zm12-1V5h-4l-1-1h-3L9 5H5v1zM8 9h1v10H8zm6 0h1v10h-1z"
                    />
                  </svg>
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
                <div class="add_file cursor-pointer" @click="addFiles">
                  <!-- <Icon name="mdi-light:image" class="h-8 w-8" /> -->
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="30px"
                    height="30px"
                    viewBox="0 0 24 24"
                  >
                    <path
                      fill="currentColor"
                      d="M5 3h13a3 3 0 0 1 3 3v13a3 3 0 0 1-3 3H5a3 3 0 0 1-3-3V6a3 3 0 0 1 3-3m0 1a2 2 0 0 0-2 2v11.59l4.29-4.3l2.5 2.5l5-5L20 16V6a2 2 0 0 0-2-2zm4.79 13.21l-2.5-2.5L3 19a2 2 0 0 0 2 2h13a2 2 0 0 0 2-2v-1.59l-5.21-5.2zM7.5 6A2.5 2.5 0 0 1 10 8.5A2.5 2.5 0 0 1 7.5 11A2.5 2.5 0 0 1 5 8.5A2.5 2.5 0 0 1 7.5 6m0 1A1.5 1.5 0 0 0 6 8.5A1.5 1.5 0 0 0 7.5 10A1.5 1.5 0 0 0 9 8.5A1.5 1.5 0 0 0 7.5 7"
                    />
                  </svg>
                </div>
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
      </BaseCard>
      <DocumentCommentModal
        size="lg"
        :key="key"
        :title="$t('File upload')"
        :open="isModalOpen"
        :close="closeFiles"
        :files="files"
        :handleUploadRead="handleUploadRead"
        :row="selectedItem"
        :refresh="loadComments"
        :item_id="props.itemsValue?.id"
      />
      <ImageViewerModal
        :itemsValue="selectedItem"
        :open="isOpenImg"
        :close="closeWindow"
      />
    </div>
  </TairoModal>
</template>
