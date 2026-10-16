<script setup lang="ts">
import { format } from 'date-fns'
import { useNotification } from '../../compsables/useNotifications.ts'

import { Menu, MenuButton, MenuItem, MenuItems } from '@headlessui/vue'
import { ref } from 'vue'
const { getItems, createItems, updateItem } = useDirectusItems()
const colorMode = useColorMode()
const myId = window.localStorage.getItem('myId')
const config = useRuntimeConfig()
const runtimeConfig = useRuntimeConfig()

const loading = ref(false)
const notifylist = ref([])
const commentlist = ref([])
const alertlist = ref([])
const activeFilter = ref('Assigned')

const { notifications, hasNewNotification, clearNewNotification } =
  useNotification()

const Thumbnail = (id) => {
  if (id) {
    return `${config.public.directus.url}assets/${id}`
  } else return '/img/avatars/8.svg'
}

const loadMyNotify = async () => {
  loading.value = true

  try {
    const filters = {
      to_user: { _in: [myId] },
      // type: 'assigned',
    }

    const items = await getItems({
      collection: 'Notify',
      params: {
        filter: filters,
        limit: 40,
        sort: '-date_created',
        meta: 'filter_count',
        fields: [
          '*',
          'from_user.last_name,from_user.first_name, from_user.avatar',
        ],
      },
    })

    if (items.data.length > 0) {
      notifylist.value = items.data
        .filter((item) => item.type !== 'comment' && item.type !== 'monitoring')
        .map((item) => ({
          user: item.from_user.first_name,
          message: item.message,
          work_order: item.work_order,
          avatar: Thumbnail(item.from_user.avatar),
          time: format(new Date(item.date_created), 'yyyy-MM-dd HH:mm'),
        }))

      commentlist.value = items.data
        .filter((item) => item.type === 'comment')
        .map((item) => ({
          user: item.from_user.first_name,
          message: item.message,
          work_order: item.work_order,
          avatar: Thumbnail(item.from_user.avatar),
          time: format(new Date(item.date_created), 'yyyy-MM-dd HH:mm'),
        }))

      alertlist.value = items.data
        .filter((item) => item.type === 'monitoring')
        .map((item) => ({
          user: item.from_user?.first_name ?? 'System',
          message: item.message,
          work_order: item.work_order,
          avatar: Thumbnail(item.from_user?.avatar),
          time: format(new Date(item.date_created), 'yyyy-MM-dd HH:mm'),
        }))
    }
    // console.log('notifylist', notifylist.value)
    // console.log('commentlist', commentlist.value)

    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('loadMyNotify', e)
  }
}

const handleClick = () => {
  clearNewNotification()
  loadMyNotify()
}

onMounted(() => {
  console.log('onMounted_Notify')
  // loadMyNotify()
})
</script>

<template>
  <div class="group inline-flex items-center justify-center text-right">
    <Menu as="div" class="relative h-9 w-9 text-left" v-slot="{ close }">
      <MenuButton as="div">
        <button
          type="button"
          @click="handleClick"
          class="inline-flex h-9 w-9 items-center justify-center rounded-full ring-1 ring-transparent transition-all duration-300 group-hover:ring-offset-4"
          :class="
            colorMode.value === 'dark'
              ? 'group-hover:ring-muted-700 ring-offset-muted-900'
              : 'group-hover:ring-muted-200'
          "
        >
          <span
            class="flex h-9 w-9 items-center justify-center rounded-full border"
            :class="
              colorMode.value === 'dark'
                ? 'border-muted-700 bg-muted-800'
                : 'border-muted-200 bg-white'
            "
          >
            <Icon name="ph:bell-duotone" class="text-muted-400 h-5 w-5" />
          </span>

          <span
            v-if="hasNewNotification"
            class="newNotify flex absolute top-0 end-0 -mt-0.5 -me-0.5"
            style="transform: translate(-3px, 3px)"
          >
            <span
              class="absolute inline-flex h-full w-full rounded-full opacity-75 animate-ping"
              style="background-color: #00bba7"
            ></span>
            <span
              class="relative inline-flex rounded-full size-2"
              style="background-color: #00bba7"
            ></span>
          </span>
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
          class="absolute end-0 mt-2 w-78 origin-top-right divide-y rounded-md border shadow-lg focus:outline-none"
          :class="
            colorMode.value === 'dark'
              ? 'divide-muted-700 border-muted-700 bg-muted-800'
              : 'divide-muted-100 border-muted-200 bg-white'
          "
        >
          <div class="p-4">
            <div class="notify_tabs relative justify-between">
              <div class="tabs relative flex justify-center">
                <button
                  type="button"
                  class="tabButton cursor-pointer border-b-2 p-3 text-sm"
                  :class="
                    activeFilter === 'Assigned'
                      ? colorMode.value === 'dark'
                        ? 'actived text-muted-100 !border-primary-500'
                        : 'actived text-muted-700 !border-primary-500'
                      : colorMode.value === 'dark'
                      ? 'border-transparent text-muted-400 hover:text-muted-100'
                      : 'border-transparent text-muted-400 hover:text-muted-700'
                  "
                  @click="activeFilter = 'Assigned'"
                >
                  {{ $t('Assigned') }}
                </button>
                <button
                  type="button"
                  class="tabButton cursor-pointer border-b-2 p-3 text-sm"
                  :class="
                    activeFilter === 'Comments'
                      ? colorMode.value === 'dark'
                        ? 'actived text-muted-100 !border-primary-500'
                        : 'actived text-muted-700 !border-primary-500'
                      : colorMode.value === 'dark'
                      ? 'border-transparent text-muted-400 hover:text-muted-100'
                      : 'border-transparent text-muted-400 hover:text-muted-700'
                  "
                  @click="activeFilter = 'Comments'"
                >
                  {{ $t('Comments') }}
                </button>
                <button
                  type="button"
                  class="tabButton cursor-pointer border-b-2 p-3 text-sm"
                  :class="
                    activeFilter === 'Alerts'
                      ? colorMode.value === 'dark'
                        ? 'actived text-muted-100 !border-primary-500'
                        : 'actived text-muted-700 !border-primary-500'
                      : colorMode.value === 'dark'
                      ? 'border-transparent text-muted-400 hover:text-muted-100'
                      : 'border-transparent text-muted-400 hover:text-muted-700'
                  "
                  @click="activeFilter = 'Alerts'"
                >
                  {{ $t('Alerts') }}
                </button>
              </div>

              <template v-if="activeFilter == 'Assigned'">
                <div class="tab_1 p-4 h-[390px] overflow-auto">
                  <MenuItem
                    as="div"
                    v-for="(item, index) in notifylist"
                    :key="index"
                    v-slot="{ active }"
                  >
                    <NuxtLink
                      :to="`/mytask#${item.work_order}`"
                      class="group flex w-full items-center rounded-md p-2 text-sm transition-colors duration-300"
                      :class="[
                        active
                          ? colorMode.value === 'dark'
                            ? 'bg-muted-700 text-primary-500'
                            : 'bg-muted-100 text-primary-500'
                          : 'text-muted-500',
                      ]"
                      @click.passive="close"
                    >
                      <div
                        class="relative inline-flex h-9 w-9 items-center justify-center rounded-full"
                      >
                        <BaseAvatar :src="item.avatar" size="xs" />
                      </div>
                      <div class="ms-2">
                        <h6
                          class="font-heading text-xs font-semibold leading-tight"
                          :class="
                            colorMode.value === 'dark'
                              ? 'text-white'
                              : 'text-muted-800'
                          "
                        >
                          {{ item.user }}
                          <span
                            class="font-normal"
                            :class="
                              colorMode.value === 'dark'
                                ? 'text-muted-400'
                                : 'text-muted-500'
                            "
                          >
                            {{ item.message }}
                          </span>
                        </h6>
                        <p class="text-muted-400 font-sans text-xs">
                          {{ item.time }}
                        </p>
                      </div>
                    </NuxtLink>
                  </MenuItem>
                </div>
              </template>
              <template v-if="activeFilter == 'Comments'">
                <div class="tab_2 p-4 h-[390px] overflow-auto">
                  <MenuItem
                    as="div"
                    v-for="(item, index) in commentlist"
                    :key="index"
                    v-slot="{ active }"
                  >
                    <NuxtLink
                      :to="`/mytask#${item.work_order}`"
                      class="group flex w-full items-center rounded-md p-2 text-sm transition-colors duration-300"
                      :class="[
                        active
                          ? colorMode.value === 'dark'
                            ? 'bg-muted-700 text-primary-500'
                            : 'bg-muted-100 text-primary-500'
                          : 'text-muted-500',
                      ]"
                      @click.passive="close"
                    >
                      <div
                        class="relative inline-flex h-9 w-9 items-center justify-center rounded-full"
                      >
                        <BaseAvatar :src="item.avatar" size="xs" />
                      </div>
                      <div class="ms-2">
                        <h6
                          class="font-heading text-xs font-semibold leading-tight"
                          :class="
                            colorMode.value === 'dark'
                              ? 'text-white'
                              : 'text-muted-800'
                          "
                        >
                          {{ item.user }}
                          <span
                            class="font-normal"
                            :class="
                              colorMode.value === 'dark'
                                ? 'text-muted-400'
                                : 'text-muted-500'
                            "
                          >
                            {{ item.message }}
                          </span>
                        </h6>
                        <p class="text-muted-400 font-sans text-xs">
                          {{ item.time }}
                        </p>
                      </div>
                    </NuxtLink>
                  </MenuItem>
                </div>
              </template>
              <template v-if="activeFilter == 'Alerts'">
                <div class="tab_3 p-4 h-[390px] overflow-auto">
                  <div
                    v-if="!alertlist.length"
                    class="flex h-full items-center justify-center text-xs text-muted-400"
                  >
                    {{ $t('No alerts') }}
                  </div>
                  <MenuItem
                    as="div"
                    v-for="(item, index) in alertlist"
                    :key="index"
                    v-slot="{ active }"
                  >
                    <div
                      class="group flex w-full items-start rounded-md p-2 text-sm transition-colors duration-300"
                      :class="[
                        active
                          ? colorMode.value === 'dark'
                            ? 'bg-muted-700 text-primary-500'
                            : 'bg-muted-100 text-primary-500'
                          : 'text-muted-500',
                      ]"
                    >
                      <div
                        class="relative inline-flex h-9 w-9 items-center justify-center rounded-full bg-warning-100 dark:bg-warning-900/30"
                      >
                        <Icon
                          name="ph:warning-circle-duotone"
                          class="h-5 w-5 text-warning-500"
                        />
                      </div>
                      <div class="ms-2">
                        <h6
                          class="font-heading text-xs font-semibold leading-tight"
                          :class="
                            colorMode.value === 'dark'
                              ? 'text-white'
                              : 'text-muted-800'
                          "
                        >
                          {{ item.user }}
                          <span
                            class="font-normal"
                            :class="
                              colorMode.value === 'dark'
                                ? 'text-muted-400'
                                : 'text-muted-500'
                            "
                          >
                            {{ item.message }}
                          </span>
                        </h6>
                        <p class="text-muted-400 font-sans text-xs">
                          {{ item.time }}
                        </p>
                      </div>
                    </div>
                  </MenuItem>
                </div>
              </template>
            </div>
          </div>
        </MenuItems>
      </Transition>
    </Menu>
  </div>
</template>

<style>
.newtabs {
  /* background-color: #f2f5f9;
  color: gray; */
}

.notify_tabs .tabButton {
  appearance: none;
  display: inline-block;
  padding: 8px 16px;
  white-space: nowrap;
  font-size: 14px;
  font-weight: 500;
  /* border-radius: 12px; */
  border: none;
  color: var(--color-text-secondary, #39485d);
  cursor: pointer;
  box-shadow: none;
  transition: background 0.3s, color 0.3s;
}
.grid-dark .tabButton {
  background-color: unset;
}
.grid-dark .tabButton:hover {
  color: rgba(37, 37, 37, 0.6);
}

.notify_tabs .tabButton:hover {
  color: #070707;
}

.notify_tabs .tabButton.actived {
  border-bottom: 2px solid;
  color: #070707;
  font-weight: 600;
}
</style>
