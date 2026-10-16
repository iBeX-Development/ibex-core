<script setup lang="ts">
import SideBarNavigation from "~/components/global/SideBarNavigationSettings";
const financeCategory = SideBarNavigation.find(category => category.name.toLowerCase() === 'users and team');
const navigation = [financeCategory];
const props = defineProps(['filter']);
console.log(props)
</script>

<template>
  <TairoSubsidebar>
    <template #header>
      <TairoSubsidebarHeader />
    </template>

    <TairoSubsidebarMenu :navigation="navigation" />
  </TairoSubsidebar>
</template>
