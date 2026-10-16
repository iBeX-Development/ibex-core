import SubsidebarLocationMenus from '~/components/global/SubsidebarLocationMenus'

export async function getData(
  currentPage = 1,
  pageSize = 10,
  sortField = null,
  sortOrder = null,
  search = null,
  status = null,
) {
  const locationMenus = SubsidebarLocationMenus(null)
  const config = useRuntimeConfig()
  const { getUsers } = useDirectusUsers()
  const { getItems, deleteItems, updateItem, createItems } = useDirectusItems()
  const myCompanyId = getMyCompanyId()

  const route = useRoute()
  const page = computed(() => parseInt((route.query.page as string) ?? '1'))

  const loading = ref(true)
  const totalItems = ref(0)
  const convertes_data = ref([])
  let roles = {}
  let menus = {}
  const gridApi = ref()
  const { params } = useRoute()

  const get_content_url = (file) => {
    if (file.type.includes('image')) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else {
      return `/img/avatars/man.jpg`
    }
  }

  // Sample permission-checking function
  const hasPermission = (res_items, collection, action) => {
    const permission = res_items.find(
      (item) => item.collection === collection && item.action === action,
    )
    return permission
      ? { id: permission.id, is_show: true }
      : { id: null, is_show: false }
  }

  const getPermOfRole = async (user_id, roleId, location_id) => {
    try {
      let sub_menus = []
      let main_menus = []
      let work_actcions = []
      let transaction_actions = []

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

      // console.log('config_role', config_role)
      // Хэрэв ямар ч config байхгүй бол default-ийг ашиглана
      if (!config_role.data.length) {
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
                break
            }
          })
        })
      }

      return {
        sub_menus,
        main_menus,
        work_actcions,
        transaction_actions,
      }
    } catch (error) {
      console.error('Error loading permissions:', error)
      return {
        sub_menus: [],
        main_menus: [],
        work_actcions: [],
        transaction_actions: [],
      }
    }
  }

  const loadItems = async (params) => {
    loading.value = true
    try {
      const filters = {
        active: status != 'active' ? 0 : 1,
        company_id: myCompanyId,
        // id: '1d83c86a-de88-4aca-ae2e-84c1480cea90',
      }

      if (myCompanyId !== 1) {
        filters['company_id'] = myCompanyId
      }
      console.log('filters', filters, myCompanyId)
      const users = await getUsers({
        params: {
          ...params,
          filter: filters,
          meta: 'filter_count',
          ...(search != null && search != '' && { search: search }),
          limit: pageSize,
          page: currentPage,
          sort: `${sortOrder === 'asc' ? '' : '-'}${
            sortField === null ? 'first_name' : sortField
          }`,

          fields: [
            '*',
            'role.*',
            'location_id.*',
            'avatar.id',
            'avatar.filename_disk',
            'avatar.type',
            'avatar.height',
          ],
        },
      })

      const usersData = users.data
      totalItems.value = users.meta.filter_count

      //user-t nemelt role bgaa yuu?
      const rolesRequests = users.data.map((item) => {
        return getItems({
          collection: 'Users_perm',
          params: {
            filter: { user_id: item.id },
            meta: 'filter_count',
            fields: ['*', 'role.*', 'location.*'],
          },
        })
      })

      const additional_rolesData = await Promise.all(rolesRequests)
      additional_rolesData.forEach((result, index) => {
        const userId = usersData[index].id // `items.data`-г ашиглан `userId` олох
        roles[userId] = result.data // `userId`-г `roles` объектод хуваарилах
      })

      // console.log('roles_data', roles)

      // additional_roles_datas
      const userRolesMap = {}
      for (const userId of Object.keys(roles)) {
        const userRoles = roles[userId]

        for (const role of userRoles) {
          if (!userRolesMap[userId]) {
            userRolesMap[userId] = []
          }
          let roleId = role.role.id
          let locId = role.location.id

          try {
            let role_config = await getPermOfRole(userId, roleId, locId)
            // console.log('role_config', userId, roleId, role_config)

            const loc_sub_menus = role_config.sub_menus || []
            const work_actcions = role_config.work_actcions || []
            const show_sub_menus = loc_sub_menus.filter(
              (menu) => menu.is_checked === true,
            )
            const SubMenuNames = show_sub_menus.map((menu) => menu.name)
            const app_work_actcions = work_actcions
              .filter((item) => item.is_checked)
              .map((item) => item.name)
              .join(', ')

            // console.log('Accessible location menus:', visibleMenus)
            // console.log('roleRermissions', roleRermissions)

            userRolesMap[userId].push({
              mainrole: false,
              userId: userId,
              role: role.role.name,
              roleId: role.role.id,
              location: role.location.name,
              locationId: role.location.id,
              Count: show_sub_menus.length,
              Actions: app_work_actcions ? app_work_actcions : '-',
              LocationSubMenu: SubMenuNames.join(', '),
              LocationSubMenuNames: SubMenuNames,
              locationSubMenuAll: loc_sub_menus,
              action: 'access',
            })
          } catch (error) {
            console.error(
              `Error fetching permissions for role ID ${role.role.id}:`,
              error,
            )
          }
        }
      }

      // main_roles_datas
      for (const user of usersData) {
        const rolesDetails = userRolesMap[user.id] || []

        let roleId = user.role?.id
        let locId = user.location?.id
        let role_config = await getPermOfRole(user.id, roleId, locId)
        // console.log('role_config', user.first_name, roleId, role_config)
        // Submenus (location-based)
        const loc_sub_menus = role_config.sub_menus || []
        const work_actcions = role_config.work_actcions || []
        const show_sub_menus = loc_sub_menus.filter(
          (menu) => menu.is_checked === true,
        )
        const SubMenuNames = show_sub_menus.map((menu) => menu.name)
        const app_work_actcions = work_actcions
          .filter((item) => item.is_checked)
          .map((item) => item.name)
          .join(', ')

        // Count, permission list
        // const locationSubMenu = loc_sub_menus.map((menu) => menu.name)

        rolesDetails.push({
          mainrole: true,
          userId: user.id,
          role: user.role?.name + '(main)',
          roleId: user.role?.id,
          location: user.location || '',
          locationId: user.location_id?.id,
          Count: user.role?.admin_access ? 'Admin' : show_sub_menus.length,
          Actions: app_work_actcions
            ? app_work_actcions
            : user.role?.admin_access
            ? 'Admin'
            : '-',
          locationSubMenuAll: loc_sub_menus,
          LocationSubMenu: user.role?.admin_access
            ? 'Admin'
            : SubMenuNames.join(', '),
          LocationSubMenuNames: SubMenuNames,
          action: 'access',
        })

        let img_path = user.avatar
          ? get_content_url(user.avatar)
          : '/img/avatars/man.jpg'

        const user_info = {
          first_name: user.first_name,
          email: user.email,
          userId: user.id,
          status: user.status,
          role: user.role?.name,
          mainLocation: user.location_id,
          roles: user.role?.admin_access ? 'Admin' : rolesDetails.length,
          menus: user.role?.admin_access
            ? 'Admin'
            : role_config.main_menus.filter((menu) => menu.is_checked).length, //menusDetails.length
          allMenusDetails: user.role?.admin_access
            ? 'Admin'
            : role_config.main_menus,
          allRolesDetails: user.role?.admin_access ? 'Admin' : rolesDetails,
          image: img_path,
          rolesDetails: rolesDetails,
        }

        convertes_data.value.push(user_info)
      }

      loading.value = false
      return convertes_data.value
    } catch (e) {
      console.log('err', e)
    }
  }

  await loadItems()

  return {
    data: convertes_data.value,
    totalCount: totalItems.value,
  }
}
