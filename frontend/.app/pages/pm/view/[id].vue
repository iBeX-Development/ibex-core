<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { priorities } from '~/components/workorder/WorkOrderConstants'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Preventative maintenance tasks',
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
const { params } = useRoute()
const teams = ref([])
const work_order = ref({})
const { getItems, createItems, updateItem } = useDirectusItems()
const { getUsers } = useDirectusUsers()
const loading = ref(true)
const key = ref(1)
const timeout = ref(null)
const toaster = useToaster()

// Counter
const daysPassed = ref(0)
const hoursPassed = ref(0)
const minutesPassed = ref(0)
const secondsPassed = ref(0)

// Work order file
const inputFile = ref()
const type = ref([])
const currentAvatar = computed(() => '/img/avatars/company.svg')
const due_date = ref(null)

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const loadWorkOrder = async () => {
  try {
    const filters = {
      id: params.id,
    }
    const items = await getItems<any>({
      collection: 'Work_pm',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*', 'asset.*', 'asset.location.name', 'template.*'],
      },
    })
    work_order.value = items.data[0]
    // loading.value = false;
  } catch (e) {
    console.log(e)
  }
  console.log(teams.value)
}

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

const handleComplete = async () => {
  const updateData = {
    collection: 'Work_pm',
    id: params.id,
    item: {
      status: '3',
    },
  }
  updateItem(updateData).then((res) => {
    // router.push(`/workorder/location/completed/${work_order?.value?.asset?.location}`);
    toaster.show({
      title: t('Update success'),
      message: t(`Record update successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  })
}

onMounted(async () => {
  loading.value = true
  await loadWorkOrder()
  await loadTypes()
  loading.value = false
})
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-5 gap-3" v-if="!loading">
      <!-- Header -->
      <div class="col-span-3">
        <div class="grid grid-cols-4">
          <div>
            <BaseHeading
              as="h3"
              size="2xl"
              weight="bold"
              class="text-muted-800 dark:text-white"
            >
              Work Order #{{ work_order.id }}
            </BaseHeading>
          </div>

          <div>
            <FormKit
              label="Priority"
              name="priority"
              type="select"
              :options="priorities"
              v-model="work_order.priority"
            />
          </div>
          <div class="ml-5">
            <FormKit
              :label="t('WO Name')"
              name="wo_name"
              type="text"
              v-model="work_order.wo_name"
            />
          </div>
          <div class="ml-5">
            <FormKit
              :label="t('Group Number')"
              name="group_number"
              type="text"
              v-model="work_order.group_number"
            />
          </div>
          <div class="col-span-2">
            <div class="pt-7">
              <BaseButton color="primary" class="p-2">
                <Icon name="ph:bank-duotone" class="-ms-1 size-4" />
                <span>{{ work_order?.asset?.name }}</span>
              </BaseButton>
            </div>
            <div class="pt-7">
              <BaseButton color="success" class="p-2" disabled>
                <Icon name="gis:location-poi-o" class="-ms-1 size-4" />
                <span>{{ work_order?.asset?.location?.name }}</span>
              </BaseButton>
            </div>
          </div>
          <div class="ml-5">
            <FormKit
              :label="t('Due date')"
              name="due"
              type="datetime-local"
              v-model="work_order.due"
            />
            <FormKit
              v-model="work_order.name"
              :label="t('Name')"
              name="name"
              type="text"
            />
          </div>
          <div class="ml-5">
            <FormKit
              :label="t('Type')"
              name="type"
              type="select"
              :options="type"
              v-model="work_order.type"
              class="ml-5"
            />
          </div>
        </div>
      </div>
      <div class="col-span-5 custom-style-wrapper">
        <div class="w-full">
          <FormKit
            v-model="work_order.description"
            :label="t('Description')"
            name="description"
            type="textarea"
            rows="4"
            class="w-full"
          />
        </div>
        <div class="w-full mt-4">
          <FormKit
            v-model="work_order.safety_notes"
            :label="t('Safety Notes')"
            name="safety_notes"
            type="textarea"
            rows="4"
            class="w-full"
          />
        </div>
      </div>
      <div class="col-span-5">
        <BaseTabs
          justify="end"
          type="box"
          model-value="tasks"
          :tabs="[
            { label: $t('Tasks'), value: 'tasks' },
            { label: $t('Schedule'), value: 'schedule' },
            { label: $t('Trades'), value: 'trades' },
            { label: $t('Parts'), value: 'parts' },
            { label: $t('Documents'), value: 'documents' },
          ]"
        >
          <template #tab="{ activeValue }">
            <p
              v-if="activeValue === 'tasks'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderitemTree
                :code="params.id"
                :key="key"
                :refresh="handleChangeKey"
              />
            </p>
            <p
              v-if="activeValue === 'schedule'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderSchedule
                :code="params.id"
                :key="key"
                :refresh="handleChangeKey"
              />
            </p>
            <p
              v-else-if="activeValue === 'trades'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderTrades />
            </p>
            <p
              v-else-if="activeValue === 'parts'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderParts />
            </p>
            <p
              v-else-if="activeValue === 'documents'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderDocuments />
            </p>
          </template>
        </BaseTabs>
        <br />
        <BaseButton color="danger" @click="handleComplete">{{
          t('Work order complete')
        }}</BaseButton>
      </div>
    </div>

    <div class="col-span-12" v-if="loading">
      <BasePlaceload class="h-4 w-full rounded" />
    </div>
  </div>
</template>

<style>
.custom-style-wrapper .max-w-md {
  max-width: none !important;
  width: 100% !important;
}
</style>
