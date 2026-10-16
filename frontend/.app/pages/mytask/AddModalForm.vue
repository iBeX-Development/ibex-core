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
const { token } = useDirectusToken()
const myCompanyId = getMyCompanyId()

const type = ref('')
const team_name = ref('')
const team_leaders = ref([])
const team_leaderName = ref(null)
const team_members = ref([])
const team_membersName = ref([])
const description = ref('')
const team_status = ref('Enable')

let imgId = ref(-1)
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
    // console.log('team_leaders!', team_leaders)

    let items = {
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
        : imgId.value != -1
        ? imgId.value
        : null,
      company_id: myCompanyId,
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

    if (props.editRow != -1) {
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

      const res = await updateItem({
        collection: 'Teams',
        id: props.editRow.id,
        item: items,
      })
      // console.log('delRes', delRes)
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

      // console.log('create', items)

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

  if (props.editRow) {
    team_name.value = props.editRow.name
    description.value = props.editRow.description
    team_members.value = props.editRow.users?.map((item) => ({
      first_name: item.directus_users_id.first_name,
      id: item.directus_users_id.id,
    }))

    team_leaders.value = props.editRow.team_leaders?.map((item) => ({
      first_name: item.directus_users_id.first_name,
      id: item.directus_users_id.id,
    }))

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
          <h3
            class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
          >
            {{ t(props.title) }}
          </h3>

          <BaseButtonClose @click="resetModal" />
        </div>
      </template>

      <!-- Body -->
      <div
        class="rowsContainer body h-[440px] grid mx-auto overflow-y-auto overflow-x-hidden"
        ref="rowsContainer"
      >
        <div class="teamsBody w-[580px] mx-auto">
          <div class="team_about flex justify-around">
            <div class="w-[354px]">
              <BaseInput
                v-model="team_name"
                :label="t('Name')"
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
                  :label="t('Status')"
                  style="width: 320px"
                  v-model="team_status"
                  :items="team_options"
                  rounded="none"
                />
              </div>

              <div class="w-[320px] flex team_leaders items-center mt-4">
                <div
                  title="Team leader"
                  class="snackBox placeholder-leader flex flex-wrap items-end gap-2"
                >
                  <BaseSnack
                    v-for="(item, index) in team_leaders"
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
              <div class="w-[320px] flex team_members items-center mt-4">
                <div
                  title="Team members"
                  class="snackBox placeholder-members flex flex-wrap items-end gap-2"
                >
                  <!-- <div class="container flex items-end gap-4"> -->
                  <BaseSnack
                    v-for="(item, index) in team_members"
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
          <div class="team_description w-[560px] flex mb-5 ml-1">
            <BaseTextarea
              v-model="description"
              contrast="default-contrast"
              size="sm"
              :label="t('Description')"
              rounded="md"
              placeholder="Write a description..."
              color-focus
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
  content: 'Team leader';
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
  content: 'Team members';
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

.team_description .nui-textarea-wrapper {
  width: 100%;
}
</style>
