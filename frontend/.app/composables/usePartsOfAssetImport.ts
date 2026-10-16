import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToaster } from '../../layers/tairo/composables/toaster'

export const usePartsOfAssetImport = () => {
  const { t } = useI18n({ useScope: 'global' })
  const toaster = useToaster()
  const { createItems, getItems, updateItem } = useDirectusItems()
  const myCompanyId = getMyCompanyId()

  const isImporting = ref(false)
  const importProgress = ref(0)

  /**
   * Import parts of asset rows into Asset_Parts table.
   * Each row has: part_number, serial_no, quantity, asset_code
   * Steps:
   *  1. Lookup Part IDs by part_number
   *  2. Lookup Asset IDs by asset_code
   *  3. Upsert Asset_Parts records (update quantity if same part+asset exists, else create)
   */
  const importPartsOfAsset = async (
    rows: Array<{
      location_code?: string
      asset_code: string
      part_number: string
      quantity: number | string
    }>,
    locationId: string | number,
    onSuccess?: () => void | Promise<void>,
  ) => {
    if (!rows || rows.length === 0) {
      toaster.show({
        title: t('Error'),
        message: t('No data to import'),
        color: 'danger',
        icon: 'mdi:alert-circle',
        closable: true,
      })
      return false
    }

    isImporting.value = true
    importProgress.value = 0

    try {
      // Collect unique part_numbers, asset_codes, and location_codes for batch lookup
      const uniquePartNumbers = [
        ...new Set(rows.map((r) => r.part_number).filter(Boolean)),
      ]
      const uniqueAssetCodes = [
        ...new Set(rows.map((r) => r.asset_code).filter(Boolean)),
      ]
      const uniqueLocationCodes = [
        ...new Set(rows.map((r) => r.location_code).filter(Boolean)),
      ]

      // Fetch parts by part_number
      const partsResponse = await getItems({
        collection: 'Parts',
        params: {
          filter: { part_number: { _in: uniquePartNumbers } },
          fields: ['id', 'part_number'],
          limit: -1,
        },
      })

      // Fetch assets by asset_code
      const assetsResponse = await getItems({
        collection: 'Assets',
        params: {
          filter: { asset_code: { _in: uniqueAssetCodes } },
          fields: ['id', 'asset_code'],
          limit: -1,
        },
      })

      // Fetch locations by location_code
      const locationsResponse =
        uniqueLocationCodes.length > 0
          ? await getItems({
              collection: 'Location',
              params: {
                filter: { location_code: { _in: uniqueLocationCodes } },
                fields: ['id', 'location_code'],
                limit: -1,
              },
            })
          : []

      // Build lookup maps
      const partMap = new Map<string, number>()
      ;(partsResponse || []).forEach((p: any) => {
        if (p.part_number) partMap.set(p.part_number.toString().trim(), p.id)
      })

      const assetMap = new Map<string, number>()
      ;(assetsResponse || []).forEach((a: any) => {
        if (a.asset_code) assetMap.set(a.asset_code.toString().trim(), a.id)
      })

      const locationMap = new Map<string, number>()
      ;(locationsResponse || []).forEach((l: any) => {
        if (l.location_code)
          locationMap.set(l.location_code.toString().trim(), l.id)
      })

      const fallbackLocationId = parseInt(locationId as string) || locationId

      // Map rows to Asset_Parts records
      const records: any[] = []
      const skipped: string[] = []

      rows.forEach((row, index) => {
        const partId = partMap.get(row.part_number?.toString().trim())
        const assetId = assetMap.get(row.asset_code?.toString().trim())

        if (!partId) {
          skipped.push(
            `Row ${index + 2}: Part_Number "${row.part_number}" not found`,
          )
          return
        }
        if (!assetId) {
          skipped.push(
            `Row ${index + 2}: Asset_Code "${row.asset_code}" not found`,
          )
          return
        }

        const resolvedLocationId =
          locationMap.get(row.location_code?.toString().trim() ?? '') ??
          fallbackLocationId

        records.push({
          part: partId,
          asset: assetId,
          location: resolvedLocationId,
          quantity: parseFloat(row.quantity as string) || 0,
          status: '1',
          company_id: myCompanyId,
        })
      })

      if (skipped.length > 0) {
        console.warn('Skipped rows during import:', skipped)
      }

      if (records.length === 0) {
        toaster.show({
          title: t('Warning'),
          message: t(
            'No valid records to import. Check Part_Number and Asset_Code values.',
          ),
          color: 'warning',
          icon: 'mdi:alert',
          closable: true,
        })
        return false
      }

      // Fetch existing Asset_Parts records to detect duplicates
      const existingRecords = await getItems({
        collection: 'Asset_Parts',
        params: {
          filter: {
            _or: records.map((r) => ({
              _and: [{ part: { _eq: r.part } }, { asset: { _eq: r.asset } }],
            })),
          },
          fields: ['id', 'part', 'asset', 'quantity'],
          limit: -1,
        },
      })

      const existingMap = new Map<string, any>()
      ;(existingRecords || []).forEach((ex: any) => {
        existingMap.set(`${ex.part}-${ex.asset}`, ex)
      })

      const toCreate: any[] = []
      const toUpdate: Array<{ id: number; quantity: number }> = []

      records.forEach((rec) => {
        const key = `${rec.part}-${rec.asset}`
        const existing = existingMap.get(key)
        if (existing) {
          toUpdate.push({ id: existing.id, quantity: rec.quantity })
        } else {
          toCreate.push(rec)
        }
      })

      // Update existing records
      for (const upd of toUpdate) {
        await updateItem({
          collection: 'Asset_Parts',
          id: upd.id,
          item: { quantity: upd.quantity },
        })
      }

      // Insert new records in batches
      const batchSize = 10
      const totalBatches = Math.ceil(toCreate.length / batchSize)
      const created: any[] = []
      // Asset_Parts create
      for (let i = 0; i < totalBatches; i++) {
        const batch = toCreate.slice(i * batchSize, (i + 1) * batchSize)
        try {
          const response = await createItems({
            collection: 'Asset_Parts',
            items: batch,
          })
          created.push(...response)
          importProgress.value = Math.round(((i + 1) / totalBatches) * 100)
        } catch (batchError: any) {
          console.error(`Error creating batch ${i + 1}:`, batchError)
        }
      }

      const skippedMsg =
        skipped.length > 0 ? ` (${skipped.length} skipped)` : ''
      toaster.show({
        title: t('Success'),
        message: t(
          `${created.length} created, ${toUpdate.length} updated${skippedMsg}`,
        ),
        color: 'success',
        icon: 'mdi:check-circle',
        closable: true,
      })

      if (onSuccess) await onSuccess()

      return {
        success: true,
        created: created.length,
        updated: toUpdate.length,
        skipped: skipped.length,
      }
    } catch (error: any) {
      console.error('Import failed:', error)
      toaster.show({
        title: t('Error'),
        message: error?.message || t('Import failed'),
        color: 'danger',
        icon: 'mdi:alert-circle',
        closable: true,
      })
      return false
    } finally {
      isImporting.value = false
    }
  }

  return {
    isImporting,
    importProgress,
    importPartsOfAsset,
  }
}
