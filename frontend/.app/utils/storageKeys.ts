// Local storage-д хадгалагддаг key нэрсийг нэг дор төвлөрүүлж, typo-с сэргийлэх зорилготой
export const STORAGE_KEYS = {
  LOCATIONS: 'locations',
  TR_ACTIONS: 'tr_actions',
  WO_ACTIONS: 'wo_actions',
  DASHBOARD: 'dashboard',
  PERMISSIONS: 'location_permissions',
  MENUS: 'menus',
  USER_INFO: 'userInfo',
  MY_ID: 'myId',
  MY_COMPANY_ID: 'myCompanyId',
  COMPANY_INFO: 'comInfo',
} as const

// Logout үед цэвэрлэх бүх local storage key-үүд
export function clearUserStorage() {
  if (import.meta.server) return
  Object.values(STORAGE_KEYS).forEach((key) => {
    if (key === STORAGE_KEYS.COMPANY_INFO) return
    window.localStorage.removeItem(key)
  })
}

// Local storage-аас утга унших нэгдсэн helper (SSR-д аюулгүй)
function getStorageItem(key: string): string | number {
  if (import.meta.server) return 0
  if (key === STORAGE_KEYS.MY_COMPANY_ID) {
    const value = window.localStorage.getItem(key)
    return value ? parseInt(value) : 0
  }
  return window.localStorage.getItem(key) || 0
}

// Local storage-аас JSON утга унших нэгдсэн helper (SSR-д аюулгүй)
function getStorageJson<T = any>(key: string, fallback: T): T {
  if (import.meta.server) return fallback
  try {
    return JSON.parse(window.localStorage.getItem(key) || 'null') ?? fallback
  } catch (_) {
    return fallback
  }
}

// STORAGE_KEYS -ийн key бүрд зориулсан getter функцүүд
export function getMyCompanyId(): string | number {
  return getStorageItem(STORAGE_KEYS.MY_COMPANY_ID)
}

export function getMyId(): string | number {
  return getStorageItem(STORAGE_KEYS.MY_ID)
}

export function getLocations(): string | number {
  return getStorageItem(STORAGE_KEYS.LOCATIONS)
}

export function getTrActions(): string | number {
  return getStorageItem(STORAGE_KEYS.TR_ACTIONS)
}

export function getWoActions(): string | number {
  return getStorageItem(STORAGE_KEYS.WO_ACTIONS)
}

export function getDashboard(): string | number {
  return getStorageItem(STORAGE_KEYS.DASHBOARD)
}

export function getPermissions<T = Record<string, any> | null>(): T {
  return getStorageJson<T>(STORAGE_KEYS.PERMISSIONS, null as T)
}

export function getMenus<T = any[] | null>(): T {
  return getStorageJson<T>(STORAGE_KEYS.MENUS, null as T)
}

export function getUserInfo<T = Record<string, any>>(): T {
  return getStorageJson<T>(STORAGE_KEYS.USER_INFO, {} as T)
}

// Login үед хадгалсан active company-ийн мэдээлэл (нэр, статус, лицензийн огноо гэх мэт)
// Зөвхөн UI төлөвийн зорилготой, аюулгүй байдлын хил биш (Directus permission-оор хамгаалагдана)
export function getCompanyInfo<T = Record<string, any>>(): T {
  return getStorageJson<T>(STORAGE_KEYS.COMPANY_INFO, {} as T)
}
