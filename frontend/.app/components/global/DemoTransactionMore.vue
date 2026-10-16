<script setup lang="ts">
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import PriorityCell from '~/components/custom/priorityCell.vue'

import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AssetParts from '~/components/parts/AssetParts.vue'
import BinLocation from '~/components/parts/BinLocations.vue'
import IncomeParts from '~/components/parts/IncomeParts.vue'
import OutcomeParts from '~/components/parts/OutcomeParts.vue'
import ShiftHistoryParts from '~/components/parts/ShiftHistoryParts.vue'
import StockParts from '~/components/parts/StockParts.vue'
import WorkOrderParts from '~/components/parts/WorkOrderParts.vue'
import Actions from '~/components/transaction/Actions.vue'
import Documents from '~/components/transaction/Documents.vue'
import OutcomeInfoModalForm from '~/components/transaction/OutcomeInfoModalForm.vue'
import Parts from '~/components/transaction/Parts.vue'

const { t } = useI18n({ useScope: 'global' })
const { params } = useRoute()

definePageMeta({
  middleware: ['auth'],
  title: 'Preview asset',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})

const status = ref({
  _neq: 3,
})

const { close, currentProps } = usePanels()
const activeTab = ref('tab-1')
let selectedStatuses = []

const { getItems, updateItem, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const loading = ref(true)
const records = ref([])
const uploadedFiles = ref([])
const transaction_parts = ref([])

const item_id = currentProps?.value?.id || null
const item_data = currentProps?.value?.data || null
const item_auto_number = currentProps?.value?.data?.auto_number || null
const refresh = currentProps?.value?.refresh || null
const modulee = currentProps?.value?.module || null
const type = currentProps?.value?.type || null
let title = ''

// console.log('currentProps', currentProps?.value)

if (item_data.transaction_type === 'OUTCOME') {
  title = t('Debt')
} else if (item_data.transaction_type === 'INCOME') {
  title = t('Income')
} else if (item_data.transaction_type === 'AssetParts') {
  title = ''
}

if (item_data?.work_order) {
  const filters = {
    status: 1,
    work_order: item_data?.work_order.id,
  }

  const wo_items = await getItems({
    collection: 'Work_order_Parts',
    params: {
      filter: filters,
      meta: 'filter_count',
      fields: ['*', 'parts.*', 'work_order.* '],
    },
  })

  const items = await getItems({
    collection: 'Transaction_parts',
    params: {
      filter: { transaction_id: item_id },
      meta: 'filter_count',
      fields: ['*', 'part.*'],
    },
  })

  if (items.data.length > 0) {
    transaction_parts.value = items.data.map((item, index) => {
      let wo_qty = 0
      if (wo_items.data.length > 0) {
        // First try to match by both part.id and part_state
        const wo_part_by_state = wo_items.data.filter(
          (wo) =>
            wo.parts.id == item.part.id && wo.part_state == item.part_state,
        )
        if (wo_part_by_state.length > 0) {
          wo_qty = wo_part_by_state[0]?.quantity
        } else {
          // Fallback: match by part.id only
          const wo_part = wo_items.data.filter(
            (wo) => wo.parts.id == item.part.id,
          )
          wo_qty = wo_part[0]?.quantity
        }
      }

      const { part, ...rest } = item

      return {
        ...rest,
        quantity: wo_qty,
        part: part,
      }
    })
  }
}

console.log(' currentProps?.value', currentProps?.value)
// console.log(' item_data', item_data)

let priority = null
const now = new Date()
const handleUpload = async (items) => {
  uploadedFiles.value = items

  if (uploadedFiles.value.length) {
    uploadedFiles.value.map(async (uploadedFile) => {
      const file_items = {
        transaction_id: item_id,
        file: uploadedFile.file.id,
        company_id: myCompanyId,
      }

      const items = await getItems<any>({
        collection: 'Transaction_files',
        params: {
          filter: file_items,
          limit: -1,
          page: 1,
          meta: 'filter_count',
          fields: ['*', 'file.*'],
        },
      })

      if (items.data.length == 0) {
        const file_res = await createItems({
          collection: 'Transaction_files',
          items: file_items,
        })
      }
    })
  }
}
</script>

<template>
  <div
    class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 border bg-white w-[80%] overflow-y-scroll"
  >
    <!-- Top accent bar -->

    <div
      class="relative flex h-14 w-full items-center px-5 border-b border-muted-100 dark:border-muted-700"
    >
      <button
        type="button"
        class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-8 w-8 items-center justify-center rounded-full transition-colors duration-300 dark:hover:text-white flex-shrink-0 z-20 mr-4"
        @click="close"
      >
        <Icon name="line-md:close" class="h-4 w-4" />
      </button>
      <div class="flex justify-between flex-1 min-w-0 gap-4" v-if="title != ''">
        <div
          class="flex items-center gap-2 font-heading text-muted-900 text-base font-semibold dark:text-white truncate"
        >
          <Icon
            :name="
              item_data.transaction_type === 'INCOME'
                ? 'ph:arrow-circle-down'
                : 'ph:arrow-circle-up'
            "
            :class="
              item_data.transaction_type === 'INCOME'
                ? 'text-emerald-500'
                : 'text-rose-500'
            "
            class="h-5 w-5 flex-shrink-0"
          />
          {{ title }}
          <span class="text-muted-400 font-normal"
            >#{{ item_auto_number }}</span
          >
        </div>
        <div class="flex items-center flex-shrink-0">
          <PriorityCell fieldName="action_status" :value="item_data.status" />
        </div>
      </div>
    </div>
    <div class="relative">
      <!-- Grid -->
      <div class="grid grid-cols-4 gap-6 asset_more p-6">
        <!-- Header -->
        <div class="col-span-4">
          <!-- outcome -->
          <BaseTabs
            v-if="modulee === 'outcome'"
            justify="end"
            type="box"
            model-value="info"
            class="tabs"
            :tabs="[
              { label: $t('Info'), value: 'info' },
              // { label: $t('Parts'), value: 'parts' },
              { label: $t('Documents'), value: 'documents' },
              { label: $t('Actions'), value: 'actions' },
            ]"
          >
            <template #tab="{ activeValue }">
              <p
                v-if="activeValue === 'info'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <OutcomeInfoModalForm
                  :key="item_id"
                  :row="item_id"
                  :editPartRow="transaction_parts"
                  :item="item_data"
                  :title="$t('Debt')"
                  module="Outcome"
                  code="Transaction"
                  size="3xl"
                />
                <Parts
                  :delete="true"
                  :transaction_id="item_id"
                  :transaction_data="item_data"
                />
              </p>
              <!-- <p
                v-else-if="activeValue === 'parts'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
              </p> -->
              <p
                v-else-if="activeValue === 'documents'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <Documents
                  :transaction_id="item_id"
                  :transaction_data="item_data"
                  :handleUpload="handleUpload"
                  :uploadedFiles="uploadedFiles"
                />
              </p>
              <p
                v-else-if="activeValue === 'actions'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <Actions
                  :delete="true"
                  :transaction_id="item_id"
                  :transaction_data="item_data"
                />
              </p>
            </template>
          </BaseTabs>
          <!-- income -->
          <BaseTabs
            v-else-if="modulee === 'income'"
            justify="end"
            type="box"
            model-value="info"
            class="tabs"
            :tabs="[
              { label: $t('Info'), value: 'info' },
              // { label: $t('Parts'), value: 'parts' },
              { label: $t('Documents'), value: 'documents' },
              { label: $t('Actions'), value: 'actions' },
            ]"
          >
            <template #tab="{ activeValue }">
              <p
                v-if="activeValue === 'info'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <OutcomeInfoModalForm
                  :key="item_id"
                  :row="item_id"
                  :item="item_data"
                  :title="$t('Income')"
                  module="Income"
                  code="Transaction"
                  size="3xl"
                />
                <Parts
                  :delete="true"
                  :transaction_id="item_id"
                  :transaction_data="item_data"
                />
              </p>
              <!-- <p
                v-if="activeValue === 'parts'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              ></p> -->
              <p
                v-else-if="activeValue === 'documents'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <Documents
                  :transaction_id="item_id"
                  :transaction_data="item_data"
                  :handleUpload="handleUpload"
                  :uploadedFiles="uploadedFiles"
                />
              </p>
              <p
                v-else-if="activeValue === 'actions'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <Actions
                  :delete="true"
                  :transaction_id="item_id"
                  :transaction_data="item_data"
                />
              </p>
            </template>
          </BaseTabs>

          <!-- parts -->
          <BaseTabs
            v-else-if="modulee === 'parts'"
            justify="end"
            type="box"
            model-value="stock"
            class="tabs"
            :tabs="[
              { label: $t('Stock'), value: 'stock' },
              { label: $t('Bin Location'), value: 'bin_location' },
              { label: $t('Assets'), value: 'assets' },
              { label: $t('Work Order'), value: 'work_order' },
              { label: $t('Income'), value: 'income' },
              { label: $t('Debt'), value: 'debt' },
              { label: $t('Shift History'), value: 'shift' },
            ]"
          >
            <template #tab="{ activeValue }">
              <div class="max-w-4xl print-page fixed -mt-[128px] ml-[50px]">
                <div class="flex justify-between items-center mb-4">
                  <h1 class="text-xl font-bold">
                    Part:
                    <span> {{ item_data?.part_number }}</span>
                  </h1>
                </div>
              </div>
              <p
                v-if="activeValue === 'stock'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <StockParts :part="item_id" :item_data="item_data" />
              </p>
              <p
                v-else-if="activeValue === 'bin_location'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <BinLocation
                  :part="item_id"
                  :item_data="item_data"
                  :locationId="
                    item_data?.location_id ? item_data?.location_id : params.id
                  "
                />
              </p>
              <p
                v-else-if="activeValue === 'assets'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <AssetParts :part="item_id" :item_data="item_data" />
              </p>
              <p
                v-else-if="activeValue === 'work_order'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <WorkOrderParts :part="item_id" :item_data="item_data" />
              </p>
              <p
                v-else-if="activeValue === 'income'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <IncomeParts :part="item_id" :item_data="item_data" />
              </p>
              <p
                v-else-if="activeValue === 'debt'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <OutcomeParts :part="item_id" :item_data="item_data" />
              </p>

              <p
                v-else-if="activeValue === 'shift'"
                class="font-sans text-sm text-gray-500 dark:text-gray-400"
              >
                <ShiftHistoryParts :part="item_id" :item_data="item_data" />
              </p>
            </template>
          </BaseTabs>
        </div>
      </div>
    </div>
  </div>
</template>
