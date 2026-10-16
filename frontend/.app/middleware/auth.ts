import { DirectusUser } from '@directus/sdk'
import SubsidebarLocationMenus from '~/components/global/SubsidebarLocationMenus'

export default defineNuxtRouteMiddleware(async (to, _from) => {
  const directus = useDirectus()
  const { fetchUser, setUser } = useDirectusAuth()
  const { getItems, deleteItems } = useDirectusItems()
  const all_locations = ref([])
  let main_role = {}
  let add_role = {}
  let main_locations = []
  let addition_locations = []
  const collections = [
    'Work_order',
    'Work_request',
    'Assets',
    'Pm',
    'Parts',
    'Location',
  ]
  const collectionsString = collections.join(',')

  const getMainRolePerm = async (roleId, location_id, user_id) => {
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
      let role_items = {}

      // all menus
      if (config_role.data.length == 0) {
        sub_menus = SubsidebarLocationMenus(location_id)
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
              case 6: // Transaction Actions
                dashboard = item.children || []
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
      }

      return (main_role[location_id] = role_items)
    } catch (error) {
      console.error('Error  main role :', error)
    }
  }

  const getMainLocationRole = async (roleIds, location_id, user_id) => {
    try {
      const { token } = useDirectusToken()
      const runtimeConfig = useRuntimeConfig()
      const domain = runtimeConfig.public.directus.url
      const location_submenus = roleIds.map((roleId) => {
        return getItems({
          collection: 'Location_menus',
          params: {
            filter: {
              user_id: user_id,
              location_id: location_id,
              role_id: roleId,
            },
            meta: 'filter_count',
            fields: ['*', 'role_id.*', 'location_id.*'],
          },
        })
      })

      const loc_submenus = await Promise.all(location_submenus)

      let sub_menus = []
      // all menus
      if (loc_submenus[0].data.length == 0) {
        sub_menus = SubsidebarLocationMenus(location_id)
      } else {
        sub_menus = loc_submenus[0].data
      }

      return (main_locations[location_id] = sub_menus)
    } catch (error) {
      console.error('Error  main role :', error)
    }
  }

  const getOtherLocationRole = async (user_id, locationId) => {
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

      const addition_loc_menus = await Promise.all(locRequests)

      // console.log('addition_loc_menus', addition_loc_menus)

      let sub_menus = []
      let main_menus = []
      let work_actcions = []
      let transaction_actions = []
      let dashboard = []
      let role_items = {}
      let location_id = 0

      // all menus
      if (addition_loc_menus[0].data.length == 0) {
        sub_menus = SubsidebarLocationMenus(locationId)
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
      }

      return (add_role[location_id] = role_items)
    } catch (error) {
      console.error('Error other role :', error)
    }
  }

  // nuxt-directus module аль хэдийн useState-ээр cache хийсэн хэрэглэгчийг
  // дахин ашиглана; байхгүй үед л шинээр /users/me рүү хандана. Ингэснээр
  // route солигдох бүрд (middleware: ['auth'] бүхий ~100 хуудас) дахин
  // давтагдаж /users/me fetch хийхээс сэргийлнэ.
  const cachedUser = useDirectusUser()
  const res = cachedUser.value
    ? Promise.resolve({ data: cachedUser.value as DirectusUser })
    : directus<{ data: DirectusUser }>('/users/me', {}, false)
  await res
    .then(async (res) => {
      setUser(res.data)

      // 1 user = 1 company: session-д хадгалагдсан active company нь
      // directus_users.company_id-тай таарч байгаа эсэх, компани идэвхтэй
      // эсэхийг шалгана. Зөвхөн UX-ийн хамгаалалт (жинхэнэ эрх Directus дээр).
      const isCompanyStillValid = await validateActiveCompany(res.data)
      if (!isCompanyStillValid) {
        return navigateTo('/login')
      }

      const myId = res.data.id
      const permissions = JSON.parse(
        window.localStorage.getItem('location_permissions'),
      )

      if (permissions) {
        // console.log('permissions_exist', permissions)
        return
      }

      const userData = res.data
      const roleIds = userData.role ? [userData.role] : []

      if (userData) {
        const roleResponse = await directus<{ data: Role }>(
          `/roles/${userData.role}`,
          {},
          false,
        )

        //admib bol location, role shalgahgui
        if (roleResponse.data.admin_access) {
          localStorage.setItem(
            'location_permissions',
            JSON.stringify({ '1': ['admin'] }),
          )
          localStorage.setItem('myId', myId)
          return
        }
      }

      const locationId = userData.location_id ? userData.location_id : 0
      const mainRole = await getMainRolePerm(userData.role, locationId, myId)
      const addRole = await getOtherLocationRole(myId, locationId)

      const location_roles = { ...main_role, ...add_role }

      // console.log('mainRole', location_roles)
      // console.log('add_role', add_role)
      // console.log('location_roles', location_roles)

      const menu_users = JSON.parse(window.localStorage.getItem('menus'))
      if (!menu_users) {
        const mainMenus = mainRole.main_menus.filter((menu) => menu.is_checked)

        if (mainMenus?.length)
          localStorage.setItem('menus', JSON.stringify(mainMenus))
      }

      const permissions_users = JSON.parse(
        window.localStorage.getItem('location_permissions'),
      )

      if (!permissions_users) {
        function getCheckedSubMenus(data) {
          const result = {}

          for (const [locationId, config] of Object.entries(data)) {
            result[locationId] = config.sub_menus.filter(
              (item) => item.is_checked === true,
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

        const uniqueDashboards = [
          ...new Map(allCheckedDashboards.map((d) => [d.id, d])).values(),
        ]

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

        localStorage.setItem('tr_actions', JSON.stringify(allCheckedTrActions))
        localStorage.setItem('wo_actions', JSON.stringify(checkedWorkActions))
        localStorage.setItem('dashboard', JSON.stringify(uniqueDashboards))
        localStorage.setItem(
          'location_permissions',
          JSON.stringify(checkedSubMenus),
        )
      }

      localStorage.setItem('myId', myId)

      // return navigateTo('/')
    })
    .catch((e) => {
      console.log('Error fetch data', e)
      return navigateTo('/login')
    })
})
