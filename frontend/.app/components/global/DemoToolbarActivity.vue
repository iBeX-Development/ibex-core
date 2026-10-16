<script setup lang="ts">
const { open } = usePanels()
const colorMode = useColorMode()
</script>

<template>
  <button
    type="button"
    class="notifyIcon flex h-9 w-9 items-center justify-center rounded-full border ring-1 ring-transparent transition-all duration-300 hover:ring-offset-4"
    :class="
      colorMode.value === 'dark'
        ? 'border-muted-700 bg-muted-800 hover:ring-muted-700 ring-offset-muted-900'
        : 'border-muted-200 bg-white hover:ring-muted-200'
    "
    @click="open('activity')"
  >
    <Icon name="ph:circles-four-duotone" class="text-muted-400 h-5 w-5" />
  </button>
</template>
