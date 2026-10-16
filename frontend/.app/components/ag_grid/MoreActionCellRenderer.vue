<script setup>
import { useI18n } from 'vue-i18n'

const { params } = defineProps(['params'])
const { t } = useI18n({ useScope: 'global' })

const onMoreClick = () => {
  params.onMoreClick(params.node.data)
}
</script>

<template>
  <div class="flex h-full items-center justify-center">
    <BaseButtonAction color="muted" @click="onMoreClick">
      <span>{{ t('More') }}</span>
    </BaseButtonAction>
  </div>
</template>
