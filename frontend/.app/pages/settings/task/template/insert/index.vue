<script setup lang="ts">
import { Calendar } from 'v-calendar'

import 'v-calendar/dist/style.css'
import '~/assets/css/vcalendar.css'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'PM templates',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()
const schema = ref([
  {
    $cmp: 'TaskCheckbox',
    name: 'custom',
    label: null,
    help: null,
    validation: null,
    children: [
      {
        $cmp: 'TaskCheckbox',
        name: 'custom',
        label: null,
        help: null,
        validation: null,
      },
    ],
  },
])

const handleAddTask = () => {
  schema.value.push({
    $cmp: 'TaskCheckbox',
    name: 'custom',
    label: null,
    help: null,
    validation: null,
  })
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <FormKit
          type="form"
          :actions="true"
          submit-label="Save"
          @submit="submitHandler"
          :submit-attrs="{
            inputClass:
              'text-sm px-10 mt-5 py-3 is-button rounded bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
            ignore: false,
          }"
        >
          <FormKit
            type="text"
            name="name"
            :label="$t('Name')"
            :help="$t('Template name')"
            validation="required"
          />
          <label class="nui-label">{{ $t('Task list') }}</label>
          <hr />

          <FormKitSchema :schema="schema" class="mb-10" />
          <BaseButton class="mt-3" @click="handleAddTask">{{
            $t('Add task')
          }}</BaseButton>
        </FormKit>
      </div>
    </div>
  </div>
</template>
