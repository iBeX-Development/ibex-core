<script setup lang="ts">
definePageMeta({
  title: 'My Assign',
  preview: {
    title: 'Preferences - My Assign',
    description: 'For account management',
    categories: ['layouts', 'settings'],
    src: '/img/screens/layouts-preferences-wallet.png',
    srcDark: '/img/screens/layouts-preferences-wallet-dark.png',
    order: 86,
    new: true,
  },
})

import {
  open_wo_status,
  wo_status_items,
} from '~/components/workorder/WorkOrderStatus'
const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()

const myId = window.localStorage.getItem('myId')
const status = ref({
  _in: [1, 2],
})
const selectedBlockchain = ref(0)
const selectedWallet = ref(0)

const { params } = useRoute()
const toaster = useToaster()
const woListRef = ref(null)
const isModalUserListOpen = ref(false)
const selected_rows = ref([])
const skip_rows = ref([])
const runtimeConfig = useRuntimeConfig()

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

const do_print = () => {
  console.log('Printing...')
}
</script>

<template>
  <div>
    <WorkorderAgGridList
      ref="woListRef"
      :status="status"
      type="open"
      :wo_status="open_wo_status"
      :wo_status_items="wo_status_items"
      :work_order_type="'wo'"
      :do_assign_multi="do_assign_multi"
      :do_print="do_print"
      :assigned="myId"
      className="myAssign"
    />
  </div>
</template>

<style>
.myAssign {
  margin-top: 60px;
}
</style>
