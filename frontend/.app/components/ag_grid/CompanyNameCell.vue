<template>
  <button
    type="button"
    class="text-left font-medium text-primary-600 hover:underline dark:text-primary-400"
    @click.stop="params.context.openUsers(params.data)"
  >
    {{ companyName }}
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const { params } = defineProps<{ params: any }>()

const companyName = computed(
  () => params.data?.name || params.data?.com_id || `#${params.data?.id || ''}`,
)
</script>
