<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Budgets',
})
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton class="left cursor-pointer" :to="`/budgets/new`">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('New Budget') }}</span>
        </BaseButton>
      </div>

      <!-- GridBody -->
      <div class="col-span-12 GridBody">
        <BudgetList />
      </div>
    </div>
  </div>
</template>
