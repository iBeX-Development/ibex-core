<script setup lang="ts">
import SideBarNavigation from '~/components/global/SideBarNavigation'
const financeCategory = SideBarNavigation.find(
  (category) => category.name.split(' ')[0].toLowerCase() === 'health',
)
const navigation = [financeCategory]
const props = defineProps(['filter'])
console.log('health and safety', financeCategory)
</script>

<template>
  <TairoSubsidebar>
    <template #header>
      <TairoSubsidebarHeader />
    </template>

    <TairoSubsidebarMenu :navigation="navigation" />
  </TairoSubsidebar>
</template>
