<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const props = defineProps({
  title: String,
  icon: String,
  icon_class: String,
  cost: String,
  percentage: {
    type: Number,
    default: 0,
  },
  comparePercentage: {
    type: Number,
    default: 0,
  },
  symbol: String,
})
</script>

<template>
  <BaseCard class="flex h-full min-h-[124px] flex-col justify-between p-4">
    <div class="mb-1 flex items-center justify-between">
      <BaseHeading
        as="h5"
        size="sm"
        weight="medium"
        lead="tight"
        class="text-muted-500 dark:text-muted-400"
      >
        <span>{{ props.title }}</span>
      </BaseHeading>
      <BaseIconBox
        size="xs"
        :class="props.icon_class"
        rounded="full"
        color="none"
      >
        <Icon :name="props.icon" class="size-5" />
      </BaseIconBox>
    </div>
    <div class="flex items-center gap-2">
      <BaseHeading
        as="h4"
        size="xl"
        weight="bold"
        lead="tight"
        class="text-success-500 dark:text-white"
      >
        <span>{{ props.percentage }} {{ props.symbol }}</span>
      </BaseHeading>
      <span class="text-muted-500">{{ t('vs') }}</span>
      <BaseHeading
        as="h4"
        size="xl"
        weight="bold"
        lead="tight"
        class="text-danger-500 dark:text-white"
      >
        <span>{{ props.comparePercentage }} {{ props.symbol }}</span>
      </BaseHeading>
    </div>
  </BaseCard>
</template>
