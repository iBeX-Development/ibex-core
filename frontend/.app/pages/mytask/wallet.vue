<script setup lang="ts">
definePageMeta({
  title: 'My Assign',
  preview: {
    title: 'Course dashboard',
    description: 'For School and Education',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-course.png',
    srcDark: '/img/screens/dashboards-course-dark.png',
    order: 13,
  },
})

import TaskCardGrid from '~/components/mytask/TaskCardGrid.vue'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'
import { sendNotification } from '~/compsables/sendNotification'
const myId = window.localStorage.getItem('myId')

const route = useRoute()
const router = useRouter()
const page = computed({
  get: () => Number.parseInt((route.query.page as string) ?? '1', 10),
  set: (value) => {
    router.push({
      query: {
        ...route.query,
        page: value,
      },
    })
  },
})

const filter = ref('')
const perPage = ref(10)
const active_tab = ref('tab-1')
const active_sub_tab = ref('wo')
const refreshKey = ref(0)
const toaster = useToaster()

import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const subTabs = [
  { key: 'wo', label: t('Work Order') },
  { key: 'pm', label: t('Preventative Maintenance') },
  { key: 'insp', label: t('Inspection') },
  { key: 'pdm', label: t('Predictive') },
]

const { params } = useRoute()
const teams = ref([])
const work_order = ref({})
const { open } = usePanels()

const { getItems, createItems, updateItem, deleteItems } = useDirectusItems()
const { getUsers } = useDirectusUsers()
const myCompanyId = getMyCompanyId()
const loading = ref(true)
const works = ref([])
const key = ref(1)
const timeout = ref(null)
const isModalUserListOpen = ref(false)
const currentRecord = ref(null)

const courses = [
  {
    title: t('ANA118 - Anatomy and physiology of young subjects'),
    description: t(
      'This week features a deeper approach of young subject anatomy and basic physiological properties. It also focuses on the latest released articles',
    ),
    category: t('Anatomy'),
    week: 6,
    duration: 120,
    comments: 25,
    time: '10:00 - 12:00',
    date: 'Feb 3, 2023',
    students: [
      {
        tooltip: 'Clark Smith',
        src: '/img/avatars/3.svg',
      },
      {
        tooltip: 'Maya Rosselini',
        src: '/img/avatars/2.svg',
      },
      {
        tooltip: 'Clarissa Miller',
        src: '/img/avatars/5.svg',
      },
      {
        tooltip: 'Jane Doe',
        src: '/img/avatars/4.svg',
      },
    ],
  },
  {
    title: t('IMM107 - Immunology and treatment of human disease'),
    description: t(
      'This unit has a strong focus on significal clinical problems in immunology and the scientific background to these problems',
    ),
    category: t('Immunology'),
    week: 6,
    duration: 90,
    comments: 12,
    time: '9:00 - 10:30',
    date: 'Feb 7, 2023',
    students: [
      {
        tooltip: 'Anna Vorsky',
        src: '/img/avatars/12.svg',
      },
      {
        tooltip: 'Hermann Mayer',
        src: '/img/avatars/16.svg',
      },
      {
        tooltip: 'Eddie Johnson',
        src: '/img/avatars/8.svg',
      },
      {
        tooltip: 'Jane Doe',
        src: '/img/avatars/14.svg',
      },
    ],
  },
  {
    title: t('CAR112 - Cardiovascular Metabolic Management'),
    description: t(
      'This unit has a strong focus on significal clinical problems in immunology and the scientific background to these problems',
    ),
    category: t('Cardiology'),
    week: 6,
    duration: 120,
    comments: 7,
    time: '2:00 - 4:00',
    date: 'Feb 7, 2023',
    students: [
      {
        tooltip: 'Troy Baker',
        src: '/img/avatars/15.svg',
      },
      {
        tooltip: 'Alan Baxter',
        src: '/img/avatars/11.svg',
      },
      {
        tooltip: 'Eric Klaus',
        src: '/img/avatars/7.svg',
      },
      {
        tooltip: 'Jane Doe',
        src: '/img/avatars/17.svg',
      },
    ],
  },
]

const parts_sum = ref(0.0)
const actual_parts_sum = ref(0.0)
const trades_sum = ref(0.0)
const actual_trades_sum = ref(0.0)

// Work_order-той адилаар assigned_to=myId-ээр надад оноогдсон Work_pm,
// Work_inspections, Predictive-ийг ч бас нэг жагсаалтад давхар харуулна.
const TYPE_CONFIG = {
  Work_order: {
    collection: 'Work_order',
    actionsCollection: 'Work_order_actions',
    panel: 'workorderopenmore',
  },
  Work_pm: {
    collection: 'Work_pm',
    actionsCollection: 'Work_pm_actions',
    panel: 'workorderpmmore',
  },
  Work_inspections: {
    collection: 'Work_inspections',
    actionsCollection: 'Work_inpection_actions',
    panel: 'inspectionmore',
  },
  Predictive: {
    collection: 'Predictive',
    actionsCollection: 'Predictive_actions',
    panel: 'workorderprmore',
  },
}

const loadParts = async (work_order) => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: work_order,
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
    // console.log('loadParts', items)
    return {
      parts_sum: items[0].sum.amount,
      actual_parts_sum: items[0].sum.actual_amount,
    }
  } catch (e) {
    console.log(e)
  }
}

const loadTrades = async (work_order) => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: work_order,
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
    // console.log('loadTrades', items)
    return {
      trades_sum: items[0].sum.total,
      actual_trades_sum: items[0].sum.actual_total,
    }
  } catch (e) {
    console.log(e)
  }
}

// Work_order-той адилаар assigned_to=myId-ээр надад оноогдсон Work_pm,
// Work_inspections, Predictive-ийг тус тусын tab-д харуулна
const worksPm = ref([])
const worksInspections = ref([])
const worksPredictive = ref([])

const loadWorkOrder = async (pager = 1, itemsPerPage = 20, sortBy = []) => {
  try {
    loading.value = true
    let sort_array = ['-created_at']
    sortBy.map((sort_object) => {
      let sort_direction = sort_object?.order == 'asc' ? '' : '-'
      let sort_key = sort_object?.key
      sort_array.push(sort_direction.concat(sort_key))
    })

    const filters = {
      assigned_to: myId,
      action_status: 4, //assigned
      active: '1',
    }
    const items = await getItems<any>({
      collection: 'Work_order',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: pager,
        sort: sort_array,
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

    // Нэг нэгээр нь parts болон trades-ийг ачаалж утгууд нэмэх (зөвхөн
    // Work_order-т хамаарна — Work_pm/Work_inspections/Predictive-д
    // Work_order_Parts/Tradecode-той шууд холбоос байдаггүй)
    const enrichedWorks = await Promise.all(
      items.data?.map(async (work) => {
        const [parts, trades] = await Promise.all([
          loadParts(work.id),
          loadTrades(work.id),
        ])

        return {
          ...work,
          _source: 'Work_order',
          parts_sum: parts?.parts_sum || 0,
          actual_parts_sum: parts?.actual_parts_sum || 0,
          trades_sum: trades?.trades_sum || 0,
          actual_trades_sum: trades?.actual_trades_sum || 0,
        }
      }),
    )

    works.value = enrichedWorks

    // Work_pm, Work_inspections, Predictive-ийг тус тусад нь өөрийн tab-руу
    const typeTargets: Record<string, any> = {
      Work_pm: worksPm,
      Work_inspections: worksInspections,
      Predictive: worksPredictive,
    }
    await Promise.all(
      Object.entries(typeTargets).map(async ([typeKey, targetRef]) => {
        try {
          const res = await getItems<any>({
            collection: TYPE_CONFIG[typeKey].collection,
            params: {
              filter: filters,
              limit: itemsPerPage,
              page: pager,
              sort: sort_array,
              meta: 'filter_count',
              fields: ['*', 'assigned_to.*'],
            },
          })
          const list = Array.isArray(res) ? res : res?.data ?? []
          targetRef.value = list.map((row: any) => ({
            ...row,
            _source: typeKey,
          }))
        } catch (e) {
          console.warn(`Failed to load ${typeKey}:`, e)
          targetRef.value = []
        }
      }),
    )

    console.log('items.value.', works.value)

    loading.value = false
  } catch (e) {
    console.log(e)
  }
}

const onClickedAction = async (obj, type) => {
  const config = TYPE_CONFIG[obj._source || 'Work_order']

  if (type == 'Approve') {
    const updateData = {
      collection: config.collection,
      id: obj.id,
      item: { action_status: 2 },
    }
    const res = await updateItem(updateData)
    handleChangeKey()
    const do_approve = await createItems({
      collection: config.actionsCollection,
      items: {
        wo_id: obj.id,
        first_user: myId,
        action_status: 2,
        company_id: myCompanyId,
      },
    })
    refresh()
  } else if (type == 'Decline') {
    const updateData = {
      collection: config.collection,
      id: obj.id,
      item: { action_status: 6 },
    }
    await updateItem(updateData)
    handleChangeKey()
    const do_decline = await createItems({
      collection: config.actionsCollection,
      items: {
        wo_id: obj.id,
        first_user: myId,
        action_status: 6,
        company_id: myCompanyId,
      },
    })
    refresh()
  } else if (type == 'Assign') {
    handleModalUserListOpen(obj)
  }
}

const onRowClicked = (item) => {
  // console.log('onRowClicked', item)
  const source = item._source || 'Work_order'
  const config = TYPE_CONFIG[source]
  // Next/Prev навигацид ашиглах, тухайн эх сурвалжийн одоо ачаалагдсан мөрүүд
  const listBySource: Record<string, any> = {
    Work_order: works.value,
    Work_pm: worksPm.value,
    Work_inspections: worksInspections.value,
    Predictive: worksPredictive.value,
  }
  open(config.panel, {
    id: item.id,
    data: item,
    wo_statuses: wo_status_items,
    type: 'open',
    refresh: refresh,
    list: listBySource[source],
    onClose: (message: any) => {
      // console.log('onMessagess')
      // console.log(message)
      // close()
    },
  })
}

onMounted(async () => {
  await loadWorkOrder()
})

watch([filter, perPage], () => {
  router.push({
    query: {
      page: undefined,
    },
  })
})

const query = computed(() => {
  return {
    filter: filter.value,
    perPage: perPage.value,
    page: page.value,
  }
})

// Choose user

const handleChangeKey = () => {
  refreshKey.value =
    Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleModalUserListOpen = (item) => {
  isModalUserListOpen.value = true
  currentRecord.value = item
}
const handleModalUserListClose = () => {
  isModalUserListOpen.value = false
}

const setUser = async (user) => {
  if (currentRecord.value) {
    const do_approve = await createItems({
      collection: 'Work_order_actions',
      items: {
        wo_id: currentRecord.value.id,
        first_user: myId,
        next_user: user.id,
        action_status: 4,
        company_id: myCompanyId,
      },
    })

    const data = {
      collection: 'Work_order',
      id: currentRecord.value.id,
      item: {
        assigned_to: user.id,
      },
    }
    await updateItem(data)
    isModalUserListOpen.value = false
    handleChangeKey()
    refresh()

    sendNotification(
      ` assigned the task to you. Task #${currentRecord.value.id}`,
      myId,
      user.id,
      currentRecord.value.id,
      'assigned',
    )

    toaster.show({
      title: t('Update'),
      message: t(`Record assigned`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }
}
const refresh = async () => {
  console.log('refreshed')
  works.value = []
  key.value += 1
  await loadWorkOrder()
}
</script>

<template>
  <div class="px-4 md:px-6 lg:px-8 pb-20">
    <!-- Header -->
    <div
      class="mb-8 flex flex-col justify-between md:flex-row md:items-center"
    ></div>

    <!-- Grid -->
    <div class="my_assign">
      <TairoContentWrapperTabbed
        :key="key"
        v-model="active_tab"
        :labels="[$t('Work Order'), $t('Transaction')]"
        reverse
        shape="curved"
      >
        <template #tab-1>
          <div :key="refreshKey">
            <!-- Work Order доторх sub-tab (My tasks/My Assign navтай ижил underline загвар) -->
            <div class="w-full overflow-x-auto pb-1">
              <div class="border-muted-300 dark:border-muted-800 border-b">
                <nav class="-mb-px flex justify-end space-x-2">
                  <button
                    v-for="tabItem in subTabs"
                    :key="tabItem.key"
                    type="button"
                    class="whitespace-nowrap border-b-2 px-3 py-4 text-sm font-medium transition-all duration-200"
                    :class="
                      active_sub_tab === tabItem.key
                        ? '!border-primary-500 !text-primary-500'
                        : 'text-muted-400 hover:text-muted-800 dark:text-muted-500 dark:hover:text-muted-100 hover:border-muted-300 dark:hover:border-muted-700 border-transparent'
                    "
                    @click="active_sub_tab = tabItem.key"
                  >
                    {{ tabItem.label }}
                  </button>
                </nav>
              </div>
            </div>

            <div class="mt-4">
              <TaskCardGrid
                v-show="active_sub_tab === 'wo'"
                :items="works"
                type="WO"
                :onRowClicked="onRowClicked"
                :onClickedAction="onClickedAction"
              />
              <TaskCardGrid
                v-show="active_sub_tab === 'pm'"
                :items="worksPm"
                type="PM"
                :onRowClicked="onRowClicked"
                :onClickedAction="onClickedAction"
              />
              <TaskCardGrid
                v-show="active_sub_tab === 'insp'"
                :items="worksInspections"
                type="INSP"
                :onRowClicked="onRowClicked"
                :onClickedAction="onClickedAction"
              />
              <TaskCardGrid
                v-show="active_sub_tab === 'pdm'"
                :items="worksPredictive"
                type="PDM"
                :onRowClicked="onRowClicked"
                :onClickedAction="onClickedAction"
              />
            </div>
          </div>
        </template>
        <template #tab-2>
          <div class="px-4 md:px-6 lg:px-8 pb-20">
            <!-- Header -->
            <div
              class="flex flex-col justify-between md:flex-row md:items-center"
            ></div>

            <!-- Grid -->
            <div class="grid grid-cols-12 gap-6">
              <!-- Course Card -->
              <div
                v-for="(course, index) in courses"
                :key="index"
                class="relative col-span-12 sm:col-span-6 lg:col-span-4"
              >
                <BaseCard rounded="md" class="p-6 flex h-full flex-col">
                  <div class="mb-6">
                    <BaseTag variant="primary">
                      <span>{{ course.category }}</span>
                    </BaseTag>
                  </div>
                  <div class="mb-6">
                    <BaseHeading
                      as="h3"
                      size="lg"
                      weight="medium"
                      lead="tight"
                      class="mb-2"
                    >
                      <span class="text-muted-800 dark:text-muted-100 h-[32px]">
                        {{ course.title }}
                      </span>
                    </BaseHeading>
                    <BaseParagraph
                      size="sm"
                      class="text-muted-500 dark:text-muted-400 h-[68px]"
                    >
                      <span>{{ course.description }}</span>
                    </BaseParagraph>
                  </div>

                  <div class="mb-8">
                    <BaseHeading
                      as="h4"
                      size="md"
                      weight="medium"
                      lead="tight"
                      class="text-muted-800 dark:text-muted-100 mb-2"
                    >
                      <span
                        >{{ t('Week') }} {{ course.week }}
                        {{ t('lecture') }}</span
                      >
                    </BaseHeading>
                    <div class="flex gap-6">
                      <div
                        class="text-muted-500 dark:text-muted-400 flex items-center gap-1"
                      >
                        <Icon
                          name="solar:watch-square-minimalistic-linear"
                          class="size-5"
                        />
                        <span class="font-sans text-sm"
                          >{{ course.duration }} min</span
                        >
                      </div>
                      <div
                        class="text-muted-500 dark:text-muted-400 flex items-center gap-1"
                      >
                        <Icon
                          name="solar:chat-square-call-linear"
                          class="size-5"
                        />
                        <span class="font-sans text-sm">
                          {{ course.comments }} {{ t('comments') }}
                        </span>
                      </div>
                    </div>
                  </div>
                  <div class="mb-8">
                    <BaseHeading
                      as="h4"
                      size="md"
                      weight="medium"
                      lead="tight"
                      class="text-muted-800 dark:text-muted-100 mb-2"
                    >
                      <span
                        >{{ t('Week') }} {{ course.week }}
                        {{ t('examination') }}</span
                      >
                    </BaseHeading>
                    <div class="flex gap-6">
                      <div
                        class="text-muted-500 dark:text-muted-400 flex items-center gap-1"
                      >
                        <Icon name="solar:calendar-linear" class="size-5" />
                        <span class="font-sans text-sm">
                          {{ course.date }} — {{ course.time }}
                        </span>
                      </div>
                    </div>
                  </div>
                  <div class="mt-4 flex">
                    <BaseButton size="sm" rounded="md" class="">
                      <span>{{ t('Approve') }}</span>
                    </BaseButton>
                    <BaseButton size="sm" rounded="md" class="ml-2">
                      <span>{{ t('Decline') }}</span>
                    </BaseButton>
                    <BaseButton size="sm" rounded="md" class="ml-2">
                      <span>{{ t('Assign') }}</span>
                    </BaseButton>
                  </div>
                </BaseCard>
              </div>
            </div>
            <div class="flex mt-6">
              <BasePagination
                v-model:page="page"
                :total="data?.length ?? 0"
                :items-per-page="perPage"
                rounded="lg"
                class="w-full"
              />
            </div>
          </div>
        </template>
      </TairoContentWrapperTabbed>
    </div>
    <UserList
      :open="isModalUserListOpen"
      :close="handleModalUserListClose"
      :setUser="setUser"
    />
  </div>
</template>
