<script setup lang="ts">
import { Menu, MenuButton, MenuItem, MenuItems } from '@headlessui/vue'

const props = defineProps<{
  horizontal?: boolean
}>()
const user = useDirectusUser()
const colorMode = useColorMode()
</script>

<template>
  <div class="group inline-flex items-center justify-center text-right">
    <Menu as="div" class="relative h-10 w-10 text-left" v-slot="{ close }">
      <MenuButton as="template">
        <button
          type="button"
          class="inline-flex h-10 w-10 items-center justify-center rounded-full ring-1 ring-transparent transition-all duration-300 group-hover:ring-primary-500 group-hover:ring-offset-4"
          :class="colorMode.value === 'dark' ? 'ring-offset-muted-800' : ''"
        >
          <div
            class="relative inline-flex h-10 w-10 items-center justify-center rounded-full"
          >
            <Icon
              name="ph:gear-six-duotone"
              class="text-muted-400 h-8 w-8 transition-all duration-300 group-hover:rotate-6 group-hover:text-primary-500"
            />
          </div>
        </button>
      </MenuButton>

      <Transition
        enter-active-class="transition duration-100 ease-out"
        enter-from-class="transform scale-95 opacity-0"
        enter-to-class="transform scale-100 opacity-100"
        leave-active-class="transition duration-75 ease-in"
        leave-from-class="transform scale-100 opacity-100"
        leave-to-class="transform scale-95 opacity-0"
      >
        <MenuItems
          class="absolute mt-2 w-60 origin-bottom-right rounded-md border shadow-lg focus:outline-none"
          :class="[
            colorMode.value === 'dark'
              ? 'border-muted-700 bg-muted-800'
              : 'border-muted-200 bg-white',
            props.horizontal ? 'top-10 end-0' : 'bottom-0 -end-64',
          ]"
        >
          <div class="p-2">
            <MenuItem as="div" v-slot="{ active }">
              <NuxtLink
                to="/profile"
                class="group flex w-full items-center rounded-md p-3 text-sm transition-colors duration-300"
                :class="[
                  active
                    ? colorMode.value === 'dark'
                      ? 'bg-muted-700 text-primary-500'
                      : 'bg-muted-100 text-primary-500'
                    : 'text-muted-400',
                ]"
                @click.passive="close"
              >
                <Icon name="ph:user-circle-duotone" class="h-5 w-5" />
                <div class="ms-3">
                  <h6
                    class="font-heading text-xs font-medium leading-none"
                    :class="
                      colorMode.value === 'dark'
                        ? 'text-white'
                        : 'text-muted-800'
                    "
                  >
                    {{ $t('Profile') }}
                  </h6>
                  <p class="text-muted-400 font-sans text-[9px]">
                    {{ $t('Profile view and modify') }}
                  </p>
                </div>
              </NuxtLink>
            </MenuItem>
            <MenuItem as="div" v-slot="{ active }">
              <NuxtLink
                to="/asset"
                class="group flex w-full items-center rounded-md p-3 text-sm transition-colors duration-300"
                :class="[
                  active
                    ? colorMode.value === 'dark'
                      ? 'bg-muted-700 text-primary-500'
                      : 'bg-muted-100 text-primary-500'
                    : 'text-muted-400',
                ]"
                @click.passive="close"
              >
                <Icon name="ph:briefcase-duotone" class="h-5 w-5" />
                <div class="ms-3">
                  <h6
                    class="font-heading text-xs font-medium leading-none"
                    :class="
                      colorMode.value === 'dark'
                        ? 'text-white'
                        : 'text-muted-800'
                    "
                  >
                    {{ $t('Assets') }}
                  </h6>
                  <p class="text-muted-400 font-sans text-[9px]">
                    {{ $t('Assets management') }}
                  </p>
                </div>
              </NuxtLink>
            </MenuItem>
            <MenuItem as="div" v-slot="{ active }">
              <NuxtLink
                to="/settings/team"
                class="group flex w-full items-center rounded-md p-3 text-sm transition-colors duration-300"
                :class="[
                  active
                    ? colorMode.value === 'dark'
                      ? 'bg-muted-700 text-primary-500'
                      : 'bg-muted-100 text-primary-500'
                    : 'text-muted-400',
                ]"
                @click.passive="close"
              >
                <Icon name="ph:users-three-duotone" class="h-5 w-5" />
                <div class="ms-3">
                  <h6
                    class="font-heading text-xs font-medium leading-none"
                    :class="
                      colorMode.value === 'dark'
                        ? 'text-white'
                        : 'text-muted-800'
                    "
                  >
                    {{ $t('Team') }}
                  </h6>
                  <p class="text-muted-400 font-sans text-[9px]">
                    {{ $t('My team and team management') }}
                  </p>
                </div>
              </NuxtLink>
            </MenuItem>
            <MenuItem as="div" v-slot="{ active }">
              <NuxtLink
                to="/settings"
                class="group flex w-full items-center rounded-md p-3 text-sm transition-colors duration-300"
                :class="[
                  active
                    ? colorMode.value === 'dark'
                      ? 'bg-muted-700 text-primary-500'
                      : 'bg-muted-100 text-primary-500'
                    : 'text-muted-400',
                ]"
                @click.passive="close"
              >
                <Icon name="ph:gear-six-duotone" class="h-5 w-5" />
                <div class="ms-3">
                  <h6
                    class="font-heading text-xs font-medium leading-none"
                    :class="
                      colorMode.value === 'dark'
                        ? 'text-white'
                        : 'text-muted-800'
                    "
                  >
                    {{ $t('Settings') }}
                  </h6>
                  <p class="text-muted-400 font-sans text-[9px]">
                    {{ $t('System settings view and modify') }}
                  </p>
                </div>
              </NuxtLink>
            </MenuItem>
          </div>
        </MenuItems>
      </Transition>
    </Menu>
  </div>
</template>
