<template>
  <TairoModal
    :open="props.open"
    size="sm"
    @close="
      () => {
        props.close()
        isRemoveAccepted = false
      }
    "
  >
    <template #header>
      <!-- Header -->
      <div class="flex w-full items-center justify-between">
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
    <div class="">
      <div class="mx-auto w-full max-w-xs text-center">
        <div
          class="relative mx-auto mb-4 flex w-24"
          :style="{ color: '#8363ee' }"
        >
          <Icon name="ph:check-circle-fill" class="h-[80px] w-[80px]" />
        </div>

        <p
          class="font-alt text-muted-500 dark:text-muted-400 text-sm leading-5"
        >
          {{ $t(props.text) }}
        </p>
      </div>
    </div>

    <template #footer>
      <!-- Footer -->
      <div class="">
        <div class="flex gap-x-2">
          <BaseButton
            @click="
              () => {
                props.close()
                isRemoveAccepted = false
              }
            "
            >{{ $t('No') }}</BaseButton
          >
          <BaseButton
            color="primary"
            flavor="solid"
            @click="
              () => {
                isRemoveAccepted = true
                do_make()
              }
            "
            >{{ $t('Yes') }}</BaseButton
          >
        </div>
      </div>
    </template>
  </TairoModal>
</template>
<script setup lang="ts">
const { createItems, updateItem, deleteItems } = useDirectusItems()
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()

const isRemoveAccepted = ref(false)
const props = withDefaults(
  defineProps<{
    itemsValue?: Object | number
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
  }>(),
  {
    itemsValue: () => ({}), // Object-д функцээр хоосон объект буцаах
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
