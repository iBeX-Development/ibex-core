<script setup lang="ts">
// import { Icon } from '#components'
// import { Icon } from '@iconify/vue'
import { computed } from 'vue'

const { params } = defineProps<{ params: any }>()

const isActive = computed(() => Number(params.data?.status) === 1)
const isDefaultCompany = computed(() => String(params.data?.id) === '1')
</script>

<template>
  <div
    v-if="!params.node.rowPinned"
    class="flex h-full items-center justify-center gap-2 company-actions-cell"
  >
    <button
      type="button"
      title="Edit"
      class="inline-flex size-7 items-center justify-center rounded text-muted-600 hover:bg-muted-100 hover:text-primary-600 dark:text-muted-300 dark:hover:bg-muted-800"
      @click.stop="params.context.openEdit(params.data)"
    >
      <Suspense>
        <Icon name="lucide:pencil" class="size-4" />
      </Suspense>
    </button>

    <button
      type="button"
      :disabled="isDefaultCompany"
      :title="isActive ? 'Deactivate' : 'Activate'"
      class="inline-flex size-7 items-center justify-center rounded text-muted-600 hover:bg-muted-100 disabled:cursor-not-allowed disabled:opacity-40 dark:text-muted-300 dark:hover:bg-muted-800"
      @click.stop="params.context.toggleStatus(params.data)"
    >
      <Suspense>
        <Icon
          :name="isActive ? 'lucide:toggle-right' : 'lucide:toggle-left'"
          :class="['size-4', isActive ? 'text-success-500' : 'text-muted-400']"
        />
      </Suspense>
    </button>

    <button
      type="button"
      :disabled="isDefaultCompany"
      title="Delete"
      class="inline-flex size-7 items-center justify-center rounded text-danger-500 hover:bg-danger-50 disabled:cursor-not-allowed disabled:opacity-40 dark:hover:bg-danger-950/30"
      @click.stop="params.context.openDelete(params.data)"
    >
      <Suspense>
        <Icon name="lucide:trash-2" class="size-4 text-danger-500" />
      </Suspense>
    </button>
  </div>
</template>
