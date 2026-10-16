// composables/useNotifications.ts
import { ref } from 'vue'

const notifications = ref<any[]>([])
const hasNewNotification = ref(false)

export function useNotification() {
  const addNotification = (notification: any) => {
    notifications.value.unshift(notification)
    hasNewNotification.value = true
  }

  const clearNewNotification = () => {
    hasNewNotification.value = false
  }

  return {
    notifications,
    hasNewNotification,
    addNotification,
    clearNewNotification,
  }
}
