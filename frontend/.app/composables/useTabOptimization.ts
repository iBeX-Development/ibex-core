// API Call Optimization Composable
// Reduces excessive API calls with debouncing

import { reactive } from 'vue'

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
 * Debounced API call handler
 *
 * Никогда кэшлэдэггүй — checked/location/date шүүлтүүд ажлын захиалгын
 * төлөв шиг байнга өөрчлөгддөг реалтайм өгөгдөл дээр ажилладаг тул ижил
 * filter комбинацаар дахин хүсэлт хийхэд ХАМГИЙН СҮҮЛИЙН өгөгдлийг үзүүлэх
 * ёстой, хуучин (кэшлэгдсэн) хариултыг биш.
 */
export function useDebouncedTabRefresh(
  tabName: string,
  refreshCallback: (filterData: any) => Promise<any>,
  delay = 300,
) {
  return (filterData: any) => {
    return new Promise<any>((resolve, reject) => {
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
