<template>
  <TairoModal
    :open="props.open"
    size="sm"
    @close="
      () => {
        close()
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
              close()
              isRemoveAccepted = false
            }
          "
        />
      </div>
    </template>

    <!-- Body -->
    <div class="">
      <div class="mx-auto w-full max-w-xs text-center">
        <div class="relative mx-auto mb-4 flex h-24 w-24">
          <Icon name="mdi:alert" class="h-[80px] w-[80px]" />
        </div>

        <p
          class="font-alt text-muted-500 dark:text-muted-400 text-sm leading-5"
        >
          {{
            $t(
              'Do you really want to delete this record. This process cannot be undone',
            )
          }}?
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
                close()
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
                do_remove()
              }
            "
            >{{ $t('Yes') }}</BaseButton
          >
        </div>
      </div>
    </template>
  </TairoModal>
</template>
<script setup>
const { createItems, updateItem, deleteItems } = useDirectusItems()
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()

const isRemoveAccepted = ref(false)
const props = defineProps({
  open: Boolean,
  code: String,
  row: Number,
  close: Function,
  refresh: Function,
  setItem: Function,
  clear: Function,
})

const row = computed({
  get: () => {
    return props.row
  },
  set: (value) => {
    console.log(value)
    this.$emit('props.row', value)
  },
})

const do_remove = async () => {
  if (isRemoveAccepted.value) {
    const data = {
      collection: props.code,
      id: props.row,
      item: {
        active: '0',
      },
    }
    toaster.show({
      title: t('Success'),
      message: t(`Record has been deleted`),
      color: 'success',
      icon: 'ph:check',
      closable: true,
    })
    await updateItem(data)
    isRemoveAccepted.value = false
    props.close()
    if (props.refresh) props.refresh()
    if (props.setItem) props.setItem(props.row, 'delete')
    if (props.clear) props.clear()
  }
}
</script>
