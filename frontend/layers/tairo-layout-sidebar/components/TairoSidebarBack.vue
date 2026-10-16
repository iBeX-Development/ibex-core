<script setup lang="ts">
import { useRouter } from 'vue-router'
const router = useRouter()

const goBack = () => {
  router.back()
}
</script>

<template #header>
  <div class="group w-[35px] h-[27px] cursor-pointer">
    <Icon
      name="line-md:close"
      class="h-6 w-6 text-primary-500"
      @click="goBack"
    />
  </div>
</template>
