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
const team_name = ref('')
const team_leaders = ref([])
const team_leaderName = ref(null)
const team_members = ref([])
const team_membersName = ref([])
const description = ref('')
const team_status = ref('Enable')

let imgId = ref('')
let UploadImg = []
let thumbnailUrl = ref('')
let team_options = ref(['Enable', 'Disable'])

const isModalLeaderOpen = ref(false)
const isModalMemberOpen = ref(false)
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
const rowsContainer = ref(null)

console.log('props.==> ', props)

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
    // console.log('team_leaders!', team_leaders)

    let items = {
      company_id: myCompanyId,
      name: team_name.value,
      description: description.value,
      team_leaders: {
        create: [],
      },
      users: {
        create: [],
      },
      _image: UploadImg.length //ids
        ? UploadImg[0].id
        : imgId.value
        ? imgId.value
        : null,
    }

    // items['users']['create'] = [
    //   {
    //     Teams_id: '+',
    //     directus_users_id: { id: '213313c8-2565-4683-98fa-7533ae926b8e' },
    //   },
    //   {
    //     Teams_id: '+',
    //     directus_users_id: { id: '54c9be79-8132-421c-b194-754657068bb2' },
    //   },
    // ]

    if (props.editRow && props.editRow !== -1) {
      team_members.value.forEach((user) => {
        items['users']['create'].push({
          Teams_id: props.editRow.id,
          directus_users_id: {
            id: user.id,
          },
        })
      })

      team_leaders.value.forEach((user) => {
        items['team_leaders']['create'].push({
          Teams_id: props.editRow.id,
          directus_users_id: {
            id: user.id,
          },
        })
      })

      // console.log('edit_items', items)

      const delRes = await deleteItems({
        collection: 'Teams_directus_users', //teams_members
        items: {
          query: {
            filter: {
              Teams_id: props.editRow.id,
            },
          },
        },
      })

      const delLeaderRes = await deleteItems({
        collection: 'Teams_directus_users_1', //teams_leaders
        items: {
          query: {
            filter: {
              Teams_id: props.editRow.id,
            },
          },
        },
      })

      // console.log('delLeaderRes', delLeaderRes)
      // console.log('delRes', delRes)
      // console.log('items', items)

      const res = await updateItem({
        collection: 'Teams',
        id: props.editRow.id,
        item: items,
      })
      console.log('updateItem', res)
    } else {
      team_members.value.forEach((user) => {
        return items['users']['create'].push({
          Teams_id: '+',
          directus_users_id: {
            id: user.id,
          },
        })
      })

      team_leaders.value.forEach((user) => {
        return items['team_leaders']['create'].push({
          Teams_id: '+',
          directus_users_id: {
            id: user.id,
          },
        })
      })

      console.log('create', items)

      const res = await createItems({
        collection: 'Teams',
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
  team_name.value = ''
  description.value = ''

  team_leaders.value = []
  team_members.value = []
  team_leaderName.value = null
  team_membersName.value = []
  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  imgId.value = ''
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
  return !!imgId.value
    ? `${config.public.directus.url}assets/${imgId.value}`
    : '/img/avatars/placeholder-file.png'
})

const handleUploaded = (newValue) => {
  console.log('done:)', newValue)
}

const chooseItem = (item) => {
  console.log('chooseItemыыы', item)

  isModalLeaderOpen.value = false
  team_leaders.value = [item]
  team_leaderName.value = item.first_name
}

const saveLeaders = (items) => {
  // console.log('saveLeaders', items)
  isModalLeaderOpen.value = false
  team_leaders.value = items
  team_leaderName.value = items.map((item) => item.first_name)
}

const saveUser = (items) => {
  // console.log('saveUser', items)
  isModalMemberOpen.value = false
  team_members.value = items
  team_membersName.value = items.map((item) => item.first_name)
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
    team_members.value.splice(index, 1)
  }
  if (type == 'leaders') {
    team_leaders.value.splice(index, 1)
  }

  // team_members.value = team_members.value.filter(
  //   (member) => member.id !== item.id
  // )
}

onMounted(async () => {
  // console.log('props-edited', props)

  if (props.editRow && props.editRow !== -1) {
    team_name.value = props.editRow.name
    description.value = props.editRow.description
    team_members.value =
      props.editRow.users?.map((item) => ({
        first_name: item.directus_users_id.first_name,
        id: item.directus_users_id.id,
      })) || []

    team_leaders.value =
      props.editRow.team_leaders?.map((item) => ({
        first_name: item.directus_users_id.first_name,
        id: item.directus_users_id.id,
      })) || []

    imgId.value = props.editRow._image
  }

  // console.log('team_leaders', team_leaders)
  // console.log('team_members', team_members)
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
          <div class="flex items-center gap-2">
            <div
              v-if="props.icon"
              class="flex size-8 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-900/30"
            >
              <Icon :name="props.icon" class="size-4 text-primary-500" />
            </div>
            <div class="flex items-center gap-2">
              <h3
                class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
              >
                {{ t(props.title) }}
              </h3>
            </div>
          </div>
          <BaseButtonClose @click="resetModal" />
        </div>
      </template>

      <!-- Body -->
      <div
        class="teamsContainer body h-[480px] mx-auto overflow-y-auto overflow-x-hidden px-6 py-4"
        ref="rowsContainer"
      >
        <!-- Top section: info + avatar -->
        <div class="flex gap-6">
          <!-- Left: fields -->
          <div class="flex-1 flex flex-col gap-3 team-form-fields">
            <BaseInput
              v-model="team_name"
              :label="t('Team Name')"
              rounded="sm"
              type="string"
              :placeholder="t('Enter team name')"
            />

            <BaseListbox
              :label="t('Status')"
              v-model="team_status"
              :items="team_options"
              rounded="sm"
            />

            <!-- Team Leaders -->
            <div class="user-field-group">
              <div class="user-field-label">
                <Icon
                  name="ph:crown-duotone"
                  class="w-4 h-4 text-warning-500"
                />
                <span>{{ t('Team Leaders') }}</span>
                <span class="user-count" v-if="team_leaders.length">{{
                  team_leaders.length
                }}</span>
              </div>
              <div class="user-field-body">
                <div class="snackBox placeholder-leader">
                  <BaseSnack
                    v-for="(item, index) in team_leaders"
                    :key="index"
                    :label="item.first_name"
                    :id="item.id"
                    color="warning"
                    size="xs"
                    @delete="onDelete(item, index, 'leaders')"
                  />
                </div>
                <button
                  type="button"
                  class="add-user-btn"
                  @click="handleModalLeaderOpen('user')"
                  :title="t('Add leader')"
                >
                  <Icon name="ph:plus" class="w-4 h-4" />
                </button>
              </div>
            </div>

            <!-- Team Members -->
            <div class="user-field-group">
              <div class="user-field-label">
                <Icon
                  name="ph:users-three-duotone"
                  class="w-4 h-4 text-primary-500"
                />
                <span>{{ t('Team Members') }}</span>
                <span class="user-count" v-if="team_members.length">{{
                  team_members.length
                }}</span>
              </div>
              <div class="user-field-body">
                <div class="snackBox placeholder-members">
                  <BaseSnack
                    v-for="(item, index) in team_members"
                    :key="index"
                    :label="item.first_name"
                    :id="item.id"
                    color="primary"
                    size="xs"
                    @delete="onDelete(item, index, 'members')"
                  />
                </div>
                <button
                  type="button"
                  class="add-user-btn"
                  @click="handleModalMemberOpen('user')"
                  :title="t('Add member')"
                >
                  <Icon name="ph:plus" class="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>

          <!-- Right: avatar -->
          <div class="flex flex-col items-center gap-2 pt-1">
            <span class="text-xs text-muted-400 font-medium">{{
              t('Team Photo')
            }}</span>
            <AvatarUpload
              code="users"
              field="login"
              height="180px"
              width="180px"
              :result="UploadImg"
              :id="imgId"
              xmargin="-180px 0px 0px 0px"
              :fileUrl="Thumbnail"
            />
          </div>
        </div>

        <!-- Description -->
        <div class="mt-4">
          <BaseTextarea
            v-model="description"
            contrast="default-contrast"
            size="sm"
            :label="t('Description')"
            rounded="md"
            :placeholder="t('Write a short description about this team...')"
            color-focus
          />
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
        :chosedItems="team_leaders"
        :saveUser="saveLeaders"
        :chooseBttn="false"
        :saveBttn="true"
      />
      <UserCheckList
        collection="Users"
        :open="isModalMemberOpen"
        :close="handleModalMemberClose"
        :chosedItems="team_members"
        :saveUser="saveUser"
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
/* User field group */
.user-field-group {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.user-field-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
}

.user-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: #e2e8f0;
  color: #475569;
  font-size: 11px;
  font-weight: 600;
  border-radius: 999px;
  padding: 0 6px;
  height: 18px;
  min-width: 18px;
}

.user-field-body {
  display: flex;
  align-items: flex-start;
  gap: 6px;
}

.teamsContainer .nui-textarea-outer {
  border: 1px solid #d9d9d9;
  border-radius: 6px;
}

.teamsContainer .snackBox {
  flex: 1;
  border: 1px solid #e2e8f0;
  height: auto;
  min-height: 38px;
  max-height: 90px;
  overflow-y: auto;
  overflow-x: hidden;
  border-radius: 0.5rem;
  display: flex;
  flex-wrap: wrap;
  align-content: flex-start;
  gap: 4px;
  padding: 6px 8px;
  background: #f8fafc;
  transition: border-color 0.2s;
}

.teamsContainer .snackBox:hover {
  border-color: #cbd5e1;
}

.teamsContainer .placeholder-leader:empty::before {
  content: 'No leaders selected';
  color: #94a3b8;
  font-size: 12px;
}

.teamsContainer .placeholder-members:empty::before {
  content: 'No members selected';
  color: #94a3b8;
  font-size: 12px;
}

.add-user-btn {
  flex-shrink: 0;
  width: 34px;
  height: 34px;
  display: flex;
  align-items: center;
  justify-content: center;
  border: 1px solid #e2e8f0;
  border-radius: 0.5rem;
  background: white;
  color: #64748b;
  cursor: pointer;
  transition: all 0.15s;
  margin-top: 2px;
}

.add-user-btn:hover {
  border-color: #6366f1;
  color: #6366f1;
  background: #eef2ff;
}

.teamsContainer .snackBox .nui-snack {
  border: 1px solid #e2e8f0;
}

.teamsContainer .snackBox .nui-button-close {
  height: 20px !important;
  width: 20px !important;
}

.team-form-fields .nui-input {
  border: 1px solid #cdd5e0 !important;
}

.team-form-fields .nui-input:focus {
  border-color: #6366f1 !important;
}
</style>
