<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
import TaskTemplateChooseModalForm from '~/components/form/TaskTemplateChooseModalForm.vue'
const { t } = useI18n({ useScope: 'global' })
const { getItemById, createItems, updateItem, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

definePageMeta({
  middleware: ['auth'],
  title: 'Work Order Templates',
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

const template = ref({})
const { params } = useRoute()
const key = ref(1)
const timeout = ref(null)
const templateName = ref(template.name)
const isModalOpen = ref(false)
const selectedItem = ref(-1)
const { getItems } = useDirectusItems()
const template_types = ref([])
const toaster = useToaster()

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleTaskAdd = async () => {
  if (selectedItem.value !== -1) {
    await createItems<any>({
      collection: 'Template_header',
      items: [
        {
          status: 'published',
          label: 'Label',
          company_id: myCompanyId,
          template_type: selectedItem.value,
          template: params.id,
          help: 'Help',
          data_label: 'Default text',
        },
      ],
    }).then(() => {
      handleChangeKey()
    })
  } else {
    toaster.show({
      title: t('Failed'),
      message: t(`Record task failed please fill template type`) + '!',
      color: 'failed',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }
}

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
  console.log(isModalOpen.value)
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log(isModalOpen.value)
  console.log(selectedItem.value)
  handleTaskAdd()
}

const handleChangeRow = (row_value) => {
  selectedItem.value = row_value
}

const handleTemplateName = (event) => {
  if (timeout.value) {
    clearTimeout(timeout)
  }
  timeout.value = setTimeout(() => {
    const updateData = {
      collection: 'Template',
      id: params.id,
      item: {
        name: event.target.value,
      },
    }
    updateItem(updateData)
  }, 500)
}

onMounted(async () => {
  template.value = await getItemById<any>({
    collection: 'Template',
    id: params.id,
  })
})
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-rows-12">
      <!-- Header -->
      <div class="row-span-12">
        <BaseCard shape="rounded" class="p-4 md:p-8">
          <label
            >{{ t('Template name') }} :
            <input
              type="text"
              class="border rounded-md p-2 focus:outline-none focus:border-indigo-500 w-full"
              :value="template.name"
              @change="handleTemplateName"
              placeholder="Here task name"
              validation="required"
              style="width: 300px"
          /></label>
          <BaseButton
            class="float-right"
            variant="pastel"
            color="primary"
            @click="handleModalOpen"
            >{{ t('Add task') }}</BaseButton
          >
        </BaseCard>
      </div>
      <div class="row-span-12">
        <TemplateTree
          :code="$route.params.id"
          :key="key"
          :refresh="handleChangeKey"
        />
      </div>
      <TaskTemplateChooseModalForm
        :key="selectedItem"
        :open="isModalOpen"
        :close="handleModalClose"
        :row="selectedItem"
        :setRow="handleChangeRow"
        :refresh="handleChangeKey"
        size="lg"
        :title="$t('Choose template type')"
      />
    </div>
  </div>
</template>
