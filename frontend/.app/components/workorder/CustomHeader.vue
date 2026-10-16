<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const props = defineProps(['params'])
// console.log('Header component params:', props.params)

onMounted(() => {
  console.log('Header Component Props:', props)
  console.log('Params object:', props.params)
  console.log('HeaderComponentParams:', props.params?.headerComponentParams)
})

const { t } = useI18n({ useScope: 'global' })
</script>

<template>
  <div class="customHeader">
    <div class="customHeaderMenuButton">
      <!-- Option 1: Use HTML entity for edit icon -->
      <span class="edit-icon">✎</span>

      <!-- Option 2: Use Unicode character -->
      <span class="edit-icon">&#9998;</span>

      <!-- Option 3: Simple CSS-based icon -->
      <span class="simple-edit-icon"></span>
    </div>
    <div class="customHeaderLabel">
      {{ params.displayName }}
      {{ params.headerComponentParams?.currencySymbol || '' }}
    </div>
  </div>
</template>
