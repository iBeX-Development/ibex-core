<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
const props = defineProps({
  accept_info: {
    type: Object,
    default: null,
  },
})

const info = computed(() => {
  if (!props.accept_info) return null
  if (typeof props.accept_info === 'string') {
    try {
      return JSON.parse(props.accept_info)
    } catch {
      return null
    }
  }
  return props.accept_info
})

const formatDate = (dateStr: string) => {
  if (!dateStr) return '—'
  const d = new Date(dateStr)
  return d.toLocaleString()
}
</script>

<template>
  <div v-if="info" class="accept_info_wrapper">
    <div class="accept_info_card">
      <div class="accept_info_header">
        <Icon name="ph:check-circle-fill" class="accept_info_icon" />
        <span class="accept_info_title">{{ t('Accept Info') }}</span>
      </div>
      <div class="accept_info_grid">
        <div class="accept_info_row" v-if="info.date">
          <span class="accept_info_label">{{ t('Date') }}</span>
          <span class="accept_info_value">{{ formatDate(info.date) }}</span>
        </div>
        <div class="accept_info_row" v-if="info.user_name">
          <span class="accept_info_label">{{ t('User') }}</span>
          <span class="accept_info_value">{{ info.user_name }}</span>
        </div>
        <div class="accept_info_row" v-if="info.action_type">
          <span class="accept_info_label">{{ t('Action') }}</span>
          <span class="accept_info_value accept_info_badge">{{
            info.action_type
          }}</span>
        </div>
        <div class="accept_info_row" v-if="info.source">
          <span class="accept_info_label">{{ t('Source') }}</span>
          <span class="accept_info_value">{{ info.source }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.accept_info_wrapper {
  padding: 4px 0;
}
.accept_info_card {
  display: flex;
  flex-direction: column;
  gap: 6px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  border-radius: 8px;
  padding: 10px 14px;
}
.dark .accept_info_card {
  background: rgb(6 78 59 / 0.25);
  border-color: rgb(6 78 59 / 0.6);
}
.accept_info_header {
  display: flex;
  align-items: center;
  gap: 6px;
}
.accept_info_icon {
  color: #16a34a;
  width: 16px;
  height: 16px;
  flex-shrink: 0;
}
.accept_info_title {
  font-size: 12px;
  font-weight: 600;
  color: #15803d;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
.dark .accept_info_title {
  color: #4ade80;
}
.accept_info_grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 4px 16px;
}
.accept_info_row {
  display: flex;
  flex-direction: column;
  gap: 1px;
}
.accept_info_label {
  font-size: 10px;
  font-weight: 500;
  color: #6b7280;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}
.accept_info_value {
  font-size: 12px;
  color: #111827;
}
.dark .accept_info_value {
  color: #e5e7eb;
}
.accept_info_badge {
  display: inline-block;
  background: #dcfce7;
  color: #166534;
  border-radius: 4px;
  padding: 1px 6px;
  font-size: 11px;
  font-weight: 500;
}
.dark .accept_info_badge {
  background: rgb(22 101 52 / 0.4);
  color: #86efac;
}
</style>
