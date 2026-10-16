<script setup lang="ts">
const { params } = defineProps(['params'])
const { value, valueFormatted } = params
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
import {
  action_status,
  priorities,
  statuses,
} from '~/components/workorder/WorkOrderConstants'

// console.log('__original', value)

const fieldName = params.colDef.field // "priority" эсвэл "status"
let tag = ''
let colorClass = ''
let text = ''
let color = ''
let icon = ''

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

if (fieldName == 'status') {
  tag = 'statusTag'
  const status = statuses.find((s) => s.value == value)
  text = status ? status.text : value
  colorClass = status ? getStatusClass(status.value) : ''
} else if (fieldName == 'priority') {
  tag = 'wotag'

  const priority = priorities.find(
    (p) => p?.__original == value || p.value == value,
  )

  // console.log('priority', priority)
  if (priority) {
    text = priority ? priority.text : value
    let val = priority?.__original ? priority?.__original : priority.value
    colorClass = priority ? getPriorityClass(val) : ''
  }
} else if (fieldName == 'action_status') {
  tag = 'action_status'

  const action = action_status.find(
    (p) => p?.__original == value || p.id == value,
  )

  if (action) {
    text = action.name
    colorClass = action.name
    color = action.color
    icon = action.icon
  }
} else if (fieldName == 'created_type') {
  tag = 'created_type statusTag'

  const created_type = [
    {
      id: 1,
      name: 'request',
      clss: 'request',
      icon: 'mdi:plus-circle-outline',
      color: '#3498db', // Blue
      by_users: true,
    },
    {
      id: 2,
      name: 'open',
      clss: 'open',
      icon: 'solar:recive-square-line-duotone',
      color: '#3d1aea', //
      by_users: true,
    },
    {
      id: 3,
      name: 'ins_generated',
      clss: 'ins_generated',
      icon: 'icon-park-outline:reject',
      color: '#f4ca0c', //
      by_users: false,
    },
    {
      id: 4,
      name: 'pm_generated',
      clss: 'pm_generated',
      icon: 'mdi:check-circle-outline',
      color: '#f4630c', // Green
      by_users: false,
    },
    {
      id: 5,
      name: 'pdm_generated',
      clss: 'pdm_generated',
      icon: 'mdi:account-arrow-right',
      color: '#811edf', // Yellow
      by_users: false,
    },
  ]

  const action = created_type.find((p) => p.name == value)

  if (action) {
    text = action.name
    colorClass = action.name + ' ' + (action.clss ? action.clss : '')
    color = action.color
    icon = action.icon
  }
}
</script>

<template>
  <div
    v-if="fieldName == 'action_status'"
    :class="`${tag} ${colorClass}`"
    :style="{
      color: color,
    }"
  >
    <div :class="`action_icon ${colorClass}Icon`">
      <Suspense>
        <Icon :name="icon" class="h-4 w-4" :style="{ color: color }"
      /></Suspense>
    </div>

    <div>{{ t(text) }}</div>
  </div>

  <div v-else :class="`${tag} ${colorClass}Tag`">
    <div
      v-if="fieldName == 'status'"
      :class="`wocircle ${colorClass}Circle`"
    ></div>
    <div>{{ t(text) }}</div>
  </div>
</template>

<style>
.wotag {
  border-radius: 16px;
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
  width: 90px;
  padding: 4px;
  line-height: 1.5;
  font-size: 10px;
  border: 1.5px solid rgba(91, 91, 91, 0.1);
  display: flex;
  justify-content: start;
  align-items: center;
  white-space: nowrap;
}

/* priority  */
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

/* actions */

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
/* created_type */
.created_type {
  display: flex;
  width: 95px;
  justify-content: center;
  font-size: 12px;
  margin-left: 3px;
  margin-top: 6px;
}
.requestTag {
  background-color: #3498db;
  color: white;
}

.openTag {
  background-color: #3d1aea63;
  color: white;
}

.ins_generatedTag {
  background-color: #f4ca0c;
  color: white;
}

.pm_generatedTag {
  background-color: #f4630c;
  color: white;
}
.pdm_generatedTag {
  background-color: #811edf;
  color: white;
}
</style>
