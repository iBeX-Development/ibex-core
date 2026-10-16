<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { priorities } from '~/components/workorder/WorkOrderConstants'

const { t } = useI18n({ useScope: 'global' })
const { open } = usePanels()

definePageMeta({
  middleware: ['auth'],
  title: 'Work order',
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
const selectedStatus = ref(null)
const showSubStatus = ref(false)
const currentAvatar = computed(() => '/img/avatars/company.svg')
const due_date = ref(null)
const inputRef = ref<HTMLInputElement>()
const showMessage = ref(false)
const progress_data = ref({})
const asset_code = ref('')
const department = ref()
const assigned_team = ref()
let param_id = 0
//print
const pathWithoutId = router.currentRoute.value.path.replace(/\/\d+$/, '')
const printPath = `${pathWithoutId}/print`

const statusMapping = {
  1: 'Open',
  2: 'In Progress',
}

const subStatusMapping = {
  5: 'Waiting approval',
  2: 'In Progress ',
}

const getIconForStatus = (statusId) => {
  const icons = {
    1: 'gis:map-unlock',
    2: 'entypo:progress-two',
    3: 'icon-park-outline:full-selection',
    5: 'mdi:approval',
  }
  return icons[statusId] || 'healthicons:default'
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleProgress = async () => {
  console.log('handle progress .....')
  await loadWorkOrderItems()
}

const loadWorkOrder = async () => {
  try {
    param_id = params.id
    const filters = {
      id: params.id,
    }
    const items = await getItems<any>({
      collection: 'Work_order',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: [
          '*',
          'status.id',
          'status.name',
          'priority.*',
          'type.name',
          'asset.*',
          'template.*',
          'assigned_to.*',
          'assigned_to.role.name',
          'asset.location.*',
          'asset.department.*',
        ],
      },
    })

    work_order.value = items.data.map((item) => ({
      ...item,
      statusName: statusMapping[item.status] || 'Unknown',
    }))[0]

    selectedStatus.value = work_order.value.status

    if (items.data[0].due) {
      due_date.value = formatDateToMMDDYYYY(new Date(items.data[0].due))
      asset_code.value = items.data[0].asset?.asset_code
      department.value = items.data[0].asset?.department?.name
      assigned_team.value = items.data[0].assigned_team?.name
    }
    console.log('item', items)
    // loading.value = false;
  } catch (e) {
    console.log(e)
  }
  console.log(teams.value)
}

const transformType = (items) => {
  console.log(items)
  const transformed_types = items.map((item) => ({
    label: item.name,
    value: item.id,
  }))
  transformed_types.unshift({
    label: '',
    value: '',
  })
  return transformed_types
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
    type.value = transformType(items.data)
    loading.value = false
  } catch (e) {
    console.log(e)
  }
}

const loadWorkOrderItems = async () => {
  loading.value = true
  try {
    const filters = {
      active: 1,
      workorder: params.id,
    }
    progress_data.value = await getItems<any>({
      collection: 'Work_order_item',
      params: {
        filter: filters,
        aggregate: {
          count: '*',
        },
        groupBy: 'template_type, value',
        meta: 'filter_count',
      },
    })
    loading.value = false
  } catch (e) {
    console.log(e)
  }
}

const handleComplete = async () => {
  const updateData = {
    collection: 'Work_order',
    id: params.id,
    item: {
      status: '3', //wo_status?
      completed_at: new Date().toISOString(),
    },
  }
  updateItem(updateData).then((res) => {
    console.log('Update', work_order)
    router.push(
      `/workorder/location/completed/${work_order?.value?.asset?.location?.id}/view/${work_order?.value?.id}`,
    )

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
  await loadWorkOrderItems()

  // if (work_order.value?.id) {
  //   document.title = `Work order #${work_order.value.id}`;
  // }

  loading.value = false
  if (work_order.value.started_at && work_order.value.due) {
    setInterval(updateDates, 1000) // Update every second
  }
  if (work_order.value.wo_status == 3) {
    router.push(
      `/workorder/location/completed/${work_order?.value?.asset?.location?.id}/view/${work_order?.value?.id}`,
    )
  }
})

const updateDates = () => {
  const now = new Date()
  if (work_order.value && work_order.value.started_at) {
    const start = new Date(work_order.value.started_at)
    const due = new Date(work_order.value.due)

    if (due < start) {
      daysPassed.value = 0
      hoursPassed.value = 0
      minutesPassed.value = 0
      secondsPassed.value = 0
      return
    }

    if (now < start) {
      daysPassed.value = 0
      hoursPassed.value = 0
      minutesPassed.value = 0
      secondsPassed.value = 0
      return
    }
    const diffTime = Math.abs(due - now, 0)
    daysPassed.value = Math.floor(diffTime / (1000 * 60 * 60 * 24))
    hoursPassed.value = Math.floor((diffTime / (1000 * 60 * 60)) % 24)
    minutesPassed.value = Math.floor((diffTime / (1000 * 60)) % 60)
    secondsPassed.value = Math.floor((diffTime / 1000) % 60)
  } else {
    daysPassed.value = 0
    hoursPassed.value = 0
    minutesPassed.value = 0
    secondsPassed.value = 0
  }
}

const formatDateToMMDDYYYY = (date) => {
  const mm = String(date.getMonth() + 1).padStart(2, '0') // Months are zero-based
  const dd = String(date.getDate()).padStart(2, '0')
  const yyyy = date.getFullYear()

  return mm + '/' + dd + '/' + yyyy
}

function onChange(event: Event) {
  const value = (event.target as HTMLInputElement).value
  let items = {}

  if (event.target.name == 'priority') {
    const priority = parseInt(event.target.value.replace(/\D/g, ''), 10)
    items = { ...items, priority }
  }

  if (event.target.name == 'type') {
    const type = parseInt(event.target.value.replace(/\D/g, ''), 10)
    items = { ...items, type }
  }

  if (event.target.type == 'datetime-local') {
    let keyName
    if (event.target.name == 'due') keyName = 'due'
    else if (event.target.name == 'started_at') keyName = 'started_at'
    else if (event.target.name == 'created_at') keyName = 'created_at'
    else if (event.target.name == 'completed_at') keyName = 'completed_at'

    items = { ...items, [keyName]: event.target.value || null }
  }

  if (event.target.name === 'wo_name') {
    items = { ...items, name: value }
  }

  if (event.target.name === 'description') {
    items = { ...items, history_description: value }
  }

  if (event.target.name === 'safety_notes') {
    items = { ...items, safety_notes: value }
  }

  if (event.target.name === 'department') {
    items = { ...items, department: value }
  }

  const updateData = {
    collection: 'Work_order',
    id: params.id,
    item: items,
  }

  updateItem(updateData).then((res) => {
    showMessage.value = true
    console.log('Update Data:', updateData)

    setTimeout(() => {
      showMessage.value = false
    }, 1000)
  })
}

function onClick(itemId: Value) {
  let items = {}

  // if (itemId == 2) {
  //   console.log('subMask')
  //   showSubStatus.value = true
  // }

  if (itemId) {
    const status = parseInt(itemId.replace(/\D/g, ''), 10)
    items = { ...items, status }
  }

  const updateData = {
    collection: 'Work_order',
    id: params.id,
    item: items,
  }

  updateItem(updateData).then((res) => {
    showMessage.value = true
    selectedStatus.value = res.status

    setTimeout(() => {
      showMessage.value = false
    }, 1000)
  })
}

const progress_value = computed(() => {
  if (progress_data?.value && progress_data?.value.data) {
    const max_value = progress_data?.value.meta.filter_count
    let completed_value = 0
    try {
      // 1. Get the sum for template_type = 5 and value = "1"
      const sumTemplateType5Value1 = progress_data?.value.data
        .filter((item) => item.template_type === 5 && item.value === '1')
        .reduce((sum, item) => sum + parseInt(item.count), 0)

      console.log(
        'Sum for template_type = 5, value = 1:',
        sumTemplateType5Value1,
      )

      // 2. Get the sum for template_type = 7 where value is not null or empty
      const sumTemplateType7NotNull = progress_data?.value.data
        .filter(
          (item) =>
            item.template_type === 7 &&
            item.value !== null &&
            item.value !== '',
        )
        .reduce((sum, item) => sum + parseInt(item.count), 0)
      console.log('Sum for template_type = 7, value:', sumTemplateType7NotNull)
      completed_value = sumTemplateType7NotNull + sumTemplateType5Value1
    } catch (error) {
      console.log(error)
    }

    return (completed_value / max_value) * 100
  } else {
    return 0
  }
})
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="max-w-24 space-y-4">
      <BaseMessage v-if="showMessage" shape="straight">Saved</BaseMessage>
    </div>

    <div class="grid grid-cols-1 items-center">
      <div
        class="grid grid-cols-4"
        style="grid-template-columns: 0.65fr 2fr 0.83fr 0.9fr"
      >
        <BaseHeading
          as="h3"
          size="2xl"
          weight="bold"
          class="text-muted-800 dark:text-white mt-3"
        >
          Work Order #{{ work_order.id }}
        </BaseHeading>
        <FormKit
          :label="t('WO Name')"
          name="wo_name"
          type="textarea"
          @change="onChange"
          rows="2"
          v-model="work_order.name"
          class="text-center custom-style-wrapper"
        />
        <FormKit
          :label="t('Group Number')"
          name="group number"
          type="text"
          @change="onChange"
          v-model="work_order.group_number"
        />
        <div class="button-wrapper mt-3">
          <BaseButton
            v-for="(statusName, statusId) in statusMapping"
            :key="statusId"
            :color="selectedStatus === parseInt(statusId) ? 'success' : 'light'"
            class="p-2 ml-3"
            @click="onClick(statusId)"
          >
            <Icon :name="getIconForStatus(statusId + 1)" class="-ms-1 size-4" />
            <div style="white-space: nowrap">{{ statusName }}</div>
          </BaseButton>
        </div>
      </div>
    </div>
    <div class="grid grid-cols-5 gap-3" v-if="!loading">
      <!-- Header -->
      <div class="col-span-3">
        <div
          class="grid grid-cols-3"
          style="grid-template-columns: 1fr 1fr 1fr"
        >
          <div class="col-span-1">
            <div class="pt-8">
              <BaseButton
                color="primary"
                class="btn-standard w-[234px] overflow-hidden text-ellipsis whitespace-nowrap"
              >
                <Icon name="ph:bank-duotone" class="-ms-1 size-4" />
                <span>{{ asset_code }} </span>
              </BaseButton>
              <br />
            </div>
            <div class="pt-9">
              <BaseButton
                color="success"
                class="btn-standard w-[234px] overflow-hidden text-ellipsis whitespace-nowrap"
                disabled
              >
                <Icon name="gis:location-poi-o" class="-ms-1 size-4" />
                <span>{{ work_order?.asset?.location?.name }}</span>
              </BaseButton>
              <br />
            </div>
            <div class="pt-9">
              <BaseButton
                color="success"
                class="btn-standard w-[234px] overflow-hidden text-ellipsis whitespace-nowrap"
                disabled
              >
                <Icon name="ri:team-fill" class="-ms-1 size-4" />
                <span>{{ assigned_team }}</span>
              </BaseButton>
              <br />
            </div>
          </div>
          <div>
            <FormKit
              :label="t('Priority')"
              name="priority"
              type="select"
              :options="priorities"
              @change="onChange"
              v-model="work_order.priority"
            />
            <FormKit
              :label="t('Type')"
              name="type"
              type="select"
              :options="type"
              v-model="work_order.type"
              @change="onChange"
              class="ml-5"
            />
            <FormKit
              :label="t('Department')"
              name="department"
              collection_name="Department"
              type="autocomplete2"
              item_value="id"
              item_title="description"
              :options="department"
              v-model="department"
              @change="onChange"
            />
          </div>
          <div class="ml-5 mr-3">
            <FormKit
              :label="t('Started date')"
              name="started_at"
              type="datetime-local"
              @change="onChange"
              v-model="work_order.started_at"
            />
            <FormKit
              :label="t('Due date')"
              name="due"
              type="datetime-local"
              v-model="work_order.due"
              @change="onChange"
            />
            <FormKit
              :label="t('Completed date')"
              name="completed_at"
              type="datetime-local"
              @change="onChange"
              v-model="work_order.completed_at"
              disabled
            />
          </div>
        </div>
      </div>

      <div class="mt-5 col-span-2">
        <div class="grid gap-5 sm:col-span-3 content-center mt-2">
          <!-- Item -->
          <BaseCard class="!bg-red-600 !dark:bg-red-600 !border-red-600 p-3">
            <div class="flex w-full items-center gap-3">
              <span class="block font-sans text-2xl font-semibold text-white">
                {{ daysPassed }} days, {{ hoursPassed }} hours,
                {{ minutesPassed }} minutes , <br />{{ secondsPassed }} seconds
              </span>
            </div>
          </BaseCard>
          <BaseCard shape="rounded" class="p-2 md:p-4" v-if="!loading">
            <div class="flex w-full">
              <BaseHeading
                as="h4"
                size="lg"
                weight="semibold"
                class="text-muted-800 dark:text-white"
              >
                {{ t('Task progress') }} {{ progress_value.toFixed(2) }}%
              </BaseHeading>
            </div>
            <div class="flex w-full mb-5 mt-3">
              <BaseProgress
                :title="t('Task progress')"
                size="xs"
                :value="progress_value"
                color="success"
              />
            </div>
          </BaseCard>
        </div>
      </div>

      <div class="col-span-5 custom-style-wrapper">
        <div class="w-full">
          <FormKit
            v-model="work_order.history_description"
            :label="t('Description')"
            name="description"
            type="textarea"
            @change="onChange"
            rows="3"
            class="w-full"
          />
        </div>
        <div class="w-full">
          <FormKit
            v-model="work_order.safety_notes"
            :label="t('Safety Notes')"
            name="safety_note"
            type="textarea"
            @change="onChange"
            rows="2"
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
            { label: $t('Trades'), value: 'trades' },
            { label: $t('Parts'), value: 'parts' },
            { label: $t('Documents'), value: 'documents' },
            { label: $t('Costs'), value: 'costs' },
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
                :progress="handleProgress"
                :freeze="false"
              />
            </p>

            <p
              v-else-if="activeValue === 'trades'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderTrades :estimated_edit="true" :work_order="work_order" />
            </p>

            <p
              v-else-if="activeValue === 'parts'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderParts :estimated_edit="true" />
            </p>
            <p
              v-else-if="activeValue === 'documents'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderDocuments />
            </p>
            <p
              v-else-if="activeValue === 'costs'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderCosts :estimated_edit="true" :work_order="work_order" />
            </p>
          </template>
        </BaseTabs>

        <br />

        <div>
          <BaseButton color="danger" @click="handleComplete">{{
            t('Work order complete')
          }}</BaseButton>
          <BaseButton
            color="primary"
            class="ml-5"
            @click="open('print', { work_order, progress_data, param_id })"
          >
            {{ t('Print') }}</BaseButton
          >
        </div>
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

.button-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
}

.btn-standard {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 150px;
  height: 40px;
  padding: 0 16px;
  font-size: 14px;
  text-align: center;
  border-radius: 8px;
  white-space: nowrap;
}
</style>
