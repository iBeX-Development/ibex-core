<script setup>
const { params } = defineProps(['params'])
const { value, valueFormatted } = params

const fieldName = params.colDef.field
let is_checked = false

if (fieldName == 'printed') {
  is_checked = params.data.printed
}
</script>

<template>
  <div class="BaseCheckbox">
    <BaseCheckbox
      v-model="is_checked"
      rounded="none"
      color="primary"
      :disabled="true"
    />
  </div>
</template>

<style>
.checkbox-cell {
  border: none !important;
}
</style>
