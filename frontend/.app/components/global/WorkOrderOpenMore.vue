<script setup lang="ts">
import { nextTick, onMounted, onUnmounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import PriorityCell from '~/components/custom/priorityCell.vue'
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import ModalItemsList from '~/components/form/ModalItemsList.vue'
import Actions from '~/components/workorder/Actions.vue'
import Comment from '~/components/workorder/Comment.vue'
import Debt from '~/components/workorder/Debt.vue'
import FailureAnalysisTab from '~/components/workorder/FailureAnalysisTab.vue'

import ModalAssetsList from '~/components/workorder/ModalAssetsList.vue'
import Progress from '~/components/workorder/Progress.vue'
import { priorities } from '~/components/workorder/WorkOrderConstants'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'
import AcceptInfoItem from '~/components/workorderitem/AcceptInfoItem.vue'
import RequestInfoItem from '~/components/workorderitem/RequestInfoItem.vue'

const { t } = useI18n({ useScope: 'global' })
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

const { open, close, currentProps, panels, current } = usePanels()

const RequestWork = ref([])
const RequestInfo = ref(false)
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const isModalApproveConfirmOpen = ref(false)
const isCompletionModalOpen = ref(false)
const completionDateTime = ref<string | null>(null)
const selectedCompletionStatus = ref<any>(null)
const locationBasedStatuses = ref<any[]>([])
const failureAnalysisEnabled = ref(false)
const selectedFailureTemplate = ref<any>(null)
const isFailureTemplateModalOpen = ref(false)
const failureAnswers = ref<Record<string, any>>({})

const parseFields = (raw: any) => {
  if (Array.isArray(raw)) return raw
  if (typeof raw === 'string') {
    try {
      return JSON.parse(raw)
    } catch {
      return []
    }
  }
  return []
}

const openFailureForm = (item: any) => {
  selectedFailureTemplate.value = item
  isFailureTemplateModalOpen.value = false
  const answers: Record<string, any> = {}
  const fields = parseFields(item.fields)
  fields.forEach((f: any) => {
    if (f.field_type === 'yes_no') answers[f.field_name] = 'Yes'
    else if (f.field_type === 'select')
      answers[f.field_name] = f.options?.[0] ?? ''
    else answers[f.field_name] = ''
  })
  failureAnswers.value = answers
}

// Failure tab
const failureResults = ref<any[]>([])
const failureResultsLoading = ref(false)

const loadFailureResults = async () => {
  if (failureResultsLoading.value) return
  failureResultsLoading.value = true
  try {
    const items = await getItems<any>({
      collection: 'Failure_analyze_result',
      params: {
        filter: { wo_id: { _eq: wo_id } },
        limit: -1,
        fields: [
          '*',
          'template_id.id',
          'template_id.name',
          'template_id.fields',
        ],
      },
    })
    failureResults.value = items?.data ?? items ?? []
  } catch (e) {
    console.error(e)
    failureResults.value = []
  } finally {
    failureResultsLoading.value = false
  }
}

// console.log('currentProps', currentProps)
const wo_id = currentProps?.value?.id || null
const wo_data = currentProps?.value?.data || null
const wo_statuses = currentProps?.value?.wo_statuses || wo_status_items
const wo_type = currentProps?.value?.type || null
const refresh = currentProps?.value?.refresh || null
const backBttn = currentProps?.value?.backBttn || false
const active_tab = currentProps?.value?.active_tab || false
const backFn = currentProps?.value?.backFn || false
const onMessage = currentProps?.value?.onMessage || false
const freezeProp = currentProps?.value?.freeze === true

// ── Жагсаалт дотор Next/Prev шилжих ────────────────────────────────────────
// Панелийг нээсэн жагсаалт (жишээ нь workorder/List.vue) одоогийн
// ачаалагдсан бүх мөрөө `list`-ээр дамжуулна. Тэрхүү массив дотор энэ
// wo_id-ийн байрлалыг олоод, дараагийн/өмнөх мөр рүү шилжинэ.
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
  // Анх нээсэн caller (List.vue, AgGridList.vue гэх мэт)-ийн бүх prop-ыг
  // (type, wo_statuses, refresh, backBttn, backFn, freeze, onClose гэх мэт)
  // хадгалж, зөвхөн шинэ мөрд хамаарах хэсгийг нь дарж бичнэ
  open('workorderopenmore', {
    ...(currentProps?.value || {}),
    id: item.id,
    data: item,
    // идэвхтэй байгаа tab-аа хадгалж, шинэ мөр рүү шилжсэний дараа ч
    // яг тухайн tab дээр нь нээгдэнэ
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
    (item) => item?.type?.toLowerCase() === 'open',
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
const tradesKey = ref(1)
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
const group_types = ref([])
const work_order_types = ref([])
const work_order_type = ref([])
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
const woNumberValue = ref<string | number | null>(null)
const selected_group_type = ref({
  value: '',
  label: '',
})
const isModalAssetOpen = ref(false)
const isModalTeamsOpen = ref(false)
const ProgressValue = ref(0)

const isPmGenerated = computed(
  () => work_order.value?.created_type === 'pm_generated',
)
const isPdmGenerated = computed(
  () => work_order.value?.created_type === 'pdm_generated',
)
const isInsGenerated = computed(
  () => work_order.value?.created_type === 'ins_generated',
)
const isExternalSource = computed(
  () => isPmGenerated.value || isPdmGenerated.value || isInsGenerated.value,
)

const woNumberLabel = computed(() => {
  const prefix = work_order.value?.wo_prefix?.toUpperCase()
  if (prefix === 'REQ') return 'REQ Number'
  if (prefix === 'PM') return 'PM Number'
  if (prefix === 'PDM') return 'PDM Number'
  if (prefix === 'INSP') return 'INSP Number'
  if (prefix === 'OPEN') return 'WO Number'

  // fallback to created_type
  const ct = work_order.value?.created_type
  if (ct === 'request') return 'REQ Number'
  if (ct === 'pm_generated') return 'PM Number'
  if (ct === 'pdm_generated') return 'PDM Number'
  if (ct === 'ins_generated') return 'INSP Number'
  return 'WO Number'
})

const itemCollection = computed(() => {
  // if (isPmGenerated.value) return 'Work_pm_item'
  // if (isPdmGenerated.value) return 'Predictive_item'
  // if (isInsGenerated.value) return 'Work_inspection_item'
  return 'Work_order_item'
})
const partsCollection = computed(() => {
  // if (isPmGenerated.value) return 'Work_pm_Parts'
  // if (isPdmGenerated.value) return 'Predictive_Parts'
  // if (isInsGenerated.value) return 'Work_inpection_Parts'
  return 'Work_order_Parts'
})
const tradesCollection = computed(() => {
  // if (isPmGenerated.value) return 'Work_pm_Tradecode'
  // if (isPdmGenerated.value) return 'Predictive_Tradecode'
  // if (isInsGenerated.value) return 'Work_inspection_Tradecode'
  return 'Work_order_Tradecode'
})
const commentsCollection = computed(() => {
  // if (isPmGenerated.value) return 'Work_pm_comments'
  // if (isPdmGenerated.value) return 'Predictive_actions'
  // if (isInsGenerated.value) return 'Work_inspection_comments'
  return 'Work_order_comments'
})
const filesCollection = computed(() => {
  // if (isPmGenerated.value) return 'Work_pm_files'
  // if (isPdmGenerated.value) return 'Predictive_files'
  // if (isInsGenerated.value) return 'Work_inspection_files'
  return 'Work_order_files'
})
let param_id = 0

//print
const pathWithoutId = router.currentRoute.value.path.replace(/\/\d+$/, '')
const printPath = `${pathWithoutId}/print`
const panelScrollContainer = ref<HTMLElement | null>(null)
const tabs = ref([
  { label: t('Tasks'), value: 'tasks' },
  { label: t('Trades'), value: 'trades' },
  { label: t('Parts'), value: 'parts' },
  { label: t('Documents'), value: 'documents' },
  { label: t('Costs'), value: 'costs' },
  { label: t('Actions'), value: 'actions' },
  { label: t('Comments'), value: 'comments' },
  { label: t('Failure'), value: 'failure' },
])
const activeTab = ref(typeof active_tab === 'string' ? active_tab : 'tasks')

if (wo_type == 'request') {
  activeTab.value = 'actions'
  tabs.value = [{ label: t('Actions'), value: 'actions' }]
}

if (!tabs.value.some((item) => item.value === activeTab.value)) {
  activeTab.value = tabs.value[0]?.value || 'tasks'
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

if (wo_type == 'request' && wo_data.type.code_work_order == 'wo') {
  readonly = true
}
// approve bol asset team name grouptype-iig tugjine
if (wo_data.action_status == 2) {
  readonly = true
}

const checkDebtTab = async () => {
  // if (wo_data?.action_status != 2) return
  try {
    const items = await getItems<any>({
      collection: 'Transaction',
      params: {
        filter: {
          _and: [
            { company_id: { _eq: myCompanyId } },
            {
              transaction_type: 'OUTCOME',
              status: { _in: [2] },
              work_order: wo_id,
            },
          ],
        },
        meta: 'filter_count',
        limit: 1,
        fields: ['id'],
      },
    })

    console.log('items', items)
    const count = items?.meta?.filter_count ?? items?.data?.length ?? 0
    if (count > 0 && !tabs.value.some((item) => item.value === 'debt')) {
      tabs.value = [...tabs.value, { label: t('Debt'), value: 'debt' }]
    }
  } catch (e) {
    console.log(e)
  }
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
    5: 'wpf:approval',
  }
  return icons[statusId] || 'healthicons:default'
}

const handleChangeKey = () => {
  console.log('handleChangeKey')
  // key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const loadWorkOrder = async () => {
  try {
    param_id = wo_id
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
          'location.*',
          'work_type.*',
          'department.*',
          'assigned_team.*',
          'template.*',
          'assigned_to.*',
          'assigned_to.role.name',
          'asset.*',
          'asset.location.*',
          'asset.department.*',
          'source_pm.id',
          'source_pm.template_pm.*',
          'source_pdm.id',
          'source_pdm.template_pm.*',
          'source_ins.id',
          'source_ins.template_pm.*',
        ],
      },
    })

    const data = items.data[0]
    work_order.value = data

    // Derive woNumberValue once from raw data — never re-derives reactively
    const _prefix = data?.wo_prefix?.toUpperCase()
    const _ct = data?.created_type
    if (_prefix === 'REQ' || _ct === 'request') {
      woNumberValue.value = data.req_number ?? data.id
    } else if (_prefix === 'PM' || _ct === 'pm_generated') {
      woNumberValue.value =
        data.source_pm?.template_pm?.auto_number ?? data.wo_number ?? data.id
    } else if (_prefix === 'PDM' || _ct === 'pdm_generated') {
      woNumberValue.value =
        data.source_pdm?.template_pm?.auto_number ?? data.wo_number ?? data.id
    } else if (_prefix === 'INSP' || _ct === 'ins_generated') {
      woNumberValue.value =
        data.source_ins?.template_pm?.auto_number ?? data.wo_number ?? data.id
    } else {
      woNumberValue.value = data.wo_number ?? data.id
    }

    // Auto-derive wo_prefix from created_type if missing
    if (!work_order.value.wo_prefix) {
      const prefixMap: Record<string, string> = {
        pm_generated: 'PM',
        pdm_generated: 'PDM',
        ins_generated: 'INSP',
        request: 'REQ',
        open: 'OPEN',
      }
      const derived = prefixMap[work_order.value.created_type]
      if (derived) {
        work_order.value.wo_prefix = derived
        // Persist back to Directus
        updateItem({
          collection: 'Work_order',
          id: wo_id,
          item: { wo_prefix: derived },
        })
      }
    }

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
    department.value = items.data[0].department?.description
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
      collection: itemCollection.value,
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

let intervalId: ReturnType<typeof setInterval> | null = null
let isMounted = false

onUnmounted(() => {
  isMounted = false
  if (intervalId) clearInterval(intervalId)
})

onMounted(async () => {
  loading.value = true
  isMounted = true

  await loadWorkOrder()
  await loadTypes()
  await loadTempTypes()
  await loadGroupTypes()

  // if (work_order.value?.id) {
  //   document.title = `Work order #${work_order.value.id}`;
  // }

  loading.value = false
  if (work_order.value.started_at && work_order.value.due) {
    intervalId = setInterval(updateDates, 1000) // Update every second
  }

  // console.log(' loadTasks.data', loadTasks)
  if (wo_type == 'request') {
    RequestInfo.value = true
    await loadRequestInfo()
  }

  await checkDebtTab()
})

const updateDates = () => {
  if (!isMounted) return
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

    const normS = sDate.value?.substring(0, 10) || null
    const normD = dDate.value?.substring(0, 10) || null
    const normC = cDate.value?.substring(0, 10) || null

    if (
      (normS && normD && normS > normD) ||
      (normS && normC && normS > normC)
    ) {
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

    items = { ...items, [keyName]: event.target.value || null }
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
  console.log(' items ', items)

  const updateData = {
    collection: 'Work_order',
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
    collection: 'Work_order',
    id: wo_id,
    item: { department: item?.id ?? null },
  }
  await updateItem(updateData)
}

function onClick(item, type) {
  let updateData = {}
  if (type == 'priority') {
    updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: { priority: item?.__original ? item.__original : item.value },
    }
  } else if (type == 'wo_status') {
    updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: { wo_status: item.id },
    }
  } else if (type == 'type') {
    // ene group_type huwissagchaar utga awdag shuu
    updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: { type: item.value },
    }
    selected_group_type.value = item
  } else if (type == 'work_type') {
    updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: { work_type: item.value },
    }
    work_order_type.value = item
  }

  updateItem(updateData).then((res) => {
    console.log('done')

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
    collection: 'Work_order',
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
    collection: 'Work_order',
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
        collection: 'Work_order_item',
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
            collection: 'Work_order_item',
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

const loadLocationStatuses = async () => {
  try {
    const locationId =
      work_order.value?.location?.id || work_order.value?.asset?.location?.id

    const filter: any = {
      type: { _in: ['completed', 'close'] },
    }
    if (locationId) {
      filter.location = { _eq: locationId }
    }

    const items = await getItems<any>({
      collection: 'Wo_status',
      params: {
        filter,
        limit: -1,
        fields: ['*'],
      },
    })

    const source =
      items.data.length > 0
        ? items.data
        : wo_statuses.filter((s) =>
            ['completed', 'close'].includes(s?.type?.toLowerCase() ?? ''),
          )
    locationBasedStatuses.value = source.map((s: any) => ({
      ...s,
      name: t(s.status_text || s.name),
    }))
  } catch {
    locationBasedStatuses.value = translatedWoStatuses.value
      .filter((s) =>
        ['completed', 'close'].includes(s?.type?.toLowerCase() ?? ''),
      )
      .map((s: any) => ({ ...s, name: t(s.status_text || s.name) }))
  }
}

const handleComplete = async () => {
  if (sDate.value == null || dDate.value == null) {
    toaster.show({
      title: t('Error'),
      message: 'Please fill in Started date and Due date!',
      color: 'Error',
      icon: 'mdi:alert',
      closable: true,
      duration: 1000,
    })
    return
  }

  completionDateTime.value =
    work_order.value.completed_at?.slice(0, 16) ??
    new Date().toISOString().slice(0, 16)

  await loadLocationStatuses()

  if (
    locationBasedStatuses.value.length > 0 &&
    !selectedCompletionStatus.value
  ) {
    selectedCompletionStatus.value = locationBasedStatuses.value[0]
  }

  isCompletionModalOpen.value = true
}

const isCompleting = ref(false)

const confirmComplete = async () => {
  // Товч дараад хариу ирэхээс өмнө дахин дарахад Work_order update /
  // Work_order_actions create давхар (duplicate) request явахаас сэргийлнэ.
  if (isCompleting.value) return
  isCompleting.value = true
  try {
    await confirmCompleteInternal()
  } finally {
    isCompleting.value = false
  }
}

const confirmCompleteInternal = async () => {
  if (!completionDateTime.value) {
    toaster.show({
      title: t('Error'),
      message: t('Please enter Completed date!'),
      color: 'Error',
      icon: 'mdi:alert',
      closable: true,
      duration: 1000,
    })
    return
  }

  console.log('completionDateTime.value', selectedCompletionStatus.value)
  if (!selectedCompletionStatus.value) {
    toaster.show({
      title: t('Error'),
      message: t('Please select a close status!'),
      color: 'Error',
      icon: 'mdi:alert',
      closable: true,
      duration: 1000,
    })
    return
  }
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

  if (failureAnalysisEnabled.value && selectedFailureTemplate.value) {
    await createItems({
      collection: 'Failure_analyze_result',
      items: {
        wo_id: wo_id,
        template_id: selectedFailureTemplate.value.id,
        answers: failureAnswers.value,
        company_id: myCompanyId,
      },
    })
  }
  cDateTime.value = completionDateTime.value
  cDate.value = completionDateTime.value.substring(0, 10)

  await updateItem({
    collection: 'Work_order',
    id: wo_id,
    item: {
      status: '3',
      wo_status: selectedCompletionStatus.value.id,
      completed_at: completionDateTime.value,
    },
  })

  await createItems({
    collection: 'Work_order_actions',
    items: {
      wo_id: wo_id,
      first_user: myId,
      action_status: 7,
      company_id: myCompanyId,
    },
  })

  isCompletionModalOpen.value = false
  windowClose('bttn')
  router.push(`/workorder/location/completed/${params.id}`)
}

const do_make = async (item, type) => {
  let statuss = 1

  // console.log('do_make_items', item)
  // console.log('cDate', cDate.value)
  // console.log('cDateTime', cDateTime.value)

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
    collection: 'Work_order',
    id: wo_id,
    item: {
      status: '3',
      wo_status: completed_status.id,
      completed_at: cDateTime.value || new Date().toISOString(),
    },
  }
  // console.log('Update', completed_status)

  updateItem(updateData).then((res) => {
    // console.log('Update', work_order)

    const action_log = createItems({
      collection: 'Work_order_actions',
      items: {
        wo_id: wo_id,
        first_user: myId,
        action_status: 7,
        company_id: myCompanyId,
      },
    })

    router.push(`/workorder/location/completed/${params.id}`)
  })
}

const handleModalConfirmClose = () => {
  isModalApproveConfirmOpen.value = false
}

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

const windowClose = async (type) => {
  if (type == 'bttn') close()

  // console.log('ProgressValue', ProgressValue)
  if (ProgressValue.value > 0) {
    // Update work
    updateItem({
      collection: 'Work_order',
      id: wo_id,
      item: {
        wo_percent: ProgressValue.value.toFixed(2),
      },
    })
  }

  // changeFn ajilladag bolhoor ene function duudagdahad l position update hiigdne.
  // Odoo drag hiisen daraa l database ruu update hiine.
  // Ene ni deerh changePos function dotorh code-g comment hiisen hesegt bga.

  // for (
  //   let parentIndex = 0;
  //   parentIndex < transformedPos.value.length;
  //   parentIndex++
  // ) {
  //   const parent = transformedPos.value[parentIndex]

  //   // Update parent
  //   updateItem({
  //     collection: 'Work_order_item',
  //     id: parent.id,
  //     item: {
  //       pos: parentIndex,
  //       parent: null,
  //     },
  //   })

  //   // console.log('parent', parent)

  //   // Update children
  //   for (
  //     let childIndex = 0;
  //     childIndex < parent.children.length;
  //     childIndex++
  //   ) {
  //     const child = parent.children[childIndex]

  //     updateItem({
  //       collection: 'Work_order_item',
  //       id: child.id,
  //       item: {
  //         parent: parent.id,
  //         pos: childIndex,
  //       },
  //     })
  //   }
  // }
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

const printClicked = async () => {
  const filters = { active: 1 }
  const items = await getItems<any>({
    collection: 'Prints_tempates',
    params: {
      filter: filters,
      limit: 1,
      meta: 'filter_count',
      fields: ['*', 'uploaded.*'],
    },
  })
  console.log('Templates loaded:', items.data)

  if (items.data.length == 0) {
    console.log('Loading template from:', printPath)

    open('print_single', {
      wo_id: wo_id,
      work_order: work_order.value,
      progress_data: progress_data.value,
      wo_statuses: wo_statuses,
      wo_type: wo_type,
      refresh: refresh,
    })
  } else {
    open('print', {
      wo_id: wo_id,
      work_order: work_order,
      progress_data: progress_data,
      wo_statuses: wo_statuses,
      wo_type: wo_type,
      refresh: refresh,
    })
  }
}
</script>

<template>
  <div
    ref="panelScrollContainer"
    class="WorkOrderOpenMoreClss nui-slimscroll border-muted-200 dark:border-muted-700 dark:bg-muted-800 h-full max-h-screen border bg-white w-[80%] overflow-y-auto overscroll-contain"
  >
    <!-- Close -->
    <div class="flex h-16 w-full items-center justify-start px-5 more">
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

      <div class="w-full taskNumber flex justify-between flex-1">
        <div
          class="flex flex-start font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white m-[10px]"
        >
          <template v-if="wo_type === 'request'">
            REQ #{{ work_order.req_number ?? work_order.id }}
          </template>
          <template v-else>
            WO #{{ work_order.wo_number ?? work_order.id }}
          </template>
          <!-- <p :style="{ color: 'red' }">#{{ item_id }}</p> -->
        </div>
        <div
          class="w-[180px] flex items-baseline justify-start items-center font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white flex-shrink-0"
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
          <BaseHeading
            as="h3"
            size="2xl"
            weight="bold"
            class="items-center capitalize"
          >
            <PriorityCell
              fieldName="action_status"
              :value="wo_data.action_status"
            />
          </BaseHeading>
        </div>
      </div>
    </div>

    <div class="relative work_order_more">
      <!-- First Row -->
      <div class="grid grid-cols-5 gap-4 wo_more px-8 py-2">
        <!-- Left: wo_number + WO Name -->
        <div class="col-span-3 grid grid-cols-3 gap-x-4 items-end">
          <div class="flex flex-col gap-1 wo_number_badge_wrapper">
            <FormKit
              :label="woNumberLabel"
              name="wo_number_badge"
              type="text"
              :model-value="'#' + (woNumberValue ?? '—')"
              :disabled="true"
              :classes="{
                input: 'wo_input wo_name',
                outer: 'wo_wrapper woname_wrapper',
                label: 'woname_label',
              }"
            />
          </div>
          <!-- <div class="flex flex-col gap-1">
            <span class="wo_label">{{ woNumberLabel }}</span>
            <div class="wo_number_badge">
              <span v-if="work_order.wo_prefix" class="wo_prefix_tag">
                {{ work_order.wo_prefix }}
              </span>

              <span class="wo_number_val">
                {{ '—' + (woNumberValue ?? '—') }}
              </span>
            </div>
          </div> -->
          <!-- WO Name -->
          <div class="col-span-2">
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
        <div class="col-span-2 flex items-end gap-1">
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

      <div class="grid grid-cols-5 gap-4 wo_more px-8" v-if="!loading">
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
                :disabled="wo_data.wo_status.id === 3 ? true : false"
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
                :label="t('Due date')"
                name="due"
                type="datetime-local"
                v-model="work_order.due"
                :disabled="wo_data.wo_status.id === 3 ? true : false"
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
                :disabled="[5, 3].includes(wo_data.wo_status.id) ? true : false"
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
              :collection="itemCollection"
            />
          </div>
        </div>

        <!--  acceptInfo -->
        <div
          class="col-span-5 custom-style-wrapper"
          v-if="work_order.accept_info"
        >
          <div class="w-full">
            <AcceptInfoItem :accept_info="work_order.accept_info" />
          </div>
        </div>

        <!--  Description -->
        <div class="col-span-5 custom-style-wrapper">
          <div class="w-full">
            <FormKit
              v-model="work_order.history_description"
              :label="t('Description')"
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
              :label="t('Safety Notes')"
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
            class="tabs"
            :tabs="tabs"
            @update:model-value="handleTabChange"
          >
            <template #tab="{ activeValue }">
              <div
                v-if="activeValue === 'tasks'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderitemTree
                  :loadTasks="loadTasks"
                  @update:loadTasks="handleTasksUpdate"
                  :changePos="changePos"
                  :code="wo_id"
                  :key="key"
                  :refresh="handleChangeKey"
                  :progress="handleProgress"
                  :freeze="freezeProp || isExternalSource"
                  :TempTypes="temp_types"
                  :collection="itemCollection"
                />
              </div>

              <div
                v-else-if="activeValue === 'trades'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderTrades
                  :key="tradesKey"
                  :estimated_edit="work_order.action_status == 2 ? false : true"
                  :actual_edit="work_order.action_status == 2 ? true : false"
                  :work_order="work_order"
                  :freeze="freezeProp || work_order.action_status == 2"
                  :collection="tradesCollection"
                />
              </div>

              <div
                v-else-if="activeValue === 'parts'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderParts
                  :estimated_edit="work_order.action_status == 2 ? false : true"
                  :actual_edit="work_order.action_status == 2 ? false : true"
                  :work_order="work_order"
                  :loadedParts="loadedParts"
                  @update:loadedParts="handlePartsUpdate"
                  :action_status="work_order.action_status"
                  :freeze="freezeProp || work_order.action_status == 2"
                  :collection="partsCollection"
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
                  :action_status="work_order.action_status"
                  :freeze="freezeProp || work_order.action_status == 2"
                  :collection="filesCollection"
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
                  :loadCostsPart="loadCostsPart"
                  :loadCostsTrades="loadCostsTrades"
                  @update:loadCostsPart="handleCostsUpdate"
                  @update:loadCostsTrades="handleTradesUpdate"
                  :action_status="work_order.action_status"
                  :freeze="freezeProp || work_order.action_status == 2"
                  :parts_collection="partsCollection"
                  :trades_collection="tradesCollection"
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

              <div
                v-else-if="activeValue === 'failure'"
                class="font-sans text-sm"
              >
                <FailureAnalysisTab :wo-id="wo_id" />
              </div>

              <div
                v-else-if="activeValue === 'debt'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <Debt :work_order="work_order" />
              </div>
            </template>
          </BaseTabs>
          <br />
          <div class="mt-[20px] mb-[80px]" v-if="showBttn">
            <BaseButton
              color="danger"
              v-if="wo_data.action_status == 2 && wo_data.wo_status.id != 3"
              @click="handleComplete"
              >{{ t('Work order complete') }}</BaseButton
            >
            <BaseButton color="primary" class="ml-5" @click="printClicked()">
              {{ t('Print') }}</BaseButton
            >
          </div>
        </div>
      </div>

      <!-- <div class="col-span-12" v-if="loading">
        <BasePlaceload class="h-4 w-full rounded" />
      </div> -->
    </div>
    <!-- Completion Modal -->
    <TairoModal
      :open="isCompletionModalOpen"
      size="md"
      @close="() => {}"
      class="overflow-y-auto"
    >
      <template #header>
        <div class="flex w-full items-center justify-between">
          <h3
            class="font-heading text-muted-900 dark:text-white text-base font-medium leading-6"
          >
            {{ t('Complete Work Order') }}
          </h3>
          <BaseButtonClose @click="isCompletionModalOpen = false" />
        </div>
      </template>

      <div class="p-4 md:p-6 space-y-5 Analysis">
        <FormKit
          :label="t('Completed Date')"
          name="completion_datetime"
          type="datetime-local"
          v-model="completionDateTime"
          :classes="{
            input: 'wo_input w-full',
            outer: 'wo_wrapper',
            label: 'wo_label',
          }"
        />
        <BaseListbox
          :label="t('Close Status')"
          :items="locationBasedStatuses"
          :model-value="selectedCompletionStatus"
          :properties="{
            value: 'id',
            label: 'name',
            icon: 'icon',
          }"
          size="md"
          rounded="md"
          @update:model-value="selectedCompletionStatus = $event"
        />
        <!-- Failure Analysis -->
        <div class="flex items-center justify-between">
          <span
            class="text-sm font-medium text-muted-700 dark:text-muted-300"
            >{{ t('Failure Analysis') }}</span
          >
          <BaseSwitchThin v-model="failureAnalysisEnabled" color="primary" />
        </div>
        <div v-if="failureAnalysisEnabled" class="space-y-3">
          <div>
            <label class="wo_label block mb-1 text-xs">{{
              t('Failure Analyze Template')
            }}</label>
            <button
              type="button"
              class="w-full text-left border border-muted-300 dark:border-muted-600 rounded-md px-3 py-2 text-sm bg-white dark:bg-muted-800 hover:border-primary-400 transition-colors flex items-center justify-between"
              @click="isFailureTemplateModalOpen = true"
            >
              <span
                v-if="selectedFailureTemplate"
                class="text-muted-900 dark:text-white"
                >{{ selectedFailureTemplate.name }}</span
              >
              <span v-else class="text-muted-400">Select template...</span>
              <Icon name="lucide:chevron-right" class="size-4 text-muted-400" />
            </button>
          </div>
          <!-- Inline fields -->
          <template
            v-if="selectedFailureTemplate"
            v-for="field in parseFields(selectedFailureTemplate.fields)"
            :key="field.field_name"
          >
            <div>
              <label
                class="wo_label block mb-1 text-xs font-medium text-muted-700 dark:text-muted-300"
              >
                {{ field.field_name }}
                <span
                  v-if="field.description"
                  class="text-muted-400 font-normal ml-1"
                  >({{ field.description }})</span
                >
              </label>
              <!-- number -->
              <BaseInput
                v-if="field.field_type === 'number'"
                v-model="failureAnswers[field.field_name]"
                type="number"
                rounded="md"
                :placeholder="field.field_name"
                class="border rounded-md"
              />
              <!-- text -->
              <BaseTextarea
                v-else-if="field.field_type === 'text'"
                v-model="failureAnswers[field.field_name]"
                rounded="md"
                :placeholder="field.field_name"
                rows="2"
                class="border rounded-md"
              />
              <!-- yes_no -->
              <div v-else-if="field.field_type === 'yes_no'" class="flex gap-3">
                <BaseButton
                  v-for="opt in field.options?.length
                    ? field.options
                    : ['Yes', 'No']"
                  :key="opt"
                  :color="
                    failureAnswers[field.field_name] === opt
                      ? 'primary'
                      : 'default'
                  "
                  rounded="md"
                  size="sm"
                  class="text-sm"
                  @click="failureAnswers[field.field_name] = opt"
                  >{{ opt }}</BaseButton
                >
              </div>
              <!-- select -->
              <BaseListbox
                v-else-if="field.field_type === 'select'"
                :items="field.options ?? []"
                :model-value="failureAnswers[field.field_name]"
                rounded="md"
                @update:model-value="failureAnswers[field.field_name] = $event"
              />
              <!-- date_time -->
              <FormKit
                v-else-if="field.field_type === 'date_time'"
                type="datetime-local"
                v-model="failureAnswers[field.field_name]"
                :classes="{
                  input: 'wo_input w-full',
                  outer: 'wo_wrapper',
                  label: 'hidden',
                }"
              />
            </div>
          </template>
        </div>
      </div>

      <template #footer>
        <div class="flex justify-end gap-2 p-4 md:p-6">
          <BaseButton rounded="md" @click="isCompletionModalOpen = false">
            {{ t('Cancel') }}
          </BaseButton>
          <BaseButton
            color="danger"
            rounded="md"
            :disabled="isCompleting"
            @click="confirmComplete"
          >
            {{ t('Confirm Complete') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>

    <!-- Failure Analyze Template Modal -->
    <ModalItemsList
      :open="isFailureTemplateModalOpen"
      :header="[
        { title: t('Name'), key: 'name', align: 'start', width: '35%' },
        { title: t('Description'), key: 'description', align: 'start' },
        {
          title: t('Action'),
          key: 'action',
          align: 'center',
          sortable: false,
          width: '15%',
        },
      ]"
      :close="
        () => {
          isFailureTemplateModalOpen = false
        }
      "
      :setItem="(item) => openFailureForm(item)"
      :title="t('Failure Analyze Templates')"
      collection="Failure_analyze_template"
      fields="id, name, description, fields"
      :filter="{ status: { _eq: 'published' } }"
    />
    <!--Asset Modal-->
    <ModalAssetsList
      :open="isModalAssetOpen"
      :close="handleModalAssetClose"
      :setAsset="setAsset"
      :location="Number(params.id)"
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
      :location="params.id"
      :title="t('Teams')"
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
/* .WorkOrderOpenMoreClss {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.WorkOrderOpenMoreClss::-webkit-scrollbar {
  display: none;
} */

.work_order_more .wo_wrapper .vs__dropdown-menu {
  width: fit-content !important;
}
.work_order_more .nui-listbox .nui-listbox-option {
  padding: 0px !important;
}
.work_order_more .wo_input,
.work_order_more .department .vs__dropdown-toggle {
  height: 40px !important;
  font-size: 13px !important;
}
.work_order_more .woname_wrapper {
  max-width: 95% !important;
}
.work_order_more .woname_label {
  font-size: 11px !important;
  font-weight: 500 !important;
  color: #6b7280 !important;
}
.custom-style-wrapper .max-w-md {
  max-width: none !important;
  width: 100% !important;
}

.work_order_more .priority_action .nui-avatar .nui-avatar-img {
  object-fit: scale-down;
}

/* Unified label size across all columns */
.work_order_more .bttns_action .wo_label,
.work_order_more .wo_label,
.work_order_more .nui-listbox-label,
.work_order_more .formkit-label {
  display: block;
  font-size: 11px !important;
  font-weight: 500 !important;
  color: #6b7280 !important;
  margin-bottom: 2px !important;
}

/* Unified input value font size */
.work_order_more .wo_input,
.work_order_more .nui-listbox-button,
.work_order_more .vs__selected,
.work_order_more .vs__search,
.work_order_more .department .vs__selected-options,
.work_order_more input[type='datetime-local'] {
  font-size: 13px !important;
}

/* Remove extra spacing from FormKit/BaseListbox wrappers for row alignment */
.work_order_more .wo_wrapper {
  margin-bottom: 0 !important;
}
.work_order_more .priority_action .nui-listbox,
.work_order_more .grid .nui-listbox {
  margin-bottom: 0 !important;
}

/* Date inputs narrower */
.work_order_more .date_action .wo_input {
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
</style>
