<script setup lang="ts">
import { computed, isProxy, toRaw } from 'vue'
import { useI18n } from 'vue-i18n'

const runtimeConfig = useRuntimeConfig()

const { t } = useI18n({ useScope: 'global' })
const { params } = useRoute()
const { getItemById, createItems, updateItem, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const props = defineProps([
  'parent',
  'refresh',
  'item',
  'code',
  'template_type',
  'template_types',
  'children',
  'freeze',
  'name',
  'collection',
])
const itemCollection = computed(() => props.collection || 'Work_order_item')

const handleAddTask = async () => {
  await createItems({
    collection: itemCollection.value,
    items: [
      {
        status: 1,
        label: 'Label',
        workorder: props.code,
        parent: props.item,
        template_type: props.template_type?.id,
        name: 'Default text',
        created_type: 'user',
        company_id: myCompanyId,
      },
    ],
  }).then((addItem) => {
    let type = props.template_type
    if (isProxy(props.template_type)) {
      type = toRaw(props.template_type)
    }
    addItem[0].template_type = type

    if (props.refresh) props.refresh('add', addItem[0])
  })
}
const handleRemoveTask = async () => {
  const updateData = {
    collection: itemCollection.value,
    id: props.item,
    item: {
      active: 0,
    },
  }
  await updateItem(updateData)
  if (props.refresh) props.refresh('remove')
}

const handleParentTask = async () => {
  const updateData = {
    collection: itemCollection.value,
    id: props.item,
    item: {
      parent: null,
    },
  }
  await updateItem(updateData).then((item) => {
    let chosenType = props.template_types.find(
      (type) => type.id === item.template_type,
    )
    let type = chosenType
    if (isProxy(chosenType)) {
      type = toRaw(chosenType)
    }
    item.template_type = type
    if (props.refresh) props.refresh('root', item)
  })
}
</script>
<template>
  <BaseDropdown
    v-if="!props.freeze"
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
        :text="t('Add sub task')"
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
