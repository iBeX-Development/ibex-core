<script setup>
const { params } = defineProps(['params'])

const onEditMenuClick = () => {
  const rowData = params.node.data
  console.log('onEditMenuClick', rowData)
  params.onEditMenu(rowData, 'menu')
}

const onEditRoleClick = () => {
  const rowData = params.node.data
  console.log('onEditMenuClick', rowData)
  params.onEditRole(rowData, 'role')
}
</script>

<template>
  <div class="buttonCell">
    <button class="button-secondary" @click="onEditMenuClick">
      <div class="text_cell">{{ $t('Menus') }}</div>
    </button>
    <button class="button-secondary" @click="onEditRoleClick">
      <div class="text_cell">{{ $t('Roles') }}</div>
    </button>
  </div>
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
