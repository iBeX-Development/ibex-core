const locationMenus = (id, permission_page = false, loc_sub_menus = []) => {
  const permissions = JSON.parse(
    window.localStorage.getItem('location_permissions') || '{}',
  )

  const set_show = (loc_id, submenu_id) => {
    if (permission_page) {
      return loc_sub_menus?.some((menu) => {
        let is_active = false
        if (menu.submenu_id) {
          if (menu.submenu_id == submenu_id) is_active = true
          else is_active = false
        } else is_active = true //default-aar bugdiig harna

        return is_active
      })
    } else {
      if (permissions && permissions[1] && permissions[1].includes('admin')) {
        return true
      }

      if (!permissions || !permissions[loc_id]) {
        return false
      }

      const hasPermission = permissions[loc_id]?.some((menu) => {
        let is_active = false
        if (menu.location_id?.id === loc_id && menu.submenu_id == submenu_id) {
          is_active = true
        } else if (menu.id == submenu_id) {
          is_active = true
        }
        return is_active
      })

      return hasPermission
    }
  }

  let sub_menus = [
    {
      id: 3,
      submenu_id: 3,
      name: 'Request List',
      icon: 'codicon:git-pull-request-go-to-changes',
      to: `/workorder/location/request/` + (id ? id : ''),
      action: 'read',
      collection: 'Work_order',
      is_show: set_show(id, 3),
    },
    {
      id: 1,
      submenu_id: 1,
      name: 'Open Work Orders',
      icon: 'octicon:tasklist-16',
      to: `/workorder/location/open/` + (id ? id : ''),
      action: 'create',
      collection: 'Work_order',
      is_show: set_show(id, 1),
    },
    {
      id: 2,
      submenu_id: 2,
      name: 'Completed Work Orders',
      icon: 'mdi:check-circle-outline',
      to: `/workorder/location/completed/` + (id ? id : ''),
      action: 'read',
      collection: 'Work_order',
      is_show: set_show(id, 2),
    },
    {
      id: 5,
      submenu_id: 5,
      name: 'Preventative Maintenances',
      icon: 'mdi:calendar-check',
      to: `/pm/location/` + (id ? id : ''),
      action: 'read',
      collection: 'Pm',
      is_show: set_show(id, 5),
    },
    {
      id: 8,
      submenu_id: 8,
      name: 'Predictive Maintenances',
      icon: 'mdi:calendar-search',
      to: `/predictive/location/` + (id ? id : ''),
      action: 'read',
      collection: 'Predictive',
      is_show: set_show(id, 8),
    },
    {
      id: 7,
      submenu_id: 7,
      name: 'Inspection',
      to: `/Inspection/location/` + (id ? id : ''),
      icon: 'mdi:clipboard-list-outline',
      action: 'read',
      collection: 'Inspection',
      is_show: set_show(id, 7),
      // children: [
      //   {
      //     name: 'List',
      //     icon: 'material-symbols-light:list-alt-check-outline',
      //     to: '/Inspection',
      //     action: 'read',
      //     collection: 'Inspection',
      //   },
      // ],
    },
    {
      id: 4,
      submenu_id: 4,
      name: 'Equipments',
      icon: 'mdi:excavator',
      to: `/asset/location/` + (id ? id : ''),
      action: 'read',
      collection: 'Assets',
      is_show: set_show(id, 4),
    },
    {
      id: 6,
      submenu_id: 6,
      name: 'Warehouse',
      icon: 'mdi:warehouse',
      to: `/parts/location/` + (id ? id : ''),
      action: 'read',
      collection: 'Parts',
      is_show: set_show(id, 6),
    },
    {
      id: 9,
      submenu_id: 9,
      name: 'Failure Analysis',
      icon: 'mdi:clipboard-alert-outline',
      to: `/failures/location/` + (id ? id : ''),
      action: 'read',
      collection: 'Failure_analyze_result',
      is_show: set_show(id, 9),
    },
    {
      id: 10,
      submenu_id: 10,
      name: 'Bin Location',
      icon: 'fluent:board-16-filled',
      to: `/transaction/location/binlocation/` + (id ? id : ''),
      action: 'read',
      collection: 'Bin_location',
      is_show: set_show(id, 10),
    },
    {
      id: 11,
      submenu_id: 11,
      name: 'Incomes',
      icon: 'mdi:cash-plus',
      to: `/transaction/location/income/` + (id ? id : ''),
      action: 'read',
      collection: 'Parts',
      is_show: set_show(id, 11),
    },
    {
      id: 12,
      submenu_id: 12,
      name: 'Debts',
      icon: 'mdi:cash-minus',
      to: `/transaction/location/outcome/` + (id ? id : ''),
      action: 'read',
      collection: 'Parts',
      is_show: set_show(id, 12),
    },
    /* {
        name: 'Vendors',
        icon: 'arcticons:vendora',
        to: '/parts',
      },
      {
        name: 'PO',
        icon: 'carbon:purchase',
        to: '/po',
      },
      {
        name: 'Bills',
        icon: 'healthicons:bills',
        to: '/bills',
      }*/
  ]

  // if (window.location.hostname === 'smartgps.ibex.mn') {
  //   sub_menus = sub_menus.filter(
  //     (menu) => menu.submenu_id !== 7 && menu.submenu_id !== 8,
  //   )
  // }

  return sub_menus
}
export default locationMenus
