<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AgGridListPm from '~/components/workorder/AgGridListPm.vue'
import WorkOrderCalendar from '~/components/workorder/Calendar.vue'

import {
  open_status_id,
  wo_status,
} from '~/components/workorder/WorkOrderStatus'
const { t } = useI18n({ useScope: 'global' })
const myId = window.localStorage.getItem('myId')
const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

import { wo_status_items } from '~/components/workorder/WorkOrderStatus'

definePageMeta({
  middleware: ['auth'],
  title: 'Preventative Maintenances',
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
  _neq: 3,
})

const { params } = useRoute()
const toaster = useToaster()
const runtimeConfig = useRuntimeConfig()

let avtiveTab = ref('tab-1')

const woListRef = ref(null)
const isModalUserListOpen = ref(false)
const selected_rows = ref([])
const skip_rows = ref([])

const woAcceptRef = ref(null)
const isAcceptOpen = ref(false)
const selected_accept_rows = ref([])
const skip_accept_rows = ref([])

console.log(params)

const refresh = (item) => {
  // console.log('refreshed')
  if (item) {
    // const newItem = { id: 6, name: "New Item", price: 100 };
    // const updatedData = [...gridApi.value.getDisplayedRowCount(), item];
    // gridApi.value.setRowData(updatedData);
    //   const newItem = { id: 6, name: "New Item", price: 100 };
    // gridOptions.api.applyTransaction({ add: [newItem] });
  }

  // gridApi.value.purgeInfiniteCache()
  // gridApi.value.refreshCells({ force: true })
  // gridApi.value.refreshServerSide({ purge: false })
  // gridApi.value.deselectAll()

  // gridApi.value.refreshServerSide()
  // gridApi.value.onFilterChanged()
  // gridApi.value.refreshInfiniteCache()
  // gridApi.valuerefreshServerSideStore({ purge: true });
}

const do_accept_multi = async () => {
  // Clear previous selections
  selected_accept_rows.value = []
  skip_accept_rows.value = []

  console.log('do_accept_multis', selected_accept_rows.value.length)

  // Get selected rows using the exposed method
  if (woAcceptRef?.value?.gridApi) {
    const { selectAll } =
      woAcceptRef?.value?.gridApi.getServerSideSelectionState()
    let rows = []
    if (!selectAll) {
      rows = woAcceptRef?.value?.gridApi.getSelectedRows()

      rows.forEach((row) => {
        if (row.action_status == 2) {
          skip_accept_rows.value.push(row.id)
        } else {
          selected_accept_rows.value.push(row.id)
        }
      })
    } else {
      // rows =
      const filterModel = woAcceptRef?.value?.gridApi?.getFilterModel()
      const filters = woAcceptRef?.value?.filterBuild(filterModel)
    }
  }

  // Check if any rows are selected
  if (!selected_accept_rows.value || selected_accept_rows.value.length === 0) {
    toaster.show({
      title: t('No selection'),
      message: t('Please select work orders to accept'),
      color: 'danger',
    })
    return
  }

  await acceptMultiple()

  woAcceptRef?.value?.refresh(selected_accept_rows)

  let msg = t('Record updated successfully')
  if (skip_accept_rows.value.length > 0) {
    let woIds = skip_accept_rows.value.join(', ')
    msg = woIds + ' numbers work order already approved and skipped'
  }
  skip_accept_rows.value = []
  selected_accept_rows.value = []

  toaster.show({
    title: t('Update'),
    message: msg + '!',
    color: 'success',
    icon: 'ph:check-circle-fill',
    closable: true,
  })
}

const do_assign_multi = () => {
  // Clear previous selections
  selected_rows.value = []
  skip_rows.value = []

  console.log('do_assign_multis', selected_rows.value.length)
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
      message: t('Please select work orders to assign'),
      color: 'danger',
    })
    return
  }
  // Open user selection modal
  isModalUserListOpen.value = true
}

const handleModalUserListClose = () => {
  isModalUserListOpen.value = false
}

const acceptMultiple = async () => {
  try {
    let url = runtimeConfig.public.directus.url + `items/Work_pm`
    const { token } = useDirectusToken()

    const data = {
      keys: selected_accept_rows.value,
      data: {
        created_type: 'open',
        action_status: 2, //approved
        type: 2, //unplanned
        wo_status: open_status_id,
        accepted_user: myId,
        is_accepted: true,
      },
    }

    const response = await fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.value}`,
      },
      body: JSON.stringify(data),
    })

    if (!response.ok) {
      toaster.show({
        title: t('Error'),
        message: t(`HTTP error! status: ${response.status}`),
        color: 'danger',
        closable: true,
      })
      return null
    }

    for (const item of selected_accept_rows.value) {
      await createItems({
        collection: 'Work_pm_actions',
        items: {
          wo_id: item,
          first_user: myId,
          action_status: 2,
          type: 'pm_to_open | created_type:generated_to_open',
          company_id: myCompanyId,
        },
      })
    }

    return await response.json()
  } catch (error) {
    toaster.show({
      title: t('Error'),
      message: t('Failed to accept work orders'),
      color: 'danger',
      closable: true,
    })
    return null
  }
}

const updateMultiple = async (user) => {
  try {
    let url = runtimeConfig.public.directus.url + `items/Work_pm`
    const { token } = useDirectusToken()

    const data = {
      keys: selected_rows.value,
      data: {
        assigned_to: user.id,
        action_status: 4,
      },
    }
    console.log('updateMultiple', data)
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
    }

    for (const item of selected_rows.value) {
      await createItems({
        collection: 'Work_pm_actions',
        items: {
          wo_id: item,
          first_user: myId,
          next_user: user.id,
          action_status: 4,
          company_id: myCompanyId,
        },
      })
    }

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

const setUser = async (user) => {
  if (selected_rows.value) {
    const data = {
      collection: 'Work_pm',
      keys: selected_rows.value,
      item: {
        assigned_to: user.id,
      },
    }
    await updateMultiple(user)
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

    toaster.show({
      title: t('Update'),
      message: msg + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }
}

const do_start_mulit = () => {
  // Get selected rows using the exposed method
  console.log('running')
}
</script>

<template>
  <div class="relative pm_list">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="left" :to="`/pm/new/${params.id}`">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('PM add') }}</span>
        </BaseButton>
        <!-- <BaseButton
          v-if="avtiveTab === 'tab-2'"
          class="ml-3"
          @click="do_accept_multi"
        >
          <Icon name="ic:sharp-assignment-turned-in" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Accept to') }}</span>
        </BaseButton> -->
        <BaseButton
          v-if="avtiveTab === 'tab-1'"
          class="ml-3"
          @click="do_assign_multi"
        >
          <Icon name="ic:sharp-assignment-turned-in" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Assign to') }}</span>
        </BaseButton>

        <BaseButton class="ml-3" @click="do_start_mulit">
          <Icon
            name="bpmn:start-event-non-interrupting-condition"
            class="-ms-1 h-4 w-4"
          />
          <span class="text-[11px]">{{ $t('Start') }}</span>
        </BaseButton>
      </div>

      <!-- GridBody -->
      <div class="col-span-12 GridBody">
        <div class="bg-white-tab"></div>

        <TairoContentWrapperTabbed
          :labels="[$t('List'), $t('Generated'), $t('Calendar')]"
          :value="avtiveTab"
          v-model="avtiveTab"
          reverse
          shape="curved"
        >
          <template #tab-1>
            <div v-if="avtiveTab === 'tab-1'">
              <AgGridListPm
                ref="woListRef"
                :status="status"
                type="pm"
                tab="pm_templates"
                :wo_status="wo_status"
                :wo_status_items="wo_status_items"
                :location="params.id"
                :work_order_type="'pm'"
              />
            </div>
          </template>
          <template #tab-2>
            <div v-if="avtiveTab == 'tab-2'">
              <AgGridListPm
                ref="woAcceptRef"
                :status="status"
                type="pm"
                tab="generated"
                :wo_status="wo_status"
                :wo_status_items="wo_status_items"
                :location="params.id"
                :work_order_type="'pm'"
              />
            </div>
          </template>
          <template #tab-3>
            <div v-if="avtiveTab == 'tab-3'">
              <WorkOrderCalendar
                :status="status"
                :location="params.id"
                collection="Work_pm"
              />
            </div>
          </template>
        </TairoContentWrapperTabbed>
        <UserList
          :open="isModalUserListOpen"
          :close="handleModalUserListClose"
          :setUser="setUser"
        />
      </div>
    </div>
  </div>
</template>

<style>
.pm_list .nui-tabs-inner {
}
.pm_list .bg-white-tab {
  background: white;
}
</style>
