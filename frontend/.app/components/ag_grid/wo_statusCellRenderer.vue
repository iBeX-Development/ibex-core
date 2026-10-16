<script setup>
const { params } = defineProps(['params'])
const { value, valueFormatted } = params
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const fieldName = params.colDef.field // "priority" эсвэл "status"
let tag = ''
let colorClass = ''
let text = ''
let circleColor = ''

// Status өнгө
const getStatusClass = (status) => {
  switch (status) {
    case 1:
      return 'Open'
    case 2:
      return 'In_progress'
    case 3:
      return 'Completed'
    case 4:
      return 'Closed'
    default:
      return ''
  }
}

if (fieldName == 'wo_status') {
  tag = 'woStatus '
  text = params.value.status_text
  colorClass = params.value.status_color
  circleColor = params.value.circle_color
}
</script>

<template>
  <div
    :class="`${tag} ${colorClass}Tag`"
    :style="{
      backgroundColor: params.value.code_color.bg_color,
      color: params.value.code_color.text_color,
    }"
  >
    <div
      :class="`wocircle ${colorClass}Circle`"
      :style="{
        backgroundColor: params.value.code_color.circle_color,
      }"
    ></div>
    <div>{{ t(text) }}</div>
  </div>
</template>

<style>
.woStatus {
  width: fit-content;
  padding: 4px 13px 4px 4px;
  border-radius: 100px;
  line-height: 1.5;
  font-size: 10px;
  border: 1.5px solid rgba(91, 91, 91, 0.1);
  display: flex;
  justify-content: start;
  align-items: center;
  white-space: nowrap;
  min-height: 28px;
  max-height: 30px;
}

.wocircle {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 8px;
  margin-left: 6px;
}
.status-cell {
  border: none !important;
}
</style>
