<script setup lang="ts">
import NormalForm from '~/components/form/NormalForm.vue'
const { params } = useRoute()

definePageMeta({
  middleware: ['auth'],
  title: 'New asset',
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
      <div class="col-span-12">
        <NormalForm
          title="Assets"
          code="Assets"
          schema_column="three-column-form"
          :row="parseInt(params.id)"
        />
      </div>
    </div>
  </div>
</template>
