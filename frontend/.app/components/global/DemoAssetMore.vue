<script setup lang="ts">
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })

const { params } = useRoute()

const status = ref({})

const { close, currentProps } = usePanels()
const activeTab = ref('tab-1')
let selectedStatuses = []

const filter_modules = {
  RawData: 'RawData',
  Settings: 'Settings',
}

const activeFilter = ref('RawData')

const { getItems, updateItem, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const loading = ref(true)
const records = ref([])

// Check hostname for conditional component rendering
const isSmartGPS = ref(false)
if (process.client) {
  isSmartGPS.value = window.location.hostname === 'smartgps.ibex-data.mn'
}

console.log(' currentProps?.value', currentProps?.value)

const asset_id = currentProps?.value?.id || null
const asset_data = currentProps?.value?.data || null
const refresh = currentProps?.value?.refresh || null
const w_type = currentProps?.value?.w_type || 'wo'
const p_type = currentProps?.value?.p_type || 'pm'
const active_tab = currentProps?.value?.active_tab || null
console.log(' asset_id', asset_id)
console.log(' asset_data', asset_data)

let priority = null
const now = new Date()
</script>

<template>
  <div
    class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 border bg-white w-[80%] overflow-y-scroll"
  >
    <div class="flex h-16 w-full items-center px-10 more">
      <button
        type="button"
        class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300 dark:hover:text-white"
        @click="close"
      >
        <Icon name="line-md:close" class="h-5 w-5" />
      </button>
      <div class="max-w-4xl title">
        <div
          class="flex font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white m-[10px]"
        >
          {{ asset_data.asset_code }}
        </div>
      </div>
    </div>
    <div class="relative">
      <!-- Grid -->
      <div class="grid grid-cols-4 gap-6 asset_more p-12">
        <!-- Header -->
        <div class="col-span-4">
          <BaseTabs
            justify="end"
            type="box"
            :model-value="active_tab != null ? active_tab : 'admition'"
            class="tabs"
            :tabs="[
              { label: $t('Admition'), value: 'admition' },
              { label: $t('PMs'), value: 'pm' },
              { label: $t('WOs'), value: 'wo' },
              { label: $t('Parts'), value: 'parts' },
              { label: $t('Datahub'), value: 'datahub' },
              { label: $t('Monitoring'), value: 'monitoring' },
              { label: $t('AI coming soon ...'), value: 'AI coming soon ...' },
              { label: $t('Children'), value: 'children' },
            ]"
          >
            <template #tab="{ activeValue }">
              <!-- Debug: Current activeValue -->
              <div v-if="false" class="p-2 bg-yellow-100">
                Active Value: {{ activeValue }}
              </div>

              <div
                v-if="activeValue === 'admition'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <!-- <NormalForm
                  title="Assets"
                  code="Assets"
                  schema_column="three-column-form"
                  fields="status,asset_code,name,asset_type,location,manufacturer,department,description,model_number,safety_notes,serial_number,barcode,available_hour,warranty_start_date,warranty_finish_date,inspection_done_date,inspection_next_due_date,purchase_code"
                  :row="asset_id"
                /> -->

                <AssetsForm
                  :row="asset_id"
                  :title="$t('Assets')"
                  code="Assets"
                  :refresh="refresh"
                />
              </div>

              <div
                v-else-if="activeValue === 'pm'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkorderList
                  :status="status"
                  class="tabGridBody"
                  type="pm"
                  :asset="asset_id"
                  :asset_data="asset_data"
                  work_order_type="pm_asset"
                  :call_type="p_type"
                  :collection_name="'Work_pm'"
                />
              </div>

              <div
                v-else-if="activeValue === 'wo'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <!-- :location="asset_data?.location" -->
                <WorkorderList
                  class="tabGridBody"
                  type="works"
                  :status="status"
                  :asset="asset_id"
                  :location="Number(params.id)"
                  :call_type="w_type"
                  work_order_type="wo"
                />
              </div>
              <div
                v-else-if="activeValue === 'parts'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <AssetsParts
                  :asset_id="asset_id"
                  :location_id="asset_data?.location"
                />
              </div>
              <div
                v-else-if="activeValue === 'datahub'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <BaseTabs
                  justify="start"
                  type="tabs"
                  v-model="activeFilter"
                  class="subtabs"
                  :tabs="[
                    { label: $t('RawData'), value: 'RawData' },
                    { label: $t('LiveData'), value: 'LiveData' },
                    { label: $t('Settings'), value: 'Settings' },
                    { label: $t('Alerts'), value: 'Alerts' },
                  ]"
                >
                  <template #tab="{ activeValue: subActiveValue }">
                    <!-- For smartgps.ibex.mn hostname -->
                    <template v-if="isSmartGPS"> </template>

                    <!-- For other hostnames -->
                    <template v-else>
                      <div
                        v-if="subActiveValue === 'RawData'"
                        class="font-sans text-sm text-gray-500 dark:text-gray-400"
                      >
                        <AssetOwnTracking
                          :asset-id="asset_id"
                          :device-id="asset_data?.device_id"
                        />
                      </div>
                      <div
                        v-if="subActiveValue === 'LiveData'"
                        class="font-sans text-sm text-gray-500 dark:text-gray-400"
                      >
                        <AssetOwnLiveData :asset-id="asset_id" />
                      </div>
                      <div
                        v-else-if="subActiveValue === 'Settings'"
                        class="font-sans text-sm text-gray-500 dark:text-gray-400"
                      >
                        <AssetOwnDeviceSettings
                          :asset-id="asset_id"
                          :device-id="asset_data?.device_id"
                        />
                      </div>
                      <div
                        v-else-if="subActiveValue === 'Alerts'"
                        class="font-sans text-sm text-gray-500 dark:text-gray-400"
                      >
                        <AssetOwnMonitoringAlertsSettings
                          :asset-id="asset_id"
                        />
                      </div>
                    </template>
                  </template>
                </BaseTabs>
              </div>
              <div
                v-else-if="activeValue === 'AI coming soon ...'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                AI coming soon ...
              </div>
              <div
                v-else-if="activeValue === 'monitoring'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <template v-if="isSmartGPS"></template>
                <template v-else>
                  <AssetOwnMonitoring :asset-id="asset_id" />
                </template>
              </div>
              <div
                v-else-if="activeValue === 'children'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <AssetsTree
                  :location="asset_data?.location || params.id"
                  :parent="asset_id"
                  :is_more_click="false"
                />
              </div>
            </template>
          </BaseTabs>
        </div>
      </div>
    </div>
  </div>
</template>
