<script setup lang="ts">
import { onMounted, onUnmounted, watch } from 'vue'

const {
  panels,
  current,
  transitionFrom,
  currentProps,
  showOverlay,
  open,
  close,
} = usePanels()

watch(
  () => current.value,
  (panel) => {
    document.documentElement.classList.toggle('panel-open', Boolean(panel))
  },
  { immediate: true },
)

onMounted(() => {
  document.documentElement.classList.add('overflow-hidden')
})

onUnmounted(() => {
  document.documentElement.classList.remove('panel-open')
})
</script>

<template>
  <div>
    <Transition
      enter-active-class="transition-transform duration-300 ease-out"
      :enter-from-class="
        transitionFrom === 'left'
          ? '-translate-x-full rtl:translate-x-full'
          : 'translate-x-full rtl:-translate-x-full'
      "
      leave-active-class="transition-transform duration-300 ease-in"
      :leave-to-class="
        transitionFrom === 'left'
          ? '-translate-x-full rtl:translate-x-full'
          : 'translate-x-full rtl:-translate-x-full'
      "
    >
      <slot
        v-bind="{
          panels,
          current,
          transitionFrom,
          currentProps,
          showOverlay,
          open,
          close,
        }"
      >
        <Suspense>
          <component
            :is="resolveComponentOrNative(current.component)"
            v-bind="currentProps"
            v-if="current?.component"
            :key="`${current.name}-${(currentProps as any)?.id ?? ''}`"
            class="fixed top-0 z-[100] h-full w-96 overflow-hidden"
            :class="[current.position === 'left' ? 'start-0' : 'end-0']"
          />
        </Suspense>
      </slot>
    </Transition>

    <div
      class="disabler bg-muted-800/60 fixed start-0 top-0 z-[99] h-full w-full cursor-pointer transition-opacity duration-300"
      :class="
        current && showOverlay
          ? 'opacity-100 pointer-events-auto'
          : 'opacity-0 pointer-events-none'
      "
      @click="close"
    />
  </div>
</template>

<style>
:global(html.panel-open),
:global(html.panel-open body) {
  overflow: hidden !important;
}
</style>
