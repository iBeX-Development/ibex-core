import { getApp, getApps, initializeApp } from 'firebase/app'
import { getMessaging, getToken, onMessage } from 'firebase/messaging'
import type { Messaging } from 'firebase/messaging'
import { useRuntimeConfig } from '#imports'

export let messaging: Messaging | null = null

export function getConfiguredMessaging(): Messaging | null {
  if (typeof window === 'undefined') return null
  const config = useRuntimeConfig().public.firebase
  if (!config.apiKey || !config.projectId || !config.messagingSenderId || !config.appId) return null
  const app = getApps().length ? getApp() : initializeApp({
    apiKey: config.apiKey,
    authDomain: config.authDomain,
    projectId: config.projectId,
    storageBucket: config.storageBucket,
    messagingSenderId: config.messagingSenderId,
    appId: config.appId,
    measurementId: config.measurementId,
  })
  messaging = getMessaging(app)
  return messaging
}

export { getToken, onMessage }
