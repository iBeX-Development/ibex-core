<template>
  <!-- New & Edit modal -->
  <TairoModal
    :key="props.key"
    :open="props.open"
    :size="props.size"
    @close="close"
  >
    <template #header>
      <!-- Header -->
      <div class="flex w-full items-center justify-between p-2 md:p-2">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white pl-8"
        >
          {{ t(title) }}
        </h3>
        <BaseButtonClose @click="close" />
      </div>
    </template>

    <!-- Body -->
    <div class="mx-auto w-full px-10">
      <div class="double">
        <FileUpload :result="uploadedFiles" />
        <BaseButton
          class="mt-10 mb-10"
          variant="solid"
          color="primary"
          @click="handleUploadedFile"
        >
          {{ t('Create document') }}</BaseButton
        >
      </div>
    </div>
  </TairoModal>
</template>

<script setup>
import { FormKitSchema } from '@formkit/vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

import { ref } from 'vue'
import TaskCheckbox from '~/components/global/TaskCheckbox.vue'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()
const uploadedFiles = ref([])

const { createItems, updateItem, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()

const props = defineProps({
  open: Boolean,
  title: String,
  collection: String,
  code: String,
  row: Number,
  size: String,
  close: Function,
  refresh: Function,
  work_order_id: Number,
})

// console.log(props)

onMounted(() => {
  console.log('Props', props)
})

const handleUploadedFile = async () => {
  console.log(uploadedFiles.value)
  console.log(props.work_order_id)
  if (uploadedFiles.value) {
    const items = uploadedFiles.value.map((uploadedFile) => {
      return {
        status: '1',
        work_order: props.work_order_id,
        file: uploadedFile.id,
        company_id: myCompanyId,
      }
    })
    console.log(items)

    //"Work_order_files"
    await createItems({ collection: props.collection, items: items }).then(
      () => {
        if (props.refresh) {
          props.refresh()
        }
      },
    )
  }
  if (props.close) {
    props.close()
    uploadedFiles.value = []
  }
}
</script>
<style>
.two-column-form {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-column-gap: 20px; /* Adjust as needed */
}
.three-column-form {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-column-gap: 20px; /* Adjust as needed */
}
.four-column-form {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-column-gap: 20px; /* Adjust as needed */
}

.v-overlay {
  z-index: 10001 !important;
}
</style>
