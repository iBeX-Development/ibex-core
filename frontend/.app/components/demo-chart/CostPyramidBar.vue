<script setup lang="ts">
import { useI18n } from "vue-i18n"
const { t } = useI18n({ useScope: "global" });

const props = defineProps({
  lineBar: Object,
})


</script>

<template>
  <BaseCard class="flex h-full flex-col p-6">
    <div class="mb-10 flex items-center justify-between">
      <BaseHeading
        as="h3"
        size="md"
        weight="semibold"
        lead="tight"
        class="text-muted-800 dark:text-white"
      >
        <span>Cost by location</span>
      </BaseHeading>
    </div>
    <div class="mb-6">
      <AddonApexcharts v-bind="props.lineBar" />
    </div>
  </BaseCard>
</template>
