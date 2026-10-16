<script setup lang="ts">
import WorkorderitemRequest from './Request.vue'
const { createItems } = useDirectusItems()

const props = defineProps({
  request_work: Array,
  location: String,
  type: String,
  tab: String,
})
</script>

<template>
  <div class="pt-1 task_container">
    <div
      v-for="(el, iindex) in props.request_work"
      :key="el.id"
      :taskId="el.id"
      v-show="el.active == 1"
      class="row task-item"
    >
      <BaseCard shape="curved" class="p-1 dragArea task">
        <div class="flex w-full items-center gap-2">
          <div>
            <BaseHeading
              tag="h3"
              size="sm"
              weight="medium"
              class="text-muted-800 dark:text-muted-100"
            >
              <WorkorderitemRequest
                v-if="el.template_type == null"
                :value="{
                  isChecked: el.value == 1,
                  requestInfo: el.request_info,
                  task: el.id,
                }"
              />
            </BaseHeading>
          </div>
        </div>
      </BaseCard>
    </div>
  </div>
</template>

<style>
.task_container .row.hide,
.task_container .row.hide .pl-5 {
  display: none;
}
.task_container .row:hover {
  cursor: pointer;
}
.task_container .row .task:hover {
  border-color: #938e8e;
}

.highlight {
  background-color: #93cfb9; /* Green highlight for valid drop zone */
}
</style>
