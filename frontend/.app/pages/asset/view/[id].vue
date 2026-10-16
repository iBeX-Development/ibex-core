<script setup lang="ts">
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { ref } from 'vue'
import NormalForm from '~/components/form/NormalForm.vue'

const { params } = useRoute()

definePageMeta({
  middleware: ['auth'],
  title: 'Preview asset',
  showback: true,
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
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseTabs
          justify="end"
          type="box"
          model-value="info"
          :tabs="[
            { label: $t('Info'), value: 'info' },
            { label: $t('PMs'), value: 'pm' },
            { label: $t('WOs'), value: 'wo' },
            { label: $t('Parts'), value: 'parts' },
            { label: $t('Vendors'), value: 'vendors' },
            { label: $t('Reports'), value: 'reports' },
            { label: $t('Children'), value: 'children' },
          ]"
        >
          <template #tab="{ activeValue }">
            <p
              v-if="activeValue === 'info'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <NormalForm
                title="Assets"
                code="Assets"
                schema_column="three-column-form"
                fields="status,name,asset_type,manufacturer,department,description,model_number,safety_notes,serial_number,barcode,available_hour,warranty_start_date,warranty_finish_date,inspection_done_date,inspection_next_due_date,purchase_code,location,asset_code"
                :row="parseInt(params.id)"
              />
            </p>

            <!-- <p
              v-else-if="activeValue === 'pm'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderPM
                :status="status"
                :asset="params.id"
                work_order_type="pm"
              />
            </p> -->
            <p
              v-else-if="activeValue === 'pm'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderList
                :status="status"
                class="tabGridBody"
                type="all"
                :asset="params.id"
                work_order_type="pm"
                call_type="pm"
              />
            </p>
            <p
              v-else-if="activeValue === 'wo'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <WorkorderList
                :status="status"
                type="all"
                :asset="params.id"
                work_order_type="wo"
              />
            </p>
            <p
              v-else-if="activeValue === 'parts'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <AssetsParts />
            </p>
            <p
              v-else-if="activeValue === 'vendors'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              Vendors
            </p>
            <p
              v-else-if="activeValue === 'reports'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <AssetsReports />
            </p>
            <p
              v-else-if="activeValue === 'children'"
              class="font-sans text-sm text-gray-500 dark:text-gray-400"
            >
              <AssetsTree :parent="params.id" :is_more_click="false" />
            </p>
          </template>
        </BaseTabs>
      </div>
    </div>
  </div>
</template>
