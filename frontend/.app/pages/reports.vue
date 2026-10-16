<script setup lang="ts">
definePageMeta({
  title: 'Reports',
  preview: {
    title: 'Reports',
    description: 'For personal usage and reports',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-personal-2.png',
    srcDark: '/img/screens/dashboards-personal-2-dark.png',
    order: 2,
  },
})

import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useRouter } from 'vue-router'

import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
// import DynamicModalForm from '~/components/form/DynamicModalForm.vue'
const user = useDirectusUser()
const config = useRuntimeConfig()
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const { t } = useI18n({ useScope: 'global' })
const router = useRouter()

definePageMeta({
  title: 'Reports',
  preview: {
    title: 'Reports',
    description: 'For personal usage and reports',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-personal-2.png',
    srcDark: '/img/screens/dashboards-personal-2-dark.png',
    order: 2,
  },
})

const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)

// Modal new & edit form
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const key = ref(1)
const key_update_modal = ref(-2)

const reportUrl = ref('')

// Компани бүр Settings > Companies дээр өөрийн metrics.ibex.mn
// dashboard-ийн холбоосыг (report_url) тохируулж болно.

// Дотоод URL (https://metrics.ibex.mn/dashboard/2-work-order-report-dashboards?company_id=5&date=&tab=4-tab-1):
//  frame-ancestors 'none'   ← iframe-д блоклогдоно
// Public URL (https://metrics.ibex.mn/public/dashboard/3d456d07-1dab-4e5f-9c49-5baa7f702ebd):
//  frame-ancestors *       ← iframe-д зөвшөөрөгдөнө

// report_type:
//   'own'    — report_url бол тухайн компанийн ЖИНХЭНЭ, тусдаа dashboard-ийн
//               бүтэн URL тул шууд ашиглана
//   'shared' — report_url бол ОЛОН компани хуваалцдаг dashboard-ийн base URL
//               тул Metabase-ийн parameter-т зориулж ?company_id=<id>-г
//               автоматаар залгана (Metabase талд тэр parameter-ийг
//               company_id талбартай холбож, "locked" болгосон байх ёстой,
//               эс тэгвэл жинхэнэ шүүлт хийгдэхгүй)
const loadReportUrl = async () => {
  loading.value = true
  try {
    const result = await getItems({
      collection: 'Companies',
      params: {
        filter: { id: { _eq: myCompanyId } },
        fields: ['report_url', 'report_type'],
        limit: 1,
      },
    })
    const data = Array.isArray(result) ? result : result?.data ?? []
    const baseUrl = data[0]?.report_url || ''
    const reportType = data[0]?.report_type || 'own'

    if (baseUrl && reportType === 'shared') {
      const separator = baseUrl.includes('?') ? '&' : '?'
      // #hide_parameters=company_id — Metabase-ийн public dashboard дээрх
      // "Company ID" filter widget-ийг харагдахгүй/өөрчлөх боломжгүй болгоно
      // (утга нь query param-аас хэвээрээ авагдана, зөвхөн UI-д нуугдана)
      reportUrl.value = `${baseUrl}${separator}company_id=${myCompanyId}#hide_parameters=company_id`
    } else {
      reportUrl.value = baseUrl
    }
  } catch (error) {
    console.error('Unable to load report url:', error)
    reportUrl.value = ''
  } finally {
    loading.value = false
  }
}

onMounted(loadReportUrl)

// console.log('user', user)
</script>

<template>
  <div class="w-full px-4 md:px-6 lg:px-8 pb-20">
    <!--
      Metabase-ийн үнэгүй tier дээр "Powered by Metabase" footer-ийг URL
      параметрээр устгах боломжгүй (зөвхөн Pro/Enterprise upgrade-ээр).
      Тиймээс iframe-ийг контейнерээсээ arай ил өндөр гаргаж, доод хэсгийг
      нь overflow-hidden-ээр тайрч нуудаг (харагдацын trick, Metabase-ийн
      талд ямар ч өөрчлөлт хийхгүй).
    -->
    <div
      v-if="reportUrl"
      class="relative w-full h-[calc(100vh-100px)] overflow-hidden rounded-xl shadow"
    >
      <iframe
        :src="reportUrl"
        class="absolute left-0 top-0 w-full border-0"
        style="height: calc(100% + 60px)"
        allowfullscreen
      ></iframe>
    </div>
    <BasePlaceholderPage
      v-else-if="!loading"
      :title="t('No report configured')"
      subtitle=""
      class="min-h-96"
    />
  </div>
</template>
