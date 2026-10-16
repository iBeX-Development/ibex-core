<script setup lang="ts">
import SideBarNavigation from '~/components/global/SideBarNavigation'
const financeCategory = SideBarNavigation.find(
  (category) => category.name.toLowerCase() === 'inspection',
)
const navigation = [financeCategory]
const props = defineProps(['filter'])
console.log('props_inspections', financeCategory)
</script>

<template>
  <TairoSubsidebar>
    <template #header>
      <TairoSubsidebarHeader />
    </template>

    <TairoSubsidebarMenu :navigation="navigation" />
  </TairoSubsidebar>
</template>
