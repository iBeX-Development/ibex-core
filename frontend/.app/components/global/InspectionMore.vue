<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import PriorityCell from '~/components/custom/priorityCell.vue'
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import WarningModalForm from '~/components/form/WarningModalForm.vue'

import ModalItemsList from '~/components/form/ModalItemsList.vue'
import Actions from '~/components/inspection/Actions.vue'
import AssetUsers from '~/components/inspection/AssetUsers.vue'
import Comment from '~/components/inspection/Comment.vue'
import Progress from '~/components/inspection/Progress.vue'
import ScheduleTab from '~/components/inspection/ScheduleTab.vue'

// import RequestInfoItem from '~/components/inspectionitem/RequestInfoItem.vue'
// import InspectionitemTree from '~/components/inspectionitem/Tree.vue'

const config = useRuntimeConfig()
const runtimeConfig = useRuntimeConfig()

import { priorities } from '~/components/workorder/WorkOrderConstants'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'

const { t } = useI18n({ useScope: 'global' })
const myId = window.localStorage.getItem('myId')
const uploadedFiles = ref([])

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

const { open, close, currentProps, panels, current } = usePanels()

const RequestWork = ref([])
const RequestInfo = ref(false)
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const isModalConfirmText = ref('')
const isModalApproveConfirmOpen = ref(false)

const wo_id = currentProps?.value?.id || null
const wo_data = currentProps?.value?.data || null
const wo_statuses = currentProps?.value?.wo_statuses || wo_status_items
const wo_type = currentProps?.value?.type || null
const mode = currentProps?.value?.mode || 'admin'
const pm_type = currentProps?.value?.pm_type || 'admin'
const refresh = currentProps?.value?.refresh || null
// const active_tab = currentProps?.value?.active_tab || 'tab-1'

const onMessage = currentProps?.value?.onMessage || false
const freezeProp = currentProps?.value?.freeze === true
const backBttn = currentProps?.value?.backBttn || false
const active_tab = currentProps?.value?.active_tab || false
const backFn = currentProps?.value?.backFn || false
const asset_data = currentProps?.value?.asset_data || null

// ── Жагсаалт дотор Next/Prev шилжих ────────────────────────────────────────
// Санамж: энэ panel-д OpenMore/PmMore/PrMore шиг амьд идэвхтэй tab ref
// байхгүй (avtiveTab нь зүгээр л 'tasks' гэсэн статик утга) тул
// сонгосон tab-аа хадгалж чадахгүй — зөвхөн анхны active_tab prop
// (currentProps-оос spread хийгдэнэ) хэвээрээ дамжина
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
  open('inspectionmore', {
    ...(currentProps?.value || {}),
    id: item.id,
    data: item,
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
const transformedPos = ref([])
const work_order = ref({})
const { getItems, createItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const { getUsers } = useDirectusUsers()
const loading = ref(true)
const key = ref(1)
const timeout = ref(null)
const toaster = useToaster()
const progressComponent = ref(null)

// Counter
const daysPassed = ref(0)
const hoursPassed = ref(0)
const minutesPassed = ref(0)
const secondsPassed = ref(0)

// Work order file
const inputFile = ref()
const group_types = ref<any[]>([])
const work_order_types = ref<any[]>([])
const work_order_type = ref<any>([])
const temp_types = ref([])
// const selectedStatus = ref(null)
const showSubStatus = ref(false)
const sDate = ref(null)
const dDate = ref(null)
const cDate = ref(null)
const cDateTime = ref(null)
const alertMsg = ref(false)
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
const ProgressValue = ref(0)
const ProgressValue1 = ref(0)
let param_id = 0

//print
const pathWithoutId = router.currentRoute.value.path.replace(/\/\d+$/, '')
const printPath = `${pathWithoutId}/print`
let avtiveTab = 'tasks'
let tabs = [
  { label: t('Tasks'), value: 'tasks' },
  { label: t('Schedule'), value: 'schedule' },
  { label: t('Asset'), value: 'asset' },
  // { label: t('Users'), value: 'users' },
  { label: t('Parts'), value: 'parts' },
  { label: t('Documents'), value: 'documents' },
  // { label: t('Costs'), value: 'costs' },
  { label: t('Actions'), value: 'actions' },
  { label: t('Comments'), value: 'comments' },
]

let generated_tabs = [
  { label: t('Tasks'), value: 'tasks' },
  // { label: t('Asset'), value: 'asset' },
  { label: t('Users'), value: 'users' },
  { label: t('Parts'), value: 'parts' },
  { label: t('Documents'), value: 'documents' },
  // { label: t('Costs'), value: 'costs' },
  { label: t('Actions'), value: 'actions' },
]

let user_tabs = [
  { label: t('Tasks'), value: 'tasks' },
  // { label: t('Asset'), value: 'asset' },
  { label: t('Users'), value: 'users' },
  { label: t('Comments'), value: 'comments' },
  { label: t('Actions'), value: 'actions' },
]

// console.log('wo_data', wo_data)
if (wo_data.wo_status?.id == 3 || wo_data.wo_status == 3) {
  readonly = true
}
// approve bol asset team name grouptype-iig tugjine
if (wo_data.action_status == 2) {
  readonly = true
}
if (
  wo_data.pm_type &&
  ['delivered', 'generated', 'completed'].includes(wo_data.pm_type)
) {
  readonly = true
}

const statusMapping = [
  {
    id: 1,
    name: 'Opne',
    icon: 'mdi:folder-open-outline',
  },
  {
    id: 2,
    name: 'In Progress',
    icon: 'mdi:progress-clock',
  },
]

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
  // console.log('handleChangeKey')
  // key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const loadWorkOrder = async () => {
  try {
    param_id = wo_id
    const filters = {
      id: wo_id,
      company_id: { _eq: myCompanyId },
    }
    const items = await getItems<any>({
      collection: 'Work_inspections',
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
          'location.*',
          'template_pm.*',
          'department.*',
          'assigned_team.id',
          'assigned_team.name',
          'template.*',
          'assigned_to.*',
          'assigned_to.role.name',
          'asset.*',
          'picture.*',
          'asset.location.*',
          'asset.department.*',
        ],
      },
    })

    work_order.value = items.data[0]
    // console.log('items.data', items.data)
    objectValue.value = {
      id: work_order.value.wo_status.id,
      name: work_order.value.wo_status.status_text,
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
    department.value = items.data[0].department?.name
    assigned_team.value = items.data[0].assigned_team?.name

    if (wo_type != 'request' && items.data[0].due) {
      due_date.value = formatDateToMMDDYYYY(new Date(items.data[0].due))
    }

    let dueObj = null
    let sdObj = null
    let cdObj = null

    if (work_order.value.due != null) {
      dueObj = new Date(work_order.value.due)
      dDate.value = dueObj.toISOString().split('T')[0]
    }

    if (work_order.value.started_at != null) {
      sdObj = new Date(work_order.value.started_at)
      sDate.value = sdObj.toISOString().split('T')[0]
    }

    if (work_order.value.completed_at != null) {
      cdObj = new Date(work_order.value.completed_at)
      cDateTime.value = work_order.value.completed_at
      cDate.value = cdObj.toISOString().split('T')[0]
    }

    // else if (wo_type === 'request') {
    //   work_order.value.started_at = null
    //   work_order.value.due = null
    // }
    // console.log('work_order.value', work_order.value)

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

const loadRequestInfo = async () => {
  try {
    const filters = {
      workorder: wo_id,
      active: 1,
      created_type: {
        _in: ['request_info'], // Зөвхөн request_info-оос бусад утгуудыг авна
      },
    }
    const items = await getItems<any>({
      collection: 'Work_inspection_item',
      params: {
        filter: filters,
        limit: -1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    RequestWork.value = items.data
  } catch (e) {
    console.log('hey', e)
  }
}

onMounted(async () => {
  loading.value = true

  await loadWorkOrder()
  await loadTypes()
  await loadTempTypes()
  await loadGroupTypes()

  // if (work_order.value?.id) {
  //   document.title = `Work order #${work_order.value.id}`;
  // }

  loading.value = false
  if (work_order.value.started_at && work_order.value.due) {
    setInterval(updateDates, 1000) // Update every second
  }

  // console.log(' loadTasks.data', loadTasks)
  if (wo_type == 'request') {
    RequestInfo.value = true
    await loadRequestInfo()
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

  // console.log('event', event)

  if (event.target.name == 'priority') {
    const priority = parseInt(event.target.value.replace(/\D/g, ''), 10)
    items = { ...items, priority }
  }

  if (event.target.name == 'work_type') {
    const work_type = parseInt(event.target.value.replace(/\D/g, ''), 10)
    items = { ...items, work_type }
  }

  if (event.target.type == 'datetime-local') {
    let keyName = ''
    let dateObj = null

    if (work_order.value.started_at) {
      const dateObj0 = new Date(work_order.value.started_at)
      sDate.value = dateObj0.toISOString().split('T')[0]
    }

    if (work_order.value.completed_at) {
      const dateObj1 = new Date(work_order.value.completed_at)
      cDate.value = dateObj1.toISOString().split('T')[0]
    }

    if (work_order.value.due) {
      const dateObj2 = new Date(work_order.value.due)
      dDate.value = dateObj2.toISOString().split('T')[0]
    }

    if (event.target.name == 'due') {
      keyName = 'due'
      dDate.value = event.target.value
    } else if (event.target.name == 'started_at') {
      keyName = 'started_at'
      sDate.value = event.target.value
    } else if (event.target.name == 'created_at') {
      keyName = 'created_at'
    } else if (event.target.name == 'completed_at') {
      keyName = 'completed_at'
      cDate.value = event.target.value
      cDateTime.value = event.target.value
    }

    if (sDate.value > cDate.value || sDate.value > dDate.value) {
      alertMsg.value = 'Check date'
      toaster.show({
        title: t('Check date'),
        message: 'start date is wrong!',
        color: 'Error',
        icon: 'mdi:alert',
        closable: true,
        duration: 1000,
      })
      return
    } else {
      alertMsg.value = false
    }

    // console.log(' alertMsg ', alertMsg)
    items = { ...items, [keyName]: event.target.value }
  }

  if (event.target.name === 'wo_name') {
    items = { ...items, name: value }
  }

  if (event.target.name === 'group_type') {
    items = { ...items, type: value }
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
    collection: 'Work_inspections',
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
    collection: 'Work_inspections',
    id: wo_id,
    item: { department: item?.id ?? null },
  }
  await updateItem(updateData)
}

function onClick(item, type) {
  let updateData = {}
  if (type == 'priority') {
    updateData = {
      collection: 'Work_inspections',
      id: wo_id,
      item: { priority: item?.__original ? item.__original : item.value },
    }
  } else if (type == 'wo_status') {
    updateData = {
      collection: 'Work_inspections',
      id: wo_id,
      item: { wo_status: item.id },
    }
  } else if (type == 'type') {
    updateData = {
      collection: 'Work_inspections',
      id: wo_id,
      item: { type: item.value },
    }
  } else if (type == 'work_type') {
    updateData = {
      collection: 'Work_inspections',
      id: wo_id,
      item: { work_type: item.value },
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
}
const setAsset = (obj: any) => {
  console.log(obj)
  let items = {
    asset: obj.id,
    location: params.id,
  }
  work_order.value.asset = obj
  const updateData = {
    collection: 'Work_inspections',
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
    collection: 'Work_inspections',
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
  // console.log('progressComponent?.value', progressComponent?.value)
  await progressComponent?.value?.loadWorkOrderItems()
  ProgressValue.value = progressComponent?.value?.progress_value
  ProgressValue1.value = ProgressValues(loadTasks)
}

const ProgressValues = (progress_data) => {
  // console.log('ProgressValues-progress_data', progress_data)

  if (progress_data && progress_data?.length) {
    const max_value = progress_data?.length
    let completed_value = 0
    try {
      // 1. Get the sum for template_type = 5 and value = "1"
      const sumTemplateType5Value1 = progress_data.filter(
        (item) =>
          item.template_type?.id === 5 &&
          (item.value == '1' || item.value == 1),
      ).length

      console.log(
        'ProgressValue1 for template_type = 5, value => 1:',
        sumTemplateType5Value1,
      )

      // 2. Get the sum for template_type = 7 where value is not null or empty
      const sumTemplateType7NotNull = progress_data.filter(
        (item) =>
          item.template_type.id === 7 &&
          item.value !== null &&
          item.value !== '',
      ).length
      console.log(
        'ProgressValue1 for template_type = 7, value:',
        sumTemplateType7NotNull,
      )
      completed_value = sumTemplateType7NotNull + sumTemplateType5Value1
    } catch (error) {
      console.log(error)
    }

    if (isNaN((completed_value / max_value) * 100)) return 0
    return (completed_value / max_value) * 100
  } else {
    return 0
  }
}

const handleTasksUpdate = (newTasks) => {
  // console.log('done:)', newTasks)
  // request-list eer uussen ajil bol
  if ((work_order.value.created_type = 'request')) {
    RequestInfo.value = true
    RequestWork.value = newTasks.filter(
      (item) => item.created_type === 'request_info',
    )
  }

  showBttn.value = true
  loadTasks = newTasks
}

const changePos = async (datas) => {
  // console.log('changePos:)', datas)

  // Guard against undefined or invalid data
  if (!datas || !Array.isArray(datas) || datas.length === 0) {
    console.warn('changePos: Invalid or empty data received')
    return
  }

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
        collection: 'Work_inspection_item',
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
            collection: 'Work_inspection_item',
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
  console.log('handleComplete', sDate.value, dDate.value, cDate.value)

  // if (sDate.value == null || dDate.value == null || cDate.value == null) {
  //   toaster.show({
  //     title: t('Error'),
  //     message: 'Not Completed and Insert dates!',
  //     color: 'Error',
  //     icon: 'mdi:alert',
  //     closable: true,
  //     duration: 1000,
  //   })
  //   return
  // }

  if (!asset_code.value) {
    console.log('asset_code', asset_code.value)
    isModalConfirmText.value = 'Choose asset items!'
    isModalConfirmOpen.value = true
  } else isModalApproveConfirmOpen.value = true
}

const createWork = () => {
  console.log('createWork')
}

const do_make = async (item, type) => {
  let statuss = 1

  // console.log('do_make_items', asset_code.value)
  // console.log('cDate', cDate.value)
  // console.log('cDateTime', cDateTime.value)

  const completed_status = wo_statuses.find(
    (item) =>
      item?.type?.toLowerCase() === 'completed' ||
      item?.status_text?.toLowerCase() === 'completed',
  )

  const updateData = {
    collection: 'Work_inspections',
    id: wo_id,
    item: {
      status: '3',
      wo_status: completed_status.id,
      completed_at: cDateTime.value || new Date().toISOString(),
    },
  }

  // console.log('Update', completed_status)
  updateItem(updateData).then((res) => {
    console.log('Update', res)
    // router.push(`/inspection/location/completed/${params.id}`)
  })
  if (refresh != null) refresh()
}

const handleModalConfirmClose = () => {
  isModalApproveConfirmOpen.value = false
  isModalConfirmOpen.value = false
}

const backToAsset = (workorder) => {
  // console.log('hihi', workorder)

  open('asset', {
    id: asset_data.id,
    data: asset_data,
    p_type: 'pm',
    active_tab: 'pm',
    w_type: 'pm',
  })
}

const windowClose = async (type) => {
  if (type == 'bttn') close()

  // Update progress if changed
  if (ProgressValue.value > 0) {
    updateItem({
      collection: 'Work_inspections',
      id: wo_id,
      item: {
        wo_percent: ProgressValue.value.toFixed(2),
      },
    })
    if (refresh != null) refresh(null, active_tab)
  } else {
    const res = updateItem({
      collection: 'Work_inspections',
      id: wo_id,
      item: {
        wo_percent: ProgressValue1.value.toFixed(2),
      },
    })
  }

  // Position updates are now handled in changePos() during drag
  // No need to update positions here anymore
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

//commnets
const selectedItem = ref(null)
const isOpenImg = ref(false)
const isOpenComment = ref(false)

const showComment = (item) => {
  console.log('showComment ->', item)
  isOpenComment.value = true
  selectedItem.value = item
}

const handleModalClose = () => {
  isOpenImg.value = false
  isOpenComment.value = false
  selectedItem.value = false
}

const get_file_url = (file) => {
  // console.log('get_content_url-files', file)

  // if (!file) {
  //   return false
  // }

  if (file?.type?.includes('image')) {
    return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
  } else {
    return false
  }
}

const remove = async (file) => {
  // console.log('remove-files', file)
  const updateData = {
    collection: 'Work_inspections',
    id: wo_id,
    item: {
      picture: null,
    },
  }

  const res = await updateItem(updateData)
}

const handleUploadedFile = async (files) => {
  // console.log('wo_id', wo_id)
  // console.log('files', files)
  // console.log('handleUploadedFile', uploadedFiles.value)
  if (uploadedFiles.value.length > 0) {
    const updateData = {
      collection: 'Work_inspections',
      id: wo_id,
      item: {
        picture: uploadedFiles.value[0].id, // зөвхөн нэг ID
      },
    }

    const res = await updateItem(updateData)
    // console.log('res', res)
  }
  uploadedFiles.value = []
}
</script>

<template>
  <div
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
        class="max-w-4xl taskNumber flex justify-between items-center w-full"
      >
        <div class="flex items-center gap-1">
          <div
            class="flex flex-start font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white m-[10px]"
          >
            INSP #{{ work_order.auto_number }}
            <!-- <p :style="{ color: 'red' }">#{{ item_id }}</p> -->
          </div>
        </div>

        <div
          class="flex items-baseline font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white m-[10px] absolute right-5"
        >
          <!-- Жагсаалт дотор Next/Prev шилжих -->
          <div v-if="navList.length" class="flex items-center gap-1 mr-2">
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
          <!-- Action status badge -->
          <div
            v-if="wo_data.template_pm == null"
            class="shrink-0 flex items-center capitalize flex"
            style="min-width: 120px; height: 44px"
          >
            <BaseHeading
              as="h3"
              size="2xl"
              weight="bold"
              class="w-[120px] flex justify-end items-center capitalize"
            >
              <PriorityCell
                fieldName="action_status"
                :value="wo_data.action_status"
              />
            </BaseHeading>
          </div>
          <div v-else class="flex flex-col gap-1 wo_number_badge_wrapper">
            <div class="flex gap-1 wo_number_badge_wrapper">
              <div class="wo_label">INSP-List:</div>
              <div class="wo_number_badge">
                <span class="wo_number_val">
                  {{
                    ' #' +
                    (wo_data.template_pm?.auto_number ?? wo_data?.auto_number)
                  }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class="relative Work_inspection_more">
      <!-- First Row -->
      <div class="grid grid-cols-5 gap-4 wo_more px-8 py-2">
        <div class="col-span-3 grid grid-cols-3 gap-x-4 items-end">
          <!-- FileUpload -->
          <div
            class="h-[62px] mw-[162px] rounded-lg flex items-center justify-center mt-[26px] mr-[10px] mb-0 ml-0"
            :disabled="readonly || wo_data.wo_status == 3 ? true : false"
          >
            <FileUpload
              :plus="false"
              :result="uploadedFiles"
              :runResult="handleUploadedFile"
              :remove="remove"
              widthSize="max-w-xl"
              :imageH="'62px'"
              :imageW="'100%'"
              :emptyStyle="'width: 100%; height: 62px;'"
              :hideText="true"
              :style="'height: 62px; width: 100%;'"
              :xstyle="'justify-content: flex-end; margin:-1px 0px 0px -25px;'"
              :fileUrl="get_file_url(work_order?.picture)"
              :disabled="readonly || wo_data.wo_status == 3 ? true : false"
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
          <div class="grid grid-cols-3 gap-x-4 gap-y-3 items-start">
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
                <span class="truncate">{{ work_order?.location?.name }}</span>
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
        <!--  Description -->
        <div class="col-span-5 custom-style-wrapper">
          <div class="w-full">
            <FormKit
              v-model="work_order.history_description"
              :label="t('Description')"
              name="description"
              :disabled="wo_data.wo_status == 3 ? true : false"
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
              name="safety_notes"
              type="textarea"
              @change="onChange"
              :disabled="wo_data.wo_status == 3 ? true : false"
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
            :model-value="avtiveTab"
            class="tabs"
            :tabs="
              work_order.pm_type == 'delivered' || pm_type == 'delivered'
                ? generated_tabs
                : mode == 'user'
                ? user_tabs
                : tabs
            "
          >
            <template #tab="{ activeValue }">
              <div
                v-if="activeValue === 'tasks'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <!-- <InspectionitemTree
                  :loadTasks="loadTasks"
                  @update:loadTasks="handleTasksUpdate"
                  :changePos="changePos"
                  :code="wo_id"
                  :key="key"
                  :refresh="handleChangeKey"
                  :progress="handleProgress"
                  :freeze="
                    wo_data.wo_status?.id == 3 || wo_data.wo_status === 3
                      ? true
                      : false
                  "
                  :TempTypes="temp_types"
                /> -->
                <WorkorderitemDynamicTree
                  :loadTasks="loadTasks"
                  @update:loadTasks="handleTasksUpdate"
                  :code="wo_id"
                  :key="key"
                  :refresh="handleChangeKey"
                  :changePos="changePos"
                  :progress="handleProgress"
                  :freeze="
                    wo_data.wo_status?.id == 3 || wo_data.wo_status === 3
                      ? true
                      : false
                  "
                  :TempTypes="temp_types"
                  collection="Work_inspection_item"
                />
              </div>

              <div
                v-else-if="activeValue === 'schedule'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <ScheduleTab
                  :work_order="work_order"
                  :refresh="refresh"
                  clickedtab="private"
                />
              </div>

              <div
                v-else-if="activeValue === 'asset'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <AssetUsers
                  :work_order="work_order"
                  :location="params.id"
                  :active_tab="active_tab"
                />
              </div>

              <div
                v-else-if="activeValue === 'users'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <InspectionUsers
                  :work_order="work_order"
                  :active_tab="active_tab"
                />
              </div>

              <div
                v-else-if="activeValue === 'parts'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <InspectionParts
                  :estimated_edit="work_order.action_status == 2 ? false : true"
                  :actual_edit="work_order.action_status == 2 ? false : true"
                  :work_order="work_order"
                  :loadedParts="loadedParts"
                  @update:loadedParts="handlePartsUpdate"
                  :active_tab="active_tab"
                />
              </div>
              <div
                v-else-if="activeValue === 'documents'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <InspectionDocuments
                  :loadDocs="loadDocs"
                  @update:loadDocs="handleDocsUpdate"
                  :work_order="work_order"
                  :active_tab="active_tab"
                />
              </div>
              <!-- <div
                v-else-if="activeValue === 'costs'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <InspectionCosts
                  :estimated_edit="work_order.action_status == 2 ? true : false"
                  :actual_edit="work_order.action_status == 2 ? false : true"
                  :work_order="work_order"
                  :loadCostsPart="loadCostsPart"
                  :loadCostsTrades="loadCostsTrades"
                  @update:loadCostsPart="handleCostsUpdate"
                  @update:loadCostsTrades="handleTradesUpdate"
                  :action_status="work_order.action_status"
                  :freeze="freezeProp || work_order.action_status == 2"
                  parts_collection="Work_inpection_Parts"
                  trades_collection="Work_inspection_Tradecode"
                />
              </div> -->
              <div
                v-else-if="activeValue === 'actions'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <Actions
                  :delete="true"
                  :work_order="work_order"
                  :loadActions="loadActions"
                  @update:loadActions="handleActionsUpdate"
                />
              </div>
              <div
                v-else-if="activeValue === 'comments'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <Comment
                  :itemsValue="work_order"
                  :open="showComment(work_order)"
                  :close="handleModalClose()"
                  :refresh="refresh"
                />
              </div>
            </template>
          </BaseTabs>
          <br />
          <div class="mt-[20px] mb-[80px]" v-if="active_tab == 'delivered'">
            <!-- <BaseButton
              color="info"
              v-if="wo_data.wo_status == 3"
              @click="createWork"
              >{{ t('Create Work') }}</BaseButton
            > -->
            <BaseButton
              color="success"
              class="ml-5"
              v-if="wo_data.wo_status != 3"
              @click="handleComplete"
              >{{ t('Complete') }}</BaseButton
            >
            <!-- <BaseButton
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
            > -->
          </div>
        </div>
      </div>

      <!-- <div class="col-span-12" v-if="loading">
        <BasePlaceload class="h-4 w-full rounded" />
      </div> -->
    </div>
    <!--Asset Modal-->
    <!-- <ModalAssetsList
      :open="isModalAssetOpen"
      :close="handleModalAssetClose"
      :setAsset="setAsset"
      :location="params.id"
      :locationName="work_order?.asset?.location?.name"
    /> -->
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
      :location="params.id"
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
    <WarningModalForm
      :text="$t(isModalConfirmText)"
      code="Transaction"
      :open="isModalConfirmOpen"
      :close="handleModalConfirmClose"
    />
  </div>
</template>

<style>
.Work_inspection_more .wo_wrapper .vs__dropdown-menu {
  width: fit-content !important;
}
.Work_inspection_more .nui-listbox .nui-listbox-option {
  padding: 0px !important;
}
.Work_inspection_more .wo_input,
.Work_inspection_more .department .vs__dropdown-toggle {
  height: 40px !important;
}
.Work_inspection_more .woname_wrapper {
  max-width: 95% !important;
}
.custom-style-wrapper .max-w-md {
  max-width: none !important;
  width: 100% !important;
}

.Work_inspection_more .priority_action .nui-avatar .nui-avatar-img {
  /* height: 60%;
    max-height: 60%;
    width: 58%;
    max-width: 60%; */
  object-fit: scale-down;
}

.dark .wo_wrapper .vs--disabled .vs__dropdown-toggle,
.dark .wo_wrapper .vs--disabled .vs__clear,
.dark .wo_wrapper .vs--disabled .vs__search,
.dark .wo_wrapper .vs--disabled .vs__selected,
.dark .wo_wrapper .vs--disabled .vs__open-indicator {
  background: rgb(15 23 42 / 0.75) !important;
  color: white !important;
}

.Work_inspection_more .wo_wrapper .vs__dropdown-menu {
  width: fit-content !important;
}
.Work_inspection_more .nui-listbox .nui-listbox-option {
  padding: 0px !important;
}
.Work_inspection_more .wo_input,
.Work_inspection_more .department .vs__dropdown-toggle {
  height: 40px !important;
  font-size: 13px !important;
}
.Work_inspection_more .woname_wrapper {
  max-width: 95% !important;
}
.Work_inspection_more .woname_label {
  font-size: 11px !important;
  font-weight: 500 !important;
  color: #6b7280 !important;
}
.custom-style-wrapper .max-w-md {
  max-width: none !important;
  width: 100% !important;
}

.Work_inspection_more .priority_action .nui-avatar .nui-avatar-img {
  object-fit: scale-down;
}

/* Unified label size across all columns */
.Work_inspection_more .bttns_action .wo_label,
.Work_inspection_more .wo_label,
.Work_inspection_more .nui-listbox-label,
.Work_inspection_more .formkit-label {
  display: block;
  font-size: 11px !important;
  font-weight: 500 !important;
  color: #6b7280 !important;
  margin-bottom: 2px !important;
}

/* Unified input value font size */
.Work_inspection_more .wo_input,
.Work_inspection_more .nui-listbox-button,
.Work_inspection_more .vs__selected,
.Work_inspection_more .vs__search,
.Work_inspection_more .department .vs__selected-options,
.Work_inspection_more input[type='datetime-local'] {
  font-size: 13px !important;
}

/* Remove extra spacing from FormKit/BaseListbox wrappers for row alignment */
.Work_inspection_more .wo_wrapper {
  margin-bottom: 0 !important;
}
.Work_inspection_more .priority_action .nui-listbox,
.Work_inspection_more .grid .nui-listbox {
  margin-bottom: 0 !important;
}

/* Date inputs narrower */
.Work_inspection_more .date_action .wo_input {
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
.Work_inspection_more .nui-listbox-outer {
  border-width: 1px !important;
  border-style: solid !important;
  border-color: #0000001f !important;
  border-radius: 4px !important;
}
</style>
