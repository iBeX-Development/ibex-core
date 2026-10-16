<template>
  <div
    class="group inline-flex items-center justify-center text-right new_request"
    :title="$t('New Request')"
    :class="{ '-mt-10': !isAdmin }"
    @click="onClick"
  >
    <Menu
      as="div"
      id="menu-button-202408211"
      class="relative h-9 w-9 text-left"
      v-slot="{ close }"
    >
      <MenuButton as="template" id="menu-button-202408210">
        <button
          id="menu-button-20240829"
          type="button"
          class="inline-flex h-9 w-9 items-center justify-center rounded-full ring-1 ring-transparent transition-all duration-300 group-hover:ring-primary-500 group-hover:ring-offset-4 border border-[gainsboro]"
          :class="colorMode.value === 'dark' ? 'ring-offset-muted-900' : ''"
        >
          <div
            class="relative inline-flex h-9 w-9 items-center justify-center rounded-full"
          >
            <Icon name="lucide:plus" class="size-3" />
          </div>
        </button>
      </MenuButton>
    </Menu>
  </div>
</template>

<script setup lang="ts">
import { Menu, MenuButton } from '@headlessui/vue'
const user = useDirectusUser()
const config = useRuntimeConfig()
const colorMode = useColorMode()
const permissions = JSON.parse(
  window.localStorage.getItem('app_permissions') || '{}',
)
const isAdmin = ref(false)

if (permissions && permissions[1] && permissions[1].includes('admin')) {
  isAdmin.value = true
}

const props = defineProps({
  actions: Function,
  type: String,
  label: String,
})

const userImgId = ref(null)
const userImgUrl = ref(null)

const onClick = () => {
  props.actions()
}
</script>
