<script setup>
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const props = defineProps({
  status: [Object, Array],
  value: [Number, Object],
  class: String,
  fieldName: String,
})
const { getItems, updateItem, createItems } = useDirectusItems()

import {
  action_status,
  priorities,
  statuses,
} from '~/components/workorder/WorkOrderConstants'

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

// Priority өнгө
const getPriorityClass = (priority) => {
  switch (priority) {
    case 1:
      return 'Low'
    case 2:
      return 'High'
    case 3:
      return 'Medium'
    case 4:
      return 'Urgent'
    default:
      return ''
  }
}

const cellData = computed(() => {
  const fieldName = props.fieldName
  const value = props.value || 0

  // console.log('priorityCell received:', {
  //   fieldName,
  //   value,
  //   'props.status': props.status,
  //   'value type': typeof value,
  // })

  let tag = ''
  let colorClass = ''
  let text = ''
  let color = ''
  let icon = ''
  let wo_status_value = null

  if (fieldName == 'status') {
    tag = 'statusTag'
    const status = statuses.find((s) => s.value === value)
    // console.log('Status field:', { value, status, statuses })
    text = status ? status.text : value
    colorClass = status ? getStatusClass(status.value) : ''
  } else if (fieldName == 'priority') {
    tag = 'wotag'
    const priority = priorities.find(
      (p) => p?.__original === value || p.value === value,
    )
    text = priority ? priority.text : value
    let val = priority?.__original ? priority?.__original : priority.value
    colorClass = priority ? getPriorityClass(val) : ''
  } else if (fieldName == 'wo_status') {
    // console.log('wo_status processing:', {
    //   value,
    //   'typeof value': typeof value,
    //   'props.status': props.status,
    //   'Array.isArray(value)': Array.isArray(value),
    // })

    // Хэрэв value нь object бол шууд ашиглана
    if (typeof value === 'object' && value !== null) {
      wo_status_value = value
      tag = 'statusTag '
      text = wo_status_value.status_text || wo_status_value.name || ''
      colorClass = wo_status_value.status_color || ''
    } else {
      // Хэрэв value нь number (ID) бол props.status-аас хайна
      if (Array.isArray(props.status)) {
        wo_status_value = props.status.find((s) => s.status_value === value)
      } else if (props.status && typeof props.status === 'object') {
        wo_status_value =
          props.status.status_value === value ? props.status : null
      }
      tag = 'statusTag '
      if (wo_status_value) {
        text = wo_status_value.status_text
        colorClass = wo_status_value.status_color
      }
    }
  } else if (fieldName == 'action_status') {
    tag = 'action_status'
    const action = action_status.find(
      (p) => p.__original === value || p.id === value,
    )
    if (action) {
      text = action.name
      colorClass = action.name
      color = action.color
      icon = action.icon
    }
  }

  return {
    tag,
    colorClass,
    text,
    color,
    icon,
    wo_status: wo_status_value,
    fieldName,
  }
})
</script>

<template>
  <div
    v-if="
      cellData.fieldName == 'wo_status' &&
      cellData.wo_status &&
      cellData.wo_status.code_color
    "
    :class="`${cellData.tag} ${cellData.colorClass}Tag`"
    :style="{
      backgroundColor: cellData.wo_status?.code_color?.bg_color,
      color: cellData.wo_status?.code_color?.text_color,
    }"
  >
    <div
      :class="`wocircle ${cellData.colorClass}Circle`"
      :style="{
        backgroundColor: cellData.wo_status?.code_color?.circle_color,
      }"
    ></div>
    <div>{{ t(cellData.text) }}</div>
  </div>
  <div
    v-else-if="cellData.fieldName == 'action_status'"
    :class="`${cellData.tag} ${cellData.colorClass}`"
    :style="{
      color: cellData.color,
    }"
  >
    <div :class="`action_icon ${cellData.colorClass}Icon`">
      <Suspense>
        <Icon
          :name="cellData.icon"
          class="h-4 w-4"
          :style="{ color: cellData.color }"
      /></Suspense>
    </div>

    <div style="white-space: nowrap">{{ t(cellData.text) }}</div>
  </div>

  <div v-else :class="`${cellData.tag} ${cellData.colorClass}Tag`">
    <div
      v-if="cellData.fieldName == 'status'"
      :class="`wocircle ${cellData.colorClass}Circle`"
    ></div>
    <div>{{ t(cellData.text) }}</div>
  </div>
</template>

<style>
.wotag {
  border-radius: 17px;
  width: 66px;
  padding: 4px;
  line-height: 1.5;
  font-size: 10px;
  border: 1.5px solid rgba(91, 91, 91, 0.1);
  display: flex;
  justify-content: center;
  align-items: center;
  white-space: nowrap;
}
.statusTag {
  border-radius: 100px;
  width: auto;
  padding: 4px;
  line-height: 1.5;
  font-size: 10px;
  border: 1.5px solid rgba(91, 91, 91, 0.1);
  display: flex;
  justify-content: start;
  align-items: center;
  white-space: nowrap;
}

/* priority */
.LowTag {
  background-color: #e6e0fc;
  color: #8363ee;
}

.MediumTag {
  background-color: #efd548;
  color: #4b410e;
}

.HighTag {
  background-color: #f4af5e;
  color: #725028;
}

.UrgentTag {
  background-color: #f43f5e;
  color: white;
}

/* status */
.OpenTag {
  background-color: #84ca8130;
}

.In_progressTag {
  background-color: #0ea5e933;
}

.CompletedTag {
  background-color: #4caf50;
  color: white;
}

.ClosedTag {
  background-color: #0f87bc;
  color: white;
}

.CancelledTag {
  background-color: #d9dcde;
}

.wocircle {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 8px;
  margin-left: 6px;
}

.OpenCircle {
  background-color: #6d9b7e;
}
.In_progressCircle {
  background-color: #47a8f8;
}
.CompletedCircle {
  background-color: #ebefeb;
}
.ClosedCircle {
  background-color: #ebefeb;
}
.CancelledCircle {
  background-color: #7b7c7c;
}

/* action_status */

.action_status {
  display: flex;
  width: 95px;
  justify-content: start;
  font-size: 14px;
  margin-left: 3px;
}
.action_icon {
  margin-right: 2px;
  width: 15px;
}

.status-cell {
  border: none !important;
}
</style>
