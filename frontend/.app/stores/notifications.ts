// // import { defineStore } from 'pinia'
// // import { ref } from 'vue'

// // export const useNotificationStore = defineStore('notification', () => {
// //   const hasNewNotification = ref(false)

// //   function setNewNotification(val: boolean) {
// //     hasNewNotification.value = val
// //   }

// //   return {
// //     hasNewNotification,
// //     setNewNotification,
// //   }
// // })

// // stores/notifications.ts
// import { defineStore } from 'pinia'
// import { computed, ref } from 'vue'

// interface Notification {
//   id: string
//   title: string
//   message: string
//   type: 'info' | 'success' | 'warning' | 'error'
//   timestamp: Date
//   read: boolean
// }

// export const useNotificationStore = defineStore('notification', () => {
//   // State
//   const notifications = ref<Notification[]>([])
//   const hasNewNotification = ref(false)

//   // Getters (computed)
//   const unreadCount = computed(() => {
//     return notifications.value.filter((n) => !n.read).length
//   })

//   const unreadNotifications = computed(() => {
//     return notifications.value.filter((n) => !n.read)
//   })

//   // Actions
//   function setNewNotification(val: boolean) {
//     hasNewNotification.value = val
//   }

//   function addNotification(
//     notification: Omit<Notification, 'id' | 'timestamp' | 'read'>,
//   ) {
//     const newNotification: Notification = {
//       ...notification,
//       id: Date.now().toString(),
//       timestamp: new Date(),
//       read: false,
//     }

//     notifications.value.unshift(newNotification)
//     hasNewNotification.value = true
//   }

//   function markAsRead(id: string) {
//     const notification = notifications.value.find((n) => n.id === id)
//     if (notification) {
//       notification.read = true
//       updateNewNotificationStatus()
//     }
//   }

//   function markAllAsRead() {
//     notifications.value.forEach((n) => (n.read = true))
//     hasNewNotification.value = false
//   }

//   function removeNotification(id: string) {
//     const index = notifications.value.findIndex((n) => n.id === id)
//     if (index > -1) {
//       notifications.value.splice(index, 1)
//       updateNewNotificationStatus()
//     }
//   }

//   function clearAll() {
//     notifications.value = []
//     hasNewNotification.value = false
//   }

//   // Helper function
//   function updateNewNotificationStatus() {
//     hasNewNotification.value = unreadCount.value > 0
//   }

//   return {
//     // State
//     notifications,
//     hasNewNotification,

//     // Getters
//     unreadCount,
//     unreadNotifications,

//     // Actions
//     setNewNotification,
//     addNotification,
//     markAsRead,
//     markAllAsRead,
//     removeNotification,
//     clearAll,
//   }
// })
