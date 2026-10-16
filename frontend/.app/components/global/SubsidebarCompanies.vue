<script setup lang="ts">
let itemCategory = ref<any[]>([
  {
    name: 'Companies',
    // is_direct: true,
    is_open: true,
    children: [
      {
        name: 'Companies',
        icon: 'codicon:git-pull-request-go-to-changes',
        to: '/companies',
        action: 'read',
        collection: 'Companies',
        exact: true,
        is_direct: true,
      },
    ],
  },
  {
    name: 'Upgrades',
    is_open: true,
    // is_direct: true,
    // action: 'read',
    children: [
      {
        name: 'Pricing',
        icon: 'material-symbols-light:upload',
        to: '/pricing',
        action: 'read',
        collection: 'Pricing',
        exact: false,
      },
    ],
  },
])

const navigation = itemCategory
const props = defineProps(['filter'])
console.log(props)
</script>

<template>
  <TairoSubsidebar>
    <template #header>
      <TairoSubsidebarHeader />
    </template>

    <TairoSubsidebarMenu :navigation="(itemCategory as any)" />
  </TairoSubsidebar>
</template>
