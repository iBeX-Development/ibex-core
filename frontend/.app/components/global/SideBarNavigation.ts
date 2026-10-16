//dotorh zadardag hesguud

const navigation = [
  // {
  //   name: 'Inventory',
  //   children: [
  //     {
  //       name: 'Parts list',
  //       icon: 'simple-icons:steamdb',
  //       to: '/parts/list',
  //       action: 'read',
  //       collection: 'Parts',
  //     },
  //   ],
  // },
  // {
  //   name: 'Transaction',
  //   children: [
  //     {
  //       name: 'Income',
  //       icon: 'material-symbols:input-circle',
  //       to: '/transaction/income',
  //       action: 'read',
  //       collection: 'Transaction',
  //     },
  //     {
  //       name: 'Debt',
  //       icon: 'material-symbols:output-circle-rounded',
  //       to: '/transaction/outcome',
  //       action: 'read',
  //       collection: 'Transaction',
  //     },
  //   ],
  // },
  // {
  //   name: 'Requests',
  //   is_direct: true,
  //   to: '/works/requests',
  //   action: 'read',
  //   collection: 'Work_order',
  // },
  {
    name: 'Health and Safety',
    is_direct: true,
    to: '/health',
    action: 'read',
    collection: 'Health',
    // children: [
    //   {
    //     name: 'List',
    //     icon: 'material-symbols-light:list-alt-check-outline',
    //     to: '/health',
    //     action: 'read',
    //     collection: 'Health',
    //   },
    // ],
  },
  {
    name: 'Projects',
    is_direct: true,
    // to: '/projects',
    // action: 'read',
    // collection: 'Projects',
    children: [
      {
        name: 'List',
        icon: 'material-symbols-light:list-alt-add-outline',
        to: '/projects',
        action: 'read',
        collection: 'Projects',
        exact: true,
      },
      {
        name: 'Done',
        icon: 'lets-icons:done-ring-round-duotone',
        to: '/projects/completed',
        action: 'read',
        collection: 'Projects',
      },
    ],
  },
  {
    name: 'Contractors',
    is_direct: true,
    to: '/contractors',
    action: 'read',
    collection: 'Contractors',
    children: [
      {
        name: 'List',
        icon: 'material-symbols-light:list-alt-outline',
        to: '/contractors',
        action: 'read',
        collection: 'Contractors',
      },
    ],
  },
  {
    name: 'Teams',
    is_direct: true,
    to: '/teams',
    action: 'read',
    collection: 'Teams',
    children: [
      {
        name: 'List',
        icon: 'material-symbols:groups-outline-sharp',
        to: '/teams',
        action: 'read',
        collection: 'Teams',
      },
    ],
  },
  {
    name: 'Mytask',
    is_direct: true,
    to: '/mytask',
    action: 'read',
    // collection: 'Teams',
    children: [
      {
        name: 'My Activity',
        icon: 'material-symbols:groups-outline-sharp',
        to: '/mytask',
        action: 'read',
        collection: 'Mytask',
      },
    ],
  },
  {
    name: 'Reports',
    is_direct: true,
    to: '/reports',
    action: 'read',
    // collection: 'Teams',
  },
  // {
  //   name: 'Warehouse',
  //   is_direct: true,
  //   to: '/warehouse',
  //   action: 'read',
  //   collection: 'Warehouse',
  //   children: [
  //     {
  //       name: 'List',
  //       icon: 'mdi:warehouse',
  //       to: '/warehouse',
  //       action: 'read',
  //       collection: 'Warehouse',
  //     },
  //   ],
  // },
]

export default navigation
