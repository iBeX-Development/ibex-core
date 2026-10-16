<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { useSidebar } from '../composables/sidebar'
import type { SidebarNavigationItemConfig } from '../types'

const props = defineProps<{
  sidebar: SidebarNavigationItemConfig
}>()

const { currentName, isOpen } = useSidebar()
const { t } = useI18n({ useScope: 'global' })
const router = useRouter()

function onSidebarItemClick() {
  console.log('onSidebarItemClick', props)
  // Inspections table-list V1
  // Teams personal V2
  // Projects Projects V3
  // Contractors  table-list V3

  if (props.sidebar.auto_click === true) {
    router.push(`/${props.sidebar.push}`)
  }

  if (typeof props.sidebar.click === 'function') {
    return props.sidebar.click()
  }

  currentName.value = props.sidebar.title
  if (props.sidebar.title == 'MyTask' || props.sidebar.title == 'Reports') {
    isOpen.value = false
  } else isOpen.value = true
}

onMounted(() => {
  if (!currentName.value) {
    console.log('Auto-clicking', currentName.value)
    onSidebarItemClick()
  }
})
</script>

<template>
  <div class="menulevel flex h-16 w-full items-center justify-center">
    <span>{{ props.sidebar.order }}</span>
    <component
      :is="resolveComponentOrNative(props.sidebar.component)"
      v-if="props.sidebar.component"
      v-bind="props.sidebar.props"
    />
    <NuxtLink
      v-else-if="props.sidebar.to && props.sidebar.icon"
      :to="props.sidebar.to"
      class="text-muted-400 flex h-12 w-12 items-center justify-center rounded-2xl transition-colors duration-300"
      data-nui-tooltip-position="right"
      :data-nui-tooltip="t(props.sidebar.title || '')"
    >
      <Icon v-bind="props.sidebar.icon" />
    </NuxtLink>

    <button
      v-else-if="props.sidebar.icon"
      type="button"
      class="menu flex h-12 w-12 items-center justify-center rounded-2xl transition-colors duration-300"
      :class="
        currentName === props.sidebar.title
          ? 'bg-primary-100 text-primary-500 dark:bg-primary-500/10'
          : 'text-muted-400'
      "
      data-nui-tooltip-position="right"
      :data-nui-tooltip="t(props.sidebar.title || '')"
      @click="onSidebarItemClick"
    >
      <Icon v-bind="props.sidebar.icon" />
    </button>
  </div>
</template>
