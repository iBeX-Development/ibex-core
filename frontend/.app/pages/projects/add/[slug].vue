<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import '~/assets/css/vcalendar.css'
import WarningModalForm from '~/components/form/WarningModalForm.vue'

import { priorities } from '~/components/workorder/WorkOrderConstants'

const { getItems, createItems, updateItem } = useDirectusItems()
const { getUsers } = useDirectusUsers()
const myCompanyId = getMyCompanyId()
const myId = window.localStorage.getItem('myId')

const { t } = useI18n({ useScope: 'global' })

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

const router = useRouter()
const route = useRoute()
const { params } = useRoute()
const toaster = useToaster()
const type = ref([])
const users = ref([])
const loading = ref(false)

const project_leaders = ref([])
const project_members = ref([])
const project_team = ref([])

const slug = computed(() => route.params.slug)
const query = computed(() => {
  return {
    slug: slug.value,
  }
})
const project = ref({
  id: null,
  name: '',
})
const asset = ref({
  id: null,
  name: '',
})

const template = ref({
  id: null,
  name: '',
})

const work_order_name = ref('')
let createdId = 1

const isModalAssetOpen = ref(false)
const isModalTemplateOpen = ref(false)

const isModalLeaderOpen = ref(false)
const isModalMemberOpen = ref(false)
const isModalTeamOpen = ref(false)

const isModalConfirmText = ref('')
const isModalConfirmOpen = ref(false)
const isError = ref(false)

const handleModalAssetClose = () => {
  isModalAssetOpen.value = false
}
const handleModalTemplateClose = () => {
  isModalTemplateOpen.value = false
  work_order_name.value = template.value.name
}

const setTemplate = (obj: any) => {
  template.value = obj
}

console.log('slug', slug)

const loadItems = async () => {
  try {
    const filters = {
      id: slug.value,
    }
    console.log('filters', filters)

    const items = await getItems<any>({
      collection: 'Projects',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['id', 'name'],
      },
    })

    console.log('items', items)
    project.value = items.data[0]
    loading.value = false
  } catch (e) {
    console.log(e)
  }
  console.log(type.value)
}

const transformUser = (items) => {
  console.log(items)
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
  console.log(users.value)
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
  console.log('saveTeam', items)
  isModalTeamOpen.value = false
  project_team.value = items
}

const resetModal = () => {
  project_members.value = []
  project_team.value = []
  project_leaders.value = []
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

  let items = {
    name: values.name,
    priority: values.priority,
    project: slug.value,
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
    company_id: myCompanyId,
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

  console.log('create', items)

  await createItems({ collection: 'Project_works', items: [items] })
    .then((ress) => {
      console.log('ress', ress)
      createdId = ress[0]?.id
    })
    .then((wo_res) => {
      // console.log('wo_res', wo_res)
      toaster.show({
        title: t('Added'),
        message: t(`Work created successfully`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })

      // resetModal()
      router.push(`/projects/details/${slug.value}`)

      // createItems({
      //   collection: 'Work_order_actions',
      //   items: {
      //     wo_id: createdId,
      //     first_user: myId,
      //     action_status: 1,
      //     // type: 'wo',
      //     type: 'open',
      //   },
      // })
    })
}
</script>

<template>
  <div class="relative TaskAdd">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-8">
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
              <div class="w-full mr-3">
                <FormKit
                  v-model="project.name"
                  name="project_name"
                  type="text"
                  :label="$t('Project name')"
                  readonly="true"
                />
              </div>
              <FormKit v-model="project.id" name="project" type="hidden" />
            </div>
            <div class="flex items-center w-full max-w-md mb-1">
              <div class="w-full">
                <FormKit
                  :label="$t('Task name')"
                  name="work_name"
                  type="text"
                  class=""
                  :validation="'required'"
                />
              </div>
            </div>
            <div class="flex items-center w-full max-w-md mb-1">
              <div class="w-full">
                <FormKit
                  :label="$t('Task description')"
                  name="description"
                  type="textarea"
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
                  :label="$t('Start date')"
                  name="started_at"
                  type="date"
                  :validation="'required'"
                />
              </div>
            </div>
            <div class="flex items-center w-full max-w-md mb-1">
              <div class="w-full">
                <FormKit
                  :label="$t('Due date')"
                  name="due"
                  type="date"
                  :validation="'required'"
                />
              </div>
            </div>

            <div class="flex items-center w-full max-w-md mb-1">
              <div class="w-full">
                <FormKit
                  :label="$t('Priority')"
                  name="priority"
                  type="select"
                  :validation="'required'"
                  :options="priorities"
                />
              </div>
            </div>

            <div class="flex items-center w-full max-w-md mb-1">
              <div class="flex project_leaders items-center mb-2 mt-3 gap-2">
                <div class="flex w-[494px]">
                  <div
                    :title="$t('Project leader')"
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
                    :title="$t('Task members')"
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
                    :title="$t('Task company')"
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
