<script setup lang="ts">
const route = useRoute()
const router = useRouter()

onMounted(() => {
  const to = route.query.to
  if (to) {
    router.replace(to as string)
  }
})
</script>

<template>
  <div class="loader">
    <BasePlaceholderPage subtitle="Loading">
      <template #image>
        <img
          class="block dark:hidden"
          src="/img/utils/loading.gif"
          alt="Placeholder image"
          style="height: 20px; width: 20px"
        />
        <img
          class="hidden dark:block"
          src="/img/utils/loading.gif"
          alt="Placeholder image"
          style="height: 20px; width: 20px"
        />
      </template>
    </BasePlaceholderPage>
  </div>
</template>
