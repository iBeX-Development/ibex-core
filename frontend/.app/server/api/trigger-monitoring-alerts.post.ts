/**
 * POST /api/trigger-monitoring-alerts
 * 
 * Excel import эсвэл cron data insert дараа frontend-с дуудна.
 * monitoring-alert-checker.js-ийг child_process-оор ажиллуулна.
 * 
 * Body: { assetId?: number }
 */
import { spawn } from 'child_process'
import { resolve } from 'path'

export default defineEventHandler(async (event) => {
  const body = await readBody(event).catch(() => ({}))
  const assetId = body?.assetId ? parseInt(String(body.assetId)) : null

  const scriptPath = resolve(process.cwd(), 'scripts/monitoring-alert-checker.js')

  const env: Record<string, string> = {
    ...process.env,
    DIRECTUS_URL: process.env.DIRECTUS_URL || '',
    DIRECTUS_TOKEN: process.env.DIRECTUS_TOKEN || '',
  }
  if (assetId) {
    env.ALERT_ASSET_ID = String(assetId)
  }

  // Fire-and-forget — import хийсэн хэрэглэгчийг хүлээлгэхгүй
  const child = spawn('node', [scriptPath], {
    env,
    detached: true,
    stdio: ['ignore', 'pipe', 'pipe'],
  })

  child.stdout?.on('data', (d: Buffer) => {
    console.log('[monitoring-trigger]', d.toString().trim())
  })
  child.stderr?.on('data', (d: Buffer) => {
    console.error('[monitoring-trigger]', d.toString().trim())
  })
  child.unref()

  return { ok: true, assetId: assetId ?? 'all' }
})
