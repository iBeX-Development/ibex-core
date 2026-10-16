<script setup lang="ts">
const props = defineProps<{
  label?: string
  hideLabel?: boolean
  click?: Function
  filter?: boolean
  tabletHidden?: boolean
}>()
</script>

<template>
  <div
    class="relative flex h-8 items-center justify-end px-6 sm:h-10 sm:justify-center sm:px-2"
    :class="props.tabletHidden && 'ptablet:hidden'"
  >
    <div
      v-if="props.label"
      class="flex justify-center text-muted-400 absolute start-8 top-1/2 mx-auto -translate-y-1/2 text-center font-sans text-xs font-medium uppercase sm:inset-x-0 sm:-top-20 sm:translate-y-0"
      :class="props.hideLabel ? 'sm:hidden' : ''"
    >
      <div>{{ props.label }}</div>
      <div v-if="props.filter" :class="props.hideLabel ? 'sm:hidden' : ''">
        <div class="w-8 cursor-pointer" @click="props.click">
          <Icon name="ion:filter" class="w-4 h-4" />
        </div>
      </div>
    </div>
    <slot></slot>
  </div>
</template>
