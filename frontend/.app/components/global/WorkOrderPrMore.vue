<script setup lang="ts">
import { nextTick, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import PriorityCell from '~/components/custom/priorityCell.vue'
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import ModalItemsList from '~/components/form/ModalItemsList.vue'
import Actions from '~/components/pr/Actions.vue'
import ConditionTab from '~/components/pr/ConditionTab.vue'
import ModalAssetsList from '~/components/workorder/ModalAssetsList.vue'
import Progress from '~/components/workorder/Progress.vue'
import WorkorderitemDynamicTree from '~/components/workorderitem/DynamicTree.vue'

import { priorities } from '~/components/workorder/WorkOrderConstants'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'

const { t } = useI18n({ useScope: 'global' })
const { open } = usePanels()
const myId = window.localStorage.getItem('myId')

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

const { close, currentProps } = usePanels()

const dateValue = ref('')

const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const isModalApproveConfirmOpen = ref(false)

const wo_id = currentProps?.value?.id || null
const wo_location = currentProps?.value?.location || null
const wo_data = currentProps?.value?.data || null
const wo_statuses = currentProps?.value?.wo_statuses || wo_status_items
const wo_type = currentProps?.value?.type || null
const refresh = currentProps?.value?.refresh || null
const chooseTab = currentProps?.value?.tab || null
const backBttn = currentProps?.value?.backBttn || false
const active_tab = currentProps?.value?.active_tab || false
const backFn = currentProps?.value?.backFn || false
const asset_data = currentProps?.value?.asset_data || null

// ── Жагсаалт дотор Next/Prev шилжих ────────────────────────────────────────
const navList = computed<any[]>(() => currentProps?.value?.list || [])
const navCurrentIndex = computed(() =>
  navList.value.findIndex((item: any) => String(item?.id) === String(wo_id)),
)
const hasNextItem = computed(
  () =>
    navCurrentIndex.value >= 0 &&
    navCurrentIndex.value < navList.value.length - 1,
)
const hasPrevItem = computed(() => navCurrentIndex.value > 0)

const navigateToListItem = (item: any) => {
  if (!item) return
  open('workorderprmore', {
    ...(currentProps?.value || {}),
    id: item.id,
    data: item,
    active_tab: activeTab.value,
    list: navList.value,
  })
}

const goToNextItem = () => {
  if (!hasNextItem.value) return
  navigateToListItem(navList.value[navCurrentIndex.value + 1])
}

const goToPrevItem = () => {
  if (!hasPrevItem.value) return
  navigateToListItem(navList.value[navCurrentIndex.value - 1])
}

const translatedWoStatuses = computed(() =>
  (Array.isArray(wo_statuses) ? wo_statuses : []).map((status) => ({
    ...status,
    name: t(status.status_text || status.name),
    icon: t(status.icon || 'fluent:approvals-app-28-regular'),
  })),
)
const open_statuses = computed(() =>
  translatedWoStatuses.value.filter(
    (item) => item?.type?.toLowerCase() === t('open'),
  ),
)

const showBttn = ref(false)
let readonly = false
let loadTasks = false
let loadTrades = false
let loadedParts = false
let loadDocs = false
let loadCostsPart = false
let loadCostsTrades = false
let loadActions = false

const router = useRouter()
const { params } = useRoute()
const teams = ref([])
const conditions = ref([])
const work_order = ref({})
const { getItems, createItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const { getUsers } = useDirectusUsers()
const loading = ref(true)
const key = ref(1)
const timeout = ref(null)
const toaster = useToaster()
const progressComponent = ref(null)
const transformedPos = ref([])
const ProgressValue = ref(0)

// Counter
const daysPassed = ref(0)
const hoursPassed = ref(0)
const minutesPassed = ref(0)
const secondsPassed = ref(0)

// Work order file
const inputFile = ref()
const group_types = ref([])
const work_order_types = ref([])

const work_order_type = ref([])
const temp_types = ref([])
// const selectedStatus = ref(null)
const showSubStatus = ref(false)
const currentAvatar = computed(() => '/img/avatars/company.svg')
const due_date = ref(null)
const inputRef = ref<HTMLInputElement>()
const progress_data = ref({})
const asset_code = ref('')
const department = ref()
const assigned_team = ref()
const selected_group_type = ref({
  value: '',
  label: '',
})
const isModalAssetOpen = ref(false)
const isModalTeamsOpen = ref(false)
let param_id = 0

//print
const pathWithoutId = router.currentRoute.value.path.replace(/\/\d+$/, '')
const printPath = `${pathWithoutId}/print`
const panelScrollContainer = ref<HTMLElement | null>(null)
const activeTab = ref(chooseTab || 'tasks')
let tabs = [
  { label: t('Tasks'), value: 'tasks' },
  { label: t('Condition'), value: 'condition' },
  { label: t('Trades'), value: 'trades' },
  { label: t('Parts'), value: 'parts' },
  { label: t('Documents'), value: 'documents' },
  { label: t('Costs'), value: 'costs' },
  { label: t('Actions'), value: 'actions' },
]
let generated_tabs = [
  { label: t('Tasks'), value: 'tasks' },
  { label: t('Trades'), value: 'trades' },
  { label: t('Parts'), value: 'parts' },
  { label: t('Documents'), value: 'documents' },
  { label: t('Costs'), value: 'costs' },
  { label: t('Actions'), value: 'actions' },
]

if (wo_type == 'request') {
  activeTab.value = 'actions'
  tabs = [{ label: t('Actions'), value: 'actions' }]
}

const isKnownTab = [...tabs, ...generated_tabs].some(
  (item) => item.value === activeTab.value,
)
if (!isKnownTab) {
  activeTab.value = tabs[0]?.value || 'tasks'
}

const handleTabChange = (newTab: string) => {
  const previousScrollTop = panelScrollContainer.value?.scrollTop ?? 0
  const previousWindowScrollY = window.scrollY
  activeTab.value = newTab

  nextTick(() => {
    if (panelScrollContainer.value) {
      panelScrollContainer.value.scrollTop = previousScrollTop
    }
    window.scrollTo({
      top: previousWindowScrollY,
      behavior: 'instant' as ScrollBehavior,
    })
  })
}
if (wo_type == 'request' && wo_data.type.code_work_order == 'wo') {
  readonly = true
}
// approve
if (wo_data.action_status == 2) {
  readonly = true
}
// created_type
if (['system', 'pdm_generated', 'manual'].includes(wo_data.created_type)) {
  readonly = true
}

// pm_type
if (
  ['generated', 'completed', 'pdm_generated', 'manual'].includes(
    wo_data.pm_type,
  )
) {
  readonly = true
}

const statusMapping = [
  {
    id: 1,
    name: t('Open'),
    icon: 'mdi:folder-open-outline',
  },
  {
    id: 2,
    name: t('In Progress'),
    icon: 'mdi:progress-clock',
  },
]

const subStatusMapping = {
  5: t('Waiting approval'),
  2: t('In Progress '),
}

const objectValue = ref({
  id: 1,
  name: t('Status'),
  icon: 'mdi:progress-clock',
})

const PriorityValue = ref({
  value: 1,
  text: t('Low'),
  media: '/img/icons/priority/low.svg',
})

const translatedPriorities = computed(() =>
  priorities.map((priority) => ({
    ...priority,
    text: t(priority.text),
    label: t(priority.label),
  })),
)

const Iconclass = ref({
  icon: 'icon_css',
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
  console.log('handleChangeKey')
  // key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const loadConditions = async () => {
  try {
    const filters = {
      active: 1,
    }
    const items = await getItems<any>({
      collection: 'Conditions',
      params: {
        filter: filters,
        meta: 'filter_count',
        // search: search.value,
        fields: ['*'],
      },
    })
    conditions.value = items.data
    console.log('loadConditions', items)
  } catch (e) {
    console.log('err', e)
  }
}

const getConditions = async () => {
  try {
    const filters = {
      active: 1,
    }
    const items = await getItems<any>({
      collection: 'Conditions',
      params: {
        filter: filters,
        meta: 'filter_count',
        // search: search.value,
        fields: ['*'],
      },
    })
    conditions.value = items.data
    console.log('loadConditions', items)
  } catch (e) {
    console.log('err', e)
  }
}

const loadWorkOrder = async () => {
  try {
    param_id = wo_id
    const filters = {
      id: wo_id,
    }

    const items = await getItems<any>({
      collection: 'Predictive',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: [
          '*',
          'status.id',
          'wo_status.*',
          'condition.*',
          'status.name',
          'type.*',
          'work_type.*',
          'asset.*',
          'template_pm.*',
          'location.*',
          'department.*',
          'assigned_team.id',
          'assigned_team.name',
          'template.*',
          'assigned_to.*',
          'assigned_to.role.name',
          'asset.location.*',
          'asset.department.*',
        ],
      },
    })

    console.log('items ->', items)
    work_order.value = items.data[0]
    objectValue.value = {
      id: work_order.value.wo_status.id,
      name: t(work_order.value.wo_status.status_text),
      icon: work_order.value.wo_status.icon,
    }

    if (work_order.value.priority) {
      let priorityItem = priorities.find(
        (p) =>
          p.value == work_order.value.priority ||
          p.__original == work_order.value.priority,
      )

      PriorityValue.value = {
        id: priorityItem.value,
        text: t(priorityItem.text),
        media: priorityItem.media,
      }
    }

    // Work type
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
    department.value = items.data[0].department?.name
    assigned_team.value = items.data[0].assigned_team?.name

    if (wo_type != 'request' && items.data[0].due) {
      due_date.value = formatDateToMMDDYYYY(new Date(items.data[0].due))
    }
    // else if (wo_type === 'request') {
    //   work_order.value.started_at = null
    //   work_order.value.due = null
    // }

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

const loadTempTypes = async () => {
  try {
    const filters = {
      enabled: true,
      code: {
        _nnull: true,
      },
    }
    const items = await getItems({
      collection: 'Template_type',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    temp_types.value = items.data
  } catch (e) {
    console.log(e)
  }
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

onMounted(async () => {
  loading.value = true

  await loadWorkOrder()
  await loadTypes()
  await loadTempTypes()
  await loadGroupTypes()

  // await loadConditions()

  loading.value = false
  // if (work_order.value.started_at && work_order.value.due) {
  //   setInterval(updateDates, 1000) // Update every second
  // }

  // console.log(' loadTasks.data', loadTasks)
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
    const cleanedValue = event.target.value.replace(/\D/g, '')
    const priority = cleanedValue ? parseInt(cleanedValue, 10) : null
    // Only include priority in items if it's a valid number (not NaN or null for empty values)
    if (priority !== null && !isNaN(priority)) {
      items = { ...items, priority }
    } else if (event.target.value === '' || event.target.value === null) {
      // Explicitly set to null for empty values to clear the foreign key
      items = { ...items, priority: null }
    }
  }

  if (event.target.name == 'work_type') {
    const cleanedValue = event.target.value.replace(/\D/g, '')
    const work_type = cleanedValue ? parseInt(cleanedValue, 10) : null
    // Only include work_type in items if it's a valid number (not NaN or null for empty values)
    if (work_type !== null && !isNaN(work_type)) {
      items = { ...items, work_type }
    } else if (event.target.value === '' || event.target.value === null) {
      // Explicitly set to null for empty values to clear the foreign key
      items = { ...items, work_type: null }
    }
  }

  if (event.target.type == 'datetime-local') {
    let keyName
    if (event.target.name == 'due') keyName = 'due'
    else if (event.target.name == 'started_at') keyName = 'started_at'
    else if (event.target.name == 'created_at') keyName = 'created_at'
    else if (event.target.name == 'completed_at') keyName = 'completed_at'

    items = { ...items, [keyName]: event.target.value }
  }

  if (event.target.name === 'wo_name') {
    items = { ...items, name: value }
  }

  if (event.target.name === 'group_number') {
    items = { ...items, group_number: value }
  }

  if (event.target.name === 'safety_notes') {
    items = { ...items, safety_notes: value }
  }

  if (event.target.name === 'description') {
    items = { ...items, history_description: value }
  }

  if (event.target.name === 'department') {
    items = { ...items, department: value }
  }

  const updateData = {
    collection: 'Predictive',
    id: wo_id,
    item: items,
  }

  updateItem(updateData).then((res) => {
    if (event.target.name === 'wo_name') {
      refresh()
    }

    // toaster.show({
    //   title: t('Updated'),
    //   message: t('Record updated successfully!'),
    //   color: 'success',
    //   icon: 'ph:user-circle-fill',
    //   closable: true,
    // })
  })
}

const setValue = async (item, ind) => {
  const updateData = {
    collection: 'Predictive',
    id: wo_id,
    item: { department: item?.id ?? null },
  }
  await updateItem(updateData)
}

const startdate = async (item) => {
  console.log('items', item)
}

function onClick(item, type) {
  let updateData = {}

  // console.log('condition', item)

  if (type == 'priority') {
    updateData = {
      collection: 'Predictive',
      id: wo_id,
      item: { priority: item.value },
    }
  } else if (type == 'condition') {
    updateData = {
      collection: 'Predictive',
      id: wo_id,
      item: { condition: item.id },
    }
  } else if (type == 'type') {
    updateData = {
      collection: 'Predictive',
      id: wo_id,
      item: { type: item.value },
    }
  } else if (type == 'work_type') {
    updateData = {
      collection: 'Predictive',
      id: wo_id,
      item: { work_type: item.value },
    }
  } else if (type == 'wo_status') {
    updateData = {
      collection: 'Predictive',
      id: wo_id,
      item: { wo_status: item.id },
    }
  }

  updateItem(updateData).then((res) => {
    console.log('done')

    // Гадаад жагсаалтыг сэргээхээс гадна энэ цонхны өөрийнх нь утгыг ч
    // (жишээ нь work_order_type) шинэчлэхийн тулд локал дата-г дахин ачаална
    loadWorkOrder()
    if (refresh != null) refresh()
  })
}

const handleAssetClick = (type) => {
  if (type == 'asset') {
    isModalAssetOpen.value = true
  } else {
    isModalTeamsOpen.value = true
  }
}

const handleModalAssetClose = () => {
  isModalAssetOpen.value = false
  isModalTeamsOpen.value = false
  if (refresh) refresh()
}
const setAsset = (obj: any) => {
  console.log('setAsset', obj)
  let items = {
    asset: obj.id,
    location: params.id,
  }
  work_order.value.asset = obj
  const updateData = {
    collection: 'Predictive',
    id: wo_id,
    item: items,
  }

  updateItem(updateData).then((res) => {
    toaster.show({
      title: t('Updated'),
      message: t('Record updated successfully!'),
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
    asset_code.value = obj.asset_code
  })
}

const setTeam = (obj: any) => {
  const updateData = {
    collection: 'Predictive',
    id: wo_id,
    item: { assigned_team: obj.id },
  }

  updateItem(updateData).then((res) => {
    // toaster.show({
    //   title: t('Updated'),
    //   message: t('Record updated successfully!'),
    //   color: 'success',
    //   icon: 'ph:user-circle-fill',
    //   closable: true,
    // })
    assigned_team.value = obj.name
  })
}

const handleProgress = async () => {
  await progressComponent?.value?.loadWorkOrderItems()
  ProgressValue.value = progressComponent?.value?.progress_value
}

const handleTasksUpdate = (newTasks) => {
  // console.log('done:)', newTasks)
  showBttn.value = true
  loadTasks = newTasks
}

const disabler = document.querySelector('.disabler')
if (disabler) {
  disabler.addEventListener(
    'click',
    () => {
      console.log('disabler-clicked')
      windowClose('disabler')
    },
    { once: true }, // 🎯 Зөвхөн нэг удаа ажиллана
  )
}

const windowClose = async (type) => {
  if (type == 'bttn') close()

  console.log('windowClose', ProgressValue)
  if (ProgressValue.value > 0) {
    // Update work
    // updateItem({
    //   collection: 'Predictive',
    //   id: wo_id,
    //   item: {
    //     wo_percent: ProgressValue.value.toFixed(2),
    //   },
    // })
  }
}

const changePos = async (datas) => {
  // console.log('changePos:)', datas)
  transformedPos.value = datas.map((item, parentIndex) => {
    let task = {
      ...item,
      pos: parentIndex + 1,
      children: item.children.map((child, childIndex) => ({
        ...child,
        pos: childIndex + 1,
      })),
    }
    console.log('task:)', task)
    return task
  })
  // console.log('transformedPos:)', transformedPos.value)

  // Immediately update positions in database after drag
  try {
    for (
      let parentIndex = 0;
      parentIndex < transformedPos.value.length;
      parentIndex++
    ) {
      const parent = transformedPos.value[parentIndex]

      // Update parent position
      await updateItem({
        collection: 'Predictive_item',
        id: parent.id,
        item: {
          pos: parentIndex,
          parent: null,
        },
      })

      // Update children positions
      if (parent.children && parent.children.length > 0) {
        for (
          let childIndex = 0;
          childIndex < parent.children.length;
          childIndex++
        ) {
          const child = parent.children[childIndex]

          await updateItem({
            collection: 'Predictive_item',
            id: child.id,
            item: {
              parent: parent.id,
              pos: childIndex,
            },
          })
        }
      }
    }
    console.log('✅ Positions updated successfully')
  } catch (error) {
    console.error('❌ Error updating positions:', error)
  }
}

const handlePartsUpdate = (items) => {
  loadedParts = items
}

const handleDocsUpdate = (items) => {
  loadDocs = items
}

const handleCostsUpdate = (items) => {
  loadCostsPart = items
}

const handleTradesUpdate = (items) => {
  loadCostsTrades = items
}

const handleActionsUpdate = (items) => {
  loadActions = items
}

const handleComplete = () => {
  isModalApproveConfirmOpen.value = true
}

const do_make = async (item, type) => {
  let statuss = 1

  if (wo_data?.action_status != 2) {
    toaster.show({
      title: t('Error'),
      message: 'Not approved!',
      color: 'Error',
      icon: 'mdi:alert',
      closable: true,
      duration: 1000,
    })
    return
  }

  const completed_status = wo_statuses.find(
    (item) =>
      item?.type?.toLowerCase() === 'completed' ||
      item?.status_text?.toLowerCase() === 'completed',
  )

  const updateData = {
    collection: 'Predictive',
    id: wo_id,
    item: {
      status: '3',
      wo_status: completed_status.id,
      completed_at: new Date().toISOString(),
    },
  }
  // console.log('Update', completed_status)

  updateItem(updateData).then((res) => {
    // console.log('Update', work_order)

    const action_log = createItems({
      collection: 'Predictive_actions',
      items: {
        wo_id: wo_id,
        first_user: myId,
        action_status: 7,
        company_id: myCompanyId,
      },
    })

    router.push(
      `/predictive/location/completed/${work_order?.value?.asset?.location?.id}`,
    )
  })
}

const handleModalConfirmClose = () => {
  isModalApproveConfirmOpen.value = false
}
const backToAsset = (workorder) => {
  console.log('hihi', workorder)
  console.log('asset_data', asset_data)

  if (asset_data) {
    open('asset', {
      id: asset_data.id,
      data: asset_data,
      p_type: 'pm',
      active_tab: 'pm',
      w_type: 'pm',
    })
  }
}
</script>

<template>
  <div
    ref="panelScrollContainer"
    class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 border bg-white w-[80%] overflow-y-scroll"
  >
    <!-- Close -->
    <div class="flex h-16 w-full items-center justify-start px-10 more">
      <button
        type="button"
        class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300 dark:hover:text-white"
        @click="windowClose('bttn')"
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

      <div
        class="prmore-header taskNumber flex justify-between items-center w-full"
      >
        <div
          class="flex flex-start font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white m-[10px]"
        >
          PDM #{{ work_order.auto_number }}
          <!-- <p :style="{ color: 'red' }">#{{ item_id }}</p> -->
        </div>

        <!-- Жагсаалт дотор Next/Prev шилжих -->
        <div v-if="navList.length" class="flex items-center gap-1 mr-4">
          <button
            type="button"
            :disabled="!hasPrevItem"
            class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-8 w-8 items-center justify-center rounded-full transition-colors duration-300 disabled:opacity-30 disabled:pointer-events-none dark:hover:text-white"
            :title="t('Previous')"
            @click="goToPrevItem"
          >
            <Icon name="ph:caret-left-bold" class="h-4 w-4" />
          </button>
          <button
            type="button"
            :disabled="!hasNextItem"
            class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-8 w-8 items-center justify-center rounded-full transition-colors duration-300 disabled:opacity-30 disabled:pointer-events-none dark:hover:text-white"
            :title="t('Next')"
            @click="goToNextItem"
          >
            <Icon name="ph:caret-right-bold" class="h-4 w-4" />
          </button>
        </div>
      </div>
    </div>

    <div class="relative pm_order_more">
      <!-- First Row -->
      <div class="grid grid-cols-5 gap-4 wo_more px-8 py-2">
        <!-- Left: Action status badge + WO Name -->
        <div class="col-span-3 grid grid-cols-3 gap-x-4 items-end">
          <!-- Action status badge -->
          <div
            v-if="work_order.template_pm == null"
            class="shrink-0 flex items-center capitalize flex flex-col gap-1"
            style="min-width: 120px; height: 42px"
          >
            <PriorityCell
              fieldName="action_status"
              :value="wo_data.action_status"
            />
          </div>
          <div v-else class="flex flex-col gap-1 wo_number_badge_wrapper">
            <FormKit
              label="PDM-List:"
              name="wo_number_badge"
              type="text"
              :model-value="'#' + work_order.template_pm?.auto_number"
              :disabled="true"
              :classes="{
                input: 'wo_input wo_number_badge',
                outer: 'wo_wrapper wo_number_badge_wrapper',
                label: 'wo_number_badge_label',
              }"
            />
          </div>
          <!-- WO Name -->
          <div class="col-span-2">
            <FormKit
              :label="t('WO Name')"
              name="wo_name"
              type="text"
              @change="onChange"
              v-model="work_order.name"
              :disabled="readonly"
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
              :disabled="readonly"
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
              <span class="wo_label">{{ t('Asset') }}</span>
              <BaseButton
                color="primary"
                class="btn-standard w-full overflow-hidden whitespace-nowrap"
                @click="handleAssetClick('asset')"
                :disabled="true"
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
                :items="translatedPriorities"
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
                <span class="truncate">{{ work_order?.location?.name }}</span>
              </BaseButton>
            </div>
            <div class="flex flex-col gap-1">
              <!-- <BaseListbox
                label="Type"
                :items="work_order_types"
                :disabled="readonly"
                :properties="{
                  value: 'value',
                  label: 'label',
                }"
                :model-value="work_order_type"
                size="md"
                rounded="md"
                @update:model-value="onClick($event, 'type')"
                style="margin-top: 4px"
              /> -->
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
                :label="t('Due date')"
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
              <span class="wo_label">{{ t('Team') }}</span>
              <BaseButton
                color="success"
                class="btn-standard w-full overflow-hidden whitespace-nowrap"
                @click="handleAssetClick('team')"
                :disabled="readonly"
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
                item_title="name"
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

        <div class="col-span-5 custom-style-wrapper">
          <BaseCard shape="curved" class="p-1 dragArea task">
            <span class="text-[9px] text-red-200 mt-0.5">{{ t('sec') }}</span>
            <div>
              <BaseHeading
                tag="h3"
                size="sm"
                weight="medium"
                class="text-muted-800 dark:text-muted-100"
              >
                <div class="flex items-center space-x-2 p-3">
                  <span class="text-muted-500 flex items-center dataHubInfo">
                    dataHub: {{ work_order.datahub_info || '-' }}
                  </span>
                </div>
              </BaseHeading>
            </div>
          </BaseCard>
        </div>

        <!--  Description -->
        <div class="col-span-5 custom-style-wrapper">
          <div class="w-full">
            <FormKit
              v-model="work_order.history_description"
              label="Description:"
              name="description"
              :disabled="false"
              type="textarea"
              @change="onChange"
              rows="3"
              class="w-full"
            />
          </div>
          <div class="w-full">
            <FormKit
              v-model="work_order.safety_notes"
              label="Safety Notes:"
              name="safety_notes"
              type="textarea"
              @change="onChange"
              :disabled="false"
              rows="2"
              class="w-full"
            />
          </div>
        </div>

        <!-- Tabs -->
        <div class="col-span-5">
          <BaseTabs
            justify="end"
            type="box"
            :model-value="activeTab"
            @update:model-value="handleTabChange"
            class="tabs"
            :tabs="
              work_order.pm_type == 'pdm_generated' ? generated_tabs : tabs
            "
          >
            <template #tab="{ activeValue }">
              <div
                v-if="activeValue === 'tasks'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderitemDynamicTree
                  :loadTasks="loadTasks"
                  @update:loadTasks="handleTasksUpdate"
                  :changePos="changePos"
                  :code="wo_id"
                  :key="key"
                  :refresh="handleChangeKey"
                  :progress="handleProgress"
                  :freeze="readonly"
                  :TempTypes="temp_types"
                  collection="Predictive_item"
                />
              </div>
              <!-- <div
                  v-else-if="activeValue === 'assets'"
                  class="font-sans text-sm text-gray-500 dark:text-gray-400"
                >
                  <PrAssets :work_order="work_order" :location="params.id" />
                </div> -->

              <div
                v-else-if="activeValue === 'condition'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <ConditionTab
                  :work_order="work_order"
                  :location="wo_location"
                  :refresh="refresh"
                  clickedtab="private"
                  :readonly="readonly"
                  :freeze="work_order.action_status == 2 ? true : false"
                />
              </div>

              <!-- <div
                v-else-if="activeValue === 'users'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <PrUsers :work_order="work_order" />
              </div> -->

              <div
                v-else-if="activeValue === 'trades'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderTrades
                  :estimated_edit="true"
                  :actual_edit="true"
                  :work_order="work_order"
                  :collection="'Predictive_Tradecode'"
                  @update:loadTrades="handleTradesUpdate"
                  :freeze="work_order.action_status == 2 ? true : false"
                />
              </div>

              <div
                v-else-if="activeValue === 'parts'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderParts
                  :estimated_edit="true"
                  :actual_edit="true"
                  :work_order="work_order"
                  :loadedParts="loadedParts"
                  @update:loadedParts="handlePartsUpdate"
                  :collection="'Predictive_Parts'"
                  :freeze="work_order.action_status == 2 ? true : false"
                />
              </div>
              <div
                v-else-if="activeValue === 'documents'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderDocuments
                  :loadDocs="loadDocs"
                  @update:loadDocs="handleDocsUpdate"
                  :work_order="work_order"
                  :collection="'Predictive_files'"
                  :freeze="work_order.action_status == 2 ? true : false"
                />
              </div>
              <div
                v-else-if="activeValue === 'costs'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderCosts
                  :estimated_edit="work_order.action_status == 2 ? true : false"
                  :actual_edit="work_order.action_status == 2 ? false : true"
                  :work_order="work_order"
                  :show_budget="true"
                  :loadCostsPart="loadCostsPart"
                  :loadCostsTrades="loadCostsTrades"
                  @update:loadCostsPart="handleCostsUpdate"
                  @update:loadCostsTrades="handleTradesUpdate"
                  :parts_collection="'Predictive_Parts'"
                  :trades_collection="'Predictive_Tradecode'"
                  :wo_collection="'Predictive'"
                  :freeze="work_order.action_status == 2 ? true : false"
                />
              </div>
              <div
                v-else-if="activeValue === 'actions'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <Actions
                  :delete="true"
                  :work_order="work_order"
                  :loadActions="loadActions"
                  @update:loadActions="handleActionsUpdate"
                  :collection="'Predictive_actions'"
                  :freeze="work_order.action_status == 2 ? true : false"
                />
              </div>
            </template>
          </BaseTabs>
          <br />
          <!-- <div class="mt-[20px] mb-[80px]" v-if="showBttn">
            :model-value="activeTab"
              color="danger"
              v-if="wo_data.action_status == 2"
            @update:model-value="handleTabChange"
              @click="handleComplete"
              >Work order complete</BaseButton
            >
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
              Print</BaseButton
            >
          </div> -->
        </div>
      </div>

      <!-- <div class="col-span-12" v-if="loading">
        <BasePlaceload class="h-4 w-full rounded" />
      </div> -->
    </div>
    <!--Asset Modal-->
    <ModalAssetsList
      :open="isModalAssetOpen"
      :close="handleModalAssetClose"
      :setAsset="setAsset"
      :location="wo_location"
    />
    <ModalItemsList
      :open="isModalTeamsOpen"
      :header="[
        { title: t('Name'), key: 'name', align: 'start', width: '30%' },
        {
          title: t('Users'),
          key: 'users',
          align: 'start',
          sortable: false,
        },
        {
          title: t('Created'),
          key: 'user_created.first_name',
          align: 'start',
          sortable: false,
        },
        { title: t('Action'), key: 'action', align: 'start', sortable: false },
      ]"
      :close="handleModalAssetClose"
      :setItem="setTeam"
      :location="wo_location"
      :title="$t('Teams')"
      class="teams"
      collection="Teams"
      :useslot="['users']"
      fields="*,user_created.first_name, users.directus_users_id.first_name, users.directus_users_id.email"
    />
    <ConfirmModalForm
      :itemsValue="wo_data"
      code="Completed"
      text="Do you agree to this action?"
      :open="isModalApproveConfirmOpen"
      :close="handleModalConfirmClose"
      :do_make="do_make"
      actionType="Completed"
      :row="wo_data.id"
      :refresh="close"
    />
  </div>
</template>

<style>
.pm_order_more .wo_wrapper .vs__dropdown-menu {
  width: fit-content !important;
}
.pm_order_more .nui-listbox .nui-listbox-option {
  padding: 0px !important;
}
.pm_order_more .wo_input,
.pm_order_more .department .vs__dropdown-toggle {
  height: 40px !important;
  font-size: 13px !important;
}
.pm_order_more .woname_wrapper {
  max-width: 95% !important;
}
.pm_order_more .woname_label {
  font-size: 11px !important;
  font-weight: 500 !important;
  color: #6b7280 !important;
}
.custom-style-wrapper .max-w-md {
  max-width: none !important;
  width: 100% !important;
}

.pm_order_more .priority_action .nui-avatar .nui-avatar-img {
  object-fit: scale-down;
}

/* Unified label size across all columns */
.pm_order_more .bttns_action .wo_label,
.pm_order_more .wo_label,
.pm_order_more .nui-listbox-label,
.pm_order_more .formkit-label {
  display: block;
  font-size: 11px !important;
  font-weight: 500 !important;
  color: #6b7280 !important;
  margin-bottom: 2px !important;
}

/* Unified input value font size */
.pm_order_more .wo_input,
.pm_order_more .nui-listbox-button,
.pm_order_more .vs__selected,
.pm_order_more .vs__search,
.pm_order_more .department .vs__selected-options,
.pm_order_more input[type='datetime-local'] {
  font-size: 13px !important;
}

/* Remove extra spacing from FormKit/BaseListbox wrappers for row alignment */
.pm_order_more .wo_wrapper {
  margin-bottom: 0 !important;
}
.pm_order_more .priority_action .nui-listbox,
.pm_order_more .grid .nui-listbox {
  margin-bottom: 0 !important;
}

/* Date inputs narrower */
.pm_order_more .date_action .wo_input {
  max-width: 160px !important;
  font-size: 12px !important;
  padding-inline: 6px !important;
}
.work_order_more .date_action {
  margin-top: -1px !important;
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
  width: 100%;
  height: 40px;
  padding: 0 12px;
  font-size: 13px;
  text-align: center;
  border-radius: 8px;
  white-space: nowrap;
  gap: 6px;
}
.dark .wo_wrapper .vs--disabled .vs__dropdown-toggle,
.dark .wo_wrapper .vs--disabled .vs__clear,
.dark .wo_wrapper .vs--disabled .vs__search,
.dark .wo_wrapper .vs--disabled .vs__selected,
.dark .wo_wrapper .vs--disabled .vs__open-indicator {
  background: rgb(15 23 42 / 0.75) !important;
  color: white !important;
}
.pm_order_more .nui-listbox-outer {
  border-width: 1px !important;
  border-style: solid !important;
  border-color: #0000001f !important;
  border-radius: 4px !important;
}
</style>
