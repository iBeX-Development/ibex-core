<script setup lang="ts">
const props = defineProps<{
  name: string
  collection?: string
  is_open?: boolean
  children: {
    name: string
    icon: string
    to: string
    exact?: boolean
  }[]
}>()
import { useI18n } from 'vue-i18n'

const open = ref(false)
const route = useRoute()
const buttonRef = ref<HTMLElement>()
const router = useRouter()
const { t } = useI18n({ useScope: 'global' })

function hasPath(value: unknown): value is string {
  return typeof value === 'string' && value.length > 0
}

const hasActiveChild = computed(() => {
  return props.children.some((item) => {
    if (!hasPath(item.to)) {
      return false
    }

    if (item.exact === true) {
      return route.path === item.to
    }

    return route.path.startsWith(item.to)
  })
})

onMounted(() => {
  if (props.is_open) open.value = true

  if (props.name === 'Works') {
    // Auto-navigate to Work Orders if not already on a work-related page
    const workOrdersChild = props.children.find(
      (child) => child.name === 'Work Orders',
    )
    if (workOrdersChild && !hasActiveChild.value) {
      nextTick(() => {
        router.push(workOrdersChild.to)
      })
    }
  }
})

watchEffect(() => {
  if (hasActiveChild.value) {
    open.value = true
  }

  // console.log('watchEffect', props)
})

function onDropClick() {
  open.value = !open.value
  if (!open.value) {
    buttonRef.value?.blur()
  }
}

function isChildActive(link: {
  name: string
  icon: string
  to: string
  exact?: boolean
}) {
  if (!hasPath(link.to)) {
    return false
  }

  // console.log('isChildActive', link, route.path)
  return (
    (link.exact && route.path === link.to) ||
    (!link.exact && route.path.startsWith(link.to))
  )
}

const { toggle } = useSidebar()
const { xl } = useTailwindBreakpoints()

function onLinkClick(event: Event, to: string) {
  console.log('onLinkClick called', { to, xlValue: xl.value })

  // Prevent default navigation
  event.preventDefault()

  if (!hasPath(to)) {
    return
  }

  // Navigate manually
  navigateTo(to)

  // Close sidebar on small screens
  if (!xl.value) {
    toggle()
  }
}

const visibleChildren = computed(() => {
  if (!props.children) return []
  const withPath = props.children.filter((child) => hasPath(child.to))

  if (props.collection === 'Location') {
    return withPath.filter((child) => child.is_show)
  }

  return withPath
})
</script>

<template>
  <li class="childs group mb-1 min-h-[2rem]">
    <a
      ref="buttonRef"
      href="#"
      class="nui-focus relative top-0.5 flex items-center"
      @click.stop.prevent="onDropClick"
    >
      <span
        class="text-muted-400 group-hover:text-primary-500 relative inline-flex items-center gap-2 font-sans text-sm transition-colors duration-300"
      >
        <span
          v-if="hasActiveChild"
          class="bg-primary-500 absolute -start-3 top-2 h-1 w-1 rounded-full"
        ></span>
        <span>{{ t(props.name) }}</span>
      </span>
      <Icon
        name="feather:chevron-down"
        class="text-muted-400 ms-auto block h-4 w-4 transition-transform duration-300"
        :class="{
          'group-focus-within:rotate-180': !open,
          'rotate-180': open,
        }"
      />
    </a>

    <div
      class="transition-all duration-150"
      :class="{
        'max-h-0 overflow-hidden opacity-0 group-focus-within:max-h-max group-focus-within:overflow-visible group-focus-within:opacity-100':
          !open,
        'max-h-max opacity-100': open,
      }"
    >
      <ul class="py-2" v-if="props?.children">
        <li
          v-for="link in visibleChildren"
          :key="link.to"
          class="locationSubItem flex h-8 w-full items-center"
        >
          <NuxtLink
            :to="link.to"
            :class="{
              'text-primary-500': isChildActive(link),
            }"
            class="nui-focus text-muted-400 hover:text-primary-500 focus:text-primary-500 flex w-full items-center ps-3 transition-colors duration-300"
            @click="(e) => onLinkClick(e, link.to)"
          >
            <Icon :name="link.icon" class="me-2 h-5 w-5" />
            <span class="font-sans text-xs">{{ t(link.name) }}</span>
          </NuxtLink>
        </li>
      </ul>
    </div>
  </li>
</template>
