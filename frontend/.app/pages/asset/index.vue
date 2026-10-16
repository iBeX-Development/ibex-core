<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Equipments',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12"></div>
      <!-- Grid -->
      <div class="col-span-12">
        <TairoContentWrapperTabbed
          :labels="[$t('Tree'), $t('List')]"
          reverse
          shape="curved"
        >
          <template #tab-1>
            <AssetsTree />
          </template>
          <template #tab-2>
            <AssetsList />
          </template>
        </TairoContentWrapperTabbed>
      </div>
    </div>
  </div>
</template>
