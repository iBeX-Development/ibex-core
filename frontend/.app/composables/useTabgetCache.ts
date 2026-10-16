// API Call Optimization Composable
// Reduces excessive API calls with debouncing and caching

import { reactive } from 'vue'

const CACHE_TTL_MS = 5 * 60 * 1000 // 5 minutes

// Cache storage
const apiCache = reactive(new Map<string, { data: any; timestamp: number }>())

// Cache hit/miss counters (for getCacheStats)
let cacheHitCount = 0
let cacheMissCount = 0

// Debounce timers for each tab (Record — dynamic tab names, e.g. tab5, need no pre-seeding)
const debounceTimers = reactive<
  Record<string, ReturnType<typeof setTimeout> | null>
>({})

// Callers currently awaiting a pending debounced refresh, per tab — resolved
// together once the (single, latest) timer actually fires. Prevents earlier
// calls from hanging forever when superseded by a newer call before `delay`
// elapses.
type PendingResolver = {
  resolve: (value: any) => void
  reject: (reason: any) => void
}
const pendingResolvers: Record<string, PendingResolver[]> = {}

// Loading states for each tab
export const tabLoadingStates = reactive<Record<string, boolean>>({})

/**
 * Create cache key from filter parameters
 */
function createCacheKey(tabName: string, filterData: any): string {
  const key = {
    tab: tabName,
    checked: filterData.checked,
    location: filterData.location,
    from: filterData.customFrom,
    to: filterData.customTo,
  }
  return JSON.stringify(key)
}

/**
 * Check if data is cached and not expired (5 minutes TTL)
 */
function getCachedData(cacheKey: string) {
  const cached = apiCache.get(cacheKey)
  if (!cached) {
    cacheMissCount++
    return null
  }

  if (Date.now() - cached.timestamp > CACHE_TTL_MS) {
    apiCache.delete(cacheKey)
    cacheMissCount++
    return null
  }

  cacheHitCount++
  return cached.data
}

/**
 * Remove expired entries so the cache doesn't grow unbounded when the same
 * filter combination is never re-requested (and so never re-checked by
 * getCachedData's own lazy expiry check)
 */
function pruneExpiredCache() {
  const now = Date.now()
  for (const [key, value] of apiCache.entries()) {
    if (now - value.timestamp > CACHE_TTL_MS) {
      apiCache.delete(key)
    }
  }
}

/**
 * Cache data with timestamp
 */
function setCachedData(cacheKey: string, data: any) {
  apiCache.set(cacheKey, {
    data,
    timestamp: Date.now(),
  })
  pruneExpiredCache()
}

/**
 * Debounced API call handler
 */
export function useDebouncedTabRefresh(
  tabName: string,
  refreshCallback: (filterData: any) => Promise<any>,
  delay = 300,
) {
  return (filterData: any) => {
    return new Promise<any>((resolve, reject) => {
      // Check cache first — a hit resolves immediately and doesn't touch
      // any pending debounce timer/resolvers
      const cacheKey = createCacheKey(tabName, filterData)
      const cachedData = getCachedData(cacheKey)

      if (cachedData) {
        console.log(`[${tabName}] Using cached data`)
        resolve(cachedData)
        return
      }

      // Clear existing timer — but keep its resolvers, they'll be settled
      // together with this call once the new timer fires
      if (debounceTimers[tabName]) {
        clearTimeout(debounceTimers[tabName]!)
      }

      if (!pendingResolvers[tabName]) pendingResolvers[tabName] = []
      pendingResolvers[tabName].push({ resolve, reject })

      tabLoadingStates[tabName] = true

      debounceTimers[tabName] = setTimeout(async () => {
        const resolvers = pendingResolvers[tabName] ?? []
        pendingResolvers[tabName] = []

        try {
          console.log(`[${tabName}] Making API calls...`)
          const result = await refreshCallback(filterData)

          // Cache the result
          setCachedData(cacheKey, result)

          tabLoadingStates[tabName] = false
          resolvers.forEach((r) => r.resolve(result))
        } catch (error) {
          tabLoadingStates[tabName] = false
          console.error(`[${tabName}] API call failed:`, error)
          resolvers.forEach((r) => r.reject(error))
        }
      }, delay)
    })
  }
}

/**
 * Batch API calls to reduce number of requests
 */
export async function batchApiCalls(calls: Array<() => Promise<any>>) {
  try {
    const results = await Promise.allSettled(calls.map((call) => call()))

    return results.map((result, index) => {
      if (result.status === 'fulfilled') {
        return result.value
      } else {
        console.error(`Batch API call ${index} failed:`, result.reason)
        return null
      }
    })
  } catch (error) {
    console.error('Batch API calls failed:', error)
    throw error
  }
}

/**
 * Clear cache for specific tab or all tabs
 */
export function clearTabCache(tabName?: string) {
  if (tabName) {
    // Clear specific tab cache
    const keysToDelete = Array.from(apiCache.keys()).filter((key) =>
      key.includes(`"tab":"${tabName}"`),
    )

    keysToDelete.forEach((key) => apiCache.delete(key))
    console.log(`Cleared cache for ${tabName}`)
  } else {
    // Clear all cache
    apiCache.clear()
    console.log('Cleared all tab cache')
  }
}

/**
 * Get cache statistics
 */
export function getCacheStats() {
  return {
    totalEntries: apiCache.size,
    cacheHits: cacheHitCount,
    cacheMisses: cacheMissCount,
  }
}
