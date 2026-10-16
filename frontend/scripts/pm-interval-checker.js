#!/usr/bin/env node
/**
 * PM Condition Checker
 * --------------------
 * Node.js 18+ (native fetch required)
 *
 * Two trigger modes handled:
 *
 *   threshold_type = 'interval'   (Тоолуортай)
 *     Fires every N units of a cumulative counter (engine_hours, odometer…).
 *     e.g. every 5000 km → oil change PM.
 *     Handles catch-up: creates multiple PMs if several intervals were missed.
 *
 *   threshold_type = 'threshold'  (Тоолуургүй)
 *     Fires once when current sensor value >= threshold_value.
 *     e.g. speed >= 80 km/h → inspection PM.
 *     Won't re-fire until `triggered_at` is cleared (reset by user/workflow).
 *
 * Environment variables:
 *   DIRECTUS_URL    - Base URL of your Directus instance (no trailing slash)
 *   DIRECTUS_TOKEN  - Static admin token
 */

'use strict'

const BASE_URL = (process.env.DIRECTUS_URL || '').replace(/\/$/, '')
const TOKEN = process.env.DIRECTUS_TOKEN || ''

if (!BASE_URL || !TOKEN) {
  console.error(
    '[pm-checker] ERROR: DIRECTUS_URL and DIRECTUS_TOKEN must be set.',
  )
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

// ─── Main logic ───────────────────────────────────────────────────────────────

async function getConfigsByType(type) {
  const fields =
    type === 'interval'
      ? 'id,asset,field_key,pm_name,trigger_interval,last_triggered_value,pm_work_order'
      : 'id,asset,field_key,field,threshold_value,pm_name,triggered_at'

  const qs =
    type === 'interval'
      ? new URLSearchParams({
          'filter[threshold_type][_eq]': 'interval',
          limit: '-1',
          fields,
        })
      : new URLSearchParams({
          'filter[threshold_type][_nin]': 'interval',
          limit: '-1',
          fields,
        })
  return apiGet(`/items/Predictive_tracking_configs?${qs}`)
}

// Keep old name as alias for backward compat
const getIntervalConfigs = () => getConfigsByType('interval')

async function getLatestDatahub(assetId, fieldKey) {
  const qs = new URLSearchParams({
    'filter[asset][_eq]': String(assetId),
    sort: '-timestamp_date',
    limit: '1',
    fields: 'timestamp_date,field_values',
  })
  const rows = await apiGet(`/items/Asset_field_data_json?${qs}`)
  if (!rows || rows.length === 0) return null
  const value = rows[0]?.field_values?.[fieldKey]
  return value != null ? parseFloat(value) : null
}

async function createPMWorkOrder(config, triggeredAtValue) {
  const wo = await apiPost('/items/Predictive', {
    name: `${config.pm_name || 'PM'} @ ${triggeredAtValue}`,
    type: 4,
    pm_type: 'pr_cron',
    created_type: 'pr_cron',
    action_status: 1,
    wo_status: 8, // draft_status_id
    asset: config.asset,
    // Store which value triggered this PM for traceability
    predictive_trigger_value: triggeredAtValue,
    predictive_config: config.id,
  })
  return wo
}

async function processConfig(config) {
  const { id, asset, field_key, trigger_interval, pm_name } = config
  let lastTriggered = parseFloat(config.last_triggered_value) || 0
  const interval = parseFloat(trigger_interval)

  if (!interval || interval <= 0) {
    console.log(
      `[pm-checker] Config #${id}: invalid trigger_interval (${trigger_interval}), skipping.`,
    )
    return
  }

  const currentValue = await getLatestDatahub(asset, field_key)
  if (currentValue === null) {
    console.log(
      `[pm-checker] Config #${id} (asset ${asset}/${field_key}): no Datahub data, skipping.`,
    )
    return
  }

  console.log(
    `[pm-checker] Config #${id} | asset=${asset} | field=${field_key} | current=${currentValue} | lastTriggered=${lastTriggered} | interval=${interval}`,
  )

  let elapsed = currentValue - lastTriggered
  let createdCount = 0

  // Loop to handle catch-up (multiple missed intervals in one run)
  while (elapsed >= interval) {
    const triggerPoint = lastTriggered + interval

    console.log(
      `[pm-checker]   → Creating PM "${pm_name}" at trigger point ${triggerPoint}`,
    )

    try {
      const wo = await createPMWorkOrder(config, triggerPoint)
      console.log(`[pm-checker]   → Created Predictive #${wo?.id}`)
    } catch (err) {
      console.error(
        `[pm-checker]   → Failed to create Predictive: ${err.message}`,
      )
      // Stop processing this config to avoid infinite loop on API failure
      break
    }

    lastTriggered = triggerPoint
    createdCount++

    // Persist updated last_triggered_value after each PM creation
    try {
      await apiPatch(`/items/Predictive_tracking_configs/${id}`, {
        last_triggered_value: lastTriggered,
      })
    } catch (err) {
      console.error(
        `[pm-checker]   → Failed to update last_triggered_value: ${err.message}`,
      )
      break
    }

    elapsed = currentValue - lastTriggered
  }

  if (createdCount > 0) {
    console.log(
      `[pm-checker] Config #${id}: created ${createdCount} PM(s), new lastTriggered=${lastTriggered}`,
    )
  } else {
    console.log(
      `[pm-checker] Config #${id}: no PM needed (elapsed ${elapsed.toFixed(
        2,
      )} < interval ${interval})`,
    )
  }
}

// ─── Threshold (Тоолуургүй) processor ───────────────────────────────────────

async function processThresholdConfig(config) {
  const {
    id,
    asset,
    field_key,
    field,
    threshold_value,
    pm_name,
    triggered_at,
  } = config

  // Already triggered — wait for user to clear triggered_at before re-firing
  if (triggered_at) {
    console.log(
      `[pm-checker] Config #${id} (threshold): already triggered at ${triggered_at}, skipping until reset.`,
    )
    return
  }

  // Read threshold value dynamically from Device_tracking_fields
  if (!field || !threshold_value) {
    console.log(
      `[pm-checker] Config #${id}: missing field or threshold_value key, skipping.`,
    )
    return
  }

  let trackingField
  try {
    trackingField = await apiGet(
      `/items/Device_tracking_fields/${field}?fields=${threshold_value}`,
    )
  } catch (err) {
    console.log(
      `[pm-checker] Config #${id}: failed to fetch Device_tracking_fields/${field}: ${err.message}`,
    )
    return
  }

  const threshold = parseFloat(trackingField[threshold_value])
  if (!threshold && threshold !== 0) {
    console.log(
      `[pm-checker] Config #${id}: invalid threshold value from Device_tracking_fields (${trackingField[threshold_value]}), skipping.`,
    )
    return
  }

  const currentValue = await getLatestDatahub(asset, field_key)
  if (currentValue === null) {
    console.log(
      `[pm-checker] Config #${id} (asset ${asset}/${field_key}): no Datahub data, skipping.`,
    )
    return
  }

  console.log(
    `[pm-checker] Config #${id} | threshold | asset=${asset} | field=${field_key} | current=${currentValue} | threshold=${threshold} (${threshold_value} from Device_tracking_fields#${field})`,
  )

  if (currentValue >= threshold) {
    console.log(
      `[pm-checker]   → ${currentValue} >= ${threshold}, creating PM "${pm_name}"...`,
    )
    try {
      const wo = await createPMWorkOrder(config, currentValue)
      console.log(`[pm-checker]   → Created Predictive #${wo?.id}`)
    } catch (err) {
      console.error(
        `[pm-checker]   → Failed to create Predictive: ${err.message}`,
      )
      return
    }

    try {
      await apiPatch(`/items/Predictive_tracking_configs/${id}`, {
        triggered_at: new Date().toISOString(),
      })
      console.log(
        `[pm-checker]   → Marked triggered_at. Will not re-fire until reset.`,
      )
    } catch (err) {
      console.error(
        `[pm-checker]   → Failed to set triggered_at: ${err.message}`,
      )
    }
  } else {
    console.log(
      `[pm-checker] Config #${id}: ${currentValue} < threshold ${threshold}, no action.`,
    )
  }
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main() {
  console.log(`[pm-checker] Running at ${new Date().toISOString()}`)

  // ── Interval configs (Тоолуортай) ─────────────────────────────────────────
  let intervalConfigs
  try {
    intervalConfigs = await getConfigsByType('interval')
  } catch (err) {
    console.error(
      `[pm-checker] Failed to load interval configs: ${err.message}`,
    )
    intervalConfigs = []
  }

  if (intervalConfigs?.length) {
    console.log(
      `[pm-checker] Processing ${intervalConfigs.length} interval config(s)...`,
    )
    for (const config of intervalConfigs) {
      try {
        await processConfig(config)
      } catch (err) {
        console.error(
          `[pm-checker] Error on interval config #${config.id}: ${err.message}`,
        )
      }
    }
  } else {
    console.log('[pm-checker] No interval configs found.')
  }

  // ── Threshold configs (Тоолуургүй) ────────────────────────────────────────
  let thresholdConfigs
  try {
    thresholdConfigs = await getConfigsByType('threshold')
  } catch (err) {
    console.error(
      `[pm-checker] Failed to load threshold configs: ${err.message}`,
    )
    thresholdConfigs = []
  }

  if (thresholdConfigs?.length) {
    console.log(
      `[pm-checker] Processing ${thresholdConfigs.length} threshold config(s)...`,
    )
    for (const config of thresholdConfigs) {
      try {
        await processThresholdConfig(config)
      } catch (err) {
        console.error(
          `[pm-checker] Error on threshold config #${config.id}: ${err.message}`,
        )
      }
    }
  } else {
    console.log('[pm-checker] No threshold configs found.')
  }

  console.log('[pm-checker] Done.')
}

main().catch((err) => {
  console.error('[pm-checker] Unhandled error:', err)
  process.exit(1)
})
