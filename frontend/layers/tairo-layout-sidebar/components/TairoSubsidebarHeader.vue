<script setup lang="ts">
const { current, isOpen } = useSidebar()

const windowWidth = ref(
  typeof window !== 'undefined' ? window.innerWidth : 1920,
)

onMounted(() => {
  const onResize = () => {
    windowWidth.value = window.innerWidth
  }
  window.addEventListener('resize', onResize)
  onUnmounted(() => window.removeEventListener('resize', onResize))
})

const comName = ref(false)

onMounted(() => {
  try {
    const comInfo = JSON.parse(window.localStorage.getItem('comInfo') || '{}')
    if (comInfo?.name) {
      comName.value = comInfo.name
    }
  } catch (error) {
    console.error('Error parsing comInfo:', error)
  }
})

// 🔹 `computed()` ашиглаж, шууд тооцоолох
const previewName = computed(() => {
  return comName.value !== false ? comName.value : false
})
</script>

<template>
  <div class="companyName flex h-16 w-full items-center px-6">
    <div
      v-if="current"
      class="font-heading text-muted-700 text-lg font-light dark:text-white"
    >
      {{ previewName !== false ? previewName : current.title }}
    </div>
    <button
      v-if="windowWidth < 1200"
      type="button"
      class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 ms-auto flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300"
      @click="isOpen = false"
    >
      <Icon name="feather:chevron-left" class="h-6 w-6" />
    </button>
  </div>
</template>
