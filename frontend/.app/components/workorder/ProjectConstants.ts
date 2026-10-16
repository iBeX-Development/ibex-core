const priorities = [
  {
    text: 'Low',
    label: 'Low',
    value: 1,
    icon: 'iconoir:priority-down-solid',
    iconColor: '#8363ee',
    media: '/img/icons/priority/low.svg',
    defaultColor: '#facc15',
  },
  {
    text: 'High',
    label: 'High',
    value: 2,
    icon: 'iconoir:priority-high-solid',
    iconColor: '#e37f0d',
    media: '/img/icons/priority/high.svg',
    defaultColor: '#f43f5e',
  },
  {
    text: 'Medium',
    label: 'Medium',
    value: 3,
    icon: 'iconoir:priority-medium-solid',
    iconColor: '#efd548',
    media: '/img/icons/priority/medium.svg',
    defaultColor: '#f97316',
  },
  {
    text: 'Urgent',
    label: 'Urgent',
    value: 4,
    icon: 'mingcute:emergency-flashers-fill',
    iconColor: '#f43f5e',
    media: '/img/icons/priority/urgent.svg',
    defaultColor: '#a855f7',
  },
]

// wo_status
const statuses = [
  {
    text: 'New',
    value: 0,
    color: '#f2f5f9',
    icon: 'ph:plus-circle-duotone',
    media: '/img/icons/priority/low.svg',
  },
  {
    text: 'In process',
    value: 1,
    color: '#2196F3',
    icon: 'ph:timer-duotone',
    media: '/img/icons/priority/high.svg',
  },
  // {
  //   text: 'blocked',
  //   value: 2,
  //   color: '#ef0b0b',
  //   icon: 'ph:warning-duotone',
  //   media: '/img/icons/priority/high.svg',
  // },
  {
    text: 'On hold',
    value: 3,
    color: '#FF9800',
    icon: 'ph:warning-duotone',
    media: '/img/icons/priority/high.svg',
  },
  // {
  //   text: 'inReview',
  //   value: 4,
  //   color: '#3d1aea',
  //   icon: 'icon-park-outline:reject',
  // },
  {
    text: 'Done',
    value: 5,
    color: '#4CAF50',
    icon: 'ph:check-circle-duotone',
    media: '/img/icons/priority/high.svg',
  },
]

const active = [
  {
    text: 'Active',
    value: '1',
  },
  {
    text: 'Inactive',
    value: '0',
  },
]

// const action_status = [
//   {
//     "text": "Accepted",
//     "value": "1"
//   },
//   {
//     "text": "Declined",
//     "value": "0"
//   }
// ]

const action_status = [
  {
    id: 1,
    name: 'created',
    icon: 'mdi:plus-circle-outline',
    color: '#3498db', // Blue
  },
  {
    id: 5,
    name: 'accepted',
    icon: 'solar:recive-square-line-duotone',
    color: '#3d1aea', //
  },
  {
    id: 6,
    name: 'declined',
    icon: 'icon-park-outline:reject',
    color: '#ef0b0b', //
  },
  {
    id: 2,
    name: 'approved',
    icon: 'mdi:check-circle-outline',
    color: '#27ae60', // Green
  },
  {
    id: 4,
    name: 'assigned',
    icon: 'mdi:account-arrow-right',
    color: '#811edf', // Yellow
  },
  {
    id: 3,
    name: 'returned',
    icon: 'mdi:undo',
    color: '#e74c3c', // Red
  },

  {
    id: 0,
    name: 'deleted',
    icon: 'mdi:delete',
    color: '#666666',
  },
  {
    id: 7,
    name: 'completed',
    icon: 'mdi:check-circle-outline',
    color: '#4caf50', //
  },
]

export { action_status, active, priorities, statuses }
