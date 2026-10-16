<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{ params: any }>()

const label = computed(() => props.params.label ?? props.params.displayName ?? '')
const isVisible = computed(() => props.params.isVisible?.())

const onToggle = () => {
  props.params.onToggle?.()
}
</script>

<template>
  <div class="flex flex-col items-start gap-1 py-1">
    <span :class="{ 'opacity-40': !isVisible }">{{ label }}</span>
    <button
      type="button"
      class="relative inline-flex h-4 w-7 shrink-0 rounded-full transition-colors"
      :class="isVisible ? 'bg-primary-500' : 'bg-muted-300 dark:bg-muted-600'"
      title="Show in charts"
      @click.stop="onToggle"
    >
      <span
        class="absolute top-0.5 left-0.5 h-3 w-3 rounded-full bg-white shadow transition-transform"
        :class="isVisible ? 'translate-x-3' : 'translate-x-0'"
      />
    </button>
  </div>
</template>
