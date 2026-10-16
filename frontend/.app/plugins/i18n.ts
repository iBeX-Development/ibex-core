import { watch } from 'vue'
import { createI18n } from 'vue-i18n'

import en from '../locales/en.json'

function loadLocaleMessages() {
  return { en } as Record<string, any>
}

export default defineNuxtPlugin(async ({ vueApp }) => {
  const savedLocale =
    (typeof localStorage !== 'undefined' && localStorage.getItem('locale')) ||
    'en'

  const i18n = createI18n({
    legacy: false,
    globalInjection: true,
    locale: savedLocale,
    fallbackLocale: 'en',
    messages: loadLocaleMessages(),
  })

  i18n.global.locale.value = savedLocale as any
  watch(
    () => i18n.global.locale.value,
    (newLocale) => {
      if (typeof localStorage !== 'undefined') {
        localStorage.setItem('locale', newLocale)
      }
    },
  )

  vueApp.use(i18n)

  // Fetch latest translations from API to pick up any keys added at runtime
  // (static imports only reflect the state at build time)
  try {
    const data = await $fetch<Record<string, any>>('/api/translations')
    for (const language of data.config?.languages ?? []) {
      const messages = data[language.code]
      if (messages && Object.keys(messages).length) {
        i18n.global.setLocaleMessage(language.code, messages)
      }
    }
  } catch {
    // silently fall back to static imports
  }

  // Компанийн override орчуулгууд (Translation_overrides) — base дээр нэмж
  // бичнэ (зөвхөн нэвтэрсэн, company_id тохирсон үед)
  if (typeof window !== 'undefined') {
    const companyId = Number(window.localStorage.getItem('myCompanyId'))
    if (companyId) {
      try {
        const { getItems } = useDirectusItems()
        const res = await getItems<any>({
          collection: 'Translation_overrides',
          params: {
            filter: { company_id: { _eq: companyId } },
            fields: ['lang_code', 'key', 'value'],
            limit: -1,
          },
        })
        const rows = Array.isArray(res) ? res : (res as any)?.data ?? []
        const byLang: Record<string, Record<string, string>> = {}
        for (const row of rows) {
          if (!byLang[row.lang_code]) byLang[row.lang_code] = {}
          byLang[row.lang_code][row.key] = row.value
        }
        for (const [lang, overrides] of Object.entries(byLang)) {
          i18n.global.mergeLocaleMessage(lang, overrides)
        }
      } catch {
        // алдаа гарвал base орчуулгаар үлдэнэ
      }
    }
  }
})
