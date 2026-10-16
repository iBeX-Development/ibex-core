<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { onMounted, ref } from 'vue'

import '~/assets/css/vcalendar.css'
const { token } = useDirectusToken()

import { useI18n } from 'vue-i18n'
// Import optimization composable and loading states
import { tabLoadingStates } from '~/composables/useTabOptimization'
const { t } = useI18n({ useScope: 'global' })
const permissions = JSON.parse(
  window.localStorage.getItem('app_permissions') || '{}',
)
const dashboard = JSON.parse(window.localStorage.getItem('dashboard'))

console.log('dashboard', dashboard)

import Tab1 from './tab1.vue'
import Tab2 from './tab2.vue'
import Tab3 from './tab3.vue'
import Tab4 from './tab4.vue'
import Tab5 from './tab5.vue'
import Tab6 from './tab6.vue'
//costs
// import FilterModalForm from '~/components/home/FilterModalForm.vue'
import FilterNewModalForm from '~/components/home/FilterNewModalForm.vue'
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

definePageMeta({
  title: 'Analytics',
  middleware: ['auth'],
  preview: {
    title: 'Analytics dashboard',
    description: 'For heavy stats and kpis',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-analytics.png',
    srcDark: '/img/screens/dashboards-analytics-dark.png',
    order: 4,
  },
})

const search = ref('')
const serverItems = ref([])

const isModalOsen = ref(false)
const activeTab = ref('cost')
const tabs = ref([
  {
    name: t('Costs'),
    key: 'cost',
    icon: 'solar:money-bag-outline',
    color: 'text-green-600',
    hoverColor: 'group-hover:bg-green-400 dark:group-hover:bg-green-400',
    id: 1,
  },
  {
    name: t('Works'),
    key: 'performance',
    icon: 'fluent:wrench-settings-24-regular',
    color: 'text-red-400',
    hoverColor: 'group-hover:bg-rose-500 dark:group-hover:bg-rose-500',
    id: 2,
  },
  {
    name: t('Tasks'),
    key: 'task',
    icon: 'carbon:operations-record',
    color: 'text-sky-500',
    hoverColor: ' group-hover:bg-sky-500 dark:group-hover:bg-sky-500',
    id: 3,
  },
  {
    name: t('Monitoring'),
    key: 'monitoring',
    icon: 'material-symbols:monitoring',
    color: 'text-orange-500',
    hoverColor: ' group-hover:bg-orange-500 dark:group-hover:bg-orange-500',
    id: 6,
  },
  // {
  //   name: t('Performance'),
  //   key: 'private',
  //   icon: 'carbon:operations-record',
  //   color: 'text-orange-500',
  //   hoverColor: ' group-hover:bg-orange-500 dark:group-hover:bg-orange-500',
  //   id: 5,
  // },
  {
    name: t('Safety'),
    key: 'safety',
    icon: 'ph:bank-duotone',
    color: 'text-indigo-500',
    hoverColor: ' group-hover:bg-indigo-500 dark:group-hover:bg-indigo-500',
    id: 4,
  },
])

const user_tabs = ref([
  {
    name: t('Performance'),
    key: 'private',
    icon: 'carbon:operations-record',
    color: 'text-sky-500',
    hoverColor: ' group-hover:bg-sky-500 dark:group-hover:bg-sky-500',
    id: 5,
  },
])

const translatedTabs = computed(() =>
  tabs.value.map((item) => ({ ...item, name: t(item.name) })),
)

//tabs_data
const tab1_data = ref([])
const tab2_data = ref([])
const tab3_data = ref([])
const tab4_data = ref([])
const tab5_data = ref([])
const tab6_data = ref([])

// Filter section
const currentDate = new Date()
const isModalOpen = ref(false)
const fromMenu = ref(false)
const toMenu = ref(false)
const today = new Date()

// Сүүлийн 10 сарын өмнөх сар (энэ сар багтсан)
const fromDate = new Date(today.getFullYear(), today.getMonth() - 9, 1)
const toDate = today
const customFrom = ref(fromDate.toISOString().split('T')[0])
const customTo = ref(toDate.toISOString().split('T')[0])

const isDropdownOpen = ref(true)
const date_filer = ref(false)
const location = ref(null)
const dashboard_type = ref(null)

const selectedRangeText = ref('Filter')
const dateOptions = ref([
  { label: t('Last 7 Days'), value: 7 },
  { label: t('Last 30 Days'), value: 30 },
  { label: t('Last 60 Days'), value: 60 },
  { label: t('Last 90 Days'), value: 90 },
  { label: t('Last 365 Days'), value: 365 },
  { label: t('All Time'), value: 'all' },
])

const loading = ref(false)

const setDashboardType = (type) => {
  dashboard_type.value = type
}

const handleModalOpen = () => {
  isModalOpen.value = !isModalOpen.value
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log('handleModalClose', isModalOpen.value)
}

const refresh = (data) => {
  console.log('refresh-index')

  if (activeTab.value == 'cost') {
    tab1_data.value = data
  } else if (activeTab.value == 'performance') {
    tab2_data.value = data
  } else if (activeTab.value == 'task') {
    tab3_data.value = data
  } else if (activeTab.value == 'safety') {
    tab4_data.value = data
  } else if (activeTab.value == 'private') {
    tab5_data.value = data
  } else if (activeTab.value == 'monitoring') {
    tab6_data.value = data
  }
}

//tab clicked
function handleTabClick(tabKey, tabName) {
  // console.log('click', tabKey, tabName)
  activeTab.value = tabKey
  // Change inner text of the element with class "MainTitle"
  // const titleElement = document.querySelector('.MainTitle')
  // if (titleElement) {
  //   titleElement.textContent = `Analytics - ${tabName}`
  // }
}

const route = useRoute()

onMounted(async () => {
  console.log('OOK')
  if (
    permissions &&
    permissions[1] &&
    permissions[1].includes('admin') &&
    myCompanyId == 1
  ) {
    console.log('admin all tabs')
  } else {
    if (dashboard && dashboard.length > 0) {
      console.log('dashboard reading', dashboard)

      tabs.value = dashboard.map((item) => ({ ...item, name: t(item.name) }))
      activeTab.value = dashboard[0].key
    } else {
      tabs.value = user_tabs.value
      activeTab.value = 'private'
    }
  }
})
</script>

<template>
  <div class="grid grid-cols-12 gap-4 dashboard">
    <!-- Grid column -->
    <div class="ltablet:col-span-12 col-span-12 lg:col-span-12">
      <div class="grid gap-4 mt-4 mb-4 ml-5">
        <div class="nui-tabs w-full h-full flex flex-col relative">
          <!-- tabs -->
          <div class="flex w-full flex-row justify-between relative">
            <div class="tabs flex justify-between relative mb-8">
              <div
                v-for="item in tabs"
                :key="item.key"
                class="tabButton group cursor-pointer w-[85px] flex flex-col items-center"
                :class="{ active: activeTab === item.key }"
                @click="handleTabClick(item.key, item.name)"
              >
                <div
                  :class="
                    `nui-mask nui-mask-hexed mx-auto flex h-16 w-16 scale-90 items-center justify-center transition-all duration-300 group-hover:scale-100 ` +
                    item.hoverColor +
                    (activeTab === item.key
                      ? ' bg-primary-500 dark:bg-primary-500'
                      : ' bg-muted-200 dark:bg-muted-700')
                  "
                >
                  <div
                    :class="
                      `nui-mask nui-mask-hexed flex h-16 w-16 scale-95 items-center justify-center transition-all duration-300 ` +
                      (activeTab === item.key
                        ? ' bg-white dark:bg-muted-900'
                        : ' bg-white dark:bg-muted-800')
                    "
                  >
                    <Icon :name="item.icon" :class="`h-6 w-6 ` + item.color" />
                  </div>
                </div>
                <BaseHeading
                  as="h5"
                  size="sm"
                  weight="medium"
                  lead="tight"
                  class="text-muted-400 dark:text-muted-400 transition-all duration-300 group-hover:text-muted-600 dark:group-hover:text-muted-200"
                >
                  <span class="font-sans text-sm tabName">
                    {{ item.name }}</span
                  >
                </BaseHeading>
              </div>
            </div>

            <div v-if="activeTab !== 'monitoring'" class="filter mt-4 mr-1">
              <BaseButton class="" @click="handleModalOpen">
                <Icon name="circum:filter" class="-ms-1 h-4 w-4" />
                <span class="text-[11px]">{{ t('Filter') }}</span>
              </BaseButton>
            </div>
          </div>

          <div
            :class="[
              isModalOpen ? 'flex w-full relative container' : '',
              'flex w-full relative container',
            ]"
          >
            <div
              :class="[
                isModalOpen ? 'w-[80%]' : 'w-[100%]',
                ' relative block tabBodys',
              ]"
            >
              <!-- Tab1 cost -->
              <div
                :class="`grid grid-cols-12 gap-4 tabBody ` + activeTab"
                v-if="activeTab === 'cost'"
              >
                <Tab1
                  v-show="!tabLoadingStates.tab1"
                  :filter-data="tab1_data"
                  :is-open-filter="isModalOpen"
                />
              </div>

              <!-- Tab2 Work performance -->
              <div
                :class="`grid grid-cols-12 gap-4 tabBody ` + activeTab"
                v-if="activeTab == 'performance'"
              >
                <Tab2 v-show="!tabLoadingStates.tab2" :filterData="tab2_data" />
              </div>

              <!-- Tab3 Task progress -->
              <div
                :class="`grid grid-cols-12 gap-4 tabBody ` + activeTab"
                v-if="activeTab === 'task'"
              >
                <Tab3 v-show="!tabLoadingStates.tab3" :filterData="tab3_data" />
              </div>

              <!-- Tab4 safety -->
              <div
                :class="`tabBody ` + activeTab"
                v-if="activeTab === 'safety'"
              >
                <Tab4 v-show="!tabLoadingStates.tab4" :filterData="tab4_data" />
              </div>

              <!-- Tab6 monitoring -->
              <div
                :class="` gap-4 tabBody ` + activeTab"
                v-if="activeTab === 'monitoring'"
              >
                <Tab6 :filterData="tab6_data" />
              </div>
              <!-- Tab5 private -->
              <div
                :class="`grid grid-cols-12 gap-4 tabBody ` + activeTab"
                v-if="activeTab === 'private'"
              >
                <Tab5 :filterData="tab5_data" />
              </div>
            </div>

            <!-- filter -->
            <div
              v-show="isModalOpen == true && activeTab !== 'monitoring'"
              class="w-[20%]"
            >
              <FilterNewModalForm
                title="Filters"
                :open="isModalOpen"
                :close="handleModalClose"
                :refresh="refresh"
                size="3xl"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.dashboard .active .tabName {
  font-weight: bold;
  color: black;
  white-space: nowrap;
}

/* tabButton-ийн зургаан өнцөгт icon-г "3D товч" мэт харагдуулна. Дүрс нь
   clip-path (nui-mask-hexed)-ээр хайчлагдсан тул энгийн box-shadow
   харагдахгүй — clip-path-ийн ДАРАА, alpha хэлбэрээр тусдаг
   `filter: drop-shadow()`-г ашиглав. */
.tabButton {
  perspective: 600px;
}

.tabButton > div:first-child {
  transition: transform 0.3s ease, filter 0.3s ease;
  filter: drop-shadow(0 2px 3px rgba(15, 23, 42, 0.15))
    drop-shadow(0 8px 12px rgba(15, 23, 42, 0.12));
}

.tabButton:hover > div:first-child {
  transform: translateY(-4px) rotateX(10deg);
  filter: drop-shadow(0 4px 6px rgba(15, 23, 42, 0.2))
    drop-shadow(0 14px 20px rgba(15, 23, 42, 0.22));
}

.tabButton:active > div:first-child {
  transform: translateY(-1px) scale(0.97);
}

.tabButton.active > div:first-child {
  filter: drop-shadow(0 3px 5px rgba(15, 23, 42, 0.18))
    drop-shadow(0 10px 18px rgba(99, 102, 241, 0.35));
}

.dark .tabButton > div:first-child {
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.5))
    drop-shadow(0 8px 14px rgba(0, 0, 0, 0.4));
}

.dark .tabButton:hover > div:first-child {
  filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.6))
    drop-shadow(0 16px 24px rgba(0, 0, 0, 0.5));
}

.dark .tabButton.active > div:first-child {
  filter: drop-shadow(0 3px 5px rgba(0, 0, 0, 0.5))
    drop-shadow(0 10px 18px rgba(99, 102, 241, 0.45));
}
</style>
