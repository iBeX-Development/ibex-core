<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

import { useForm } from 'vee-validate'
import WarningModalForm from '~/components/form/WarningModalForm.vue'

const config = useRuntimeConfig()
const { deleteUsers } = useDirectusUsers()
const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const { token } = useDirectusToken()

const type = ref('')
const key = ref(1)
const project_name = ref('')
const project_code = ref('')
const customer = ref('')
const project_leaders = ref([])
const project_members = ref([])
const project_team = ref([])
const description = ref('')
const project_status = ref('published')
let project_options = ref(['published', 'draft', 'archived'])
const project_type = ref('Members')
let project_types = ref(['Members', 'Teams'])

const category_status = ref('Mining')
let category_options = ref(['Mining', 'Software', 'Foods', 'Education'])

let imgId = ref(-1)
const UploadImg = ref([])
let thumbnailUrl = ref('')

const isModalLeaderOpen = ref(false)
const isModalMemberOpen = ref(false)
const isModalTeamOpen = ref(false)
const isModalConfirmText = ref('')
const isModalConfirmOpen = ref(false)
const isError = ref(false)

const props = defineProps({
  open: Boolean,
  code: String,
  title: String,
  icon: String,
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
const projectContainer = ref(null)

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
    console.log('Submit хийх боломжтой!', values)
    // console.log('project_leaders!', project_leaders)

    let items = {
      name: project_name.value,
      code: project_code.value,
      description: description.value,
      // category: category_status.value,
      project_leaders: {
        create: [],
      },
      users: {
        create: [],
      },
      team: {
        create: [],
      },
      _image: UploadImg.value.length //ids
        ? UploadImg.value[0].id
        : imgId.value != -1
        ? imgId.value
        : null,
      company_id: myCompanyId,
    }

    if (!project_code.value || project_code.value == '') {
      error = true
      isModalConfirmText.value = 'Register is empty!'
    }
    if (!project_name.value || project_name.value == '') {
      error = true
      isModalConfirmText.value = 'Name is empty!'
    }

    if (error == true) {
      isModalConfirmOpen.value = true
      return
    }

    // // items['users']['create'] = [
    // //   {
    // //     Projects_id: '+',
    // //     directus_users_id: { id: '213313c8-2565-4683-98fa-7533ae926b8e' },
    // //   },
    // //   {
    // //     Projects_id: '+',
    // //     directus_users_id: { id: '54c9be79-8132-421c-b194-754657068bb2' },
    // //   },
    // // ]

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

      project_team.value.forEach((team) => {
        items['team']['create'].push({
          Projects_id: props.editRow.id,
          Teams_id: {
            id: team.id,
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

      const delTeamsRes = await deleteItems({
        collection: 'Projects_Teams_1', //mainProject-teams
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

      // props.refresh()

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

      project_team.value.forEach((team) => {
        return items['team']['create'].push({
          Projects_id: '+',
          Teams_id: {
            id: team.id,
          },
        })
      })

      console.log('create', items)

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
  project_code.value = ''
  description.value = ''
  category_status.value = ''

  project_leaders.value = []
  project_members.value = []
  project_team.value = []
  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  imgId.value = -1
  UploadImg.value = []

  // Reset form
  resetForm()
  success.value = false
  setErrors({})

  // Reset scroll position if needed
  if (projectContainer.value) {
    projectContainer.value.scrollTop = 0
  }

  // Close modal
  props.close()
  props.refresh()
}

// 🔹 `computed()` ашиглаж, шууд тооцоолох
const Thumbnail = computed(() => {
  if (UploadImg.value.length) {
    return `${config.public.directus.url}assets/${UploadImg.value[0].id}`
  }
  return imgId.value != null && imgId.value != -1
    ? `${config.public.directus.url}assets/${imgId.value}`
    : '/img/avatars/placeholder-file.png'
})

const get_content_url = (file, type) => {
  // console.log('file ->', file)

  if (type == 'avatar') {
    if (file && file.type.includes('image')) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else {
      return `/img/avatars/3.svg`
    }
  }

  if (type == 'project') {
    if (file && file.type.includes('image')) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else {
      return `/img/projects/15.jpg`
    }
  }

  if (type == 'leader') {
    if (file && file.type.includes('image')) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else {
      return `/img/avatars/1.svg`
    }
  }
}
const handleUploaded = (newValue) => {
  console.log('done:)', newValue)
}

const chooseItem = (item) => {
  // console.log('chooseItemыыы', item)

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

const saveTeam = (items) => {
  console.log('saveTeam', items)
  isModalTeamOpen.value = false
  project_team.value = items
}

const onDelete = (item, index, type) => {
  // console.log('onDelete', item)
  if (type == 'members') {
    project_members.value.splice(index, 1)
  }
  if (type == 'leaders') {
    project_leaders.value.splice(index, 1)
  }
  if (type == 'teams') {
    project_team.value.splice(index, 1)
  }

  // project_members.value = project_members.value.filter(
  //   (member) => member.id !== item.id
  // )
}

onMounted(async () => {
  // console.log('props-edited', props)

  if (props.editRow) {
    project_name.value = props.editRow.name
    project_code.value = props.editRow.code
    description.value = props.editRow.description
    project_members.value =
      props.editRow.users?.map((item) => ({
        first_name: item.directus_users_id.first_name,
        id: item.directus_users_id.id,
      })) ?? []

    project_team.value =
      props.editRow.team?.map((item) => ({
        name: item.Teams_id.name,
        id: item.Teams_id.id,
      })) ?? []

    project_leaders.value =
      props.editRow.project_leaders?.map((item) => ({
        first_name: item.directus_users_id.first_name,
        id: item.directus_users_id.id,
      })) ?? []

    const imageField = props.editRow._image
    imgId.value =
      imageField == null
        ? -1
        : typeof imageField === 'object'
        ? imageField.id ?? -1
        : imageField
  }

  // console.log('project_leaders', project_leaders)
  // console.log('project_members', project_members)
})

const handleModalLeaderOpen = (type) => {
  isModalLeaderOpen.value = true
}

const handleModalMemberOpen = (type) => {
  isModalMemberOpen.value = true
}

const handleModalTeamOpen = (type) => {
  isModalTeamOpen.value = true
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalTeamOpen.value = false
  isModalMemberOpen.value = false
  isModalLeaderOpen.value = false
  isModalConfirmText.value = ''
  isError.value = false
}

const handleModalLeaderClose = () => {
  isModalLeaderOpen.value = false
}

const handleModalMemberClose = () => {
  isModalMemberOpen.value = false
}
const handleModalTeamClose = () => {
  isModalTeamOpen.value = false
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
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
            {{ $t(props.title) }}
          </h3>

          <BaseButtonClose @click="resetModal" />
        </div>
      </template>

      <!-- Body -->
      <div
        class="projectContainer body h-[500px] grid mx-auto overflow-y-auto overflow-x-hidden"
        ref="projectContainer"
      >
        <div class="projectsBody w-full max-w-[600px] mx-auto px-2 py-1">
          <div class="project_about grid grid-cols-[1fr_auto] gap-8">
            <div class="flex flex-col gap-2 max-w-[340px]">
              <BaseInput
                v-model="project_name"
                :label="$t('Name')"
                rounded="md"
                type="string"
                class="border rounded-md"
              />
              <div class="flex gap-4">
                <BaseInput
                  v-model="project_code"
                  :label="$t('Code')"
                  rounded="md"
                  type="string"
                  class="flex-1 border rounded-md"
                />
                <BaseListbox
                  :label="$t('Status')"
                  v-model="project_status"
                  :items="project_options"
                  rounded="md"
                  class="flex-1"
                />
              </div>

              <div class="project_leaders">
                <label class="field_label">{{ $t('Project leader') }}</label>
                <div class="flex items-center gap-2">
                  <div
                    class="snackLeaderBox snackBox placeholder-leader flex flex-wrap items-center gap-2"
                  >
                    <BaseSnack
                      v-for="(item, index) in project_leaders"
                      :key="index"
                      :label="item.first_name"
                      :id="item.id"
                      icon="ph:user-circle-duotone"
                      color="muted"
                      size="sm"
                      @delete="onDelete(item, index, 'leaders')"
                    />
                  </div>

                  <BaseButton
                    shape="curved"
                    color="default"
                    class="add_bttn"
                    :title="$t('Add')"
                    @click="handleModalLeaderOpen('user')"
                  >
                    <Icon name="mynaui:plus" class="h-4 w-4" />
                  </BaseButton>
                </div>
              </div>
            </div>

            <div
              class="UploadImg w-[194px] h-[220px] flex items-center justify-center"
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

          <div class="project_members">
            <label class="field_label">{{ $t('Project members') }}</label>
            <div class="flex items-center gap-2">
              <div
                class="snackMemberBox snackBox placeholder-members flex flex-wrap items-center gap-2"
              >
                <BaseSnack
                  v-for="(item, index) in project_members"
                  :key="index"
                  :label="item.first_name"
                  :id="item.id"
                  icon="ph:user-circle-duotone"
                  color="muted"
                  size="sm"
                  @delete="onDelete(item, index, 'members')"
                />
              </div>

              <BaseButton
                shape="curved"
                color="default"
                class="add_bttn"
                :title="$t('Add')"
                @click="handleModalMemberOpen('user')"
              >
                <Icon name="mynaui:plus" class="h-4 w-4" />
              </BaseButton>
            </div>
          </div>

          <div class="project_teams mt-2">
            <label class="field_label">{{ $t('Project Teams') }}</label>
            <div class="flex items-center gap-2">
              <div
                class="snackTeamBox snackBox placeholder-teams flex flex-wrap items-center gap-2"
              >
                <BaseSnack
                  v-for="(item, index) in project_team"
                  :key="index"
                  :label="item.name"
                  :id="item.id"
                  icon="ph:users-three-duotone"
                  color="muted"
                  size="sm"
                  @delete="onDelete(item, index, 'teams')"
                />
              </div>

              <BaseButton
                shape="curved"
                color="default"
                class="add_bttn"
                :title="$t('Add')"
                @click="handleModalTeamOpen('user')"
              >
                <Icon name="mynaui:plus" class="h-4 w-4" />
              </BaseButton>
            </div>
          </div>

          <div class="project_description mt-2">
            <BaseTextarea
              v-model="description"
              contrast="default-contrast"
              size="sm"
              :label="$t('Description')"
              rounded="md"
              :placeholder="$t('Write a description...')"
              color-focus
              class="border"
            />
          </div>
        </div>
      </div>

      <!-- Modal Footer -->
      <div
        class="shadow-muted-300/30 dark:shadow-muted-800/30 flex items-center justify-end gap-2 m-[25px]"
      >
        <BaseButton type="reset" shape="rounded" @click="resetModal">
          <span>{{ $t('Close') }}</span>
        </BaseButton>
        <BaseButton
          type="submit"
          shape="rounded"
          color="primary"
          @click="
            () => {
              onSubmit()
            }
          "
        >
          <span>{{ $t('Save') }}</span>
        </BaseButton>
      </div>
      <UserCheckList
        collection="Users"
        :open="isModalLeaderOpen"
        :close="handleModalLeaderClose"
        :chosedItems="project_leaders"
        :saveUser="saveLeaders"
        :chooseBttn="false"
        :saveBttn="true"
      />
      <UserCheckList
        collection="Users"
        :open="isModalMemberOpen"
        :close="handleModalMemberClose"
        :chosedItems="project_members"
        :saveUser="saveUser"
        :chooseBttn="false"
        :saveBttn="true"
      />
      <UserCheckList
        collection="Teams"
        :open="isModalTeamOpen"
        :close="handleModalTeamClose"
        :chosedItems="project_team"
        :saveUser="saveTeam"
        :chooseBttn="false"
        :saveBttn="true"
      />
      <WarningModalForm
        :text="$t(isModalConfirmText)"
        code="Status"
        :open="isModalConfirmOpen"
        :close="handleModalConfirmClose"
      />
    </TairoModal>
  </form>
</template>

<style>
.projectContainer .field_label {
  display: block;
  margin-bottom: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
}
.dark .projectContainer .field_label {
  color: #94a3b8;
}

.projectContainer .snackBox {
  width: 100%;
  min-height: 42px;
  border: 1px solid #cdd5e0;
  border-radius: 0.5rem;
  padding: 6px 10px;
  align-items: center;
  overflow-y: auto;
  overflow-x: hidden;
}
.dark .projectContainer .snackBox {
  border-color: #3b3f54;
}

.projectContainer .placeholder-leader,
.projectContainer .placeholder-members,
.projectContainer .placeholder-teams {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}
.projectContainer .placeholder-leader:empty::before {
  content: 'Project leader';
  color: #97a3b6;
}
.projectContainer .placeholder-members:empty::before {
  content: 'Project members';
  color: #97a3b6;
}
.projectContainer .placeholder-teams:empty::before {
  content: 'Project Teams';
  color: #97a3b6;
}

.projectContainer .snackBox .nui-snack {
  border: 1px solid #c1bebe;
}
.projectContainer .snackBox .nui-button-close {
  height: 24px !important;
}

.projectContainer .add_bttn {
  flex-shrink: 0;
  width: 38px;
  height: 38px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
}

.project_description .nui-textarea-wrapper {
  width: 100%;
}
</style>
