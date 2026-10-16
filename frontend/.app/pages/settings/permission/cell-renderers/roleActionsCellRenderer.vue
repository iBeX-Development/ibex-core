<script setup>
import { ref } from 'vue'

const { params } = defineProps(['params'])
const isModalVisible = ref(false) // Tracks modal visibility

const openModal = () => {
  isModalVisible.value = true // Show modal
}

const closeModal = () => {
  isModalVisible.value = false // Hide modal
}

const onEditClick = () => {
  const rowData = params.node.data
  // console.log('onEditClick:', rowData)
  params.onEditLocation(rowData, 'location')
}
</script>

<template #start>
  <BaseButton
    size="sm"
    rounded="md"
    variant="ghost"
    class="w-[60px]"
    @click="onEditClick"
  >
    {{ $t('View') }}
  </BaseButton>
</template>

<style>
.buttonCell {
  display: flex;
  gap: 8px;
  flex-direction: row-reverse;
}

.buttonCell button {
  appearance: none;
  display: inline-block;
  padding: 2px;
  width: 62px;
  height: 34px;
  white-space: nowrap;
  border-radius: 6px;
  border: 1px solid var(--ag-border-color);
  cursor: pointer;
  font-size: 13px;
}
.buttonCell .text_cell {
  height: 30px;
  margin-top: -10px;
}
.removeButton {
  display: flex !important;
  justify-content: center;
  align-items: center;
  height: 40px;
  width: 40px;
}

.removeButton img {
  width: 20px;
}

.buttonStopSelling {
  height: 40px;
  line-height: 1.8;
}
</style>
