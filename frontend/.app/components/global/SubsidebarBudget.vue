<script setup lang="ts">
import SideBarNavigation from '~/components/global/SideBarNavigation'

const budgetCategory = SideBarNavigation.find(
  (category) => category.name.toLowerCase() === 'budgets',
)
const navigation = [budgetCategory]
</script>

<template>
  <TairoSubsidebar>
    <template #header>
      <TairoSubsidebarHeader />
    </template>
    <TairoSubsidebarMenu :navigation="navigation" />
  </TairoSubsidebar>
</template>
