<script setup lang="ts">
import { useSidebar } from '../composables/sidebar'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const props = withDefaults(
  defineProps<{
    sidebar?: boolean
    horizontalScroll?: boolean
  }>(),
  {
    sidebar: true,
  },
)

const app = useAppConfig()
const { hasSubsidebar } = useSidebar()

const route = useRoute()

const showNavBurger = computed(() => {
  return (
    props.sidebar &&
    app.tairo.sidebar?.toolbar?.showNavBurger &&
    hasSubsidebar.value
  )
})
</script>

<template>
  <div
    class="toolBar relative z-50 flex h-16 items-center gap-2"
    :class="props.horizontalScroll && 'pe-4 xl:pe-10'"
  >
    <TairoSidebarBurger v-if="showNavBurger" class="-ms-3" />
    <TairoSidebarBack v-if="route.meta.showback == true" class="back" />

    <BaseHeading
      v-if="app.tairo.sidebar?.toolbar?.showTitle"
      as="h1"
      size="2xl"
      weight="light"
      class="text-muted-800 hidden dark:text-white md:block MainTitle"
    >
      <slot name="title">{{
        route.meta.title ? t(String(route.meta.title)) : ''
      }}</slot>
    </BaseHeading>

    <div class="ms-auto"></div>
    <TairoSidebarTools class="h-16" />
  </div>
</template>
