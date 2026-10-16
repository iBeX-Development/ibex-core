<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import WorkOrderList from '~/components/workorder/List.vue'
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
  _eq: 3,
})
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <WorkOrderList :status="status" type="completed" />
      </div>
    </div>
  </div>
</template>
