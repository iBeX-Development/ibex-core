<script setup lang="ts">
const { params } = defineProps(['params'])
const { value, data } = params
const progress_value = computed(() => {
  if (typeof data?.progress_value === 'number') {
    return data.progress_value
  }
  return 0
})
</script>

<template>
  <div class="progress">
    <div class="flex items-center">
      <div class="relative">
        <BaseProgressCircle
          :value="progress_value"
          :thickness="1"
          :size="50"
          class="text-success-500"
        />
        <span
          class="absolute start-1/2 top-1/2 z-10 ms-0.5 -translate-x-1/2 -translate-y-1/2 font-sans text-[0.65rem] font-semibold rtl:me-0.5 rtl:ms-0 rtl:translate-x-1/2"
        >
          {{ progress_value }}%
        </span>
      </div>
    </div>
  </div>
</template>

<style>
.progress {
  height: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: start;
}

.image {
  max-width: 100%;
  max-height: 100px;
  background-color: rgba(201, 201, 201, 0.2);
  border-radius: 8px;
  /* margin: 8px; */
}

.image img {
  width: 37px;
  height: 37px;
}

.progress div:first-child {
  font-weight: 500;
}

.progress div {
  padding-bottom: 0;
  line-height: 1.5;
}

.progress img {
  border-radius: 8px;
}

.stockCell {
  background-color: var(--color-bg-secondary);
  color: var(--color-text-secondary);
  width: fit-content;
  padding-top: 2px;
  margin-top: 4px;
  padding-right: 4px;
  padding-left: 4px;
  font-size: 12px;
}
</style>
