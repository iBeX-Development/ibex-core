// FilterNewModalForm.vue болон tab1/tab2/tab3.vue-ийн Огноо шүүлтийн анхны
// (default) утгыг НЭГ л газраас гаргадаг байхын тулд ашиглана. Өмнө нь эдгээр
// файл тус бүр өөрсдөө "сүүлийн N сар" гэдгийг тусад нь тооцоолдог байсан тул
// FilterNewModalForm-ийн модал дээр харагдах анхны огноо болон tab-уудын
// анхны фильтр (хэрэглэгч Filter панель нээж өөрчлөхөөс өмнөх) хоорондоо
// зөрөх эрсдэлтэй байв.
//
// `.toISOString()` нь UTC руу хөрвүүлдэг тул (Монгол UTC+8) `started_at`-ыг
// backend талд naive (timezone-гүй) утга гэж хадгалж/харьцуулдаг тул шөнийн
// цагт өдрийг буруу шилжүүлдэг байсан — иймд local getter-үүдээр гардаг
// toLocalDateStr/toLocalIsoStr-г ашиглана (tab1/tab2/tab3-д адилхан зассан).
export const toLocalDateStr = (d: Date): string => {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

export const toLocalIsoStr = (d: Date): string => {
  const hh = String(d.getHours()).padStart(2, '0')
  const mm = String(d.getMinutes()).padStart(2, '0')
  const ss = String(d.getSeconds()).padStart(2, '0')
  return `${toLocalDateStr(d)}T${hh}:${mm}:${ss}`
}

// Өнөөдрөөс `monthsBack` сарын өмнөх сарын 1-нээс өнөөдөр хүртэлх анхны
// огнооны хязгаарыг буцаана (default: сүүлийн 3 сарын өмнөх сар, өнөөдрийг
// багтаагаад 4 сар).
export function getDefaultDateRange(monthsBack = 3) {
  const today = new Date()
  const from = new Date(today.getFullYear(), today.getMonth() - monthsBack, 1)

  return {
    from: toLocalDateStr(from),
    to: toLocalDateStr(today),
  }
}

type DateInput = Date | string | null | undefined

// tab1/tab2/tab3.vue-ийн load* функцууд бүр `from`/`to` аргументаа Date
// объект эсвэл 'YYYY-MM-DD' string хэлбэрээр хүлээж авдаг бөгөөд, ямар ч утга
// өгөгдөөгүй үед тус бүрдээ өөр өөр hardcode-логдсон "N сарын өмнөх"
// fallback тооцоолдог байсан (9 сар, 4 сар, 6 хоног гэх мэт зөрүүтэй). Одоо
// бүх дуудалт customFrom.value/customTo.value-г тодорхой дамжуулдаг болсон
// тул эдгээр функц зөвхөн ирсэн утгаа Date объект болгож хөрвүүлэхэд
// хангалттай — hardcode fallback шаардлагагүй болсон. `fallback` нь зөвхөн
// хамгаалалт (defensive) болгож үлдээсэн бөгөөд өөрөө getDefaultDateRange()
// рүү тулгуурладаг тул нэг л эх сурвалжтай хэвээр байна.
export function toRangeStart(value: DateInput, fallback?: DateInput): Date {
  if (value instanceof Date) return value
  if (value) return new Date(`${value}T00:00:01`)
  if (fallback instanceof Date) return fallback
  if (fallback) return new Date(`${fallback}T00:00:01`)
  return new Date(`${getDefaultDateRange().from}T00:00:01`)
}

export function toRangeEnd(value: DateInput, fallback?: DateInput): Date {
  if (value instanceof Date) return value
  if (value) return new Date(`${value}T23:59:59`)
  if (fallback instanceof Date) return fallback
  if (fallback) return new Date(`${fallback}T23:59:59`)
  return new Date(`${getDefaultDateRange().to}T23:59:59`)
}
