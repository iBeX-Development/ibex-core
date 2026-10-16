<script setup lang="ts">
import { nextTick, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import PriorityCell from '~/components/custom/priorityCell.vue'
import Actions from '~/components/workorder/Actions.vue'
import Progress from '~/components/workorder/Progress.vue'
import RequestInfoItem from '~/components/workorderitem/RequestInfoItem.vue'

import { priorities } from '~/components/workorder/WorkOrderConstants'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'

const { t } = useI18n({ useScope: 'global' })

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
const { close, currentProps } = usePanels()
const { open } = usePanels()

let readonly = true
let loadTasks = false
let loadedTrades = false
let loadedParts = false
let loadDocs = false
let loadCostsPart = false
let loadCostsTrades = false
let loadActions = false

const wo_id = currentProps?.value?.id || null
const wo_data = currentProps?.value?.data || null

const wo_statuses = currentProps?.value?.wo_statuses || wo_status_items
const wo_type = currentProps?.value?.type || null
const refresh = currentProps?.value?.refresh || null
const active_tab = currentProps?.value?.active_tab || false
const open_statuses = wo_statuses.filter(
  (item) => item?.type?.toLowerCase() === 'open',
)

const panelScrollContainer = ref<HTMLElement | null>(null)
const tabItems = [
  { label: t('Tasks'), value: 'tasks' },
  { label: t('Trades'), value: 'trades' },
  { label: t('Parts'), value: 'parts' },
  { label: t('Documents'), value: 'documents' },
  { label: t('Costs'), value: 'costs' },
  { label: t('Actions'), value: 'actions' },
]
const activeTab = ref(typeof active_tab === 'string' ? active_tab : 'tasks')

if (!tabItems.some((item) => item.value === activeTab.value)) {
  activeTab.value = 'tasks'
}

const handleTabChange = (newTab: string) => {
  const previousScrollTop = panelScrollContainer.value?.scrollTop ?? 0
  activeTab.value = newTab

  nextTick(() => {
    if (panelScrollContainer.value) {
      panelScrollContainer.value.scrollTop = previousScrollTop
    }
  })
}

const progressComponent = ref(null)
const backBttn = currentProps?.value?.backBttn || false

// Counter
const daysPassed = ref(0)
const hoursPassed = ref(0)
const minutesPassed = ref(0)
const secondsPassed = ref(0)
let select_statuses = {}

// Work order file
const inputFile = ref()
const group_types = ref([])
const work_order_types = ref([])
const work_order_type = ref([])
const selected_group_type = ref({
  value: '',
  label: '',
})

const selectedStatus = ref(null)
const showSubStatus = ref(false)
const currentAvatar = computed(() => '/img/avatars/company.svg')
const due_date = ref(null)
const inputRef = ref<HTMLInputElement>()
const showMessage = ref(false)
const progress_data = ref({})
const asset_code = ref('')
const department = ref()
const description = ref()
const safety_note = ref()
const assigned_team = ref()
const actual_parts_sum = ref(0.0)
const actual_trades_sum = ref(0.0)

const statusMapping = {
  3: 'Completed',
}

const subStatusMapping = {
  5: 'Waiting approval',
  2: 'In Progress ',
}

const objectValue = ref({
  id: 1,
  name: 'Status',
  icon: 'mdi:progress-clock',
})

const PriorityValue = ref({
  value: 1,
  text: 'Low',
  media: '/img/icons/priority/low.svg',
})

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

const handleProgress_old = async () => {
  console.log('handle progress .....')
  await loadWorkOrderItems()
}
const handleProgress = async () => {
  await progressComponent?.value?.loadWorkOrderItems()
}

const loadWorkOrder = async () => {
  try {
    const filters = {
      id: wo_id,
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
          'wo_status.*',
          'type.*',
          'work_type.*',
          'department.*',
          'assigned_team.*',
          'assigned_team.id',
          'assigned_team.name',
          'template.*',
          'asset.*',
          'asset.location.*',
          'asset.department.*',
        ],
      },
    })

    // console.log('items.data.', items.data)
    // work_order.value = items.data.map((item) => ({
    //   ...item,
    //   statusName: statusMapping[item.wo_status] || 'Unknown',
    // }))[0]
    work_order.value = items.data[0]

    select_statuses = wo_statuses.find(
      (item) => item?.id === work_order.value.wo_status.id,
    )

    // console.log('select_statuses', select_statuses)
    // selectedStatus.value = work_order.value.wo_status
    objectValue.value = {
      id: items.data[0].wo_status.id,
      name: items.data[0].wo_status.status_text,
      icon: items.data[0].wo_status.icon,
    }

    if (items.data[0].due) {
      due_date.value = formatDateToMMDDYYYY(new Date(items.data[0].due))
    }

    if (work_order.value.priority) {
      let priorityItem = priorities.find(
        (p) =>
          p.value == work_order.value.priority ||
          p.__original == work_order.value.priority,
      )

      PriorityValue.value = {
        id: priorityItem.value,
        text: priorityItem.text,
        media: priorityItem.media,
      }
    }

    // work type
    if (work_order.value.work_type) {
      work_order_type.value = {
        label: work_order.value.work_type.code,
        value: work_order.value.work_type.id,
      }
    }

    // Group type
    if (work_order.value.type) {
      selected_group_type.value = {
        label: work_order.value.type.name,
        value: work_order.value.type.id,
      }
    }

    asset_code.value = items.data[0].asset?.asset_code
    department.value = items.data[0].asset?.department?.name
    assigned_team.value = items.data[0].assigned_team?.name

    // loading.value = false;
  } catch (e) {
    console.log(e)
  }
  // console.log(teams.value)
}

const transformType = (items, codeField) => {
  console.log('transformType_items', items)
  const transformed_types = items.map((item) => ({
    label: codeField == 'code' ? item.code : item.name,
    value: item.id,
  }))
  console.log('transformed_types', transformed_types)

  return transformed_types
}

const loadGroupTypes = async () => {
  try {
    const filters = {
      status: 'published',
    }
    const items = await getItems<any>({
      collection: 'Work_types',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    console.log('loadGroupTypes_items', items)
    work_order_types.value = transformType(items.data, 'code')
  } catch (e) {
    console.log(e)
  }
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
    console.log('loadTypes_items', items)
    group_types.value = transformType(items.data, 'name')
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
      workorder: wo_id,
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

const loadParts = async () => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: wo_id,
    }
    const items = await getItems({
      collection: 'Work_order_Parts',
      params: {
        filter: filters,
        aggregate: {
          sum: 'amount,actual_amount',
        },
      },
    })
    // console.log('LoadParts : ', items)
    actual_parts_sum.value = items[0].sum.actual_amount
    loading.value = false
  } catch (e) {
    console.log(e)
  }
}

const loadTrades = async () => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: wo_id,
    }
    const items = await getItems({
      collection: 'Work_order_Tradecode',
      params: {
        filter: filters,
        aggregate: {
          sum: 'total,duration,actual_total,actual_duration',
        },
      },
    })
    console.log(items)
    actual_trades_sum.value = items[0].sum.actual_total
    loading.value = false
  } catch (e) {
    console.log(e)
  }
}

const handleClose = async () => {
  await loadParts()
  await loadTrades()
  // console.log('Actuals : ', actual_parts_sum.value, actual_trades_sum.value)
  if (actual_parts_sum.value > 0 && actual_trades_sum > 0) {
    const updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: {
        status: 5,
      },
    }
    work_order.value.wo_status = 5
    work_order.value = work_order
    updateItem(updateData).then((res) => {
      toaster.show({
        title: t('Close work orders success'),
        message: t(`Record close successfull`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
    })
  } else {
    toaster.show({
      title: t('Need action to close'),
      message:
        t(`Close work order need to add actual parts, actual trades`) + '!',
      color: 'danger',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }
}

onMounted(async () => {
  loading.value = true

  await loadWorkOrder()
  await loadTypes()
  await loadWorkOrderItems()
  await loadGroupTypes()

  loading.value = false
  setInterval(updateDates, 1000) // Update every second
})

const updateDates = () => {
  if (work_order.value?.wo_status === 3) {
    // If the work order is completed, stop updating the time
    clearInterval(timeout.value)
    return
  }

  const now = new Date()
  if (work_order.value && work_order.value.started_at) {
    const start = new Date(work_order.value.started_at)
    const done = new Date(work_order.value.completed_at)
    const diffTime = Math.abs(start - done)
    //console.log(start)
    //console.log(now)

    // Calculate days, hours, minutes, and seconds
    daysPassed.value = Math.floor(diffTime / (1000 * 60 * 60 * 24))
    hoursPassed.value = Math.floor((diffTime / (1000 * 60 * 60)) % 24)
    minutesPassed.value = Math.floor((diffTime / (1000 * 60)) % 60)
    secondsPassed.value = Math.floor((diffTime / 1000) % 60)
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
  // console.log('H', value)

  if (event.target.name == 'priority') {
    const priority = parseInt(event.target.value.replace(/\D/g, ''), 10)
    items = { ...items, priority }
  }

  if (event.target.name == 'work_type') {
    const work_type = parseInt(event.target.value.replace(/\D/g, ''), 10)
    items = { ...items, work_type }
  }

  if (event.target.type == 'datetime-local') {
    let keyName
    if (event.target.name == 'due') keyName = 'due'
    else if (event.target.name == 'started_at') keyName = 'started_at'
    else if (event.target.name == 'created_at') keyName = 'created_at'
    else if (event.target.name == 'completed_at') keyName = 'completed_at'

    items = { ...items, [keyName]: event.target.value }
  }

  if (event.target.type == 'textarea') {
    items = { history_description: event.target.value }
  }

  // const updateData = {
  //   collection: 'Work_order',
  //   id: wo_id,
  //   item: items,
  // }

  // updateItem(updateData).then((res) => {
  //   showMessage.value = true
  //   console.log('Update:', updateData)

  //   setTimeout(() => {
  //     showMessage.value = false
  //   }, 1000)
  // })
}

function onClick(item, type) {
  // return
  let updateData = {}
  if (type == 'priority') {
    updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: { priority: item.value },
    }
  } else if (type == 'wo_status') {
    updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: { wo_status: item.id },
    }
  } else if (type == 'type') {
    updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: { type: item.value },
    }
  } else if (type == 'work_type') {
    updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: { work_type: item.value },
    }
  }

  console.log('updateData', type, updateData)
  updateItem(updateData).then((res) => {
    console.log('done')

    if (refresh != null) refresh()
  })
}

const handleTasksUpdate = (newTasks) => {
  // console.log('done:)', newTasks)
  loadTasks = newTasks
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

const backToAsset = (workorder) => {
  // console.log('hihi', workorder)
  open('asset', {
    id: workorder.asset.id,
    data: workorder.asset,
    p_type: 'pm',
    active_tab: active_tab,
    w_type: 'wo',
  })
}
</script>

<template>
  <div
    ref="panelScrollContainer"
    class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 border bg-white w-[80%] overflow-y-scroll"
  >
    <div class="flex h-16 w-full items-center justify-start px-10 more">
      <button
        type="button"
        class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300 dark:hover:text-white"
        @click="close"
      >
        <Icon name="line-md:close" class="h-5 w-5" />
      </button>
      <button
        v-if="backBttn == true"
        type="button"
        class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300 dark:hover:text-white"
        @click="() => backToAsset(work_order)"
      >
        <Icon name="feather:chevron-right" class="h-6 w-6" />
      </button>

      <div class="max-w-4xl taskNumber">
        <div
          class="flex flex-start font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white m-[10px]"
        >
          Completed Work Order #{{ work_order.id }}
          <!-- <p :style="{ color: 'red' }">#{{ item_id }}</p> -->
        </div>
      </div>
    </div>
    <div class="relative work_order_more">
      <!-- First Row -->
      <div class="grid grid-cols-5 gap-4 wo_more px-8 py-2">
        <!-- Left: Action status badge + WO Name -->
        <div class="col-span-3 flex items-end gap-3">
          <!-- Action status badge -->
          <div
            class="shrink-0 flex items-center capitalize"
            style="min-width: 120px; height: 42px"
          >
            <PriorityCell
              fieldName="action_status"
              :value="wo_data.action_status"
            />
          </div>
          <!-- WO Name -->
          <div class="flex-1 min-w-0">
            <FormKit
              :label="t('WO Name')"
              name="wo_name"
              type="text"
              @change="onChange"
              v-model="work_order.name"
              :disabled="wo_data.action_status == 2 ? true : false"
              :classes="{
                input: 'wo_input wo_name',
                outer: 'wo_wrapper woname_wrapper',
                label: 'woname_label',
              }"
            />
          </div>
        </div>

        <!-- Right: Group Type + Status (aligned above timer) -->
        <div class="col-span-2 flex items-end gap-3">
          <!-- Group Type -->
          <div class="flex-1">
            <BaseListbox
              :label="t('Group Type')"
              :items="group_types"
              :model-value="selected_group_type"
              :properties="{
                value: 'value',
                label: 'label',
              }"
              :disabled="wo_data.action_status == 2 ? true : false"
              size="md"
              rounded="md"
              @update:model-value="onClick($event, 'type')"
            />
          </div>
          <!-- Status -->
          <div class="flex-1">
            <BaseListbox
              :label="t('Status')"
              :items="open_statuses"
              :properties="{
                value: 'id',
                label: 'name',
                icon: 'icon',
              }"
              :model-value="objectValue"
              size="md"
              rounded="md"
              @update:model-value="onClick($event, 'wo_status')"
              :disabled="readonly"
            />
          </div>
        </div>
      </div>
      <div class="grid grid-cols-5 gap-3 wo_more px-8" v-if="!loading">
        <!-- Inputs -->
        <div class="col-span-3">
          <div class="grid grid-cols-3 gap-x-5 gap-y-3 items-start">
            <!-- Row 1: Asset | Priority | Started date -->
            <div class="flex flex-col gap-1 bttns_action">
              <span class="wo_label">Asset</span>
              <BaseButton
                color="primary"
                class="btn-standard w-full overflow-hidden whitespace-nowrap"
                @click="handleAssetClick('asset')"
                :disabled="wo_data.action_status == 2 ? true : false"
              >
                <Icon name="ph:bank-duotone" class="-ms-1 size-4 shrink-0" />
                <span class="truncate">{{ asset_code }}</span>
              </BaseButton>
            </div>
            <div
              class="flex flex-col gap-1 priority_action"
              style="margin-top: 4px"
            >
              <BaseListbox
                :label="t('Priority')"
                :items="priorities"
                :disabled="readonly"
                :properties="{
                  value: 'value',
                  label: 'text',
                  media: 'media',
                }"
                :model-value="PriorityValue"
                size="md"
                rounded="md"
                @update:model-value="onClick($event, 'priority')"
              />
            </div>
            <div class="flex flex-col gap-1 date_action">
              <FormKit
                :label="t('Started date')"
                name="started_at"
                type="datetime-local"
                @change="onChange"
                :disabled="wo_data.action_status == 2 ? true : false"
                v-model="work_order.started_at"
                :classes="{
                  input: 'wo_input',
                  outer: 'wo_wrapper',
                  label: 'wo_label',
                }"
              />
            </div>

            <!-- Row 2: Location | Type | Due date -->
            <div class="flex flex-col gap-1 bttns_action">
              <span class="wo_label">{{ t('Location') }}</span>
              <BaseButton
                color="success"
                class="btn-standard w-full overflow-hidden whitespace-nowrap"
                disabled
              >
                <Icon name="gis:location-poi-o" class="-ms-1 size-4 shrink-0" />
                <span class="truncate">{{
                  work_order?.asset?.location?.name ||
                  work_order?.location?.name
                }}</span>
              </BaseButton>
            </div>
            <div class="flex flex-col gap-1">
              <BaseListbox
                :label="t('Type')"
                :items="work_order_types"
                :disabled="readonly"
                :properties="{
                  value: 'value',
                  label: 'label',
                }"
                :model-value="work_order_type"
                size="md"
                rounded="md"
                @update:model-value="onClick($event, 'work_type')"
                style="margin-top: 4px"
              />
            </div>
            <div class="flex flex-col gap-1 date_action">
              <FormKit
                label="Due date:"
                name="due"
                type="datetime-local"
                v-model="work_order.due"
                :disabled="wo_data.action_status == 2 ? true : false"
                @change="onChange"
                :classes="{
                  input: 'wo_input',
                  outer: 'wo_wrapper',
                  label: 'wo_label',
                }"
              />
            </div>

            <!-- Row 3: Team | Department | Completed date -->
            <div class="flex flex-col gap-1 bttns_action">
              <span class="wo_label">Team</span>
              <BaseButton
                color="success"
                class="btn-standard w-full overflow-hidden whitespace-nowrap"
                @click="handleAssetClick('team')"
                :disabled="wo_data.action_status == 2 ? true : false"
              >
                <Icon name="ri:team-fill" class="-ms-1 size-4 shrink-0" />
                <span class="truncate">{{ assigned_team }}</span>
              </BaseButton>
            </div>
            <div class="flex flex-col gap-1">
              <FormKit
                :label="t('Department')"
                name="department"
                collection_name="Department"
                type="autocomplete2"
                item_value="id"
                item_title="description"
                :disabled="readonly"
                :options="department"
                option_class="department"
                v-model="department"
                :setValue="setValue"
                :classes="{
                  input: 'wo_input',
                  outer: 'wo_wrapper',
                  label: 'wo_label',
                }"
              />
            </div>
            <div class="flex flex-col gap-1 date_action">
              <FormKit
                :label="t('Completed date')"
                name="completed_at"
                type="datetime-local"
                @change="onChange"
                v-model="work_order.completed_at"
                :disabled="wo_data.wo_status.id === 5 ? true : false"
                :classes="{
                  input: 'wo_input',
                  outer: 'wo_wrapper',
                  label: 'wo_label',
                }"
              />
            </div>
          </div>
        </div>

        <!-- timer -->
        <div
          class="col-span-2"
          style="margin-top: 24px; max-width: 460px; min-width: 370px"
        >
          <div class="flex flex-col gap-3">
            <!-- Elapsed time badges -->
            <div
              class="rounded-lg border border-red-300 bg-red-50 dark:bg-red-950 dark:border-red-700 px-3 py-2"
            >
              <p
                class="text-[10px] font-medium text-red-400 dark:text-red-400 uppercase tracking-wide mb-1.5"
              >
                {{ t('Elapsed time') }}
              </p>
              <div class="grid grid-cols-4 gap-1">
                <div
                  class="flex flex-col items-center bg-red-600 rounded-md px-1 py-1.5"
                >
                  <span class="text-base font-bold text-white leading-none">{{
                    daysPassed
                  }}</span>
                  <span class="text-[9px] text-red-200 mt-0.5">{{
                    t('days')
                  }}</span>
                </div>
                <div
                  class="flex flex-col items-center bg-red-600 rounded-md px-1 py-1.5"
                >
                  <span class="text-base font-bold text-white leading-none">{{
                    hoursPassed
                  }}</span>
                  <span class="text-[9px] text-red-200 mt-0.5">{{
                    t('hrs')
                  }}</span>
                </div>
                <div
                  class="flex flex-col items-center bg-red-600 rounded-md px-1 py-1.5"
                >
                  <span class="text-base font-bold text-white leading-none">{{
                    minutesPassed
                  }}</span>
                  <span class="text-[9px] text-red-200 mt-0.5">{{
                    t('min')
                  }}</span>
                </div>
                <div
                  class="flex flex-col items-center bg-red-600 rounded-md px-1 py-1.5"
                >
                  <span class="text-base font-bold text-white leading-none">{{
                    secondsPassed
                  }}</span>
                  <span class="text-[9px] text-red-200 mt-0.5">{{
                    t('sec')
                  }}</span>
                </div>
              </div>
            </div>
            <Progress ref="progressComponent" :wo_id="wo_id" />
          </div>
        </div>

        <!--  requestInfo -->
        <div class="col-span-5 custom-style-wrapper">
          <div class="w-full">
            <RequestInfoItem
              v-if="RequestInfo == true"
              :request_work="RequestWork"
              collection="Work_order_item"
            />
          </div>
        </div>

        <!--  Description -->
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
              disabled
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
              disabled
            />
          </div>
        </div>

        <!-- Tabs -->
        <div class="col-span-5">
          <BaseTabs
            justify="end"
            type="box"
            :model-value="activeTab"
            class="tabs"
            :tabs="tabItems"
            @update:model-value="handleTabChange"
          >
            <template #tab="{ activeValue }">
              <p
                v-if="activeValue === 'tasks'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderitemTree
                  :loadTasks="loadTasks"
                  @update:loadTasks="handleTasksUpdate"
                  :code="work_order.id"
                  :key="key"
                  :refresh="handleChangeKey"
                  :progress="handleProgress"
                  :freeze="true"
                />
              </p>

              <p
                v-else-if="activeValue === 'trades'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderTrades
                  :estimated_edit="false"
                  :actual_edit="false"
                  :work_order="work_order"
                  :freeze="true"
                />
              </p>

              <p
                v-else-if="activeValue === 'parts'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderParts
                  :estimated_edit="false"
                  :actual_edit="false"
                  :work_order="work_order"
                  :freeze="true"
                />
              </p>
              <p
                v-else-if="activeValue === 'documents'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderDocuments :work_order="work_order" :freeze="true" />
              </p>
              <p
                v-else-if="activeValue === 'costs'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderCosts
                  :estimated_edit="true"
                  :actual_edit="true"
                  :work_order="work_order"
                  :freeze="true"
                />
              </p>
              <p
                v-else-if="activeValue === 'actions'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <Actions :delete="true" :work_order="work_order" />
              </p>
            </template>
          </BaseTabs>

          <br />

          <div class="mt-[20px] mb-[80px]">
            <BaseButton
              color="primary"
              class="ml-5"
              @click="
                open('print', {
                  wo_id: wo_id,
                  work_order: work_order,
                  progress_data: progress_data,
                  wo_statuses: wo_statuses,
                  wo_type: wo_type,
                  refresh: refresh,
                })
              "
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
  </div>
</template>

<style>
.work_order_more .nui-listbox .nui-listbox-option {
  padding: 0px !important;
}
.work_order_more .wo_input {
  height: 40px !important;
}
.work_order_more .woname_wrapper {
  max-width: 95% !important;
}
.custom-style-wrapper .max-w-md {
  max-width: none !important;
  width: 100% !important;
}

.btn-standard {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 150px; /* Adjust to the desired width */
  height: 40px; /* Adjust to match both buttons */
  padding: 0 16px; /* Consistent padding */
  font-size: 14px; /* Consistent font size */
  text-align: center;
  border-radius: 8px; /* Optional: for rounded corners */
  white-space: nowrap; /* Prevent text wrapping */
}

.button-wrapper {
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>
