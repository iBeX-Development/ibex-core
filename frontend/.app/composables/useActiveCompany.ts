// 1 user = 1 company бүтэцтэй тул active company нь зөвхөн
// directus_users.company_id-аас гардаг. Энэ composable нь тухайн утгыг
// нэг газраас уншиж, session бүрд тогтвортой ашиглах боломж олгоно.
//
// Чухал: эндэх шалгалтууд бүгд зөвхөн UX-ийн зорилготой (UI state).
// Жинхэнэ security boundary нь Directus талын role/permission filter дээр байх ёстой.

// Company идэвхтэй эсэхийг шалгах (status=1 болон лиценз хугацаа дуусаагүй)
export function isCompanyValid(
  company: Record<string, any> | null | undefined,
): boolean {
  if (!company || !company.id) return false
  if (Number(company.status) !== 1) return false

  const licenseDate = company.license_date
  if (licenseDate) {
    const licenseExpiresAt = new Date(
      /^\d{4}-\d{2}-\d{2}$/.test(licenseDate)
        ? `${licenseDate}T23:59:59.999`
        : licenseDate,
    )
    if (
      !Number.isNaN(licenseExpiresAt.getTime()) &&
      licenseExpiresAt < new Date()
    ) {
      return false
    }
  }

  return true
}

// Session-д хадгалагдсан active company-ийн мэдээллийг унших (зөвхөн UI state)
export function useActiveCompany() {
  const companyId = getMyCompanyId()
  const companyInfo = getCompanyInfo()
  return { companyId, companyInfo }
}

// Company-ийн статус/лиценз шалгалтыг route бүрд биш, зөвхөн тодорхой
// хугацаа тутам сервер лүү явуулах throttle (page navigation болгонд API дуудахгүй байх)
const COMPANY_REVALIDATE_INTERVAL_MS = 5 * 60 * 1000 // 5 минут
const COMPANY_LAST_CHECKED_KEY = 'companyLastCheckedAt'

function shouldRevalidateCompany(): boolean {
  if (import.meta.server) return false
  const lastChecked = Number(
    window.sessionStorage.getItem(COMPANY_LAST_CHECKED_KEY) || 0,
  )
  return Date.now() - lastChecked > COMPANY_REVALIDATE_INTERVAL_MS
}

function markCompanyChecked(): void {
  if (import.meta.server) return
  window.sessionStorage.setItem(COMPANY_LAST_CHECKED_KEY, String(Date.now()))
}

// Login үед компанийг аль хэдийн шалгасан тул middleware дахин шалгах хугацааг
// (throttle-ийг) шинэчилж, ижил company-г давхар API-аар шалгахаас сэргийлнэ.
export function markActiveCompanyChecked(): void {
  markCompanyChecked()
}

// Directus /users/me-ээс ирсэн current user-тэй session дэх myCompanyId-г
// тэнцүүлж, компанийн идэвхтэй эсэхийг сервер талаас дахин шалгана.
// false буцаавал session-г цэвэрлэж, дуудсан тал нь /login руу чиглүүлэх ёстой.
// Сервер лүү хийх бодит шалгалтыг 5 минут тутамд л хийж, бусад navigation дээр
// зөвхөн локал (localStorage) тэнцүүлэлт хийнэ.
export async function validateActiveCompany(
  currentUser: Record<string, any> | null | undefined,
): Promise<boolean> {
  if (import.meta.server) return true

  const myCompanyId = getMyCompanyId()
  const userCompanyId = currentUser?.company_id

  // localStorage гараар/санамсаргүй өөрчлөгдсөн, эсвэл company_id огт
  // байхгүй бол session-г итгэмжлэхгүй.
  if (
    !userCompanyId ||
    !myCompanyId ||
    String(userCompanyId) !== String(myCompanyId)
  ) {
    clearUserStorage()
    return false
  }

  if (!shouldRevalidateCompany()) {
    return true
  }

  try {
    const runtimeConfig = useRuntimeConfig()
    const { token } = useDirectusToken()
    const response = await fetch(
      `${
        runtimeConfig.public.directus.url
      }items/Companies?filter[id][_eq]=${encodeURIComponent(
        String(userCompanyId),
      )}&limit=1&fields=*`,
      { headers: { Authorization: `Bearer ${token.value}` } },
    )
    const json = await response.json()
    const company =
      response.ok && Array.isArray(json.data) ? json.data[0] : null

    // const { getItems } = useDirectusItems()
    // const result = await getItems({
    //   collection: 'Companies',
    //   params: {
    //     filter: { id: { _eq: userCompanyId } },
    //     limit: 1,
    //     fields: ['*'],
    //   },
    // })
    // const company = Array.isArray(result)
    //   ? (result[0] as Record<string, any>)
    //   : null

    if (!isCompanyValid(company)) {
      clearUserStorage()
      return false
    }

    window.localStorage.setItem(
      STORAGE_KEYS.COMPANY_INFO,
      JSON.stringify(company),
    )
    markCompanyChecked()
    return true
  } catch (error) {
    console.error('Error validating active company:', error)
    // Сүлжээний алдаанд шууд unauth хийхгүй, өмнөх cache-ээ ашиглана
    return true
  }
}
