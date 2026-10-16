<script setup lang="ts">
// import { BaseCheckboxGroup } from '#components'
import {
  completed_status_ids,
  open_status_ids,
  wo_status_items,
} from '~/components/workorder/WorkOrderStatus'
import { isProxy, onMounted, ref, toRaw } from 'vue'

import PriorityCell from '~/components/custom/priorityCell.vue'
import Board from './board.vue'
import { useI18n } from 'vue-i18n'

definePageMeta({
  title: 'My Activity',
  preview: {
    title: 'Table list 1',
    description: 'For list views and collections',
    categories: ['layouts', 'lists'],
    src: '/img/screens/layouts-table-list-1.png',
    srcDark: '/img/screens/layouts-table-list-1-dark.png',
    order: 44,
  },
})

const { t } = useI18n({ useScope: 'global' })
const props = defineProps({
  location: Number,
  work_order: Number,
  type: String,
  tab: String,
  assigned: String,
  className: String,
})

const active_tab = ref('tab-1')
const myId = window.localStorage.getItem('myId')
const { open } = usePanels()
const route = useRoute()
const router = useRouter()
const loading = ref(false)

const { params } = useRoute()
const teams = ref([])
const wo_statuses = ref([])
let my_teams_ids = [0]
const work_order = ref([])
const key = ref(1)
const { getItems, createItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const { getUsers } = useDirectusUsers()

const data = ref([])

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

const filterValue = ref('')
const filterNumber = ref('')
const perPage = ref(25)

// const hashed = computed({
//   get: () => (filterValue.value = route.hash.split('#')[1]),
//   set: (value) => {
//     return (filterValue.value = value)
//   },
// })

//comments
const file_items = ref(null)
const selectedItem = ref(null)
const isOpenImg = ref(false)
const isOpenComment = ref(false)

import CommentModalForm from '~/components/form/CommentModalForm.vue'

// console.log('hasheeed ->', hashed.value)
// console.log('filterValue ->', filterValue.value)
// console.log('route ->', route)

const get_content_url = (file) => {
  // console.log('file ->', file)

  if (file && file.type.includes('image')) {
    return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
  } else {
    return ``
  }
}

if (data && 'picture' in data) {
  file_items.value = data.picture
} else if (data && 'part' in data) {
  file_items.value = data.part.picture
} else if (data && 'file' in data) {
  file_items.value = data.file
}

const showImg = (file) => {
  // console.log('file ->', file)
  isOpenImg.value = true
  selectedItem.value = file
}

const showComment = (item) => {
  // console.log('showComment ->', item)
  isOpenComment.value = true
  selectedItem.value = item
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleModalClose = () => {
  isOpenImg.value = false
  isOpenComment.value = false
  // selectedItem.value = false
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const query = computed(() => {
  return {
    filter: filterValue.value,
    perPage: perPage.value,
    page: page.value,
  }
})

const paginatedData = computed(() => {
  const start = (page.value - 1) * perPage.value
  const end = start + perPage.value
  return data.value?.slice(start, end) ?? []
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

const refresh = async (item) => {
  console.log('refreshed')
  data.value = []
  key.value += 1
  await loadWorkOrder(active_tab)

  // const newItem = { id: 6, name: "New Item", price: 100 };
  // const updatedData = [...gridApi.value.getDisplayedRowCount(), item];
  // gridApi.value.setRowData(updatedData);
  //   const newItem = { id: 6, name: "New Item", price: 100 };
  // gridOptions.api.applyTransaction({ add: [newItem] });
}

const onRowClicked = (item) => {
  // console.log('onRowClicked', item)

  // if (item.wo_status != 3) {
  open('workorderopenmore', {
    id: item.id,
    data: item,
    type: item.wo_status == 3 ? 'completed' : 'open',
    wo_statuses: wo_status_items,
    refresh: refresh,
    freeze: item.wo_status == 3 ? true : false,
  })
  // }
  // else if (item.wo_status == 3) {
  //   open('workordercompletedmore', {
  //     id: item.id,
  //     data: item,
  //     wo_statuses: wo_status_items,
  //     type: 'completed',
  //     refresh: refresh,
  //   })
  // }
}

const loadMyTeams = async () => {
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
      directus_users_id: { _in: [myId] },
    }

    const member_items = await getItems({
      collection: 'Teams_directus_users',
      params: {
        filter: filters_member,
        // limit: itemsPerPage,
        // page: page,
        // search: search.value,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    const leaders_items = await getItems({
      collection: 'Teams_directus_users_1',
      params: {
        filter: filters_member,
        // limit: itemsPerPage,
        // page: page,
        // search: search.value,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    if (member_items.data.length || leaders_items.data.length) {
      // console.log('member_items', my_teams_ids)
      my_teams_ids = [
        ...new Set([
          ...(member_items.data?.map((item) => item.Teams_id) || []),
          ...(leaders_items.data?.map((item) => item.Teams_id) || []),
        ]),
      ]
    }

    // if (isProxy(my_teams_ids.value)) {
    //   my_teams_ids.value = toRaw(my_teams_ids.value)
    // }
    // console.log('my_teams_ids_hi', my_teams_ids)

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

// tab-1 (Нээлттэй), tab-2 (Дууссан), tab-3 (Хүсэлт) tab тус бүрийн Work_order
// filter-ийг нэг л газраас гаргана. mytask.vue (эцэг layout, header дэх
// tab тус бүрийн тоог тооцдог) ижил логикийг тусад нь давхардуулж
// тооцдог тул энэ функц дотор дахин бичихээс зайлсхийхийн тулд adilxan
// байлгаарай.
const buildTabFilters = (tabKey) => {
  let filters = {
    active: '1',
    company_id: myCompanyId,
    action_status: { _in: [2] }, //approved
    assigned_team: { _in: my_teams_ids },
  }

  if (tabKey == 'tab-2') {
    filters.wo_status = { _in: completed_status_ids }
  }

  if (tabKey == 'tab-1') {
    filters.wo_status = { _in: open_status_ids }
  }

  if (tabKey == 'tab-3') {
    filters['request_user'] = { _null: false }
    filters.created_type = 'request'
    filters.wo_status = { _in: open_status_ids }
    filters['action_status'] = {
      _in: [1, 6],
    }
    delete filters.assigned_team
  }

  return filters
}

const loadWorkOrder = async (
  active_tab,
  pager = 1,
  itemsPerPage = 20,
  sortBy = [],
) => {
  try {
    let sort_array = ['-created_at']
    let searchField = 'id'
    sortBy.map((sort_object) => {
      let sort_direction = sort_object?.order == 'asc' ? '' : '-'
      let sort_key = sort_object?.key
      sort_array.push(sort_direction.concat(sort_key))
    })

    let filters = buildTabFilters(active_tab.value)

    // console.log('active_tab.value', active_tab.value)

    if (filterValue.value && filterValue.value.length > 1) {
      if (searchField == 'id') {
        filters[searchField] = {
          _eq: filterValue.value,
        }
      } else {
        filters[searchField] = {
          _icontains: filterValue.value,
        }
      }
    }

    console.log('Work_order.filters', filters)

    const items = await getItems({
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
          'asset.*',
          'template.*',
          'asset.location.*',
          'asset.department.*',
          'assigned_team.*',
        ],
      },
    })

    work_order.value = items.data

    if (items.data.length) {
      data.value = items.data?.map((item) => {
        // console.log('item', item)
        // item.wo_status
        return {
          ...item,
          position: 'Task #' + item.wo_number || item.id,
          // id: item.id,
          // name: item.name,
          // wo_status: item.wo_status,
          // priority: item.priority,
          comment_cnt: item.comment_cnt || '',
          asset_name: item.asset?.name || null,
          location_name: item.asset?.location?.name || null,
          department_name: item.asset?.department?.name || null,
          assigned_team_name: item.assigned_team?.name || null,
          // due: item.due,
          // started_at: item.started_at,
          // wo_percent: item.wo_percent,
        }
      })
    } else data.value = []

    // console.log('work_order', work_order)
  } catch (e) {
    console.log(e)
  }
}

onMounted(async () => {
  loading.value = true

  await loadMyTeams()
  await loadWoStatus()
  await loadWorkOrder(active_tab)
  loading.value = false
})

watch(active_tab, () => {
  loadWorkOrder(active_tab)
})

watch(
  () => route.hash,
  (newHash, oldHash) => {
    // console.log('route.hash changed:', newHash)
    if (newHash) {
      filterValue.value = newHash.split('#')[1]
      console.log('route.hash filterValue:', filterValue.value)
    }
  },
)

watch(filterValue, async () => {
  console.log('filterValue', filterValue)
  await loadWorkOrder(active_tab)
})
</script>

<template>
  <div
    class="pb-20 dark:[--color-input-default-bg:var(--color-muted-950)] my_tasks"
  >
    <TairoContentWrapper>
      <div>
        <!-- <div v-if="data?.length === 0">
          <BasePlaceholderPage
            title="No matching results"
            subtitle="Looks like we couldn't find any matching results for your search terms. Try other search terms."
          >
            <template #image>
              <img
                class="block dark:hidden"
                src="/img/illustrations/placeholders/flat/placeholder-search-4.svg"
                alt="Placeholder image"
              />
              <img
                class="hidden dark:block"
                src="/img/illustrations/placeholders/flat/placeholder-search-4-dark.svg"
                alt="Placeholder image"
              />
            </template>
          </BasePlaceholderPage>
        </div> -->
        <div class="relative mt-[60px]">
          <BaseInput
            v-model="filterValue"
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
            :labels="[$t('List'), $t('Completed'), $t('Request')]"
            reverse
            shape="curved"
          >
            <template #tab-1>
              <div>
                <div
                  :class="`w-full sticky-table-wrap border border-muted-200 dark:border-muted-700 my_task_${
                    $colorMode.value === 'light' ? '' : 'dark'
                  } `"
                >
                  <TairoTable
                    rounded="sm"
                    :scrollable="false"
                    style="border-radius: 8px"
                  >
                    <template #header>
                      <TairoTableHeading spaced class="text-center">
                        <div class="flex items-center justify-center font-bold">
                          №
                        </div>
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Task name') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Priority') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Status') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Accept') }}
                      </TairoTableHeading>

                      <TairoTableHeading spaced>
                        {{ t('Start') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Due') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Comments') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Completed') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced class="text-end">
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
                    <TairoTableRow
                      v-for="(item, index) in paginatedData"
                      :key="item.id"
                    >
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
                          <div
                            class="ms-3 leading-none max-w-[272px] overflow-hidden text-ellipsis whitespace-nowrap"
                            :title="item.name"
                          >
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

                      <TairoTableCell spaced class="capitalize">
                        <PriorityCell
                          fieldName="action_status"
                          :value="item.action_status"
                          :status="action_status"
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
                      <TairoTableCell light spaced @click="showComment(item)">
                        {{ item.comment_cnt }}
                      </TairoTableCell>
                      <TairoTableCell spaced>
                        <div class="flex items-center">
                          <div class="relative">
                            <BaseProgressCircle
                              :model-value="item.wo_percent"
                              :thickness="1"
                              :size="50"
                              :value="item.wo_percent"
                              variant="primary"
                              class="text-success-500"
                            />
                            <div
                              class="absolute start-1/2 top-1/2 z-10 ms-0.5 -translate-x-1/2 -translate-y-1/2 font-sans text-[0.65rem] font-semibold rtl:me-0.5 rtl:ms-0 rtl:translate-x-1/2"
                            >
                              {{ item.wo_percent }}%
                            </div>
                          </div>
                        </div>
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
                  <!-- <BaseSelect v-model="perPage" label="" class="!h-[43px] mt-[3px]">
                      <BaseSelectItem :value="10"> 10</BaseSelectItem>
                      <BaseSelectItem :value="25"> 25</BaseSelectItem>
                      <BaseSelectItem :value="50"> 50</BaseSelectItem>
                      <BaseSelectItem :value="100"> 100</BaseSelectItem>
                    </BaseSelect> -->
                  <BasePagination
                    :current-page="page"
                    :total-items="data?.length ?? 0"
                    :item-per-page="perPage"
                    rounded="lg"
                    class="w-full"
                    @update:page="(p) => (page = p)"
                  />
                </div>
              </div>
            </template>
            <template #tab-2>
              <div>
                <div
                  :class="`w-full sticky-table-wrap border border-muted-200 dark:border-muted-700 my_task_${
                    $colorMode.value === 'light' ? '' : 'dark'
                  } `"
                >
                  <TairoTable
                    rounded="sm"
                    :scrollable="false"
                    style="border-radius: 8px"
                  >
                    <template #header>
                      <TairoTableHeading
                        spaced
                        class="p-4 completed_items w-16 text-center"
                      >
                        <div class="flex items-center justify-center font-bold">
                          №
                        </div>
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
                        {{ t('Accept') }}
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
                      <!-- <TairoTableHeading spaced class="completed_items">
                        Completed
                      </TairoTableHeading> -->

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
                    <TairoTableRow
                      v-for="(item, index) in paginatedData"
                      :key="item.id"
                    >
                      <TairoTableCell spaced class="w-16">
                        <div class="flex items-center justify-center">
                          <!-- <BaseCheckbox :value="item.id" /> -->
                          <p
                            class="font-heading text-sm font-semibold text-muted-600 dark:text-muted-400"
                          >
                            {{ index + 1 }}
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
                      <TairoTableCell spaced class="capitalize">
                        <PriorityCell
                          fieldName="action_status"
                          :value="item.action_status"
                          :status="action_status"
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
                      <!-- <TairoTableCell spaced>
                        <div class="flex items-center">
                          <div class="relative">
                            <BaseProgressCircle
                              :model-value="item.wo_percent"
                              :thickness="1"
                              :size="50"
                              :value="item.wo_percent"
                              variant="primary"
                              class="text-success-500"
                            />
                            <div
                              class="absolute start-1/2 top-1/2 z-10 ms-0.5 -translate-x-1/2 -translate-y-1/2 font-sans text-[0.65rem] font-semibold rtl:me-0.5 rtl:ms-0 rtl:translate-x-1/2"
                            >
                              {{ item.wo_percent }}%
                            </div>
                          </div>
                        </div>
                      </TairoTableCell> -->
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
                    :current-page="page"
                    :total-items="data?.length ?? 0"
                    :item-per-page="perPage"
                    rounded="lg"
                    class="w-full"
                    @update:page="(p) => (page = p)"
                  />
                </div>
              </div>
            </template>

            <template #tab-3>
              <div>
                <div
                  :class="`w-full sticky-table-wrap border border-muted-200 dark:border-muted-700 my_task_${
                    $colorMode.value === 'light' ? '' : 'dark'
                  } `"
                >
                  <TairoTable
                    rounded="sm"
                    :scrollable="false"
                    style="border-radius: 8px"
                  >
                    <template #header>
                      <TairoTableHeading spaced class="p-4 w-16 text-center">
                        <div class="flex items-center justify-center font-bold">
                          <!-- <BaseCheckbox
                      :model-value="
                        selected.length > 0 && !isAllVisibleSelected
                          ? 'indeterminate'
                          : isAllVisibleSelected
                      "
                      @click="toggleAllVisibleSelection" 
                    /> -->
                          №
                        </div>
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Task name') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Priority') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Status') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Accept') }}
                      </TairoTableHeading>

                      <TairoTableHeading spaced>
                        {{ t('Start') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Due') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Comments') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced>
                        {{ t('Completed') }}
                      </TairoTableHeading>
                      <TairoTableHeading spaced class="text-end">
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
                    <TairoTableRow
                      v-for="(item, index) in paginatedData"
                      :key="item.id"
                    >
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
                          <div
                            class="ms-3 leading-none max-w-[272px] overflow-hidden text-ellipsis whitespace-nowrap"
                            :title="item.name"
                          >
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

                      <TairoTableCell spaced class="capitalize">
                        <PriorityCell
                          fieldName="action_status"
                          :value="item.action_status"
                          :status="action_status"
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
                        <div class="flex items-center">
                          <div class="relative">
                            <BaseProgressCircle
                              :model-value="item.wo_percent"
                              :thickness="1"
                              :size="50"
                              :value="item.wo_percent"
                              variant="primary"
                              class="text-success-500"
                            />
                            <div
                              class="absolute start-1/2 top-1/2 z-10 ms-0.5 -translate-x-1/2 -translate-y-1/2 font-sans text-[0.65rem] font-semibold rtl:me-0.5 rtl:ms-0 rtl:translate-x-1/2"
                            >
                              {{ item.wo_percent }}%
                            </div>
                          </div>
                        </div>
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
                    :current-page="page"
                    :total-items="data?.total ?? 0"
                    :item-per-page="perPage"
                    rounded="lg"
                    class="w-full"
                    @update:page="(p) => (page = p)"
                  />
                </div>
              </div>
            </template>
          </TairoContentWrapperTabbed>
        </div>
      </div>
    </TairoContentWrapper>
  </div>
  <CommentModalForm
    :key="key"
    :itemsValue="selectedItem"
    :open="isOpenComment"
    :close="handleModalClose"
    collection="Work_order_comments"
  />
</template>
<style>
.my_tasks .completed_items {
  background: #e6f7e6;
}

/* .my_task_dark .bg-white {
  background-color: rgb(30 41 59) !important;
  color: #94a3b8 !important;
} */

/* Хүснэгтийн толгойг (thead) байрандаа тогтоож, зөвхөн мөрүүдийг (tbody)
   босоо чиглэлд гүйлгэдэг болгоно. Өмнө нь TairoTable :scrollable="false"
   гэсэн дээр нь эцэг element дээр нь overflow:hidden давхар тавигдсан
   байсан тул баганууд (10 багана) багтахгүй бол зүгээр л ил үзэгдэхгүй,
   гүйлгэх ямар ч арга байхгүй "тасарсан" харагддаг байв. */
.my_tasks .sticky-table-wrap {
  max-height: 65vh;
  overflow: auto;
  /* Хайчлалт (rounded corner clipping)-ыг зөвхөн ЭНД (жинхэнэ scroll
     container дээр нь) хийнэ — TairoTable-ийн өөрийнх нь дотор
     overflow:hidden тавивал sticky thead-ийн scroll-ийн reference
     ancestor нь тэр болж, гаднах гүйлгэлттэй зөрчилдөх эрсдэлтэй */
  border-radius: 0.5rem;
}

.my_tasks .sticky-table-wrap thead {
  position: sticky;
  top: 0;
  z-index: 10;
  background: white;
}

.dark .my_tasks .sticky-table-wrap thead {
  background: rgb(30 41 59);
}
</style>
