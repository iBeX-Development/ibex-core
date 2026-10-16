<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'
import { useMonitoringAlerts } from '~/composables/useMonitoringAlerts'

const {
  browserNotif,
  popupModal,
  closeBrowserPopup,
  closePopupModal,
  startLogPolling,
  stopLogPolling,
} = useMonitoringAlerts(ref(null))

onMounted(() => startLogPolling())
onUnmounted(() => stopLogPolling())
</script>

<template>
  <div>
    <!-- Browser notification toast (notify_browser) -->
    <Transition
      enter-active-class="transition duration-300 ease-out"
      enter-from-class="translate-x-8 opacity-0"
      enter-to-class="translate-x-0 opacity-100"
      leave-active-class="transition duration-200 ease-in"
      leave-from-class="translate-x-0 opacity-100"
      leave-to-class="translate-x-8 opacity-0"
    >
      <div
        v-if="browserNotif.show"
        class="fixed top-20 right-6 z-[9999] w-[360px] max-w-[calc(100vw-2rem)]"
      >
        <div
          class="relative overflow-hidden rounded-xl bg-white dark:bg-muted-900 shadow-2xl ring-1 ring-muted-200 dark:ring-muted-700"
        >
          <div class="flex items-start gap-3 p-4">
            <div
              class="flex-shrink-0 flex items-center justify-center w-10 h-10 rounded-full bg-danger-100 dark:bg-danger-900/30"
            >
              <Icon name="ph:warning-fill" class="h-6 w-6 text-danger-500" />
            </div>
            <div class="min-w-0 flex-1">
              <p class="text-sm font-semibold text-muted-800 dark:text-white pr-4">
                {{ browserNotif.title }}
              </p>
              <p class="mt-0.5 text-sm text-muted-500 dark:text-muted-300 break-words">
                {{ browserNotif.message }}
              </p>
              <div
                v-if="browserNotif.asset || browserNotif.location"
                class="mt-2 flex flex-wrap items-center gap-2"
              >
                <span
                  v-if="browserNotif.asset"
                  class="inline-flex items-center gap-1 rounded bg-muted-100 dark:bg-muted-800 px-1.5 py-0.5 text-xs text-muted-600 dark:text-muted-300"
                >
                  <Icon name="ph:wrench" class="h-3 w-3" />
                  {{ browserNotif.asset }}
                </span>
                <span
                  v-if="browserNotif.location"
                  class="inline-flex items-center gap-1 rounded bg-muted-100 dark:bg-muted-800 px-1.5 py-0.5 text-xs text-muted-600 dark:text-muted-300"
                >
                  <Icon name="ph:map-pin" class="h-3 w-3" />
                  {{ browserNotif.location }}
                </span>
              </div>
            </div>
            <button
              class="flex-shrink-0 text-muted-400 hover:text-muted-600 dark:hover:text-muted-200 transition-colors"
              @click="closeBrowserPopup"
            >
              <Icon name="ph:x" class="h-4 w-4" />
            </button>
          </div>
          <div class="h-1 w-full bg-muted-100 dark:bg-muted-800">
            <div class="browser-notif-bar h-full bg-danger-500" />
          </div>
        </div>
      </div>
    </Transition>

    <!-- Centered modal popup (notify_popup) -->
    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="popupModal.show"
        class="fixed inset-0 z-[9998] flex items-center justify-center p-4"
      >
        <div
          class="absolute inset-0 bg-muted-900/60 backdrop-blur-sm"
          @click="closePopupModal"
        />
        <div
          class="relative z-10 w-[420px] max-w-full overflow-hidden rounded-xl bg-white dark:bg-muted-900 shadow-2xl"
        >
          <div class="flex items-center justify-end px-3 pt-3">
            <button
              class="flex items-center justify-center w-7 h-7 rounded-md border border-muted-200 dark:border-muted-700 text-muted-400 hover:text-muted-600 dark:hover:text-muted-200 transition-colors"
              @click="closePopupModal"
            >
              <Icon name="ph:x" class="h-4 w-4" />
            </button>
          </div>
          <div class="px-6 pb-6 pt-2 text-center">
            <div
              class="mx-auto mb-4 flex items-center justify-center w-16 h-16 rounded-full bg-danger-100 dark:bg-danger-900/30"
            >
              <Icon name="ph:warning-fill" class="h-9 w-9 text-danger-500" />
            </div>
            <p class="text-base font-semibold text-muted-800 dark:text-white">
              {{ popupModal.title }}
            </p>
            <p class="mt-2 text-sm text-muted-500 dark:text-muted-300">
              {{ popupModal.message }}
            </p>
            <div
              v-if="popupModal.asset || popupModal.location"
              class="mt-3 flex flex-wrap items-center justify-center gap-2"
            >
              <span
                v-if="popupModal.asset"
                class="inline-flex items-center gap-1 rounded-full bg-muted-100 dark:bg-muted-800 px-2.5 py-1 text-xs font-medium text-muted-700 dark:text-muted-200"
              >
                <Icon name="ph:wrench" class="h-3.5 w-3.5 text-primary-500" />
                {{ popupModal.asset }}
              </span>
              <span
                v-if="popupModal.location"
                class="inline-flex items-center gap-1 rounded-full bg-muted-100 dark:bg-muted-800 px-2.5 py-1 text-xs font-medium text-muted-700 dark:text-muted-200"
              >
                <Icon name="ph:map-pin" class="h-3.5 w-3.5 text-primary-500" />
                {{ popupModal.location }}
              </span>
            </div>
            <div class="mt-6 flex justify-center">
              <BaseButton color="danger" @click="closePopupModal">
                Хаах
              </BaseButton>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.browser-notif-bar {
  animation: notif-shrink 6s linear forwards;
}
@keyframes notif-shrink {
  from {
    width: 100%;
  }
  to {
    width: 0%;
  }
}
</style>
