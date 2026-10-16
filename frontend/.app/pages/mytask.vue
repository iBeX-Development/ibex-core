<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
import {
  completed_status_ids,
  open_status_ids,
} from '~/components/workorder/WorkOrderStatus'
// import DynamicModalForm from '~/components/form/DynamicModalForm.vue'
const user = useDirectusUser()
const config = useRuntimeConfig()

const { t } = useI18n({ useScope: 'global' })
const router = useRouter()

const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const myId = window.localStorage.getItem('myId')

// "/mytask/*" доорх бүх nav item (Tasks-ийн 3 дэд tab + Assign/
// Inspections/Teams/Projects/Equipments)-ын тоог header дээр "|"-ээр
// зааглаж харуулна (өмнө нь "31" гэсэн hardcode-логдсон нэг тоо байсан).
// mytask.vue нь аль ч дэд route идэвхтэй байгаагаас үл хамааран эцэг
// байдлаараа үргэлж mount хийгддэг цорын ганц компонент тул энд төвлөрүүлж
// тооцно — эс тэгвэл жишээ нь /mytask/wallet дээр шууд орсон хэрэглэгчид
// index.vue mount хийгдээгүй тул tab1/2/3 тоо хэзээ ч ирэхгүй байх байсан.
const myTaskTabCounts = useMyTaskTabCounts()

const countOf = async (collection: string, filter: any) => {
  try {
    const res = await getItems({
      collection,
      params: { filter, aggregate: { count: '*' } },
    })
    return Number(res?.[0]?.count ?? 0)
  } catch (e) {
    console.log(`countOf(${collection}) error`, e)
    return 0
  }
}

// mytask/index.vue-ийн buildTabFilters()-той АДИЛХАН логик — тэнд
// жагсаалт татахад, энд зөвхөн толгойн тоонд ашиглана.
const buildTaskFilters = (tabKey: string, teamIds: number[]) => {
  let filters: any = {
    active: '1',
    company_id: myCompanyId,
    action_status: { _in: [2] },
    assigned_team: { _in: teamIds },
  }

  if (tabKey == 'tab-2') filters.wo_status = { _in: completed_status_ids }
  if (tabKey == 'tab-1') filters.wo_status = { _in: open_status_ids }
  if (tabKey == 'tab-3') {
    filters.request_user = { _null: false }
    filters.created_type = 'request'
    filters.wo_status = { _in: open_status_ids }
    filters.action_status = { _in: [1, 6] }
    delete filters.assigned_team
  }

  return filters
}

// teams.vue/mytask/index.vue-ийн адилхан "надад харьяалагдах багийн ID"
// тооцоолол — гишүүн эсвэл ахлагчаар нь орсон бүх Teams.id
const loadMyTeamIds = async (): Promise<number[]> => {
  const filters_member = { directus_users_id: { _in: [myId] } }
  const [memberItems, leaderItems] = await Promise.all([
    getItems({
      collection: 'Teams_directus_users',
      params: { filter: filters_member, meta: 'filter_count', fields: ['*'] },
    }),
    getItems({
      collection: 'Teams_directus_users_1',
      params: { filter: filters_member, meta: 'filter_count', fields: ['*'] },
    }),
  ])

  return [
    ...new Set<number>([
      ...(memberItems.data?.map((item: any) => item.Teams_id) || []),
      ...(leaderItems.data?.map((item: any) => item.Teams_id) || []),
    ]),
  ]
}

// inspection.vue-ийн адилхан "надад харьяалагдах Work_inspections.id"
// тооцоолол, дараа нь тэдгээрийн (нээлттэй+дууссан) нийт тоо
const loadInspectionCount = async () => {
  const memberRes = await getItems({
    collection: 'Work_inspection_users',
    params: {
      filter: { user: { _in: [myId] } },
      meta: 'filter_count',
      fields: ['*'],
    },
  })
  const myWorksIds = [
    ...new Set<number>(
      memberRes.data?.map((item: any) => item.work_order) || [],
    ),
  ]

  const filters: any = {
    active: '1',
    pm_type: { _in: ['delivered', 'generated'] },
    company_id: { _eq: myCompanyId },
    wo_status: { _in: [...open_status_ids, ...completed_status_ids] },
  }
  if (myWorksIds.length) filters.id = { _in: myWorksIds }

  return countOf('Work_inspections', filters)
}

const loadHeaderCounts = async () => {
  try {
    const teamIds = await loadMyTeamIds()
    const teamIdsForFilter = teamIds.length ? teamIds : [0]

    // wallet.vue ("My Assign")-ийн адилхан filter — 4 collection дээр
    // (Work_order/Work_pm/Work_inspections/Predictive) надад оноогдсон
    // (assigned_to=миний ID, action_status=4 буюу "assigned") бичлэгүүд
    const assignFilter = {
      assigned_to: myId,
      action_status: 4,
      active: '1',
    }

    const [
      tab1,
      tab2,
      tab3,
      assignWo,
      assignPm,
      assignInsp,
      assignPdm,
      inspectionCount,
      teamsCount,
      projectsCount,
      equipmentsCount,
    ] = await Promise.all([
      countOf('Work_order', buildTaskFilters('tab-1', teamIdsForFilter)),
      countOf('Work_order', buildTaskFilters('tab-2', teamIdsForFilter)),
      countOf('Work_order', buildTaskFilters('tab-3', teamIdsForFilter)),
      countOf('Work_order', assignFilter),
      countOf('Work_pm', assignFilter),
      countOf('Work_inspections', assignFilter),
      countOf('Predictive', assignFilter),
      loadInspectionCount(),
      countOf('Teams', {
        active: 1,
        id: { _in: teamIdsForFilter },
        company_id: { _eq: myCompanyId },
      }),
      countOf('Projects', {
        active: 1,
        state: { _in: [0, 1, 3] },
        company_id: myCompanyId,
      }),
      countOf('Assets', {
        assigned_user: { _eq: myId },
        status: { _eq: '1' },
      }),
    ])

    myTaskTabCounts.value = {
      tab1,
      tab2,
      tab3,
      wallet: assignWo + assignPm + assignInsp + assignPdm,
      inspection: inspectionCount,
      teams: teamsCount,
      projects: projectsCount,
      equipments: equipmentsCount,
    }
  } catch (e) {
    console.log('loadHeaderCounts error', e)
  }
}

onMounted(() => {
  loadHeaderCounts()
})

definePageMeta({
  title: 'My Activity',
  preview: {
    title: 'Activity',
    description: 'For personal usage and reports',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-personal-2.png',
    srcDark: '/img/screens/dashboards-personal-2-dark.png',
    order: 2,
  },
})

const areaTaskCompletion = reactive(useAreaTaskCompletion())
const barTeamEfficiency = reactive(useBarTeamEfficiency())

function useAreaTaskCompletion() {
  const { primary, info, success } = useTailwindColors()
  const type = 'area'
  const height = 295

  const options = {
    chart: {
      toolbar: {
        show: false,
      },
    },
    colors: [success.value, info.value, primary.value],
    legend: {
      position: 'top',
    },
    dataLabels: {
      enabled: false,
    },
    stroke: {
      width: [2, 2, 2],
      curve: 'smooth',
    },
    xaxis: {
      type: 'datetime',
      categories: [
        '2020-09-19T00:00:00.000Z',
        '2020-09-20T01:30:00.000Z',
        '2020-09-21T02:30:00.000Z',
        '2020-09-22T03:30:00.000Z',
        '2020-09-23T04:30:00.000Z',
        '2020-09-24T05:30:00.000Z',
        '2020-09-25T06:30:00.000Z',
      ],
    },
    tooltip: {
      x: {
        format: 'dd/MM/yy HH:mm',
      },
    },
  }

  const series = shallowRef([
    {
      name: 'Pending',
      data: [31, 40, 28, 51, 42, 109, 100],
    },
    {
      name: 'Completed',
      data: [11, 32, 45, 32, 34, 52, 41],
    },
    {
      name: 'Blocked',
      data: [78, 53, 36, 10, 14, 5, 2],
    },
  ])

  return {
    type,
    height,
    options,
    series,
  }
}

function useBarTeamEfficiency() {
  const { primary, info, success } = useTailwindColors()
  const type = 'bar'
  const height = 250

  const options = {
    chart: {
      toolbar: {
        show: false,
      },
    },
    colors: [success.value, info.value, primary.value],
    legend: {
      position: 'top',
    },
    plotOptions: {
      bar: {
        horizontal: false,
        endingShape: 'rounded',
        columnWidth: '55%',
      },
    },
    dataLabels: {
      enabled: false,
    },
    stroke: {
      show: true,
      width: 2,
      colors: ['transparent'],
    },
    xaxis: {
      categories: [
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
      ],
    },
    yaxis: {
      labels: {
        formatter: function (val: string) {
          return val + 70
        },
      },
    },
    fill: {
      opacity: 1,
    },
    tooltip: {
      y: {
        formatter: function (val: string) {
          return val + 'hrs'
        },
      },
    },
  }

  const series = shallowRef([
    {
      name: 'Design',
      data: [-26, -15, -13, -14, -9, -12, -7, -10, -4],
    },
    {
      name: 'Development',
      data: [6, 15, 31, 28, 17, 35, 21, 44, 24],
    },
    {
      name: 'Management',
      data: [-35, -29, -34, -44, -25, -22, -18, -17, -29],
    },
  ])

  return {
    type,
    height,
    options,
    series,
  }
}

const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)

// Modal new & edit form
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const key = ref(1)
const key_update_modal = ref(-2)

const toaster = useToaster()

const loadItems = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array = []
  sortBy.map((sort_object) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })
  loading.value = true
  try {
    const filters = {
      active: 1,
    }
    const items = await getItems<any>({
      collection: 'mytask',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: [
          '*',
          'team_leaders.directus_users_id.first_name',
          'team_leaders.directus_users_id.avatar',
          'team_leaders.directus_users_id.id',
          'users.*',
          'users.directus_users_id.first_name',
          'users.directus_users_id.avatar',
          'users.directus_users_id.id',
        ],
      },
    })
    serverItems.value = items.data
    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
  // console.log('isModalOpen', isModalOpen.value)
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log(isModalOpen.value)
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const do_edit = (item) => {
  console.log('Team : ', item)
  console.log('Team : ', item)
  // Perform your action here
  selectedItem.value = item
  console.log(selectedItem.value)
  isModalOpen.value = true
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleChangeModalKey = () => {
  selectedItem.value = -1
}

const clearItem = () => {
  selectedItem.value = -1
}

const moremytask = () => {
  console.log('moremytask')
  router.push(`/mytask/more`)
}
// console.log('user', user)
</script>

<template>
  <div class="w-full px-4 md:px-6 lg:px-8 pb-20">
    <div class="w-full mt-4">
      <BaseCard class="p-5">
        <div class="flex flex-col items-center md:flex-row">
          <div
            class="ltablet:flex-row ltablet:items-center flex flex-col items-center gap-4 text-center md:items-start md:text-left lg:flex-row lg:items-center"
          >
            <BaseAvatar
              :src="
                user?.avatar
                  ? `${config.public.directus.url}assets/${user.avatar}`
                  : '/img/avatars/2.svg'
              "
              size="xl"
            />
            <div class="text-center md:text-left">
              <BaseHeading
                as="h2"
                size="xl"
                weight="light"
                lead="tight"
                class="text-muted-800 dark:text-white"
              >
                <span>{{ t('Welcome ' + user?.first_name) }}</span>
              </BaseHeading>
              <BaseParagraph>
                <span class="text-muted-400"> {{ user?.email }}</span>
              </BaseParagraph>
            </div>
          </div>

          <div
            class="ltablet:flex-row ltablet:items-center ms-auto flex flex-col gap-6 text-center md:text-left lg:flex-row lg:items-center"
          >
            <div class="flex-1 items_count">
              <BaseHeading
                as="h3"
                size="xl"
                weight="semibold"
                lead="tight"
                class="text-muted-800 dark:text-white"
              >
                <span
                  class="flex flex-wrap items-center justify-center gap-2 md:justify-start"
                >
                  <span
                    >{{ myTaskTabCounts.tab1 ?? '…' }}
                    <small class="text-xs font-medium text-muted-400">{{
                      t('List')
                    }}</small></span
                  >
                  <span class="text-muted-300 dark:text-muted-600">|</span>
                  <span
                    >{{ myTaskTabCounts.tab2 ?? '…' }}
                    <small class="text-xs font-medium text-muted-400">{{
                      t('Completed')
                    }}</small></span
                  >
                  <span class="text-muted-300 dark:text-muted-600">|</span>
                  <span
                    >{{ myTaskTabCounts.tab3 ?? '…' }}
                    <small class="text-xs font-medium text-muted-400">{{
                      t('Request')
                    }}</small></span
                  >
                  <span class="text-muted-300 dark:text-muted-600">|</span>
                  <span
                    >{{ myTaskTabCounts.wallet ?? '…' }}
                    <small class="text-xs font-medium text-muted-400">{{
                      t('Assign')
                    }}</small></span
                  >
                  <span class="text-muted-300 dark:text-muted-600">|</span>
                  <span
                    >{{ myTaskTabCounts.inspection ?? '…' }}
                    <small class="text-xs font-medium text-muted-400">{{
                      t('Inspections')
                    }}</small></span
                  >
                  <span class="text-muted-300 dark:text-muted-600">|</span>
                  <span
                    >{{ myTaskTabCounts.teams ?? '…' }}
                    <small class="text-xs font-medium text-muted-400">{{
                      t('Teams')
                    }}</small></span
                  >
                  <span class="text-muted-300 dark:text-muted-600">|</span>
                  <span
                    >{{ myTaskTabCounts.projects ?? '…' }}
                    <small class="text-xs font-medium text-muted-400">{{
                      t('Projects')
                    }}</small></span
                  >
                  <span class="text-muted-300 dark:text-muted-600">|</span>
                  <span
                    >{{ myTaskTabCounts.equipments ?? '…' }}
                    <small class="text-xs font-medium text-muted-400">{{
                      t('Equipments')
                    }}</small></span
                  >
                </span>
              </BaseHeading>
            </div>
            <!-- <div class="relative z-20 flex flex-col gap-3">
              <BaseButton @click="handleModalOpen">
                <Icon name="mynaui:plus" class="-ms-1 h-4 w-4" />
                <span class="text-[11px]">{{ $t('Team add') }}</span>
              </BaseButton>
            </div> -->
          </div>
        </div>
      </BaseCard>
    </div>

    <div class="mt-8">
      <div class="w-full overflow-x-auto pb-1">
        <div class="border-muted-300 dark:border-muted-800 border-b">
          <nav class="-mb-px flex space-x-10">
            <NuxtLink
              to="/mytask"
              exact-active-class="!border-primary-500 !text-primary-500"
              class="text-muted-400 hover:text-muted-800 dark:text-muted-500 dark:hover:text-muted-100 hover:border-muted-300 dark:hover:border-muted-700 whitespace-nowrap border-b-2 border-transparent py-4 text-sm font-medium transition-all duration-200"
            >
              {{ t('My tasks') }}
            </NuxtLink>
            <NuxtLink
              to="/mytask/wallet"
              class="text-muted-400 hover:text-muted-800 dark:text-muted-500 dark:hover:text-muted-100 hover:border-muted-300 dark:hover:border-muted-700 whitespace-nowrap border-b-2 border-transparent py-4 text-sm font-medium transition-all duration-200"
              exact-active-class="!border-primary-500 !text-primary-500"
            >
              {{ t('My Assign') }}
            </NuxtLink>
            <NuxtLink
              to="/mytask/inspection"
              exact-active-class="!border-primary-500 !text-primary-500"
              class="text-muted-400 hover:text-muted-800 dark:text-muted-500 dark:hover:text-muted-100 hover:border-muted-300 dark:hover:border-muted-700 whitespace-nowrap border-b-2 border-transparent py-4 text-sm font-medium transition-all duration-200"
            >
              {{ t('My inspections') }}
            </NuxtLink>
            <NuxtLink
              to="/mytask/teams"
              class="text-muted-400 hover:text-muted-800 dark:text-muted-500 dark:hover:text-muted-100 hover:border-muted-300 dark:hover:border-muted-700 whitespace-nowrap border-b-2 border-transparent py-4 text-sm font-medium transition-all duration-200"
              exact-active-class="!border-primary-500 !text-primary-500"
            >
              {{ t('My teams') }}
            </NuxtLink>
            <NuxtLink
              to="/mytask/projects"
              class="text-muted-400 hover:text-muted-800 dark:text-muted-500 dark:hover:text-muted-100 hover:border-muted-300 dark:hover:border-muted-700 whitespace-nowrap border-b-2 border-transparent py-4 text-sm font-medium transition-all duration-200"
              exact-active-class="!border-primary-500 !text-primary-500"
            >
              {{ t('My projects') }}
            </NuxtLink>
            <NuxtLink
              to="/mytask/equipments"
              class="text-muted-400 hover:text-muted-800 dark:text-muted-500 dark:hover:text-muted-100 hover:border-muted-300 dark:hover:border-muted-700 whitespace-nowrap border-b-2 border-transparent py-4 text-sm font-medium transition-all duration-200"
              exact-active-class="!border-primary-500 !text-primary-500"
            >
              {{ t('My equipments') }}
            </NuxtLink>
          </nav>
        </div>
      </div>

      <div>
        <NuxtPage />
      </div>
    </div>
  </div>
</template>
