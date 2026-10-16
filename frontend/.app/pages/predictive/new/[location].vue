<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import '~/assets/css/vcalendar.css'
import ModalTemplateList from '~/components/workorder/ModalTemplateList.vue'
import { draft_status_id } from '~/components/workorder/WorkOrderStatus'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'New PDM templates',
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

const { getItems, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const router = useRouter()
const type = ref([])
const users = ref<Array<{ id: string; label: string }>>([])
const loading = ref(false)
const { params } = useRoute()
const asset = ref({
  id: null,
  name: '',
})
const template = ref<{ id: string | undefined; name: string }>({
  id: undefined,
  name: '',
})

const assigned_user = ref<{ id: string; label: string } | null>(null)
const userSearch = ref('')
const showUserDropdown = ref(false)

const filteredUsers = computed(() => {
  const q = userSearch.value.toLowerCase().trim()
  if (q.length < 2) return []
  return users.value.filter((u) => u.label.toLowerCase().includes(q))
})

const chooseUser = (u: { id: string; label: string }) => {
  assigned_user.value = u
  userSearch.value = u.label
  showUserDropdown.value = false
}

const clearUser = () => {
  assigned_user.value = null
  userSearch.value = ''
  showUserDropdown.value = false
}

const hideUserDropdown = () => {
  setTimeout(() => {
    showUserDropdown.value = false
  }, 200)
}
const work_order_name = ref('')
let createdId = 1
const myId = window.localStorage.getItem('myId')

const isModalAssetOpen = ref(false)
const isModalTemplateOpen = ref(false)
const handleModalAssetClose = () => {
  isModalAssetOpen.value = false
}
const handleModalTemplateClose = () => {
  isModalTemplateOpen.value = false
  work_order_name.value = template.value.name
}
const setAsset = (obj: any) => {
  asset.value = obj
}
const setTemplate = (obj: any) => {
  template.value = obj
}

const max_depth = 5

const field_templates = () => {
  let fields = ['id, name, parent, data_label, template_type.*, template.id']
  for (let i = 0; i <= max_depth; i++) {
    const joined_string = Array.from({ length: i }, () => 'children').join('.')
    if (joined_string !== '')
      fields.push(
        [
          joined_string.concat('.id'),
          joined_string.concat('.name'),
          joined_string.concat('.parent'),
          joined_string.concat('.data_label'),
          joined_string.concat('.template_type.*'),
          joined_string.concat('.template.id'),
        ].join(','),
      )
  }
  return fields
}

const insertTemplateItems = async (
  templateNode: any,
  workorderId: number,
  parentId: number | null = null,
) => {
  const added = await createItems({
    collection: 'Predictive_item',
    items: [
      {
        status: 1,
        active: 1,
        workorder: workorderId,
        parent: parentId,
        name: templateNode.data_label ?? templateNode.name,
        template_type:
          templateNode.template_type?.id ?? templateNode.template_type,
        created_type: 'user',
        company_id: myCompanyId,
      },
    ],
  })
  const newId = Array.isArray(added) ? added[0]?.id : added?.id
  if (!newId) return
  if (templateNode.children?.length) {
    await Promise.all(
      templateNode.children.map((child: any) =>
        insertTemplateItems(child, workorderId, newId),
      ),
    )
  }
}

const insertPredictiveItems = async (workorderId: number) => {
  if (!template.value.id) return
  const fields_tem = field_templates()
  const items = await getItems({
    collection: 'Template_header',
    params: {
      filter: {
        status: 'published',
        parent: { _null: true },
        template: template.value.id,
      },
      limit: -1,
      meta: 'filter_count',
      fields: fields_tem,
    },
  })
  await Promise.all(
    items.data.map((node: any) => insertTemplateItems(node, workorderId, null)),
  )
}
const { getUsers } = useDirectusUsers()
const toaster = useToaster()

const transformType = (items: any) => {
  console.log(items)
  const transformed_users = items.data.map((item: any) => ({
    label: item.name,
    value: item.id,
  }))
  transformed_users.unshift({
    label: '',
    value: '',
  })
  return transformed_users
}

const loadTypes = async () => {
  try {
    const filters = {
      status: '1',
      // code_work_order: 'wo',
    }
    const items = await getItems<any>({
      collection: 'Work_group_type',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    type.value = transformType(items)
    loading.value = false
  } catch (e) {
    console.log(e)
  }
  console.log(type.value)
}

const transformUser = (items: any) => {
  const list = Array.isArray(items) ? items : items?.data ?? []
  return list.map((item: any) => ({
    id: item.id,
    label: item.first_name + ' ' + item.last_name,
  }))
}

const loadUsers = async () => {
  try {
    const filters = {
      // status: 'active',
      active: 1,
      company_id: myCompanyId,
    }
    const items = await getUsers<any>({
      params: {
        filter: filters,
        limit: 25,
        page: 1,
        fields: ['*'],
      },
    })
    users.value = transformUser(items)
    loading.value = false
  } catch (e) {
    console.log(e)
  }
  console.log('users.value', users.value)
}

onMounted(async () => {
  // await loadTeams();
  await loadUsers()
  // await loadTypes();
})

const submitHandler = async (values: any) => {
  console.log('Values : ', values)
  values.status = 1 //Open
  values.priority = 1 //Low
  values.type = 5 //pdm
  values.pm_type = 'pdm'
  values.created_type = 'pdm'
  values.action_status = 1 //created
  values.wo_status = draft_status_id
  values.wo_status = 1

  values.location = params.location
  values.assigned_to = assigned_user.value?.id ?? null
  delete values.assigned_to_name

  // templates dotorh items flow-oor uusch bgaa,
  // work_order_items_tree webhook back-end projectryy ogch parentaa olj update hiideg.
  console.log('Values_2 : ', values)

  await createItems({
    collection: 'Predictive',
    items: [{ ...values, company_id: myCompanyId }],
  })
    .then(async (cre_res: any) => {
      createdId = cre_res[0]?.id
      console.log('wo_res', cre_res)

      router.push(`/predictive/location/${params.location}`)
      toaster.show({
        title: t('Added'),
        message: t(`Record created successfully`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })

      createItems({
        collection: 'Predictive_actions',
        items: {
          wo_id: createdId,
          first_user: myId,
          action_status: 1,
          type: 'pdm',
          company_id: myCompanyId,
        },
      })

      if (assigned_user.value?.id) {
        createItems({
          collection: 'Predictive_users',
          items: {
            work_order: createdId,
            user: assigned_user.value.id,
            company_id: myCompanyId,
          },
        })
      }

      // await insertPredictiveItems(createdId)
    })
    .catch((err) => {
      console.log('wo_pr_err', err)
      toaster.show({
        title: t('Error'),
        message: t('Failed to create record'),
        color: 'danger',
      })
    })
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-6">
        <BaseCard rounded="md" class="p-6 nui-bg-white">
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
                  v-model="template.name"
                  name="template_name"
                  type="text"
                  :label="t('Template')"
                  readonly="true"
                />
              </div>
              <BaseButton
                color="danger"
                class="mt-5"
                @click="isModalTemplateOpen = true"
              >
                {{ t('Choose') }}
              </BaseButton>
              <FormKit v-model="template.id" name="template" type="hidden" />
            </div>
            <div class="flex items-center w-full max-w-md mb-1">
              <div class="w-full">
                <FormKit
                  v-model="work_order_name"
                  :label="t('Name')"
                  name="name"
                  type="text"
                  class=""
                  :validation="'required'"
                />
              </div>
            </div>

            <!-- <div class="flex items-center w-full max-w-md mb-1">
              <div class="w-full">
                <label class="nui-label pb-1 text-[0.825rem]">{{
                  t('Assigned user')
                }}</label>
                <div class="relative">
                  <div class="relative">
                    <input
                      v-model="userSearch"
                      type="text"
                      class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full pr-8"
                      style="
                        padding: 10px;
                        border: 1px solid #d1d5db;
                        border-radius: 6px;
                      "
                      :placeholder="t('Search user...')"
                      autocomplete="off"
                      @focus="showUserDropdown = true"
                      @input="showUserDropdown = true"
                      @blur="hideUserDropdown"
                    />
                    <button
                      v-if="assigned_user"
                      class="absolute right-2 top-1/2 -translate-y-1/2 text-muted-400 hover:text-red-500"
                      type="button"
                      @mousedown.prevent="clearUser"
                    >
                      <Icon name="ph:x" class="size-3.5" />
                    </button>
                  </div>
                  <div
                    v-if="showUserDropdown && filteredUsers.length > 0"
                    class="absolute z-50 mt-1 w-full max-h-56 overflow-y-auto bg-white dark:bg-muted-900 border border-muted-200 dark:border-muted-700 rounded-lg shadow-xl"
                  >
                    <div
                      v-for="u in filteredUsers"
                      :key="u.id"
                      class="flex items-center px-3 py-2 hover:bg-muted-50 dark:hover:bg-muted-800 cursor-pointer text-sm"
                      @mousedown.prevent="chooseUser(u)"
                    >
                      <Icon
                        name="lucide:user"
                        class="size-4 mr-2 text-muted-400"
                      />
                      <span class="text-muted-700 dark:text-muted-200">{{
                        u.label
                      }}</span>
                    </div>
                  </div>
                  <div
                    v-if="
                      showUserDropdown &&
                      userSearch.length >= 2 &&
                      filteredUsers.length === 0
                    "
                    class="absolute z-50 mt-1 w-full bg-white dark:bg-muted-900 border border-muted-200 dark:border-muted-700 rounded-lg shadow-xl"
                  >
                    <div class="px-3 py-2 text-xs text-muted-400">
                      {{ t('No results') }}
                    </div>
                  </div>
                </div>
              </div>
            </div> -->
          </FormKit>
          <ModalTemplateList
            :open="isModalTemplateOpen"
            :close="handleModalTemplateClose"
            :setTemplate="setTemplate"
          />
        </BaseCard>
      </div>
    </div>
  </div>
</template>
