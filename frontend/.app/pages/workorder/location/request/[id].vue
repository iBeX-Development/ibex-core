<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
// import WorkOrderList from '~/components/workorder/List.vue'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Request Lists',
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
  _eq: 1,
})
const { params } = useRoute()

const woListRef = ref(null)

const handleExcelExportClick = () => {
  woListRef?.value?.exportExcel()
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="left" @click="handleExcelExportClick">
          <Icon name="ri:file-excel-2-line" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Export excel') }}</span>
        </BaseButton>
      </div>

      <!-- GridBody -->
      <div class="col-span-12 GridBody">
        <WorkorderAgGridList
          ref="woListRef"
          :status="status"
          type="request"
          :wo_status="wo_status"
          :wo_status_items="wo_status_items"
          :location="params.id"
          :work_order_type="'request'"
        />
        <!-- <WorkOrderList
          ref="woListRef"
          :status="status"
          type="open"
          :work_order_type="'request'"
          :location="params.id"
        /> -->
      </div>
    </div>
  </div>
</template>
