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
  const { getItems, deleteItems, updateItem, createItems } = useDirectusItems()

  const route = useRoute()
  const page = computed(() => parseInt((route.query.page as string) ?? '1'))
  const { getUsers } = useDirectusUsers()

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

  const getLocationOfRole = async (user_id, roleId, location_id) => {
    try {
      let sub_menus = []

      const addition_loc_menus = await getItems({
        collection: 'Location_menus',
        params: {
          filter: {
            user_id: user_id,
            role_id: roleId,
          },
          meta: 'filter_count',
          fields: ['*', 'role_id.*', 'location_id.*'],
        },
      })

      // default menus
      if (addition_loc_menus.data.length == 0) {
        sub_menus = SubsidebarLocationMenus(location_id)
      } else {
        sub_menus = addition_loc_menus.data
      }
      return sub_menus
    } catch (error) {
      console.error('Error other role :', error)
    }
  }

  const loadItems = async (params) => {
    loading.value = true
    try {
      const filters = {
        active: status != 'active' ? 0 : 1,
        // company_id: myCompanyId,
        // id: '1d83c86a-de88-4aca-ae2e-84c1480cea90',
      }

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

      // const users = await getUsers({
      //   params: {
      //     ...params,
      //     filter: filters,
      //     meta: 'filter_count',
      //     ...(search != null && search != '' && { search: search }),
      //     limit: pageSize,
      //     page: currentPage,
      //     sort: `${sortOrder === 'asc' ? '' : '-'}${
      //       sortField === null ? 'first_name' : sortField
      //     }`,

      //     fields: [
      //       '*',
      //       'role.*',
      //       'location_id.*',
      //       'avatar.id',
      //       'avatar.filename_disk',
      //       'avatar.type',
      //       'avatar.height',
      //       // 'Users_perm.*', // Users_perm хүснэгтээс role мэдээлэл авах
      //       // 'menu_users.*', // menu_users хүснэгтээс menu_id мэдээлэл авах
      //       // 'Users_perm.location.*', // Users_perm хүснэгтээс location мэдээлэл авах
      //       'Users_perm.role.*', // Users_perm хүснэгтээс role мэдээлэл авах
      //       'menu_users.menu_id.*', // menu_users хүснэгтээс menu_id мэдээлэл авах
      //     ],
      //     // deep: true,
      //     deep: {
      //       Users_perm: {
      //         _filter: {
      //           user_id: { _eq: '1d83c86a-de88-4aca-ae2e-84c1480cea90' }, // `user_id` нь хэрэглэгчийн `id`-тай таарах
      //         },
      //       },
      //       // menu_users: {
      //       //   _filter: {
      //       //     user_id: { _eq: '1d83c86a-de88-4aca-ae2e-84c1480cea90' }, // `user_id` нь хэрэглэгчийн `id`-тай таарах
      //       //   },
      //       // },

      //       // menu_users: {
      //       //   user_id: { _eq: '1d83c86a-de88-4aca-ae2e-84c1480cea90' },
      //       // },
      //     },
      //   },
      // })

      // console.log('getUsers', users)

      const usersData = users.data
      totalItems.value = users.meta.filter_count

      //nemelt role bgaa yuu?
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

      //menu tohirgoo orson uu?
      const menuRequests = users.data.map((item) => {
        return getItems({
          collection: 'menu_users',
          params: {
            filter: { user_id: item.id },
            meta: 'filter_count',
            fields: ['*', 'menu_id.*'],
          },
        })
      })

      const additional_rolesData = await Promise.all(rolesRequests)
      const menuData = await Promise.all(menuRequests)

      // const additional_rolesData = []
      // const menuData = []

      additional_rolesData.forEach((result, index) => {
        const userId = usersData[index].id // `items.data`-г ашиглан `userId` олох
        roles[userId] = result.data // `userId`-г `roles` объектод хуваарилах
        menus[userId] = menuData[index].data // `userId`-г `roles` объектод хуваарилах
      })

      const userRolesMap = {}
      // additional_roles_datas
      for (const userId of Object.keys(roles)) {
        const userRoles = roles[userId]

        for (const role of userRoles) {
          if (!userRolesMap[userId]) {
            userRolesMap[userId] = []
          }
          let roleId = role.role.id
          let locId = role.location.id

          try {
            let loc_sub_menus = await getLocationOfRole(userId, roleId, locId)
            const mySubMenus = SubsidebarLocationMenus(
              locId,
              true,
              loc_sub_menus,
            )
            // console.log('mySubMenus', mySubMenus)

            const visibleMenus = SubsidebarLocationMenus(locId).filter((menu) =>
              loc_sub_menus.some(
                (allow) => parseInt(allow.submenu_id) === menu.id,
              ),
            )

            const SubMenu = visibleMenus.map((menu) => menu.name).join(', ')

            // console.log('Accessible location menus:', visibleMenus)
            // console.log('roleRermissions', roleRermissions)

            userRolesMap[userId].push({
              mainrole: false,
              userId: userId,
              role: role.role.name,
              roleId: role.role.id,
              location: role.location.name,
              locationId: role.location.id,
              MenuCount: visibleMenus.length,
              SubMenu: SubMenu,
              locationSubMenu: mySubMenus,
              locationSubMenuAll: locationMenus,
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
        const menusDetails = menus[user.id] || []

        let roleId = user.role?.id
        let locId = user.location?.id
        let loc_sub_menus = await getLocationOfRole(user.id, roleId, locId)
        const mySubMenus = SubsidebarLocationMenus(locId, true, loc_sub_menus)
        const visibleMenus = SubsidebarLocationMenus(locId).filter((menu) =>
          loc_sub_menus.some((allow) => parseInt(allow.submenu_id) === menu.id),
        )
        const SubMenu = visibleMenus.map((menu) => menu.name).join(', ')

        rolesDetails.push({
          mainrole: true,
          userId: user.id,
          role: user.role?.name + '(main)',
          roleId: user.role?.id,
          location: user.location || '',
          locationId: user.location_id?.id,
          MenuCount: loc_sub_menus.length,
          locationSubMenu: mySubMenus,
          locationSubMenuAll: locationMenus,
          SubMenu: SubMenu,
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
          menus: user.role?.admin_access ? 'ALL' : menusDetails.length,
          allMenusDetails: user.role?.admin_access ? 'ALL' : menusDetails,
          allRolesDetails: user.role?.admin_access ? 'ALL' : rolesDetails,
          image: img_path,
          roles: user.role?.admin_access ? 'ALL' : rolesDetails.length,
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
