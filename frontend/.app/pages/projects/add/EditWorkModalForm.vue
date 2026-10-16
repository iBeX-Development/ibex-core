<script setup lang="ts">
import 'v-calendar/dist/style.css'

import { computed, onMounted, ref, toRefs } from 'vue'
import { useI18n } from 'vue-i18n'

import { useRouter } from 'vue-router'
import '~/assets/css/vcalendar.css'

const config = useRuntimeConfig()
const { deleteUsers } = useDirectusUsers()
const { t } = useI18n({ useScope: 'global' })

const { getUsers } = useDirectusUsers()
const myCompanyId = getMyCompanyId()
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const { token } = useDirectusToken()

import WarningModalForm from '~/components/form/WarningModalForm.vue'
import { priorities } from '~/components/workorder/ProjectConstants'

const myId = window.localStorage.getItem('myId')
const key = ref(1)

definePageMeta({
  middleware: ['auth'],
  title: 'Add task',
  showback: true,
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})

const props = defineProps({
  open: Boolean,
  code: String,
  title: String,
  close: Function,
  refresh: Function,
  clear: Function,
  editRow: Object,
  editTask: Object,
  row: Object,
})
const { editTask } = toRefs(props)

const router = useRouter()
const route = useRoute()
const { params } = useRoute()
const toaster = useToaster()
const type = ref([])
const users = ref([])
const loading = ref(false)

const task_id = ref(0)
const task_name = ref('')
const task_description = ref('')
const task_started_at = ref('')
const task_due = ref('')
const task_priority = ref('')
const project_leaders = ref([])
const project_members = ref([])
const project_team = ref([])

const slug = computed(() => route.params.slug)
const query = computed(() => {
  return {
    slug: slug.value,
  }
})
const task = ref([])

let createdId = 1
const isModalLeaderOpen = ref(false)
const isModalMemberOpen = ref(false)
const isModalTeamOpen = ref(false)

const isModalConfirmText = ref('')
const isModalConfirmOpen = ref(false)
const isError = ref(false)

const loadItems = async () => {
  try {
    const filters = {
      id: task_id.value,
    }

    const items = await getItems<any>({
      collection: 'Project_works',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: [
          '*',
          'task_leaders.*',
          'task_leaders.directus_users_id.*',
          'task_leaders.directus_users_id.avatar.*',
          'task_leaders.directus_users_id.role.*',

          'task_members.*',
          'task_members.directus_users_id.*',
          'task_members.directus_users_id.avatar.*',
          'task_members.directus_users_id.role.*',

          'task_company.*',
          'task_company.Contractors_id.*',
          'task_company.Contractors_id._image.*',
        ],
      },
    })

    // console.log('items', items)
    if (items.data.length) {
      task.value = items.data[0]
      task_name.value = task.value.name
      task_id.value = parseInt(task.value.id)
      task_priority.value = task.value.priority
      // console.log('task.value.priority', task.value.priority)
      // task_priority.value = priorities.find(
      //   (item) =>
      //     item.value == task.value.priority ||
      //     item?.__original == task.value.priority,
      // )
      task_started_at.value = task.value.started_at
      task_due.value = task.value.due
      task_description.value = task.value.description

      project_members.value = task.value.task_members?.map((item) => ({
        first_name: item.directus_users_id.first_name,
        id: item.directus_users_id.id,
      }))

      project_team.value = task.value.task_company?.map((item) => ({
        name: item.Contractors_id.name,
        id: item.Contractors_id.id,
      }))

      project_leaders.value = task.value.task_leaders?.map((item) => ({
        first_name: item.directus_users_id.first_name,
        id: item.directus_users_id.id,
      }))
    }
    loading.value = false
  } catch (e) {
    console.log(e)
  }
  // console.log(type.value)
}

const transformUser = (items) => {
  // console.log(items)
  const transformed_users = items.data.map((item) => ({
    label: item.first_name + ' ' + item.last_name,
    value: item.id,
  }))
  transformed_users.unshift({
    label: '',
    value: '',
  })
  return transformed_users
}

const loadUsers = async () => {
  try {
    const filters = {
      status: 'active',
      company_id: myCompanyId,
    }
    const items = await getUsers<any>({
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    users.value = transformUser(items)
    loading.value = false
  } catch (e) {
    console.log(e)
  }
  // console.log(users.value)
}

const handleModalMemberOpen = (type) => {
  isModalMemberOpen.value = true
}

const handleModalMemberClose = () => {
  isModalMemberOpen.value = false
}

const handleModalTeamOpen = (type) => {
  isModalTeamOpen.value = true
}

const handleModalTeamClose = () => {
  isModalTeamOpen.value = false
}
const handleModalLeaderOpen = (type) => {
  isModalLeaderOpen.value = true
}

const handleModalLeaderClose = () => {
  isModalLeaderOpen.value = false
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalTeamOpen.value = false
  isModalMemberOpen.value = false
  isModalLeaderOpen.value = false
  isModalConfirmText.value = ''
  isError.value = false
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
  // console.log('saveTeam', items)
  isModalTeamOpen.value = false
  project_team.value = items
}

const resetModal = () => {
  // console.log('resetModal')
  task_name.value = ''
  task_description.value = ''
  task_started_at.value = ''
  task_due.value = ''
  task_priority.value = ''
  project_members.value = []
  project_team.value = []
  project_leaders.value = []
  props.close()
  // props.refresh()
  // task list refresh hiih heregtei.
}

const refreshed = (id) => {
  console.log('hi', id)
  if (props.refresh) props.refresh(id)
}

const onDelete = (item, index, type) => {
  // console.log('onDelete', item)
  if (type == 'members') {
    project_members.value.splice(index, 1)
  }
  if (type == 'company') {
    project_team.value.splice(index, 1)
  }
  if (type == 'leaders') {
    project_leaders.value.splice(index, 1)
  }

  // project_members.value = project_members.value.filter(
  //   (member) => member.id !== item.id
  // )
}

// if (props.editTask) {
//   console.log('editTask_task_id', props.editTask)

//   task_id.value = parseInt(props.editTask.id)
//   task_name.value = props.editTask.name
//   task_priority.value = priorities.find(
//     (item) =>
//       item.value == props.editTask.priority ||
//       item?.__original == props.editTask.priority,
//   )

//   task_started_at.value = props.editTask.started_at
//   task_due.value = props.editTask.due
//   task_description.value = props.editTask.description
//   project_members.value = props.editTask.task_members?.map((item) => ({
//     first_name: item.directus_users_id.first_name,
//     id: item.directus_users_id.id,
//   }))
//   project_team.value = props.editTask.task_company?.map((item) => ({
//     name: item.Contractors_id.name,
//     id: item.Contractors_id.id,
//   }))
//   project_leaders.value = props.editTask.task_leaders?.map((item) => ({
//     first_name: item.directus_users_id.first_name,
//     id: item.directus_users_id.id,
//   }))
// }

watchEffect(async () => {
  if (editTask.value?.id) {
    // console.log('watchEffect new editTask', editTask.value)
    task_id.value = parseInt(editTask.value.id)
    await loadItems()
  }
})

// watch(
//   () => editTask.value?.id,
//   async (newVal) => {
//     console.log('newVal_1', newVal)

//     if (newVal) {
//       console.log('newVal_2', newVal)

//       task_id.value = parseInt(newVal)
//       console.log('task_id', task_id.value)

//       await loadItems()
//     }
//   },
//   { immediate: true, deep: true }, // Add deep: true to catch nested property changes
// )

onMounted(async () => {
  await loadUsers()
  await loadItems()
})

const submitHandler = async (values) => {
  // console.log('Values : ', values)
  if (!Number.isInteger(values.assigned_team)) {
    delete values.assigned_team
  }

  // values.action_status = 1
  let error = false
  values.status = 'published'
  values.project = slug.value
  values.name = values.work_name
  if (!values.name || values.name == '') {
    error = true
    isModalConfirmText.value = 'Task name is empty!'
  }
  if (!values.description || values.description == '') {
    error = true
    isModalConfirmText.value = 'Description is empty!'
  }

  if (error == true) {
    isModalConfirmOpen.value = true
    return
  }

  let saved_priority = priorities.find(
    (item) =>
      item.value == values.priority.__original ||
      item?.__original == values.priority.__original,
  )

  // console.log('saved_priority', saved_priority)
  // console.log('values.priority', values.priority)

  let items = {
    name: values.name,
    priority: saved_priority ? saved_priority.id : values.priority,
    project: parseInt(slug.value),
    project_name: values.project_name,
    description: values.description,
    due: values.due,
    started_at: values.started_at,
    work_name: values.work_name,
    task_leaders: {
      create: [],
    },
    task_members: {
      create: [],
    },
    task_company: {
      create: [],
    },
  }

  project_members.value.forEach((user) => {
    return items['task_members']['create'].push({
      Projects_id: '+',
      directus_users_id: {
        id: user.id,
      },
    })
  })

  project_leaders.value.forEach((user) => {
    return items['task_leaders']['create'].push({
      Projects_id: '+',
      directus_users_id: {
        id: user.id,
      },
    })
  })

  project_team.value.forEach((team) => {
    return items['task_company']['create'].push({
      Projects_id: '+',
      Contractors_id: {
        id: team.id,
      },
    })
  })

  // console.log('create', items)

  // console.log(' props.editTask?.id,', props.editTask?.id)

  if (props.editTask) {
    const delRes = await deleteItems({
      collection: 'Project_works_directus_users',
      items: {
        query: {
          filter: {
            Project_works_id: props.editTask?.id,
          },
        },
      },
    })

    const delLeaderRes = await deleteItems({
      collection: 'Project_works_directus_users_1',
      items: {
        query: {
          filter: {
            Project_works_id: props.editTask?.id,
          },
        },
      },
    })

    const delTeamsRes = await deleteItems({
      collection: 'Project_works_Contractors_1',
      items: {
        query: {
          filter: {
            Project_works_id: props.editTask?.id,
          },
        },
      },
    })

    // console.log('delLeaderRes', delLeaderRes)
    // console.log('delRes', delRes)

    updateItem({
      collection: 'Project_works',
      id: parseInt(props.editTask.id),
      item: items,
    }).then((res) => {
      console.log('done', res)
      refreshed(props.editTask?.id)

      // toaster.show({
      //   title: t('Updated'),
      //   message: t('Record updated successfully!'),
      //   color: 'success',
      //   icon: 'ph:user-circle-fill',
      //   closable: true,
      // })
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
}
</script>

<template>
  <form
    action=""
    method="POST"
    @submit.prevent="submitHandler"
    class="mx-auto w-full max-w-3xl"
  >
    <TairoModal :open="props.open" size="2xl" @close="resetModal">
      <template #header>
        <!-- Header -->
        <div class="flex w-full items-center justify-between">
          <h3
            class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
          >
            {{ props.title }}
          </h3>

          <BaseButtonClose @click="resetModal" />
        </div>
      </template>
      <!-- Body -->
      <div class="relative TaskAdd">
        <!-- Grid -->
        <div class="grid grid-cols-12 gap-6">
          <!-- Body -->
          <div class="col-span-12">
            <BaseCard
              color="default"
              rounded="md"
              class="flex justify-center p-6 nui-bg-white"
            >
              <FormKit
                type="form"
                :actions="true"
                :submit-label="t('Save')"
                @submit="submitHandler"
                :submit-attrs="{
                  inputClass:
                    'text-sm px-10 mt-5 py-3 is-button rounded bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
                  ignore: false,
                }"
              >
                <div class="flex items-center w-full max-w-md mb-1">
                  <div class="w-full">
                    <FormKit
                      :label="t('Task name')"
                      name="work_name"
                      type="text"
                      class=""
                      v-model="task_name"
                      :validation="'required'"
                    />
                  </div>
                </div>
                <div class="flex items-center w-full max-w-md mb-1">
                  <div class="w-full">
                    <FormKit
                      :label="t('Task description')"
                      name="description"
                      type="textarea"
                      v-model="task_description"
                      :classes="{
                        input: 'desc_input',
                        outer: 'desc_wrapper',
                        label: 'desc_label',
                      }"
                    />
                  </div>
                </div>
                <div class="flex items-center w-full max-w-md mb-1">
                  <div class="w-full">
                    <FormKit
                      :label="t('Start date')"
                      name="started_at"
                      type="date"
                      v-model="task_started_at"
                      :validation="'required'"
                    />
                  </div>
                  <div class="w-full ml-3">
                    <FormKit
                      :label="t('Due date')"
                      name="due"
                      type="date"
                      v-model="task_due"
                      :validation="'required'"
                    />
                  </div>
                </div>

                <div class="flex items-center w-full max-w-md mb-1">
                  <div class="w-full">
                    <FormKit
                      :label="t('Priority')"
                      name="priority"
                      type="select"
                      :validation="'required'"
                      v-model="task_priority"
                      :options="priorities"
                    />
                  </div>
                </div>

                <div class="flex items-center w-full max-w-md mb-1">
                  <div
                    class="flex project_leaders items-center mb-2 mt-3 gap-2"
                  >
                    <div class="flex w-[494px]">
                      <div
                        title="Project leader"
                        class="snackLeaderBox snackBox placeholder-leader flex flex-wrap items-end gap-2"
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
                        style="width: 36px; height: 48px"
                        color="default"
                        :class="'ml-1'"
                        @click="handleModalLeaderOpen('user')"
                      >
                        {{
                          project_leaders == null || project_leaders.length == 0
                            ? `...`
                            : project_leaders.length
                        }}
                      </BaseButton>
                    </div>
                  </div>
                </div>

                <!-- Task members -->
                <div class="flex items-center w-full max-w-md mb-1">
                  <div class="flex project_members items-center mb-2 gap-2">
                    <div class="flex w-[494px]">
                      <div
                        title="Task members"
                        class="snackMemberBox snackBox placeholder-members flex flex-wrap items-end gap-2"
                      >
                        <BaseSnack
                          v-for="(item, index) in project_members"
                          :key="index"
                          :label="item.first_name"
                          :id="item.id"
                          color="muted"
                          size="xs"
                          @delete="onDelete(item, index, 'members')"
                        />
                      </div>

                      <BaseButton
                        style="width: 36px; height: 48px"
                        color="default"
                        :class="'ml-1'"
                        @click="handleModalMemberOpen('user')"
                      >
                        {{
                          project_members == null || project_members.length == 0
                            ? `...`
                            : project_members.length
                        }}
                      </BaseButton>
                    </div>
                  </div>
                </div>

                <!-- Task company -->
                <div class="flex items-center w-full max-w-md mb-1">
                  <div class="flex project_teams items-center mb-2 gap-2">
                    <div class="flex w-[494px]">
                      <div
                        title="Task company"
                        class="snackTeamBox snackBox placeholder-teams flex flex-wrap items-end gap-2"
                      >
                        <BaseSnack
                          v-for="(item, index) in project_team"
                          :key="index"
                          :label="item.name"
                          :id="item.id"
                          color="muted"
                          size="xs"
                          @delete="onDelete(item, index, 'company')"
                        />
                      </div>

                      <BaseButton
                        style="width: 36px; height: 48px"
                        color="default"
                        :class="'ml-1'"
                        @click="handleModalTeamOpen('user')"
                      >
                        {{
                          project_team == null || project_team.length == 0
                            ? `...`
                            : project_team.length
                        }}
                      </BaseButton>
                    </div>
                  </div>
                </div>
              </FormKit>
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
                collection="Contractors"
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
            </BaseCard>
          </div>
        </div>
      </div>
    </TairoModal>
  </form>
</template>

<style>
.TaskAdd .snackLeaderBox {
  width: 448px;
  border: 1px solid #cdd5e0;
  height: 48px;
  /* height: auto;
  min-height: 38px;
  max-height: 120px; */
  overflow-y: auto;
  overflow-x: hidden;
  border-radius: 0.375rem;
  align-items: flex-start;
  padding: 5px;
}
.TaskAdd .snackMemberBox {
  width: 530px;
  border: 1px solid #cdd5e0;
  height: 38px;
  overflow-y: auto;
  overflow-x: hidden;
  border-radius: 0.375rem;
  align-items: flex-start;
  padding: 5px;
}
.TaskAdd .snackTeamBox {
  width: 530px;
  border: 1px solid #cdd5e0;
  height: 38px;
  overflow-y: auto;
  overflow-x: hidden;
  border-radius: 0.375rem;
  align-items: flex-start;
  padding: 5px;
}
.TaskAdd .placeholder-leader {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}

.TaskAdd .placeholder-leader:empty::before {
  content: 'Task owner';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}

.TaskAdd .placeholder-members {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
  height: 48px;
}
.TaskAdd .placeholder-members:empty::before {
  content: 'Task members';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}

.TaskAdd .placeholder-teams {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
  height: 48px;
}
.TaskAdd .placeholder-teams:empty::before {
  content: 'Task company';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}
.TaskAdd .snackBox .nui-snack {
  border: 1px solid #c1bebe;
}

.TaskAdd .snackBox .nui-button-close {
  height: 24px !important;
}

.project_description .nui-textarea-wrapper {
  width: 100%;
}
</style>
