<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import OwnMonitoring from '~/components/asset/OwnMonitoring.vue'

import '~/assets/css/vcalendar.css'
const { token } = useDirectusToken()
const { t } = useI18n({ useScope: 'global' })
const route = useRoute()
const router = useRouter()

definePageMeta({
  title: 'Device metrics',
  middleware: ['auth'],
  preview: {
    title: 'Device metrics',
    description: 'Device performance metrics and statistics',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-analytics.png',
    srcDark: '/img/screens/dashboards-analytics-dark.png',
    order: 4,
  },
})

const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

// Байршил (Location) жагсаалт ба сонголт
const locations = ref<any[]>([])
const selectedLocationId = ref<string | number | null>(null)
const locationLoading = ref(false)
const locationQuery = ref('')
const showLocationDropdown = ref(false)

// Олдсон Төхөөрөмжүүд
const assets = ref<any[]>([])
const selectedAssetId = ref<string | number | null>(null)
const searchQuery = ref('')
const loading = ref(false)
const error = ref<string | null>(null)

// Asset grid пейджинг
const assetPage = computed(() => parseInt((route.query.page as string) ?? '1'))
const assetPerPage = ref(12)

// Огнооны хүрээ — хуучин байрлал руугаа (хуудасны дээд тал) буцаав.
// OwnMonitoring-д prop-оор дамжуулж, доторх давхардсан огнооны controls-ыг
// hideDateControls-аар нуудаг (assetId солигдоход шиг, огноо солигдоход ч
// OwnMonitoring-г бүрэн шинээр mount хийхийн тулд :key-д оруулна — учир нь
// тэр prop-ийн өөрчлөлтийг дотооддоо ажигладаггүй).
const customFrom = ref(
  new Date(new Date().setDate(new Date().getDate() - 30))
    .toISOString()
    .split('T')[0],
)
const customTo = ref(new Date().toISOString().split('T')[0])
const selectedRange = ref(30)

const calculateDateRange = (days: number | string) => {
  const today = new Date()
  let fromDate: Date
  const toDate: Date = new Date(today)

  if (days === 'all') {
    fromDate = new Date('2020-01-01')
  } else {
    fromDate = new Date(today)
    fromDate.setDate(today.getDate() - Number(days) + 1)
  }

  return {
    from: fromDate.toISOString().split('T')[0],
    to: toDate.toISOString().split('T')[0],
  }
}

const dateOptions = computed(() => [
  { label: t('Last 7 days'), value: 7, ...calculateDateRange(7) },
  { label: t('Last 30 days'), value: 30, ...calculateDateRange(30) },
  { label: t('Last 60 days'), value: 60, ...calculateDateRange(60) },
  { label: t('Last 90 days'), value: 90, ...calculateDateRange(90) },
])

const applyDateRange = (days: number | string) => {
  selectedRange.value = days as any
  const option = dateOptions.value.find((opt) => opt.value === days)

  if (option) {
    customFrom.value = option.from
    customTo.value = option.to
  }
}

// Шүүсэн Төхөөрөмжүүд
const filteredAssets = computed(() => {
  const query = searchQuery.value.toLowerCase()
  if (!query) return assets.value

  return assets.value.filter((asset) => {
    const name = (asset.name || '').toLowerCase()
    const code = (asset.asset_code || '').toLowerCase()
    return name.includes(query) || code.includes(query)
  })
})

// Grid-д харуулах хуудаслагдсан Төхөөрөмжүүд
const paginatedAssets = computed(() => {
  console.log('Filtered Assets:', filteredAssets.value.length)
  console.log('Filtered Assets:', filteredAssets.value)
  console.log('Current Page:', assetPage.value)
  console.log('Assets Per Page:', assetPerPage.value)
  const start = (assetPage.value - 1) * assetPerPage.value
  console.log('Start Index:', start)
  return filteredAssets.value.slice(start, start + assetPerPage.value)
})

// Сонгосон байршлын объект
const selectedLocation = computed(
  () => locations.value.find((l) => l.id === selectedLocationId.value) || null,
)

const getLocationLabel = (loc: any) =>
  loc?.name || loc?.location_code || `#${loc?.id ?? ''}`

const filteredLocations = computed(() => {
  const q = locationQuery.value.trim().toLowerCase()
  if (!q) return locations.value.slice(0, 30)

  return locations.value
    .filter((loc) => {
      const name = (loc?.name || '').toLowerCase()
      const code = (loc?.location_code || '').toLowerCase()
      return name.includes(q) || code.includes(q) || String(loc?.id).includes(q)
    })
    .slice(0, 30)
})

// Сонгосон төхөөрмийн объект
const selectedAsset = computed(() => {
  if (selectedAssetId.value === 'all') {
    return { name: t('All equipment'), asset_code: '' }
  }
  return (
    assets.value.find((asset) => asset.id === selectedAssetId.value) || null
  )
})

// Төхөөрөмжүүдийг ачаалах (сонгосон байршлаар, parent+child бүгд нэг түвшинд)
const loadAssets = async () => {
  if (!selectedLocationId.value) {
    assets.value = []
    return
  }
  try {
    loading.value = true
    error.value = null

    const response = await getItems({
      collection: 'Assets',
      params: {
        filter: {
          // status: '1',
          location: { _eq: selectedLocationId.value },
          company_id: { _eq: myCompanyId },
        },
        fields: ['id', 'name', 'asset_code', 'asset_type'],
        sort: ['id'],
        limit: -1,
        meta: 'filter_count',
      },
    })

    const items = Array.isArray(response)
      ? response
      : (response as any)?.data || []

    assets.value = items
    router.push({ query: { page: undefined } })
    selectedAssetId.value = null
    console.log('✅ Төхөөрөмжүүд ачаалагдсан:', items.length, 'төхөөрөмж')
  } catch (err: any) {
    console.error('❌ Төхөөрөмжүүд ачаалахад алдаа:', err)

    // Диагностик информац
    if (err.response?.status === 403) {
      error.value = t(
        'Access to Assets collection is denied. Please contact the administrator.',
      )
    } else if (err.response?.status === 404) {
      error.value = t('Assets collection not found.')
    } else {
      error.value = err.message || t('Error loading equipment')
    }

    assets.value = []
  } finally {
    loading.value = false
  }
}

// Байршлуудыг ачаалах
const loadLocations = async () => {
  try {
    locationLoading.value = true
    const response = await getItems({
      collection: 'Location',
      params: {
        filter: { status: '1', company_id: { _eq: myCompanyId } },
        fields: ['id', 'name', 'location_code'],
        sort: ['id'],
        limit: -1,
      },
    })
    locations.value = Array.isArray(response)
      ? response
      : (response as any)?.data || []
  } catch (err) {
    console.error('❌ Байршлууд ачаалахад алдаа:', err)
    locations.value = []
  } finally {
    locationLoading.value = false
  }
}

// Байршил сонгогдоход холбоотой төхөөрөмжүүдийг ачаална
const onLocationChange = () => {
  searchQuery.value = ''
  selectedAssetId.value = null
  loadAssets()
}

const onLocationInput = (newValue: string | number | undefined) => {
  locationQuery.value = typeof newValue === 'string' ? newValue : ''
  selectedLocationId.value = null
  selectedAssetId.value = null
  assets.value = []
  showLocationDropdown.value = true
  router.push({ query: { page: undefined } })
}

const selectLocation = (loc: any) => {
  selectedLocationId.value = loc.id
  locationQuery.value = getLocationLabel(loc)
  showLocationDropdown.value = false
  onLocationChange()
}

const onLocationFocus = () => {
  showLocationDropdown.value = true
}

const onLocationBlur = () => {
  // Delay hide so option click can register first.
  setTimeout(() => {
    showLocationDropdown.value = false
  }, 120)
}

// Сонгосон Төхөөрөмжийг солих (grid item дээр дарахад)
const selectAsset = (assetId: string | number | null) => {
  selectedAssetId.value = assetId
}

onMounted(() => {
  loadLocations()
})

watch(paginatedAssets, () => {
  console.log('Paginated Assets Updated:', paginatedAssets.value)
})
</script>

<template>
  <div
    class="min-h-screen from-muted-50 to-muted-100 dark:from-muted-900 dark:to-muted-950 pb-12"
  >
    <!-- Filters Card -->
    <div class="space-y-6">
      <BaseCard
        class="cardBox2 p-8 shadow-sm border border-muted-200 dark:border-muted-800"
      >
        <div class="space-y-8">
          <!-- Date Range Filter Section -->
          <div class="border-b border-muted-200 dark:border-muted-800 pb-6">
            <div class="flex flex-wrap items-end gap-3">
              <!-- Quick range buttons -->
              <div class="flex flex-wrap gap-2">
                <button
                  v-for="opt in dateOptions"
                  :key="opt.value"
                  type="button"
                  @click="applyDateRange(opt.value)"
                  :class="[
                    'px-3 py-1.5 rounded-md text-xs font-medium transition-colors',
                    selectedRange === opt.value
                      ? 'bg-primary-600 text-white dark:bg-primary-500'
                      : 'bg-muted-100 text-muted-700 hover:bg-muted-200 dark:bg-muted-700 dark:text-muted-300 dark:hover:bg-muted-600',
                  ]"
                >
                  {{ opt.label }}
                </button>
              </div>

              <!-- Custom date inputs -->
              <div class="flex items-end gap-2">
                <div>
                  <label
                    class="block text-xs font-medium text-muted-600 dark:text-muted-400 mb-1"
                  >
                    {{ t('Start') }}
                  </label>
                  <input
                    v-model="customFrom"
                    type="date"
                    class="rounded-md border border-muted-300 dark:border-muted-600 bg-white dark:bg-muted-800 text-muted-900 dark:text-white px-2 py-1.5 text-xs focus:outline-none focus:ring-2 focus:ring-primary-500"
                    @change="selectedRange = 0"
                  />
                </div>
                <span class="text-muted-400 pb-1.5 text-sm">—</span>
                <div>
                  <label
                    class="block text-xs font-medium text-muted-600 dark:text-muted-400 mb-1"
                  >
                    {{ t('End') }}
                  </label>
                  <input
                    v-model="customTo"
                    type="date"
                    class="rounded-md border border-muted-300 dark:border-muted-600 bg-white dark:bg-muted-800 text-muted-900 dark:text-white px-2 py-1.5 text-xs focus:outline-none focus:ring-2 focus:ring-primary-500"
                    @change="selectedRange = 0"
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- Asset Selection Section -->
          <div class="border-b border-muted-200 dark:border-muted-800 pb-8">
            <div class="flex flex-col gap-4">
              <!-- Location filter + asset search -->
              <div class="flex flex-col sm:flex-row sm:items-end gap-3">
                <div class="flex-1 min-w-0">
                  <label
                    class="block text-xs font-medium text-muted-600 dark:text-muted-400 mb-1"
                  >
                    {{ t('Location') }}
                  </label>
                  <div class="relative">
                    <BaseInput
                      v-model="locationQuery"
                      type="text"
                      :placeholder="t('Select a location...')"
                      size="md"
                      icon="ph:map-pin"
                      :disabled="locationLoading"
                      :classes="{ input: locationQuery ? 'pr-8' : '' }"
                      style="
                        border-radius: 0.375rem;
                        border: 1px solid;
                        height: 36px;
                      "
                      @update:model-value="onLocationInput"
                      @focus="onLocationFocus"
                      @blur="onLocationBlur"
                    >
                      <template #action>
                        <button
                          v-if="locationQuery"
                          type="button"
                          class="location-clear-btn absolute right-2 top-1/2 -translate-y-1/2 text-muted-400 hover:text-muted-600 dark:hover:text-muted-200"
                          :aria-label="t('Clear')"
                          @mousedown.prevent="onLocationInput('')"
                        >
                          <Icon name="ph:x-circle-fill" class="h-4 w-4" />
                        </button>
                      </template>
                    </BaseInput>

                    <div
                      v-if="showLocationDropdown && filteredLocations.length"
                      class="absolute z-20 mt-1 w-full max-h-64 overflow-auto rounded-md border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-800 shadow-lg"
                    >
                      <button
                        v-for="loc in filteredLocations"
                        :key="loc.id"
                        type="button"
                        class="w-full px-3 py-2 text-left text-sm hover:bg-muted-100 dark:hover:bg-muted-700"
                        @mousedown.prevent="selectLocation(loc)"
                      >
                        <div
                          class="font-medium text-muted-800 dark:text-muted-100"
                        >
                          {{ loc.name || t('Unnamed location') }}
                        </div>
                        <div class="text-xs text-muted-400">
                          {{ loc.location_code || `#${loc.id}` }}
                        </div>
                      </button>
                      <div
                        v-if="
                          !locationLoading && filteredLocations.length === 0
                        "
                        class="px-3 py-2 text-xs text-muted-500"
                      >
                        {{ t('No results found') }}
                      </div>
                    </div>
                  </div>
                </div>

                <div v-if="selectedLocationId" class="flex-1 min-w-0">
                  <label
                    class="block text-xs font-medium text-muted-600 dark:text-muted-400 mb-1"
                  >
                    {{ t('Search equipment') }}
                  </label>
                  <BaseInput
                    v-model="searchQuery"
                    type="text"
                    :placeholder="t('Search by name or code...')"
                    size="md"
                    style="
                      border-radius: 0.375rem;
                      border-width: 1px;
                      border-style: solid;
                      height: 36px;
                    "
                    @update:model-value="
                      router.push({ query: { page: undefined } })
                    "
                  >
                    <template #prefix>
                      <Icon
                        name="ph:magnifying-glass"
                        class="h-4 w-4 text-muted-500"
                      />
                    </template>
                  </BaseInput>
                </div>
              </div>

              <!-- Байршил сонгоогүй үед -->
              <div
                v-if="!selectedLocationId"
                class="text-center py-8 text-muted-500"
              >
                <Icon
                  name="ph:map-pin"
                  class="h-10 w-10 mx-auto mb-2 opacity-40"
                />
                <p class="text-sm">{{ t('Select a location first') }}</p>
              </div>

              <!-- Хоосон -->
              <div
                v-else-if="!loading && filteredAssets.length === 0"
                class="text-center py-8 text-muted-500"
              >
                <Icon
                  name="ph:cube"
                  class="h-10 w-10 mx-auto mb-2 opacity-40"
                />
                <p class="text-sm">{{ t('No equipment in this location') }}</p>
              </div>

              <!-- Asset grid -->
              <div v-else-if="selectedLocationId">
                <div
                  class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3"
                >
                  <button
                    v-for="asset in paginatedAssets"
                    :key="asset.id"
                    type="button"
                    class="group flex items-center gap-3 rounded-xl border-2 p-3 text-left transition-all"
                    :class="
                      selectedAssetId === asset.id
                        ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/20 shadow-md'
                        : 'border-muted-200 dark:border-muted-700 bg-[#f8f8f8] dark:bg-muted-800 hover:border-primary-300 hover:shadow-sm'
                    "
                    @click="selectAsset(asset.id)"
                  >
                    <div
                      class="flex-shrink-0 flex items-center justify-center w-10 h-10 rounded-lg"
                      :class="
                        selectedAssetId === asset.id
                          ? 'bg-primary-500 text-white'
                          : 'bg-muted-100 dark:bg-muted-700 text-muted-500 group-hover:text-primary-500'
                      "
                    >
                      <Icon name="ph:cube-duotone" class="h-6 w-6" />
                    </div>
                    <div class="min-w-0 flex-1">
                      <div class="text-xs font-mono text-muted-500 truncate">
                        {{ asset.asset_code || '—' }}
                      </div>
                      <div
                        class="text-sm font-medium text-muted-800 dark:text-white truncate"
                      >
                        {{ asset.name }}
                      </div>
                    </div>
                    <Icon
                      v-if="selectedAssetId === asset.id"
                      name="ph:check-circle-fill"
                      class="h-5 w-5 text-primary-500 flex-shrink-0"
                    />
                  </button>
                </div>

                <!-- Pager -->
                <div v-if="filteredAssets.length > assetPerPage" class="mt-4">
                  <BasePagination
                    :current-page="assetPage"
                    :total-items="filteredAssets.length"
                    :item-per-page="assetPerPage"
                    rounded="lg"
                    @update:page="
                      (page) =>
                        router.push({
                          query: { page: page > 1 ? page : undefined },
                        })
                    "
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- Loading State -->
          <div v-if="loading" class="flex items-center justify-center py-12">
            <div class="text-center">
              <div class="mb-4">
                <BaseIconBox size="xl" color="primary" class="animate-spin">
                  <Icon name="svg-spinners:blocks-shuffle-3" class="h-8 w-8" />
                </BaseIconBox>
              </div>
              <p class="text-muted-600 dark:text-muted-400 font-medium">
                {{ t('Loading equipment...') }}
              </p>
            </div>
          </div>

          <!-- Error State -->
          <div
            v-if="error"
            class="bg-danger-50 dark:bg-danger-900/20 border-l-4 border-danger-500 rounded-lg p-6"
          >
            <div class="flex items-start gap-4">
              <div
                class="p-2 rounded-lg bg-danger-100 dark:bg-danger-900/30 flex-shrink-0"
              >
                <Icon
                  name="ph:warning-circle-fill"
                  class="h-6 w-6 text-danger-600 dark:text-danger-400"
                />
              </div>
              <div>
                <h4 class="font-bold text-danger-800 dark:text-danger-200 mb-1">
                  {{ t('An error occurred') }}
                </h4>
                <p class="text-danger-700 dark:text-danger-300 text-sm">
                  {{ error }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </BaseCard>

      <!-- Charts Section — OwnMonitoring.vue-тэй адил (sparkline/статистик/
           олон график, sensor tab) харуулна -->
      <div v-if="selectedAssetId" class="space-y-6">
        <BaseCard
          class="cardBox p-6 shadow-sm border border-muted-200 dark:border-muted-800"
        >
          <div class="flex items-center gap-3">
            <div class="p-2 rounded-lg bg-info-100 dark:bg-info-900/30">
              <Icon
                name="ph:chart-bar"
                class="h-6 w-6 text-info-600 dark:text-info-400"
              />
            </div>
            <div>
              <BaseHeading as="h2" size="md" weight="bold">
                {{ t('Equipment performance chart') }}
              </BaseHeading>
              <p
                v-if="selectedAsset"
                class="text-sm text-muted-600 dark:text-muted-400 mt-1"
              >
                <span
                  class="font-medium text-primary-600 dark:text-primary-400"
                >
                  {{ selectedAsset.name }}
                </span>
                <span v-if="selectedAsset.asset_code" class="text-muted-400">
                  ({{ selectedAsset.asset_code }})
                </span>
              </p>
            </div>
          </div>
        </BaseCard>

        <!-- assetId эсвэл дээд огнооны filter (customFrom/customTo)
             солигдох бүрд бүрэн шинээр mount хийгдэхийн тулд :key
             шаардлагатай — OwnMonitoring эдгээр prop-ийн өөрчлөлтийг
             дотооддоо ажигладаггүй, зөвхөн анх mount хийгдэхдээ л дата
             ачаалдаг тул. hide-date-controls нь доторх давхардсан огнооны
             controls-ыг (дээд талд аль хэдийн байгаа тул) нуудаг. -->
        <OwnMonitoring
          :key="`${selectedAssetId}-${customFrom}-${customTo}`"
          :asset-id="Number(selectedAssetId)"
          :from="customFrom"
          :to="customTo"
          hide-date-controls
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Градиент фон */
.bg-gradient-to-br {
  background-image: linear-gradient(135deg, var(--tw-gradient-stops));
}

/* Анимацийн стилүүд */
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes slideDown {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

@keyframes pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.fade-in {
  animation: fadeIn 0.3s ease-in-out;
}

.slide-down {
  animation: slideDown 0.4s ease-in-out;
}

/* Smooth transitions */
button {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

button:hover {
  transform: translateY(-2px);
}

button:active {
  transform: translateY(0);
}

/* Location input дэх X (цэвэрлэх) товч босоо голлуулгаа (translateY(-50%))
   алдахгүйн тулд дээрх ерөнхий button:hover дүрмээс чөлөөлнө — эс тэгвэл
   hover хийхэд голлуулгын transform нь -2px-ээр солигдож, товч "үсэрч"
   харагддаг байсан */
.location-clear-btn,
.location-clear-btn:hover,
.location-clear-btn:active {
  transform: translateY(-50%);
}

/* Card hover effects */
:deep(.BaseCard) {
  transition: all 0.3s ease-in-out;
}

:deep(.BaseCard:hover) {
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

/* "3D" карт — энд `cardBox` нь BaseCard-ийн root дээр (тусдаа wrapper div
   биш) шууд class-аар нэгддэг тул `.nui-card` тусад нь заах шаардлагагүй,
   `perspective()`-г transform-ийн дотор өөрт нь оруулав (эцэг элементэд
   perspective property тавих боломжгүй тул). */
.cardBox,
.cardBox2 {
  transition: transform 0.25s ease, box-shadow 0.25s ease;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.06),
    0 8px 16px -6px rgba(15, 23, 42, 0.12),
    0 20px 32px -12px rgba(15, 23, 42, 0.18);
}

.cardBox:hover {
  transform: perspective(800px) translateY(-6px) rotateX(2deg);
  box-shadow: 0 2px 4px rgba(15, 23, 42, 0.08),
    0 16px 24px -8px rgba(15, 23, 42, 0.18),
    0 32px 48px -16px rgba(15, 23, 42, 0.28);
}

:global(.dark) .cardBox {
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.4), 0 8px 16px -6px rgba(0, 0, 0, 0.5),
    0 20px 32px -12px rgba(0, 0, 0, 0.6);
}

:global(.dark) .cardBox:hover {
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.5), 0 16px 24px -8px rgba(0, 0, 0, 0.6),
    0 32px 48px -16px rgba(0, 0, 0, 0.7);
}

/* Smooth scrolling */
html {
  scroll-behavior: smooth;
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: transparent;
}

::-webkit-scrollbar-thumb {
  background-color: rgba(0, 0, 0, 0.2);
  border-radius: 4px;
}

::-webkit-scrollbar-thumb:hover {
  background-color: rgba(0, 0, 0, 0.3);
}

/* Dark mode scrollbar */
:dark::-webkit-scrollbar-thumb {
  background-color: rgba(255, 255, 255, 0.1);
}

:dark::-webkit-scrollbar-thumb:hover {
  background-color: rgba(255, 255, 255, 0.2);
}
</style>
