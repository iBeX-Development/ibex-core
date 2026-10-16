<template>
  <div
    class="group inline-flex items-center justify-center text-right my_profile"
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
          class="inline-flex h-9 w-9 items-center justify-center rounded-full ring-1 ring-transparent transition-all duration-300 group-hover:ring-primary-500 group-hover:ring-offset-4"
          :class="colorMode.value === 'dark' ? 'ring-offset-muted-900' : ''"
        >
          <div
            class="relative inline-flex h-9 w-9 items-center justify-center rounded-full"
          >
            <img
              :src="
                user?.avatar
                  ? `${config.public.directus.url}assets/${user.avatar}`
                  : '/img/avatars/2.svg'
              "
              style="height: 100%; width: 100%"
              class="max-w-full rounded-full object-cover shadow-sm"
              :class="colorMode.value === 'dark' ? 'border-transparent' : ''"
              alt=""
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
          class="my_helper absolute end-0 mt-2 w-64 origin-top-right divide-y rounded-md border shadow-lg focus:outline-none"
          :class="
            colorMode.value === 'dark'
              ? 'divide-muted-700 border-muted-700 bg-muted-800'
              : 'divide-muted-100 border-muted-200 bg-white'
          "
        >
          <div class="p-6 text-center">
            <div
              class="relative mx-auto flex h-20 w-20 items-center justify-center rounded-full"
            >
              <img
                :src="
                  user?.avatar
                    ? `${config.public.directus.url}assets/${user.avatar}`
                    : '/img/avatars/2.svg'
                "
                class="max-w-full rounded-full object-cover shadow-sm"
                :class="colorMode.value === 'dark' ? 'border-transparent' : ''"
                alt=""
                style="width: 100%; height: 100%"
              />
            </div>
            <div class="mt-3">
              <h6
                class="font-heading text-sm font-medium"
                :class="
                  colorMode.value === 'dark' ? 'text-white' : 'text-muted-800'
                "
              >
                {{ user?.first_name }} {{ user?.last_name }}
              </h6>
              <p class="text-muted-400 font-sans text-xs">
                {{ user?.email }}
              </p>
              <p v-if="roleName" class="text-muted-400 mb-4 font-sans text-xs">
                {{ roleName }}
              </p>
              <BaseButton
                to="/profile"
                shape="curved"
                class="w-full"
                @click.passive="close"
                >{{ $t('Profile') }}</BaseButton
              >
            </div>
          </div>

          <div class="p-6">
            <BaseButton
              @click.passive="close"
              shape="curved"
              class="w-full"
              @click="quitSystem"
            >
              {{ $t('Logout') }}
            </BaseButton>
          </div>
        </MenuItems>
      </Transition>
    </Menu>
  </div>
</template>

<script setup lang="ts">
import { Menu, MenuButton, MenuItems } from '@headlessui/vue'
const user = useDirectusUser()
const config = useRuntimeConfig()
const colorMode = useColorMode()
const { logout } = useDirectusAuth()
const { token } = useDirectusToken()

const userImgId = ref(null)
const userImgUrl = ref(null)
const roleName = ref('')

// Одоогийн нэвтэрсэн хэрэглэгчийн role-ийн нэрийг харуулна
onMounted(async () => {
  try {
    const roleId =
      typeof user.value?.role === 'object'
        ? user.value?.role?.id
        : user.value?.role
    if (!roleId) return

    const response = await fetch(
      `${config.public.directus.url}roles/${roleId}?fields=name`,
      { headers: { Authorization: `Bearer ${token.value}` } },
    )
    const result = await response.json()
    roleName.value = result?.data?.name || ''
  } catch (error) {
    console.error('Unable to load role name:', error)
  }
})

// 🔹 `localStorage`-оос `userInfo` авахдаа `process.client` шалгах
// onMounted(() => {
//   if (process.client) {
//     try {
//       const userInfo = JSON.parse(
//         window.localStorage.getItem('userInfo') || '{}',
//       )
//       if (userInfo?.avatar) {
//         userImgId.value = userInfo.avatar
//       }
//     } catch (error) {
//       console.error('Error parsing userInfo:', error)
//     }
//   }
// })

// // 🔹 `computed()` ашиглаж, шууд тооцоолох
// const previewUrl = computed(() => {
//   return userImgId.value
//     ? `${config.public.directus.url}assets/${userImgId.value}`
//     : '/img/avatars/2.svg'
// })

function quitSystem() {
  // System logout here
  logout()
  clearUserStorage()
  window.localStorage.removeItem('sidebar_locations_cache_v3')
  window.localStorage.removeItem('sidebar_shared')
  window.localStorage.removeItem('sidebar_inventory')
  window.localStorage.removeItem('app_permissions')
  // window.localStorage.removeItem('sidebar_locations_cache_v2')
  // window.localStorage.removeItem('pm_pagesize')
  // window.localStorage.removeItem('completed')
  // window.localStorage.removeItem('request')
  // window.localStorage.removeItem('comInfo')

  navigateTo('/login')
}
</script>
