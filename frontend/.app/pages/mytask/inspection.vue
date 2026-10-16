<script setup lang="ts">
// import { BaseCheckboxGroup } from '#components'
import {
  completed_status_ids,
  open_status_ids,
  wo_status_items,
} from '~/components/workorder/WorkOrderStatus'
import { ref, nextTick } from 'vue'

import PriorityCell from '~/components/custom/priorityCell.vue'
import Board from './board.vue'

import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
definePageMeta({
  title: 'My Inspections',
  preview: {
    title: 'Table list 1',
    description: 'For list views and collections',
    categories: ['layouts', 'lists'],
    src: '/img/screens/layouts-table-list-1.png',
    srcDark: '/img/screens/layouts-table-list-1-dark.png',
    order: 44,
  },
})

const datass = ref([
  {
    id: '1',
    picture: '/img/illustrations/layouts/post-13.svg',
    name: '1396 Redmond Street',
    location: '1396 Redmond Street, Apartment 12, Suite H 102, Los Angeles, CA',
    rating: 4,
    details: {
      rooms: 5,
      beds: 3,
      bathrooms: 1,
    },
    amenities: {
      parking: true,
      wifi: true,
      heater: true,
      cleaning: true,
      other: true,
      otherThing: true,
      otherCoolThing: true,
    },
  },
  {
    id: '2',
    picture: '/img/illustrations/layouts/post-2.svg',
    name: '24 Mulberry Street',
    location: '24 Mulberry Street, Suite 43, New York, NY',
    rating: 5,
    details: {
      rooms: 3,
      beds: 2,
      bathrooms: 1,
    },
    amenities: {
      wifi: true,
      cleaning: true,
    },
  },
])

const myId = window.localStorage.getItem('myId')
const userInfo = JSON.parse(window.localStorage.getItem('userInfo') || '{}')
const config = useRuntimeConfig()
const { open } = usePanels()

const loading = ref(false)
const active_tab = ref('tab-1')

const { params } = useRoute()
const teams = ref([])
const wo_statuses = ref([])
const my_works_ids = ref([])
const work_order = ref([])
const key = ref(1)
const { getItems, createItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const { getUsers } = useDirectusUsers()

const data = ref([])
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

// const offset = (page - 1) * perPage
// const filterRe = new RegExp(filter, 'i')

// return {
//   total: data.length,
//   data: !filter
//     ? data.slice(offset, offset + perPage)
//     : data
//         .filter((item) => {
//           return [item.name, item.location, item.position].some(item =>
//             item.match(filterRe),
//           )
//         })
//         .slice(offset, offset + perPage),
// }

const selected = ref<number[]>([])

const isAllVisibleSelected = computed(() => {
  return selected.value.length === data.value?.length
})

function toggleAllVisibleSelection() {
  if (isAllVisibleSelected.value) {
    selected.value = []
  } else {
    selected.value = data.value?.map((item) => item.id) ?? []
  }
}

const getPriorityLabel = (priority) => {
  switch (priority) {
    case 1:
      return 'Low'
    case 2:
      return 'High'
    case 3:
      return 'Medium'
    case 4:
      return 'Urgent'
    default:
      return ''
  }
}

const get_file_url = (file) => {
  // console.log('get_content_url-files', file)

  // if (!file) {
  //   return false
  // }

  if (file?.type?.includes('image')) {
    return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
  } else {
    return '/img/apps/4.jpg'
  }
}

const refresh = async (item, tab_index) => {
  data.value = []
  key.value += 1

  // Tab утгыг өөрчлөхийн өмнө хадгалах
  const targetTab = tab_index

  // Reverse байгаа тул tab-2 нь tab-1 болж харагдаж байж магадгүй
  const actualIndex = tab_index === 'tab-2' ? 0 : 1 // reverse-тэй
  // reverse байгаа тул tab index-ийг эргүүлэх хэрэгтэй
  if (tab_index === 'tab-2') {
    active_tab.value = 'tab-1' // reverse-тэй учираас tab-2 нь tab-1 болж харагдана
  } else {
    active_tab.value = 'tab-2'
  }

  // Key өөрчилсний дараа tab утга сэтгэх
  await nextTick(() => {
    key.value += 1
  })

  await nextTick(() => {
    active_tab.value = targetTab
  })

  await loadWorkOrder()
}

const onRowClicked = (item) => {
  // console.log('onRowClicked', item)

  open('inspectionmore', {
    id: item.id,
    data: item,
    type: 'open',
    mode: 'user',
    wo_statuses: wo_status_items,
    refresh: refresh,
    active_tab: active_tab,
    list: data.value,
  })
}

const loadMyInspec = async () => {
  loading.value = true

  // { page, itemsPerPage, sortBy }
  // let sort_array = []
  // sortBy.map((sort_object) => {
  //   let sort_direction = sort_object?.order == 'asc' ? '' : '-'
  //   let sort_key = sort_object?.key
  //   sort_array.push(sort_direction.concat(sort_key))
  // })
  try {
    const filters_member = {
      user: { _in: [myId] },
    }

    const member_items = await getItems({
      collection: 'Work_inspection_users',
      params: {
        filter: filters_member,
        // limit: itemsPerPage,
        // page: page,
        // search: search.value,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    my_works_ids.value = [
      ...new Set([
        ...(member_items.data?.map((item) => item.work_order) || []),
      ]),
    ]

    // if (isProxy(my_works_ids.value)) {
    //   my_works_ids.value = toRaw(my_works_ids.value)
    // }
    // console.log('my_works_ids', my_works_ids)

    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

const loadWoStatus = async () => {
  loading.value = true

  // { page, itemsPerPage, sortBy }
  // let sort_array = []
  // sortBy.map((sort_object) => {
  //   let sort_direction = sort_object?.order == 'asc' ? '' : '-'
  //   let sort_key = sort_object?.key
  //   sort_array.push(sort_direction.concat(sort_key))
  // })
  try {
    const filters = {
      active: 1,
    }
    const items = await getItems({
      collection: 'Module_status',
      params: {
        filter: filters,
        limit: -1,
        sort: ['position'],
        meta: 'filter_count',
        fields: ['*', 'code_color.*'],
      },
    })

    wo_statuses.value = items.data

    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

const loadWorkOrder = async (pager = 1, itemsPerPage = 20, sortBy = []) => {
  try {
    let sort_array = ['-created_at']
    sortBy.map((sort_object) => {
      let sort_direction = sort_object?.order == 'asc' ? '' : '-'
      let sort_key = sort_object?.key
      sort_array.push(sort_direction.concat(sort_key))
    })

    let filters = {
      active: '1',
      // wo_status: { _in: [...open_status_ids, ...completed_status_ids] },
      // id: { _in: my_works_ids.value },
      pm_type: { _in: ['delivered', 'generated'] },
      company_id: { _eq: myCompanyId },
    }

    if (my_works_ids.value.length) {
      filters.id = { _in: my_works_ids.value }
    }

    // console.log('loadWorkOrder.value', active_tab.value)
    if (active_tab.value == 'tab-2') {
      filters.wo_status = { _in: completed_status_ids }
    }

    if (active_tab.value == 'tab-1') {
      filters.wo_status = { _in: open_status_ids }
    }

    // const filters = {
    //   active: '1',
    //   wo_status: { _in: [...open_status_ids, ...completed_status_ids] },
    //   id: { _in: my_works_ids.value },
    // }

    // console.log('dsdsdsdsd', filters)
    const items = await getItems({
      collection: 'Work_inspections',
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
          'asset.*',
          'template.*',
          'picture.*',
          'asset.location.*',
          'asset.department.*',
          'assigned_team.*',
        ],
      },
    })

    work_order.value = items.data

    // if (items.data.length) {
    data.value = items.data?.map((item) => {
      // console.log('item', item)
      // item.wo_status
      return {
        ...item,
        picture: item.picture,
        position: 'Task #' + item.auto_number,
        // id: item.id,
        // name: item.name,
        // wo_status: item.wo_status,
        history_description: item.history_description,
        created_at: item.created_at,

        priority: item.priority,
        comment_cnt: item.comment_cnt || '',
        asset_name: item.asset?.name || null,
        location_name: item.asset?.location?.name || null,
        department_name: item.asset?.department?.name || null,
        assigned_team_name: item.assigned_team?.name || null,
        due: item.due ? item.due.split('T')[0] : '?',
        started_at: item.started_at ? item.started_at.split('T')[0] : '?',
        wo_percent: item.wo_percent,
      }
    })
    // }

    // console.log('work_order', work_order)
  } catch (e) {
    console.log(e)
  }
  console.log(teams.value)
}

onMounted(async () => {
  loading.value = true

  await loadMyInspec()
  await loadWoStatus()
  await loadWorkOrder()
  loading.value = false
})
watch(active_tab, () => {
  loadWorkOrder()
})
</script>

<template>
  <div
    class="pb-20 dark:[--color-input-default-bg:var(--color-muted-950)] my_inspection"
  >
    <TairoContentWrapper>
      <div>
        <div class="relative mt-[60px]">
          <BaseInput
            v-model="filter"
            icon="lucide:search"
            :placeholder="t('Filter')"
            :classes="{
              wrapper: 'w-[340px] ',
            }"
          />
        </div>
        <div class="mt-[-44px]">
          <TairoContentWrapperTabbed
            :key="key"
            v-model="active_tab"
            :labels="[$t('List'), $t('Completed')]"
            shape="curved"
            reverse
            position="!justify-end"
          >
            <template #tab-1>
              <div>
                <div class="w-full space-y-4">
                  <TransitionGroup
                    enter-active-class="transform-gpu"
                    enter-from-class="opacity-0 -translate-x-full"
                    enter-to-class="opacity-100 translate-x-0"
                    leave-active-class="absolute transform-gpu"
                    leave-from-class="opacity-100 translate-x-0"
                    leave-to-class="opacity-0 -translate-x-full"
                  >
                    <BaseCard
                      v-for="item in data"
                      :key="item.id"
                      rounded="lg"
                      class="flex flex-col p-4 sm:flex-row sm:items-center"
                    >
                      <div
                        class="flex flex-col justify-center gap-3 text-center sm:flex-row sm:justify-start sm:text-start"
                      >
                        <div class="w-[172px]">
                          <img
                            class="bg-muted-100 dark:bg-muted-700/60 w-full rounded-lg border border-gray-400 h-[114px] w-[100%] object-cover"
                            :src="get_file_url(item?.picture)"
                            :alt="item.name"
                            height="114px"
                            width="100%"
                          />
                        </div>
                        <div class="w-[344px]">
                          <div
                            class="flex flex-col gap-2 text-start sm:flex-row sm:items-center mb-1"
                          >
                            <BaseHeading
                              tag="h3"
                              size="sm"
                              weight="medium"
                              class="text-muted-900 dark:text-muted-100"
                            >
                              <span :style="{ color: 'red' }">{{
                                item.position
                              }}</span>
                              {{ '-' + item.name }}
                            </BaseHeading>
                          </div>
                          <BaseParagraph
                            size="xs"
                            lead="none"
                            class="text-muted-400 flex gap-1 text-start text-sm sm:mt-0 sm:items-end"
                          >
                            <span>{{
                              item.history_description
                                ? item.history_description
                                : ' No description'
                            }}</span>
                          </BaseParagraph>
                          <div
                            class="text-muted-900 dark:text-white font-medium my-2 flex items-center gap-2"
                          >
                            <span class="font-sans text-xs whitespace-nowrap">
                              {{ item.created_at?.split('T')[0] }} delivered
                            </span>
                            <span class="text-muted-400">&middot;</span>
                            <span class="font-sans text-xs whitespace-nowrap">
                              {{ item.started_at?.split('T')[0] }} start
                            </span>
                            <span class="text-muted-400">&middot;</span>
                            <span class="font-sans text-xs whitespace-nowrap">
                              {{ item.due?.split('T')[0] }} due
                            </span>
                          </div>
                          <div
                            class="text-muted-400 mt-auto flex items-center gap-6"
                          >
                            <div class="flex items-center gap-1">
                              <Icon
                                name="ph:broadcast-duotone"
                                class="size-4"
                              />
                              <span class="font-sans text-xs whitespace-nowrap">
                                {{ getPriorityLabel(item.priority) }} priority
                              </span>
                            </div>
                            <div class="flex items-center gap-1">
                              <Icon
                                name="ph:thermometer-duotone"
                                class="size-4"
                              />
                              <span class="font-sans text-xs whitespace-nowrap">
                                {{ item.comment_cnt ? item.comment_cnt : 0 }}
                                comments
                              </span>
                            </div>
                            <div class="flex items-center gap-1">
                              <Icon name="ph:waves-duotone" class="size-4" />
                              <span class="font-sans text-xs whitespace-nowrap">
                                {{
                                  item.due && item.started_at
                                    ? isNaN(
                                        Math.ceil(
                                          (new Date(item.due) -
                                            new Date(item.started_at)) /
                                            (1000 * 60 * 60 * 24),
                                        ),
                                      )
                                      ? '?'
                                      : Math.ceil(
                                          (new Date(item.due) -
                                            new Date(item.started_at)) /
                                            (1000 * 60 * 60 * 24),
                                        )
                                    : '?'
                                }}
                                days duration
                              </span>
                            </div>
                          </div>
                        </div>
                      </div>
                      <div
                        style="width: 320px; justify-content: end !important"
                        class="flex items-center"
                      >
                        <div
                          class="w-full grow space-y-1 sm:w-auto sm:max-w-[180px]"
                        >
                          <div class="flex items-center justify-between">
                            <h4
                              class="text-muted-700 dark:text-muted-100 font-sans text-sm font-medium"
                            >
                              Progress
                            </h4>
                            <div>
                              <span class="text-muted-400 font-sans text-sm">
                                {{ item.wo_percent }}%
                              </span>
                            </div>
                          </div>
                          <BaseProgress
                            size="xs"
                            variant="primary"
                            :value="item.wo_percent"
                            color="success"
                          />
                        </div>
                      </div>
                      <div
                        class="mt-4 flex items-center justify-end gap-2 sm:ms-auto sm:mt-4"
                      >
                        <BaseButton
                          size="sm"
                          rounded="md"
                          variant="ghost"
                          class="w-full sm:w-24"
                          @click="onRowClicked(item)"
                        >
                          More Info
                        </BaseButton>
                      </div>
                    </BaseCard>
                  </TransitionGroup>
                </div>
                <div class="flex mt-6">
                  <BasePagination
                    :page="1"
                    :total="100"
                    :items-per-page="10"
                    rounded="lg"
                    class="w-full"
                  />
                </div>
              </div>
            </template>
            <template #tab-2>
              <div>
                <div class="w-full">
                  <TairoTable rounded="sm" :scrollable="false">
                    <template #header>
                      <TairoTableHeading spaced class="p-4 completed_items">
                        <div class="flex items-center">№</div>
                      </TairoTableHeading>
                      <TairoTableHeading spaced class="completed_items">
                        {{ t('Task name') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced class="completed_items">
                        {{ t('Priority') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced class="completed_items">
                        {{ t('Status') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced class="completed_items">
                        {{ t('Start') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced class="completed_items">
                        {{ t('Due') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced class="completed_items">
                        {{ t('Comments') }}
                      </TairoTableHeading>
                      <!-- <TairoTableHeading spaced> Completed </TairoTableHeading> -->
                      <TairoTableHeading
                        spaced
                        class="text-end completed_items"
                      >
                        {{ t('Action') }}
                      </TairoTableHeading>
                    </template>

                    <TairoTableRow
                      v-if="selected.length > 0"
                      :hoverable="false"
                    >
                      <TairoTableCell
                        colspan="6"
                        class="bg-success-100 text-success-700 dark:bg-success-700 dark:text-success-100 p-4"
                      >
                        You have selected {{ selected.length }} items of the
                        total {{ data?.length }} items.
                        <a
                          href="#"
                          class="outline-none hover:underline focus:underline"
                          >{{ t('Click here to everything') }}</a
                        >
                      </TairoTableCell>
                    </TairoTableRow>

                    <!-- <BaseCheckboxGroup v-model="selected" as-child> -->
                    <TairoTableRow v-for="(item, index) in data" :key="item.id">
                      <TairoTableCell spaced>
                        <div class="flex items-center">
                          <!-- <BaseCheckbox :value="item.id" /> -->
                          <p class="font-heading text-sm font-semibold">
                            {{ index + 1 }}.
                          </p>
                        </div>
                      </TairoTableCell>
                      <TairoTableCell spaced>
                        <div class="flex items-center">
                          <div class="ms-3 leading-none">
                            <h4
                              class="text-muted-900 dark:text-white font-sans text-sm font-medium"
                            >
                              {{ item.name }}
                            </h4>
                            <p
                              class="text-muted-600 dark:text-muted-400 font-sans text-xs"
                            >
                              {{ item.position }}
                            </p>
                          </div>
                        </div>
                      </TairoTableCell>
                      <TairoTableCell spaced class="capitalize">
                        <PriorityCell
                          fieldName="priority"
                          :value="item.priority"
                        />
                      </TairoTableCell>

                      <TairoTableCell spaced class="capitalize">
                        <PriorityCell
                          fieldName="wo_status"
                          :value="item.wo_status"
                          :status="wo_statuses"
                        />
                      </TairoTableCell>
                      <TairoTableCell spaced>
                        <div class="relative items-center">
                          <div class="font-sans text-[0.65rem] font-semibold">
                            {{ item.started_at?.split('T')[0] }}
                          </div>
                        </div>
                      </TairoTableCell>
                      <TairoTableCell spaced>
                        <div class="relative items-center">
                          <div class="font-sans text-[0.65rem] font-semibold">
                            {{ item.due?.split('T')[0] }}
                          </div>
                        </div>
                      </TairoTableCell>
                      <TairoTableCell light spaced>
                        {{ item.comment_cnt }}
                      </TairoTableCell>
                      <TairoTableCell spaced>
                        <div class="flex justify-end">
                          <BaseButtonAction
                            color="muted"
                            @click="onRowClicked(item)"
                          >
                            <span>{{ t('More') }}</span>
                          </BaseButtonAction>
                        </div>
                      </TairoTableCell>
                    </TairoTableRow>
                    <!-- </BaseCheckboxGroup> -->
                  </TairoTable>
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
      </div>
    </TairoContentWrapper>
  </div>
</template>
<style>
.my_inspection .completed_items {
  background: #e6f7e6;
}
</style>
