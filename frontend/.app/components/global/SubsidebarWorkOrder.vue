<script setup lang="ts">
import { onMounted, ref } from 'vue'

const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const CACHE_KEY = 'sidebar_shared'
const CACHE_TTL = 24 * 60 * 60 * 1000 // 24 hours
// Pricing_packages.permissions доторх "Shared sections" бүлгийн id
// (DemoPackagePermissionMore.vue-той тохирсон)
const PACKAGE_GROUP_ID = 7

const baseCategories = [
  {
    name: 'Works',
    is_open: true,
    children: [
      {
        name: 'Requests',
        icon: 'codicon:git-pull-request-go-to-changes',
        to: '/works/requests',
        action: 'read',
        collection: 'Work_order',
      },
      {
        name: 'Work Orders',
        icon: 'octicon:tasklist-16',
        to: '/works/workorders',
        action: 'read',
        collection: 'Work_order',
        exact: true,
      },
      {
        name: 'Completed Works',
        icon: 'mdi:check-all',
        to: '/works/completed',
        action: 'read',
        collection: 'Work_order',
      },
      {
        name: 'All Works',
        icon: 'fluent:briefcase-search-24-regular',
        to: '/works/allworks',
        action: 'read',
        collection: 'Work_order',
      },
    ],
  },
  {
    name: 'Uploads',
    is_open: true,
    children: [
      {
        name: 'Parts',
        icon: 'material-symbols-light:upload',
        to: '/shared/parts',
        action: 'read',
        collection: 'Parts',
        exact: true,
      },
      {
        name: 'Datahub',
        icon: 'material-symbols-light:upload-2-rounded',
        to: '/shared/datahub',
        action: 'read',
        collection: 'Parts',
      },
      {
        name: 'Formats',
        icon: 'material-symbols-light:upload-2-rounded',
        to: '/shared/formats',
        action: 'read',
        collection: 'Parts',
      },
    ],
  },
]

const navigation = ref<any[]>(baseCategories)
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

// login.vue-с role-ийн Shared sections (id=7) сонголтоор хадгалсан
// зөвшөөрөгдсөн нэрсийн жагсаалт. Байхгүй бол role хязгаарлалтгүй
// (Package зөвшөөрөл дангаараа хүчинтэй байна).
const filterByRole = (categories: any[]) => {
  let allowedNames: string[] | null = null
  try {
    const raw = localStorage.getItem('role_shared_sections')
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
    filterByPackage(baseCategories, packagePermissions, PACKAGE_GROUP_ID),
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
