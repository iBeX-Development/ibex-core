<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import ActionDropdownMulti from '~/components/ag_grid/ActionDropdownMulti.vue'

// import WorkOrderFullTimeLine from '~/components/workorder/FullTimeLine.vue'
import Performance from '~/components/workorder/Performance.vue'
import DayPilot from '~/components/workorder/daypilots/DayPilot.vue'
const { open } = usePanels()

import {
  completed_wo_status,
  wo_status_items,
} from '~/components/workorder/WorkOrderStatus'
const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Work order completed tasks',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})
const status = ref({
  _in: [3],
})

// console.log('open_status_ids', open_status_ids)

const myId = window.localStorage.getItem('myId')
const { params } = useRoute()
const toaster = useToaster()
const woListRef = ref(null)
const woTimeLineRef = ref(null)

const isModalUserListOpen = ref(false)
const isPrint = ref(false)
const selected_rows = ref([])
const skip_rows = ref([])
const runtimeConfig = useRuntimeConfig()
const key = ref(1)
const active_tab = ref('tab-1')

// const columnState = JSON.parse(localStorage.getItem('open'))
// const colId = ref(null)
// const sort = ref(null)
// const sortedColumns = columnState?.filter((col) => col.sort !== null)
// if (sortedColumns?.length) {
//   colId.value = sortedColumns[0].colId
//   sort.value = sortedColumns[0].sort
//   console.log('sort_changes_ind', colId.value, sort.value)
// }

const handleExcelExportClick = () => {
  // console.log(woListRef?.value)
  // console.log(woTimeLineRef?.value)
  // console.log(active_tab.value)

  if (active_tab.value == 'tab-1') {
    const filterModel = woListRef?.value?.gridApi?.getFilterModel()
    const filters = woListRef?.value?.filterBuild(filterModel)
    console.log(filters)
    exportMultiple(filters)
  } else if (active_tab.value == 'tab-2') {
    woTimeLineRef?.value?.exportToExcel()
  }
}

const do_assign_multi = () => {
  // Get selected rows using the exposed method
  if (woListRef?.value?.gridApi) {
    const { selectAll } =
      woListRef?.value?.gridApi.getServerSideSelectionState()
    let rows = []
    if (!selectAll) {
      rows = woListRef?.value?.gridApi.getSelectedRows()

      rows.forEach((row) => {
        if (row.action_status == 2) {
          skip_rows.value.push(row.id)
        } else {
          selected_rows.value.push(row.id)
        }
      })
    } else {
      // rows =
      const filterModel = woListRef?.value?.gridApi?.getFilterModel()
      const filters = woListRef?.value?.filterBuild(filterModel)
    }
  }
  // Check if any rows are selected
  if (!selected_rows.value || selected_rows.value.length === 0) {
    toaster.show({
      title: t('No selection'),
      message: t('Selected Work order already Assigned'),
      color: 'danger',
    })
    return
  }
  // Open user selection modal
  isModalUserListOpen.value = true
}
const getCurrentPageRowIds = () => {
  const api = woListRef?.value?.gridApi
  if (!api) return []

  const rowCount = api.getDisplayedRowCount()
  const ids = []

  for (let i = 0; i < rowCount; i++) {
    const rowNode = api.getDisplayedRowAtIndex(i)
    if (rowNode && rowNode.data) {
      ids.push(rowNode.data.id)
    }
  }

  return ids
}

const do_print = () => {
  selected_rows.value = []
  console.log('Printing_1 ...', selected_rows.value)
  if (woListRef?.value?.gridApi) {
    let rows = []
    const { selectAll } =
      woListRef?.value?.gridApi.getServerSideSelectionState()
    if (!selectAll) {
      rows = woListRef?.value?.gridApi.getSelectedRows()

      rows.forEach((row) => {
        if (!selected_rows.value.includes(row.id)) {
          selected_rows.value.push(row.id)
        }
      })
    } else {
      const idsOnPage = getCurrentPageRowIds()
      idsOnPage.forEach((id) => {
        // Та энд id-д харгалзах action_status-г мэдэхгүй учир skip_rows-ийг бөглөхөд хүндрэлтэй
        // Хэрвээ шаардлагатай бол, нэмэлт fetch хийх хэрэгтэй байж магадгүй
        if (!selected_rows.value.includes(id)) {
          selected_rows.value.push(id)
        }
      })
    }

    // const addUniqueIds = (ids) => {
    //   const currentSet = new Set(selected_rows.value)
    //   ids.forEach((id) => currentSet.add(id))
    //   selected_rows.value = Array.from(currentSet)
    // }
    // addUniqueIds(selected_rows.value)

    if (selected_rows.value.length === 0) {
      toaster.show({
        title: t('No selection'),
        color: 'danger',
      })
      return
    }
    console.log('length...', selected_rows.value.length)

    if (selected_rows.value.length > 30) {
      toaster.show({
        title: t('Too many selection'),
        color: 'danger',
      })
      return
    }
    console.log('Printing_2...', selected_rows.value)
    open('printMulti', {
      wo_ids: selected_rows,
      refresh: closedPrint,
    })

    // isPrint.value = true
  }
}

const do_accept = async (item) => {
  // actionType.value = 'do_accept'
  // console.log('do_accept...', item)
  await updateMultiple(null, 5)
}

const do_delete = async (item) => {
  // actionType.value = 'do_delete'
  // console.log('do_delete...', item)
  await updateMultiple(null, 0)
}
const do_approve = async (item) => {
  // actionType.value = 'do_approve'
  // console.log('do_approve...', item)
  await updateMultiple(null, 2)
}

const do_return = async (item) => {
  // actionType.value = 'do_return'
  // console.log('do_return...', item)
  await updateMultiple(null, 3)
}

const do_decline = async (item) => {
  // actionType.value = 'do_decline'
  // console.log('do_decline...', item)
  await updateMultiple(null, 6)
}

const do_assign = async (item) => {
  // actionType.value = 'do_assign'
  // console.log('do_assignss...', item)
  isModalUserListOpen.value = true
}

const do_actions = () => {
  // console.log('do_actions...')
  selected_rows.value = []

  if (woListRef?.value?.gridApi) {
    const { selectAll } =
      woListRef?.value?.gridApi.getServerSideSelectionState()
    let rows = []
    if (!selectAll) {
      rows = woListRef?.value?.gridApi.getSelectedRows()

      rows.forEach((row) => {
        selected_rows.value.push(row.id)
        // if (row.action_status == 2) {
        //   skip_rows.value.push(row.id)
        // } else {
        //   selected_rows.value.push(row.id)
        // }
      })
    } else {
      // rows =
      const filterModel = woListRef?.value?.gridApi?.getFilterModel()
      const filters = woListRef?.value?.filterBuild(filterModel)
    }
  }

  // console.log('selected_rows', selected_rows)
  // Check if any rows are selected
  if (!selected_rows.value || selected_rows.value.length === 0) {
    toaster.show({
      title: t('No selection'),
      color: 'danger',
    })
    return
  }

  // Open user selection modal
  // isModalUserListOpen.value = true
}

const handleModalUserListClose = () => {
  isModalUserListOpen.value = false
}

const closedPrint = () => {
  isPrint.value = false
}

const setUser = async (user) => {
  if (selected_rows.value) {
    const data = {
      collection: 'Work_order',
      keys: selected_rows.value,
      item: {
        assigned_to: user.id,
      },
    }
    await updateMultiple(user, 4)
    isModalUserListOpen.value = false
    // refresh

    woListRef?.value?.refresh(selected_rows)
    let msg = t(`Record updated successfully`)
    if (skip_rows.value.length > 0) {
      let woIds = skip_rows.value.join(', ')
      msg = woIds + ' numbers work order already approved and skipped assigned'
    }
    skip_rows.value = []
    selected_rows.value = []
  }
}

const updateMultiple = async (user, type) => {
  try {
    let url = runtimeConfig.public.directus.url + `items/Work_order`
    const { token } = useDirectusToken()

    const data = {
      keys: selected_rows.value,
      data: {
        assigned_to: user ? user.id : null,
        action_status: type,
      },
    }

    const response = await fetch(url, {
      method: 'PATCH', // Use PATCH method for updates
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.value}`,
      },
      body: JSON.stringify(data), // Convert data to JSON string
    })

    if (!response.ok) {
      toaster.show({
        title: t('Error'),
        message: t(`HTTP error! status: ${response.status}`),
        color: 'danger',
        closable: true,
      })
    } else {
      toaster.show({
        title: t('Updated'),
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
    }

    for (const item of selected_rows.value) {
      await createItems({
        collection: 'Work_order_actions',
        items: {
          wo_id: item,
          first_user: myId,
          next_user: user ? user.id : null,
          action_status: type,
          company_id: myCompanyId,
        },
      })
    }

    woListRef?.value?.refresh(selected_rows)
    return await response.json()
  } catch (error) {
    toaster.show({
      title: t('Error'),
      message: t('Failed to update work orders'),
      color: 'danger',
      closable: true,
    })
    return null
  }
}

const exportMultiple = async (filters) => {
  try {
    const encoded_filter = encodeURIComponent(JSON.stringify(filters))
    const { token } = useDirectusToken()
    let url =
      runtimeConfig.public.directus.url +
      `items/Work_order?export=csv&limit=-1&access_token=${token.value}&filter=${encoded_filter}`
    window.open(url, '_blank')
  } catch (error) {
    console.log(error)
    toaster.show({
      title: t('Error'),
      message: t('Failed to update work orders'),
      color: 'danger',
      closable: true,
    })
    return null
  }
}

onMounted(async () => {
  // console.log('onMounted_wo_statuses')
})

watch(active_tab, (newVal) => {
  // console.log('active_tab', sort.value, newVal)
  woTimeLineRef?.value?.newLoading()
})
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="" @click="handleExcelExportClick">
          <Icon name="fa6-solid:file-csv" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Export') }}</span>
        </BaseButton>

        <!-- <BaseButton class="ml-3" @click="do_assign_multi">
          <Icon name="ic:sharp-assignment-turned-in" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Assign') }}</span>
        </BaseButton> -->
        <BaseButton class="ml-3" @click="do_print">
          <Icon name="solar:printer-2-broken" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Print') }}</span>
        </BaseButton>
        <BaseButton class="ml-3 !p-0" @click="do_actions">
          <ActionDropdownMulti
            :ids="selected_rows"
            :onAcceptClick="do_accept"
            :onApproveClick="do_approve"
            :onDeleteClick="do_delete"
            :onDeclinedClick="do_decline"
            :onAssignClick="do_assign"
            :onReturnClick="do_return"
          />
        </BaseButton>
      </div>

      <!-- GridBody -->
      <div class="col-span-12 GridBody">
        <TairoContentWrapperTabbed
          :labels="[$t('List'), $t('Timeline'), $t('Perform')]"
          reverse
          :key="key"
          v-model="active_tab"
          shape="curved"
        >
          <template #tab-1>
            <WorkorderAgGridList
              ref="woListRef"
              :status="status"
              type="completed"
              className="tabGridBody"
              :wo_status="completed_wo_status"
              :wo_status_items="wo_status_items"
              :location="params.id"
              :work_order_type="'wo'"
              :show_location="true"
            />
          </template>
          <!-- <template #tab-2>
            <WorkOrderCalendar :status="status" :location="params.id" />
          </template> -->
          <template #tab-2>
            <DayPilot ref="woTimeLineRef" />
          </template>
          <template #tab-3>
            <Performance :status="status" :location="params.id" />
          </template>
        </TairoContentWrapperTabbed>
        <UserList
          :open="isModalUserListOpen"
          :close="handleModalUserListClose"
          :setUser="setUser"
        />
        <!-- <DemoPrintActivityMulti
          v-if="isPrint"
          :open="isPrint"
          :close="closedPrint"
          :wo_ids="selected_rows"
        /> -->
      </div>
    </div>
  </div>
</template>
