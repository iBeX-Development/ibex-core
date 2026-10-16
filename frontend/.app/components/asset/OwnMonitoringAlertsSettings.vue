<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()

interface Props {
  assetId?: string | number | null
}
const props = defineProps<Props>()

const { getItems, createItems, updateItem, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

// ─── Types ────────────────────────────────────────────────────────────────
interface TrackingField {
  id: string | number
  field_key: string
  field_name_mn: string
  field_name_en: string
  unit?: string
  value1?: number | null
  value2?: number | null
  value3?: number | null
  value4?: number | null
  is_show?: number
}

interface AlertRow {
  id?: string | number
  asset: string | number
  field?: string | number | null
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

// Default fields shown when Device_tracking_fields has no records for this asset
const defaultFields: TrackingField[] = [
  {
    id: 'speed',
    field_key: 'speed',
    field_name_mn: 'Speed',
    field_name_en: 'Speed',
    unit: 'км/ц',
  },
  {
    id: 'fuel_level',
    field_key: 'fuel_level',
    field_name_mn: 'Fuel',
    field_name_en: 'Fuel Level',
    unit: '%',
  },
  {
    id: 'engine_hours',
    field_key: 'engine_hours',
    field_name_mn: 'Engine hours',
    field_name_en: 'Engine Hours',
    unit: 'ц',
  },
  {
    id: 'odometer',
    field_key: 'odometer',
    field_name_mn: 'Гүйлт',
    field_name_en: 'Odometer',
    unit: 'км',
  },
  {
    id: 'temperature',
    field_key: 'temperature',
    field_name_mn: 'Температур',
    field_name_en: 'Temperature',
    unit: '°C',
  },
  {
    id: 'altitude',
    field_key: 'altitude',
    field_name_mn: 'Өндөр',
    field_name_en: 'Altitude',
    unit: 'м',
  },
  {
    id: 'direction',
    field_key: 'direction',
    field_name_mn: 'Чиглэл',
    field_name_en: 'Direction',
    unit: '°',
  },
  {
    id: 'satellites',
    field_key: 'satellites',
    field_name_mn: 'Дагуул',
    field_name_en: 'Satellites',
    unit: '',
  },
  {
    id: 'latitude',
    field_key: 'latitude',
    field_name_mn: 'Latitude',
    field_name_en: 'Latitude',
    unit: '°',
  },
  {
    id: 'longitude',
    field_key: 'longitude',
    field_name_mn: 'Longitude',
    field_name_en: 'Longitude',
    unit: '°',
  },
]

// ─── State ────────────────────────────────────────────────────────────────
const trackingFields = ref<TrackingField[]>([])
const alerts = ref<AlertRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const editingAlert = ref<AlertRow | null>(null)

// Alert trigger logs (Monitoring_alert_logs) — сервер талын хуудаслалт
// (нэг asset дээр өдөрт хэдэн зуун лог хуримтлагдаж болох тул client-side
// бүх мөрийг нэг дор татахгүй, зөвхөн идэвхтэй хуудасны 50-ийг татна)
const logs = ref<any[]>([])
const logsLoading = ref(false)
const logsPage = ref(1)
const logsPerPage = ref(50)
const logsTotal = ref(0)

const conditionOptions = [
  { value: '>=', label: '>= (Их эсвэл тэнцүү)' },
  { value: '<=', label: '<= (Бага эсвэл тэнцүү)' },
]

const thresholdTypeOptions = computed(() => {
  const base = [
    { value: 'value1', label: 'Value 1' },
    { value: 'value2', label: 'Value 2' },
    { value: 'value3', label: 'Value 3' },
    { value: 'value4', label: 'Value 4' },
    // { value: 'custom', label: t('Enter manually') },
  ]
  return base
})

// Модал дотор одоо сонгосон field-ийн тохиргоо (threshold value1-4 харуулахад)
const selectedTrackingField = computed(() =>
  trackingFields.value.find((f) => f.field_key === form.value.field_key),
)

// ─── Form state ───────────────────────────────────────────────────────────
const form = ref<AlertRow>({
  asset: props.assetId as string | number,
  field_key: '',
  condition: '>=',
  threshold_type: 'value1',
  custom_value: null,
  notify_popup: true,
  notify_sound: false,
  notify_browser: false,
  notify_email: false,
  email_address: null,
  alert_message: null,
  cooldown_minutes: 30,
  is_active: true,
})

// Helper: get threshold value label for a field
function getThresholdLabel(row: AlertRow): string {
  if (row.threshold_type === 'custom') return String(row.custom_value ?? '-')
  const tf = trackingFields.value.find((f) => f.field_key === row.field_key)
  if (!tf) return '-'
  const val = (tf as any)[row.threshold_type]
  return val !== null && val !== undefined ? String(val) : '-'
}

// Helper: get field label
function getFieldLabel(row: AlertRow): string {
  const tf = trackingFields.value.find((f) => f.field_key === row.field_key)
  return tf ? `${tf.field_name_mn} (${tf.field_key})` : row.field_key
}

// ─── Load data ────────────────────────────────────────────────────────────
// Settings (OwnDeviceSettings.vue)-тэй адил ЗӨВХӨН is_show=1 талбаруудыг л
// сонгох боломжтой болгоно — is_show=0 (унтарсан) талбарыг Add alert дээр
// харуулахгүй. Ижил field_key хэд хэдэн мөрд (rawdata/livedata эсвэл өөр
// sensor) давхцаж болох тул field_key бүрээс ЗӨВХӨН эхний тохиргоог авна —
// ингэснээр dropdown болон "Selected field threshold values" давхардахгүй
const loadTrackingFields = async () => {
  if (!props.assetId) return

  console.log('props.assetId', props.assetId)
  try {
    const res = await getItems<any>({
      collection: 'Device_tracking_fields',
      params: {
        filter: {
          asset: { _eq: props.assetId },
          company_id: { _eq: myCompanyId },
          status: 'published',
          is_show: { _eq: 1 },
        },
        fields: [
          'id',
          'field_key',
          'field_name_mn',
          'field_name_en',
          'unit',
          'value1',
          'value2',
          'value3',
          'value4',
          'is_show',
        ],
        sort: ['sort_order'],
      },
    })
    const items = Array.isArray(res) ? res : (res as any)?.data ?? []

    const deduped: TrackingField[] = []
    const seenKeys = new Set<string>()
    for (const item of items) {
      if (!item.field_key || seenKeys.has(item.field_key)) continue
      seenKeys.add(item.field_key)
      deduped.push(item)
    }

    trackingFields.value = deduped.length > 0 ? deduped : defaultFields
  } catch (_e) {
    trackingFields.value = defaultFields
  }
}

const loadAlerts = async () => {
  if (!props.assetId) return
  loading.value = true
  try {
    const res = await getItems<any>({
      collection: 'Monitoring_alerts',
      params: {
        filter: {
          asset: { _eq: props.assetId },
          company_id: { _eq: myCompanyId },
        },
        sort: ['id'],
        limit: 100,
      },
    })
    alerts.value = (Array.isArray(res) ? res : (res as any)?.data ?? []).map(
      (item: any): AlertRow => ({
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
        cooldown_minutes: Number(item.cooldown_minutes) || 30,
        is_active: !!item.is_active,
        last_triggered: item.last_triggered,
      }),
    )
  } catch (_e) {
    toaster.show({
      title: t('Error'),
      message: t('Failed to load alert list'),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  } finally {
    loading.value = false
  }
}

// ─── Open modal ───────────────────────────────────────────────────────────
const openAdd = () => {
  editingAlert.value = null
  form.value = {
    asset: props.assetId as string | number,
    field_key: trackingFields.value[0]?.field_key ?? '',
    condition: '>=',
    threshold_type: 'value1',
    custom_value: null,
    notify_popup: true,
    notify_sound: false,
    notify_browser: false,
    notify_email: false,
    email_address: null,
    alert_message: null,
    cooldown_minutes: 30,
    is_active: true,
  }
  showModal.value = true
}

const openEdit = (row: AlertRow) => {
  editingAlert.value = row
  form.value = { ...row }
  showModal.value = true
}

// Auto-fill field_name when field_key changes
watch(
  () => form.value.field_key,
  (key) => {
    const tf = trackingFields.value.find((f) => f.field_key === key)
    if (tf) form.value.field_name = tf.field_name_mn
  },
)

// ─── Save ─────────────────────────────────────────────────────────────────
const saveAlert = async () => {
  if (!form.value.field_key) {
    toaster.show({
      title: t('Warning'),
      message: t('Select a field'),
      color: 'warning',
      icon: 'ph:warning',
      closable: true,
    })
    return
  }
  saving.value = true
  try {
    const payload: any = {
      asset: props.assetId,
      field_key: form.value.field_key,
      field_name: form.value.field_name || form.value.field_key,
      condition: form.value.condition,
      threshold_type: form.value.threshold_type,
      custom_value:
        form.value.threshold_type === 'custom'
          ? form.value.custom_value ?? null
          : null,
      notify_popup: form.value.notify_popup ? 1 : 0,
      notify_sound: form.value.notify_sound ? 1 : 0,
      notify_browser: form.value.notify_browser ? 1 : 0,
      notify_email: form.value.notify_email ? 1 : 0,
      email_address: form.value.notify_email ? form.value.email_address : null,
      alert_message: form.value.alert_message || null,
      cooldown_minutes: form.value.cooldown_minutes || 30,
      is_active: form.value.is_active ? 1 : 0,
      company_id: myCompanyId,
    }

    if (editingAlert.value?.id) {
      await updateItem({
        collection: 'Monitoring_alerts',
        id: String(editingAlert.value.id),
        item: payload,
      })
    } else {
      await createItems({ collection: 'Monitoring_alerts', items: [payload] })
    }

    toaster.show({
      title: t('Success'),
      message: t('Alert saved'),
      color: 'success',
      icon: 'ph:check',
      closable: true,
    })
    showModal.value = false
    await loadAlerts()
  } catch (e: any) {
    toaster.show({
      title: t('Error'),
      message: String(e?.message || e),
      color: 'danger',
      icon: 'ph:warning',
      closable: true,
    })
  } finally {
    saving.value = false
  }
}

// ─── Toggle active ─────────────────────────────────────────────────────────
const toggleActive = async (row: AlertRow) => {
  if (!row.id) return
  try {
    await updateItem({
      collection: 'Monitoring_alerts',
      id: row.id,
      item: { is_active: row.is_active ? 0 : 1 },
    })
    row.is_active = !row.is_active
  } catch (_e) {}
}

// ─── Delete ───────────────────────────────────────────────────────────────
const deleteAlert = async (row: AlertRow) => {
  if (!row.id) return
  if (!confirm(t('Delete this alert?'))) return
  try {
    await deleteItems({
      collection: 'Monitoring_alerts',
      items: [row.id as string],
    })
    alerts.value = alerts.value.filter((a) => a.id !== row.id)
    toaster.show({
      title: t('Deleted'),
      message: t('Alert deleted'),
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

// ─── Load alert trigger logs ───────────────────────────────────────────────
const loadLogs = async () => {
  if (!props.assetId) return
  logsLoading.value = true
  try {
    const res = await getItems<any>({
      collection: 'Monitoring_alert_logs',
      params: {
        filter: { asset: { _eq: props.assetId } },
        sort: ['-triggered_at'],
        limit: logsPerPage.value,
        page: logsPage.value,
        meta: 'filter_count',
      },
    })
    logs.value = Array.isArray(res) ? res : (res as any)?.data ?? []
    logsTotal.value = Array.isArray(res)
      ? logs.value.length
      : (res as any)?.meta?.filter_count ?? 0
  } catch (_e) {
    logs.value = []
    logsTotal.value = 0
  } finally {
    logsLoading.value = false
  }
}

// Шүүлтүүр/asset солигдох, гараар "Refresh" дарах үед 1-р хуудас руу буцаана
const reloadLogs = () => {
  if (logsPage.value === 1) {
    loadLogs()
  } else {
    logsPage.value = 1
  }
}

watch(logsPage, loadLogs)

// ─── Lifecycle ────────────────────────────────────────────────────────────
onMounted(async () => {
  await loadTrackingFields()
  await loadAlerts()
  await loadLogs()
})

watch(
  () => props.assetId,
  async () => {
    await loadTrackingFields()
    await loadAlerts()
    reloadLogs()
  },
)
</script>

<template>
  <div class="p-4 space-y-4">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <BaseHeading as="h3" size="md" weight="medium">
          {{ t('Monitoring alerts') }}
        </BaseHeading>
        <BaseParagraph size="sm" class="text-muted-400 mt-1">
          {{
            t(
              'Sends popup, sound, and email alerts when a field value exceeds the threshold',
            )
          }}
        </BaseParagraph>
      </div>
      <div class="flex gap-2">
        <BaseButton size="sm" color="muted" @click="loadAlerts">
          <Icon name="ph:arrows-clockwise" class="h-4 w-4 mr-1" />
          {{ t('Refresh') }}
        </BaseButton>
        <BaseButton size="sm" color="primary" @click="openAdd">
          <Icon name="ph:plus" class="h-4 w-4 mr-1" />
          {{ t('Add alert') }}
        </BaseButton>
      </div>
    </div>

    <!-- Tracking fields missing warning -->
    <BaseMessage
      v-if="trackingFields.every((f) => typeof f.id === 'string')"
      type="info"
      icon="ph:info"
    >
      {{
        t(
          'No tracking fields configured in Device Settings — showing default fields',
        )
      }}
    </BaseMessage>

    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center py-10">
      <BaseButtonIcon loading shape="full" size="lg" />
    </div>

    <!-- Empty -->
    <BaseCard
      v-else-if="!loading && alerts.length === 0"
      class="p-8 text-center"
    >
      <Icon
        name="ph:bell-slash"
        class="h-12 w-12 mx-auto mb-3 text-muted-300"
      />
      <BaseParagraph size="sm" class="text-muted-400">
        {{ t('No alerts configured') }}
      </BaseParagraph>
      <BaseButton size="sm" color="primary" class="mt-4" @click="openAdd">
        <Icon name="ph:plus" class="h-4 w-4 mr-1" />
        {{ t('Add alert') }}
      </BaseButton>
    </BaseCard>

    <!-- Alert list -->
    <BaseCard v-else class="overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr
              class="border-b border-muted-200 dark:border-muted-700 bg-muted-50 dark:bg-muted-800"
            >
              <th
                class="px-3 py-2 text-left text-xs font-semibold text-muted-500 uppercase"
              >
                {{ t('Field') }}
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-semibold text-muted-500 uppercase"
              >
                {{ t('Condition') }}
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-semibold text-muted-500 uppercase"
              >
                {{ t('Threshold') }}
              </th>
              <th
                class="px-3 py-2 text-center text-xs font-semibold text-muted-500 uppercase"
              >
                {{ t('Alerts') }}
              </th>
              <th
                class="px-3 py-2 text-center text-xs font-semibold text-muted-500 uppercase"
              >
                {{ t('Active') }}
              </th>
              <th
                class="px-3 py-2 text-center text-xs font-semibold text-muted-500 uppercase"
              >
                {{ t('Action') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-muted-100 dark:divide-muted-800">
            <tr
              v-for="row in alerts"
              :key="row.id"
              class="hover:bg-muted-50 dark:hover:bg-muted-800/50 transition-colors"
              :class="{ 'opacity-50': !row.is_active }"
            >
              <!-- Field -->
              <td class="px-3 py-2">
                <span class="font-medium text-muted-700 dark:text-muted-200">{{
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
              </td>

              <!-- Threshold -->
              <td class="px-3 py-2">
                <span
                  v-if="row.threshold_type !== 'custom'"
                  class="text-xs text-muted-400 mr-1"
                  >{{ row.threshold_type }}</span
                >
                <span class="font-medium">{{ getThresholdLabel(row) }}</span>
              </td>

              <!-- Notifications -->
              <td class="px-3 py-2">
                <div class="flex items-center justify-center gap-2">
                  <span
                    v-if="row.notify_popup"
                    class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-primary-100 dark:bg-primary-900/30 text-primary-600 text-xs"
                    :title="t('Popup notification')"
                  >
                    <Icon name="ph:bell" class="h-3 w-3" />
                    <span class="hidden sm:inline">popup</span>
                  </span>
                  <span
                    v-if="row.notify_sound"
                    class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-warning-100 dark:bg-warning-900/30 text-warning-600 text-xs"
                    :title="t('Sound alert')"
                  >
                    <Icon name="ph:speaker-high" class="h-3 w-3" />
                    <span class="hidden sm:inline">sound</span>
                  </span>
                  <span
                    v-if="row.notify_browser"
                    class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-info-100 dark:bg-info-900/30 text-info-600 text-xs"
                    :title="t('Browser notification')"
                  >
                    <Icon name="ph:monitor" class="h-3 w-3" />
                    <span class="hidden sm:inline">notify</span>
                  </span>
                  <span
                    v-if="row.notify_email"
                    class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-success-100 dark:bg-success-900/30 text-success-600 text-xs"
                    :title="row.email_address || t('Email')"
                  >
                    <Icon name="ph:envelope" class="h-3 w-3" />
                    <span class="hidden sm:inline">email</span>
                  </span>
                </div>
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
                    :class="row.is_active ? 'translate-x-3' : 'translate-x-0'"
                  />
                </button>
              </td>

              <!-- Actions -->
              <td class="px-3 py-2">
                <div class="flex items-center justify-center gap-1">
                  <BaseButtonIcon
                    size="xs"
                    color="muted"
                    @click="openEdit(row)"
                  >
                    <Icon name="ph:pencil-simple" class="h-3.5 w-3.5" />
                  </BaseButtonIcon>
                  <BaseButtonIcon
                    size="xs"
                    color="danger"
                    @click="deleteAlert(row)"
                  >
                    <Icon name="ph:trash" class="h-3.5 w-3.5" />
                  </BaseButtonIcon>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </BaseCard>

    <!-- ── Alert trigger logs ─────────────────────────────────────────────── -->
    <div class="mt-6">
      <div class="mb-2 flex items-center justify-between">
        <BaseHeading as="h4" size="sm" weight="medium">
          {{ t('Alert history') }}
          <span class="ml-1 text-xs text-muted-400">({{ logsTotal }})</span>
        </BaseHeading>
        <BaseButton size="xs" color="muted" @click="reloadLogs">
          <Icon name="ph:arrows-clockwise" class="h-3.5 w-3.5 mr-1" />
          {{ t('Refresh') }}
        </BaseButton>
      </div>

      <div v-if="logsLoading" class="flex items-center justify-center py-6">
        <BaseButtonIcon loading shape="full" size="sm" />
      </div>

      <BaseCard
        v-else-if="!logsTotal"
        class="p-6 text-center text-sm text-muted-400"
      >
        <Icon name="ph:clock-counter-clockwise" class="h-8 w-8 mx-auto mb-2" />
        <div>{{ t('No alert history') }}</div>
      </BaseCard>

      <BaseCard v-else class="overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full text-sm">
            <thead>
              <tr
                class="border-b border-muted-200 dark:border-muted-700 bg-muted-50 dark:bg-muted-800"
              >
                <th
                  class="px-3 py-2 text-left text-xs font-semibold text-muted-500 uppercase"
                >
                  {{ t('Date') }}
                </th>
                <th
                  class="px-3 py-2 text-left text-xs font-semibold text-muted-500 uppercase"
                >
                  {{ t('Field') }}
                </th>
                <th
                  class="px-3 py-2 text-left text-xs font-semibold text-muted-500 uppercase"
                >
                  {{ t('Condition') }}
                </th>
                <th
                  class="px-3 py-2 text-left text-xs font-semibold text-muted-500 uppercase"
                >
                  {{ t('Message') }}
                </th>
                <th
                  class="px-3 py-2 text-center text-xs font-semibold text-muted-500 uppercase"
                >
                  {{ t('Alerts') }}
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-muted-100 dark:divide-muted-800">
              <tr
                v-for="log in logs"
                :key="log.id"
                class="hover:bg-muted-50 dark:hover:bg-muted-800/50"
              >
                <td class="px-3 py-2 text-xs text-muted-500 whitespace-nowrap">
                  {{
                    log.triggered_at
                      ? new Date(log.triggered_at).toLocaleString('mn-MN')
                      : '-'
                  }}
                </td>
                <td class="px-3 py-2">
                  <span class="text-muted-700 dark:text-muted-200">{{
                    log.field_name || log.field_key
                  }}</span>
                  <span class="ml-1 text-xs text-muted-400"
                    >({{ log.field_key }})</span
                  >
                </td>
                <td class="px-3 py-2">
                  <span class="font-mono text-info-500 font-semibold">{{
                    log.condition
                  }}</span>
                  <span class="ml-1 text-xs text-muted-400">{{
                    log.threshold_value ?? log.threshold_type
                  }}</span>
                </td>
                <td class="px-3 py-2 max-w-[220px]">
                  <span class="text-xs text-muted-600 dark:text-muted-300">{{
                    log.message || '—'
                  }}</span>
                </td>
                <td class="px-3 py-2">
                  <div class="flex items-center justify-center gap-1">
                    <Icon
                      v-if="log.notify_popup"
                      name="ph:bell"
                      class="h-3.5 w-3.5 text-primary-500"
                      :title="t('Popup')"
                    />
                    <Icon
                      v-if="log.notify_sound"
                      name="ph:speaker-high"
                      class="h-3.5 w-3.5 text-warning-500"
                      :title="t('Sound')"
                    />
                    <Icon
                      v-if="log.notify_browser"
                      name="ph:bell-ringing"
                      class="h-3.5 w-3.5 text-info-500"
                      :title="t('Browser')"
                    />
                    <Icon
                      v-if="log.notify_email"
                      name="ph:envelope"
                      class="h-3.5 w-3.5 text-success-500"
                      :title="t('Email')"
                    />
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </BaseCard>

      <div v-if="logsTotal > logsPerPage" class="mt-3">
        <BasePagination
          v-model:current-page="logsPage"
          :total-items="logsTotal"
          :item-per-page="logsPerPage"
          :no-router="true"
          rounded="lg"
          class="w-full"
        />
      </div>
    </div>

    <!-- ── Modal ────────────────────────────────────────────────────────── -->
    <TairoModal :open="showModal" size="md" @close="showModal = false">
      <template #header>
        <div
          class="flex items-center gap-2 p-4 border-b border-muted-200 dark:border-muted-700"
        >
          <Icon name="ph:bell-ringing" class="h-5 w-5 text-primary-500" />
          <BaseHeading as="h3" size="sm" weight="semibold">
            {{ editingAlert ? t('Edit alert') : t('Add alert') }}
          </BaseHeading>
        </div>
      </template>

      <div class="p-4 space-y-4">
        <!-- Field selection -->
        <div>
          <label class="block text-xs font-medium text-muted-500 mb-1">{{
            t('Monitoring field')
          }}</label>
          <select
            v-model="form.field_key"
            class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-3 py-2 text-sm text-muted-700 dark:text-muted-200 focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
          >
            <option value="" disabled>{{ t('Select a field') }}</option>
            <option
              v-for="tf in trackingFields"
              :key="tf.field_key"
              :value="tf.field_key"
            >
              {{ tf.field_name_mn }} ({{ tf.field_key }})
              <template v-if="tf.unit"> — {{ tf.unit }}</template>
            </option>
          </select>
        </div>

        <!-- Condition + Threshold row -->
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="block text-xs font-medium text-muted-500 mb-1">{{
              t('Condition')
            }}</label>
            <select
              v-model="form.condition"
              class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-3 py-2 text-sm text-muted-700 dark:text-muted-200 focus:ring-2 focus:ring-primary-500"
            >
              <option
                v-for="opt in conditionOptions"
                :key="opt.value"
                :value="opt.value"
              >
                {{ opt.label }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-xs font-medium text-muted-500 mb-1">{{
              t('Threshold value')
            }}</label>
            <select
              v-model="form.threshold_type"
              class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-3 py-2 text-sm text-muted-700 dark:text-muted-200 focus:ring-2 focus:ring-primary-500"
            >
              <option
                v-for="opt in thresholdTypeOptions"
                :key="opt.value"
                :value="opt.value"
              >
                {{ opt.label }}
              </option>
            </select>
          </div>
        </div>

        <!-- Value1-5 reference display -->
        <div
          v-if="form.field_key && form.threshold_type !== 'custom'"
          class="rounded-lg bg-muted-50 dark:bg-muted-800 p-3"
        >
          <p class="text-xs text-muted-400 mb-2">
            {{ t('Selected field threshold values') }}:
          </p>
          <div v-if="selectedTrackingField" class="flex flex-wrap gap-2">
            <span
              v-for="v in ['value1', 'value2', 'value3', 'value4']"
              :key="v"
              class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-medium transition-colors"
              :class="
                form.threshold_type === v
                  ? 'bg-primary-500 text-white'
                  : 'bg-muted-200 dark:bg-muted-700 text-muted-600 dark:text-muted-300'
              "
            >
              {{ v }}:
              {{ (selectedTrackingField as any)[v] ?? '-' }}
            </span>
          </div>
        </div>

        <!-- Custom value -->
        <div v-if="form.threshold_type === 'custom'">
          <label class="block text-xs font-medium text-muted-500 mb-1">{{
            t('Manually entered threshold value')
          }}</label>
          <input
            v-model.number="form.custom_value"
            type="number"
            class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-3 py-2 text-sm text-muted-700 dark:text-muted-200 focus:ring-2 focus:ring-primary-500"
            :placeholder="t('Enter a numeric value')"
          />
        </div>

        <!-- Alert message -->
        <div>
          <label class="block text-xs font-medium text-muted-500 mb-1">{{
            t('Alert message (optional)')
          }}</label>
          <input
            v-model="form.alert_message"
            type="text"
            class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-3 py-2 text-sm text-muted-700 dark:text-muted-200 focus:ring-2 focus:ring-primary-500"
            :placeholder="t('Leave blank to auto-generate')"
          />
        </div>

        <!-- Notification types -->
        <div>
          <label class="block text-xs font-medium text-muted-500 mb-2">{{
            t('Notification methods')
          }}</label>
          <div class="space-y-2">
            <!-- Popup -->
            <label class="flex items-center gap-3 cursor-pointer">
              <input
                v-model="form.notify_popup"
                type="checkbox"
                class="rounded border-muted-300 text-primary-500 focus:ring-primary-500"
              />
              <div class="flex items-center gap-2">
                <Icon name="ph:bell" class="h-4 w-4 text-primary-500" />
                <span class="text-sm text-muted-700 dark:text-muted-200">{{
                  t('Popup notification (on page)')
                }}</span>
              </div>
            </label>

            <!-- Sound -->
            <label class="flex items-center gap-3 cursor-pointer">
              <input
                v-model="form.notify_sound"
                type="checkbox"
                class="rounded border-muted-300 text-warning-500 focus:ring-warning-500"
              />
              <div class="flex items-center gap-2">
                <Icon name="ph:speaker-high" class="h-4 w-4 text-warning-500" />
                <span class="text-sm text-muted-700 dark:text-muted-200">{{
                  t('Sound alert (every 5-10 seconds)')
                }}</span>
              </div>
            </label>

            <!-- Browser notify -->
            <label class="flex items-center gap-3 cursor-pointer">
              <input
                v-model="form.notify_browser"
                type="checkbox"
                class="rounded border-muted-300 text-info-500 focus:ring-info-500"
              />
              <div class="flex items-center gap-2">
                <Icon name="ph:monitor" class="h-4 w-4 text-info-500" />
                <span class="text-sm text-muted-700 dark:text-muted-200">{{
                  t('Browser Notify (system notification)')
                }}</span>
              </div>
            </label>

            <!-- Email -->
            <label class="flex items-center gap-3 cursor-pointer">
              <input
                v-model="form.notify_email"
                type="checkbox"
                class="rounded border-muted-300 text-success-500 focus:ring-success-500"
              />
              <div class="flex items-center gap-2">
                <Icon name="ph:envelope" class="h-4 w-4 text-success-500" />
                <span class="text-sm text-muted-700 dark:text-muted-200">{{
                  t('Email alert')
                }}</span>
              </div>
            </label>

            <!-- Email address input -->
            <div v-if="form.notify_email" class="ml-7">
              <input
                v-model="form.email_address"
                type="email"
                class="w-full rounded-lg border border-muted-200 dark:border-muted-700 bg-white dark:bg-muted-900 px-3 py-2 text-sm text-muted-700 dark:text-muted-200 focus:ring-2 focus:ring-success-500"
                :placeholder="t('email@example.com')"
              />
            </div>
          </div>
        </div>

        <!-- Active -->
        <label class="flex items-center gap-3 cursor-pointer">
          <input
            v-model="form.is_active"
            type="checkbox"
            class="rounded border-muted-300 text-primary-500 focus:ring-primary-500"
          />
          <span class="text-sm text-muted-700 dark:text-muted-200">{{
            t('Activate alert')
          }}</span>
        </label>
      </div>

      <template #footer>
        <div
          class="p-4 flex justify-end gap-2 border-t border-muted-200 dark:border-muted-700"
        >
          <BaseButton color="muted" @click="showModal = false">{{
            t('Cancel')
          }}</BaseButton>
          <BaseButton color="primary" :loading="saving" @click="saveAlert">
            <Icon name="ph:floppy-disk" class="h-4 w-4 mr-1" />
            {{ t('Save') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>
  </div>
</template>
