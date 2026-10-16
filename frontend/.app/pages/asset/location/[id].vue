<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
import AssetImportModal from '~/components/assets/AssetImportModal.vue'
import PartsOfAssetImportModal from '~/components/parts/PartsOfAssetImportModal.vue'
import { useAssetImport } from '~/composables/useAssetImport'
import { usePartsOfAssetImport } from '~/composables/usePartsOfAssetImport'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Equipments',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})
const { params } = useRoute()
const router = useRouter()
const toaster = useToaster()
const { getItems } = useDirectusItems()
const isImportModalOpen = ref(false)
const isPartsOfAssetImportModalOpen = ref(false)
const { importAssets } = useAssetImport()
const { importPartsOfAsset } = usePartsOfAssetImport()

// Asset import fields
const assetFields = [
  { name: 'asset_code', label: 'Asset Code', required: true },
  { name: 'name', label: 'Asset Name', required: true },
  { name: 'reading_type', label: 'Reading Type', required: true },
  { name: 'serial_number', label: 'Serial Number' },
  { name: 'model_number', label: 'Model Number' },
  { name: 'purchase_cost', label: 'Purchase Cost' },
  { name: 'description', label: 'Description' },
]

// Convert params.id to number
const locationId = computed(() => {
  const id = Array.isArray(params.id) ? params.id[0] : params.id
  return parseInt(id as string, 10)
})

const handleImportClick = () => {
  isImportModalOpen.value = true
}

const handleImportPartsOfAssetsClick = () => {
  isPartsOfAssetImportModalOpen.value = true
}

const handleImportModalClose = () => {
  isImportModalOpen.value = false
}

const handleAssetsImport = async (assetsData: any[]) => {
  const success = await importAssets(assetsData, locationId.value)
  if (success) {
    // Refresh the assets list
    handleImportModalClose()
    // You may want to emit a refresh event or use a key to force component reload
    // window.location.reload()
  }
}

const onNewAssetClick = async () => {
  const myCompanyId = getMyCompanyId()

  try {
    const companyRes = await getItems({
      collection: 'Companies',
      params: {
        filter: { id: { _eq: myCompanyId } },
        fields: ['active_asset_cnt'],
        limit: 1,
      },
    })
    const companyData = Array.isArray(companyRes)
      ? companyRes
      : companyRes?.data ?? []
    const activeAssetCnt = Number(companyData[0]?.active_asset_cnt) || 0

    // active_asset_cnt = 0 -> hyazgaargui
    if (activeAssetCnt > 0) {
      const assetsRes = await getItems({
        collection: 'Assets',
        params: {
          filter: { company_id: { _eq: myCompanyId }, status: { _eq: '1' } },
          meta: 'filter_count',
          limit: 1,
          fields: ['id'],
        },
      })
      const currentAssetCnt = assetsRes?.meta?.filter_count ?? 0

      if (currentAssetCnt >= activeAssetCnt) {
        toaster.clearAll()
        toaster.show({
          title: t('Error'),
          message: t('Asset limit reached. Please upgrade your package'),
          color: 'danger',
          icon: 'ph:warning-circle-fill',
          closable: true,
        })
        return
      }
    }

    router.push(`/asset/new/${locationId.value}`)
  } catch (error) {
    console.error('Error checking asset limit:', error)
    toaster.clearAll()
    toaster.show({
      title: t('Error'),
      message: t('Unable to add asset, please try again'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
  }
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="left cursor-pointer" @click="onNewAssetClick">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Add Asset') }}</span>
        </BaseButton>

        <BaseButton class="left cursor-pointer ml-1" @click="handleImportClick">
          <Icon name="octicon:upload-16" class="h-4 w-4" />
          <span class="text-[11px]">{{ $t('Import Assets') }}</span>
        </BaseButton>

        <!-- <BaseButton
          class="left cursor-pointer ml-1"
          @click="handleImportPartsOfAssetsClick"
        >
          <Icon name="octicon:upload-16" class="h-4 w-4" />
          <span class="text-[11px]">{{ $t('Import Parts Of Asset') }}</span>
        </BaseButton> -->
      </div>

      <!-- GridBody -->
      <div class="col-span-12 GridBody">
        <TairoContentWrapperTabbed
          :labels="[$t('List'), $t('Tree')]"
          reverse
          shape="curved"
        >
          <template #tab-1>
            <AssetsList :location="locationId" />
          </template>
          <template #tab-2>
            <AssetsTree :location="locationId" :parent="(0 as any)" />
          </template>
        </TairoContentWrapperTabbed>
      </div>
    </div>

    <!-- Import Modal -->
    <AssetImportModal
      :is-open="isImportModalOpen"
      :location-id="locationId"
      :fields="assetFields"
      @close="handleImportModalClose"
      @import="handleAssetsImport"
    />

    <!-- Parts of Asset Import Modal -->
    <PartsOfAssetImportModal
      :is-open="isPartsOfAssetImportModalOpen"
      :location-id="locationId"
      @close="isPartsOfAssetImportModalOpen = false"
      @import="(rows) => importPartsOfAsset(rows, locationId)"
    />
  </div>
</template>
