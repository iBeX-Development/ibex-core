<script setup>
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const { params } = useRoute()
const { getItemById, createItems, updateItem, deleteItems } = useDirectusItems()
const props = defineProps(['parent', 'refresh', 'addtask'])
const handleAddTask = async () => {
  if (props.addtask) {
    props.addtask()
  }
}
const handleRemoveTask = async () => {
  deleteItems({
    collection: 'Template_header',
    items: {
      query: {
        filter: {
          id: props.parent,
        },
      },
    },
  }).then(() => {
    if (props.refresh) props.refresh()
  })
}

const handleParentTask = async () => {
  const updateData = {
    collection: 'Template_header',
    id: props.parent,
    item: {
      parent: null,
    },
  }
  console.log(updateData)
  updateItem(updateData).then(() => {
    if (props.refresh) props.refresh()
  })
}
</script>
<template>
  <BaseDropdown
    flavor="context"
    label="Dropdown"
    orientation="end"
    condensed
    shape="curved"
    class="absolute mt-[-18px]"
  >
    <div class="">
      <BaseDropdownItem
        :title="t('Add')"
        :text="t('Add task record')"
        @click="handleAddTask"
      >
        <template #start>
          <Icon name="ph:pencil-line-fill" class="me-2 block h-5 w-5" />
        </template>
      </BaseDropdownItem>
      <BaseDropdownDivider />
      <BaseDropdownItem
        :title="t('Make root')"
        :text="t('Makes task to root')"
        @click="handleParentTask"
      >
        <template #start>
          <Icon name="ph:pencil-line-fill" class="me-2 block h-5 w-5" />
        </template>
      </BaseDropdownItem>
      <BaseDropdownDivider />
      <BaseDropdownItem
        :title="t('Remove')"
        :text="t('Remove from list')"
        @click="handleRemoveTask"
      >
        <template #start>
          <Icon name="ph:trash-duotone" class="me-2 block h-5 w-5" />
        </template>
      </BaseDropdownItem>
    </div>
  </BaseDropdown>
</template>
