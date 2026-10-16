<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AgGridListInspection from '~/components/workorder/AgGridListInspection.vue'

const { t } = useI18n({ useScope: 'global' })
const myId = window.localStorage.getItem('myId')
const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

import {
  wo_status,
  wo_status_items,
} from '~/components/workorder/WorkOrderStatus'

definePageMeta({
  middleware: ['auth'],
  title: 'Inspections',
  preview: {
    title: 'Inspections',
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

let avtiveTab = ref('tab-1')
const woListRef = ref(null)
const isModalUserListOpen = ref(false)
const selected_rows = ref([])
const skip_rows = ref([])
const runtimeConfig = useRuntimeConfig()

console.log(params)

const do_assign_multi = () => {
  // Clear previous selections
  selected_rows.value = []
  skip_rows.value = []

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

const updateMultiple = async (user) => {
  try {
    let url = runtimeConfig.public.directus.url + `items/Work_inspections`
    const { token } = useDirectusToken()

    const data = {
      keys: selected_rows.value,
      data: {
        assigned_to: user.id,
        action_status: 4,
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
    }

    for (const item of selected_rows.value) {
      await createItems({
        collection: 'Work_inpection_actions',
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
    console.log('error', error)
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
      collection: 'Work_inspections',
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
  <div class="relative inspection_list">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="left" :to="`/inspection/new/${params.id}`">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Add') }}</span>
        </BaseButton>
        <BaseButton
          v-if="avtiveTab === 'tab-1'"
          class="ml-3"
          @click="do_assign_multi"
        >
          <Icon name="ic:sharp-assignment-turned-in" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Assign to') }}</span>
        </BaseButton>

        <BaseButton class="ml-3">
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
          :labels="[$t('List'), $t('Delivered'), $t('Completed')]"
          :value="avtiveTab"
          v-model="avtiveTab"
          reverse
          shape="curved"
        >
          <template #tab-1>
            <div v-if="avtiveTab === 'tab-1'">
              <AgGridListInspection
                ref="woListRef"
                :status="status"
                type="inspection"
                code="inspection"
                tab="inspection_templates"
                :wo_status="wo_status"
                :wo_status_items="wo_status_items"
                :location="params.id"
                :work_order_type="'inspection'"
              />
            </div>
          </template>
          <template #tab-2>
            <div v-if="avtiveTab == 'tab-2'">
              <AgGridListInspection
                :status="status"
                type="inspection"
                code="inspection"
                tab="delivered"
                :wo_status="wo_status"
                :wo_status_items="wo_status_items"
                :location="params.id"
                :work_order_type="'inspection'"
              />
            </div>
          </template>
          <template #tab-3>
            <div v-if="avtiveTab == 'tab-3'">
              <AgGridListInspection
                :status="status"
                type="inspection"
                code="inspection"
                tab="completed"
                :wo_status="wo_status"
                :wo_status_items="wo_status_items"
                :location="params.id"
                :work_order_type="'inspection'"
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
.inspection_list .nui-tabs-inner {
}
.inspection_list .bg-white-tab {
  background: white;
}
</style>
