/**
 * Excel to Asset Mapping Utility
 * Handles conversion of Excel data to Asset object format
 */

export interface AssetDataMap {
  asset_code?: string
  name?: string
  location?: string | number
  reading_type?: string
  serial_number?: string
  department?: string | number
  asset_type?: string
  manufacturer?: string
  status?: number
  purchase_cost?: number
  available_hour?: number
  parent?: string | number
  model_number?: string
  [key: string]: any
}

export interface ExcelColumnMapping {
  [excelColumn: string]: string // Maps Excel column name to Asset field name
}

/**
 * Default mapping for common Excel column names to Asset fields
 */
export const DEFAULT_COLUMN_MAPPING: ExcelColumnMapping = {
  // Excel column headers (exact matches)
  number: '', // Ignore row number
  asset_code: 'asset_code',
  Asset_code: 'asset_code',
  'Asset Code': 'asset_code',
  CODE: 'asset_code',
  Code: 'asset_code',

  name: 'name',
  Name: 'name',
  asset_name: 'name',
  Asset_name: 'name',
  'Asset Name': 'name',

  reading_type: 'reading_type',
  Reading_type: 'reading_type',
  'Reading Type': 'reading_type',
  Type: 'reading_type',

  serial_number: 'serial_number',
  Serial_number: 'serial_number',
  serial: 'serial_number',
  Serial: 'serial_number',
  SERIAL: 'serial_number',
  'Serial Number': 'serial_number',

  manufacturer: 'manufacturer',
  Manufacturer: 'manufacturer',
  Mfg: 'manufacturer',

  department: 'department',
  Department: 'department',

  asset_type: 'asset_type',
  Asset_type: 'asset_type',
  'Asset Type': 'asset_type',

  status: 'status',
  Status: 'status',

  purchase_cost: 'purchase_cost',
  'Purchase Cost': 'purchase_cost',

  available_hour: 'available_hour',
  'Available Hour': 'available_hour',

  model_number: 'model_number',
  'Model Number': 'model_number',

  child: 'parent',
  Child: 'parent',
  parent: 'parent',
  Parent: 'parent',
  'Parent Asset': 'parent',

  location: 'location',
}

/**
 * Map Excel row to Asset object based on field definitions
 * @param row Raw Excel row data
 * @param fields Field definitions with name and type
 * @param locationId Location ID for the asset
 * @returns Mapped asset object
 */
export const mapExcelRowToAsset = (
  row: any,
  locationId: string | number,
  fields: any[] = [],
): AssetDataMap => {
  const asset: AssetDataMap = {
    location: parseInt(locationId as unknown as string) || locationId,
    status: 1, // Default to active
  }

  // If fields provided, use them for mapping
  if (fields && fields.length > 0) {
    fields.forEach((field) => {
      const value = row[field.name] || row[field.name?.toLowerCase()]

      if (value !== undefined && value !== null && value !== '') {
        // Handle different field types
        switch (field.type || 'text') {
          case 'number':
            asset[field.name] = parseFloat(value)
            break
          default:
            asset[field.name] = String(value).trim()
        }
      }
    })
  }

  // Fallback: use all row data as-is if no fields defined
  if (!fields || fields.length === 0) {
    Object.entries(row).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        asset[key] = String(value).trim()
      }
    })
  }

  return asset
}

/**
 * Map status value to standard format (0 = Inactive, 1 = Active)
 */
export const mapStatus = (value: any): number => {
  if (typeof value === 'number') {
    return value === 0 ? 0 : 1
  }

  const strValue = String(value).toLowerCase().trim()
  if (
    strValue === 'active' ||
    strValue === '1' ||
    strValue === 'yes' ||
    strValue === 'true'
  ) {
    return 1
  }
  if (
    strValue === 'inactive' ||
    strValue === '0' ||
    strValue === 'no' ||
    strValue === 'false'
  ) {
    return 0
  }

  return 1 // Default to active
}

/**
 * @deprecated Use fields-based validation in component instead
 * Validate Excel row data
 * @param row Excel row data
 * @param requiredFields List of required field names
 * @param mapping Optional column mapping
 * @returns Validation result
 */
export const validateAssetRow = (
  row: any,
  requiredFields: string[] = ['asset_code', 'name', 'reading_type'],
  mapping?: ExcelColumnMapping,
): { isValid: boolean; errors: string[] } => {
  const errors: string[] = []

  requiredFields.forEach((field) => {
    let value: any

    // If mapping provided, find the Excel column that maps to this field
    if (mapping) {
      const excelCol = Object.keys(mapping).find(
        (col) => mapping[col] === field,
      )
      if (excelCol) {
        value = row[excelCol] || row[excelCol.toLowerCase()]
      }
    }

    // Fallback: check by field name variations
    if (!value) {
      const foundKey = Object.keys(row).find(
        (k) => k.toLowerCase() === field.toLowerCase(),
      )
      value =
        row[field] ||
        row[field.toUpperCase()] ||
        row[field.toLowerCase()] ||
        (foundKey ? row[foundKey] : undefined)
    }

    if (!value || String(value).trim() === '') {
      errors.push(`Missing required field: ${field}`)
    }
  })

  return {
    isValid: errors.length === 0,
    errors,
  }
}

/**
 * @deprecated Use explicit fields definition instead
 * Build a custom mapping based on Excel headers detected
 * @param headers Excel headers from first row
 * @returns Auto-detected column mapping
 */
export const autoDetectColumnMapping = (
  headers: string[],
): ExcelColumnMapping => {
  const mapping: ExcelColumnMapping = {}

  headers.forEach((header) => {
    const normalized = header.toLowerCase().trim()

    // Exact matches first (priority)
    if (normalized === 'number') {
      mapping[header] = '' // Ignore row number
    } else if (normalized === 'asset_code') {
      mapping[header] = 'asset_code'
    } else if (normalized === 'name') {
      mapping[header] = 'name'
    } else if (normalized === 'reading_type') {
      mapping[header] = 'reading_type'
    } else if (normalized === 'serial_number') {
      mapping[header] = 'serial_number'
    } else if (normalized === 'child') {
      mapping[header] = 'parent'
    } else if (normalized === 'location') {
      mapping[header] = 'location'
    } else if (normalized === 'model_number') {
      mapping[header] = 'model_number'
    } else if (normalized === 'purchase_cost') {
      mapping[header] = 'purchase_cost'
    }
    // Fuzzy matches (fallback)
    else if (
      normalized.includes('code') ||
      normalized.includes('asset code') ||
      normalized === 'acc-001'
    ) {
      mapping[header] = 'asset_code'
    } else if (
      normalized.includes('asset name') ||
      normalized.includes('asset_name')
    ) {
      mapping[header] = 'name'
    } else if (
      normalized.includes('reading') ||
      normalized.includes('type') ||
      normalized.includes('reading_type')
    ) {
      mapping[header] = 'reading_type'
    } else if (normalized === 'serial' || normalized.includes('serial')) {
      mapping[header] = 'serial_number'
    } else if (
      normalized.includes('manufacturer') ||
      normalized.includes('mfg')
    ) {
      mapping[header] = 'manufacturer'
    } else if (normalized.includes('department')) {
      mapping[header] = 'department'
    } else if (normalized.includes('asset') && normalized.includes('type')) {
      mapping[header] = 'asset_type'
    } else if (normalized.includes('status')) {
      mapping[header] = 'status'
    } else if (normalized.includes('cost') || normalized.includes('price')) {
      mapping[header] = 'purchase_cost'
    } else if (normalized.includes('hour')) {
      mapping[header] = 'available_hour'
    } else if (normalized === 'model_number' || normalized.includes('model')) {
      mapping[header] = 'model_number'
    } else if (normalized.includes('parent')) {
      mapping[header] = 'parent'
    }
  })

  return mapping
}

/**
 * Export asset object to Excel format (for download)
 */
export const exportAssetsToExcel = (assets: AssetDataMap[]) => {
  const headers = [
    'Asset_code',
    'Asset_name',
    'Reading_type',
    'Serial',
    'Manufacturer',
    'Department',
    'Status',
  ]

  const rows = assets.map((asset) => [
    asset.asset_code || '',
    asset.name || '',
    asset.reading_type || '',
    asset.serial_number || '',
    asset.manufacturer || '',
    asset.department || '',
    asset.status === 1 ? 'Active' : 'Inactive',
  ])

  return [headers, ...rows]
}
