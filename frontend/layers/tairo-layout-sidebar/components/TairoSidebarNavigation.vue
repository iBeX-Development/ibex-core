<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useSidebar } from '../composables/sidebar'

const props = withDefaults(
  defineProps<{
    subsidebar?: boolean
    expanded?: boolean
  }>(),
  {
    subsidebar: true,
    expanded: false,
  },
)

const { isOpen, current, sidebars } = useSidebar()
const router = useRouter()
const colorMode = useColorMode()

const panelWidth = ref(228)
const isResizing = ref(false)
const startX = ref(0)
const startWidth = ref(0)

const startResize = (e: MouseEvent) => {
  isResizing.value = true
  startX.value = e.clientX
  startWidth.value = panelWidth.value
}

const onResize = (e: MouseEvent) => {
  if (!isResizing.value) return
  const diff = e.clientX - startX.value
  panelWidth.value = Math.max(200, Math.min(500, startWidth.value + diff))
}

const stopResize = () => {
  isResizing.value = false
}

onMounted(() => {
  window.addEventListener('mousemove', onResize)
  window.addEventListener('mouseup', stopResize)
})

onUnmounted(() => {
  window.removeEventListener('mousemove', onResize)
  window.removeEventListener('mouseup', stopResize)
})

const startSidebars = computed(() =>
  sidebars.value?.filter(
    (sidebar) => !sidebar.position || sidebar.position === 'start',
  ),
)
const endSidebars = computed(() =>
  sidebars.value?.filter((sidebar) => sidebar.position === 'end'),
)

const subsidebarEnabled = computed(() => {
  return Boolean(
    props.subsidebar !== false && current.value?.subsidebar?.component,
  )
})
</script>

<template>
  <div
    class="pointer-events-none fixed start-0 top-0 z-[60] flex h-full xl:z-80 select-none"
  >
    <!-- Icon sidebar -->
    <div
      class="Icon pointer-events-auto relative z-20 flex h-full w-[80px] flex-col border-r transition-all duration-300"
      :class="[
        colorMode.value === 'dark'
          ? 'border-muted-700 bg-muted-800'
          : 'border-muted-200 bg-white',
        isOpen
          ? ''
          : '-translate-x-full rtl:translate-x-full xl:translate-x-0 rtl:xl:-translate-x-0',
      ]"
    >
      <slot></slot>

      <!-- Top Menu -->
      <div class="TopMenu">
        <slot name="top"></slot>

        <TairoSidebarNavigationItem
          v-for="item in startSidebars"
          :key="item.title"
          :sidebar="item"
        />
      </div>
      <!-- Bottom Menu -->
      <div class="mt-auto BottomMenu">
        <div class="flex h-10 w-full items-center justify-center">
          <DemoButton
            :actions="
              () => {
                router.push(`/workorder/request/add`)
              }
            "
          />
        </div>
        <TairoSidebarNavigationItem
          v-for="item in endSidebars"
          :key="item.title"
          :sidebar="item"
        />

        <slot name="end"></slot>
      </div>
    </div>

    <!-- Menu panel -->
    <div
      v-if="subsidebarEnabled"
      class="locationsPanel panel pointer-events-auto relative z-10 h-full border-r transition-all duration-300"
      :style="{ width: `${panelWidth}px` }"
      :class="[
        colorMode.value === 'dark'
          ? 'border-muted-700 bg-muted-800'
          : 'border-muted-200 bg-white',
        isOpen
          ? ''
          : 'rtl:translate-x-[calc(100%_+_80px)] translate-x-[calc(-100%_-_80px)]',
      ]"
    >
      <!-- Enhanced Resize handle -->
      <div
        class="startResize absolute -right-2 top-0 items-center h-full w-4 group cursor-col-resize flex justify-center hover:bg-muted-100/50 dark:hover:bg-muted-700/50 transition-all duration-200"
        @mousedown="startResize"
      >
        <!-- Vertical grip pattern with better spacing -->
        <div
          class="resizePoints flex flex-col items-center space-y-1 opacity-50 group-hover:opacity-100 transition-opacity duration-200"
        >
          <!-- Top grip dots -->
          <div class="flex space-x-0.5">
            <div
              class="w-0.5 h-0.5 bg-muted-500 dark:bg-muted-400 rounded-full"
            ></div>
            <div
              class="w-0.5 h-0.5 bg-muted-500 dark:bg-muted-400 rounded-full"
            ></div>
          </div>
          <!-- Middle grip dots -->
          <div class="flex space-x-0.5">
            <div
              class="w-0.5 h-0.5 bg-muted-500 dark:bg-muted-400 rounded-full"
            ></div>
            <div
              class="w-0.5 h-0.5 bg-muted-500 dark:bg-muted-400 rounded-full"
            ></div>
          </div>
          <!-- Bottom grip dots -->
          <div class="flex space-x-0.5">
            <div
              class="w-0.5 h-0.5 bg-muted-500 dark:bg-muted-400 rounded-full"
            ></div>
            <div
              class="w-0.5 h-0.5 bg-muted-500 dark:bg-muted-400 rounded-full"
            ></div>
          </div>
        </div>

        <!-- Active resize indicator -->
        <div
          class="absolute right-0 top-0 h-full w-1 bg-transparent group-hover:bg-primary-500 transition-all duration-200 rounded-l-sm"
        ></div>
      </div>

      <slot name="subnav">
        <KeepAlive>
          <component
            :is="resolveComponentOrNative(current.subsidebar?.component)"
            :key="current?.subsidebar?.component"
            v-if="current?.subsidebar?.component"
          ></component>
        </KeepAlive>
      </slot>
    </div>
  </div>
</template>
