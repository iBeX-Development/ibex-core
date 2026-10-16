<script setup lang="ts">
import { Calendar } from 'v-calendar'

import 'v-calendar/dist/style.css'
import '~/assets/css/vcalendar.css'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
import { priorities } from '~/components/workorder/WorkOrderConstants'

definePageMeta({
  middleware: ['auth'],
  title: 'PM templates',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import ModalAssetsList from '~/components/workorder/ModalAssetsList.vue'
import ModalTemplateList from '~/components/workorder/ModalTemplateList.vue'
import DynamicModalForm from '~/components/form/DynamicModalForm.vue'

const router = useRouter()
const { params } = useRoute()
const teams = ref([])
const users = ref([])
const work_order = ref({})
const loading = ref(true)
const due = ref(null)
const asset = ref({
  id: null,
  name: '',
})
const template = ref({
  id: null,
  name: '',
})
const toaster = useToaster()

const isModalAssetOpen = ref(false)
const isModalTemplateOpen = ref(false)
const handleModalAssetClose = () => {
  isModalAssetOpen.value = false
}
const handleModalTemplateClose = () => {
  isModalTemplateOpen.value = false
}
const setAsset = (obj: any) => {
  asset.value = obj
}
const setTemplate = (obj: any) => {
  template.value = obj
}

const { getItems, createItems, updateItem } = useDirectusItems()
const { getUsers } = useDirectusUsers()
const myCompanyId = getMyCompanyId()

const transformTeams = (items) => {
  const transformed_teams = items.data.map((item) => ({
    label: item.name,
    value: item.id,
  }))
  transformed_teams.unshift({
    label: '',
    value: null,
  })
  return transformed_teams
}

const loadTeams = async () => {
  try {
    const filters = {
      status: 'published',
      company_id: { _eq: myCompanyId },
    }
    const items = await getItems<any>({
      collection: 'Teams',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    teams.value = transformTeams(items)
    // loading.value = false;
  } catch (e) {
    console.log(e)
  }
  console.log(teams.value)
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

// autocomplete2-д нэрээр нь харуулахын тулд одоогийн assigned_to ID-г
// {id, full_name} хэлбэрт хөрвүүлнэ
const fetchAssignedUserOption = async (id) => {
  if (!id) return null
  try {
    const res = await getUsers<any>({
      params: {
        filter: { id: { _eq: id } },
        fields: ['id', 'first_name', 'last_name'],
        limit: 1,
      },
    })
    const items = Array.isArray(res) ? res : res?.data ?? []
    const u = items[0]
    if (!u) return null
    return {
      ...u,
      full_name: `${u.first_name || ''} ${u.last_name || ''}`.trim(),
    }
  } catch (e) {
    return null
  }
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
    // loading.value = false;
  } catch (e) {
    console.log(e)
  }
  console.log(users.value)
}

const loadWorkOrder = async () => {
  try {
    const filters = {
      id: params.id,
      company_id: { _eq: myCompanyId },
    }
    const items = await getItems<any>({
      collection: 'Work_order',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*', 'asset.*', 'template.*'],
      },
    })
    work_order.value = items.data[0]
    if (work_order.value.assigned_to) {
      work_order.value.assigned_to = await fetchAssignedUserOption(
        work_order.value.assigned_to,
      )
    }
    // loading.value = false;
  } catch (e) {
    console.log(e)
  }
  console.log(teams.value)
}

onMounted(async () => {
  loading.value = true
  await loadTeams()
  await loadUsers()
  await loadWorkOrder()
  console.log(work_order.value)
  asset.value = work_order.value.asset
  template.value = work_order.value.template
  due.value = work_order.value.due.split('T')[0]
  console.log(asset.value, template.value)
  loading.value = false
})

const submitHandler = async (values) => {
  console.log('Values : ', values)
  values.assigned_to = values.assigned_to?.id ?? values.assigned_to ?? null
  setTimeout(() => {
    if (values && values.assigned_to == '') {
      values['assigned_to'] = null
    }

    const updateData = {
      collection: 'Work_order',
      id: params.id,
      item: values,
    }
    updateItem(updateData).then((res) => {
      router.push('/workorder/open')
      toaster.show({
        title: t('Update success'),
        message: t(`Record update successfully`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
    })
  }, 500)
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12" v-if="!loading">
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
                v-model="asset.name"
                name="asset_name"
                type="text"
                :label="t('Asset')"
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
          </div>
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
          </div>

          <div class="flex items-center w-full max-w-md mb-1">
            <div class="w-full">
              <FormKit
                v-model="work_order.name"
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
                v-model="due"
                :label="t('Due date')"
                name="due"
                type="date"
                :validation="'required'"
              />
            </div>
          </div>

          <div class="flex items-center w-full max-w-md mb-1">
            <div class="w-full">
              <FormKit
                v-model="work_order.priority"
                :label="t('Priority')"
                name="priority"
                type="select"
                :validation="'required'"
                :options="priorities"
              />
            </div>
          </div>
          <div class="flex items-center w-full max-w-md mb-1">
            <div class="w-full">
              <FormKit
                v-model="work_order.assigned_team"
                :label="t('Assigned team')"
                name="assigned_team"
                type="select"
                :options="teams"
              />
            </div>
          </div>
          <div class="flex items-center w-full max-w-md mb-1">
            <div class="w-full">
              <FormKit
                v-model="work_order.assigned_to"
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
          :location="work_order.location"
        />
        <ModalTemplateList
          :open="isModalTemplateOpen"
          :close="handleModalTemplateClose"
          :setTemplate="setTemplate"
        />
      </div>
      <div class="col-span-6" v-if="loading">
        <BasePlaceload class="h-4 w-full rounded" />
      </div>
    </div>
  </div>
</template>
