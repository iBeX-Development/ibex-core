<script setup lang="ts">
import { Container, Draggable } from 'vue3-smooth-dnd'
import { getDemoDetails } from '../detailsData'

definePageMeta({
  title: 'Project Board',
  layout: 'empty',
  middleware: ['auth'],
  showback: true,
  preview: [
    {
      title: 'Project board',
      description: 'For a fitness project kanban board',
      categories: ['layouts', 'projects', 'kanban'],
      src: '/img/screens-projects-board.png',
      srcDark: '/img/screens-projects-board-dark.png',
      order: 74,
      params: {
        slug: 'health-and-fitness-dashboard',
      },
    },
    {
      title: 'Project board',
      description: 'For a banking project kanban board',
      categories: ['layouts', 'projects', 'kanban'],
      src: '/img/screens-projects-board.png',
      srcDark: '/img/screens-projects-board-dark.png',
      order: 74,
      params: {
        slug: 'banking-and-finance-dashboard',
      },
    },
  ],
})
const props = defineProps({
  key: Number,
  datas: Object,
  refresh: Function,
  rowId: Number,
})
interface ColumnContent {
  title: string
  tasks: any[]
}

interface Column {
  [key: string]: ColumnContent
}

const columns = reactive<Column>({
  new: {
    title: t('New'),
    tasks: [],
  },
  inProgress: {
    title: t('In Progress'),
    tasks: [],
  },
  // blocked: {
  //   title: 'Blocked',
  //   tasks: [],
  // },
  onHold: {
    title: t('On Hold'),
    tasks: [],
  },
  // inReview: {
  //   title: 'In Review',
  //   tasks: [],
  // },
  done: {
    title: t('Done'),
    tasks: [],
  },
})

const { open, close } = usePanels()

import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const { getUsers } = useDirectusUsers()
const myCompanyId = getMyCompanyId()
// comments
const myId = window.localStorage.getItem('myId')
const userImgId = ref(null)
const task_id = ref(-1)
const project_id = ref(-1)
const my_name = ref('')
const my_id = ref('')
const userImgUrl = ref(null)
let wo_ids = []

const toaster = useToaster()
const route = useRoute()
const router = useRouter()
const data = ref([])
const initial_datas = ref([])
const config = useRuntimeConfig()

const isModalApproveConfirmOpen = ref(false)
const isModalCompanyOpen = ref(false)
const isModalTeamsOpen = ref(false)
const isModalOpen = ref(false)
const key = ref(1)

const search = ref('')
const serverItems = ref([])
const works = ref([])
const loading = ref(false)
const totalItems = ref(0)
const sDate = ref(null)
const dDate = ref(new Date())
const cDate = ref(new Date())
const cDateTime = ref(null)
const alertMsg = ref(false)
const contractor_team = ref([])
const progressComponent = ref(null)
const progressCircleComponent = ref(null)
const commentArea = ref('')

const isModalNewFile = ref(false)
const itemsValue = ref(-1)
const uploadedFiles = ref([])
const editFiles = ref([])
const rowData = ref([])
const rowFiles = ref([])
const files = ref(false)
const selectedItem = ref(-1)
let transformedFiles = []

const category_status = ref(1)
let category_options = ref(['Mining', 'Software', 'Foods', 'Education'])

const categories = ref([
  {
    label: 'Health Safety Environment Security And Communities',
    value: 1,
  },
  {
    label: 'People And Organization',
    value: 2,
  },
  {
    label: 'Mine Operations Concentrator Maintenance',
    value: 3,
  },
  {
    label: 'Underground',
    value: 4,
  },
  {
    label: ' Operator Production Truck',
    value: 5,
  },
])

const objectValue = ref({
  id: 4,
  name: 'Underground',
  icon: 'mdi:progress-clock',
})

const statusValue = ref({
  id: 1,
  name: 'Status',
  icon: 'mdi:progress-clock',
})
const comments = ref([
  {
    text: 'I think buttons corners should be a little more rounded.',
    author: {
      name: 'Marjory L.',
      picture: '/img/avatars/12.svg',
      posted: '2 days ago',
    },
  },
  {
    text: 'Are you planning to add this as a global setting in the configuration file?',
    author: {
      name: 'Kendra W.',
      picture: '/img/avatars/10.svg',
      posted: '2 days ago',
    },
  },
  {
    text: 'Not sure about it yet. Still need to check this out with the engineering team',
    author: {
      name: 'Marjory L.',
      picture: '/img/avatars/12.svg',
      posted: '2 days ago',
    },
  },
])

const slug = computed(() => route.params.slug)
const query = computed(() => {
  return {
    slug: slug.value,
  }
})

const get_file_type = (file) => {
  let type = ''
  if (file?.type.includes('image')) {
    type = '/img/icons/files/ai.svg'
  } else if (file?.type.includes('video')) {
    type = '/img/icons/files/video.svg'
  } else if (file?.type.includes('doc')) {
    type = '/img/icons/files/doc-2.svg'
  } else if (file?.type.includes('pdf')) {
    type = '/img/icons/files/pdf.svg'
  } else if (file?.type.includes('xlsx')) {
    type = '/img/icons/files/sheet.svg'
  } else if (file?.type.includes('pptx')) {
    type = '/img/icons/files/ppt.svg'
  }

  return type
}

const get_content_url = (file, type) => {
  // console.log('file ->', file)

  if (type == 'avatar') {
    if (file && file.type.includes('image')) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else if (file) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else {
      return `/img/avatars/3.svg`
    }
  }

  if (type == 'project') {
    if (file && file.type.includes('image')) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else {
      return `/img/projects/15.jpg`
    }
  }

  if (type == 'leader') {
    if (file && file.type.includes('image')) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else {
      return `/img/avatars/1.svg`
    }
  }
}

function transformProjects(serverData, initial_items, works) {
  // console.log('text', initial_items)
  // console.log('serverData', serverData)
  // console.log('works', works)
  let transformedTasks = []
  const filtered = initial_items.data.find(
    (item) => item.id == serverData[0].id,
  )

  const filtered_task = works.filter((item) => item.project == serverData[0].id)

  transformedTasks = filtered_task.map((item) => {
    // console.log('item', item)
    let taskList = []
    wo_ids.push(item.id)

    if (item.checklist.length) {
      taskList = item.checklist.map((item) => {
        return {
          id: item.id,
          text: item.name,
          done: parseInt(item.value) == 1 ? true : false,
          author: {
            id: item.user_created.id,
            name: item.user_created.first_name,
            last_name: item.user_created.last_name,
            picture: item.user_created.avatar
              ? `${config.public.directus.url}assets/${item.user_created.avatar?.filename_disk}`
              : null,
          },
        }
      })
    }

    if (item.files.length) {
      item.files.map((item) => {
        const file = item.file || {}
        const user = item.user_created || {}
        // console.log('item', item)

        // Convert file size from bytes to KB/MB/GB for readability
        const fileSizeInKB = file.filesize / 1024 // Convert bytes to KB
        let fileSize = fileSizeInKB.toFixed(2) + ' KB' // Default size in KB
        if (fileSizeInKB > 1024) {
          const fileSizeInMB = fileSizeInKB / 1024 // Convert to MB
          fileSize = fileSizeInMB.toFixed(2) + ' MB'
        }
        if (fileSizeInKB > 1024 * 1024) {
          const fileSizeInGB = fileSizeInKB / (1024 * 1024) // Convert to GB
          fileSize = fileSizeInGB.toFixed(2) + ' GB'
        }

        transformedFiles.push({
          row_id: item.id,
          id: file.id,
          type: file.type,
          filename_disk: file.filename_disk || 'filename_disk',
          name: file.filename_disk || 'Unnamed File', // Default fallback for missing name
          icon: get_file_type(file), // Ensure get_file_type() is defined correctly
          size: fileSize,
          version: '1.8.2', // Static version, could be dynamic if needed
          uploaded: file.uploaded_on || 'N/A', // Fallback if 'uploaded_on' is missing
          author: {
            id: user.id || 'Unknown', // Fallback for missing author id
            name: user.first_name || 'Unknown', // Fallback for missing author name
            picture: get_content_url(user.avatar, 'avatar') || '', // Ensure URL is valid
          },
        })
      })
    }

    return {
      id: item.id,
      name: item.name,
      status: item.status,
      priority: item.priority,
      description: item.description,
      started_at: item.started_at,
      due: item.due,
      task_leaders: item.task_leaders,
      assignee: item.task_leaders.map((assignee) => {
        // console.log('assignee', assignee)
        return {
          src: get_content_url(assignee.directus_users_id.avatar, 'avatar'),
          badge: '/img/stacks/illustrator.svg',
          role: assignee.directus_users_id.role.name,
          bio: assignee.directus_users_id.email,
          tooltip:
            assignee.directus_users_id.first_name +
            ' .' +
            assignee.directus_users_id.last_name.substring(0, 2),
          id: assignee.directus_users_id.id,
          text: assignee.directus_users_id.location,
        }
      })[0],
      task_members: item.task_members,
      task_company: item.task_company,
      completion: 100,
      checklist: taskList,
      comments: item.comments.map((comment) => {
        return {
          id: comment.id,
          text: comment.text,
          author: {
            id: comment.user_created.id,
            name: comment.user_created.first_name,
            last_name: comment.user_created.last_name,
            posted: '7 hours ago',
            picture: comment.user_created.avatar
              ? `${config.public.directus.url}assets/${comment.user_created.avatar?.filename_disk}`
              : null,
          },
        }
      }),
      files: item.files.map((fileItem) => {
        // console.log('file', fileItem)
        return {
          id: fileItem.id,
          filename_download: fileItem.file.filename_download,
          name: fileItem.file.filename_download,
          icon: '/img/icons/files/doc-2.svg',
          title: fileItem.file.title,
          uploaded: '2 weeks ago',
          type: fileItem.file.type,
          size: fileItem.file.filesize,
          width: fileItem.file.width,
          height: fileItem.file.height,
          version: '1.8.2',
          author: {
            name: 'Melany D.',
            picture: '/img/avatars/25.svg',
          },
        }
      }),
    }
  })

  return serverData.map((project) => {
    const teamUsers = project.team.flatMap((teamItem) => {
      const team = teamItem.Teams_id
      const users = team?.users || []
      const team_leaders = team?.team_leaders || []

      const team_leaderss = team_leaders.map((user) => {
        const directusUser = user.directus_users_id
        const fname = `${directusUser?.first_name || ''} ${
          directusUser?.last_name || ''
        }`.trim()

        return {
          id: directusUser?.id,
          full_name: fname,
          text: directusUser.email || filtered?.team[0].text,
          email: directusUser?.email,
          tooltip: fname,
          'data-nui-tooltip': fname,
          avatar: get_content_url(directusUser?.avatar, 'avatar'),
          location: directusUser?.location,
          role: `Team leader, ` + directusUser?.role?.name,
          status: directusUser?.status,
          src: get_content_url(directusUser?.avatar, 'avatar'),
          badge: '/img/stacks/illustrator.svg',
        }
      })

      const userss = users.map((user) => {
        const directusUser = user.directus_users_id
        const fname = `${directusUser?.first_name || ''} ${
          directusUser?.last_name || ''
        }`.trim()

        return {
          id: directusUser?.id,
          full_name: fname,
          text: directusUser.email || filtered?.team[0].text,
          email: directusUser?.email,
          tooltip: fname,
          'data-nui-tooltip': fname,
          avatar: get_content_url(directusUser?.avatar, 'avatar'),
          location: directusUser?.location,
          role: directusUser?.role?.name,
          status: directusUser?.status,
          src: get_content_url(directusUser?.avatar, 'avatar'),
          badge: '/img/stacks/illustrator.svg',
        }
      })

      return [...team_leaderss, ...userss]
    })

    const ownerIds = project.project_leaders.map(
      (item) => item.directus_users_id?.id,
    )

    const users = project.users.map((member) => {
      const directusUser = member.directus_users_id
      const fname = `${directusUser?.first_name || ''} ${
        directusUser?.last_name || ''
      }`.trim()

      return {
        id: directusUser?.id,
        bio: directusUser?.bio || filtered?.team[0].bio,
        text: directusUser.email || filtered?.team[0].text,
        full_name: fname,
        email: directusUser?.email,
        tooltip: fname,
        'data-nui-tooltip': fname,
        avatar: (directusUser?.avatar?.id, 'avatar'),
        location: directusUser?.location,
        role: directusUser?.role?.name,
        status: directusUser?.status,
        src: get_content_url(directusUser?.avatar, 'avatar'),
        badge: '/img/stacks/illustrator.svg',
      }
    })

    const p_teams = project.team.map((teamItem) => {
      const team = teamItem.Teams_id
      const users = team?.users || []

      return {
        id: team?.id,
        name: team?.name,
        description: team?.description,
        badge: team?._image, // possibly a badge image
        leaders: team?.team_leaders || [],
        users: users.map((user) => {
          const directusUser = user.directus_users_id
          return {
            id: directusUser?.id,
            full_name: `${directusUser?.first_name || ''} ${
              directusUser?.last_name || ''
            }`.trim(),
            email: directusUser?.email,
            avatar: get_content_url(directusUser?.avatar, 'avatar'),
            location: directusUser?.location.name,
            role: directusUser?.role.name,
            status: directusUser?.status,
          }
        }),
      }
    })

    const contactorTeams = project.contactor_teams.map((teamItem) => {
      const team = teamItem.Teams_id
      const users = team?.users || []

      return {
        id: team?.id,
        name: team?.name,
        text: team?.description,
        logo: get_content_url(team?._image, 'avatar'), // possibly a badge image
        leaders: team?.team_leaders || [],
        // users: users.map((user) => {
        //   const directusUser = user.directus_users_id
        //   return {
        //     id: directusUser?.id,
        //     full_name: `${directusUser?.first_name || ''} ${
        //       directusUser?.last_name || ''
        //     }`.trim(),
        //     email: directusUser?.email,
        //     avatar: get_content_url(directusUser?.avatar, 'avatar'),
        //     location: directusUser?.location.name,
        //     role: directusUser?.role.name,
        //     status: directusUser?.status,
        //   }
        // }),
      }
    })

    const contactorCompnay = project.contactor_company.map((teamItem) => {
      const team = teamItem.Contractors_id
      const users = team?.users || []

      return {
        id: team?.id,
        name: team?.name,
        text: team?.description,
        logo: get_content_url(team?._image, 'avatar'), // possibly a badge image
        leaders: team?.team_leaders || [],
      }
    })

    // console.log('wo_ids', wo_ids)
    // console.log('teamUsers', teamUsers)
    // console.log('ownerIds', ownerIds)
    // console.log('contactorTeams', contactorTeams)
    return {
      id: parseInt(project.id),
      slug: parseInt(project.id),
      name: project.name,
      image: get_content_url(project._image, 'project'),
      completed: project.completed,
      description: project.description,
      date_created: new Date().toISOString(),
      date_updated: new Date().toISOString(),
      dueDate: new Date(project.dueDate).toISOString().split('T')[0],
      startDate: new Date(project.startDate).toISOString().split('T')[0],
      category: 1, // examples
      project_leaders: project.project_leaders.map((item) => ({
        id: item.directus_users_id?.id,
      })),
      created: [project.user_created].map((item) => ({
        id: item.id,
        avatar: get_content_url(item.avatar, 'avatar'),
        badge:
          item.badge || filtered?.owner.badge || '/img/stacks/illustrator.svg',
        role: item.role.name || filtered?.owner.role,
        bio: item.bio || filtered?.owner.bio,
        name: item.first_name || filtered?.owner.name,
        text: item.email || filtered?.owner.text,
        tooltip: item.first_name || filtered?.owner.name,
        'data-nui-tooltip': item.first_name || filtered?.owner.name,
      })),
      owner: project.project_leaders.map((item) => ({
        id: item.directus_users_id?.id,
        avatar: get_content_url(item.directus_users_id?.avatar, 'avatar'),
        badge:
          item.directus_users_id?.badge ||
          filtered?.owner.badge ||
          '/img/stacks/illustrator.svg',
        role: item.directus_users_id?.role.name || filtered?.owner.role,
        bio: item.directus_users_id?.bio || filtered?.owner.bio,
        name: item.directus_users_id?.first_name || filtered?.owner.name,
        text: item.directus_users_id?.email || filtered?.owner.text,
        tooltip: item.directus_users_id.first_name || filtered?.owner.name,
        'data-nui-tooltip':
          item.directus_users_id.first_name || filtered?.owner.name,
      }))[0],
      team: [...teamUsers, ...users]
        .filter(
          (user, index, self) =>
            index === self.findIndex((u) => u.id === user.id),
        )
        .filter((user) => !ownerIds.includes(user.id)), // owner бол хасна
      project_team: p_teams,
      files: transformedFiles || filtered?.files,
      tasks: transformedTasks,
      stacks: filtered?.stacks || [],
      tools: filtered?.tools || [],
      customer: filtered?.customer,
      contactor_teams: contactorTeams || filtered?.contactor_teams,
      contactor_company: contactorCompnay || filtered?.contactor_teams,
    }
  })
}

const transformType = (items) => {
  // console.log(items)
  const transformed_types = items.map((item) => ({
    label: item.name,
    value: item.id,
  }))
  transformed_types.unshift({
    label: '',
    value: '',
  })
  return transformed_types
}

const loadTypes = async () => {
  try {
    const filters = {}
    const items = await getItems<any>({
      collection: 'Categories',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    category_options.value = transformType(items.data)
    loading.value = false
  } catch (e) {
    console.log(e)
  }
}

const loadItems = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array = []
  sortBy.map((sort_object) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })
  loading.value = true
  try {
    const filters = {
      id: slug.value,
    }
    const items = await getItems<any>({
      collection: 'Projects',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: [
          '*',
          'user_created.*',
          'user_created.avatar.*',
          'user_created.role.*',

          'project_leaders.directus_users_id.*',
          'project_leaders.directus_users_id.avatar.*',
          'project_leaders.directus_users_id.role.*',
          '_image.*',

          'contactor_teams.*',
          'contactor_teams.Teams_id.*',
          'contactor_teams.Teams_id._image.*',

          'contactor_company.*',
          'contactor_company.Contractors_id.*',
          'contactor_company.Contractors_id._image.*',

          'team.*',
          'state.*',
          'category.*',
          'team.Teams_id.*',
          'team.Teams_id.team_leaders.*',
          'team.Teams_id.team_leaders.directus_users_id.*',
          'team.Teams_id.team_leaders.directus_users_id.role.*',
          'team.Teams_id.team_leaders.directus_users_id.avatar.*',
          'team.Teams_id.users.*',
          'team.Teams_id.users.directus_users_id.*',
          'team.Teams_id.users.directus_users_id.role.*',
          'team.Teams_id.users.directus_users_id.avatar.*',

          'users.*',
          'users.directus_users_id.*',
          'users.directus_users_id.avatar.*',
          'users.directus_users_id.role.*',
        ],
      },
    })
    serverItems.value = items.data[0]
    if (items.data.length > 0) {
      statusValue.value = {
        id: serverItems.value.state?.id,
        name: serverItems.value.state?.status_text,
        icon: serverItems.value.state?.icon,
      }

      category_status.value = {
        value: serverItems.value.category?.id,
        label: serverItems.value.category?.name,
      }

      let dueObj = null
      let sdObj = null
      let cdObj = null
      if (serverItems.value.dueDate != null) {
        dueObj = new Date(serverItems.value.dueDate)
        dDate.value = dueObj.toISOString().split('T')[0]
      }

      if (serverItems.value.startDate != null) {
        sdObj = new Date(serverItems.value.startDate)
        sDate.value = sdObj.toISOString().split('T')[0]
      }

      works.value = await getItems({
        collection: 'Project_works',
        params: {
          filter: {
            project: slug.value,
          },
          limit: itemsPerPage,
          page: page,
          sort: sort_array,
          meta: 'filter_count',
          search: search.value,
          fields: [
            '*',
            'user_created.*',
            'user_created.avatar.*',
            'user_created.role.*',

            'task_leaders.directus_users_id.*',
            'task_leaders.directus_users_id.avatar.*',
            'task_leaders.directus_users_id.role.*',

            'task_members.*',
            'task_members.directus_users_id.*',
            'task_members.directus_users_id.avatar.*',
            'task_members.directus_users_id.role.*',

            'task_company.*',
            'task_company.Contractors_id.*',
            'task_company.Contractors_id._image.*',
          ],
        },
      }).then(async (wo_res) => {
        // console.log('wo_res', wo_res)

        if (wo_res.data.length > 0) {
          if (wo_res.data.length > 0) {
            const works_items = await Promise.all(
              wo_res.data.map(async (item) => {
                const pro_work_files = await getItems<any>({
                  collection: 'Project_work_files',
                  params: {
                    filter: {
                      project_work: item.id,
                    },
                    limit: itemsPerPage,
                    page: page,
                    sort: sort_array,
                    meta: 'filter_count',
                    search: search.value,
                    fields: ['*', 'file.*'],
                  },
                })

                const pro_work_comment = await getItems<any>({
                  collection: 'Project_work_comments',
                  params: {
                    filter: {
                      project_work: item.id,
                    },
                    limit: itemsPerPage,
                    page: page,
                    sort: sort_array,
                    meta: 'filter_count',
                    search: search.value,
                    fields: [
                      '*',
                      'user_created.*',
                      'user_created.avatar.*',
                      'user_created.role.*',
                    ],
                  },
                })

                const pro_work_task = await getItems<any>({
                  collection: 'Project_work_item',
                  params: {
                    filter: {
                      project_work: item.id,
                      // status: 1,
                      active: '1',
                    },
                    limit: itemsPerPage,
                    page: page,
                    sort: sort_array,
                    meta: 'filter_count',
                    search: search.value,
                    fields: [
                      '*',
                      'user_created.*',
                      'user_created.avatar.*',
                      'user_created.role.*',
                    ],
                  },
                })

                return {
                  ...item,
                  comments: pro_work_comment.data,
                  files: pro_work_files.data,
                  checklist: pro_work_task.data,
                }
              }),
            )
            // console.log('  works.1', works_items)
            return works_items
          }
        }
      })
    }

    const serverItemss = transformProjects(
      items.data,
      initial_datas.value,
      works.value,
    )

    // console.log('items.3', serverItemss)
    return serverItemss
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

// ------------ comments sections   --------------------------

const addComment = async (type) => {
  // console.log('addComment', commentArea.value)
  createItems({
    collection: 'Project_comments',
    items: [
      {
        status: 1,
        project: slug.value,
        text: commentArea.value,
        company_id: myCompanyId,
      },
    ],
  }).then(async (addItem) => {
    commentArea.value = ''
    key.value =
      Math.random().toString(36).substring(2) + Date.now().toString(36)

    console.log('records', addItem)
    await loadComments()

    // if (props.refresh) props.refresh()
  })
}

const deleteComment = async (item) => {
  // console.log('deleteComment', item)

  let items = {
    status: '0',
  }

  const data = {
    collection: 'Project_comments',
    id: item.id,
    item: items,
  }

  let deleted = await updateItem(data)
  // console.log('deleted', deleted)
  await loadComments()

  // const deleted = await deleteItems({
  //   collection: 'Project_comments',
  //   items: {
  //     query: {
  //       filter: {
  //         id: item.id,
  //       },
  //     },
  //   },
  // })
}
const loadComments = async () => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      project: slug.value,
    }

    const comment_items = await getItems<any>({
      collection: 'Project_comments',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: [
          '*',
          'user_created.*',
          'user_created.avatar.*',
          'user_created.role.*',
        ],
      },
    })
    // console.log('comment_items', comment_items)

    if (comment_items.data.length) {
      let commentist = comment_items.data.map((comment) => {
        return {
          id: comment.id,
          text: comment.text,
          author: {
            id: comment.user_created.id,
            name: comment.user_created.first_name,
            last_name: comment.user_created.last_name,
            posted: formatToLocalDateTime(comment.date_created),
            picture: comment.user_created.avatar
              ? `${config.public.directus.url}assets/${comment.user_created.avatar?.filename_disk}`
              : null,
          },
        }
      })
      // console.log('commentist', commentist)
      comments.value = commentist
    }
    loading.value = false
  } catch (e) {}
}

function formatToLocalDateTime(isoString) {
  const date = new Date(isoString)

  const year = date.getFullYear()
  const month = (date.getMonth() + 1).toString().padStart(2, '0') // months are 0-indexed
  const day = date.getDate().toString().padStart(2, '0')

  const hours = date.getHours().toString().padStart(2, '0')
  const minutes = date.getMinutes().toString().padStart(2, '0')

  return `${year}-${month}-${day} ${hours}:${minutes}`
}

const refresh = async (id: any) => {
  // console.log('refreshddd', id)
  let ref_perPage = parseInt((query.value.perPage as string) || '5', 10)
  let ref_page = parseInt((query.value.page as string) || '1', 10)
  let ref_filter = (query.value.filter as string) || ''
  let ref_slugg = (query.value.slug as string) || ''

  let ref_offset = (ref_page - 1) * ref_perPage
  let ref_filterRe = new RegExp(ref_filter, 'i')

  let datas_orginal = await loadItems({ page: 1, itemsPerPage: -1, sortBy: [] })
  data.value = {
    total: datas_orginal.length,
    data: !ref_filter
      ? datas_orginal.slice(ref_offset, ref_offset + ref_perPage)
      : datas_orginal
          .filter((item) => {
            return [item.name, item.owner.name, item.category].some((item) =>
              item.match(ref_filterRe),
            )
          })
          .slice(ref_offset, ref_offset + ref_perPage),
    recent: datas_orginal.filter((item) => item.recent === true),
    project: ref_slugg
      ? datas_orginal.find((item) => item.slug == ref_slugg)
      : undefined,
  }
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)

  const updatedtasks = ref(data.value?.project?.tasks)
  if (updatedtasks.value) {
    // Reset all column task arrays safely
    columns.new.tasks = []
    columns.inProgress.tasks = []
    columns.onHold.tasks = []
    columns.done.tasks = []

    // Хэрэв blocked, inReview хэсгүүдээ идэвхжүүлэх бол эднийг ч бас цэвэрлэнэ:
    // columns.blocked && (columns.blocked.tasks = [])
    // columns.inReview && (columns.inReview.tasks = [])
    for (const task of updatedtasks.value) {
      switch (task.status) {
        case 0:
          columns.new.tasks.push(task)
          break
        case 1:
          columns.inProgress.tasks.push(task)
          break
        case 2:
          columns.blocked.tasks.push(task)
          break
        case 3:
          columns.onHold.tasks.push(task)
          break
        case 4:
          columns.inReview.tasks.push(task)
          break
        case 5:
          columns.done.tasks.push(task)
          break
      }
    }
  }

  if (id) {
    // console.log('router', router)
    // console.log('id_router', id)
    // openTaskPanel(id, data.value?.project?.tasks, data.value?.project, false)
    // router.replace(`/projects/board/${id}`)
    // router.back()
    // await router.replace({
    //   path: '/projects',
    //   query: { to: `/details/${id}` },
    // })
    // await router.replace(`/projects/board/${id}`)
  }
}

// watch(
//   () => key.value,
//   (newVal, oldVal) => {
//     console.log('key changed:', oldVal, '→', newVal)
//   },
// )

onMounted(async () => {
  const perPage = parseInt((query.value.perPage as string) || '5', 10)
  const page = parseInt((query.value.page as string) || '1', 10)
  const filter = (query.value.filter as string) || ''
  const slugg = (query.value.slug as string) || ''
  console.log('boooooord_slug', slugg)

  const offset = (page - 1) * perPage
  const filterRe = new RegExp(filter, 'i')

  // await loadItems({ page: 1, itemsPerPage: -1, sortBy: [] })
  const datas = await getDemoDetails()

  initial_datas.value = {
    total: datas.length,
    data: !filter
      ? datas.slice(offset, offset + perPage)
      : datas
          .filter((item) => {
            return [item.name, item.owner.name, item.category].some((item) =>
              item.match(filterRe),
            )
          })
          .slice(offset, offset + perPage),
    recent: datas.filter((item) => item.recent === true),
    project: slugg ? datas.find((item) => item.slug == slugg) : undefined,
  }

  const datas_org = await loadItems({ page: 1, itemsPerPage: -1, sortBy: [] })
  data.value = {
    total: datas_org?.length,
    data: !filter
      ? datas_org.slice(offset, offset + perPage)
      : datas_org
          .filter((item) => {
            return [item.name, item.owner.name, item.category].some((item) =>
              item.match(filterRe),
            )
          })
          .slice(offset, offset + perPage),
    recent: datas_org.filter((item) => item.recent === true),
    project: slugg ? datas_org.find((item) => item.slug == slugg) : undefined,
  }

  console.log('boooooord_slug', data.value)

  await loadTypes()
  await loadComments()
  // handleProgress()

  const userInfo = JSON.parse(window.localStorage.getItem('userInfo') || '{}')
  if (userInfo?.avatar) {
    userImgId.value = userInfo.avatar
  }

  my_id.value = userInfo?.id
  my_name.value = userInfo?.first_name
  project_id.value = slugg

  const tasks = ref(data.value?.project?.tasks)

  if (tasks.value) {
    for (const task of tasks.value) {
      switch (task.status) {
        case 0:
          columns.new.tasks.push(task)
          break
        case 1:
          columns.inProgress.tasks.push(task)
          break
        case 2:
          columns.blocked.tasks.push(task)
          break
        case 3:
          columns.onHold.tasks.push(task)
          break
        case 4:
          columns.inReview.tasks.push(task)
          break
        case 5:
          columns.done.tasks.push(task)
          break
      }
    }
  }
})

const board = computed(() => Object.values(columns || {}))
const currentTask = ref()

// function openTaskPanel(id: number, tasks: any) {
//   currentTask.value = tasks.find((task: any) => task.id === id)
//   open('task', {
//     task: currentTask,

//     // listen to "message" event emited from panel component
//     onMessage: async (message: any) => {
//       console.log('onMessage')
//       console.log(message)
//       close()
//     },
//   })
// }

function openTaskPanel(id: number, tasks: any, item: any, reloading: any) {
  currentTask.value = tasks.find((task: any) => task.id === id)
  open('task', {
    task: currentTask,
    project: item,
    reloadItem: reloading,
    // listen to "message" event emited from panel component
    onMessage: async (message: any) => {
      console.log('onMessage')
      console.log(message)
      close()
    },
  })
}

function onDrop(column: ColumnContent, dropResult: any) {
  if (
    typeof dropResult?.addedIndex !== 'number' ||
    typeof dropResult?.removedIndex !== 'number'
  ) {
    return
  }
  if (dropResult.addedIndex === dropResult.removedIndex) {
    return
  }

  let itemToAdd

  if (dropResult.removedIndex !== null) {
    itemToAdd = column.tasks.splice(dropResult.removedIndex, 1)[0]
  }
  if (dropResult.addedIndex !== null) {
    column.tasks.splice(dropResult.addedIndex, 0, itemToAdd)
  }
}
</script>

<template>
  <TairoSidebarLayout
    :key="key"
    horizontal-scroll
    class="bg-muted-100 dark:bg-muted-900 h-screen w-full"
  >
    <div
      v-if="data?.project !== undefined"
      class="flex h-12 items-center justify-between pe-4 xl:pe-10"
    >
      <div class="flex items-center gap-2">
        <BaseAvatar :src="data?.project.customer.logo" size="xs" />
        <div>
          <BaseParagraph size="xs" class="text-muted-400">
            {{ data?.project.customer.name }}
          </BaseParagraph>
          <BaseHeading as="h2" size="sm" weight="medium">
            {{ data?.project.name }}
          </BaseHeading>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <BaseAvatarGroup :avatars="data?.project.team" size="xs" />
        <BaseButtonIcon
          :to="`/projects/details/${slug}`"
          rounded="lg"
          data-nui-tooltip="Project details"
        >
          <Icon name="lucide:layout-template" class="size-4" />
        </BaseButtonIcon>
        <BaseButtonIcon
          :to="`/projects/add/${slug}`"
          rounded="full"
          data-nui-tooltip="New task"
        >
          <Icon name="lucide:plus" class="size-4" />
        </BaseButtonIcon>
      </div>
    </div>
    <div class="flex h-[calc(100vh_-_133px)] grow space-x-6 overflow-auto pt-2">
      <!-- Column -->
      <div
        v-for="column in board"
        :key="column.title"
        class="flex h-full w-[17rem] shrink-0 flex-col"
      >
        <!-- Column header -->
        <div class="flex h-14 shrink-0 items-center px-2">
          <!-- Column title -->
          <span class="block font-sans text-sm font-semibold">{{
            column.title
          }}</span>
          <!-- Column count -->
          <span
            class="text-primary-500 dark:text-sunny ms-2 flex size-5 items-center justify-center text-sm font-semibold"
            >{{ column.tasks.length }}</span
          >
          <!-- Column action -->
          <!-- <button
            class="text-primary-500 dark:text-sunny hover:bg-primary-500/20 dark:hover:bg-sunny/20 ms-auto flex size-6 items-center justify-center rounded-full transition-colors duration-300"
          >
            <Icon name="lucide:plus" class="size-4" />
          </button> -->
        </div>
        <!-- Scrollable area -->
        <div class="nui-slimscroll overflow-auto pb-10 pe-2">
          <Container
            tag="div"
            class="flex flex-col gap-y-4"
            orientation="vertical"
            :group-name="column.title"
            drag-class="transform rotate-2 transform-gpu"
            drop-class="opacity-40"
            :drop-placeholder="{
              className:
                'mt-4 border-muted-200 border-dashed dark:border-muted-700 dark:bg-muted-800 group relative flex cursor-pointer flex-col items-start rounded-lg border bg-white/90 p-4 hover:bg-white opacity-60 mb-4',
            }"
            @drop="(dropResult: any) => onDrop(column, dropResult)"
          >
            <!-- Board card -->
            <template v-if="column.tasks.length > 0">
              <Draggable v-for="task in column.tasks" :key="task.id">
                <div
                  role="button"
                  tabindex="0"
                  class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 group relative flex cursor-pointer flex-col items-start rounded-lg border bg-white/90 p-4 hover:bg-white"
                  draggable="true"
                  @click="
                    () =>
                      openTaskPanel(
                        task.id,
                        data?.project?.tasks,
                        data?.project,
                        refresh,
                      )
                  "
                >
                  <div class="relative mb-2">
                    <div
                      class="mb-2 flex w-full items-center justify-between gap-2"
                    >
                      <BaseTag
                        rounded="full"
                        variant="pastel"
                        color="muted"
                        class="m-0 -ms-1 inline-flex h-6 scale-90 items-center py-0 text-xs font-semibold"
                      >
                        Task #{{ task.id }}
                      </BaseTag>
                      <BaseText size="xs" class="text-muted-400">
                        {{ task.created }}
                      </BaseText>
                    </div>
                    <BaseHeading
                      as="h4"
                      size="sm"
                      weight="medium"
                      class="line-clamp-2"
                    >
                      <span>{{ task.name }}</span>
                    </BaseHeading>
                  </div>
                  <div
                    class="text-muted-500 dark:text-muted-200 mt-2 flex w-full items-center justify-between text-xs font-medium"
                  >
                    <div class="flex items-center gap-2">
                      <BaseAvatar
                        :src="task.assignee.src"
                        size="xxs"
                        class="shrink-0"
                      />
                      <BaseText size="xs" class="text-muted-400">
                        {{ task.assignee.tooltip }}
                      </BaseText>
                    </div>
                    <div class="text-muted-400 flex items-center gap-3">
                      <div
                        v-if="task.checklist.length > 0"
                        :data-nui-tooltip="`${task.checklist.length} subtask${
                          task.checklist.length > 1 ? 's' : ''
                        } in checklist`"
                        data-nui-tooltip-position="start"
                      >
                        <Icon name="lucide:check-circle" class="size-4" />
                      </div>
                      <div
                        v-if="task.files.length > 0"
                        :data-nui-tooltip="`${task.files.length} file${
                          task.files.length > 1 ? 's' : ''
                        } uploaded`"
                        data-nui-tooltip-position="start"
                      >
                        <Icon name="lucide:file" class="size-4" />
                      </div>
                      <div
                        v-if="task.comments.length > 0"
                        :data-nui-tooltip="`${task.comments.length} comment${
                          task.comments.length > 1 ? 's' : ''
                        }`"
                        data-nui-tooltip-position="start"
                      >
                        <Icon name="lucide:message-circle" class="size-4" />
                      </div>
                    </div>
                  </div>
                </div>
              </Draggable>
            </template>
            <!-- Placeholder -->
            <div v-else>
              <div
                class="text-muted-400 mt-10 flex items-center justify-center"
              >
                <Icon name="ph:kanban-thin" class="size-8" />
              </div>
              <div class="mt-2 text-center">
                <!-- <BaseHeading as="h4" size="md" weight="light" class="mb-1">
                  <span>Nothing to show</span>
                </BaseHeading> -->
                <BaseParagraph
                  size="xs"
                  lead="tight"
                  class="text-muted-500 dark:text-muted-400 mx-auto max-w-[200px] !font-sans"
                >
                  <span>{{ $t('Nothing to show') }}</span>
                </BaseParagraph>
                <!-- <button
                  :to="`/projects/add/${slug}`"
                  class="text-primary-500 dark:text-sunny mx-auto mt-2 flex items-center justify-center gap-1 font-sans text-xs underline-offset-4 hover:underline"
                >
                  <Icon name="lucide:plus" class="size-3" />
                  <span>New Task</span>
                </button> -->
              </div>
            </div>
          </Container>
        </div>
      </div>
      <!-- Add Column -->
      <!-- <div class="flex w-72 shrink-0 flex-col">
        <div class="flex h-14 shrink-0 items-center px-2">
          <span class="block font-sans text-sm font-semibold">Customize</span>
        </div>
        <div class="w-full">
          <button
            class="text-muted-500 dark:text-muted-400 hover:text-primary-500 dark:hover:text-sunny border-muted-300 dark:border-muted-600 hover:border-primary-500 dark:hover:border-sunny flex h-12 w-full items-center justify-center gap-x-2 rounded-xl border-2 border-dashed px-6 font-sans transition-colors duration-300 hover:border-solid"
          >
            <Icon name="ph:gear-six-duotone" class="size-4" />
            <span class="text-sm">Manage columns</span>
          </button>
        </div>
      </div> -->
      <div class="w-6 shrink-0" />
    </div>
  </TairoSidebarLayout>
</template>

<style>
.smooth-dnd-container.vertical > .smooth-dnd-draggable-wrapper {
  overflow: visible;
}
</style>
