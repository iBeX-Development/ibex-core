<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
import DeletionModalForm from '~/components/form/DeletionModalForm.vue'
const { params } = useRoute()

import {
  wo_status,
  wo_status_items,
} from '~/components/workorder/WorkOrderStatus'

const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Request list',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})
const { getItems } = useDirectusItems()
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const key = ref(1)
const status = ref({
  _neq: 3,
})

const toaster = useToaster()

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
  console.log(isModalOpen.value)
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log(isModalOpen.value)
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const do_edit = (item) => {
  // Perform your action here
  selectedItem.value = item.id
  console.log(selectedItem.value)
  // isModalOpen.value = true;
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const clearItem = () => {
  selectedItem.value = -1
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-1">
      <!-- <WorkorderList
        :status="status"
        type="open"
        :work_order_type="'request'"
      /> -->

      <WorkorderAgGridList
        ref="woListRef"
        :status="status"
        type="request"
        :wo_status="wo_status"
        :wo_status_items="wo_status_items"
        :location="params.id"
        :work_order_type="'request'"
      />

      <DeletionModalForm
        :key="selectedItem"
        code="Work_request"
        :open="isModalConfirmOpen"
        :close="handleModalConfirmClose"
        :row="selectedItem"
        :refresh="handleChangeKey"
        :clear="clearItem"
      />
    </div>
  </div>
</template>
