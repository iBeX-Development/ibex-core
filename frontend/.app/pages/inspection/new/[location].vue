<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import '~/assets/css/vcalendar.css'
import ModalAssetsList from '~/components/workorder/ModalAssetsList.vue'
import ModalTemplateList from '~/components/workorder/ModalTemplateList.vue'
import {
  open_status_id,
  draft_status_id,
} from '~/components/workorder/WorkOrderStatus'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'New Inspection templates',
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
const type = ref([])
const users = ref([])
const loading = ref(false)
const { params } = useRoute()
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

const { getItems, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const { getUsers } = useDirectusUsers()
const toaster = useToaster()

const transformType = (items) => {
  console.log(items)
  const transformed_users = items.data.map((item) => ({
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

onMounted(async () => {
  // await loadTeams();
  await loadUsers()
  // await loadTypes();
})

const submitHandler = async (values) => {
  console.log('Values : ', values)
  values.status = '1'
  values.priority = 1
  values.type = 4 //pm
  values.pm_type = 'inspection'
  values.created_type = 'inspection'
  values.action_status = 1
  // values.wo_status = draft_status_id
  values.wo_status = open_status_id
  values.location = params.location
  values.assigned_to = values.assigned_to?.id || values.assigned_to || null

  // templates dotorh items flow-oor uusch bgaa,
  // work_order_items_tree webhook back-end projectryy ogch parentaa olj update hiideg.
  console.log('Values_2 : ', values)

  await createItems({
    collection: 'Work_inspections',
    items: [{ ...values, company_id: myCompanyId }],
  }).then((asset_res) => {
    createdId = asset_res[0]?.id
    console.log('wo_res', asset_res)
    console.log('asset_res.asset', asset_res[0]?.asset)

    // getItems({
    //   collection: 'Assets',
    //   params: {
    //     filter: {
    //       id: asset_res[0]?.asset,
    //     },
    //     // filter: {
    //     //   query: {
    //     //     id: asset_res[0]?.asset,
    //     //   },
    //     // },
    //     limit: 1,
    //     page: 1,
    //     meta: 'filter_count',
    //     fields: ['*', 'location.*'],
    //   },
    // }).then((loc_res) => {
    //   console.log(loc_res)

    router.push(`/inspection/location/${params.location}`)
    toaster.show({
      title: t('Added'),
      message: t(`Record created successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })

    createItems({
      collection: 'Work_inpection_actions',
      items: {
        wo_id: createdId,
        first_user: myId,
        action_status: 1,
        type: 'inspection',
        company_id: myCompanyId,
      },
    })
    // })
  })
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-6">
        <BaseCard color="default" rounded="md" class="p-6 nui-bg-white">
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
            <!-- <div class="flex items-center w-full max-w-md mb-1">
              <div class="w-full mr-3">
                <FormKit
                  v-model="asset.name"
                  name="asset_name"
                  type="text"
                  label="Asset"
                  :validation="'required'"
                  readonly="true"
                />
              </div>
              <BaseButton
                color="danger"
                class="mt-5"
                @click="isModalAssetOpen = true"
              >
                {{ t('Choose') }}
              </BaseButton>
              <FormKit v-model="asset.id" name="asset" type="hidden" />
            </div> -->
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

            <div class="flex items-center w-full max-w-md mb-1">
              <div class="w-full">
                <FormKit
                  :label="t('Assigned user')"
                  name="assigned_to"
                  type="autocomplete2"
                  collection_name="users"
                  item_value="id"
                  item_title="full_name"
                  search_field="full_name"
                  :placeholder="t('Choose a user')"
                />
              </div>
            </div>
          </FormKit>
          <ModalAssetsList
            :open="isModalAssetOpen"
            :close="handleModalAssetClose"
            :setAsset="setAsset"
            :location="params.location"
          />
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
