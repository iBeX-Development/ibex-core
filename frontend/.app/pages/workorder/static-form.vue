<template>
  <div class="relative">
    <!-- Centered with reduced padding on top -->
    <div class="grid grid-cols-12 gap-6">
      <div class="col-span-6">
        <BaseCard
          color="default"
          rounded="md"
          class="p-10 nui-bg-white shadow-lg"
        >
          <FormKit
            type="form"
            :actions="true"
            :submit-label="$t('Save')"
            @submit="submitHandler"
            :submit-attrs="{
              inputClass:
                'text-sm px-10 mt-5 py-3 rounded bg-primary-500 dark:bg-primary-500 text-white hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400',
              ignore: false,
            }"
          >
            <div class="grid grid-cols-2 gap-4 mb-5">
              <!-- Left column for Name and Description fields -->
              <div>
                <FormKit
                  name="name"
                  type="text"
                  :label="$t('Name')"
                  :validation="'required'"
                  class="text-lg"
                />
                <FormKit
                  name="description"
                  type="textarea"
                  :label="$t('Description')"
                  :validation="'required'"
                  rows="4"
                  class="text-lg mt-4"
                />
              </div>

              <!-- Right column for Photo Upload -->
              <div
                class="h-60 border-2 border-dashed rounded-lg flex items-center justify-center"
              >
                <FileUpload :plus="false" />
              </div>
            </div>

            <!-- 2x2 Layout for Status, Parent, Manufacturer, Department -->
            <div class="grid grid-cols-2 gap-4 mb-5">
              <FormKit
                name="status"
                type="text"
                :label="$t('Status')"
                class="text-lg"
              />
              <FormKit
                name="parent"
                type="text"
                :label="$t('Parent')"
                class="text-lg"
              />
              <FormKit
                name="manufacturer"
                type="text"
                :label="$t('Manufacturer')"
                class="text-lg"
              />
              <FormKit
                name="department"
                type="text"
                :label="$t('Department')"
                class="text-lg"
              />
            </div>

            <!-- Asset Information Section -->
            <div class="grid grid-cols-2 gap-4 mb-5">
              <FormKit
                name="asset_type"
                type="text"
                :label="$t('Asset Type')"
                class="text-lg"
              />
              <FormKit
                name="reading_type"
                type="text"
                :label="$t('Reading Type')"
                class="text-lg"
              />
              <FormKit
                name="module_number"
                type="text"
                :label="$t('Module Number')"
                class="text-lg"
              />
              <FormKit
                name="serial_number"
                type="text"
                :label="$t('Serial Number')"
                class="text-lg"
              />
              <FormKit
                name="barcode"
                type="text"
                :label="$t('Barcode')"
                class="text-lg"
              />
              <FormKit
                name="available_hour"
                type="text"
                :label="$t('Available Hour')"
                class="text-lg"
              />
            </div>
            n
            <!-- Warranty and Inspection Dates Section -->
            <div class="grid grid-cols-2 gap-4 mb-5">
              <FormKit
                name="warranty_start_date"
                type="date"
                :label="$t('Warranty Start Date')"
                class="text-lg"
              />
              <FormKit
                name="warranty_finish_date"
                type="date"
                :label="$t('Warranty Finish Date')"
                class="text-lg"
              />
              <FormKit
                name="inspection_done_date"
                type="date"
                :label="$t('Inspection Done Date')"
                class="text-lg"
              />
              <FormKit
                name="inspection_next_due_date"
                type="date"
                :label="$t('Inspection Next Due Date')"
                class="text-lg"
              />
            </div>

            <!-- Asset Supplier and Purchase Cost Section -->
            <div class="grid grid-cols-2 gap-4 mb-5">
              <FormKit
                name="asset_code"
                type="text"
                :label="$t('Asset Code')"
                class="text-lg"
              />
              <FormKit
                name="purchase_cost"
                type="text"
                :label="$t('Purchase Cost')"
                class="text-lg"
              />
            </div>

            <!-- Safety Notes Section -->
            <div class="mb-5">
              <FormKit
                name="safety_notes"
                type="textarea"
                :label="$t('Safety Notes')"
                rows="3"
                class="text-lg"
              />
            </div>
          </FormKit>
        </BaseCard>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { Calendar } from 'v-calendar'

import 'v-calendar/dist/style.css'
import '~/assets/css/vcalendar.css'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
definePageMeta({
  middleware: ['auth'],
  title: 'New asset',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})
</script>

<style>
/* Additional styling if required */
</style>
