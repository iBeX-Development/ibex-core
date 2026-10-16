<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import '~/assets/css/vcalendar.css'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'PM templates',
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

const router = useRouter()
const schema = ref([])
const { getItemById, createItems, updateItem, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const submitHandler = async (values) => {
  console.log(values)
  await createItems({
    collection: 'Template',
    items: [
      {
        status: 'published',
        name: values.name,
        company_id: myCompanyId,
      },
    ],
  }).then(() => {
    router.push('/settings/task/template')
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
        </FormKit>
      </div>
    </div>
  </div>
</template>
