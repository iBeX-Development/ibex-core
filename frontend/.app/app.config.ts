/**
 * This file is used to configure the app
 *
 * If you have the "Cannot find name 'defineAppConfig'.ts(2304)" error
 * update the root tsconfig.json file to include the following:
 *
 *  "extends": "./.app/.nuxt/tsconfig.json"
 *
 */

export default defineAppConfig({
  nuxtIcon: {},
  nui: {
    defaultShapes: {},
  },
  toaster: {
    theme: {
      // #nt-container-д position/z-index анхнаасаа тохируулаагүй байсан тул
      // toast нь нээлттэй modal-ийн (z-[9999]) ард нуугдаж байсан
      containerClass:
        'fixed top-4 end-4 z-[99999] flex flex-col gap-4 pointer-events-none',
    },
  },
  tairo: {
    title: 'Work open management',
    sidebar: {
      toolbar: {
        showNavBurger: true,
        tools: [
          {
            component: 'DemoThemeToggle',
            props: {
              disableTransitions: true,
            },
          },
          {
            component: 'DemoToolbarLanguage',
          },
          {
            component: 'DemoToolbarNotifications',
          },
          {
            component: 'DemoToolbarActivity',
          },
          {
            component: 'DemoToolbarAccountMenu',
          },
        ],
      },
      circularMenu: {
        enabled: true,
        tools: [
          // {
          //   component: 'DemoThemeToggle',
          //   props: {
          //     class: 'ms-auto',
          //     disableTransitions: true,
          //     inverted: true,
          //   },
          // },
          {
            component: 'DemoCircularMenuLanguage',
          },
          {
            component: 'DemoCircularMenuNotifications',
          },
          {
            component: 'DemoCircularMenuActivity',
          },
        ],
      },
      navigation: {
        logo: {
          component: 'TairoLogo',
          props: { class: 'text-primary-600 h-10' },
        },
        items: [],
      },
    },
    panels: [
      {
        name: 'language',
        position: 'right',
        component: 'DemoPanelLanguage',
      },
      {
        name: 'activity',
        position: 'right',
        component: 'DemoPanelActivity',
      },
      {
        name: 'print',
        position: 'right',
        component: 'DemoPrintActivity',
      },
      {
        name: 'print_single',
        position: 'right',
        component: 'DemoPrintActivityDefault',
      },
      {
        name: 'printMulti',
        position: 'right',
        component: 'DemoPrintActivityMulti',
      },
      {
        name: 'printWoSummary',
        position: 'right',
        component: 'WorkOrderPrintSummary',
      },
      {
        name: 'asset',
        position: 'right',
        component: 'DemoAssetMore',
      },
      {
        name: 'binlocation',
        position: 'right',
        component: 'DemoBinLocationMore',
      },
      {
        name: 'transaction',
        position: 'right',
        component: 'DemoTransactionMore',
      },
      {
        name: 'workorderopenmore',
        position: 'right',
        component: 'WorkOrderOpenMore',
      },
      {
        name: 'workordercompletedmore',
        position: 'right',
        component: 'WorkOrderCompletedMore',
      },
      {
        name: 'workorderpmmore',
        position: 'right',
        component: 'WorkOrderPmMore',
      },
      {
        name: 'workorderprmore',
        position: 'right',
        component: 'WorkOrderPrMore',
      },
      {
        name: 'demopanelcompany',
        position: 'right',
        component: 'DemoPanelCompany',
      },
      {
        name: 'search',
        position: 'right',
        component: 'DemoPanelSearch',
      },
      {
        name: 'task',
        position: 'right',
        component: 'DemoPanelTask',
      },
      {
        name: 'inspectionmore',
        position: 'right',
        component: 'InspectionMore',
      },

      {
        name: 'rolePermissionMore',
        position: 'right',
        component: 'DemoRolePermissionMore',
      },
      {
        name: 'packagePermissionMore',
        position: 'right',
        component: 'DemoPackagePermissionMore',
      },
    ],
    error: {
      logo: {
        component: 'img',
        props: {
          src: '/img/illustrations/system/404-1.svg',
          class: 'relative z-20 w-full max-w-lg mx-auto',
        },
      },
    },
  },
})
