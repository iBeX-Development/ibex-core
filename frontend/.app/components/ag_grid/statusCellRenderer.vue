<script setup>
const { params } = defineProps(['params'])
const { value, valueFormatted } = params
const width = params.width ?? null
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
</script>

<template>
  <div :class="`tag ${valueFormatted}Tag`" :style="width ? { width } : {}">
    <div :class="`circle ${valueFormatted}Circle`"></div>
    <span>{{ t(valueFormatted) }}</span>
  </div>
</template>

<style>
.tag {
  border-radius: 100px;
  padding-left: 4px;
  padding-right: 12px;
  line-height: 1.8;
  font-size: 10px;
  border: 1.5px solid rgba(91, 91, 91, 0.1);
  display: flex;
  justify-content: start;
  align-items: center;
  white-space: nowrap;
  padding: 3px;
  height: 30px;
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
.ActiveTag {
  background-color: #dcfce7;
  border: 1.5px solid rgba(22, 163, 74, 0.2);
  color: #16a34a;
}
.ActiveCircle {
  background-color: #16a34a;
}
.ApprovedTag {
  background-color: #dbeafe;
  border: 1.5px solid rgba(37, 99, 235, 0.2);
  color: #2563eb;
}
.ApprovedCircle {
  background-color: #2563eb;
}
.ClosedTag {
  background-color: #f3f4f6;
  border: 1.5px solid rgba(107, 114, 128, 0.2);
  color: #6b7280;
}
.ClosedCircle {
  background-color: #6b7280;
}
.InactiveTag {
  background-color: #fee2e2;
  border: 1.5px solid rgba(220, 38, 38, 0.2);
  color: #dc2626;
}
.InactiveCircle {
  background-color: #dc2626;
}
.AssignedTag {
  background-color: #fef9c3;
  border: 1.5px solid rgba(202, 138, 4, 0.2);
  color: #ca8a04;
}
.AssignedCircle {
  background-color: #ca8a04;
}
.DeclinedTag {
  background-color: #fce7f3;
  border: 1.5px solid rgba(219, 39, 119, 0.2);
  color: #db2777;
}
.DeclinedCircle {
  background-color: #db2777;
}
.DeletedTag {
  background-color: #f3f4f6;
  border: 1.5px solid rgba(107, 114, 128, 0.2);
  color: #6b7280;
}
.DeletedCircle {
  background-color: #6b7280;
}
.status-cell {
  border: none !important;
}
</style>
