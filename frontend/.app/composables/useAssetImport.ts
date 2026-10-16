import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useToaster } from '../../layers/tairo/composables/toaster'
export const useAssetImport = () => {
  const { t } = useI18n({ useScope: 'global' })
  const toaster = useToaster()
  const { createItems } = useDirectusItems()
  const myCompanyId = getMyCompanyId()

  const isImporting = ref(false)
  const importProgress = ref(0)

  /**
   * Process bulk asset creation from imported Excel data
   * @param assets Array of asset objects to create
   * @param locationId Location ID for the assets
   * @param onSuccess Optional callback to refresh after successful import
   * @returns Promise with import results
   */
  const importAssets = async (
    assets: any[],
    locationId: string | number,
    onSuccess?: () => void | Promise<void>,
  ) => {
    if (!assets || assets.length === 0) {
      toaster.show({
        title: t('Error'),
        message: t('No assets to import'),
        color: 'danger',
        icon: 'mdi:alert-circle',
        closable: true,
      })
      return false
    }

    isImporting.value = true
    importProgress.value = 0

    try {
      // Prepare assets with location and clean up invalid foreign keys
      const assetsToCreate = assets.map((asset) => {
        const prepared: any = {
          ...asset,
          location: parseInt(locationId as unknown as string) || locationId,
          status: asset.status || 1, // Default to active
          company_id: myCompanyId,
        }

        // Remove parent field if it's null, empty, or invalid
        if (
          !prepared.parent ||
          prepared.parent === '' ||
          prepared.parent === 'null'
        ) {
          delete prepared.parent
        }

        // Remove other potentially invalid foreign key fields if empty
        const foreignKeyFields = ['parent', 'category', 'manufacturer']
        foreignKeyFields.forEach((field) => {
          if (
            prepared[field] === '' ||
            prepared[field] === null ||
            prepared[field] === undefined
          ) {
            delete prepared[field]
          }
        })

        return prepared
      })

      // Create assets in batches to avoid overwhelming the API
      const batchSize = 10
      const totalBatches = Math.ceil(assetsToCreate.length / batchSize)
      const results: any[] = []

      console.log(
        `Starting import of ${assetsToCreate.length} assets in ${totalBatches} batches...`,
      )

      for (let i = 0; i < totalBatches; i++) {
        const batch = assetsToCreate.slice(i * batchSize, (i + 1) * batchSize)

        console.log(`Importing batch ${i + 1} of ${totalBatches}...`)
        console.log(`batch batch of ${batch}...`)

        try {
          const response = await createItems({
            collection: 'Assets',
            items: batch,
          })
          results.push(...response)

          // Update progress
          importProgress.value = Math.round(((i + 1) / totalBatches) * 100)
        } catch (batchError: any) {
          console.error(`Error creating batch ${i + 1}:`, batchError)

          // Log detailed error information
          if (batchError.response?.data?.errors) {
            batchError.response.data.errors.forEach((err: any) => {
              console.error(
                `Field: ${err.extensions?.field}, Code: ${err.extensions?.code}, Message: ${err.message}`,
              )
            })
          }

          // Try to handle foreign key errors by removing problematic fields
          if (
            batchError.response?.data?.errors?.[0]?.extensions?.code ===
            'INVALID_FOREIGN_KEY'
          ) {
            const invalidField =
              batchError.response.data.errors[0].extensions.field
            console.warn(`Removing invalid foreign key field: ${invalidField}`)

            const cleanedBatch = batch.map((item) => {
              const copy = { ...item }
              delete copy[invalidField]
              return copy
            })

            try {
              const retryResponse = await createItems({
                collection: 'Assets',
                items: cleanedBatch,
              })
              results.push(...retryResponse)
            } catch (retryError) {
              console.error(`Retry failed for batch ${i + 1}:`, retryError)
            }
          }

          // Continue with next batch instead of failing completely
        }
      }

      // Show success message
      toaster.show({
        title: t('Success'),
        message: t(`${results.length} assets imported successfully`),
        color: 'success',
        icon: 'mdi:check-circle',
        closable: true,
      })

      // Run callback if provided
      if (onSuccess) {
        await onSuccess()
      }

      return true
    } catch (error) {
      console.error('Error importing assets:', error)
      toaster.show({
        title: t('Error'),
        message: t(
          'Error importing assets. Please check the data and try again.',
        ),
        color: 'danger',
        icon: 'mdi:alert-circle',
        closable: true,
      })
      return false
    } finally {
      isImporting.value = false
      importProgress.value = 0
    }
  }

  /**
   * Validate Excel data structure
   * @param data Array of data objects
   * @returns Validation result with errors
   */
  const validateExcelData = (data: any[]) => {
    const errors: string[] = []
    const requiredFields = ['asset_code', 'name', 'reading_type']

    data.forEach((row, index) => {
      const rowNum = index + 2 // +2 for header row and 1-based indexing

      // Check required fields
      requiredFields.forEach((field) => {
        const value = row[field] || row[field.toLowerCase()]
        if (!value || value.toString().trim() === '') {
          errors.push(`Row ${rowNum}: Missing required field "${field}"`)
        }
      })
    })

    return {
      isValid: errors.length === 0,
      errors,
      total: data.length,
    }
  }

  return {
    isImporting,
    importProgress,
    importAssets,
    validateExcelData,
  }
}
