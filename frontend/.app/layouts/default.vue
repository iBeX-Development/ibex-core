<template>
  <TairoSidebarLayout>
    <slot />
    <AlertNotificationCenter />
  </TairoSidebarLayout>
</template>

<script setup lang="ts">
import { useFirebaseMessaging } from '../compsables/useFirebaseMessaging'

onMounted(async () => {
  await useFirebaseMessaging()
})
</script>
