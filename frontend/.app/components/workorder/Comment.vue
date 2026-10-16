<script setup lang="ts">
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
import ImageViewerModal from '~/components/form/ImageViewerModal.vue'
import { sendNotification } from '~/compsables/sendNotification'

import { defineProps } from 'vue'
import { useI18n } from 'vue-i18n'
import DocumentCommentModal from '~/components/form/DocumentCommentModal.vue'
const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const config = useRuntimeConfig()
const my_teams_users = ref([])

// const { params } = useRoute();

const props = defineProps({
  handleUpload: Function,
  uploadedFiles: Object,
  itemsValue: Object,
  open: Boolean,
  code: String,
  actionType: String,
  text: String,
  successfullText: Boolean,
  row: Number,
  do_make: Function,
  close: Function,
  refresh: Function,
  clear: Function,
})

// comments
const loading = ref(false)
const myId = window.localStorage.getItem('myId')
const userImgId = ref(null)
const task_id = ref(-1)
const project_id = ref(-1)
const my_name = ref('')
const my_id = ref('')
const userImgUrl = ref(null)
const key = ref(1)
const commentArea = ref('')
const wo_users = ref([])

//files
const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selected = ref([])
const selectAll = ref(false)
const rowData = ref([])
const uploadedFiles = ref([])
const files = ref(false)
const isOpenImg = ref(false)

const comments = ref([])
const isRemoveAccepted = ref(false)

const row = computed({
  get: () => {
    return props.row
  },
  set: (value) => {
    console.log(value)
    this.$emit('props.row', value)
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
    if (props.refresh) props.refresh()
    if (props.clear) props.clear()
  }
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
      collection: 'Work_order_comments',
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
    //   collection: 'Work_order_comments',
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

//text comments
const addComment = async (type) => {
  // console.log('addComment', commentArea.value)
  createItems({
    collection: 'Work_order_comments',
    items: [
      {
        status: 1,
        work_order: props.itemsValue.id,
        text: commentArea.value,
        company_id: myCompanyId,
      },
    ],
  }).then(async (addItem) => {
    commentArea.value = ''
    key.value =
      Math.random().toString(36).substring(2) + Date.now().toString(36)

    // console.log('records', addItem)
    await loadComments()
    setCommentCnt('add')
    // console.log('my_teams_users', my_teams_users)

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
          console.error(
            `Failed to send notification to user ${user.id}:`,
            error,
          )
        }
      })

    // if (props.refresh) props.refresh()
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
    collection: 'Work_order_comments',
    id: item.id,
    item: items,
  }

  let deleted = await updateItem(data)
  // console.log('deleted', deleted)
  await loadComments()
  setCommentCnt('delete')

  // const deleted = await deleteItems({
  //   collection: 'Work_order_comments',
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
      work_order: props.itemsValue.id,
    }

    const comment_items = await getItems({
      collection: 'Work_order_comments',
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
    // console.log('comment_items', comment_items)

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
  } catch (e) {}
}

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

    // if (isProxy(my_teams_users.value)) {
    //   my_teams_users.value = toRaw(my_teams_users.value)
    // }
    // console.log('my_teams_users', my_teams_users)

    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
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

const showImg = (file) => {
  // console.log('file ->', file)
  isOpenImg.value = true
  selectedItem.value = file
}

onMounted(async () => {
  await loadComments()

  if (props.itemsValue?.assigned_team) {
    await loadMyTeamsUsers()
  }

  const userInfo = JSON.parse(window.localStorage.getItem('userInfo') || '{}')
  if (userInfo?.avatar) {
    userImgId.value = userInfo.avatar
  }

  my_id.value = userInfo?.id
  my_name.value = userInfo?.first_name

  // console.log('loadComments', props)
  // console.log('companys', companys)
  // console.log('getDemoDetails', data.value)
})
</script>

<template>
  <!-- Body -->
  <div class="relative">
    <BaseCard>
      <div class="p-6">
        <h4 class="text-muted-400 font-sans text-xs font-semibold uppercase">
          {{ $t('Comments') }} ({{ comments.length }})
        </h4>
        <div v-if="comments.length === 0">
          <div class="text-muted-400 mt-10 flex items-center justify-center">
            <Icon name="ph:chat-circle-thin" class="h-10 w-10" />
          </div>
          <div class="mb-6 mt-2 text-center">
            <BaseHeading as="h4" size="md" weight="light" class="mb-1">
              <span>{{ $t('Nothing to show') }}</span>
            </BaseHeading>
            <BaseParagraph
              size="xs"
              lead="tight"
              class="text-muted-500 dark:text-muted-400 mx-auto max-w-[200px] !font-sans"
            >
              <span>{{ $t('No comments') }}</span>
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
                {{ $t('posted') }} {{ comment.author.posted }}
              </BaseText>
              <BaseParagraph
                size="xs"
                class="text-muted-500 dark:text-muted-400"
              >
                {{ comment.text }}
              </BaseParagraph>
            </div>

            <div class="productCell">
              <div
                v-for="(file, c) in comment.file"
                :key="c"
                class="image cursor-pointer ml-2"
                @click="showImg(file)"
              >
                <img :src="get_file_type(file)" alt="part" />
              </div>
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
          :placeholder="$t('Write a comment...')"
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
                <Icon name="mdi-light:image" class="h-8 w-8" />
              </div>
              <BaseButtonAction
                color="primary"
                :my_id="myId"
                @click="addComment"
              >
                {{ $t('Publish') }}
              </BaseButtonAction>
            </div>
          </template>
        </BaseTextarea>
      </div>
    </BaseCard>
  </div>
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
</template>

<style>
.productCell {
  height: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: start;
}

.image {
  max-width: 100%;
  max-height: 100px;
  background-color: rgba(201, 201, 201, 0.2);
  border-radius: 8px;
  /* margin: 8px; */
}

.image img {
  width: 37px;
  height: 37px;
}

.productCell div:first-child {
  font-weight: 500;
}

.productCell div {
  padding-bottom: 0;
  line-height: 1.5;
}

.productCell img {
  border-radius: 8px;
}

.stockCell {
  background-color: var(--color-bg-secondary);
  color: var(--color-text-secondary);
  width: fit-content;
  padding-top: 2px;
  margin-top: 4px;
  padding-right: 4px;
  padding-left: 4px;
  font-size: 12px;
}
</style>
