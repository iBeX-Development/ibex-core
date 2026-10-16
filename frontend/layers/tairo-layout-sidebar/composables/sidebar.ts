/**
 * Composable to manage navigation of the sidebar layout
 *
 * You can define sidebar items in your app.config.ts
 *
 * ```ts
 * export default defineAppConfig({
 *   tairo: {
 *     sidebar: {
 *       items: {
 *           name: 'Dashboards',
 *
 *           // You can define an active path to highlight the item
 *           activePath: '/dashboards',
 *
 *           // You can define an icon to display in the sidebar
 *           icon: { name: 'ph:sidebar-duotone', class: 'w-5 h-5' },
 *
 *           // Or use a component
 *           // It should be registered in the app as a global component (in components/global)
 *           component: { name: 'AppThemeToggle', props: {} },
 *
 *           // You can chose to display a subsidebar by defining a component name
 *           // It should be registered in the app as a global component
 *           subsidebar: { name: 'SidebarMenuDashboards', props: {} },
 *
 *           // Or you can define a route to navigate to
 *           to: '/dashboards',
 *
 *           // Or you can define a click handler (eg. to open a panel)
 *           click: () => {
 *             const { open } = usePanels()
 *             open('panel-name')
 *           },
 *         },
 *       ],
 *     },
 *   },
 * })
 * ```
 */
export function useSidebar() {
  const app = useAppConfig()
  const route = useRoute()
  let defaultMenus = [
    {
      title: 'Location',
      icon: { name: 'gis:layers-o', class: 'w-5 h-5' },
      subsidebar: { component: 'SubsidebarAssets' },
    },

    {
      title: 'Position',
      icon: { name: 'gis:folder-pois', class: 'w-5 h-5' },
      subsidebar: {
        component: 'SubsidebarPosition',
        props: { filter: 'position' },
      },
    },
    {
      title: 'Parts',
      icon: { name: 'ic:outline-mark-as-unread', class: 'w-5 h-5' },
      subsidebar: {
        component: 'SubsidebarParts',
        props: { filter: 'parts' },
      },
    },
    {
      title: 'Users and team',
      icon: {
        name: 'material-symbols:settings-account-box',
        class: 'w-5 h-5',
      },
      subsidebar: {
        component: 'SubsidebarSettings',
        props: { filter: 'users and team' },
      },
    },
    {
      title: 'My Account',
      component: 'DemoAccountMenu',
      position: 'end',
    },
  ]

  const sidebars = computed(() => {
    if (
      app.tairo.sidebar?.navigation?.enabled === false ||
      app.tairo.sidebar?.navigation?.items?.length === 0
    ) {
      const permissions = JSON.parse(
        window.localStorage.getItem('app_permissions') || '{}',
      )
      const myId = window.localStorage.getItem('myId')

      let menus = [
        {
          title: 'Location',
          icon: { name: 'gis:layers-o', class: 'w-5 h-5' },
          subsidebar: { component: 'SubsidebarAssets' },
        },
      ]

      if (permissions && permissions[1] && permissions[1].includes('admin')) {
        let admin_menus = []
        let menus = JSON.parse(window.localStorage.getItem('menus'))

        if (menus) {
          admin_menus = menus.map((item) => {
            let icon_name = item.icon_name ? true : null
            let subsidebar = {
              auto_click: item.is_direct ? true : false,
              push: `${item.filter}`,
              subsidebar: {
                component: item.component,
                ...(item.filter && {
                  props: { filter: item.filter },
                }),
              },
            }
            if (item.position === 'end') {
              subsidebar = { component: 'DemoAccountMenu' }
            }

            return {
              title: item.title,
              position: item.position,
              ...subsidebar,
              ...(icon_name && {
                icon: {
                  name: item.icon_name,
                  class: 'w-5 h-5',
                },
              }),
            }
          })
        }

        if (admin_menus?.length > 0) return admin_menus
        else return menus

        // return defaultMenus
      } else {
        let show_menus = []
        let menu_users = JSON.parse(window.localStorage.getItem('menus'))
        if (menu_users) {
          show_menus = menu_users.map((item) => {
            const icon_name = item.icon_name ? true : null
            let subsidebar = {
              auto_click: item.is_direct ? true : false,
              push: `${item.filter}`,
              subsidebar: {
                component: item.component,
                ...(item.filter && {
                  props: { filter: item.filter },
                }),
              },
            }
            if (item.position === 'end') {
              subsidebar = { component: 'DemoAccountMenu' }
            }

            return {
              title: item.title,
              position: item.position,
              ...subsidebar,
              ...(icon_name && {
                icon: {
                  name: item.icon_name,
                  class: 'w-5 h-5',
                },
              }),
            }
          })
        }

        // console.log('show_menus', show_menus)
        if (show_menus?.length > 0) return show_menus
        else return menus
      }
      // return app.tairo.sidebar.navigation?.items
    }
    // app.tairo.sidebar.navigation.items = defaultMenus
    // return app.tairo.sidebar?.navigation?.items
  })

  const currentName = useState('sidebar-name', () => '')
  const isOpen = useState<boolean | undefined>('sidebar-open', () => undefined)

  const hasSubsidebar = computed(() => {
    return sidebars.value?.some((sidebar) => sidebar.subsidebar?.component)
  })

  const current = computed(() => {
    if (!currentName.value) {
      return undefined
    }
    return sidebars.value?.find(({ title }) => title === currentName.value)
  })

  function toggle() {
    // If no sidebar item is selected, open the first one
    if (!currentName.value && !isOpen.value) {
      if (!sidebars.value?.[0]?.title) {
        // No sidebar items defined
        return
      }

      // Select the first sidebar item by default
      currentName.value = sidebars.value[0].title
    }

    isOpen.value = !isOpen.value
  }

  function close(unselect = false) {
    isOpen.value = false
    if (unselect) {
      currentName.value = ''
    }
  }

  function open(name: string) {
    currentName.value = name
    isOpen.value = true
  }

  function detect() {
    if (!app.tairo.sidebar?.navigation?.startOpen) {
      isOpen.value = false
      return
    }

    const item = sidebars.value?.find(
      (bar) => bar?.activePath && route.fullPath.startsWith(bar.activePath),
    )
    if (item) {
      currentName.value = item.title
      if (!process.client) {
        isOpen.value = Boolean(currentName.value)
      } else {
        const isXl = useTailwindBreakpoints().xl.value
        isOpen.value = Boolean(currentName.value) && isXl
      }
    }
    return
  }

  function setup() {
    // Detect sidebar item on server page load
    if (!process.client) {
      detect()
      return
    }

    // Detect sidebar item on client page change
    // page:finish allow to wait for the page to be fully loaded before detecting the sidebar item
    const nuxtApp = useNuxtApp()
    const removeHook = nuxtApp.hook('page:finish', (e) => {
      detect()
      removeHook()
      return
    })

    // register a watcher to close sidebar when screen become extra large
    const { xl } = useTailwindBreakpoints()
    // close sidebar when screen become extra large
    watch(xl, (isXl) => {
      if (!isXl) {
        isOpen.value = false
      }
    })

    // register a watcher to open sidebar when a sidebar item is selected
    watch(
      () => currentName,
      (value) => {
        if (value) {
          // only open sidebar if it's not already open
          // and the screen is not extra large
          if (xl.value) {
            isOpen.value = true
          }
        } else {
          isOpen.value = false
        }
      },
    )
  }

  return {
    sidebars,
    hasSubsidebar,
    current,
    currentName,
    isOpen,
    toggle,
    close,
    open,
    detect,
    setup,
  }
}
