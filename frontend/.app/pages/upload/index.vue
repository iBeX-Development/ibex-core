<script setup lang="ts">
import { Calendar } from 'v-calendar'

import 'v-calendar/dist/style.css'
import '~/assets/css/vcalendar.css'

definePageMeta({
  middleware: ["auth"],
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})
const user = useDirectusUser();
const files = ref([]);
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseCard>
          <p>Test 1</p>
          <BaseInputFileHeadlessOverrided v-model="files"/>
          <p>Test 2</p>
        </BaseCard>
      </div>
    </div>
  </div>
</template>
