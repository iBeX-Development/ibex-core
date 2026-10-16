import { getToken, onMessage } from 'firebase/messaging'
import { useToaster } from '../../layers/tairo/composables/toaster'
import { getConfiguredMessaging } from './useFirebase'
import { useNotification } from './useNotifications'

export const useFirebaseMessaging = async () => {
  const toaster = useToaster()
  const { addNotification } = useNotification()

  try {
    const config = useRuntimeConfig().public.firebase
    if (!config.apiKey || !config.projectId || !config.messagingSenderId || !config.appId || !config.vapidKey) {
      console.info('Firebase messaging disabled: required client configuration is missing')
      return
    }
    const messaging = getConfiguredMessaging()
    if (!messaging) return
    // The excluded deployment-specific worker must be provisioned explicitly.
    const serviceWorkerRegistration = await navigator.serviceWorker.getRegistration('/firebase-messaging-sw.js')
    const expectedWorkerUrl = new URL('/firebase-messaging-sw.js', window.location.origin).href
    if (!serviceWorkerRegistration || serviceWorkerRegistration.active?.scriptURL !== expectedWorkerUrl) {
      console.info('Firebase messaging disabled: approved service worker is not registered')
      return
    }
    const currentToken = await getToken(messaging, {
      vapidKey: config.vapidKey,
      serviceWorkerRegistration,
    })

    if (currentToken) {
      // Directus API руу хадгална
      const myId = window.localStorage.getItem('myId')

      const { getItems, deleteItems, updateItem, createItems } =
        useDirectusItems()

      const existingTokens = await getItems({
        collection: 'user_device_tokens',
        params: {
          filter: {
            user_id: { _eq: myId },
            token: { _eq: currentToken },
          },
        },
      })

      if (existingTokens.length === 0) {
        const device_tokens = await createItems({
          collection: 'user_device_tokens',
          items: {
            user_id: myId,
            token: currentToken,
            device_type: 'web',
          },
        })

        console.log('Notification token saved')
      }

      // Та энэ token-г Directus эсвэл өөр backend руу хадгалж болно
    } else {
      console.warn('No token retrieved. Notification permission not granted.')
    }

    let notificationSound: HTMLAudioElement | null = null
    notificationSound = new Audio('/sounds/notify.mp3')
    notificationSound.load()

    // Хуудас ачаалсны дараа хэрэглэгч ямар нэгэн үйлдэл хиймэгц sound-ыг load хийх
    document.addEventListener('click', () => {
      if (!notificationSound) {
        notificationSound = new Audio('/sounds/notify.mp3')
        notificationSound.load()
      }
    })

    // ✅ Realtime notification хүлээж авах
    onMessage(messaging, (payload) => {
      console.log('🔔 Realtime Notification received: ', payload)

      try {
        if (notificationSound) {
          notificationSound.currentTime = 0
          notificationSound.play().catch((err) => {
            console.warn('Дуу тоглуулахад алдаа гарлаа:', err)
          })
        }

        addNotification({
          user: 'System',
          message: 'New event just happened!',
          avatar: '/img/avatars/8.svg',
          time: 'Just now',
        })

        // 🔴 Badge-г идэвхжүүлэх
        // notificationStore.setNewNotification(true)

        // toaster.show({
        //   title: payload.notification?.title ?? 'Шинэ мэдэгдэл',
        //   message: payload.notification?.body ?? '',
        //   color: 'success',
        //   icon: 'mingcute:notification-newdot-fill',
        //   duration: 5000, // ms
        // })
      } catch (err) {
        console.error('Failed to play notification sound:', err)
      }

      // Optional: Show visual alert, toast, or badge
    })
  } catch (error) {
    console.error('🔥 Error getting FCM token:', error)
  }
}
