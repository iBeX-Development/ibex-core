const navigation = [
  {
    name: 'Position',
    children: [
      {
        name: 'Company',
        icon: 'ph:buildings-duotone',
        to: '/settings/company',

        action: 'read',
        collection: 'Company',
      },
      // {
      //   name: 'Companies',
      //   icon: 'streamline-ultimate:office-building-tall-2',
      //   to: '/companies',
      //   action: 'read',
      //   collection: 'Companies',
      // },
      {
        name: 'Login',
        icon: 'mdi:web-clock',
        to: '/settings/logins',
        action: 'read',
        collection: 'Login_page',
      },
      {
        name: 'Region',
        icon: 'gis:bbox-alt',
        to: '/region',
        action: 'read',
        collection: 'Region',
      },
      {
        name: 'Location',
        icon: 'gis:location-poi-o',
        to: '/location',
        action: 'read',
        collection: 'Location',
      },
    ],
  },
  {
    name: 'Assets',
    children: [
      {
        name: 'Asset Type',
        icon: 'ph:piggy-bank-duotone',
        to: '/assettype',

        action: 'read',
        collection: 'Assets_type',
      },
      {
        name: 'Manufacturer',
        icon: 'fluent:manufacturer-24-regular',
        to: '/manufacturer',

        action: 'read',
        collection: 'Manufacturer',
      },
      {
        name: 'Supplier',
        icon: 'carbon:scis-transparent-supply',
        to: '/supplier',

        action: 'read',
        collection: 'Supplier',
      },

      {
        name: 'Reading type',
        icon: 'ic:outline-mark-as-unread',
        to: '/readingtype',

        action: 'read',
        collection: 'Reading_type',
      },
      {
        name: 'Sensors',
        icon: 'fluent:device-meeting-room-microphone-below-16-regular',
        to: '/sensors',
        action: 'read',
        collection: 'Sensors',
      },

      // {
      //   name: 'Parts',
      //   icon: 'ic:outline-mark-as-unread',
      //   to: '/parts',

      //   action: 'read',
      //   collection: 'Parts',
      // },
    ],
  },
  {
    name: 'Manage Work Order',
    children: [
      {
        name: 'Template',
        icon: 'ph:briefcase-duotone',
        to: '/settings/task/template',

        action: 'read',
        collection: 'Template',
      },
      {
        name: 'Status',
        icon: 'ph:squares-four-duotone',
        to: '/settings/status',
        action: 'read',
        collection: 'Status',
      },
      {
        name: 'Trades',
        icon: 'clarity:employee-group-line',
        to: '/settings/trades',
        action: 'read',
        collection: 'Trades',
      },
      {
        name: 'Department',
        icon: 'mingcute:department-line',
        to: '/department',

        action: 'read',
        collection: 'Department',
      },
      {
        name: 'Work types',
        icon: 'eos-icons:product-classes-outlined',
        to: '/work_types',
        action: 'read',
        collection: 'Work_types',
      },
      {
        name: 'Work Group Types',
        icon: 'i-material-symbols:hotel-class-outline',
        to: '/work_group_types',
        action: 'read',
        collection: 'Work_group_type',
      },
    ],
  },
  {
    name: 'Schedule Maintenance',
    children: [
      {
        name: 'Schedule',
        icon: 'hugeicons:time-schedule',
        to: '/pm/schedule',

        action: 'read',
        collection: 'Schedule',
      },
    ],
  },

  // {
  //   name: 'Predictive Maintenance',
  //   children: [
  //     {
  //       name: 'predictive',
  //       icon: 'hugeicons:time-schedule',
  //       to: '/predictive/schedule',

  //       action: 'read',
  //       collection: 'predictive_schedule',
  //     },
  //   ],
  // },
  {
    name: 'Users and Team',
    children: [
      {
        name: 'Users',
        icon: 'ph:user-fill',
        to: '/settings/user',

        action: 'read',
        collection: 'Users',
      },
      {
        name: 'Team',
        icon: 'ph:users-four-duotone',
        to: '/settings/team',

        action: 'read',
        collection: 'Team',
      },
      {
        name: 'News',
        icon: 'gis:bbox-alt',
        to: '/settings/news',

        action: 'read',
        collection: 'news',
      },
      {
        name: 'Permission',
        icon: 'ph:lock-open-duotone',
        to: '/settings/permission',

        action: 'read',
        collection: 'directus_roles',
      },
      {
        name: 'Roles',
        icon: 'oui:app-users-roles',
        to: '/settings/roles',
        action: 'read',
        collection: 'directus_roles',
      },
    ],
  },
  {
    name: 'Parts',
    children: [
      {
        name: 'Uom list',
        icon: 'ic:outline-mark-as-unread',
        to: '/settings/uom',
        action: 'read',
        collection: 'Unit of measure',
      },
      {
        name: 'Segments',
        icon: 'ph:line-segments-fill',
        to: '/settings/segments',
        action: 'read',
        collection: 'Segments',
      },
      {
        name: 'Category',
        icon: 'i-material-symbols:hotel-class-outline',
        to: '/settings/class',
        action: 'read',
        collection: 'Class',
      },
      {
        name: 'Commodity',
        icon: 'i-iconoir:commodity',
        to: '/settings/commodity',
        action: 'read',
        collection: 'Commodity',
      },
      {
        name: 'State',
        icon: 'ph:squares-four-duotone',
        to: '/settings/state',
        action: 'read',
        collection: 'State',
      },
    ],
  },
  {
    name: 'Monitoring',
    children: [
      // {
      //   name: 'Alert types',
      //   icon: 'ph:bell-ringing-duotone',
      //   to: '/alerttype',
      //   action: 'read',
      //   collection: 'Alert_type',
      // },
      {
        name: 'Monitoring Commands',
        icon: 'ph:list-bullets-duotone',
        to: '/settings/monitoring/commands',
        action: 'read',
        collection: 'Monitoring_alerts',
      },
      {
        name: 'Bulk apply',
        icon: 'ph:stack-plus-duotone',
        to: '/settings/monitoring/bulk',
        action: 'create',
        collection: 'Monitoring_alerts',
      },
      {
        name: 'Monitoring backups',
        icon: 'ph:database-duotone',
        to: '/settings/monitoring/backups',
        action: 'create',
        collection: 'Monitoring_alerts',
      },
    ],
  },
  {
    name: 'Contracts',
    children: [
      {
        name: 'Payment terms',
        icon: 'streamline:money-cash-dollar-coin-accounting-billing-payment-cash-coin-currency-money-finance',
        to: '/settings/payment',
        action: 'read',
        collection: 'Payment_term',
      },
      {
        name: 'Income terms',
        icon: 'token:ern',
        to: '/settings/incomes',
        action: 'read',
        collection: 'Income_term',
      },
      {
        name: 'Currency',
        icon: 'bi:currency-exchange',
        to: '/settings/currency',
        action: 'read',
        collection: 'Currency',
      },
    ],
  },
  {
    name: 'Templates',
    children: [
      {
        name: 'WO Prints',
        icon: 'streamline:money-cash-dollar-coin-accounting-billing-payment-cash-coin-currency-money-finance',
        to: '/settings/prints',
        action: 'read',
        collection: 'Prints_tempates',
      },
      {
        name: 'Failure Analysis',
        icon: 'hugeicons:time-schedule',
        to: '/settings/failure',
        action: 'read',
        collection: 'Failure_analysis',
      },
    ],
  },
  {
    name: 'Language',
    children: [
      {
        name: 'Language',
        icon: 'iconoir:language',
        to: '/settings/language',
        action: 'read',
        collection: 'Language',
      },
    ],
  },
]

// Check hostname for conditional component rendering
// const isSmartGPS = ref(false)
// if (process.client) {
//   isSmartGPS.value = window.location.hostname === 'smartgps.ibex.mn'
// }

export default navigation
