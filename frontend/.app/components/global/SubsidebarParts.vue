<script setup lang="ts">
import { onMounted, ref } from 'vue'

const isSmartGPS =
  process.client && window.location.hostname === 'smartgps.ibex.mn'

const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const CACHE_KEY = 'sidebar_inventory'
const CACHE_TTL = 24 * 60 * 60 * 1000 // 24 hours
// Pricing_packages.permissions доторх "Inventory" бүлгийн id
// (DemoPackagePermissionMore.vue-той тохирсон)
const PACKAGE_GROUP_ID = 8

const baseInventories = [
  {
    name: 'Budgets',
    is_open: true,
    children: [
      {
        name: 'Budget List',
        icon: 'mdi:cash-multiple',
        to: '/budgets',
        action: 'read',
        collection: 'Budget',
      },
    ],
  },
  {
    name: 'Item list',
    is_open: true,
    children: [
      {
        name: 'Parts list',
        icon: 'prime:list',
        to: '/parts/list',
        action: 'read',
        collection: 'Parts',
      },
      {
        name: 'Warehouse',
        icon: 'mdi:warehouse',
        to: '/warehouse',
        action: 'read',
        collection: 'Warehouse',
      },
    ],
  },
  {
    name: 'Transaction',
    is_open: true,
    children: [
      {
        name: 'Income',
        icon: 'material-symbols-light:arrow-circle-right-outline-rounded',
        to: '/transaction/income',
        action: 'read',
        collection: 'Transaction',
      },
      {
        name: 'Debt',
        icon: 'material-symbols-light:arrow-circle-left-outline-rounded',
        to: '/transaction/outcome',
        action: 'read',
        collection: 'Transaction',
      },
    ],
  },
]

const navigation = ref<any[]>(baseInventories)
const props = defineProps(['filter'])

// packagePermissions доторх тухайн бүлгийн (group id) зөвшөөрөгдсөн нэрс
// Эдгээр item-үүд id-гүй тул name-ээр match хийнэ.
// Багц тохируулаагүй/олдоогүй бол null (хязгаарлалтгүй)
const getPackageAllowedNames = (packagePermissions: any[], groupId: number) => {
  const group = (packagePermissions || []).find((p: any) => p.id === groupId)
  if (!group) return null

  return new Set(
    (group.children || [])
      .filter((child: any) => child.is_checked)
      .map((child: any) => child.name),
  )
}

const filterByPackage = (
  categories: any[],
  packagePermissions: any[],
  groupId: number,
) => {
  const allowedNames = getPackageAllowedNames(packagePermissions, groupId)
  if (!allowedNames) return categories

  return categories
    .map((category) => ({
      ...category,
      children: (category.children || []).filter((child: any) =>
        allowedNames.has(child.name),
      ),
    }))
    .filter((category) => category.children.length > 0)
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
        fields: ['id', 'permissions'],
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

// login.vue-с role-ийн Inventory (id=8) сонголтоор хадгалсан зөвшөөрөгдсөн
// нэрсийн жагсаалт. Байхгүй бол role хязгаарлалтгүй (Package зөвшөөрөл
// дангаараа хүчинтэй байна).
const filterByRole = (categories: any[]) => {
  let allowedNames: string[] | null = null
  try {
    const raw = localStorage.getItem('role_inventory')
    allowedNames = raw ? JSON.parse(raw) : null
  } catch (_) {
    allowedNames = null
  }
  if (!allowedNames) return categories

  const allowedSet = new Set(allowedNames)
  return categories
    .map((category) => ({
      ...category,
      children: (category.children || []).filter((child: any) =>
        allowedSet.has(child.name),
      ),
    }))
    .filter((category) => category.children.length > 0)
}

const loadNavigation = async () => {
  const cached = localStorage.getItem(CACHE_KEY)
  if (cached) {
    try {
      const { data, ts } = JSON.parse(cached)
      if (Date.now() - ts < CACHE_TTL) {
        navigation.value = data
        return
      }
    } catch (_) {}
  }

  const packagePermissions = await loadPackagePermissions()
  const transformed = filterByRole(
    filterByPackage(baseInventories, packagePermissions, PACKAGE_GROUP_ID),
  )

  navigation.value = transformed
  localStorage.setItem(
    CACHE_KEY,
    JSON.stringify({ data: transformed, ts: Date.now() }),
  )
}

onMounted(loadNavigation)
</script>

<template>
  <TairoSubsidebar>
    <template #header>
      <TairoSubsidebarHeader />
    </template>

    <TairoSubsidebarMenu :navigation="(navigation as any)" />
  </TairoSubsidebar>
</template>
