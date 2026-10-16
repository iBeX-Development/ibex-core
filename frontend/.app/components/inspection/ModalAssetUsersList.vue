<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import ModalAssetsList from '~/components/inspection/ModalAssetsList.vue'

const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()

const selectedItems = ref<any[]>([])
const assetOptions = ref<any[]>([])
const selectedAsset = ref<any>(null)
const isUserChooseOpen = ref(false)
const isAssetModalOpen = ref(false)
const searchAsset = ref('')
const addedPairs = ref<any[]>([])

const props = defineProps({
  open: Boolean,
  close: Function,
  saveUsers: Function,
  location: [Number, String],
  currentAsset: Object,
})

type TableOptions = {
  page: number
  itemsPerPage: number
  sortBy: Array<{ key?: string; order?: 'asc' | 'desc' }>
}

const closeModal = () => {
  if (props.close) {
    props.close()
  }
}

const applySelected = () => {
  if (!selectedAsset.value?.id) {
    toaster.show({
      title: t('Warning'),
      message: t('Please choose asset'),
      color: 'warning',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  if (!selectedItems.value || selectedItems.value.length === 0) {
    toaster.show({
      title: t('Warning'),
      message: t('Please choose users'),
      color: 'warning',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  // Add pair to the list for preview
  addedPairs.value.push({
    asset: selectedAsset.value,
    users: [...selectedItems.value],
  })

  // Clear selection for next entry
  selectedAsset.value = null
  selectedItems.value = []
  searchAsset.value = ''

  toaster.show({
    title: t('Success'),
    message: t('Asset and users added to list'),
    color: 'success',
    icon: 'ph:check-circle-fill',
    closable: true,
  })
}

const removePair = (index: number) => {
  addedPairs.value.splice(index, 1)
}

const savePairs = async () => {
  if (addedPairs.value.length === 0) {
    toaster.show({
      title: t('Warning'),
      message: t('Please add at least one asset and users'),
      color: 'warning',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  if (!props.saveUsers) {
    return
  }

  // Save all pairs sequentially
  for (let i = 0; i < addedPairs.value.length; i++) {
    const pair = addedPairs.value[i]
    await props.saveUsers({
      asset: pair.asset,
      users: pair.users,
    })
  }

  // Clear and close
  addedPairs.value = []
  selectedItems.value = []
  selectedAsset.value = null
  searchAsset.value = ''
  closeModal()
}

const openUserChoose = () => {
  isUserChooseOpen.value = true
}

const closeUserChoose = () => {
  isUserChooseOpen.value = false
}

const savePickedUsers = (users: any[]) => {
  selectedItems.value = users || []
  isUserChooseOpen.value = false
}

const filteredAssets = computed(() => {
  if (!searchAsset.value) {
    return assetOptions.value
  }
  const query = searchAsset.value.toLowerCase()
  return assetOptions.value.filter(
    (asset: any) =>
      asset.name?.toLowerCase().includes(query) ||
      asset.asset_code?.toLowerCase().includes(query),
  )
})

const openAssetModal = () => {
  isAssetModalOpen.value = true
}

const closeAssetModal = () => {
  isAssetModalOpen.value = false
}

const selectAssetFromModal = (asset: any) => {
  selectedAsset.value = asset
  searchAsset.value = asset.name
  isAssetModalOpen.value = false
}

const modalAssetLocation = computed<number | undefined>(() => {
  return typeof props.location === 'number' ? props.location : undefined
})

const loadAssets = async () => {
  try {
    const filters: any = { status: '1', company_id: { _eq: myCompanyId } }
    if (props.location) {
      const locationId = parseInt(props.location as string, 10)
      filters.location = locationId
    }

    console.log('Loading assets with filters:', filters)

    const items = await getItems({
      collection: 'Assets',
      params: {
        filter: filters,
        limit: -1,
        sort: ['name'],
        fields: ['id', 'name', 'asset_code', 'location.id', 'status'],
      },
    })

    let assetsRows: any[] = []
    if (Array.isArray(items)) {
      assetsRows = items
    } else {
      assetsRows = (items as any)?.data || []
    }
    assetOptions.value = assetsRows
  } catch (e) {
    console.error('Error loading assets:', e)
    assetOptions.value = []
  }
}

watch(
  () => props.open,
  async (isOpen) => {
    if (!isOpen) {
      return
    }

    selectedItems.value = []
    selectedAsset.value = null
    searchAsset.value = ''
    isUserChooseOpen.value = false
    await loadAssets()
  },
)
</script>

<template>
  <TairoModal
    :open="props.open"
    :style="{ padding: '0' }"
    :size="'xl'"
    @close="closeModal"
    :classes="{ wrapper: 'TairoModal Users' }"
  >
    <template #header>
      <div class="border-b border-muted-200 dark:border-muted-700 px-6 py-4">
        <div class="flex w-full items-center justify-between">
          <div class="flex items-center gap-3">
            <div
              class="flex size-10 items-center justify-center rounded-lg bg-gradient-to-br from-primary-100 to-primary-50 dark:from-primary-900/30 dark:to-primary-800/20 shadow-sm"
            >
              <Icon
                name="lucide:users"
                class="size-5 text-primary-600 dark:text-primary-400"
              />
            </div>
            <div>
              <h3
                class="font-heading text-muted-900 text-lg font-semibold leading-6 dark:text-white"
              >
                {{ t('Asset and users') }}
              </h3>
              <p class="text-muted-400 mt-0.5 text-xs dark:text-muted-500">
                {{ t('Choose one asset and multiple users') }}
              </p>
            </div>
          </div>
          <BaseButtonClose @click="closeModal" />
        </div>
      </div>
    </template>

    <div class="TairoModalBody px-6 py-5">
      <!-- Asset Section -->
      <div
        class="mb-6 rounded-lg border border-muted-200 bg-gradient-to-br from-muted-50 to-muted-0 p-4 dark:border-muted-700 dark:from-muted-900/30 dark:to-muted-900/10"
      >
        <label
          class="text-muted-700 mb-3 block text-sm font-semibold dark:text-muted-300"
        >
          <Icon
            name="lucide:package"
            class="mb-0.5 mr-1.5 inline-block size-4"
          />
          {{ t('Asset') }}
        </label>
        <div class="mb-3 flex gap-2">
          <div class="flex-1">
            <BaseInput
              v-model="searchAsset"
              type="text"
              :placeholder="t('Search assets by name or code...')"
              icon="lucide:search"
              rounded="md"
              size="md"
              class="border border-muted-300 bg-white shadow-sm transition-all duration-200 focus:border-primary-400 dark:border-muted-600 dark:bg-muted-800"
            />
          </div>
          <BaseButton
            color="muted"
            rounded="md"
            size="md"
            class="shadow-sm hover:shadow-md transition-all duration-200 dark:hover:bg-muted-700"
            @click="openAssetModal"
            :title="t('Browse all assets')"
          >
            <Icon name="lucide:more-horizontal" class="h-4 w-4" />
          </BaseButton>
        </div>

        <!-- Selected asset display -->
        <div v-if="selectedAsset" class="animate-in fade-in duration-200">
          <BaseTag
            rounded="md"
            color="primary"
            variant="solid"
            class="inline-flex items-center gap-2 px-3 py-2"
          >
            <Icon name="lucide:check-circle-2" class="h-4 w-4" />
            <span
              >{{ selectedAsset.name }} ({{ selectedAsset.asset_code }})</span
            >
          </BaseTag>
        </div>
        <div v-else class="text-muted-400 text-xs italic dark:text-muted-500">
          {{ t('No asset selected') }}
        </div>
      </div>

      <!-- Users Section -->
      <div
        class="mb-6 rounded-lg border border-muted-200 bg-gradient-to-br from-muted-50 to-muted-0 p-4 dark:border-muted-700 dark:from-muted-900/30 dark:to-muted-900/10"
      >
        <p
          class="text-muted-700 mb-3 flex items-center text-sm font-semibold dark:text-muted-300"
        >
          <Icon name="lucide:users-2" class="mr-1.5 size-4" />
          {{ t('Users') }}
        </p>
        <div
          class="rounded-lg border border-muted-200 bg-white p-4 dark:border-muted-700 dark:bg-muted-800/50"
        >
          <div v-if="selectedItems.length" class="flex flex-wrap gap-2">
            <BaseTag
              v-for="user in selectedItems"
              :key="user.id"
              rounded="full"
              color="info"
              variant="pastel"
              class="inline-flex items-center gap-1"
            >
              <Icon name="lucide:user-check" class="h-3 w-3" />
              <span>{{ user.first_name }} {{ user.last_name }}</span>
            </BaseTag>
          </div>
          <p v-else class="text-muted-400 text-sm italic dark:text-muted-500">
            {{ t('No users selected') }}
          </p>

          <div class="mt-4 flex justify-end gap-2">
            <BaseButton
              size="sm"
              @click="openUserChoose"
              class="shadow-sm hover:shadow-md transition-all duration-200"
            >
              <Icon name="lucide:list-plus" class="-ms-1 h-4 w-4" />
              <span>{{ t('Choose') }}</span>
            </BaseButton>
            <BaseButton
              size="sm"
              color="primary"
              :disabled="selectedItems.length === 0 || !selectedAsset"
              @click="applySelected"
              class="shadow-sm hover:shadow-md transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <Icon name="lucide:plus" class="-ms-1 h-4 w-4" />
              <span>{{ t('Add') }}</span>
            </BaseButton>
          </div>
        </div>
      </div>

      <!-- Added Pairs Preview Table -->
      <div v-if="addedPairs.length > 0" class="mb-6">
        <h4
          class="text-muted-700 mb-3 text-sm font-semibold dark:text-muted-300"
        >
          <Icon
            name="lucide:list-checks"
            class="mb-0.5 mr-1.5 inline-block size-4"
          />
          {{ t('Added Items') }} ({{ addedPairs.length }})
        </h4>
        <div class="space-y-3">
          <div
            v-for="(pair, idx) in addedPairs"
            :key="idx"
            class="flex items-center justify-between rounded-lg border border-muted-200 bg-muted-50 p-3 dark:border-muted-700 dark:bg-muted-900/30"
          >
            <div class="flex-1">
              <div class="flex items-center gap-2 mb-2">
                <Icon
                  name="lucide:package"
                  class="h-4 w-4 text-primary-600 dark:text-primary-400"
                />
                <span class="font-medium text-muted-900 dark:text-white">{{
                  pair.asset.name
                }}</span>
                <span class="text-muted-500 text-xs dark:text-muted-400"
                  >({{ pair.asset.asset_code }})</span
                >
              </div>
              <div class="flex flex-wrap gap-1 ml-6">
                <BaseTag
                  v-for="user in pair.users"
                  :key="user.id"
                  rounded="full"
                  color="info"
                  variant="pastel"
                  size="sm"
                >
                  {{ user.first_name }} {{ user.last_name }}
                </BaseTag>
              </div>
            </div>
            <BaseButton
              color="danger"
              size="sm"
              rounded="md"
              @click="removePair(idx)"
              class="ml-3 shadow-sm hover:shadow-md transition-all duration-200"
            >
              <Icon name="lucide:trash-2" class="h-4 w-4" />
            </BaseButton>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div
        class="flex items-center justify-between border-t border-muted-200 pt-5 dark:border-muted-700"
      >
        <p class="text-muted-500 text-xs dark:text-muted-400">
          {{ addedPairs.length }} {{ t('items added') }}
        </p>
        <div class="flex items-center gap-2">
          <BaseButton
            @click="closeModal"
            class="shadow-sm hover:shadow-md transition-all duration-200"
          >
            {{ t('Cancel') }}
          </BaseButton>
          <BaseButton
            color="primary"
            :disabled="addedPairs.length === 0"
            class="shadow-sm hover:shadow-md transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
            @click="savePairs"
          >
            <Icon name="lucide:save" class="-ms-1 h-4 w-4" />
            {{ t('Save All') }}
          </BaseButton>
        </div>
      </div>

      <UserCheckList
        collection="Users"
        :open="isUserChooseOpen"
        :close="closeUserChoose"
        :saveUser="savePickedUsers"
        :chooseBttn="false"
        :saveBttn="true"
        :chosedItems="selectedItems"
      />

      <ModalAssetsList
        :open="isAssetModalOpen"
        :close="closeAssetModal"
        :setAsset="selectAssetFromModal"
        :location="props.location"
      />
    </div>
  </TairoModal>
</template>

<style scoped>
.TairoModal.Users .TairoModalBody {
  padding: 0 !important;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(-4px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-in {
  animation: fadeIn 0.2s ease-in-out;
}
</style>
