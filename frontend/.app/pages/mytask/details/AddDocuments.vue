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
      <div class="file_name mb-5">
        <BaseInput
          v-model="file_name"
          label="File name"
          rounded="none"
          type="string"
        />
      </div>
      <div class="double">
        <FileUpload :result="uploadedFiles" :multiple="1" />
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
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

import { ref } from 'vue'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()
const uploadedFiles = ref([])
const file_name = ref('')
const uploads = ref([])

const { createItems, updateItem, deleteItems } = useDirectusItems()
const toaster = useToaster()

const props = defineProps({
  open: Boolean,
  title: String,
  code: String,
  row: Number,
  size: String,
  close: Function,
  refresh: Function,
  handleUploadRead: Function,
  fileName: String,
  project_work: Number,
  files: Object,
})

// console.log(props)

onMounted(() => {
  // console.log('Props', props)
})

const handleUploadedFile = async () => {
  // console.log('handleUploadedFile')
  // console.log('name', file_name.value)

  if (!file_name.value || file_name.value == '') {
    toaster.show({
      title: t('Insert file name'),
      color: 'Error',
      icon: 'mdi:alert',
      closable: true,
      duration: 1000,
    })
    return
  }

  if (uploadedFiles.value) {
    const items = uploadedFiles.value.map((uploadedFile) => {
      return {
        status: '1',
        project_work: props.project_work,
        file: uploadedFile,
      }
    })
    // console.log(items)
    props.handleUploadRead(items, file_name.value)
  }

  if (props.close) {
    props.close()
    uploadedFiles.value = []
    file_name.value = ''
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
