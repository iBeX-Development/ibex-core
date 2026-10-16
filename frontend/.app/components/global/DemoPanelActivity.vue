<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
const { close } = usePanels()
const activeTab = ref('tab-1')
const colorMode = useColorMode()

const search = ref('')
const teams = ref([])
const loading = ref(true)
const totalItems = ref(0)
const { getItems, updateItem } = useDirectusItems()
const user = useDirectusUser()
const config = useRuntimeConfig()

const loadItems = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array = []
  sortBy.map((sort_object) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })
  loading.value = true
  try {
    const filters = { active: 1 }
    const items = await getItems({
      collection: 'Teams',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: '',
        fields: [
          '*',
          'team_leaders.directus_users_id.first_name',
          'team_leaders.directus_users_id.last_name',
          'team_leaders.directus_users_id.avatar',
          'team_leaders.directus_users_id.id',
          'users.*',
          'users.directus_users_id.first_name',
          'users.directus_users_id.id',
        ],
      },
    })
    teams.value = items.data
    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {
    loading.value = false
  }
}

onMounted(async () => {
  await loadItems({ page: 1, itemsPerPage: 4, sortBy: [] })
})
</script>

<template>
  <div
    class="border"
    :class="
      colorMode.value === 'dark'
        ? 'border-muted-700 bg-muted-800'
        : 'border-muted-200 bg-white'
    "
  >
    <div
      class="activepanel flex h-16 w-full items-center justify-between px-10"
    >
      <h2
        class="font-heading text-lg font-semibold"
        :class="colorMode.value === 'dark' ? 'text-white' : 'text-muted-700'"
      >
        {{ t('My Activity') }}
      </h2>
      <button
        type="button"
        class="text-muted-400 flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300"
        :class="
          colorMode.value === 'dark'
            ? 'hover:bg-muted-700 hover:text-white'
            : 'hover:bg-muted-100 hover:text-muted-600'
        "
        @click="close"
      >
        <Icon name="feather:chevron-right" class="h-6 w-6" />
      </button>
    </div>

    <div class="flex h-16 items-center px-10">
      <!-- Tabs -->
      <div
        class="relative flex h-10 w-full items-center rounded-lg font-sans text-sm"
        :class="colorMode.value === 'dark' ? 'bg-muted-700' : 'bg-muted-100'"
      >
        <button
          type="button"
          class="relative z-20 flex h-full flex-1 items-center justify-center"
          :class="activeTab === 'tab-1' ? 'text-white' : 'text-muted-400'"
          @click="activeTab = 'tab-1'"
        >
          <span>{{ t('Team') }}</span>
        </button>
        <button
          type="button"
          class="relative z-20 flex h-full flex-1 items-center justify-center"
          :class="activeTab === 'tab-2' ? 'text-white' : 'text-muted-400'"
          @click="activeTab = 'tab-2'"
        >
          <span>{{ t('Projects') }}</span>
        </button>
        <button
          type="button"
          class="relative z-20 flex h-full flex-1 items-center justify-center"
          :class="activeTab === 'tab-3' ? 'text-white' : 'text-muted-400'"
          @click="activeTab = 'tab-3'"
        >
          <span>{{ t('Schedule') }}</span>
        </button>
        <div
          class="bg-primary-600 absolute start-0 top-0 z-10 h-full w-1/3 rounded-lg transition-all duration-300"
          :class="[
            activeTab === 'tab-1' && 'ms-0',
            activeTab === 'tab-2' && 'ms-[33.3%]',
            activeTab === 'tab-3' && 'ms-[66.6%]',
          ]"
        ></div>
      </div>
    </div>

    <div
      class="slimscroll relative h-[calc(100%_-_128px)] w-full overflow-y-auto px-10"
    >
      <div class="py-6">
        <!-- Team tab content -->
        <div v-if="activeTab === 'tab-1'" class="space-y-4">
          <div
            v-for="(item, index) in teams"
            :key="index"
            class="flex items-center rounded-lg border p-4"
            :class="
              colorMode.value === 'dark'
                ? 'border-muted-600 bg-muted-700'
                : 'border-muted-200 bg-white'
            "
          >
            <div
              class="relative inline-flex h-9 w-9 items-center justify-center rounded-full"
            >
              <BaseAvatar
                :src="
                  item?._image
                    ? `${config.public.directus.url}assets/${item._image}`
                    : null
                "
                :text="item.name.slice(0, 2).toUpperCase()"
                class="text-primary-500 shrink-0"
                :class="
                  colorMode.value === 'dark'
                    ? 'bg-primary-500/20'
                    : 'bg-primary-100'
                "
              />
            </div>
            <div class="ms-3">
              <h6
                class="font-heading text-sm font-semibold"
                :class="
                  colorMode.value === 'dark' ? 'text-white' : 'text-muted-800'
                "
              >
                {{ item.name }}
              </h6>
              <p class="text-muted-400 font-sans text-xs">
                {{ item.description }}
              </p>
            </div>
            <NuxtLink
              to="#"
              class="text-muted-400 hover:border-primary-500 hover:text-primary-500 ms-auto flex h-9 w-9 items-center justify-center rounded-full border transition-colors duration-300"
              :class="
                colorMode.value === 'dark'
                  ? 'border-muted-500 hover:border-primary-500'
                  : 'border-muted-200'
              "
            >
              <Icon name="feather:arrow-right" class="h-4 w-4" />
            </NuxtLink>
          </div>
        </div>

        <!-- Project tab content -->
        <div v-else-if="activeTab === 'tab-2'" class="space-y-4">
          <!-- Project 1 -->
          <div
            class="border-muted-200 dark:border-muted-600 dark:bg-muted-700 rounded-lg border bg-white p-4"
          >
            <div class="mb-4 flex items-center">
              <div
                class="relative inline-flex h-9 w-9 items-center justify-center rounded-xl"
              >
                <img
                  src="/img/icons/logos/slicer.svg"
                  class="max-w-full rounded-xl object-cover shadow-sm"
                  alt=""
                />
              </div>
              <div class="ms-3">
                <h6
                  class="font-heading text-muted-800 text-sm font-semibold dark:text-white"
                >
                  {{ t('The slicer project') }}
                </h6>
                <p class="text-muted-400 font-sans text-xs">getslicer.io</p>
              </div>
              <NuxtLink
                to="#"
                class="border-muted-200 text-muted-400 hover:border-primary-500 hover:text-primary-500 dark:border-muted-500 dark:hover:border-primary-500 ms-auto flex h-9 w-9 items-center justify-center rounded-full border transition-colors duration-300"
              >
                <Icon name="feather:arrow-right" class="h-4 w-4" />
              </NuxtLink>
            </div>
            <div
              class="bg-muted-200 dark:bg-muted-800 relative mb-4 h-1 w-full overflow-hidden rounded-lg"
            >
              <div
                class="bg-primary-500 absolute start-0 top-0 h-full w-[34%] rounded-lg transition duration-300"
              ></div>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-muted-400 font-sans">5/24</span>
              <div class="flex items-end">
                <div
                  v-for="avatar in [2, 3, 4]"
                  :key="avatar"
                  class="dark:border-muted-700 relative -ms-2 inline-flex h-8 w-8 items-center justify-center rounded-full border-2 border-white"
                >
                  <img
                    :src="`/img/avatars/${avatar}.svg`"
                    class="max-w-full rounded-full object-cover shadow-sm dark:border-transparent"
                    alt=""
                  />
                </div>
                <div
                  class="bg-muted-200 dark:border-muted-700 dark:bg-muted-800 relative -ms-2 inline-flex h-8 w-8 items-center justify-center rounded-full border-2 border-white"
                >
                  <span
                    class="font-alt text-muted-500 dark:text-muted-300 -ms-1 text-sm font-normal uppercase"
                    >+3</span
                  >
                </div>
              </div>
            </div>
          </div>
          <!-- Project 2 -->
          <div
            class="border-muted-200 dark:border-muted-600 dark:bg-muted-700 rounded-lg border bg-white p-4"
          >
            <div class="mb-4 flex items-center">
              <div
                class="relative inline-flex h-9 w-9 items-center justify-center rounded-xl"
              >
                <img
                  src="/img/icons/logos/metamovies.svg"
                  class="max-w-full rounded-xl object-cover shadow-sm dark:border-transparent"
                  alt=""
                />
              </div>
              <div class="ms-3">
                <h6
                  class="font-heading text-muted-800 text-sm font-semibold dark:text-white"
                >
                  {{ t('Metamovies reworked') }}
                </h6>
                <p class="text-muted-400 font-sans text-xs">metamovies.co</p>
              </div>
              <NuxtLink
                to="#"
                class="border-muted-200 text-muted-400 hover:border-primary-500 hover:text-primary-500 dark:border-muted-500 dark:hover:border-primary-500 ms-auto flex h-9 w-9 items-center justify-center rounded-full border transition-colors duration-300"
              >
                <Icon name="feather:arrow-right" class="h-4 w-4" />
              </NuxtLink>
            </div>
            <div
              class="bg-muted-200 dark:bg-muted-800 relative mb-4 h-1 w-full overflow-hidden rounded-lg"
            >
              <div
                class="bg-primary-500 absolute start-0 top-0 h-full w-[88%] rounded-lg transition duration-300"
              ></div>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-muted-400 font-sans">28/31</span>
              <div class="flex items-end">
                <div
                  v-for="avatar in [13, 24]"
                  :key="avatar"
                  class="dark:border-muted-700 relative -ms-2 inline-flex h-8 w-8 items-center justify-center rounded-full border-2 border-white"
                >
                  <img
                    :src="`/img/avatars/${avatar}.svg`"
                    class="max-w-full rounded-full object-cover shadow-sm dark:border-transparent"
                    alt=""
                  />
                </div>
              </div>
            </div>
          </div>
          <!-- Project 3 -->
          <div
            class="border-muted-200 dark:border-muted-600 dark:bg-muted-700 rounded-lg border bg-white p-4"
          >
            <div class="mb-4 flex items-center">
              <div
                class="relative inline-flex h-9 w-9 items-center justify-center rounded-xl"
              >
                <img
                  src="/img/icons/logos/fastpizza.svg"
                  class="max-w-full rounded-xl object-cover shadow-sm dark:border-transparent"
                  alt=""
                />
              </div>
              <div class="ms-3">
                <h6
                  class="font-heading text-muted-800 text-sm font-semibold dark:text-white"
                >
                  {{ t('Fast Pizza redesign') }}
                </h6>
                <p class="text-muted-400 font-sans text-xs">fastpizza.com</p>
              </div>
              <NuxtLink
                to="#"
                class="border-muted-200 text-muted-400 hover:border-primary-500 hover:text-primary-500 dark:border-muted-500 dark:hover:border-primary-500 ms-auto flex h-9 w-9 items-center justify-center rounded-full border transition-colors duration-300"
              >
                <Icon name="feather:arrow-right" class="h-4 w-4" />
              </NuxtLink>
            </div>
            <div
              class="bg-muted-200 dark:bg-muted-800 relative mb-4 h-1 w-full overflow-hidden rounded-lg"
            >
              <div
                class="bg-primary-500 absolute start-0 top-0 h-full w-[62%] rounded-lg transition duration-300"
              ></div>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-muted-400 font-sans">25/39</span>
              <div class="flex items-end">
                <div
                  v-for="avatar in [11, 3]"
                  :key="avatar"
                  class="dark:border-muted-700 relative -ms-2 inline-flex h-8 w-8 items-center justify-center rounded-full border-2 border-white"
                >
                  <img
                    :src="`/img/avatars/${avatar}.svg`"
                    class="max-w-full rounded-full object-cover shadow-sm dark:border-transparent"
                    alt=""
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Timeline/Schedule tab content -->
        <div v-else-if="activeTab === 'tab-3'" class="space-y-4">
          <div>
            <template
              v-for="(item, idx) in [
                {
                  icon: 'ph:phone-duotone',
                  title: 'Call Danny at Colby\'s',
                  time: 'Today - 11:30am',
                },
                {
                  avatar: '/img/avatars/3.svg',
                  title: 'Meeting with Mike',
                  time: 'Today - 01:00pm',
                },
                {
                  icon: 'ph:chat-circle-duotone',
                  title: 'Answer Annie\'s message',
                  time: 'Today - 01:45pm',
                },
                {
                  avatar: '/img/avatars/18.svg',
                  title: 'Meeting with John',
                  time: 'Today - 03:00pm',
                },
                {
                  icon: 'ph:envelope-duotone',
                  title: 'Send marketing campaign',
                  time: 'Today - 03:30pm',
                },
                {
                  icon: 'ph:selection-all-duotone',
                  title: 'Project review',
                  time: 'Today - 04:30pm',
                },
                {
                  icon: 'ph:note-duotone',
                  title: 'Write proposal for Andy',
                  time: 'Today - 06:30pm',
                },
              ]"
              :key="idx"
            >
              <div
                class="after:border-muted-300 dark:after:border-muted-600 relative flex pb-8 after:absolute after:start-4 after:top-10 after:h-[calc(100%_-_36px)] after:w-px after:border-l after:content-['']"
              >
                <div
                  class="border-muted-200 text-muted-400 after:border-muted-300 dark:border-muted-600 dark:bg-muted-700 dark:after:border-muted-600 relative flex h-9 w-9 items-center justify-center rounded-full border bg-white shadow-lg after:absolute after:-end-8 after:top-4 after:h-px after:w-5 after:border-t after:content-['']"
                >
                  <Icon v-if="item.icon" :name="item.icon" />
                  <div
                    v-else
                    class="relative inline-flex h-7 w-7 items-center justify-center rounded-full"
                  >
                    <img
                      :src="item.avatar"
                      class="max-w-full rounded-full object-cover shadow-sm dark:border-transparent"
                      alt=""
                    />
                  </div>
                </div>
                <div class="ms-10">
                  <h6
                    class="font-heading text-muted-800 text-sm font-semibold dark:text-white"
                  >
                    {{ t(item.title) }}
                  </h6>
                  <p class="text-muted-400 font-sans text-xs">
                    {{ t(item.time) }}
                  </p>
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
