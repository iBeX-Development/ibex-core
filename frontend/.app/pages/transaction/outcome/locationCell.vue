<script setup>
const { params } = defineProps(['params'])

let colorClass = 'location-text'
let text = ''
let idx = ''
const fieldName = params.colDef.field // "priority" эсвэл "status"

if (fieldName == 'location.name') {
  colorClass = 'location-text'
  text = params.value
    .toLowerCase()
    .split(' ')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ')
} else if (fieldName == 'work_order') {
  colorClass = 'work-text'
  idx = params.value.wo_number
  text = params.value.name
}
</script>
<template>
  <div :class="`${colorClass} location-cell`">
    <div :class="`location-text`">
      {{ idx !== '' ? '#' + idx + ' ' : '' }}{{ text }}
    </div>
  </div>
</template>

<style>
.location-cell {
  border-radius: 24px;
  padding: 4px;
  line-height: 1.5;
  font-size: 13px;
  border: 1.5px solid rgba(91, 91, 91, 0.1);
  justify-content: center;
  align-items: center;
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  width: auto;
  max-width: 144px;
}
.location-cell:hover {
  background-color: #f2effd;
  border-color: #8363ee;
  color: #8363ee;
  cursor: pointer;
}
.location-text {
  text-align: start;
  text-overflow: ellipsis;
  margin-left: 7px;
}
.work-text {
  font-weight: 400;
}

.activeTag {
  background-color: #84ca8130;
  border: 1.5px solid rgb(70, 227, 114, 0.2);
}
.approvedTag {
  background-color: #37b6e730;
  border: 1.5px solid #47a8f86c;
}
.returnedTag {
  background-color: #caab7036;
  border: 1.5px solid rgba(82, 83, 83, 0.2);
}
.outOfStockTag {
  background-color: rgb(255, 0, 0, 0.05);
  color: rgb(234, 83, 83);
  border: 1.5px solid rgb(255, 0, 0, 0.3);
}

.circle {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 8px;
  margin-left: 6px;
}

.activeCircle {
  background-color: #6d9b7e;
}
.approvedCircle {
  background-color: #47a8f8;
}
.returnedCircle {
  background-color: #7b7c7c;
}

.outOfStockCircle {
  background-color: #ea5353;
}
.status-cell {
  border: none !important;
}
</style>
