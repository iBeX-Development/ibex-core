<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import SubsidebarLocationMenus from './SubsidebarLocationMenus'
const loading = ref(true)
const navigation = ref<any[]>([])
const searchQuery = ref('')

const { getItems } = useDirectusItems()

const CACHE_KEY = 'sidebar_locations_cache_v3'
const CACHE_TTL = 24 * 60 * 60 * 1000 // 24 hours
const myCompanyId = getMyCompanyId()

// packagePermissions доторх тухайн бүлгийн (group id) зөвшөөрөгдсөн id-нууд
// Багц тохируулаагүй/олдоогүй бол null (хязгаарлалтгүй)
const getPackageAllowedIds = (packagePermissions: any[], groupId: number) => {
  const group = (packagePermissions || []).find((p: any) => p.id === groupId)
  if (!group) return null

  return new Set(
    (group.children || [])
      .filter((child: any) => child.is_checked)
      .map((child: any) => child.id),
  )
}

const filterByPackage = (
  items: any[],
  packagePermissions: any[],
  groupId: number,
) => {
  const allowedIds = getPackageAllowedIds(packagePermissions, groupId)
  return allowedIds
    ? (items || []).filter((item: any) => allowedIds.has(item.id))
    : items
}

const loadPackagePermissions = async () => {
  try {
    const companyRes = await getItems({
      collection: 'Companies',
      params: {
        filter: { id: myCompanyId },
        fields: ['id', 'package'],
      },
    })
    const companyData = Array.isArray(companyRes)
      ? companyRes
      : (companyRes as any)?.data ?? []
    const packageId = companyData[0]?.package

    if (!packageId) return []

    const packageRes = await getItems({
      collection: 'Pricing_packages',
      params: {
        filter: { id: packageId },
        fields: ['*'],
      },
    })
    const packageData = Array.isArray(packageRes)
      ? packageRes
      : (packageRes as any)?.data ?? []

    return Array.isArray(packageData[0]?.permissions)
      ? packageData[0].permissions
      : []
  } catch (error) {
    console.error('Unable to load package permissions:', error)
    return []
  }
}

const loadLocation = async () => {
  // 1. Show cached data immediately if available
  const cached = localStorage.getItem(CACHE_KEY)
  if (cached) {
    try {
      const { data, ts } = JSON.parse(cached)
      if (Date.now() - ts < CACHE_TTL) {
        navigation.value = data
        loading.value = false
        return
      }
    } catch (_) {}
  }

  try {
    const locations = window.localStorage.getItem('locations')
    const filters: any = {
      status: '1',
      company_id: myCompanyId,
    }

    if (locations && locations !== '0') {
      filters.id = { _in: locations }
    }

    const items = await getItems<any>({
      collection: 'Location',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*', 'region.*'],
        sort: ['position'],
      },
    })
    const packagePermissions = await loadPackagePermissions()
    const transformed = transformNavigation(items.data, packagePermissions)
    navigation.value = transformed
    // Save to cache
    localStorage.setItem(
      CACHE_KEY,
      JSON.stringify({ data: transformed, ts: Date.now() }),
    )
  } catch (e) {
    console.log(e)
  }
}

const transformNavigation = (items: any[], packagePermissions: any[] = []) => {
  let show_locations: any[] = []
  const permissionsStr =
    window.localStorage.getItem('location_permissions') || '{}'
  const permissions = permissionsStr ? JSON.parse(permissionsStr) : null

  if (permissions && permissions[1] && permissions[1].includes('admin')) {
    show_locations = items
  } else if (permissions && Object.keys(permissions).length) {
    // items-д байгаа байрлалуудыг гүйлгэж үзнэ
    show_locations = items.filter((location: any) => permissions[location.id])
  } else {
    // Хэрэв ямар нэгэн permission байхгүй бол бүх items-г харуулна
    show_locations = items
  }

  const transformed_locations: any[] = show_locations.map((item: any) => {
    return {
      name: item.name,
      id: item.id,
      collection: 'Location',
      icon: 'ph:buildings-duotone',
      children: filterByPackage(
        SubsidebarLocationMenus(item.id),
        packagePermissions,
        3,
      ),

      // children: [
      //   {
      //     name: 'Open Work Orders',
      //     icon: 'octicon:tasklist-16',
      //     to: `/workorder/location/open/${item.id}`,
      //     action: 'create',
      //     collection: 'Work_order',
      //     is_show: hasPermission('Work_order', 'create'),
      //   },
      //   {
      //     name: 'Completed Work Orders',
      //     icon: 'pajamas:task-done',
      //     to: `/workorder/location/completed/${item.id}`,
      //     action: 'read',
      //     collection: 'Work_order',
      //     is_show: hasPermission('Work_order', 'read'),
      //   },
      //   {
      //     name: 'Workorder request list',
      //     icon: 'codicon:git-pull-request-go-to-changes',
      //     to: `/workorder/location/request/${item.id}`,
      //     action: 'read',
      //     collection: 'Work_order',
      //     is_show: hasPermission('Work_order', 'read'),
      //   },
      //   {
      //     name: 'Assets',
      //     icon: 'ph:bank-duotone',
      //     to: `/asset/location/${item.id}`,
      //     action: 'read',
      //     collection: 'Assets',
      //     is_show: hasPermission('Assets', 'read'),
      //   },
      //   {
      //     name: 'Preventative Maintenances',
      //     icon: 'icon-park-outline:schedule',
      //     to: `/pm/location/${item.id}`,
      //     action: 'read',
      //     collection: 'Pm',
      //     is_show: hasPermission('Pm', 'read'),
      //   },
      //   {
      //     name: 'Parts',
      //     icon: 'ic:outline-mark-as-unread',
      //     to: `/parts/location/${item.id}`,
      //     action: 'read',
      //     collection: 'Parts',
      //     is_show: hasPermission('Parts', 'read'),
      //   },
      //   /* {
      //   name: 'Vendors',
      //   icon: 'arcticons:vendora',
      //   to: '/parts',
      // },
      // {
      //   name: 'PO',
      //   icon: 'carbon:purchase',
      //   to: '/po',
      // },
      // {
      //   name: 'Bills',
      //   icon: 'healthicons:bills',
      //   to: '/bills',
      // }*/
      // ],
    }
  })
  if (transformed_locations.length == 0) {
    transformed_locations.unshift({
      name: 'No location',
      icon: 'ph:buildings-duotone',
      to: '/asset/by/',
    })
  }
  return transformed_locations
}

onMounted(async () => {
  loading.value = true
  await loadLocation()
  loading.value = false
})

// Filter navigation based on search query
const filteredNavigation = computed(() => {
  const query = searchQuery.value.toLowerCase().trim()
  console.log('Search Query:', query) // Debugging log
  // If less than 2 characters, show all
  if (query.length < 2) {
    return navigation.value
  }

  return (navigation.value as any[])
    .map((item: any) => {
      console.log('item Query:', item) // Debugging log

      // Check if parent name matches
      const parentMatches = item.name?.toLowerCase().includes(query)

      if (!item.children) {
        return parentMatches ? item : null
      }

      // Filter children based on search query
      const filteredChildren = item.children.filter((child: any) =>
        child.name.toLowerCase().includes(query),
      )

      // Return item if parent matches or has matching children
      if (parentMatches || filteredChildren.length > 0) {
        return {
          ...item,
          children:
            filteredChildren.length > 0 ? filteredChildren : item.children,
        }
      }

      return null
    })
    .filter((item: any): item is Exclude<typeof item, null> => item !== null)
})
</script>

<template>
  <TairoSubsidebar>
    <template #header>
      <TairoSubsidebarHeader />
    </template>

    <template #search>
      <!-- Search Input -->
      <div
        class="SearchInput flex-shrink-0 bg-white dark:bg-muted-800 px-4 py-1 mb-4 border-gray-200 dark:border-muted-700"
      >
        <input
          v-model="searchQuery"
          type="text"
          :placeholder="$t('Name') + '...'"
          class="w-full px-3 py-1 mb-3 rounded-md border border-gray-300 dark:border-muted-600 bg-white dark:bg-muted-900 text-gray-900 dark:text-muted-100 placeholder-gray-500 dark:placeholder-muted-400 focus:outline-none focus:ring-2 focus:ring-primary-500 text-sm"
        />
      </div>
    </template>

    <TairoSubsidebarMenu :navigation="filteredNavigation" />
  </TairoSubsidebar>
</template>
