<script setup lang="ts">
import { useSidebar } from '../composables/sidebar'
const { token } = useDirectusToken()

const props = withDefaults(
  defineProps<{
    sidebar?: boolean
    subsidebar?: boolean
    toolbar?: boolean
    circularMenu?: boolean
    condensed?: boolean
    horizontalScroll?: boolean
  }>(),
  {
    sidebar: true,
    subsidebar: true,
    toolbar: true,
    circularMenu: true,
  },
)

if (!token.value) {
  console.log('token=>', token)
  navigateTo('/login')
}

const app = useAppConfig()
const { setup, currentName, isOpen, toggle } = useSidebar()
setup()

onMounted(() => {
  document.documentElement.classList.add('overflow-hidden')
})

onUnmounted(() => {
  // document.documentElement.classList.remove('overflow-hidden')
  currentName.value = ''
  isOpen.value = undefined
})

const sidebarEnabled = computed(() => {
  return (
    app.tairo.sidebar?.navigation?.enabled !== false && props.sidebar !== false
  )
})
const toolbarEnabled = computed(() => {
  return (
    app.tairo.sidebar?.toolbar?.enabled !== false && props.toolbar !== false
  )
})
const circularMenuEnabled = computed(() => {
  return (
    app.tairo.sidebar?.circularMenu?.enabled !== false &&
    props.circularMenu !== false
  )
})

const wrapperClass = computed(() => {
  if (props.condensed) {
    return 'mainClass4 bg-muted-100 dark:bg-muted-900 relative min-h-screen w-full overflow-x-hidden'
  }

  if (!sidebarEnabled.value) {
    return 'mainClass5 bg-muted-100 dark:bg-muted-900 relative min-h-screen w-full overflow-x-hidden px-4 transition-all duration-300 xl:px-10'
  }

  const list = [
    'mainClass6 bg-muted-100 dark:bg-muted-900 relative h-screen w-full overflow-y-auto px-4 transition-all duration-300 xl:px-10',
  ]

  if (isOpen.value) {
    list.push('xl:max-w-[calc(100%_-_300px)] xl:ms-[300px]')
  } else {
    list.push('xl:max-w-[calc(100%_-_80px)] xl:ms-[80px]')
  }

  if (props.horizontalScroll) {
    list.push('!pe-0 xl:!pe-0')
  }

  return list
})
</script>

<template>
  <div class="sidebarlayout bg-muted-100 dark:bg-muted-900 pb-20">
    <slot name="sidebar">
      <TairoSidebarNavigation
        v-if="sidebarEnabled"
        :subsidebar="props.subsidebar"
      >
        <div
          v-if="app.tairo.sidebar?.navigation?.logo?.component"
          class="menus comLogo flex h-16 w-full items-center justify-center logo"
        >
          <slot name="logo">
            <NuxtLink to="/" class="flex items-center justify-center">
              <component
                :is="
                  resolveComponentOrNative(
                    app.tairo.sidebar?.navigation.logo.component,
                  )
                "
                v-bind="app.tairo.sidebar?.navigation.logo.props"
              ></component>
            </NuxtLink>
          </slot>
        </div>
      </TairoSidebarNavigation>
      <div
        role="button"
        class="bg-muted-800 dark:bg-muted-900 fixed start-0 top-0 z-[59] block h-full w-full transition-opacity duration-300 lg:hidden"
        :class="
          isOpen
            ? 'opacity-50 dark:opacity-75'
            : 'opacity-0 pointer-events-none'
        "
        @click="toggle"
      ></div>
    </slot>

    <div :class="wrapperClass">
      <div
        :class="[
          props.condensed && !props.horizontalScroll && 'w-full',
          !props.condensed && props.horizontalScroll && 'mx-auto w-full',
          !props.condensed &&
            !props.horizontalScroll &&
            'mx-auto w-full max-w-7xl large2',
        ]"
        style="max-width: calc(100% - 100px)"
      >
        <slot name="toolbar">
          <TairoSidebarToolbar
            v-if="toolbarEnabled"
            :sidebar="props.sidebar"
            :horizontal-scroll="props.horizontalScroll"
          >
            <template #title><slot name="toolbar-title"></slot></template>
          </TairoSidebarToolbar>
        </slot>

        <main>
          <slot />
        </main>
      </div>
    </div>

    <TairoPanels />
    <TairoSidebarCircularMenu v-if="circularMenuEnabled" />
  </div>
</template>

<style scoped>
/* .mainClass6 {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.mainClass6::-webkit-scrollbar {
  display: none;
} */
</style>
