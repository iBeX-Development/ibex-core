<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
const { t } = useI18n({ useScope: 'global' })
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const toaster = useToaster()
const { params } = useRoute()

definePageMeta({
  middleware: ['auth'],
  title: 'New asset',
  showback: true,
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})

const props = defineProps({
  open: Boolean,
  title: String,
  close: Function,
  refresh: Function,
  row: Number,
  id: Number,
  code: String,
})
</script>

<template>
  <div class="relative">
    <div class="grid grid-cols-12 gap-6">
      <div class="col-span-8">
        <AssetsForm
          :row="-1"
          title="Assets"
          code="Assets"
          :location="Number(params.location)"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-safety-note-wrapper .max-w-md {
  max-width: none !important;
  width: 100% !important;
}
</style>
