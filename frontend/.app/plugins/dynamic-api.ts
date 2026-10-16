// Dynamic API URL plugin
// NOTE: Энэ plugin нь domain-оос хамааруулж анхдагч API URL-ийг сонгодог
// Хоёр өөр баазтай ажиллахын тулд useDatabase1() болон useDatabase2() ашигла
export default defineNuxtPlugin({
  name: 'dynamic-api',
  enforce: 'pre', // nuxt-directus module-с өмнө ажиллах ЁСТОЙ
  parallel: false, // Sequential байх - бусад plugin-с өмнө ажиллах
  setup(nuxtApp) {
    const config = useRuntimeConfig()

    // Domain-оос хамааруулж API URL тодорхойлох
    const getDynamicApiUrl = () => {
      if (process.server) {
        console.log(
          `[Dynamic API] Server side - using default: ${
            (config.public.directus as any).url
          }`,
        )
        return (config.public.directus as any).url
      }

      const hostname = window.location.hostname

      // Domain-оос хамааруулж PRIMARY API URL сонгох
      const domainMap: Record<string, string> = {
        'app.ibex.mn': 'https://api.ibex.mn/',
        'smartgps.ibex.mn': 'https://smartgps-admin.ibex.mn/',
        localhost: 'https://api.ibex.mn/',
        '127.0.0.1': 'http://localhost:8056/',
      }

      // Тохирох domain олох, эсвэл default ашиглах
      const apiUrl = domainMap[hostname] || (config.public.directus as any).url

      // console.log(`[Dynamic API] Domain: ${hostname}`)
      // console.log(
      //   `[Dynamic API] Default url: ${(config.public.directus as any).url}`,
      // )
      // console.log(`[Dynamic API] Selected PRIMARY url: ${apiUrl}`)

      return apiUrl
    }

    // Directus module-д dynamic URL нэвтрүүлэх
    const dynamicUrl = getDynamicApiUrl()

    // CRITICAL: Config болон Directus client-ийг шууд солих
    ;(config.public.directus as any).url = dynamicUrl

    // console.log(`[Dynamic API] ✅ Config URL set to: ${dynamicUrl}`)

    // Directus client URL шинэчлэх функц
    const updateDirectusClientUrl = () => {
      if (process.client && nuxtApp.$directus) {
        const directusClient = nuxtApp.$directus as any

        // Update URL - зөвхөн өөр байвал
        if (directusClient.url && directusClient.url !== dynamicUrl) {
          const oldUrl = directusClient.url
          directusClient.url = dynamicUrl
          // console.log(
          //   `[Dynamic API] ⚠️ Directus client URL was ${oldUrl}, changed to: ${dynamicUrl}`,
          // )
        } else if (directusClient.url) {
          console.log(
            `[Dynamic API] ✅ Directus client URL already correct: ${dynamicUrl}`,
          )
        }

        // Update internal client URL
        if (directusClient.client) {
          if (
            directusClient.client.url &&
            directusClient.client.url !== dynamicUrl
          ) {
            const oldUrl = directusClient.client.url
            directusClient.client.url = dynamicUrl
            // console.log(
            //   `[Dynamic API] ⚠️ Directus internal client URL was ${oldUrl}, changed to: ${dynamicUrl}`,
            // )
          } else if (directusClient.client.url) {
            console.log(
              `[Dynamic API] ✅ Directus internal client URL already correct`,
            )
          }
        }
        return true
      }
      return false
    }

    // Hook-үүдээр олон удаа оролдох
    nuxtApp.hook('app:created', () => {
      // console.log('[Dynamic API] Hook: app:created fired')
      if (!updateDirectusClientUrl()) {
        console.log(
          '[Dynamic API] ⚠️ $directus not available yet in app:created',
        )
      }
    })

    nuxtApp.hook('app:mounted', () => {
      // console.log('[Dynamic API] Hook: app:mounted fired')
      if (!updateDirectusClientUrl()) {
        console.log(
          '[Dynamic API_SODOO] ⚠️ $directus not available yet in app:mounted',
        )
      }
    })

    nuxtApp.hook('page:finish', () => {
      // console.log('[Dynamic API] Hook: page:finish fired')
      if (!updateDirectusClientUrl()) {
        console.log(
          '[Dynamic API] ⚠️ $directus not available yet in page:finish',
        )
      }
    })

    // Vue app бэлэн болсны дараа давхар шалгах
    if (process.client) {
      setTimeout(() => {
        // console.log('[Dynamic API] Delayed check after 100ms')
        updateDirectusClientUrl()
      }, 100)

      // CRITICAL FIX: Global fetch interceptor
      // Бүх API request-үүдийг шалгаж, буруу URL байвал засна
      const originalFetch = window.fetch
      window.fetch = function (input: RequestInfo | URL, init?: RequestInit) {
        let url =
          typeof input === 'string'
            ? input
            : input instanceof URL
            ? input.href
            : input.url

        // Хэрэв api.ibex.mn руу явж байвал харин smartgps.ibex.mn domain дээр байгаа бол
        // console.log(
        //   `[window.location.hostname] 🔧 : ${window.location.hostname}`,
        // )
        if (
          url.includes('api.ibex.mn') &&
          window.location.hostname === 'smartgps.ibex.mn'
        ) {
          url = url.replace(
            'https://api.ibex.mn/',
            'https://smartgps-admin.ibex.mn/',
          )
          // console.log(
          //   `[Dynamic API-fetch] 🔧 Window.fetch intercepted and fixed URL to: ${url}`,
          // )

          // URL object бол шинэчлэх
          if (input instanceof URL) {
            input = new URL(url)
          } else if (typeof input !== 'string') {
            input = new Request(url, input)
          } else {
            input = url
          }
        }

        return originalFetch.call(window, input, init)
      }

      // console.log('[Dynamic API] ✅ Global window.fetch interceptor installed')

      // CRITICAL FIX 2: Intercept $fetch from globalThis
      // nuxt-directus uses Nuxt's $fetch which is available on globalThis
      try {
        // Wait for $fetch to be available on globalThis
        const setupFetchInterceptor = () => {
          const globalFetch = (globalThis as any).$fetch
          if (globalFetch && !globalFetch.__intercepted) {
            const originalFetch = globalFetch
            ;(globalThis as any).$fetch = new Proxy(originalFetch, {
              apply(target: any, thisArg: any, argArray: any[]) {
                const [url, options = {}] = argArray

                // Intercept and rewrite URL if needed
                if (
                  typeof url === 'string' &&
                  url.includes('api.ibex.mn') &&
                  window.location.hostname === 'smartgps.ibex.mn'
                ) {
                  const newUrl = url.replace(
                    'https://api.ibex.mn/',
                    'https://smartgps-admin.ibex.mn/',
                  )
                  // console.log(
                  //   `[Dynamic API] 🔧 globalThis.$fetch intercepted: ${url} → ${newUrl}`,
                  // )
                  argArray[0] = newUrl
                }

                return Reflect.apply(target, thisArg, argArray)
              },
            })
            ;(globalThis as any).$fetch.__intercepted = true
            // console.log(
            //   '[Dynamic API] ✅ globalThis.$fetch interceptor installed',
            // )
          }
        }

        // Try immediately
        setupFetchInterceptor()

        // Try again after a delay to catch late initialization
        setTimeout(setupFetchInterceptor, 50)
        setTimeout(setupFetchInterceptor, 200)
      } catch (error) {
        console.error('[Dynamic API] ❌ Failed to intercept $fetch:', error)
      }
    }

    console.log(`[Dynamic API] ✅ PRIMARY Database initialized: ${dynamicUrl}`)
    // console.log(`[Dynamic API] ⚠️  All API calls should use: ${dynamicUrl}`)
    // console.log(
    //   `[Dynamic API] 💡 Use useDatabase1() or useDatabase2() for dual database access`,
    // )

    // Global-д ашиглах
    return {
      provide: {
        apiUrl: dynamicUrl,
        getApiUrl: getDynamicApiUrl,
      },
    }
  },
})
