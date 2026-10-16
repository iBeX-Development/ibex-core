<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

import { useForm } from 'vee-validate'

const config = useRuntimeConfig()
const { deleteUsers } = useDirectusUsers()
const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const { token } = useDirectusToken()
const myCompanyId = getMyCompanyId()

const type = ref('')
const project_name = ref('')
const customer = ref('')
const project_leaders = ref([])
const project_members = ref([])
const description = ref('')
const project_status = ref('draft')
let project_options = ref(['published', 'draft', 'archived'])

let imgId = ref(-1)
let UploadImg = []
let thumbnailUrl = ref('')

const isModalLeaderOpen = ref(false)
const isModalMemberOpen = ref(false)
const isModalConfirmText = ref('')
const isModalConfirmOpen = ref(false)
const isError = ref(false)

const props = defineProps({
  open: Boolean,
  code: String,
  close: Function,
  refresh: Function,
  clear: Function,
  editRow: Object,
  row: Object,
})
const success = ref(false)
const rows = ref([
  {
    meeting: {
      title: '',
      type: '',
      position: '',
      colorCode: '',
    },
  },
])

// Scroll контейнерийг тодорхойлох ref
const rowsContainer = ref(null)

// Modify initial values to handle dynamic rows
const initialValues = computed(() => ({
  module: props.editRow
    ? [
        {
          id: 1,
          name: 'Work order',
          text: 'Your location work order',
          icon: 'ph:buildings-duotone',
          module_key: 'work_order',
        },
      ]
    : '',
  rows: rows.value.map((row) => ({
    meeting: {
      title: row.meeting.title,
      position: row.meeting.position,
      type: row.meeting.type,
      colorCode: row.meeting.colorCode,
    },
  })),
}))

const {
  handleSubmit,
  isSubmitting,
  setFieldError,
  meta,
  values,
  errors,
  resetForm,
  setFieldValue,
  setErrors,
} = useForm({
  initialValues,
})

const emits = defineEmits<{
  (event: 'reset'): void
}>()

const onSubmit = handleSubmit(
  async (values) => {
    success.value = false
    let error = false
    let errorMsg = ''
    // console.log('Submit хийх боломжтой!', values)
    // console.log('project_leaders!', project_leaders)

    let items = {
      name: project_name.value,
      description: description.value,
      project_leaders: {
        create: [],
      },
      users: {
        create: [],
      },
      _image: UploadImg.length //ids
        ? UploadImg[0].id
        : imgId.value != -1
        ? imgId.value
        : null,
      company_id: myCompanyId,
    }

    // items['users']['create'] = [
    //   {
    //     Projects_id: '+',
    //     directus_users_id: { id: '213313c8-2565-4683-98fa-7533ae926b8e' },
    //   },
    //   {
    //     Projects_id: '+',
    //     directus_users_id: { id: '54c9be79-8132-421c-b194-754657068bb2' },
    //   },
    // ]

    if (props.editRow != -1) {
      project_members.value.forEach((user) => {
        items['users']['create'].push({
          Projects_id: props.editRow.id,
          directus_users_id: {
            id: user.id,
          },
        })
      })

      project_leaders.value.forEach((user) => {
        items['project_leaders']['create'].push({
          Projects_id: props.editRow.id,
          directus_users_id: {
            id: user.id,
          },
        })
      })

      // console.log('edit_items', items)

      const delRes = await deleteItems({
        collection: 'Projects_directus_users', //projectmembers
        items: {
          query: {
            filter: {
              Projects_id: props.editRow.id,
            },
          },
        },
      })

      const delLeaderRes = await deleteItems({
        collection: 'Projects_directus_users_1', //projectLeader
        items: {
          query: {
            filter: {
              Projects_id: props.editRow.id,
            },
          },
        },
      })

      // console.log('delLeaderRes', delLeaderRes)
      // console.log('delRes', delRes)

      const res = await updateItem({
        collection: 'Projects',
        id: props.editRow.id,
        item: items,
      })
      // console.log('delRes', delRes)
    } else {
      project_members.value.forEach((user) => {
        return items['users']['create'].push({
          Projects_id: '+',
          directus_users_id: {
            id: user.id,
          },
        })
      })

      project_leaders.value.forEach((user) => {
        return items['project_leaders']['create'].push({
          Projects_id: '+',
          directus_users_id: {
            id: user.id,
          },
        })
      })

      // console.log('create', items)

      const res = await createItems({
        collection: 'Projects',
        items: items,
      })
    }

    resetModal()
    toaster.clearAll()
    toaster.show({
      title: 'Success',
      message: `Record has been created`,
      color: 'success',
      icon: 'ph:check',
      closable: true,
    })
  },
  (error) => {
    // this callback is optional and called only if the form has errors
    success.value = false

    // here you have access to the error
    console.log('error2', error)

    // you can use it to scroll to the first error
    document.documentElement.scrollTo({
      top: 0,
      behavior: 'smooth',
    })
  },
)

const resetModal = () => {
  // Reset rows to initial state
  project_name.value = ''
  description.value = ''

  project_leaders.value = []
  project_members.value = []
  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  imgId.value = -1
  UploadImg.value = []

  // Reset form
  resetForm()
  success.value = false
  setErrors({})

  // Reset scroll position if needed
  if (rowsContainer.value) {
    rowsContainer.value.scrollTop = 0
  }

  // Close modal
  props.close()
  props.refresh()
}

// 🔹 `computed()` ашиглаж, шууд тооцоолох
const Thumbnail = computed(() => {
  return imgId.value != -1
    ? `${config.public.directus.url}assets/${imgId.value}`
    : '/img/avatars/placeholder-file.png'
})

const handleUploaded = (newValue) => {
  console.log('done:)', newValue)
}

const chooseItem = (item) => {
  console.log('chooseItemыыы', item)

  isModalLeaderOpen.value = false
  project_leaders.value = [item]
}

const saveLeaders = (items) => {
  // console.log('saveLeaders', items)
  isModalLeaderOpen.value = false
  project_leaders.value = items
}

const saveUser = (items) => {
  // console.log('saveUser', items)
  isModalMemberOpen.value = false
  project_members.value = items
}

const handleModalLeaderOpen = (type) => {
  isModalLeaderOpen.value = true
}

const handleModalMemberOpen = (type) => {
  isModalMemberOpen.value = true
}

const onDelete = (item, index, type) => {
  // console.log('onDelete', item)
  if (type == 'members') {
    project_members.value.splice(index, 1)
  }
  if (type == 'leaders') {
    project_leaders.value.splice(index, 1)
  }

  // project_members.value = project_members.value.filter(
  //   (member) => member.id !== item.id
  // )
}

onMounted(async () => {
  // console.log('props-edited', props)

  if (props.editRow) {
    project_name.value = props.editRow.name
    description.value = props.editRow.description
    project_members.value = props.editRow.users?.map((item) => ({
      first_name: item.directus_users_id.first_name,
      id: item.directus_users_id.id,
    }))

    project_leaders.value = props.editRow.project_leaders?.map((item) => ({
      first_name: item.directus_users_id.first_name,
      id: item.directus_users_id.id,
    }))

    imgId.value = props.editRow._image
  }

  // console.log('project_leaders', project_leaders)
  // console.log('project_members', project_members)
})

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  isError.value = false
}

const handleModalLeaderClose = () => {
  isModalLeaderOpen.value = false
}

const handleModalMemberClose = () => {
  isModalMemberOpen.value = false
}
</script>

<template>
  <form
    action=""
    method="POST"
    @submit.prevent="onSubmit"
    class="mx-auto w-full max-w-3xl"
  >
    <TairoModal :open="props.open" size="2xl" @close="resetModal">
      <template #header>
        <!-- Header -->
        <div class="flex w-full items-center justify-between">
          <h3
            class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
          >
            &nbsp;
          </h3>

          <BaseButtonClose @click="resetModal" />
        </div>
      </template>

      <BaseTabs
        justify="end"
        type="box"
        model-value="info"
        class="tabs"
        :tabs="[
          { label: $t('Info'), value: 'info' },
          { label: $t('Documents'), value: 'documents' },
        ]"
      >
        <template #tab="{ activeValue }">
          <div
            ref="rowsContainer"
            v-if="activeValue === 'info'"
            class="rowsContainer overflow-auto h-[380px] font-sans text-sm text-gray-500 dark:text-gray-400"
          >
            <div
              class="rowsContainer body w-[580px] h-[440px] grid mx-auto overflow-y-auto overflow-x-hidden"
              ref="rowsContainer"
            >
              <div class="project_about flex justify-around">
                <div class="w-[354px]">
                  <BaseInput
                    v-model="project_name"
                    label="Name"
                    rounded="none"
                    style="
                      width: 320px;
                      border: 1px solid #cbd5e1;
                      border-radius: 7px;
                    "
                    type="string"
                  />
                  <BaseInput
                    v-model="customer"
                    label="Customer"
                    rounded="none"
                    style="
                      width: 320px;
                      border: 1px solid #cbd5e1;
                      border-radius: 7px;
                    "
                    type="string"
                  />
                  <div class="w-[320px]">
                    <BaseListbox
                      label="Status"
                      style="
                        width: 320px;
                        border: 1px solid #cbd5e1;
                        border-radius: 7px;
                      "
                      v-model="project_status"
                      :items="project_options"
                      rounded="none"
                    />
                  </div>

                  <div class="w-[320px] flex project_leaders items-center mt-4">
                    <div
                      title="Project leader"
                      class="snackBox placeholder-leader flex flex-wrap items-end gap-2"
                    >
                      <BaseSnack
                        v-for="(item, index) in project_leaders"
                        :key="index"
                        :label="item.first_name"
                        :id="item.id"
                        color="muted"
                        size="xs"
                        @delete="onDelete(item, index, 'leaders')"
                      />
                    </div>

                    <BaseButton
                      style="width: 36px"
                      color="default"
                      :class="'ml-1'"
                      @click="handleModalLeaderOpen('user')"
                    >
                      ...
                    </BaseButton>
                  </div>
                  <div class="w-[320px] flex project_members items-center mt-4">
                    <div
                      title="Project members"
                      class="snackBox placeholder-members flex flex-wrap items-end gap-2"
                    >
                      <!-- <div class="container flex items-end gap-4"> -->
                      <BaseSnack
                        v-for="(item, index) in project_members"
                        :key="index"
                        :label="item.first_name"
                        :id="item.id"
                        color="muted"
                        size="xs"
                        @delete="onDelete(item, index, 'members')"
                      />
                      <!-- </div> -->
                    </div>

                    <BaseButton
                      style="width: 36px"
                      color="default"
                      :class="'ml-1'"
                      @click="handleModalMemberOpen('user')"
                    >
                      ...
                    </BaseButton>
                  </div>
                </div>

                <div
                  class="LoginImg w-[210px] h-[266px] flex items-center justify-center"
                >
                  <AvatarUpload
                    code="users"
                    field="login"
                    height="210px"
                    width="194px"
                    :result="UploadImg"
                    :id="imgId"
                    xmargin="-208px 0px 0px -20px"
                    :fileUrl="Thumbnail"
                  />
                </div>
              </div>
              <div class="project_description w-[560px] flex mb-5 ml-1">
                <BaseTextarea
                  v-model="description"
                  contrast="default-contrast"
                  size="sm"
                  label="Description"
                  rounded="md"
                  placeholder="Write a description..."
                  color-focus
                />
              </div>
            </div>
          </div>
          <div
            v-else-if="activeValue === 'documents'"
            class="h-[380px] w-[94%] overflow-auto font-sans text-sm text-gray-500 dark:text-gray-400"
          >
            <!-- <Documents
              :transaction_id="props.row"
              :handleUpload="handleUpload"
              :uploadedFiles="uploadedFiles"
              :editFiles="editFiles"
            /> -->
          </div>
        </template>
      </BaseTabs>
    </TairoModal>
  </form>
</template>

<style>
.rowsContainer .templates,
.rowsContainer .options {
  margin-top: 10px;
}

.rowsContainer .templates .nui-radio {
  margin-bottom: 8px;
}
.rowsContainer .options {
  /* border-left: 1px solid gray; */
}
.rowsContainer .options .InputBox {
  width: 80%;
  margin: auto;
}

.rowsContainer .snackBox {
  width: 360px;
  border: 1px solid #cdd5e0;
  height: auto;
  min-height: 38px;
  max-height: 120px;
  overflow-y: auto;
  overflow-x: hidden;
  border-radius: 0.375rem;
  align-items: center;
  padding: 10px;
}
.rowsContainer .placeholder-leader {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}

.rowsContainer .placeholder-leader:empty::before {
  content: 'Project leader';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}

.rowsContainer .placeholder-members {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}
.rowsContainer .placeholder-members:empty::before {
  content: 'Project members';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}
.rowsContainer .snackBox .nui-snack {
  border: 1px solid #c1bebe;
}

.rowsContainer .snackBox .nui-button-close {
  height: 24px !important;
}

.project_description .nui-textarea-wrapper {
  width: 100%;
}
</style>
