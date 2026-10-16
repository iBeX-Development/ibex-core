<template>
  <TairoModal
    :open="props.open"
    size="xl"
    @close="
      () => {
        props.close()
        isRemoveAccepted = false
      }
    "
  >
    <template #header>
      <!-- Header -->
      <div class="flex w-full items-center justify-between p-4">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
        >
          &nbsp;
        </h3>

        <BaseButtonClose
          @click="
            () => {
              props.close()
              isRemoveAccepted = false
            }
          "
        />
      </div>
    </template>

    <!-- Body -->
    <div class="px-5 md:p-6">
      <div class="mx-auto mt-[-35px] w-full max-w-xl text-center">
        <img
          :src="get_content_url(props.itemsValue)"
          alt="img"
          style="height: 500px; width: 100%; border-radius: 10px"
        />
      </div>
      <BaseButton
        class="mt-10 mb-10"
        variant="solid"
        color="primary"
        @click="deleteFile(props.itemsValue)"
      >
        {{ t('delete file') }}</BaseButton
      >
    </div>
  </TairoModal>
</template>
<script setup lang="ts">
const { createItems, updateItem, deleteItems } = useDirectusItems()
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const config = useRuntimeConfig()

const isRemoveAccepted = ref(false)
const props = withDefaults(
  defineProps<{
    itemsValue?: Object
    work_order?: Object
    open?: Boolean
    code?: String
    actionType?: String
    text?: String
    successfullText?: Boolean
    row?: Number
    do_make?: Function
    close?: Function
    refresh?: Function
    clear?: Function
    deleteFile?: Function
  }>(),
  {
    itemsValue: () => ({}), // Object-д функцээр хоосон объект буцаах
    work_order: () => ({}), // Object-д функцээр хоосон объект буцаах
    open: true, // Boolean-ийн анхны утга
    code: '', // String-ийн анхны утга
    actionType: '',
    text: '',
    successfullText: true,
    row: 0, // Number-ийн анхны утга
    do_make: () => {}, // Функцын анхны утга (хоосон функц)
    close: () => {},
    refresh: () => {},
    clear: () => {},
    deleteFile: () => {},
  },
)

const row = computed({
  get: () => {
    return props.row
  },
  set: (value) => {
    console.log(value)
    this.$emit('props.row', value)
  },
})

const get_content_url = (file) => {
  // console.log('file ->', file)

  if (file && file.type.includes('image')) {
    return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
  } else {
    return ``
  }
}
const deleteFile = (file) => {
  props.deleteFile(file, props.work_order)
}

const do_make = () => {
  if (isRemoveAccepted.value) {
    if (props.successfullText) {
      toaster.show({
        title: t('Success'),
        message: t(`Successfully`),
        color: 'success',
        icon: 'ph:check',
        closable: true,
      })
    }

    isRemoveAccepted.value = false
    props.do_make(props.itemsValue, props.actionType)
    props.close()
    if (props.refresh) props.refresh()
    if (props.clear) props.clear()
  }
}
</script>
