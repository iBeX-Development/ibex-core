<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { sendNotification } from '~/compsables/sendNotification'

const { t } = useI18n({ useScope: 'global' })
const { getItems, updateItem, deleteItems, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const toaster = useToaster()

definePageMeta({
  middleware: ['auth'],
  title: 'Monitoring Commands',
  showback: true,
})

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
  cooldown_minutes: number
  is_active: boolean
  last_triggered?: string | null
}

// ─── State ────────────────────────────────────────────────────────────────
const alerts = ref<AlertRow[]>([])
const loading = ref(true)
const search = ref('')
const filterAsset = ref('')
const filterActive = ref<'' | '1' | '0'>('')
const filterTriggered = ref<'' | '1' | '0'>('')
const total = ref(0)
const page = ref(1)
const perPage = ref(25)

// Asset lookup map
const assetMap = ref<
  Record<number, { name: string; asset_code: string; location: number | null }>
>({})

// Location lookup map (location id -> display name)
const locationMap = ref<Record<number, string>>({})

// Tracking field lookup map ("asset:field_key" -> value1..value5)
const trackingFieldMap = ref<
  Record<string, { unit?: string; [key: string]: any }>
>({})

const conditionLabels: Record<string, string> = {
  '>': ' (их)',
  '<': '(бага)',
  '>=': '(их тэнцүү)',
  '<=': '(бага тэнцүү)',
  '=': '(тэнцүү)',
  '!=': '(тэнцүү биш)',
}

// Client-side pagination over loaded alerts
const paginatedAlerts = computed(() => {
  const start = (page.value - 1) * perPage.value
  return alerts.value.slice(start, start + perPage.value)
})

// ─── Load ─────────────────────────────────────────────────────────────────
const loadAlerts = async () => {
  loading.value = true
  page.value = 1
  try {
    const filter: any = {
      company_id: myCompanyId,
    }
    if (filterActive.value !== '')
      filter.is_active = { _eq: Number(filterActive.value) }

    // Triggered status: '1' = ажилласан (last_triggered set), '0' = ажиллаагүй
    if (filterTriggered.value === '1') filter.last_triggered = { _nnull: true }
    else if (filterTriggered.value === '0')
      filter.last_triggered = { _null: true }

    // Search: asset field is a plain INT, so resolve matching asset IDs
    // (by asset_code / name) first, then filter alerts by those IDs.
    const term = search.value.trim()
    if (term) {
      let matchedAssetIds: number[] = []
      try {
        const matchRes = await getItems<any>({
          collection: 'Assets',
          params: {
            filter: {
              _or: [
                { asset_code: { _icontains: term } },
                { name: { _icontains: term } },
              ],
              company_id: myCompanyId,
            },
            fields: ['id'],
            limit: -1,
          },
        })
        const matchData = Array.isArray(matchRes)
          ? matchRes
          : (matchRes as any)?.data ?? []
        matchedAssetIds = matchData.map((a: any) => Number(a.id))
      } catch (_e) {}

      filter._or = [
        // -1 ensures no match when no asset matched the term
        { asset: { _in: matchedAssetIds.length ? matchedAssetIds : [-1] } },
        { field_key: { _icontains: term } },
        { field_name: { _icontains: term } },
        { alert_message: { _icontains: term } },
      ]
    }

    const res = await getItems<any>({
      collection: 'Monitoring_alerts',
      params: {
        filter,
        fields: ['*', 'asset.*'],
        sort: ['asset', 'field_key'],
        limit: -1,
        meta: 'filter_count',
      },
    })

    const data = Array.isArray(res) ? res : (res as any)?.data ?? []
    const meta = (res as any)?.meta

    alerts.value = data.map(
      (item: any): AlertRow => ({
        id: item.id,
        asset: item.asset,
        field: item.field != null ? Number(item.field) : null,
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
        cooldown_minutes: Number(item.cooldown_minutes) || 30,
        is_active: !!item.is_active,
        last_triggered: item.last_triggered,
      }),
    )

    total.value = Number(meta?.filter_count) || data.length

    // Load Device_tracking_fields values (value1..value5) to resolve thresholds.
    // Alerts don't store the field id, so resolve by asset + field_key.
    // item.asset may be an expanded object ({id, name, ...}) because we use fields: ['*', 'asset.*']
    const getAssetId = (raw: any): number | null => {
      if (raw == null) return null
      if (typeof raw === 'object') return raw.id != null ? Number(raw.id) : null
      const n = Number(raw)
      return isNaN(n) ? null : n
    }
    const trackAssetIds = [
      ...new Set(
        data
          .map((item: any) => getAssetId(item.asset))
          .filter((v): v is number => v != null),
      ),
    ] as number[]
    if (trackAssetIds.length) {
      try {
        const tfRes = await getItems<any>({
          collection: 'Device_tracking_fields',
          params: {
            filter: { asset: { _in: trackAssetIds }, company_id: myCompanyId },
            fields: [
              'asset',
              'field_key',
              'unit',
              'value1',
              'value2',
              'value3',
              'value4',
            ],
            limit: -1,
          },
        })
        const tfData = Array.isArray(tfRes) ? tfRes : (tfRes as any)?.data ?? []
        tfData.forEach((f: any) => {
          // asset may come back as a plain id or an expanded object
          const assetId =
            f.asset != null && typeof f.asset === 'object'
              ? Number(f.asset.id)
              : Number(f.asset)
          trackingFieldMap.value[`${assetId}:${f.field_key}`] = f
        })
        console.log(
          '[commands] tracking fields loaded',
          tfData.length,
          Object.keys(trackingFieldMap.value),
        )
      } catch (e) {
        console.log('[commands] tracking fields load error', e)
      }
    }

    // Load asset names separately (asset field is plain INT, not M2O relation)
    const ids = [
      ...new Set(data.map((item: any) => Number(item.asset)).filter(Boolean)),
    ] as number[]
    if (ids.length) {
      try {
        const assetRes = await getItems<any>({
          collection: 'Assets',
          params: {
            filter: { id: { _in: ids }, company_id: myCompanyId },
            fields: ['id', 'name', 'asset_code', 'location'],
            limit: ids.length,
          },
        })
        const assetData = Array.isArray(assetRes)
          ? assetRes
          : (assetRes as any)?.data ?? []
        assetData.forEach((a: any) => {
          assetMap.value[Number(a.id)] = {
            name: a.name,
            asset_code: a.asset_code,
            location: a.location != null ? Number(a.location) : null,
          }
        })

        // Load location names separately
        const locIds = [
          ...new Set(
            assetData
              .map((a: any) => (a.location != null ? Number(a.location) : null))
              .filter((v: number | null): v is number => v != null),
          ),
        ] as number[]
        if (locIds.length) {
          try {
            const locRes = await getItems<any>({
              collection: 'Location',
              params: {
                filter: { id: { _in: locIds }, company_id: myCompanyId },
                fields: ['id', 'name', 'location_code'],
                limit: locIds.length,
              },
            })
            const locData = Array.isArray(locRes)
              ? locRes
              : (locRes as any)?.data ?? []
            locData.forEach((l: any) => {
              locationMap.value[Number(l.id)] =
                l.name || l.location_code || `#${l.id}`
            })
          } catch (_e) {}
        }
      } catch (_e) {}
    }
  } catch (e: any) {
    toaster.show({
      title: t('Error'),
      message: String(e?.message || e),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  } finally {
    loading.value = false
  }
}

// ─── Toggle active ─────────────────────────────────────────────────────────
const toggleActive = async (row: AlertRow) => {
  try {
    await updateItem({
      collection: 'Monitoring_alerts',
      id: String(row.id),
      item: { is_active: row.is_active ? 0 : 1 },
    })
    row.is_active = !row.is_active
  } catch (_e) {}
}

// ─── Delete ───────────────────────────────────────────────────────────────
const deleteAlert = async (row: AlertRow) => {
  if (!confirm(t('Delete this command?'))) return
  try {
    await deleteItems({
      collection: 'Monitoring_alerts',
      items: [row.id as string],
    })
    alerts.value = alerts.value.filter((a) => a.id !== row.id)
    toaster.show({
      title: t('Deleted'),
      message: t('Command deleted'),
      color: 'success',
      icon: 'ph:trash',
      closable: true,
    })
  } catch (e: any) {
    toaster.show({
      title: t('Error'),
      message: String(e?.message || e),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  }
}

// Helper: asset display
const assetName = (row: AlertRow) => {
  const a = assetMap.value[Number(row.asset)]
  if (a) return a.asset_code || a.name || `#${row.asset}`
  return row.asset ? `#${row.asset}` : '-'
}

// Helper: full asset label (asset_code + name) for popups
const assetFull = (row: AlertRow) => {
  const a = assetMap.value[Number(row.asset)]
  if (!a) return row.asset ? `#${row.asset}` : '-'
  const parts = [a.asset_code, a.name].filter(Boolean)
  return parts.length ? parts.join(' — ') : `#${row.asset}`
}

// Helper: resolve the numeric value for a threshold row (null = not found)
const resolveThresholdVal = (row: AlertRow): string | null => {
  if (row.threshold_type === 'custom')
    return row.custom_value != null ? String(row.custom_value) : null
  const assetId =
    row.asset != null && typeof row.asset === 'object'
      ? Number((row.asset as any).id)
      : Number(row.asset)
  const tf = trackingFieldMap.value[`${assetId}:${row.field_key}`]
  const val = tf ? tf[row.threshold_type] : null
  return val != null && val !== '' ? String(val) : null
}

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

// Group alerts by asset location
const groupedAlerts = computed(() => {
  const groups = new Map<
    string,
    { key: string; label: string; rows: AlertRow[] }
  >()
  const noLocationLabel = t('No location')

  for (const row of paginatedAlerts.value) {
    const asset = assetMap.value[Number(row.asset)]
    const locId = asset?.location ?? null
    const label =
      locId != null ? locationMap.value[locId] || `#${locId}` : noLocationLabel
    const key = locId != null ? String(locId) : '__none__'

    if (!groups.has(key)) groups.set(key, { key, label, rows: [] })
    groups.get(key)!.rows.push(row)
  }

  // Sort groups by label, but keep "no location" last
  return [...groups.values()].sort((a, b) => {
    if (a.key === '__none__') return 1
    if (b.key === '__none__') return -1
    return a.label.localeCompare(b.label)
  })
})

// Collapsed location groups (by key)
const collapsedGroups = ref<Set<string>>(new Set())

const toggleGroup = (key: string) => {
  const next = new Set(collapsedGroups.value)
  if (next.has(key)) next.delete(key)
  else next.add(key)
  collapsedGroups.value = next
}

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

const closeBrowserPopup = () => {
  browserNotif.value.show = false
  if (browserNotifTimer) clearTimeout(browserNotifTimer)
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

const showPopupModal = (
  title: string,
  message: string,
  asset = '',
  location = '',
) => {
  popupModal.value = { show: true, title, message, asset, location }
}

const closePopupModal = () => {
  popupModal.value.show = false
}

// Web Audio beep
const playBeep = (frequency = 880, duration = 300, volume = 0.5) => {
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
  } catch (_e) {}
}

const sendTestEmail = async (row: AlertRow, label: string, message: string) => {
  if (!row.email_address) return
  const config = useRuntimeConfig()
  const baseUrl = (config.public.directus as any)?.url || ''
  try {
    await $fetch(
      `${baseUrl}flows/trigger/d831f177-8490-4329-b257-fee2a7820a6d`,
      {
        method: 'POST',
        body: {
          cc: 'ibex.admin@gmail.com',
          to: row.email_address,
          subject: `[CMMS Alert] ${label} дохиолол`,
          message,
          asset: row.asset,
          field: row.field_key,
        },
      },
    )
  } catch (_e) {}
}

const runCommand = async (row: AlertRow) => {
  const label = row.field_name || row.field_key
  const message = row.alert_message || `${label} — тест дохиолол`
  const assetLabel = assetFull(row)
  const locLabel = locationName(row)
  runningId.value = row.id

  try {
    // Popup — centered modal
    if (row.notify_popup) {
      showPopupModal(`⚠️ Дохиолол — ${label}`, message, assetLabel, locLabel)
    }

    // Sound — 3 beeps
    if (row.notify_sound) {
      playBeep(880, 300)
      setTimeout(() => playBeep(880, 300), 400)
      setTimeout(() => playBeep(880, 300), 800)
    }

    // Browser notification — designed in-page popup
    if (row.notify_browser) {
      showBrowserPopup(`⚠️ Дохиолол — ${label}`, message, assetLabel, locLabel)
    }

    // Email
    if (row.notify_email) {
      await sendTestEmail(row, label, message)
    }

    // Mark as triggered (ажилласан)
    try {
      const nowIso = new Date().toISOString()
      await updateItem({
        collection: 'Monitoring_alerts',
        id: String(row.id),
        item: { last_triggered: nowIso },
      })
      row.last_triggered = nowIso
    } catch (_e) {
      console.log('update last_triggered error', _e)
    }

    // Write a log record (ямар asset, хэзээ, ямар сувгаар дохисон)
    try {
      const a = assetMap.value[Number(row.asset)]
      await createItems({
        collection: 'Monitoring_alert_logs',
        items: [
          {
            alert: row.id,
            asset: row.asset ? Number(row.asset) : null,
            location: a?.location ?? null,
            field_key: row.field_key,
            field_name: row.field_name || row.field_key,
            condition: row.condition,
            threshold_type: row.threshold_type,
            threshold_value:
              row.threshold_type === 'custom' ? row.custom_value ?? null : null,
            message,
            notify_popup: row.notify_popup ? 1 : 0,
            notify_sound: row.notify_sound ? 1 : 0,
            notify_browser: row.notify_browser ? 1 : 0,
            notify_email: row.notify_email ? 1 : 0,
            company_id: myCompanyId,
            source: 'manual',
            triggered_at: new Date().toISOString(),
          },
        ],
      })
    } catch (_e) {
      console.log('write alert log error', _e)
    }

    // In-app notification (Directus db/send_notification)
    try {
      const myId = window.localStorage.getItem('myId')
      if (myId) {
        console.log('sendNotification', message, myId, Number(row.asset) || 0)
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

    // Nothing enabled
    if (
      !row.notify_popup &&
      !row.notify_sound &&
      !row.notify_browser &&
      !row.notify_email
    ) {
      toaster.show({
        title: t('Warning'),
        message: t('No notification type selected for this command'),
        color: 'warning',
        icon: 'ph:info',
        closable: true,
      })
    }
  } finally {
    runningId.value = null
  }
}

onMounted(() => loadAlerts())
</script>

<template>
  <div>
    <!-- Browser notification popup (designed) -->
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
              <p
                class="text-sm font-semibold text-muted-800 dark:text-white pr-4"
              >
                {{ browserNotif.title }}
              </p>
              <p
                class="mt-0.5 text-sm text-muted-500 dark:text-muted-300 break-words"
              >
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
          <!-- progress bar -->
          <div class="h-1 w-full bg-muted-100 dark:bg-muted-800">
            <div class="browser-notif-bar h-full bg-danger-500" />
          </div>
        </div>
      </div>
    </Transition>

    <!-- notify_popup centered modal -->
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
        <!-- backdrop / disabler -->
        <div
          class="absolute inset-0 bg-muted-900/60 backdrop-blur-sm"
          @click="closePopupModal"
        />
        <!-- dialog -->
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
                {{ t('Close') }}
              </BaseButton>
            </div>
          </div>
        </div>
      </div>
    </Transition>

    <!-- Summary cards (top) -->
    <BaseCard class="mb-4 p-4">
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div class="text-center">
          <Icon
            name="ph:list-bullets"
            class="h-6 w-6 mx-auto mb-1 text-muted-400"
          />
          <p class="text-2xl font-bold text-muted-800 dark:text-white">
            {{ total }}
          </p>
          <p class="text-xs text-muted-400">{{ t('Total commands') }}</p>
        </div>
        <div class="text-center">
          <Icon
            name="ph:check-circle"
            class="h-6 w-6 mx-auto mb-1 text-primary-500"
          />
          <p class="text-2xl font-bold text-primary-500">
            {{ alerts.filter((a) => a.is_active).length }}
          </p>
          <p class="text-xs text-muted-400">{{ t('Active') }}</p>
        </div>
        <div class="text-center">
          <Icon name="ph:bell" class="h-6 w-6 mx-auto mb-1 text-warning-500" />
          <p class="text-2xl font-bold text-warning-500">
            {{ alerts.filter((a) => a.last_triggered).length }}
          </p>
          <p class="text-xs text-muted-400">{{ t('Triggered') }}</p>
        </div>
        <div class="text-center">
          <Icon
            name="ph:envelope"
            class="h-6 w-6 mx-auto mb-1 text-success-500"
          />
          <p class="text-2xl font-bold text-success-500">
            {{ alerts.filter((a) => a.notify_email).length }}
          </p>
          <p class="text-xs text-muted-400">{{ t('Email alert') }}</p>
        </div>
      </div>
    </BaseCard>

    <TairoContentWrapper>
      <template #left>
        <!-- <BaseParagraph size="sm" class="text-muted-400 mt-1">
          {{ t('Monitoring alert settings for all assets') }}
        </BaseParagraph> -->
      </template>
      <template #right>
        <div class="flex items-center gap-2 flex-wrap">
          <!-- Search -->
          <BaseInput
            v-model="search"
            icon="ph:magnifying-glass"
            :placeholder="t('Search...')"
            size="sm"
            class="w-48"
            @keyup.enter="loadAlerts"
          />

          <!-- Active filter -->
          <!-- <select
            v-model="filterActive"
            class="rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-3 py-1.5 text-sm text-muted-700 dark:text-muted-200 focus:ring-2 focus:ring-primary-500"
            @change="loadAlerts"
          >
            <option value="">{{ t('All') }}</option>
            <option value="1">{{ t('Active') }}</option>
            <option value="0">{{ t('Inactive') }}</option>
          </select> -->

          <!-- Triggered filter -->
          <select
            v-model="filterTriggered"
            class="rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-3 py-1.5 text-sm text-muted-700 dark:text-muted-200 focus:ring-2 focus:ring-primary-500"
            @change="loadAlerts"
          >
            <option value="">{{ t('All') }}</option>
            <option value="1">{{ t('Executed') }}</option>
            <option value="0">{{ t('Not executed') }}</option>
          </select>

          <BaseButton size="sm" color="muted" @click="loadAlerts">
            <Icon name="ph:arrows-clockwise" class="h-4 w-4 mr-1" />
            {{ t('Refresh') }}
          </BaseButton>
        </div>
      </template>

      <!-- Loading -->
      <div v-if="loading" class="flex items-center justify-center py-16">
        <BaseButtonIcon loading shape="full" size="lg" />
      </div>

      <!-- Empty -->
      <BaseCard v-else-if="!alerts.length" class="p-10 text-center">
        <Icon
          name="ph:bell-slash"
          class="h-14 w-14 mx-auto mb-3 text-muted-300"
        />
        <BaseParagraph class="text-muted-400">{{
          t('No commands configured')
        }}</BaseParagraph>
        <BaseParagraph size="xs" class="text-muted-300 mt-1">
          {{ t('Add from the asset Datahub → Alerts tab') }}
        </BaseParagraph>
      </BaseCard>

      <!-- Table -->
      <BaseCard v-else class="overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr
                class="border-b border-muted-200 dark:border-muted-700 bg-muted-50 dark:bg-muted-800"
              >
                <th
                  class="px-3 py-2.5 text-left text-xs font-semibold text-muted-500 uppercase tracking-wide"
                >
                  {{ t('Assets') }}
                </th>
                <th
                  class="px-3 py-2.5 text-left text-xs font-semibold text-muted-500 uppercase tracking-wide"
                >
                  {{ t('Field') }}
                </th>
                <th
                  class="px-3 py-2.5 text-left text-xs font-semibold text-muted-500 uppercase tracking-wide"
                >
                  {{ t('Condition') }}
                </th>
                <th
                  class="px-3 py-2.5 text-left text-xs font-semibold text-muted-500 uppercase tracking-wide"
                >
                  {{ t('Threshold') }}
                </th>
                <th
                  class="px-3 py-2.5 text-left text-xs font-semibold text-muted-500 uppercase tracking-wide"
                >
                  {{ t('Alerts') }}
                </th>
                <th
                  class="px-3 py-2.5 text-left text-xs font-semibold text-muted-500 uppercase tracking-wide"
                >
                  {{ t('Message') }}
                </th>
                <th
                  class="px-3 py-2.5 text-left text-xs font-semibold text-muted-500 uppercase tracking-wide"
                >
                  {{ t('Last triggered') }}
                </th>
                <th
                  class="px-3 py-2.5 text-center text-xs font-semibold text-muted-500 uppercase tracking-wide"
                >
                  {{ t('Active') }}
                </th>
                <th
                  class="px-3 py-2.5 text-center text-xs font-semibold text-muted-500 uppercase tracking-wide"
                >
                  {{ t('Action') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-muted-100 dark:divide-muted-800">
              <template v-for="group in groupedAlerts" :key="group.key">
                <!-- Location group header -->
                <tr class="bg-muted-100 dark:bg-muted-800/70">
                  <td colspan="9" class="px-3 py-2">
                    <button
                      type="button"
                      class="flex w-full items-center gap-2 text-left"
                      @click="toggleGroup(group.key)"
                    >
                      <Icon
                        :name="
                          collapsedGroups.has(group.key)
                            ? 'ph:caret-right-bold'
                            : 'ph:caret-down-bold'
                        "
                        class="h-3.5 w-3.5 text-muted-400"
                      />
                      <Icon
                        name="ph:map-pin-duotone"
                        class="h-4 w-4 text-primary-500"
                      />
                      <span
                        class="font-semibold text-muted-700 dark:text-muted-200"
                        >{{ group.label }}</span
                      >
                      <span class="text-xs text-muted-400"
                        >({{ group.rows.length }})</span
                      >
                    </button>
                  </td>
                </tr>
                <tr
                  v-for="row in collapsedGroups.has(group.key)
                    ? []
                    : group.rows"
                  :key="row.id"
                  class="hover:bg-muted-50 dark:hover:bg-muted-800/50 transition-colors"
                  :class="{ 'opacity-50': !row.is_active }"
                >
                  <!-- Asset -->
                  <td class="px-3 py-2">
                    <span
                      class="whitespace-nowrap font-medium text-muted-700 dark:text-muted-200"
                      >{{ assetName(row) }}</span
                    >
                  </td>

                  <!-- Field -->
                  <td class="px-3 py-2">
                    <span class="text-muted-700 dark:text-muted-200">{{
                      row.field_name || row.field_key
                    }}</span>
                    <span class="ml-1 text-xs text-muted-400"
                      >({{ row.field_key }})</span
                    >
                  </td>

                  <!-- Condition -->
                  <td class="px-3 py-2">
                    <span class="font-mono text-info-500 font-semibold">{{
                      row.condition
                    }}</span>
                    <span class="ml-1 text-xs text-muted-400">{{
                      conditionLabels[row.condition]
                    }}</span>
                  </td>

                  <!-- Threshold -->
                  <td class="whitespace-nowrap px-3 py-2">
                    <!-- custom: just show the number -->
                    <template v-if="row.threshold_type === 'custom'">
                      <span class="font-medium">{{
                        resolveThresholdVal(row) ?? '-'
                      }}</span>
                    </template>
                    <!-- value1..value5: type in gray, resolved number after it -->
                    <template v-else>
                      <span class="text-xs text-muted-400">{{
                        row.threshold_type
                      }}</span>
                      <span
                        v-if="resolveThresholdVal(row) !== null"
                        class="ml-1 font-medium text-muted-700 dark:text-muted-200"
                        >: {{ resolveThresholdVal(row) }}</span
                      >
                    </template>
                  </td>

                  <!-- Notification badges -->
                  <td class="px-3 py-2">
                    <div class="flex items-center gap-1.5 flex-wrap">
                      <span
                        v-if="row.notify_popup"
                        class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-primary-100 dark:bg-primary-900/30 text-primary-600 text-xs"
                        :title="t('Popup notification')"
                      >
                        <Icon name="ph:bell" class="h-3 w-3" />popup
                      </span>
                      <span
                        v-if="row.notify_sound"
                        class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-warning-100 dark:bg-warning-900/30 text-warning-600 text-xs"
                        :title="t('Sound alert')"
                      >
                        <Icon name="ph:speaker-high" class="h-3 w-3" />sound
                      </span>
                      <span
                        v-if="row.notify_browser"
                        class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-info-100 dark:bg-info-900/30 text-info-600 text-xs"
                        :title="t('Browser notification')"
                      >
                        <Icon name="ph:bell-ringing" class="h-3 w-3" />browser
                      </span>
                      <span
                        v-if="row.notify_email"
                        class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-success-100 dark:bg-success-900/30 text-success-600 text-xs"
                        :title="row.email_address || t('Email')"
                      >
                        <Icon name="ph:envelope" class="h-3 w-3" />email
                      </span>
                    </div>
                  </td>

                  <!-- Alert message -->
                  <td class="px-3 py-2 max-w-[180px]">
                    <span
                      v-if="row.alert_message"
                      class="text-xs text-muted-600 dark:text-muted-300 line-clamp-2"
                      :title="row.alert_message"
                      >{{ row.alert_message }}</span
                    >
                    <span v-else class="text-xs text-muted-300">—</span>
                    <span
                      v-if="row.email_address"
                      class="mt-1 flex items-center gap-1 text-xs text-success-600 truncate"
                      :title="row.email_address"
                    >
                      <Icon name="ph:envelope" class="h-3 w-3 flex-shrink-0" />
                      {{ row.email_address }}
                    </span>
                  </td>

                  <!-- Last triggered -->
                  <td
                    class="px-3 py-2 text-xs text-muted-400 whitespace-nowrap"
                  >
                    {{ formatDate(row.last_triggered) }}
                  </td>

                  <!-- Active toggle -->
                  <td class="px-3 py-2 text-center">
                    <button
                      class="w-8 h-5 rounded-full transition-colors relative flex-shrink-0 inline-flex"
                      :class="
                        row.is_active
                          ? 'bg-primary-500'
                          : 'bg-muted-300 dark:bg-muted-600'
                      "
                      @click="toggleActive(row)"
                    >
                      <span
                        class="absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white shadow transition-transform"
                        :class="
                          row.is_active ? 'translate-x-3' : 'translate-x-0'
                        "
                      />
                    </button>
                  </td>

                  <!-- Actions -->
                  <td class="px-3 py-2 text-center">
                    <div class="flex items-center justify-center gap-1">
                      <BaseButtonIcon
                        size="xs"
                        color="primary"
                        :loading="runningId === row.id"
                        :title="t('Run')"
                        @click="runCommand(row)"
                      >
                        <Icon name="ph:play" class="h-3.5 w-3.5" />
                      </BaseButtonIcon>
                      <BaseButtonIcon
                        size="xs"
                        color="danger"
                        :title="t('Delete')"
                        @click="deleteAlert(row)"
                      >
                        <Icon name="ph:trash" class="h-3.5 w-3.5" />
                      </BaseButtonIcon>
                    </div>
                  </td>
                </tr>
              </template>
            </tbody>
          </table>
        </div>
      </BaseCard>

      <!-- Pager -->
      <div class="mt-4">
        <BasePagination
          v-model:page="page"
          :total="alerts.length"
          :items-per-page="perPage"
          rounded="lg"
          class="w-full"
        />
      </div>
    </TairoContentWrapper>
  </div>
</template>

<style scoped>
.browser-notif-bar {
  animation: browserNotifShrink 6s linear forwards;
}
@keyframes browserNotifShrink {
  from {
    width: 100%;
  }
  to {
    width: 0%;
  }
}
</style>
