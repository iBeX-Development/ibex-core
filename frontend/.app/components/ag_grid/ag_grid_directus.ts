const { getItems, deleteItems, updateItem, createItems } = useDirectusItems()
export async function fetchPageData(grid_params) {
  const loading = ref(true)
  const totalItems = ref(0)
  const serverItems = ref([])
  const { params } = useRoute()
  // console.log('grid_params', grid_params)

  const loadItems = async () => {
    loading.value = true
    try {
      const filters = {
        ...(grid_params.filters || {}), // grid_params.filters-ээс нэмэх
      }

      if (grid_params.search && grid_params.search.length > 0) {
        const searchVal = grid_params.search.trim()
        const isNumeric = /^\d+$/.test(searchVal)

        if (grid_params.searchField == 'id') {
          if (isNumeric) {
            filters['wo_number'] = { _eq: Number(searchVal) }
          } else {
            filters['name'] = { _icontains: searchVal }
          }
        } else if (
          grid_params.searchField &&
          grid_params.searchField.includes(',')
        ) {
          // Multiple fields: integer fields use _eq, string fields use _icontains
          const fields = grid_params.searchField.split(',').map((f) => f.trim())
          const integerFields = ['wo_number', 'req_number', 'id']
          const orBranches = []
          for (const f of fields) {
            if (integerFields.includes(f)) {
              if (isNumeric)
                orBranches.push({ [f]: { _eq: Number(searchVal) } })
            } else {
              orBranches.push({ [f]: { _icontains: searchVal } })
            }
          }
          if (orBranches.length > 0) filters['_or'] = orBranches
        } else {
          filters[grid_params.searchField] = { _icontains: searchVal }
        }
      }

      const items = await getItems<any>({
        collection: grid_params.collection,
        params: withCompanyFilter({
          filter: filters,
          meta: 'filter_count',
          limit: grid_params.pageSize,
          page: grid_params.currentPage,
          sort: `${grid_params.sortOrder === 'asc' ? '' : '-'}${
            grid_params.sortField === null ? 'id' : grid_params.sortField
          }`,
          fields: grid_params.fields,
        }),
      })
      //console.log(items)
      serverItems.value = items?.data ? items.data : []
      totalItems.value = items?.meta.filter_count ? items.meta.filter_count : 0
      loading.value = false
    } catch (e) {}
  }

  await loadItems()
  return {
    data: serverItems.value,
    totalCount: totalItems.value,
  }
}
