#!/usr/bin/env node
/**
 * Monitoring Alert Checker
 * ------------------------
 * Node.js 18+ (native fetch required)
 *
 * pm2 cron болон Excel/cron import дараа trigger болдог.
 *
 * Горим:
 *  1. Monitoring_alerts-с бүх идэвхтэй alert татна
 *  2. Тус тусын asset-ийн хамгийн сүүлийн Asset_field_data_json авна
 *  3. Device_tracking_fields-с босго утга авна
 *  4. Нөхцөл шалгаж cooldown хангагдсан бол:
 *     - last_triggered шинэчлэх
 *     - Monitoring_alert_logs бүртгэх
 *     - notify_email байвал Directus flow-оор имэйл илгээх
 *
 * Env:
 *   DIRECTUS_URL    - Directus-ийн URL (trailing slash байхгүй)
 *   DIRECTUS_TOKEN  - Static admin token
 *   ALERT_ASSET_ID  - (заавал биш) зөвхөн тухайн asset шалгах
 *
 * Ажиллуулах:
 *   node scripts/monitoring-alert-checker.js
 *   ALERT_ASSET_ID=42 node scripts/monitoring-alert-checker.js
 */

'use strict'

const BASE_URL = (process.env.DIRECTUS_URL || '').replace(/\/$/, '')
const TOKEN = process.env.DIRECTUS_TOKEN || ''
const FILTER_ASSET_ID = process.env.ALERT_ASSET_ID
  ? parseInt(process.env.ALERT_ASSET_ID)
  : null

if (!BASE_URL || !TOKEN) {
  console.error('[monitoring] ERROR: DIRECTUS_URL and DIRECTUS_TOKEN must be set.')
  process.exit(1)
}

const HEADERS = {
  Authorization: `Bearer ${TOKEN}`,
  'Content-Type': 'application/json',
}

// ─── Directus helpers ────────────────────────────────────────────────────────

async function apiGet(path) {
  const res = await fetch(`${BASE_URL}${path}`, { headers: HEADERS })
  if (!res.ok) {
    const body = await res.text()
    throw new Error(`GET ${path} → ${res.status}: ${body}`)
  }
  return (await res.json()).data
}

async function apiPost(path, body) {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'POST',
    headers: HEADERS,
    body: JSON.stringify(body),
  })
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`POST ${path} → ${res.status}: ${text}`)
  }
  return (await res.json()).data
}

async function apiPatch(path, body) {
  const res = await fetch(`${BASE_URL}${path}`, {
    method: 'PATCH',
    headers: HEADERS,
    body: JSON.stringify(body),
  })
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`PATCH ${path} → ${res.status}: ${text}`)
  }
  return (await res.json()).data
}

// ─── Condition check ─────────────────────────────────────────────────────────

function checkCondition(value, condition, threshold) {
  switch (condition) {
    case '>':  return value > threshold
    case '<':  return value < threshold
    case '>=': return value >= threshold
    case '<=': return value <= threshold
    case '=':  return value === threshold
    case '!=': return value !== threshold
    default:   return false
  }
}

function isCooldownOver(lastTriggered, cooldownMinutes) {
  if (!lastTriggered) return true
  const last = new Date(lastTriggered).getTime()
  return Date.now() - last >= cooldownMinutes * 60 * 1000
}

// ─── Data fetchers ────────────────────────────────────────────────────────────

async function loadActiveAlerts() {
  const filterParts = ['filter[is_active][_eq]=true', 'limit=-1',
    'fields=id,asset,field_key,field_name,condition,threshold_type,custom_value,' +
    'notify_popup,notify_sound,notify_browser,notify_email,email_address,' +
    'alert_message,cooldown_minutes,last_triggered']

  if (FILTER_ASSET_ID) {
    filterParts.push(`filter[asset][_eq]=${FILTER_ASSET_ID}`)
  }

  return apiGet(`/items/Monitoring_alerts?${filterParts.join('&')}`)
}

async function fetchLatestFieldValues(assetId) {
  const qs = new URLSearchParams({
    'filter[asset][_eq]': String(assetId),
    sort: '-date_created',
    limit: '1',
    fields: 'field_data',
  })
  const rows = await apiGet(`/items/Asset_field_data_json?${qs}`)
  if (!rows || rows.length === 0) return {}

  const raw = rows[0]?.field_data
  if (!raw) return {}
  const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw
  const result = {}
  for (const [k, v] of Object.entries(parsed)) {
    result[k] = Number(v)
  }
  return result
}

async function fetchFieldThresholds(assetId) {
  const qs = new URLSearchParams({
    'filter[asset][_eq]': String(assetId),
    fields: 'field_key,value1,value2,value3,value4',
    limit: '50',
  })
  const rows = await apiGet(`/items/Device_tracking_fields?${qs}`)
  if (!rows) return {}
  const map = {}
  for (const item of rows) {
    map[item.field_key] = {
      value1: Number(item.value1) || 0,
      value2: Number(item.value2) || 0,
      value3: Number(item.value3) || 0,
      value4: Number(item.value4) || 0,
    }
  }
  return map
}

// ─── Alert trigger ────────────────────────────────────────────────────────────

async function sendEmailViaFlow(alert, value, threshold) {
  if (!alert.email_address) return
  const label = alert.field_name || alert.field_key
  const subject = `[CMMS Alert] ${label} дохиолол`
  const message =
    alert.alert_message ||
    `${label}: ${value} ${alert.condition} ${threshold}`

  try {
    await apiPost('/flows/trigger/monitoring-alert-email', {
      to: alert.email_address,
      subject,
      message,
      asset: alert.asset,
      field: alert.field_key,
      value,
      threshold,
    })
    console.log(`[monitoring]   ✉️  Email sent to ${alert.email_address}`)
  } catch (e) {
    console.warn(`[monitoring]   ⚠️  Email flow failed: ${e.message}`)
  }
}

async function triggerAlert(alert, value, threshold) {
  const label = alert.field_name || alert.field_key
  const message =
    alert.alert_message ||
    `${label}: ${value} ${alert.condition} ${threshold}`

  console.log(
    `[monitoring]   🔔 ALERT #${alert.id} | ${label}: ${value} ${alert.condition} ${threshold} | msg: ${message}`,
  )

  // 1. last_triggered шинэчлэх
  try {
    await apiPatch(`/items/Monitoring_alerts/${alert.id}`, {
      last_triggered: new Date().toISOString(),
    })
  } catch (e) {
    console.warn(`[monitoring]   ⚠️  Failed to update last_triggered: ${e.message}`)
  }

  // 2. Monitoring_alert_logs бүртгэх
  try {
    await apiPost('/items/Monitoring_alert_logs', {
      alert: alert.id,
      asset: alert.asset,
      field_key: alert.field_key,
      field_name: alert.field_name,
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
    })
  } catch (e) {
    console.warn(`[monitoring]   ⚠️  Failed to write alert log: ${e.message}`)
  }

  // 3. Email (server-side сувгаар боломжтой)
  if (alert.notify_email) {
    await sendEmailViaFlow(alert, value, threshold)
  }
}

// ─── Per-asset processing ─────────────────────────────────────────────────────

async function processAsset(assetId, alertsForAsset) {
  const [values, thresholds] = await Promise.all([
    fetchLatestFieldValues(assetId),
    fetchFieldThresholds(assetId),
  ])

  if (Object.keys(values).length === 0) {
    console.log(`[monitoring] Asset ${assetId}: no field data, skipping`)
    return
  }

  for (const alert of alertsForAsset) {
    if (!isCooldownOver(alert.last_triggered, alert.cooldown_minutes || 30)) {
      console.log(
        `[monitoring]   ⏳ Alert #${alert.id} (${alert.field_key}) cooldown not over, skip`,
      )
      continue
    }

    const currentValue = values[alert.field_key]
    if (currentValue === undefined || isNaN(currentValue)) {
      console.log(
        `[monitoring]   — Alert #${alert.id}: field_key "${alert.field_key}" not in latest data`,
      )
      continue
    }

    // Босго тодорхойлно
    let threshold = null
    if (alert.threshold_type === 'custom') {
      threshold = alert.custom_value !== null ? Number(alert.custom_value) : null
    } else {
      const ft = thresholds[alert.field_key]
      if (ft && alert.threshold_type in ft) {
        threshold = ft[alert.threshold_type]
      }
    }

    if (threshold === null || isNaN(threshold)) {
      console.log(
        `[monitoring]   — Alert #${alert.id}: threshold undefined, skip`,
      )
      continue
    }

    if (checkCondition(currentValue, alert.condition, threshold)) {
      await triggerAlert(alert, currentValue, threshold)
    } else {
      console.log(
        `[monitoring]   ✓ Alert #${alert.id} (${alert.field_key}): ${currentValue} ${alert.condition} ${threshold} = false, ok`,
      )
    }
  }
}

// ─── Entry point ──────────────────────────────────────────────────────────────

async function main() {
  console.log(`[monitoring] === Monitoring Alert Checker started at ${new Date().toISOString()} ===`)
  if (FILTER_ASSET_ID) {
    console.log(`[monitoring] Filtering for asset ID: ${FILTER_ASSET_ID}`)
  }

  let alerts
  try {
    alerts = await loadActiveAlerts()
  } catch (e) {
    console.error(`[monitoring] Failed to load alerts: ${e.message}`)
    process.exit(1)
  }

  if (!alerts || alerts.length === 0) {
    console.log('[monitoring] No active alerts found, exiting.')
    return
  }

  console.log(`[monitoring] Loaded ${alerts.length} active alert(s)`)

  // Asset-аар нь бүлэглэх
  const byAsset = {}
  for (const alert of alerts) {
    const aid = String(alert.asset)
    if (!byAsset[aid]) byAsset[aid] = []
    byAsset[aid].push(alert)
  }

  for (const [assetId, assetAlerts] of Object.entries(byAsset)) {
    console.log(`[monitoring] --- Asset ${assetId} (${assetAlerts.length} alert(s)) ---`)
    try {
      await processAsset(assetId, assetAlerts)
    } catch (e) {
      console.error(`[monitoring] Asset ${assetId} error: ${e.message}`)
    }
  }

  console.log(`[monitoring] === Done at ${new Date().toISOString()} ===`)
}

main().catch((e) => {
  console.error('[monitoring] Fatal:', e.message)
  process.exit(1)
})
