<template>
  <!-- New & Edit modal -->
  <TairoModal
    :key="props.key"
    :open="props.open"
    :size="props.size"
    @close="close"
  >
    <template #header>
      <div class="flex w-full items-center justify-between px-5 py-4">
        <div class="flex items-center gap-2">
          <span class="doc-modal-icon-wrap">
            <Icon
              name="ph:upload-simple-duotone"
              class="size-4 text-primary-500"
            />
          </span>
          <h3
            class="font-heading text-muted-900 text-base font-semibold dark:text-white"
          >
            {{ t(title) }}
          </h3>
        </div>
        <BaseButtonClose @click="close" />
      </div>
    </template>

    <!-- Body -->
    <div class="px-6 pb-2 pt-1">
      <FileUpload :result="uploadedFiles" :multiple="1" />

      <div class="doc-modal-footer">
        <span class="doc-modal-hint">
          <Icon name="ph:info" class="size-3.5 me-1 opacity-60" />
          {{
            uploadedFiles.length
              ? `${uploadedFiles.length} file${
                  uploadedFiles.length > 1 ? 's' : ''
                } ready`
              : t('Drop or select files above')
          }}
        </span>
        <div class="flex gap-2">
          <BaseButton size="sm" @click="close">
            {{ t('Cancel') }}
          </BaseButton>
          <BaseButton
            size="sm"
            variant="solid"
            color="primary"
            :disabled="!uploadedFiles.length"
            @click="handleUploadedFile"
          >
            <Icon name="ph:check-bold" class="me-1 size-3" />
            {{ t('Save') }}
          </BaseButton>
        </div>
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
  transaction_id: Number,
  files: Object,
})

// console.log(props)

onMounted(() => {
  console.log('Props', props)
})

const handleUploadedFile = async () => {
  // console.log(uploadedFiles.value)
  if (uploadedFiles.value) {
    const items = uploadedFiles.value.map((uploadedFile) => {
      return {
        status: '1',
        transaction_id: props.transaction_id,
        file: uploadedFile,
      }
    })
    // console.log(items)
    props.handleUploadRead(items)
  }

  if (props.close) {
    props.close()
    uploadedFiles.value = []
  }
}
</script>
<style>
.doc-modal-icon-wrap {
  width: 28px;
  height: 28px;
  border-radius: 8px;
  background: #ede9fe;
  display: flex;
  align-items: center;
  justify-content: center;
}
.dark .doc-modal-icon-wrap {
  background: #3b1fa3;
}
.doc-modal-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 0 8px;
  border-top: 1px solid #e5e7eb;
  margin-top: 12px;
  gap: 8px;
}
.dark .doc-modal-footer {
  border-top-color: #27272a;
}
.doc-modal-hint {
  font-size: 12px;
  color: #9ca3af;
  display: flex;
  align-items: center;
}
.v-overlay {
  z-index: 10001 !important;
}
</style>
