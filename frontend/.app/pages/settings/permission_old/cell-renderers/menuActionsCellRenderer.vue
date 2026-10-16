<script setup>
const { params } = defineProps(['params'])

const onEditMenuClick = () => {
  const rowData = params.node.data
  console.log('onEditMenuClick')
  params.onEditMenu(rowData, 'menu')
}

const onEditRoleClick = () => {
  const rowData = params.node.data
  console.log('onEditRoleClick')
  params.onEditRole(rowData, 'role')
}
</script>

<template>
  <div class="buttonCell">
    <button class="button-secondary" @click="onEditMenuClick">Menus</button>
    <button class="button-secondary" @click="onEditRoleClick">Roles</button>
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
  padding: 0.375em 1em 0.5em;
  white-space: nowrap;
  border-radius: 6px;
  box-shadow: 0 0 0 4px transparent, 0 1px 2px 0 #0c111d11;
  outline: none;
  background-color: var(--ag-background-color);
  color: var(--color-fg-primary, #101828);
  border: 1px solid var(--ag-border-color);
  cursor: pointer;
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
