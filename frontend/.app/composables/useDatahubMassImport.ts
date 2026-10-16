import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToaster } from '../../layers/tairo/composables/toaster'

export interface AssetImportResult {
  asset_code: string
  asset_id: number | null
  total_rows: number
  inserted: number
  skipped_duplicate: number
  skipped_no_asset: number
  error?: string
}

export const useDatahubMassImport = () => {
  const { t } = useI18n({ useScope: 'global' })
  const toaster = useToaster()
  const { createItems, getItems } = useDirectusItems()
  const myCompanyId = getMyCompanyId()

  const isImporting = ref(false)
  const progress = ref(0)
  const currentAsset = ref('')
  const results = ref<AssetImportResult[]>([])

  /**
   * Parse a timestamp value from any format to { unix (seconds), iso }
   */
  function parseTimestamp(value: any): { unix: number; iso: string } | null {
    if (!value && value !== 0) return null
    const str = String(value).trim()

    // Try numeric (unix seconds or ms)
    const num = Number(str)
    if (!isNaN(num) && num > 0) {
      if (num > 946684800 && num < 9999999999) {
        // seconds
        return {
          unix: Math.floor(num),
          iso: new Date(num * 1000).toISOString(),
        }
      } else if (num > 946684800000) {
        // milliseconds
        return {
          unix: Math.floor(num / 1000),
          iso: new Date(num).toISOString(),
        }
      }
    }

    // Try date string
    const d = new Date(str)
    if (!isNaN(d.getTime())) {
      return { unix: Math.floor(d.getTime() / 1000), iso: d.toISOString() }
    }

    return null
  }

  /**
   * Mass import datahub data.
   * @param sheets - array of { assetCode, rows: Record<string,any>[] }
   *   Each sheet is one asset. rows come from Excel sheet parsing.
   *   Each row must have a timestamp/dated_time column.
   */
  const massImport = async (
    sheets: Array<{ assetCode: string; rows: Record<string, any>[] }>,
  ) => {
    if (!sheets || sheets.length === 0) {
      toaster.show({
        title: t('Error'),
        message: t('No data to import'),
        color: 'danger',
        icon: 'mdi:alert-circle',
        closable: true,
      })
      return []
    }

    isImporting.value = true
    progress.value = 0
    results.value = []

    try {
      // 1. Fetch all assets referenced in the sheets
      const uniqueCodes = [
        ...new Set(sheets.map((s) => s.assetCode).filter(Boolean)),
      ]
      const assetsResponse = await getItems({
        collection: 'Assets',
        params: {
          filter: { asset_code: { _in: uniqueCodes } },
          fields: ['id', 'asset_code'],
          limit: -1,
        },
      })

      const assetMap = new Map<string, number>()
      ;(assetsResponse || []).forEach((a: any) => {
        if (a.asset_code) assetMap.set(a.asset_code.toString().trim(), a.id)
      })

      const allResults: AssetImportResult[] = []
      const allSessionItems: any[] = [] // collect across all assets for one history record

      for (let si = 0; si < sheets.length; si++) {
        const { assetCode, rows } = sheets[si]
        currentAsset.value = assetCode
        progress.value = Math.round((si / sheets.length) * 100)

        const result: AssetImportResult = {
          asset_code: assetCode,
          asset_id: null,
          total_rows: rows.length,
          inserted: 0,
          skipped_duplicate: 0,
          skipped_no_asset: 0,
        }

        const assetId = assetMap.get(assetCode?.trim())
        if (!assetId) {
          result.skipped_no_asset = rows.length
          result.error = `Asset "${assetCode}" not found`
          allResults.push(result)
          continue
        }
        result.asset_id = assetId

        // 2. Parse timestamps from rows
        const parsed: Array<{ unix: number; iso: string; fieldValues: any }> =
          []
        for (const row of rows) {
          const tsRaw =
            row['timestamp'] ??
            row['dated_time'] ??
            row['epochtime'] ??
            row['Timestamp'] ??
            row['EpochTime']
          const ts = parseTimestamp(tsRaw)
          if (!ts) continue

          // Build field_values — skip metadata/identifier columns
          const SKIP_KEYS = new Set([
            'timestamp',
            'dated_time',
            'epochtime',
            'Timestamp',
            'EpochTime',
            'dated_Time',
            'Location_Code',
            'location_code',
            'Asset_Code',
            'asset_code',
          ])
          const fieldValues: any = { dated_time: ts.iso }
          for (const [key, val] of Object.entries(row)) {
            if (!SKIP_KEYS.has(key)) {
              fieldValues[key] = val
            }
          }
          parsed.push({ unix: ts.unix, iso: ts.iso, fieldValues })
        }

        if (parsed.length === 0) {
          result.error = 'No valid timestamps found'
          allResults.push(result)
          continue
        }

        // 3. Check existing records to avoid duplicates (by asset + timestamp)
        const unixValues = parsed.map((p) => p.unix)
        const existingResponse = await getItems({
          collection: 'Asset_field_data_json',
          params: {
            filter: {
              asset: { _eq: assetId },
              timestamp: { _in: unixValues },
            },
            fields: ['timestamp'],
            limit: -1,
          },
        })

        const existingTimestamps = new Set<number>(
          (existingResponse || []).map((e: any) => Number(e.timestamp)),
        )

        // 4. Filter out duplicates
        const toInsert = parsed.filter((p) => {
          if (existingTimestamps.has(p.unix)) {
            result.skipped_duplicate++
            return false
          }
          return true
        })

        if (toInsert.length === 0) {
          allResults.push(result)
          continue
        }

        // 5. Insert in batches of 20
        const allInsertedItems: any[] = []
        const batchSize = 20
        for (let i = 0; i < toInsert.length; i += batchSize) {
          const batch = toInsert.slice(i, i + batchSize).map((p) => ({
            asset: assetId,
            timestamp: p.unix,
            timestamp_date: p.iso,
            field_values: p.fieldValues,
            import_source: 'mass_excel',
            company_id: myCompanyId,
          }))
          try {
            await createItems({
              collection: 'Asset_field_data_json',
              items: batch,
            })
            result.inserted += batch.length
            allInsertedItems.push(...batch)
          } catch (e: any) {
            console.error(`Batch error for ${assetCode}:`, e)
          }
        }

        allSessionItems.push(...allInsertedItems)
        allResults.push(result)
      }

      results.value = allResults
      progress.value = 100

      // Save ONE Datahub_history record for the entire import session
      if (allSessionItems.length > 0) {
        try {
          await createItems({
            collection: 'Datahub_history',
            items: [
              {
                snapshot_type: 'mass_excel_import',
                snapshot_at: new Date().toISOString(),
                data_snapshot: allSessionItems,
                source: 'mass_excel',
                record_count: allSessionItems.length,
                company_id: myCompanyId,
              },
            ],
          })
        } catch (e: any) {
          console.warn('Datahub_history snapshot failed:', e)
        }
      }

      const totalInserted = allResults.reduce((s, r) => s + r.inserted, 0)
      const totalDup = allResults.reduce((s, r) => s + r.skipped_duplicate, 0)

      toaster.show({
        title: t('Success'),
        message: t(`${totalInserted} inserted, ${totalDup} duplicates skipped`),
        color: 'success',
        icon: 'mdi:check-circle',
        closable: true,
      })

      return allResults
    } catch (error: any) {
      console.error('Mass import failed:', error)
      toaster.show({
        title: t('Error'),
        message: error?.message || t('Import failed'),
        color: 'danger',
        icon: 'mdi:alert-circle',
        closable: true,
      })
      return []
    } finally {
      isImporting.value = false
      currentAsset.value = ''
    }
  }

  return {
    isImporting,
    progress,
    currentAsset,
    results,
    massImport,
  }
}
