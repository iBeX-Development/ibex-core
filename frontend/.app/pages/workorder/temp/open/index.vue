<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import WorkOrderCalendar from '~/components/workorder/Calendar.vue'
import WorkOrderList from '~/components/workorder/List.vue'

const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Work order open tasks',
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
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="left" to="/workorder/add">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Work order add') }}</span>
        </BaseButton>
      </div>
      <!-- Grid -->
      <div class="col-span-12">
        <TairoContentWrapperTabbed
          :labels="[$t('List'), $t('Calendar')]"
          reverse
          shape="curved"
        >
          <template #tab-1>
            <WorkOrderList
              :status="status"
              type="open"
              :work_order_type="'wo'"
            />
          </template>
          <template #tab-2>
            <WorkOrderCalendar />
          </template>
        </TairoContentWrapperTabbed>
      </div>
    </div>
  </div>
</template>
