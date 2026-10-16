<script setup lang="ts">
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'

import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import Actions from '~/components/bin/Actions.vue'
import BinParts from '~/components/bin/BinParts.vue'

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

const loading = ref(true)
const records = ref([])
const uploadedFiles = ref([])
const transaction_parts = ref([])

const item_id = currentProps?.value?.id || null
const title = currentProps?.value?.name || null
const item_data = currentProps?.value?.data || null
const refresh = currentProps?.value?.refresh || null
const modulee = currentProps?.value?.module || null
const type = currentProps?.value?.type || null

console.log('title', item_data)

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
        const wo_part = wo_items.data.filter(
          (wo) => wo.parts.id == item.part.id,
        )
        wo_qty = wo_part[0]?.quantity
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
          {{ title }}
          <!-- <span class="text-muted-400 font-normal">#{{ item_id }}</span> -->
        </div>
        <!-- <div class="flex items-center flex-shrink-0">
          <PriorityCell fieldName="action_status" :value="item_data.status" />
        </div> -->
      </div>
    </div>
    <div class="relative">
      <!-- Grid -->
      <div class="grid grid-cols-4 gap-6 asset_more p-6">
        <!-- Header -->
        <div class="col-span-4">
          <BaseTabs
            justify="end"
            type="box"
            model-value="parts"
            class="tabs"
            :tabs="[
              { label: $t('Parts'), value: 'parts' },
              { label: $t('Actions'), value: 'actions' },
            ]"
          >
            <template #tab="{ activeValue }">
              <div v-if="activeValue === 'parts'">
                <BinParts :item_data="{ id: item_id, ...(item_data || {}) }" />
              </div>
              <div v-else-if="activeValue === 'actions'">
                <Actions :item_data="{ id: item_id, ...(item_data || {}) }" />
              </div>
            </template>
          </BaseTabs>
        </div>
      </div>
    </div>
  </div>
</template>
