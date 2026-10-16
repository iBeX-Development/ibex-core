<script setup lang="ts">
import { toTypedSchema } from '@vee-validate/zod'
import { Field, useForm } from 'vee-validate'
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { z } from 'zod'

const { login, loginWithProvider, fetchUser, setUser } = useDirectusAuth()
const { getItems } = useDirectusItems()
const { t } = useI18n({ useScope: 'global' })
let comInfo = JSON.parse(window.localStorage.getItem('comInfo') || '{}')
let myCompanyId = comInfo?.id || null
if (definePageMeta) {
  definePageMeta({
    layout: 'empty',
    title: 'Login',
    preview: {
      title: 'Login 4',
      description: 'For authentication and sign in',
      categories: ['layouts', 'authentication'],
      src: '/img/screens/auth-login-4.png',
      srcDark: '/img/screens/auth-login-4-dark.png',
      order: 99,
    },
  })
}

const VALIDATION_TEXT = {
  EMAIL_REQUIRED: t('A valid email is required'),
  PASSWORD_REQUIRED: t('A password is required'),
}

// This is the Zod interfaces for the form input
// It's used to define the shape that the form data will have
const zodSchema = z.object({
  email: z.string().email(VALIDATION_TEXT.EMAIL_REQUIRED),
  password: z.string().min(1, VALIDATION_TEXT.PASSWORD_REQUIRED),
  trustDevice: z.boolean(),
})

// Zod has a great infer method that will
// infer the shape of the interfaces into a TypeScript type
type FormInput = z.infer<typeof zodSchema>

const validationSchema = toTypedSchema(zodSchema)
const initialValues = computed<FormInput>(() => ({
  email: '',
  password: '',
  trustDevice: false,
}))

const loginItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const comInfos = ref([])
let main_locations = []
let addition_locations = []

let main_role = {}
let add_role = {}

const {
  handleSubmit,
  isSubmitting,
  setFieldError,
  meta,
  values,
  errors,
  resetForm,
  setFieldValue,
  setErrors,
} = useForm({
  validationSchema,
  initialValues,
})

const router = useRouter()
const toaster = useToaster()
const runtimeConfig = useRuntimeConfig()
// const { token } = useDirectusToken()
// const config = useRuntimeConfig()

const fetchData = async (token, role_id) => {
  try {
    let url =
      runtimeConfig.public.directus.url +
      `roles?limit=-1&fields[]=id&fields[]=name&fields[]=description&fields[]=icon&fields[]=admin_access&fields[]=users&deep[users][_aggregate][count]=id&deep[users][_groupBy][0]=role&deep[users][_sort]=role&deep[users][_limit]=-1&sort=name&filter[id][_eq]=${role_id}`
    // console.log(url)
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.value}`,
      },
    })
    return await response.json()
  } catch (error) {
    console.error('Error fetching data:', error)
  }
  return null
}

// Company-ийн Pricing_packages.permissions уншиж авах
const loadPackagePermissions = async (packageId) => {
  if (!packageId) return []

  try {
    const result = await getItems({
      collection: 'Pricing_packages',
      params: {
        filter: { id: packageId },
        fields: ['*'],
      },
    })
    const data = Array.isArray(result) ? result : result?.data ?? []

    return Array.isArray(data[0]?.permissions) ? data[0].permissions : []
  } catch (error) {
    console.error('Unable to load package permissions:', error)
    return []
  }
}

// packagePermissions доторх тухайн бүлгийн (menu group id) зөвшөөрөгдсөн id-нууд
// Багц тохируулаагүй/олдоогүй бол null (хязгаарлалтгүй)
const getPackageAllowedIds = (packagePermissions, groupId) => {
  const group = (packagePermissions || []).find((p) => p.id === groupId)
  if (!group) return null

  return new Set(
    (group.children || [])
      .filter((child) => child.is_checked)
      .map((child) => child.id),
  )
}

const filterByPackage = (items, packagePermissions, groupId) => {
  const allowedIds = getPackageAllowedIds(packagePermissions, groupId)
  return allowedIds
    ? (items || []).filter((item) => allowedIds.has(item.id))
    : items
}

// packagePermissions доторх тухайн бүлгийн (menu group id) зөвшөөрөгдсөн
// item-үүдийг id-аас гадна name, key-тай нь бүтнээр нь буцаана
const getPackageAllowedItems = (packagePermissions, groupId) => {
  const group = (packagePermissions || []).find((p) => p.id === groupId)
  if (!group) return null

  return (group.children || [])
    .filter((child) => child.is_checked)
    .map((child) => ({ id: child.id, name: child.name, key: child.key }))
}

// Хянах самбарын алдангийн жагсаалт (DemoPackagePermissionMore-той тохирсон id/key)
const defaultDashboardTabs = [
  {
    name: t('Costs'),
    key: 'cost',
    icon: 'solar:money-bag-outline',
    color: 'text-green-600',
    hoverColor: 'group-hover:bg-green-400 dark:group-hover:bg-green-400',
    id: 1,
  },
  {
    name: t('Works'),
    key: 'performance',
    icon: 'fluent:wrench-settings-24-regular',
    color: 'text-red-400',
    hoverColor: 'group-hover:bg-rose-500 dark:group-hover:bg-rose-500',
    id: 2,
  },
  {
    name: t('Tasks'),
    key: 'task',
    icon: 'carbon:operations-record',
    color: 'text-sky-500',
    hoverColor: ' group-hover:bg-sky-500 dark:group-hover:bg-sky-500',
    id: 3,
  },
  {
    name: t('Monitoring'),
    key: 'monitoring',
    icon: 'material-symbols:monitoring',
    color: 'text-orange-500',
    hoverColor: ' group-hover:bg-orange-500 dark:group-hover:bg-orange-500',
    id: 6,
  },
  // {
  //   name: t('Performance'),
  //   key: 'private',
  //   icon: 'carbon:operations-record',
  //   color: 'text-orange-500',
  //   hoverColor: ' group-hover:bg-orange-500 dark:group-hover:bg-orange-500',
  //   id: 5,
  // },
  {
    name: t('Safety'),
    key: 'safety',
    icon: 'ph:bank-duotone',
    color: 'text-indigo-500',
    hoverColor: ' group-hover:bg-indigo-500 dark:group-hover:bg-indigo-500',
    id: 4,
  },
]

const getMainRolePerm = async (
  roleId,
  location_id,
  user_id,
  packagePermissions,
) => {
  try {
    const { token } = useDirectusToken()
    const runtimeConfig = useRuntimeConfig()
    const domain = runtimeConfig.public.directus.url
    const config_role = await getItems({
      collection: 'Roles_perm',
      params: {
        filter: {
          role_id: roleId,
        },
        meta: 'filter_count',
        fields: ['*', 'role_id.*', 'location_id.*'],
      },
    })

    let sub_menus = []
    let main_menus = []
    let work_actcions = []
    let transaction_actions = []
    let dashboard = []
    let shared_sections = []
    let inventory = []
    let has_shared_sections = false
    let has_inventory = false
    let role_items = {}

    // all menus
    if (config_role.data.length == 0) {
      const allowedIds = getPackageAllowedIds(packagePermissions, 3)
      sub_menus = SubsidebarLocationMenus(location_id).map((menu) => ({
        ...menu,
        is_checked: allowedIds ? allowedIds.has(menu.id) : true,
      }))

      const allowedDashboardIds = getPackageAllowedIds(packagePermissions, 6)
      dashboard = defaultDashboardTabs.map((tab) => ({
        ...tab,
        is_checked: allowedDashboardIds
          ? allowedDashboardIds.has(tab.id)
          : true,
      }))
    } else {
      config_role.data.forEach((ele) => {
        const access_data = ele.access_data || []
        access_data.forEach((item) => {
          switch (item.id) {
            case 1: // Menus
              main_menus = item.children || []
              break
            case 3: // Locations subMenus
              sub_menus = item.children || []
              break
            case 4: // Work Actions
              work_actcions = item.children || []
              break
            case 5: // Transaction Actions
              transaction_actions = item.children || []
              break
            case 6: // Transaction Actions
              dashboard = item.children || []
              break
            case 7: // Shared sections
              shared_sections = item.children || []
              has_shared_sections = true
              break
            case 8: // Inventory
              inventory = item.children || []
              has_inventory = true
              break
          }
        })
      })
    }

    role_items = {
      sub_menus,
      main_menus,
      work_actcions,
      transaction_actions,
      dashboard,
      shared_sections,
      inventory,
      has_shared_sections,
      has_inventory,
    }

    return (main_role[location_id] = role_items)
  } catch (error) {
    console.error('Error  main role :', error)
  }
}

const getOtherLocationRole = async (
  user_id,
  locationId,
  packagePermissions,
) => {
  try {
    const { token } = useDirectusToken()
    const runtimeConfig = useRuntimeConfig()
    const domain = runtimeConfig.public.directus.url

    //nemelt location harah bol
    const res_items = await getItems({
      collection: 'Users_perm',
      params: {
        filter: { user_id: user_id },
        meta: 'filter_count',
        fields: ['*', 'role.*', 'location.*'],
      },
    })

    const other_locations = res_items.data
    // console.log('other_locations', other_locations)

    if (other_locations.length == 0) return
    const locRequests = other_locations.map(async (item) => {
      let roleId = item.role.id
      let location_id = item.location.id

      const res = await getItems({
        collection: 'Roles_perm',
        params: {
          filter: {
            // location_id: location_id,
            role_id: roleId,
          },
          meta: 'filter_count',
          fields: ['*', 'role_id.*', 'location_id.*'],
        },
      })

      // console.log('res', res)

      if (res.data.length > 0) {
        return {
          data: res.data,
          location_id: location_id,
        }
      }
    })

    const addition_loc_menus = (await Promise.all(locRequests)).filter(
      (locationMenus) => locationMenus,
    )

    if (addition_loc_menus.length === 0) return

    // console.log('addition_loc_menus', addition_loc_menus)

    let sub_menus = []
    let main_menus = []
    let work_actcions = []
    let transaction_actions = []
    let dashboard = []
    let shared_sections = []
    let inventory = []
    let has_shared_sections = false
    let has_inventory = false
    let role_items = {}
    let location_id = 0

    // all menus
    if (addition_loc_menus[0].data.length == 0) {
      const allowedIds = getPackageAllowedIds(packagePermissions, 3)
      sub_menus = SubsidebarLocationMenus(locationId).map((menu) => ({
        ...menu,
        is_checked: allowedIds ? allowedIds.has(menu.id) : true,
      }))

      const allowedDashboardIds = getPackageAllowedIds(packagePermissions, 6)
      dashboard = defaultDashboardTabs.map((tab) => ({
        ...tab,
        is_checked: allowedDashboardIds
          ? allowedDashboardIds.has(tab.id)
          : true,
      }))
    } else {
      // console.log('else', addition_loc_menus)
      location_id = addition_loc_menus[0].location_id

      addition_loc_menus[0].data.forEach((ele) => {
        const access_data = ele.access_data || []
        access_data.forEach((item) => {
          switch (item.id) {
            case 1: // Menus
              main_menus = item.children || []
              break
            case 3: // Locations subMenus
              sub_menus = item.children || []
              break
            case 4: // Work Actions
              work_actcions = item.children || []
              break
            case 5: // Transaction Actions
              transaction_actions = item.children || []
              break
            case 6: //  dashboard
              dashboard = item.children || []
              break
            case 7: // Shared sections
              shared_sections = item.children || []
              has_shared_sections = true
              break
            case 8: // Inventory
              inventory = item.children || []
              has_inventory = true
              break
          }
        })
      })
    }

    role_items = {
      sub_menus,
      main_menus,
      work_actcions,
      transaction_actions,
      dashboard,
      shared_sections,
      inventory,
      has_shared_sections,
      has_inventory,
    }

    return (add_role[location_id] = role_items)
  } catch (error) {
    console.error('Error other role :', error)
  }
}

// This is where you would send the form data to the server
const onSubmit = handleSubmit(async (values) => {
  // here you have access to the validated form values
  // console.log('auth-success', values)

  try {
    // fake delay, this will make isSubmitting value to be true

    const login_response = await login({
      email: values.email,
      password: values.password,
    })
    setUser(login_response.user)
    const userData = login_response.user
    const myId = login_response.user?.id
    myCompanyId = login_response.user?.company_id || myCompanyId

    if (!myCompanyId) {
      setFieldError('password', t('Invalid credentials'))
      return
    }

    // console.log('login_response', login_response)

    if (userData) {
      const { token } = useDirectusToken()
      const companyResponse = await fetch(
        `${
          runtimeConfig.public.directus.url
        }items/Companies?filter[id][_eq]=${encodeURIComponent(
          String(myCompanyId),
        )}&limit=1&fields=*`,
        {
          headers: {
            Authorization: `Bearer ${token.value}`,
          },
        },
      )
      comInfo = await companyResponse.json()
      const companyData =
        companyResponse.ok && Array.isArray(comInfo.data) ? comInfo.data : []

      if (!companyResponse.ok) {
        console.error('Unable to load company information:', comInfo)
      }

      if (Number(companyData[0]?.status) !== 1) {
        toaster.clearAll()
        toaster.show({
          title: t('Login failed'),
          message: t('Organization is inactive'),
          color: 'danger',
          icon: 'ph:warning-circle-fill',
          closable: true,
        })
        return
      }

      const licenseDate = companyData[0]?.license_date
      const licenseExpiresAt = licenseDate
        ? new Date(
            /^\d{4}-\d{2}-\d{2}$/.test(licenseDate)
              ? `${licenseDate}T23:59:59.999`
              : licenseDate,
          )
        : null

      if (
        licenseExpiresAt &&
        !Number.isNaN(licenseExpiresAt.getTime()) &&
        licenseExpiresAt < new Date()
      ) {
        toaster.clearAll()
        toaster.show({
          title: t('Login failed'),
          message: t('Organization license has expired'),
          color: 'danger',
          icon: 'ph:warning-circle-fill',
          closable: true,
        })
        return
      }

      // console.log('comInfo', companyData)
      comInfos.value = companyData
      localStorage.setItem(STORAGE_KEYS.USER_INFO, JSON.stringify(userData))
      localStorage.setItem(
        STORAGE_KEYS.COMPANY_INFO,
        JSON.stringify(companyData[0] || {}),
      )
      localStorage.setItem(
        STORAGE_KEYS.MY_COMPANY_ID,
        String(myCompanyId || ''),
      )
      localStorage.setItem(STORAGE_KEYS.MY_ID, myId)
      // Login дээр компанийг шалгасан тул auth middleware-ийн throttle-ийг шинэчилнэ
      markActiveCompanyChecked()

      // Өмнөх (өөр эрхтэй) session-ээс үлдсэн хуучин role-ийн Shared
      // sections/Inventory хязгаарлалт байвал цэвэрлэнэ — доор admin бус
      // хэрэглэгчийн хувьд шаардлагатай бол дахин тохируулна.
      // SubsidebarWorkOrder/SubsidebarParts-ийн 24 цагийн кэшийг ч мөн
      // цэвэрлэж, шинэ зөвшөөрлөөр дахин тооцоолуулна.
      localStorage.removeItem('role_shared_sections')
      localStorage.removeItem('role_inventory')
      localStorage.removeItem('sidebar_shared')
      localStorage.removeItem('sidebar_inventory')

      const packagePermissions = await loadPackagePermissions(
        companyData[0]?.package,
      )

      // console.log('userData.role')
      // console.log(userData.role, token)
      const roleResponse = await fetchData(token, userData.role)
      // console.log('roleResponse', roleResponse)

      if (roleResponse?.data?.[0]?.admin_access) {
        // admin_access true бол бүх эрхтэй админ хэрэглэгч ч гэсэн
        // байгууллагын багцын (Pricing_packages) зөвшөөрөлд хамаарна
        localStorage.setItem(
          'app_permissions',
          JSON.stringify({ '1': ['admin'] }),
        )

        const allowedSubmenuIds = getPackageAllowedIds(packagePermissions, 3)

        if (!allowedSubmenuIds) {
          localStorage.setItem(
            'location_permissions',
            JSON.stringify({ '1': ['admin'] }),
          )
        } else {
          const locationsRes = await getItems({
            collection: 'Location',
            params: {
              filter: { status: '1', company_id: myCompanyId },
              fields: ['id', 'position'],
              limit: -1,
              sort: ['position'],
            },
          })
          const locationsData = Array.isArray(locationsRes)
            ? locationsRes
            : (locationsRes as any)?.data ?? []
          const allowedSubmenus =
            getPackageAllowedItems(packagePermissions, 3) || []
          const permissionsData = {}

          locationsData.forEach((loc) => {
            permissionsData[loc.id] = allowedSubmenus
          })

          localStorage.setItem(
            'location_permissions',
            JSON.stringify(permissionsData),
          )
        }

        // admin_access true бол ч дашбордын харагдах табууд багцын
        // зөвшөөрөлд (group 6) хамаарна
        localStorage.setItem(
          'dashboard',
          JSON.stringify(
            filterByPackage(defaultDashboardTabs, packagePermissions, 6),
          ),
        )

        const menusRes = await getItems({
          collection: 'Menus',
          params: {
            filter: { is_active: 1 },
            sort: ['sort_number'],
            meta: 'filter_count',
            fields: ['*'],
          },
        })
        if (menusRes.data) {
          // Багцын зөвшөөрлийг зөвхөн 'start' байрлалтай (тохиргоо хийгддэг) цэсэнд
          // хэрэглэнэ. 'end' байрлалтай цэсүүд (My Account гэх мэт) багцын
          // зөвшөөрлийн жагсаалтад байдаггүй тул үргэлж харагдана.
          const startMenus = filterByPackage(
            menusRes.data.filter((m) => m.position === 'start'),
            packagePermissions,
            1,
          )
          const otherMenus = menusRes.data.filter((m) => m.position !== 'start')
          let finalMenus = [...startMenus, ...otherMenus]
          if (myCompanyId == 1 && roleResponse?.data?.[0]?.admin_access) {
            let add_menus = {
              id: 17,
              user_created: '7e91d147-dbbd-4211-8bbc-a83c51fdfaa3',
              date_created: '2026-08-13T02:16:12.301Z',
              user_updated: '7e91d147-dbbd-4211-8bbc-a83c51fdfaa3',
              date_updated: '2026-08-13T02:17:54.895Z',
              title: 'Companies',
              icon_name: 'streamline-ultimate:office-building-tall-2',
              component: 'SubsidebarCompanies',
              filter: 'companies',
              position: 'start',
              is_active: 1,
              is_direct: true,
              exact: true,
              sort_number: 13,
              company_id: 1,
            }
            finalMenus.push(add_menus)
            console.log('admin_ok')
          }
          localStorage.setItem('menus', JSON.stringify(finalMenus))
        }
      } else {
        console.log('user')
        const locationId = userData.location_id ? userData.location_id : 0
        const mainRole = await getMainRolePerm(
          userData.role,
          locationId,
          myId,
          packagePermissions,
        )
        const addRole = await getOtherLocationRole(
          myId,
          locationId,
          packagePermissions,
        )

        // heden location haruulah tohirgoo end awsan
        const location_roles = { ...main_role, ...add_role }

        // Role-ийн Shared sections (7) / Inventory (8) доторх subItem-үүдийн
        // сонголтыг байршил бүрээр нэгтгэж (union), SubsidebarWorkOrder.vue /
        // SubsidebarParts.vue-д ашиглах localStorage рүү хадгална.
        // has_* === false бол тухайн role энэ бүлгийг огт тохируулаагүй гэсэн
        // үг тул хязгаарлалтгүй (localStorage-с хасна — Package-ийн зөвшөөрөл
        // дангаараа хүчинтэй байна); has_* === true бол зөвхөн is_checked
        // болсон нэрсээр хязгаарлана (юу ч чекгүй бол юу ч харагдахгүй).
        const collectRoleGroupNames = (groupKey, hasKey) => {
          let hasConfig = false
          const names = new Set()
          Object.values(location_roles).forEach((item) => {
            if (item?.[hasKey]) {
              hasConfig = true
              ;(item[groupKey] || []).forEach((c) => {
                if (c.is_checked) names.add(c.name)
              })
            }
          })
          return hasConfig ? Array.from(names) : null
        }

        const roleSharedSections = collectRoleGroupNames(
          'shared_sections',
          'has_shared_sections',
        )
        const roleInventory = collectRoleGroupNames(
          'inventory',
          'has_inventory',
        )

        if (roleSharedSections) {
          localStorage.setItem(
            'role_shared_sections',
            JSON.stringify(roleSharedSections),
          )
        } else {
          localStorage.removeItem('role_shared_sections')
        }

        if (roleInventory) {
          localStorage.setItem('role_inventory', JSON.stringify(roleInventory))
        } else {
          localStorage.removeItem('role_inventory')
        }

        const mainMenus = filterByPackage(
          (mainRole?.main_menus || []).filter((menu) => menu.is_checked),
          packagePermissions,
          1,
        )
        if (mainMenus?.length)
          localStorage.setItem('menus', JSON.stringify(mainMenus))

        const permissions_users = JSON.parse(
          window.localStorage.getItem('location_permissions'),
        )

        // console.log('permissions_users', permissions_users)
        if (!permissions_users) {
          function getCheckedSubMenus(data) {
            const result = {}

            for (const [locationId, config] of Object.entries(data)) {
              result[locationId] = filterByPackage(
                config.sub_menus.filter((item) => item.is_checked === true),
                packagePermissions,
                3,
              )
            }

            return result
          }

          function getCheckedWorkActions(data) {
            const actions = {}

            for (const [locationId, config] of Object.entries(data)) {
              actions[locationId] = config.work_actcions.filter(
                (item) => item.is_checked === true,
              )
            }

            return actions
          }

          const allCheckedDashboards = Object.values(location_roles).flatMap(
            (item) => item.dashboard.filter((d) => d.is_checked),
          )

          const uniqueDashboards = filterByPackage(
            [...new Map(allCheckedDashboards.map((d) => [d.id, d])).values()],
            packagePermissions,
            6,
          )

          const allCheckedTrActions = Object.values(location_roles).flatMap(
            (item) => item.transaction_actions.filter((d) => d.is_checked),
          )

          function removeUnchecked(data) {
            const cleaned = {}
            for (const [locationId, config] of Object.entries(data)) {
              cleaned[locationId] = {
                sub_menus: config.sub_menus.filter(
                  (item) => item.is_checked === true,
                ),
                main_menus: config.main_menus.filter(
                  (item) => item.is_checked === true,
                ),
                work_actcions: config.work_actcions.filter(
                  (item) => item.is_checked === true,
                ),
                transaction_actions: config.transaction_actions.filter(
                  (item) => item.is_checked === true,
                ),
              }
            }

            return cleaned
          }

          const cleanedData = removeUnchecked(location_roles)
          const checkedSubMenus = getCheckedSubMenus(location_roles)
          const checkedWorkActions = getCheckedWorkActions(location_roles)

          // console.log('allCheckedTrActions', uniqueDashboards)
          // console.log('checkedWorkActions', checkedWorkActions)
          // console.log('allCheckedDashboards', allCheckedDashboards)

          // console.log('checkedSubMenus', checkedSubMenus)
          // permissions -location-sub-menus
          // menus -main-menus
          // dashboard -dashboard-tabs
          // wo_actions -work_order_actions
          // tr_actions -transactioins_actions

          localStorage.setItem(
            'tr_actions',
            JSON.stringify(allCheckedTrActions),
          )
          localStorage.setItem('wo_actions', JSON.stringify(checkedWorkActions))
          localStorage.setItem('dashboard', JSON.stringify(uniqueDashboards))
          localStorage.setItem(
            'location_permissions',
            JSON.stringify(checkedSubMenus),
          )
        }

        // console.log('hihi', mainMenus)
      }
    }

    toaster.clearAll()
    toaster.show({
      title: t('Login success'),
      message: t(`Welcome back`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
    router.push('/')
  } catch (error: any) {
    console.log(error)
    // this will set the error on the form
    setFieldError('password', t('Invalid credentials'))
    return
  }
})

const loadItems = async (page, itemsPerPage) => {
  console.log('loadItems', itemsPerPage, comInfos)
  try {
    loading.value = true
    const filters = {
      active: 1,
      status: 'Publish',
    }

    if (myCompanyId) {
      filters.company_id = myCompanyId
    }

    const items = await getItems({
      collection: 'Login_set',
      params: {
        filter: filters,
        limit: 1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    loginItems.value = items.data
    totalItems.value = items.meta.filter_count
    loading.value = false

    // console.log('loginItems->', loginItems)
    // console.log('loginItems->', loginItems.value)
  } catch (e) {
    console.log('eeeer_no1', e)
  }
}
const hasLoginItems = computed(() => loginItems.value.length > 0)
const hasOnlyImg = computed(() => {
  // console.log(
  //   'hasOnlyImg',
  //   loginItems.value.length > 0 &&
  //     loginItems.value[0]?._image != null &&
  //     loginItems.value[0]?._video == null &&
  //     loginItems.value[0]?._text == '',
  // )
  return (
    loginItems.value.length > 0 &&
    loginItems.value[0]?._image != null &&
    loginItems.value[0]?._video == null
  )
})
const hasOnlyVideo = computed(() => {
  // console.log(
  //   'hasOnlyVideo',
  //   loginItems.value.length > 0 &&
  //     loginItems.value[0]?._image == null &&
  //     loginItems.value[0]?._video != null &&
  //     loginItems.value[0]?._text == '',
  // )
  return (
    loginItems.value.length > 0 &&
    loginItems.value[0]?._image == null &&
    loginItems.value[0]?._video != null
  )
})
const hasItems = computed(() => {
  // console.log(
  //   'all',
  //   loginItems.value.length > 0 &&
  //     loginItems.value[0]?._image != null &&
  //     loginItems.value[0]?._video != null,
  // )

  // Босоо байрлалыг Vertical хэвтээ байрлалыг Horizontal гэж нэрлэх
  return (
    loginItems.value.length > 0 &&
    loginItems.value[0]?._image != null &&
    loginItems.value[0]?._video != null
  )
})
const hasVideo = computed(() => {
  return loginItems.value.length > 0 && loginItems.value[0]?._video
})
const ImgUrl = computed(() => {
  return loginItems.value.length > 0 && loginItems.value[0]?._image
    ? `${runtimeConfig.public.directus.url}assets/${loginItems.value[0]._image}`
    : false
})
const VideoUrl = computed(() => {
  return loginItems.value.length > 0 && loginItems.value[0]?._video
    ? `${runtimeConfig.public.directus.url}assets/${loginItems.value[0]._video}`
    : false
})
onMounted(async () => {
  await loadItems(1, 1)
  console.log('Hello iBex')
})

const logClassInfo = () => {
  console.log('Selected axis:', loginItems.value[0]?.axis, loginItems.value) // Log the axis value
  console.log('Applied classes:', [
    loginItems.value[0]?.axis === 'Vertical'
      ? 'media_Vertical'
      : 'media_Horizontal',
    'media_box',
    'w-full',
    'h-full',
  ]) // Log applied classes
}
</script>

<template>
  <div class="flex h-screen w-full flex-col items-center md:flex-row">
    <div
      class="bg-muted-100 dark:bg-muted-900 hidden h-screen w-full md:w-1/2 lg:block xl:w-2/3"
    >
      <div v-if="loading == true"><Icon name="codex:loader" /></div>
      <div v-else class="w-full h-full">
        <div v-if="hasLoginItems" class="login_page w-full h-full">
          <div v-if="hasItems == true" class="w-full h-full">
            <div
              :class="[
                loginItems[0]?.axis === 'Vertical'
                  ? 'media_Vertical'
                  : 'media_Horizontal',
                loginItems[0]?._video_position === 'Left'
                  ? `video_${loginItems[0].axis}_left`
                  : loginItems[0]?._video_position === 'Right'
                  ? `video_${loginItems[0].axis}_right`
                  : loginItems[0]?._video_position === 'Top'
                  ? `video_${loginItems[0].axis}_top`
                  : `video_${loginItems[0].axis}_bottom`,
                'media_box',
                'w-full',
                'h-full',
              ]"
            >
              <div
                class="image_login"
                :style="{
                  height:
                    loginItems[0]?.axis === 'Vertical'
                      ? `${loginItems[0]?._image_size}%`
                      : '100%',
                  width:
                    loginItems[0]?.axis === 'Vertical'
                      ? '100%'
                      : `${loginItems[0]?._image_size}%`,
                }"
              >
                <img
                  :class="{
                    'object-contain': loginItems[0]?.axis === 'Vertical',
                    'object-cover': loginItems[0]?.axis !== 'Vertical',
                  }"
                  :src="ImgUrl"
                  alt="Uploaded Image"
                  :style="{
                    height: '100%',
                    width: '100%',
                    objectFit: 'cover',
                  }"
                />
              </div>
              <div
                class="video_login"
                :style="{
                  height:
                    loginItems[0]?.axis === 'Vertical'
                      ? `${loginItems[0]?._video_size}%`
                      : '100%',
                  width:
                    loginItems[0]?.axis === 'Vertical'
                      ? '100%'
                      : `${loginItems[0]?._video_size}%`,
                }"
              >
                <video
                  v-if="hasVideo"
                  class="w-full h-full object-cover loginVideo"
                  :style="{
                    height: '100%',
                    width: '100%',
                  }"
                  :src="VideoUrl"
                  autoplay
                  muted
                  loop
                  playsinline
                ></video>
              </div>
            </div>
          </div>

          <div v-if="hasOnlyVideo == true" class="w-full h-full">
            <div class="media_img w-full h-full">
              <video
                v-if="hasVideo"
                class="w-full h-full object-cover loginVideo"
                :src="VideoUrl"
                autoplay
                muted
                loop
                playsinline
              ></video>
            </div>
          </div>

          <div v-if="hasOnlyImg == true && ImgUrl" class="w-full h-full">
            <div class="media_img w-full h-full">
              <img
                class="img w-full h-full object-cover loginImage"
                :src="ImgUrl"
                alt="Uploaded Image"
              />
            </div>
          </div>
        </div>
        <img
          v-else
          class="w-full h-full object-cover loginImage defaultLoginImage"
          src="/img/illustrations/Login-Image.jpg"
          alt="Mining trucks in action"
        />
      </div>
    </div>

    <div
      class="dark:bg-muted-800 flex h-screen w-full items-center justify-center bg-white px-6 md:mx-auto md:w-1/2 md:max-w-md lg:max-w-full lg:px-16 xl:w-1/3 xl:px-12"
    >
      <div
        class="comLogo mx-auto flex h-full w-full max-w-xs flex-col items-center justify-between py-8"
      >
        <div class="mx-auto flex w-full max-w-xs items-center justify-between">
          <NuxtLink
            to="#"
            class="text-muted-400 hover:text-primary-500 dark:text-muted-700 dark:hover:text-primary-500 transition-colors duration-300"
          >
            <TairoLogo class="h-10 w-10" />
          </NuxtLink>
          <div>
            <BaseThemeToggle />
          </div>
        </div>
        <div class="w-full">
          <form
            method="POST"
            action=""
            @submit.prevent="onSubmit"
            class="mt-6"
            novalidate
          >
            <div class="space-y-4">
              <Field
                v-slot="{ field, errorMessage, handleChange, handleBlur }"
                name="email"
              >
                <BaseInput
                  :model-value="field.value"
                  :error="errorMessage"
                  :disabled="isSubmitting"
                  type="email"
                  :label="$t('Email address')"
                  :placeholder="$t('Email address')"
                  icon="ph:user-duotone"
                  @update:model-value="handleChange"
                  @blur="handleBlur"
                />
              </Field>
              <Field
                v-slot="{ field, errorMessage, handleChange, handleBlur }"
                name="password"
              >
                <BaseInput
                  :model-value="field.value"
                  :error="errorMessage"
                  :disabled="isSubmitting"
                  type="password"
                  :label="$t('Password')"
                  :placeholder="$t('Password')"
                  icon="ph:lock-duotone"
                  @update:model-value="handleChange"
                  @blur="handleBlur"
                />
              </Field>
            </div>

            <!-- Remember -->
            <div class="mt-6 flex items-center justify-between">
              <Field
                v-slot="{ field, errorMessage, handleChange, handleBlur }"
                name="trustDevice"
              >
                &nbsp;
              </Field>

              <div class="text-sm leading-5">
                <NuxtLink
                  to="/auth/recover"
                  class="text-primary-600 hover:text-primary-500 font-sans text-xs font-medium underline-offset-4 transition duration-150 ease-in-out hover:underline"
                >
                  {{ $t('Forgot your password') }}?
                </NuxtLink>
              </div>
            </div>

            <!-- Submit -->
            <div class="mt-6">
              <div class="block w-full rounded-md shadow-sm">
                <BaseButton
                  :disabled="isSubmitting"
                  :loading="isSubmitting"
                  type="submit"
                  color="primary"
                  class="!h-11 w-full"
                >
                  {{ $t('Sign in') }}
                </BaseButton>
              </div>
            </div>
          </form>

          <!--          <hr-->
          <!--            class="border-muted-200 dark:border-muted-700 my-6 w-full border-t"-->
          <!--          />-->

          <!-- No account link -->
          <!--          <p-->
          <!--            class="text-muted-400 mt-4 flex justify-between font-sans text-xs leading-5"-->
          <!--          >-->
          <!--            <span>{{ $t("Don't have an account") }}?</span>-->
          <!--            <NuxtLink-->
          <!--              to="/auth/signup-1"-->
          <!--              class="text-primary-600 hover:text-primary-500 font-medium underline-offset-4 transition duration-150 ease-in-out hover:underline"-->
          <!--            >-->
          <!--              {{ $t('Create Account') }}-->
          <!--            </NuxtLink>-->
          <!--          </p>-->
        </div>
        <div class="text-center">
          <BaseText size="xs" class="text-muted-400">
            <!--            © {{ new Date().getFullYear() }} {{ $t('My company') }}.-->

            {{ comInfos[0]?.name ? comInfos[0]?.name : $t('My company') }}
          </BaseText>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.login_page .media_box {
  display: flex;
}

.login_page .media_Horizontal {
  flex-direction: row;
}
.login_page .video_Horizontal_left {
  flex-direction: row-reverse !important;
}

.login_page .media_Vertical {
  flex-direction: column;
}

.login_page .video_Vertical_top {
  flex-direction: column-reverse !important;
}
</style>
