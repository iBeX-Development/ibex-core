<script setup lang="ts">
const { open } = usePanels()
const colorMode = useColorMode()
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'

const { locale } = useI18n({ useScope: 'global' })

const iconExtensions = ['svg', 'png', 'jpg', 'jpeg', 'webp']
const iconExtensionIndex = ref(0)
const toolbarIcon = computed(
  () =>
    `/img/icons/flags/${locale.value}.${
      iconExtensions[iconExtensionIndex.value]
    }`,
)

const tryNextIconExtension = () => {
  if (iconExtensionIndex.value < iconExtensions.length - 1) {
    iconExtensionIndex.value += 1
  }
}

watch(locale, () => {
  iconExtensionIndex.value = 0
})
</script>

<template>
  <button
    type="button"
    class="language flex h-9 w-9 items-center justify-center rounded-full border ring-1 ring-transparent transition-all duration-300 hover:ring-offset-4"
    :class="
      colorMode.value === 'dark'
        ? 'border-muted-700 bg-muted-800 hover:ring-muted-700 ring-offset-muted-900'
        : 'border-muted-200 bg-white hover:ring-muted-200'
    "
    @click="open('language')"
  >
    <img
      class="h-7 w-7 rounded-full"
      :src="toolbarIcon"
      alt="flag icon"
      @error="tryNextIconExtension"
    />
  </button>
</template>
