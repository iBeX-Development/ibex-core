<script setup>

const { params } = defineProps(['params'])

const onEditClick = () => {
  const rowData = params.node.data
  console.log('onEditClick')
  params.onEdit(rowData)
}

const onDeleteClick = () => {
  const rowData = params.node.data
  console.log('onDeleteClick')
  params.onDelete(rowData)
}
</script>

<template>
  <div class="buttonCell">
    <BaseButton @click="onEditClick">Edit</BaseButton>
    <BaseButton @click="onDeleteClick">Delete</BaseButton>
  </div>
</template>

