// Company-aware Directus items helper (1 user = 1 company).
//
// Зорилго: шинэ record бүр зөв company-д автоматаар үүсэх, list/detail
// request бүрийг tenant-aware болгох. Энэ composable нь бүх createItems/
// getItems дуудлагыг нэг газар төвлөрүүлж, developer шинэ page хийхдээ
// company_id filter мартах эрсдэлийг бууруулна.
//
// Чухал: эдгээр нь зөвхөн клиент талын тохиргоо/UX. Жинхэнэ security
// boundary нь Directus талын role/permission filter дээр байх ёстой.

export interface TenantQueryOptions {
  filter?: Record<string, any>
  [key: string]: any
}

// List/detail/search/export/dashboard query-нд active company filter нэмэх
export function withCompanyFilter(
  query: TenantQueryOptions = {},
): TenantQueryOptions {
  const { companyId } = useActiveCompany()
  if (!companyId) return query

  const { filter, ...rest } = query
  return {
    ...rest,
    filter: filter
      ? { _and: [{ company_id: { _eq: companyId } }, filter] }
      : { company_id: { _eq: companyId } },
  }
}

// Create хийхэд company_id-г автоматаар оноох. Хэрэв дата дээр нь аль хэдийн
// company_id тодорхой заасан бол (жишээ нь platform admin company сонгосон)
// түүнийг дарж бичихгүй.
export function withCompanyId<T extends Record<string, any>>(data: T): T {
  const { companyId } = useActiveCompany()
  if (!companyId) return data
  if (data.company_id !== undefined && data.company_id !== null) return data
  return { ...data, company_id: companyId }
}

// Тухайн record идэвхтэй company-д харьяалагдаж байгаа эсэхийг шалгах
// (detail route нээх, share/export хийхийн өмнө ашиглана)
export function belongsToActiveCompany(
  record: Record<string, any> | null | undefined,
): boolean {
  const { companyId } = useActiveCompany()
  if (!record || !companyId) return false
  return String(record.company_id) === String(companyId)
}

export function useTenantItems() {
  const { getItems, createItems, updateItem, deleteItems } = useDirectusItems()

  // Стандартчилсан list/search/export/dashboard тоолуур - company scope-той
  const getTenantItems = (
    options: { collection: string } & TenantQueryOptions,
  ) => {
    const { collection, ...query } = options
    return getItems({ collection, ...withCompanyFilter(query) })
  }

  // Стандартчилсан create helper - company_id автоматаар орно
  const createTenantItems = (options: {
    collection: string
    items: Record<string, any> | Record<string, any>[]
    [key: string]: any
  }) => {
    const items = Array.isArray(options.items)
      ? options.items.map(withCompanyId)
      : withCompanyId(options.items)
    return createItems({ ...options, items })
  }

  // Update дээр company_id-г client талаас өөрчлөх боломжгүй болгох
  // (record-ийн company_id нь immutable байх ёстой)
  const updateTenantItem = (options: {
    collection: string
    id: string | number
    item: Record<string, any>
    [key: string]: any
  }) => {
    const { company_id: _companyId, ...safeItem } = options.item || {}
    return updateItem({ ...options, item: safeItem })
  }

  return {
    getTenantItems,
    createTenantItems,
    updateTenantItem,
    deleteItems,
    withCompanyFilter,
    withCompanyId,
    belongsToActiveCompany,
  }
}
