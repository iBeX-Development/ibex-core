/**
 * useMonitoringAlerts — Monitoring_alerts / Monitoring_alert_logs-тай ажиллах composable.
 *
 * 2 үндсэн зориулалт:
 *  1. runCheckForAssets — mass import дараа тухайн asset-үүдийг шууд (нэг удаа)
 *     шалгаж, popup/sound/browser/email-ээр дохиолол өгнө (нөхцөл өөрөө шалгана).
 *  2. startLogPolling/stopLogPolling — 5 минутын pm2 cron
 *     (scripts/monitoring-alert-checker.js) Monitoring_alert_logs-д бичсэн
 *     шинэ мөрүүдийг 10 минут тутам уншиж, ЯГ ТУХАЙ ЦАГТ нь хэрэглэгчид
 *     popup/sound/browser notification-оор хүргэнэ (нөхцөл дахин шалгахгүй,
 *     зөвхөн хүргэлт хийнэ — cron аль хэдийн шалгасан).
 *
 * startPolling/stopPolling/tick (assetId тус бүрээр 10с тутам өөрөө нөхцөл
 * шалгадаг хуучин горим) нь cron-той давхардаж, идэвхгүй болгосон тул одоо
 * хаана ч дуудагдахгүй — устгаагүй байгаа шалтгаан нь OwnMonitoring.vue-д
 * коммент хэлбэрээр эргэж ашиглах магадлалтай учир.
 */

import { onUnmounted, ref } from 'vue'
import { sendNotification } from '~/compsables/sendNotification'

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface MonitoringAlert {
  id?: string | number
  asset: string | number
  field?: string | number | null
  field_key: string
  field_name?: string
  condition: '>' | '<' | '>=' | '<=' | '=' | '!='
  threshold_type: 'value1' | 'value2' | 'value3' | 'value4'
  custom_value?: number | null
  notify_popup: boolean
  notify_sound: boolean
  notify_browser: boolean
  notify_email: boolean
  email_address?: string | null
  alert_message?: string | null
  is_active: boolean
}

// ---------------------------------------------------------------------------
// Sound helper — Web Audio API беэп
// ---------------------------------------------------------------------------
function playBeep(frequency = 880, duration = 300, volume = 0.5) {
  try {
    const ctx = new (window.AudioContext ||
      (window as any).webkitAudioContext)()
    const oscillator = ctx.createOscillator()
    const gainNode = ctx.createGain()
    oscillator.connect(gainNode)
    gainNode.connect(ctx.destination)
    oscillator.type = 'square'
    oscillator.frequency.value = frequency
    gainNode.gain.value = volume
    oscillator.start()
    oscillator.stop(ctx.currentTime + duration / 1000)
    setTimeout(() => ctx.close(), duration + 100)
  } catch (_e) {
    // Audio context дэмжихгүй орчинд алдаа дарна
  }
}

// ---------------------------------------------------------------------------
// Browser Notification API — жинхэнэ OS-level мэдэгдэл
// ---------------------------------------------------------------------------
function requestBrowserPermission() {
  if (typeof window === 'undefined' || !('Notification' in window)) return
  if (
    Notification.permission !== 'granted' &&
    Notification.permission !== 'denied'
  ) {
    Notification.requestPermission().catch(() => {})
  }
}

function sendBrowserNotification(title: string, message: string) {
  if (typeof window === 'undefined' || !('Notification' in window)) return
  if (Notification.permission !== 'granted') return
  try {
    new Notification(title, { body: message, icon: '/img/logo.png' })
  } catch (_e) {
    // зарим орчинд Notification constructor алдаа өгдөг
  }
}

// ---------------------------------------------------------------------------
// Condition checker
// ---------------------------------------------------------------------------
function checkCondition(
  value: number,
  condition: string,
  threshold: number,
): boolean {
  switch (condition) {
    case '>':
      return value > threshold
    case '<':
      return value < threshold
    case '>=':
      return value >= threshold
    case '<=':
      return value <= threshold
    case '=':
      return value === threshold
    case '!=':
      return value !== threshold
    default:
      return false
  }
}

// ---------------------------------------------------------------------------
// Main composable
// ---------------------------------------------------------------------------
export function useMonitoringAlerts(
  assetId: Ref<string | number | null | undefined>,
) {
  const { getItems, createItems } = useDirectusItems()
  const myCompanyId = getMyCompanyId()
  const toaster = useToaster()
  const config = useRuntimeConfig()

  const alerts = ref<MonitoringAlert[]>([])
  const isPolling = ref(false)
  let pollingTimer: ReturnType<typeof setInterval> | null = null

  // ----------------------------------------------------------------
  // Load alerts from Directus
  // ----------------------------------------------------------------
  const loadAlerts = async () => {
    if (!assetId.value) return
    try {
      const res = await getItems<any>({
        collection: 'Monitoring_alerts',
        params: {
          filter: {
            asset: { _eq: assetId.value },
            is_active: { _eq: true },
          },
          limit: 50,
        },
      })
      alerts.value = (Array.isArray(res) ? res : (res as any)?.data ?? []).map(
        (item: any): MonitoringAlert => ({
          id: item.id,
          asset: item.asset,
          field: item.field,
          field_key: item.field_key,
          field_name: item.field_name,
          condition: item.condition,
          threshold_type: item.threshold_type,
          custom_value:
            item.custom_value !== null ? Number(item.custom_value) : null,
          notify_popup: !!item.notify_popup,
          notify_sound: !!item.notify_sound,
          notify_browser: !!item.notify_browser,
          notify_email: !!item.notify_email,
          email_address: item.email_address,
          alert_message: item.alert_message,
          is_active: !!item.is_active,
        }),
      )
    } catch (_e) {
      // алдаа дарна — polling дуусгахгүй
    }
  }

  // ----------------------------------------------------------------
  // Fetch device_tracking_fields threshold values for the asset
  // ----------------------------------------------------------------
  const fetchFieldThresholds = async (): Promise<
    Record<string, Record<string, number>>
  > => {
    if (!assetId.value) return {}
    try {
      const res = await getItems<any>({
        collection: 'Device_tracking_fields',
        params: {
          filter: { asset: { _eq: assetId.value } },
          fields: ['field_key', 'value1', 'value2', 'value3', 'value4'],
          limit: 50,
        },
      })
      const items = Array.isArray(res) ? res : (res as any)?.data ?? []
      const map: Record<string, Record<string, number>> = {}
      for (const item of items) {
        map[item.field_key] = {
          value1: Number(item.value1) || 0,
          value2: Number(item.value2) || 0,
          value3: Number(item.value3) || 0,
          value4: Number(item.value4) || 0,
        }
      }
      return map
    } catch (_e) {
      return {}
    }
  }

  // ----------------------------------------------------------------
  // Fetch latest data values
  // ----------------------------------------------------------------
  const fetchLatestValues = async (): Promise<Record<string, number>> => {
    if (!assetId.value) return {}
    try {
      const res = await getItems<any>({
        collection: 'Asset_field_data_json',
        params: {
          filter: { asset: { _eq: assetId.value } },
          sort: ['-date_created'],
          limit: 1,
        },
      })
      const items = Array.isArray(res) ? res : (res as any)?.data ?? []
      if (!items.length) return {}

      const raw = items[0]?.field_values
      if (!raw) return {}
      const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw
      const result: Record<string, number> = {}
      for (const [k, v] of Object.entries(parsed)) {
        result[k] = Number(v)
      }
      return result
    } catch (_e) {
      return {}
    }
  }

  // ----------------------------------------------------------------
  // Send email via Directus flow
  // ----------------------------------------------------------------
  const sendEmail = async (
    alert: MonitoringAlert,
    value: number,
    threshold: number,
  ) => {
    if (!alert.email_address) return
    const baseUrl = (config.public.directus as any)?.url || ''
    const subject = `[CMMS Alert] ${
      alert.field_name || alert.field_key
    } дохиолол`
    const body =
      alert.alert_message ||
      `${alert.field_name || alert.field_key}: ${value} ${
        alert.condition
      } ${threshold}`
    try {
      await $fetch(`${baseUrl}flows/trigger/monitoring-alert-email`, {
        method: 'POST',
        body: {
          to: alert.email_address,
          subject,
          message: body,
          asset: assetId.value,
          field: alert.field_key,
          value,
          threshold,
        },
      })
    } catch (_e) {
      // Directus flow байхгүй бол дарна
    }
  }

  // ----------------------------------------------------------------
  // Run alert actions (popup, sound, email) and update last_triggered
  // ----------------------------------------------------------------

  // ─── Run / test a command's notifications ──────────────────────────────────
  const runningId = ref<string | number | null>(null)

  // Custom in-page browser notification popup
  const browserNotif = ref<{
    show: boolean
    title: string
    message: string
    asset: string
    location: string
  }>({
    show: false,
    title: '',
    message: '',
    asset: '',
    location: '',
  })
  let browserNotifTimer: ReturnType<typeof setTimeout> | null = null

  // ─── Types ────────────────────────────────────────────────────────────────
  interface AlertRow {
    id: string | number
    asset: any
    field?: number | null
    field_key: string
    field_name?: string
    condition: string
    threshold_type: string
    custom_value?: number | null
    notify_popup: boolean
    notify_sound: boolean
    notify_browser: boolean
    notify_email: boolean
    email_address?: string | null
    alert_message?: string | null
    is_active: boolean
  }

  // Centered modal popup (for notify_popup)
  const popupModal = ref<{
    show: boolean
    title: string
    message: string
    asset: string
    location: string
  }>({
    show: false,
    title: '',
    message: '',
    asset: '',
    location: '',
  })

  // Asset lookup map
  const assetMap = ref<
    Record<
      number,
      { name: string; asset_code: string; location: number | null }
    >
  >({})

  // Location lookup map (location id -> display name)
  const locationMap = ref<Record<number, string>>({})

  // Helper: last triggered
  const formatDate = (val?: string | null) => {
    if (!val) return '-'
    return new Date(val).toLocaleString('mn-MN')
  }

  // Helper: location display for a row
  const locationName = (row: AlertRow) => {
    const a = assetMap.value[Number(row.asset)]
    const locId = a?.location ?? null
    if (locId != null) return locationMap.value[locId] || `#${locId}`
    return '-'
  }

  // Helper: full asset label (asset_code + name) for popups
  const assetFull = (row: AlertRow) => {
    const a = assetMap.value[Number(row.asset)]
    if (!a) return row.asset ? `#${row.asset}` : '-'
    const parts = [a.asset_code, a.name].filter(Boolean)
    return parts.length ? parts.join(' — ') : `#${row.asset}`
  }

  const showBrowserPopup = (
    title: string,
    message: string,
    asset = '',
    location = '',
  ) => {
    browserNotif.value = { show: true, title, message, asset, location }
    if (browserNotifTimer) clearTimeout(browserNotifTimer)
    browserNotifTimer = setTimeout(() => {
      browserNotif.value.show = false
    }, 6000)
  }

  const showPopupModal = (
    title: string,
    message: string,
    asset = '',
    location = '',
  ) => {
    popupModal.value = { show: true, title, message, asset, location }
  }

  // ----------------------------------------------------------------
  // Trigger alert
  // ----------------------------------------------------------------
  const triggerAlert = async (
    alert: MonitoringAlert,
    value: number,
    threshold: number,
    assetLabel = '',
    locationLabel = '',
  ) => {
    const label = alert.field_name || alert.field_key
    const message =
      alert.alert_message ||
      `${label}: ${value} ${alert.condition} ${threshold}`

    // In-app notification (Directus db/send_notification)
    try {
      const myId = window.localStorage.getItem('myId')
      if (myId) {
        await sendNotification(
          message,
          myId,
          myId,
          0,
          'monitoring',
          'Monitoring Alert',
        )
      }
    } catch (_e) {
      console.log('sendNotification with runcommand error', _e)
    }

    if (alert.notify_popup) {
      showPopupModal(
        `⚠️ Дохиолол — ${label}`,
        message,
        assetLabel,
        locationLabel,
      )
      toaster.show({
        title: `⚠️ Дохиолол — ${label}`,
        message,
        color: 'danger',
        icon: 'ph:warning-circle-fill',
        closable: true,
      })
    }

    if (alert.notify_sound) {
      // 3 удаа беэп дуугарна
      playBeep(880, 300)
      setTimeout(() => playBeep(880, 300), 400)
      setTimeout(() => playBeep(880, 300), 800)
    }

    if (alert.notify_browser) {
      showBrowserPopup(
        `⚠️ Дохиолол — ${label}`,
        message,
        assetLabel,
        locationLabel,
      )
      sendBrowserNotification(
        `⚠️ ${alert.field_name || alert.field_key}`,
        message,
      )
    }

    if (alert.notify_email) {
      await sendEmail(alert, value, threshold)
    }

    // Monitoring_alert_logs бүртгэх
    try {
      await createItems({
        collection: 'Monitoring_alert_logs',
        items: [
          {
            alert: alert.id ?? null,
            asset: alert.asset ? Number(alert.asset) : null,
            field_key: alert.field_key,
            field_name: alert.field_name || alert.field_key,
            condition: alert.condition,
            threshold_type: alert.threshold_type,
            threshold_value: threshold,
            triggered_value: value,
            message,
            notify_popup: alert.notify_popup ? 1 : 0,
            notify_sound: alert.notify_sound ? 1 : 0,
            notify_browser: alert.notify_browser ? 1 : 0,
            notify_email: alert.notify_email ? 1 : 0,
            source: 'auto',
            triggered_at: new Date().toISOString(),
            company_id: myCompanyId,
          },
        ],
      })
    } catch (_e) {}
  }

  // ----------------------------------------------------------------
  // One polling tick
  // ----------------------------------------------------------------
  const tick = async () => {
    if (!alerts.value.length) return

    const [values, thresholds] = await Promise.all([
      fetchLatestValues(),
      fetchFieldThresholds(),
    ])

    for (const alert of alerts.value) {
      const currentValue = values[alert.field_key]
      if (currentValue === undefined || isNaN(currentValue)) continue

      // Босго тодорхойлно
      let threshold: number | null = null
      if (alert.threshold_type === 'custom') {
        threshold = alert.custom_value ?? null
      } else {
        const fieldThresholds = thresholds[alert.field_key]
        if (fieldThresholds) {
          threshold = fieldThresholds[alert.threshold_type] ?? null
        }
      }
      if (threshold === null || isNaN(threshold)) continue

      if (checkCondition(currentValue, alert.condition, threshold)) {
        await triggerAlert(alert, currentValue, threshold)
      }
    }
  }

  // ----------------------------------------------------------------
  // Start / Stop polling
  // ----------------------------------------------------------------
  const startPolling = async (intervalMs = 10_000) => {
    if (isPolling.value) return
    isPolling.value = true
    await loadAlerts()
    pollingTimer = setInterval(async () => {
      await tick()
    }, intervalMs)
  }

  const stopPolling = () => {
    if (pollingTimer) {
      clearInterval(pollingTimer)
      pollingTimer = null
    }
    isPolling.value = false
  }

  // ----------------------------------------------------------------
  // Realtime log polling — 5 минутын cron (monitoring-alert-checker.js)-ийн
  // Monitoring_alert_logs-д бичсэн шинэ мөрүүдийг богино зайтай (10мин) уншиж,
  // popup / sound / browser notification-оор хэрэглэгчид хүргэнэ.
  // Cron нь аль хэдийн нөхцөл шалгаж лог бичсэн тул энд дахин шалгахгүй,
  // зөвхөн "хүргэлт" хийнэ. notify_email-ийг cron/Directus flow аль хэдийн
  // илгээсэн тул энд дахин илгээхгүй.
  // ----------------------------------------------------------------
  const LOG_LAST_SEEN_KEY_PREFIX = 'monitoringAlertLogs_lastSeenId_'
  const LOG_POLL_INTERVAL_MS = 600_000
  let logPollingTimer: ReturnType<typeof setInterval> | null = null
  let isLogPolling = false
  let lastSeenLogId = 0

  // Asset (+ Location)-ийн мэдээллийг нэг л удаа татаж assetMap/locationMap-д
  // кэшлээд, дараагийн alert-ууд дээр дахин fetch хийхгүй
  const resolveAssetInfo = async (
    assetId: number,
  ): Promise<{ assetLabel: string; locationLabel: string }> => {
    if (!assetId) return { assetLabel: '', locationLabel: '' }

    if (!assetMap.value[assetId]) {
      try {
        const res = await getItems<any>({
          collection: 'Assets',
          params: {
            filter: { id: { _eq: assetId } },
            fields: ['id', 'asset_code', 'name', 'location'],
            limit: 1,
          },
        })
        const arr = Array.isArray(res) ? res : (res as any)?.data ?? []
        const item = arr[0]
        if (item) {
          assetMap.value = {
            ...assetMap.value,
            [assetId]: {
              name: item.name,
              asset_code: item.asset_code,
              location: item.location ? Number(item.location) : null,
            },
          }
        }
      } catch (_e) {}
    }

    const a = assetMap.value[assetId]
    const assetLabel = a
      ? [a.asset_code, a.name].filter(Boolean).join(' — ') || `#${assetId}`
      : `#${assetId}`

    const locId = a?.location ?? null
    let locationLabel = ''
    if (locId != null) {
      if (!locationMap.value[locId]) {
        try {
          const res = await getItems<any>({
            collection: 'Location',
            params: {
              filter: { id: { _eq: locId } },
              fields: ['id', 'name', 'location_code'],
              limit: 1,
            },
          })
          const arr = Array.isArray(res) ? res : (res as any)?.data ?? []
          const item = arr[0]
          if (item) {
            locationMap.value = {
              ...locationMap.value,
              [locId]: item.name || item.location_code || `#${locId}`,
            }
          }
        } catch (_e) {}
      }
      locationLabel = locationMap.value[locId] || `#${locId}`
    }

    return { assetLabel, locationLabel }
  }

  const deliverAlertLog = async (row: any) => {
    const label = row.field_name || row.field_key
    const message =
      row.message ||
      `${label}: ${row.triggered_value ?? '-'} ${row.condition ?? ''} ${
        row.threshold_value ?? '-'
      }`
    const title = `⚠️ Дохиолол — ${label}`
    const { assetLabel, locationLabel } = await resolveAssetInfo(
      Number(row.asset),
    )

    if (row.notify_popup) {
      showPopupModal(title, message, assetLabel, locationLabel)
      toaster.show({
        title,
        message: assetLabel ? `${assetLabel} — ${message}` : message,
        color: 'danger',
        icon: 'ph:warning-circle-fill',
        closable: true,
      })
    }

    if (row.notify_sound) {
      playBeep(880, 300)
      setTimeout(() => playBeep(880, 300), 400)
      setTimeout(() => playBeep(880, 300), 800)
    }

    if (row.notify_browser) {
      showBrowserPopup(title, message, assetLabel, locationLabel)
      sendBrowserNotification(
        title,
        assetLabel ? `${assetLabel} — ${message}` : message,
      )
    }

    // In-app notification (Directus db/send_notification) — идэвхтэй tab-тай
    // хэрэглэгчийн bell/notification list-д харагдана
    try {
      const myId = window.localStorage.getItem('myId')
      if (myId) {
        await sendNotification(message, myId, myId, 0, 'monitoring', title)
      }
    } catch (_e) {
      console.log('sendNotification (log polling) error', _e)
    }
  }

  const fetchNewAlertLogs = async (companyId: number, afterId: number) => {
    try {
      console.log('fetchNewAlertLogs')

      const res = await getItems<any>({
        collection: 'Monitoring_alert_logs',
        params: {
          filter: {
            company_id: { _eq: companyId },
            id: { _gt: afterId },
          },
          fields: [
            'id',
            'asset',
            'field_key',
            'field_name',
            'condition',
            'threshold_value',
            'triggered_value',
            'message',
            'notify_popup',
            'notify_sound',
            'notify_browser',
            'notify_email',
          ],
          sort: ['id'],
          limit: 50,
        },
      })
      return Array.isArray(res) ? res : (res as any)?.data ?? []
    } catch (_e) {
      return []
    }
  }

  const logPollTick = async (companyId: number, storageKey: string) => {
    const rows = await fetchNewAlertLogs(companyId, lastSeenLogId)
    if (!rows.length) return
    rows.forEach((row: any, index: number) => {
      setTimeout(() => deliverAlertLog(row), index * 700)
    })
    lastSeenLogId = Number(rows[rows.length - 1].id)
    window.localStorage.setItem(storageKey, String(lastSeenLogId))
  }

  const startLogPolling = async () => {
    if (isLogPolling || typeof window === 'undefined') return
    const companyId = Number(getMyCompanyId())
    if (!companyId) return
    isLogPolling = true
    requestBrowserPermission()

    const storageKey = `${LOG_LAST_SEEN_KEY_PREFIX}${companyId}`
    const stored = window.localStorage.getItem(storageKey)

    if (stored) {
      lastSeenLogId = Number(stored) || 0
    } else {
      // Анх удаа ажиллаж байгаа бол өнгөрсөн логийг дахин цацахгүйн тулд
      // одоо байгаа хамгийн сүүлийн id-г baseline болгоно
      try {
        console.log('startLogPolling')
        const res = await getItems<any>({
          collection: 'Monitoring_alert_logs',
          params: {
            filter: { company_id: { _eq: companyId } },
            fields: ['id'],
            sort: ['-id'],
            limit: 1,
          },
        })
        const rows = Array.isArray(res) ? res : (res as any)?.data ?? []
        lastSeenLogId = rows.length ? Number(rows[0].id) : 0
      } catch (_e) {
        lastSeenLogId = 0
      }
      window.localStorage.setItem(storageKey, String(lastSeenLogId))
    }

    logPollingTimer = setInterval(() => {
      logPollTick(companyId, storageKey)
    }, LOG_POLL_INTERVAL_MS)
  }

  const stopLogPolling = () => {
    if (logPollingTimer) {
      clearInterval(logPollingTimer)
      logPollingTimer = null
    }
    isLogPolling = false
  }

  onUnmounted(() => {
    stopPolling()
    stopLogPolling()
  })

  // ----------------------------------------------------------------
  // runCheckForAssets — mass import дараа олон asset-д alert шалгах
  // ----------------------------------------------------------------
  const runCheckForAssets = async (assetIds: number[]) => {
    if (!assetIds.length) return

    console.log('[MonitoringAlerts] runCheckForAssets → assetIds:', assetIds)

    toaster.show({
      title: '🔔 Monitoring шалгаж байна...',
      message: `${assetIds.length} asset-ийн alert нөхцөл шалгагдаж байна`,
      color: 'info',
      icon: 'ph:bell',
      closable: true,
    })

    // Load active alerts for these assets
    let alertList: MonitoringAlert[] = []
    try {
      const res = await getItems<any>({
        collection: 'Monitoring_alerts',
        params: {
          filter: { asset: { _in: assetIds }, is_active: { _eq: true } },
          fields: [
            'id',
            'asset',
            'field',
            'field_key',
            'field_name',
            'condition',
            'threshold_type',
            'custom_value',
            'notify_popup',
            'notify_sound',
            'notify_browser',
            'notify_email',
            'email_address',
            'alert_message',
          ],
          limit: 200,
        },
      })
      alertList = (Array.isArray(res) ? res : (res as any)?.data ?? []).map(
        (item: any): MonitoringAlert => ({
          id: item.id,
          asset: item.asset,
          field: item.field,
          field_key: item.field_key,
          field_name: item.field_name,
          condition: item.condition,
          threshold_type: item.threshold_type,
          custom_value:
            item.custom_value !== null ? Number(item.custom_value) : null,
          notify_popup: !!item.notify_popup,
          notify_sound: !!item.notify_sound,
          notify_browser: !!item.notify_browser,
          notify_email: !!item.notify_email,
          email_address: item.email_address,
          alert_message: item.alert_message,
          is_active: !!item.is_active,
        }),
      )
      console.log(
        `[MonitoringAlerts] alerts found: ${alertList.length}`,
        alertList,
      )
    } catch (e) {
      console.error('[MonitoringAlerts] ERROR fetching alerts:', e)
      return
    }

    if (!alertList.length) {
      console.warn(
        '[MonitoringAlerts] No active alerts found for assetIds:',
        assetIds,
      )
      return
    }

    // Load asset info for display labels
    const assetRes = await getItems<any>({
      collection: 'Assets',
      params: {
        filter: { id: { _in: assetIds } },
        fields: ['id', 'asset_code', 'name', 'location'],
        limit: -1,
      },
    }).catch(() => [])
    const assetArr: any[] = Array.isArray(assetRes)
      ? assetRes
      : (assetRes as any)?.data ?? []
    const assetInfoMap = new Map(assetArr.map((a: any) => [Number(a.id), a]))

    const locIds = [
      ...new Set(
        assetArr
          .map((a: any) => (a.location ? Number(a.location) : null))
          .filter(Boolean),
      ),
    ] as number[]
    const locLabelMap: Record<number, string> = {}
    if (locIds.length) {
      const locRes = await getItems<any>({
        collection: 'Location',
        params: {
          filter: { id: { _in: locIds } },
          fields: ['id', 'name', 'location_code'],
          limit: -1,
        },
      }).catch(() => [])
      const locArr: any[] = Array.isArray(locRes)
        ? locRes
        : (locRes as any)?.data ?? []
      locArr.forEach((l: any) => {
        locLabelMap[Number(l.id)] = l.name || l.location_code || `#${l.id}`
      })
    }

    // Group alerts by asset
    const byAsset = new Map<number, MonitoringAlert[]>()
    for (const alert of alertList) {
      const aid = Number(alert.asset)
      if (!byAsset.has(aid)) byAsset.set(aid, [])
      byAsset.get(aid)!.push(alert)
    }

    for (const [assetId, assetAlerts] of byAsset) {
      // Fetch ALL records in the recent import batch (last 500 by date_created)
      // so we can detect peak/min values — not just the last row.
      const fieldValueMap: Record<string, number[]> = {}
      try {
        const dataRes = await getItems<any>({
          collection: 'Asset_field_data_json',
          params: {
            filter: { asset: { _eq: assetId } },
            sort: ['-date_created'],
            limit: 500,
          },
        })
        const dataArr: any[] = Array.isArray(dataRes)
          ? dataRes
          : (dataRes as any)?.data ?? []
        for (const row of dataArr) {
          const raw = row?.field_values
          if (!raw) continue
          const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw
          for (const [k, v] of Object.entries(parsed)) {
            const num = Number(v)
            if (!isNaN(num)) {
              if (!fieldValueMap[k]) fieldValueMap[k] = []
              fieldValueMap[k].push(num)
            }
          }
        }
      } catch (_e) {}

      const fieldKeys = Object.keys(fieldValueMap)
      console.log(
        `[MonitoringAlerts] asset ${assetId} field keys in batch:`,
        fieldKeys,
        '— record count:',
        Object.values(fieldValueMap)[0]?.length ?? 0,
      )
      if (!fieldKeys.length) {
        console.warn(
          `[MonitoringAlerts] asset ${assetId}: no field_values data found, skipping`,
        )
        continue
      }

      // Fetch thresholds
      const thresholds: Record<string, Record<string, number>> = {}
      try {
        const tfRes = await getItems<any>({
          collection: 'Device_tracking_fields',
          params: {
            filter: { asset: { _eq: assetId } },
            fields: ['field_key', 'value1', 'value2', 'value3', 'value4'],
            limit: 50,
          },
        })
        const tfArr: any[] = Array.isArray(tfRes)
          ? tfRes
          : (tfRes as any)?.data ?? []
        tfArr.forEach((f: any) => {
          thresholds[f.field_key] = {
            value1: Number(f.value1) || 0,
            value2: Number(f.value2) || 0,
            value3: Number(f.value3) || 0,
            value4: Number(f.value4) || 0,
          }
        })
      } catch (_e) {}

      const info = assetInfoMap.get(assetId)
      const assetLabel = info
        ? `${info.asset_code || ''} ${info.name || ''}`.trim()
        : `#${assetId}`
      const locId = info?.location ? Number(info.location) : null
      const locationLabel = locId ? locLabelMap[locId] || `#${locId}` : ''

      console.log(`[MonitoringAlerts] asset ${assetId} thresholds:`, thresholds)
      for (const alert of assetAlerts) {
        const vals = fieldValueMap[alert.field_key]
        if (!vals?.length) {
          console.warn(
            `[MonitoringAlerts] alert ${alert.id}: field_key "${alert.field_key}" not in batch values`,
          )
          continue
        }

        let threshold: number | null = null
        if (alert.threshold_type === 'custom') {
          threshold = alert.custom_value ?? null
        } else {
          threshold =
            thresholds[alert.field_key]?.[alert.threshold_type] ?? null
        }
        if (threshold === null || isNaN(threshold)) {
          console.warn(
            `[MonitoringAlerts] alert ${alert.id}: threshold null/NaN (type: ${alert.threshold_type})`,
          )
          continue
        }

        // Pick the most extreme value in the batch for this condition:
        // > / >= → max value (peak high)  |  < / <= → min value (peak low)
        // = / != → find first match
        let checkValue: number
        if (alert.condition === '<' || alert.condition === '<=') {
          checkValue = Math.min(...vals)
        } else if (alert.condition === '=' || alert.condition === '!=') {
          const match = vals.find((v) =>
            checkCondition(v, alert.condition, threshold as number),
          )
          if (match === undefined) {
            console.log(
              `[MonitoringAlerts] alert ${alert.id} (${alert.field_key}): no value matches ${alert.condition} ${threshold} in batch`,
            )
            continue
          }
          checkValue = match
        } else {
          checkValue = Math.max(...vals)
        }

        const condResult = checkCondition(
          checkValue,
          alert.condition,
          threshold,
        )
        console.log(
          `[MonitoringAlerts] alert ${alert.id} (${alert.field_key}): peak=${checkValue} ${alert.condition} ${threshold} → ${condResult} (batch size: ${vals.length})`,
        )
        if (condResult) {
          console.log(
            `[MonitoringAlerts] FIRING alert ${alert.id} →`,
            alert.notify_popup ? 'popup' : '',
            alert.notify_browser ? 'browser' : '',
            alert.notify_sound ? 'sound' : '',
          )
          await triggerAlert(
            alert,
            checkValue,
            threshold,
            assetLabel,
            locationLabel,
          )
        }
      }
    }
  }

  return {
    alerts,
    isPolling,
    loadAlerts,
    startPolling,
    stopPolling,
    browserNotif,
    popupModal,
    closeBrowserPopup: () => {
      browserNotif.value.show = false
    },
    closePopupModal: () => {
      popupModal.value.show = false
    },
    runCheckForAssets,
    startLogPolling,
    stopLogPolling,
  }
}
