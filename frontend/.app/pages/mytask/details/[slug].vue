<script setup lang="ts">
definePageMeta({
  title: 'Project Details',
  middleware: ['auth'],
  showback: true,
  preview: [
    {
      title: 'Project details',
      description: 'For displaying fitness project details',
      categories: ['layouts', 'projects'],
      src: '/img/screens-projects-details.png',
      srcDark: '/img/screens-projects-details-dark.png',
      order: 72,
      params: {
        slug: 'health-and-fitness-dashboard',
      },
    },
    {
      title: 'Project details',
      description: 'For displaying banking project details',
      categories: ['projects'],
      src: '/img/screens-projects-details.png',
      srcDark: '/img/screens-projects-details-dark.png',
      order: 72,
      params: {
        slug: 'banking-and-finance-dashboard',
      },
    },
  ],
})

const { open, close } = usePanels()

import { useI18n } from 'vue-i18n'
import ModalItemsList from '~/components/form/ModalItemsList.vue'
// import { statuses } from '~/components/workorder/WorkOrderStatus'
import { statuses } from '~/components/workorder/ProjectConstants'

import { getDemoDetails } from '../detailsData'
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
const companys = ref([])
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

const stateValue = ref({
  value: 1,
  text: 'Status',
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
          file_name: item.file_name,
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
    if (item.task_company.length) {
      companys.value.push(
        ...item.task_company.map((company) => {
          return {
            logo: get_content_url(company.Contractors_id._image, 'avatar'),
            text: company.Contractors_id.description,
            name: company.Contractors_id.name,
            id: company.Contractors_id.id,
          }
        }),
      )
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
          file_name: fileItem.file_name,
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

  let contactor_companys = []
  if (companys.value.length) {
    contactor_companys = Array.from(
      new Map(companys.value.map((item) => [item.id, item])).values(),
    )
  }

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

    // const contactorCompnay = project.contactor_company.map((teamItem) => {
    //   const team = teamItem.Contractors_id
    //   const users = team?.users || []

    //   return {
    //     id: team?.id,
    //     name: team?.name,
    //     text: team?.description,
    //     logo: get_content_url(team?._image, 'avatar'), // possibly a badge image
    //     leaders: team?.team_leaders || [],
    //   }
    // })

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
      files: transformedFiles || [],
      tasks: transformedTasks || [],
      stacks: filtered?.stacks || [],
      tools: filtered?.tools || [],
      customer: filtered?.customer,
      contactor_teams: contactorTeams || filtered?.contactor_teams,
      contactor_company: contactor_companys || filtered?.contactor_teams,
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
      if (serverItems.value.state) {
        let stateItem = statuses.find(
          (p) =>
            p.value == serverItems.value.state ||
            p.__original == serverItems.value.state,
        )

        stateValue.value = {
          value: stateItem?.value,
          text: stateItem?.text,
          icon: stateItem?.icon,
        }
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

    // console.log('items.3', serverItems)
    return serverItemss
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

onMounted(async () => {
  const perPage = parseInt((query.value.perPage as string) || '5', 10)
  const page = parseInt((query.value.page as string) || '1', 10)
  const filter = (query.value.filter as string) || ''
  const slugg = (query.value.slug as string) || ''

  const offset = (page - 1) * perPage
  const filterRe = new RegExp(filter, 'i')

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

  // console.log('data', data)
  // console.log('companys', companys)
  // console.log('getDemoDetails', data.value)
})

const currentTask = ref()

function openTaskPanel(id: number, tasks: any, item: any, reloading: any) {
  currentTask.value = tasks.find((task: any) => task.id === id)
  open('task', { task: currentTask, project: item, reloadItem: reloading })
}

function onClick(item, type) {
  // console.log('onClick', item)
  let updateData = {}
  if (type == 'category') {
    updateData = {
      collection: 'Projects',
      id: slug.value,
      item: { category: item.value },
    }
  } else if (type == 'wo_status') {
    updateData = {
      collection: 'Projects',
      id: slug.value,
      item: { state: item.value },
    }
  } else if (type == 'type') {
    updateData = {
      collection: 'Projects',
      id: slug.value,
      item: { type: item.value },
    }
  }
  // console.log('updateData', updateData)

  updateItem(updateData).then((res) => {
    console.log('done')
    toaster.show({
      title: t('Updated'),
      message: t('Record updated successfully!'),
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })

    // refresh()
  })
}

function onChange(event: Event) {
  const value = (event.target as HTMLInputElement).value
  let items = {}

  // console.log('onchange')
  if (event.target.type == 'datetime-local') {
    let keyName = ''
    let dateObj = null

    if (event.target.name == 'due') {
      keyName = 'dueDate'
      dDate.value = event.target.value
    } else if (event.target.name == 'started_at') {
      keyName = 'startDate'
      sDate.value = event.target.value
    } else if (event.target.name == 'created_at') {
      keyName = 'created_at'
    } else if (event.target.name == 'completed_at') {
      keyName = 'completed_at'
      cDate.value = event.target.value
      cDateTime.value = event.target.value
    }

    if (sDate.value > dDate.value) {
      alertMsg.value = 'Check date'
      toaster.show({
        title: t('Check date'),
        message: 'start date is wrong!',
        color: 'Error',
        icon: 'mdi:alert',
        closable: true,
        duration: 1000,
      })
      return
    } else {
      alertMsg.value = false
    }

    items = { ...items, [keyName]: event.target.value }
    // console.log(' items ', items)

    const updateData = {
      collection: 'Projects',
      id: slug.value,
      item: items,
    }

    updateItem(updateData).then((res) => {
      refresh(false)

      toaster.show({
        title: t('Updated'),
        message: t('Record updated successfully!'),
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
    })
  }
}

const handleTeamClick = (type) => {
  if (type == 'company') {
    isModalCompanyOpen.value = true
  } else {
    isModalTeamsOpen.value = true
  }
}

const handleModalTeamClose = () => {
  isModalCompanyOpen.value = false
  isModalTeamsOpen.value = false
}

const refresh = async (id: any) => {
  // console.log('details_refreshed', id)
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
  key.value = Math.random().toString(36) + Date.now() // key шинэчлэх

  // console.log(' data.value ', data.value)
  // console.log('datas_orginal', datas_orginal)

  if (id) {
    openTaskPanel(id, data.value?.project?.tasks, data.value?.project, false)
  }
}

const handleRemoveClick = (type, item) => {
  if (type == 'team') {
    setTeam(item, 'remove')
  } else if (type == 'company') {
    setCompany(item, 'remove')
  }
}

const setCompany = async (obj: any, type = 'add') => {
  console.log(obj)
  console.log('setCompany')
  let items = {
    contactor_company: {
      create: [],
    },
  }
  // console.log('serverItems', serverItems.value.contactor_company)

  if (serverItems.value.contactor_company.length > 0) {
    serverItems.value.contactor_company.forEach((team) => {
      items['contactor_company']['create'].push({
        Projects_id: slug.value,
        Contractors_id: {
          id: team.Contractors_id.id,
        },
      })
    })
  }

  if (type == 'add') {
    items['contactor_company']['create'].push({
      Projects_id: slug.value,
      Contractors_id: {
        id: obj.id,
      },
    })
  } else if (type == 'remove') {
    items['contactor_company']['create'] = items['contactor_company'][
      'create'
    ].filter((team) => team.Contractors_id.id !== obj.id)
  }

  const delTeamsRes = await deleteItems({
    collection: 'Projects_Contractors',
    items: {
      query: {
        filter: {
          Projects_id: slug.value,
        },
      },
    },
  })

  // console.log('items-teams', items)

  let updateContractTeam = {
    collection: 'Projects',
    id: slug.value,
    item: items,
  }

  updateItem(updateContractTeam).then((res) => {
    // console.log('resultss_company', res)
    refresh(false)
    toaster.show({
      title: t('Success'),
      message: t('Record updated successfully!'),
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  })
}

const setTeam = async (obj: any, type = 'add') => {
  let items = {
    contactor_teams: {
      create: [],
    },
  }
  // console.log('serverItems', serverItems.value.contactor_teams)

  if (serverItems.value.contactor_teams.length > 0) {
    serverItems.value.contactor_teams.forEach((team) => {
      items['contactor_teams']['create'].push({
        Projects_id: slug.value,
        Teams_id: {
          id: team.Teams_id.id,
        },
      })
    })
  }

  if (type == 'add') {
    items['contactor_teams']['create'].push({
      Projects_id: slug.value,
      Teams_id: {
        id: obj.id,
      },
    })
  } else if (type == 'remove') {
    items['contactor_teams']['create'] = items['contactor_teams'][
      'create'
    ].filter((team) => team.Teams_id.id !== obj.id)
  }

  const delTeamsRes = await deleteItems({
    collection: 'Projects_Teams', //old-
    items: {
      query: {
        filter: {
          Projects_id: slug.value,
        },
      },
    },
  })

  // console.log('items-teams', items)

  let updateContractTeam = {
    collection: 'Projects',
    id: slug.value,
    item: items,
  }

  updateItem(updateContractTeam).then((res) => {
    // console.log('resultss', res)
    refresh(false)
    toaster.show({
      title: t('Success'),
      message: t('Record updated successfully!'),
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  })
}

const do_edit = (id) => {
  console.log('id : ', serverItems.value)
  // Perform your action here
  selectedItem.value = serverItems.value
  isModalOpen.value = true
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log(isModalOpen.value)
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleProgress = async () => {
  progressCircleComponent?.value?.loadWorkItems()
}

const deleteProject = async (itemId) => {
  console.log('deleteProject', itemId)

  let items = {
    active: 0,
  }

  const updata = {
    collection: 'Projects',
    id: itemId,
    item: items,
  }

  let deleted = await updateItem(updata)
  router.replace(`/projects`)
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

// ------------ files sections   --------------------------
const loadFiles = async () => {
  // console.log('Documents.vue', task_id)
  // console.log('Documents.vue id', task_id)
  loading.value = true
  try {
    const filters = {
      project_work: slug.value,
    }

    // console.log('filters.vue id', filters)

    const items = await getItems<any>({
      collection: 'Project_work_files',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: [
          '*',
          'file.*',
          'user_created.*',
          'user_created.avatar.*',
          'user_created.role.*',
        ],
      },
    })

    rowData.value = items.data
    // console.log('loadFiles', rowData.value)

    if (items.data.length) {
      let filesList = items.data.map((item) => {
        const file = item.file || {}
        const user = item.user_created || {}

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

        return {
          row_id: item.id,
          id: file.id,
          type: file.type,
          file_name: item.file_name,
          filename_disk: file.filename_disk || 'filename_disk',
          name: file.filename_disk || 'Unnamed File', // Default fallback for missing name
          icon: get_file_type(file), // Ensure get_file_type() is defined correctly
          size: fileSize,
          version: '1.8.2', // Static version, could be dynamic if needed
          uploaded: file.uploaded_on || 'N/A', // Fallback if 'uploaded_on' is missing
          author: {
            id: user.id || 'Unknown', // Fallback for missing author id
            name: user.first_name || 'Unknown', // Fallback for missing author name
            picture: get_content_url(user.avatar) || '', // Ensure URL is valid
          },
        }
      })
      // console.log('filesList', filesList)
      if (props.task) {
        props.task.files = filesList
      }
    }

    loading.value = false
  } catch (e) {}
}

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

const addFiles = (type) => {
  isModalNewFile.value = true
  uploadedFiles.value = ''
}

const addFilesClose = (type) => {
  isModalNewFile.value = false
  uploadedFiles.value = ''
}

const downloadFile = async (item) => {
  let path = get_content_url(item, 'avatar')
  window.open(path, '_blank')
}

const deleteFile = async (item) => {
  // console.log('deleteFile', item)

  await deleteItems({
    collection: 'Project_work_files',
    items: {
      query: {
        filter: {
          id: item.row_id,
        },
      },
    },
  })
  await loadFiles()
}

const handleUploadRead = async (items) => {
  // console.log('handleUploadRead-uploadedFiles', items)
  rowData.value = [...rowData.value, ...items]
  rowFiles.value = [...rowData.value, ...items]
  saveUpload(items)
}

const saveUpload = async (items) => {
  uploadedFiles.value = items

  if (uploadedFiles.value.length) {
    uploadedFiles.value.map(async (uploadedFile) => {
      const file_items = {
        // project_work: slug.value,
        project_work: slug.value,
        file: uploadedFile.file.id,
        company_id: myCompanyId,
      }

      const file_res = await createItems({
        collection: 'Project_work_files',
        items: file_items,
      })

      await loadFiles()

      // console.log('file_res-saved', file_res)
    })
  }
  // console.log('uploadedFiles-saved', uploadedFiles)
}

const previewUrl = computed(() => {
  return userImgId.value
    ? `${config.public.directus.url}assets/${userImgId.value}`
    : '/img/avatars/2.svg'
})
</script>

<template>
  <div class="relative">
    <div class="absolute end-0 top-2 z-20 hidden sm:block mr-6">
      <BaseButton
        size="md"
        rounded="lg"
        :to="`/mytask/board/${slug}`"
        :datas="data.value || []"
      >
        <Icon name="ph:kanban-duotone" class="size-4" />
        <span>{{ t('Open Board') }}</span>
      </BaseButton>
    </div>
    <div v-if="data?.project === undefined">
      <div class="loader">
        <BasePlaceholderPage subtitle="Loading">
          <template #image>
            <img
              class="block dark:hidden"
              src="/img/utils/loading.gif"
              alt="Placeholder image"
              style="height: 20px; width: 20px"
            />
            <img
              class="hidden dark:block"
              src="/img/utils/loading.gif"
              alt="Placeholder image"
              style="height: 20px; width: 20px"
            />
          </template>
        </BasePlaceholderPage>
      </div>
    </div>
    <div v-else class="h-full">
      <BaseTabs
        model-value="overview"
        :tabs="[
          {
            label: t('Overview'),
            value: 'overview',
          },
          {
            label: t('Team users'),
            value: 'team',
          },
          {
            label: t('Tasks'),
            value: 'tasks',
          },
        ]"
      >
        <template #tab="{ activeValue }">
          <!-- Overview -->
          <div v-if="activeValue === 'overview'">
            <div class="overview grid grid-cols-12 gap-6">
              <div class="ltablet:col-span-8 col-span-12 lg:col-span-8">
                <BaseCard class="space-y-12 p-10">
                  <div
                    class="border-muted-200 dark:border-muted-700 flex flex-col items-center justify-between gap-8 border-b pb-12 sm:flex-row"
                  >
                    <div class="min-w-[312px]">
                      <BaseHeading tag="h2" size="2xl" weight="medium">
                        {{ data?.project.name }}
                      </BaseHeading>
                      <!-- <BaseParagraph
                        size="lg"
                        class="text-muted-600 dark:text-muted-400"
                      >
                        {{ data?.project.category }}
                      </BaseParagraph> -->
                      <BaseParagraph size="sm" class="text-muted-400 py-4">
                        {{ data?.project.description }}
                      </BaseParagraph>
                      <div class="flex items-center justify-between">
                        <div class="flex items-center gap-2">
                          <BaseAvatar
                            :src="data?.project.owner?.avatar"
                            :data-nui-tooltip="`${data?.project.owner?.name} owns this project`"
                          />
                          <div>
                            <BaseHeading tag="h3" size="sm" weight="medium">
                              {{ data?.project.owner?.name }}
                            </BaseHeading>
                            <BaseParagraph size="xs" class="text-muted-400">
                              {{ t('Project owner') }}
                            </BaseParagraph>
                          </div>
                        </div>
                        <BaseAvatarGroup
                          :avatars="data?.project.team"
                          :limit="3"
                        />
                      </div>
                      <div
                        class="!mt-[30px] flex flex-col items-start gap-1 border-t p-2"
                      >
                        <div class="flex !ml-[-8px] mb-2">
                          <p class="text-muted-400 font-sans text-xs">
                            {{ t('Project Teams') }}
                          </p>

                          <!-- <div class="flex mt-[-10px]">
                          <BaseButtonIcon
                            muted
                            size="sm"
                            @click="handleTeamClick('team')"
                          >
                            <Icon name="lucide:plus" />
                          </BaseButtonIcon>
                        </div> -->
                        </div>

                        <div
                          class="!ml-[-8px] flex items-center gap-2"
                          v-for="cteam in data?.project.contactor_teams"
                          :key="cteam.id"
                        >
                          <BaseAvatar
                            :src="cteam.logo"
                            size="sm"
                            :data-nui-tooltip="cteam.name"
                            class="bg-muted-100 dark:bg-muted-700"
                          />
                          <div>
                            <BaseHeading
                              tag="h5"
                              size="md"
                              weight="medium"
                              lead="none"
                              class="line-clamp-1"
                            >
                              {{ cteam.name }}
                            </BaseHeading>
                            <BaseParagraph size="sm" class="text-muted-400">
                              {{ cteam.text }}
                            </BaseParagraph>
                          </div>
                          <!-- <div class="flex absolute right-6">
                          <BaseButtonIcon
                            @click="handleRemoveClick('team', cteam)"
                            muted
                            size="sm"
                            id="{{cteam.id}}"
                          >
                            <Icon name="lucide:minus" />
                          </BaseButtonIcon>
                        </div> -->
                        </div>
                      </div>
                    </div>
                    <div class="w-full shrink-0 sm:w-72">
                      <img
                        :src="data?.project.image"
                        :alt="data?.project.name"
                        class="rounded-lg h-[200px]"
                      />
                    </div>
                  </div>

                  <!-- inputs -->
                  <div
                    class="inputs border-muted-200 dark:border-muted-700 grid gap-4 border-b pb-12 sm:grid-cols-3"
                  >
                    <div>
                      <div>
                        <BaseListbox
                          :label="t('Category')"
                          :items="category_options"
                          :properties="{
                            value: 'value',
                            label: 'label',
                            // icon: 'icon', //baazaas awdag bolsonoos hoish zuraggui bolson
                          }"
                          :model-value="category_status"
                          size="md"
                          rounded="md"
                          @update:model-value="onClick($event, 'category')"
                          :disabled="serverItems?.state == 5 ? true : false"
                        />
                        <BaseListbox
                          :label="t('State')"
                          class="status_item mt-[2px]"
                          :items="statuses"
                          :properties="{
                            value: 'value',
                            label: 'text',
                            icon: 'icon', //baazaas awdag bolsonoos hoish zuraggui bolson
                          }"
                          :model-value="stateValue"
                          size="md"
                          rounded="md"
                          @update:model-value="onClick($event, 'wo_status')"
                          :disabled="serverItems?.state == 5 ? true : false"
                        />
                      </div>
                    </div>
                    <div>
                      <div>
                        <FormKit
                          :label="t('Started date')"
                          name="started_at"
                          type="datetime-local"
                          @change="onChange"
                          :disabled="serverItems?.state == 5 ? true : false"
                          :value="serverItems?.startDate || null"
                          :classes="{
                            input: 'wo_input',
                            outer: 'wo_wrapper',
                            label: 'wo_label',
                          }"
                        />
                        <FormKit
                          :label="t('Due date')"
                          name="due"
                          type="datetime-local"
                          :value="serverItems?.dueDate || null"
                          :disabled="serverItems?.state == 5 ? true : false"
                          @change="onChange"
                          :classes="{
                            input: 'wo_input',
                            outer: 'wo_wrapper',
                            label: 'wo_label',
                          }"
                        />
                      </div>
                    </div>
                    <div class="flex justify-center items-center">
                      <ProgressCircleComp
                        ref="progressCircleComponent"
                        :wo_ids="wo_ids"
                        :project_id="slug"
                        :completed="serverItems?.completed || 0"
                      />
                    </div>
                  </div>

                  <!-- files -->
                  <div>
                    <div class="all_files flex justify-between">
                      <h4
                        class="text-muted-400 mb-6 font-sans text-xs font-semibold uppercase"
                      >
                        {{ t('Recent files') }}
                      </h4>
                      <!-- <BaseButtonIcon
                        muted
                        size="sm"
                        class="mt-[-10px]"
                        @click="addFiles('new')"
                      >
                        <Icon name="lucide:plus" />
                      </BaseButtonIcon> -->
                    </div>
                    <div class="grid gap-8 pb-6 sm:grid-cols-2">
                      <div
                        v-for="(file, index) in data?.project.files"
                        :key="index"
                        rounded="lg"
                      >
                        <div class="flex w-full items-center gap-2">
                          <img
                            :src="file.icon"
                            :alt="file.name"
                            class="max-w-[46px]"
                          />
                          <div>
                            <BaseHeading tag="h3" size="sm" weight="medium">
                              {{ file.file_name }}
                            </BaseHeading>
                            <BaseParagraph size="xs" class="text-muted-400">
                              <span>{{ file.size }}</span>
                              <span class="px-1 text-base leading-tight">
                                &middot;
                              </span>
                              <span>v{{ file.version }}</span>
                            </BaseParagraph>
                          </div>
                          <div class="ms-auto">
                            <BaseButtonIcon
                              rounded="full"
                              data-nui-tooltip="Download file"
                              size="sm"
                              @click="downloadFile(file)"
                            >
                              <Icon name="lucide:arrow-down" />
                            </BaseButtonIcon>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                </BaseCard>
              </div>

              <div class="ltablet:col-span-4 col-span-12 lg:col-span-4">
                <div class="space-y-6">
                  <!-- Customer -->
                  <BaseCard class="p-6">
                    <div class="flex justify-between mb-2">
                      <h4
                        class="text-muted-400 mb-6 font-sans text-xs font-semibold uppercase"
                      >
                        {{ t('Contractor Company') }}
                      </h4>

                      <!-- <div class="flex mt-[-10px]">
                        <BaseButtonIcon
                          muted
                          size="sm"
                          @click="handleTeamClick('company')"
                        >
                          <Icon name="lucide:plus" />
                        </BaseButtonIcon>
                      </div> -->
                    </div>
                    <div
                      class="mb-4 flex items-center gap-2"
                      v-for="cteam in data?.project.contactor_company"
                      :key="cteam.id"
                    >
                      <BaseAvatar
                        :src="cteam.logo"
                        size="md"
                        :data-nui-tooltip="cteam.name"
                        class="bg-muted-100 dark:bg-muted-700"
                      />
                      <div>
                        <BaseHeading
                          tag="h5"
                          size="md"
                          weight="medium"
                          lead="none"
                          class="line-clamp-1"
                        >
                          {{ cteam.name }}
                        </BaseHeading>
                        <BaseParagraph
                          size="xs"
                          class="overflow-hidden text-muted-400"
                        >
                          {{ cteam.text }}
                        </BaseParagraph>
                      </div>
                    </div>

                    <!-- <div
                      class="mb-4 flex items-center gap-2"
                      v-for="cteam in data?.project.contactor_company"
                      :key="cteam.id"
                    >
                      <BaseAvatar
                        :src="cteam.logo"
                        size="md"
                        :data-nui-tooltip="cteam.name"
                        class="bg-muted-100 dark:bg-muted-700"
                      />
                      <div>
                        <BaseHeading
                          tag="h5"
                          size="md"
                          weight="medium"
                          lead="none"
                          class="line-clamp-1"
                        >
                          {{ cteam.name }}
                        </BaseHeading>
                        <BaseParagraph
                          size="xs"
                          class="overflow-hidden text-muted-400"
                        >
                          {{ cteam.text }}
                        </BaseParagraph>
                      </div>
                      <div class="flex absolute right-6">
                        <BaseButtonIcon
                          muted
                          size="sm"
                          @click="handleRemoveClick('company', cteam)"
                        >
                          <Icon name="lucide:minus" />
                        </BaseButtonIcon>
                      </div>
                    </div> -->
                    <!-- <div class="w-full space-y-1">
                      <div class="flex items-center justify-between">
                        <h4
                          class="text-muted-700 dark:text-muted-100 font-sans text-sm font-medium"
                        >
                          Progress
                        </h4>
                        <div>
                          <span class="text-muted-400 font-sans text-sm">
                            {{ data?.project.completed }}%
                          </span>
                        </div>
                      </div>
                      <BaseProgress
                        size="xs"
                        color="primary"
                        :value="data?.project.completed"
                      />
                    </div> -->
                  </BaseCard>

                  <!-- Teams -->
                  <!-- <BaseCard class="p-6">
                    <div class="flex justify-between mb-2">
                      <h4
                        class="text-muted-400 mb-6 font-sans text-xs font-semibold uppercase"
                      >
                        Contractor Teams
                      </h4>

                      <div class="flex mt-[-10px]">
                        <BaseButtonIcon
                          muted
                          size="sm"
                          @click="handleTeamClick('team')"
                        >
                          <Icon name="lucide:plus" />
                        </BaseButtonIcon>
                      </div>
                    </div>

                    <div
                      class="mb-4 flex items-center gap-2"
                      v-for="cteam in data?.project.contactor_teams"
                      :key="cteam.id"
                    >
                      <BaseAvatar
                        :src="cteam.logo"
                        size="md"
                        :data-nui-tooltip="cteam.name"
                        class="bg-muted-100 dark:bg-muted-700"
                      />
                      <div>
                        <BaseHeading
                          tag="h5"
                          size="md"
                          weight="medium"
                          lead="none"
                          class="line-clamp-1"
                        >
                          {{ cteam.name }}
                        </BaseHeading>
                        <BaseParagraph size="sm" class="text-muted-400">
                          {{ cteam.text }}
                        </BaseParagraph>
                      </div>
                      <div class="flex absolute right-6">
                        <BaseButtonIcon
                          @click="handleRemoveClick('team', cteam)"
                          muted
                          size="sm"
                          id="{{cteam.id}}"
                        >
                          <Icon name="lucide:minus" />
                        </BaseButtonIcon>
                      </div>
                    </div>
                  </BaseCard> -->

                  <!-- Comments -->
                  <BaseCard class="p-8">
                    <div class="pb-6">
                      <h4
                        class="text-muted-400 font-sans text-xs font-semibold uppercase"
                      >
                        {{ $t('Comments') }} ({{ comments.length }})
                      </h4>
                      <div v-if="comments.length === 0">
                        <div
                          class="text-muted-400 mt-10 flex items-center justify-center"
                        >
                          <Icon name="ph:chat-circle-thin" class="h-10 w-10" />
                        </div>
                        <div class="mb-6 mt-2 text-center">
                          <BaseHeading
                            as="h4"
                            size="md"
                            weight="light"
                            class="mb-1"
                          >
                            <span>{{ $t('Nothing to show') }}</span>
                          </BaseHeading>
                          <BaseParagraph
                            size="xs"
                            lead="tight"
                            class="text-muted-500 dark:text-muted-400 mx-auto max-w-[200px] !font-sans"
                          >
                            <span>{{ $t('No comments') }}</span>
                          </BaseParagraph>
                        </div>
                      </div>
                      <div v-else class="mt-6 flex flex-col gap-8">
                        <div
                          v-for="(comment, c) in comments"
                          :key="c"
                          class="flex gap-3"
                        >
                          <BaseAvatar :src="comment.author.picture" size="xs" />
                          <div>
                            <BaseHeading as="h3" size="sm" weight="medium">
                              {{ comment.author.name }}
                            </BaseHeading>
                            <BaseText
                              size="xs"
                              class="text-muted-400 mb-2"
                              lead="none"
                            >
                              {{ $t('posted') }} {{ comment.author.posted }}
                            </BaseText>
                            <BaseParagraph
                              size="xs"
                              class="text-muted-500 dark:text-muted-400"
                            >
                              {{ comment.text }}
                            </BaseParagraph>
                          </div>
                          <div class="flex commentCell absolute right-10">
                            <!-- <div
                  @click="editComment(comment)"
                  class="hover:text-[#532fcb] cursor-pointer"
                >
                  <Icon name="tabler:edit" />
                </div> -->
                            <div
                              v-if="comment.author.id == myId"
                              @click="deleteComment(comment)"
                              class="hover:text-[#532fcb] cursor-pointer"
                            >
                              <Icon name="mdi-light:delete" />
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div>
                      <BaseTextarea
                        v-model="commentArea"
                        shape="rounded"
                        :placeholder="$t('Write a comment...')"
                        :rows="4"
                        addon
                        class="write_comments"
                      >
                        <template #addon>
                          <div class="flex items-center gap-2">
                            <BaseAvatar
                              :src="previewUrl"
                              class="me-1"
                              size="xs"
                            />
                            <BaseHeading
                              as="h4"
                              size="sm"
                              weight="semibold"
                              class="text-muted-800 dark:text-white"
                            >
                              {{ my_name }}
                            </BaseHeading>
                          </div>
                          <div class="flex items-center gap-2">
                            <BaseButtonAction
                              color="primary"
                              :my_id="myId"
                              @click="addComment"
                            >
                              {{ $t('Publish') }}
                            </BaseButtonAction>
                          </div>
                        </template>
                      </BaseTextarea>
                    </div>
                  </BaseCard>
                </div>
              </div>
            </div>
          </div>
          <!-- Team -->
          <div v-else-if="activeValue === 'team'">
            <div class="team grid gap-6 sm:grid-cols-3">
              <BaseCard
                elevated-hover
                class="hover:!border-primary-500 relative"
              >
                <NuxtLink to="#">
                  <Icon
                    name="uiw:star-on"
                    class="text-primary-500 absolute end-6 top-6"
                  />
                  <div class="flex flex-col items-center p-5 sm:flex-row">
                    <div class="flex flex-col gap-3 sm:flex-row">
                      <BaseAvatar
                        :src="data?.project.owner?.avatar"
                        :badge-src="data?.project.owner?.badge"
                        :text="data?.project.owner?.name"
                        size="lg"
                        class="bg-muted-500/20 text-muted-500"
                      />
                      <div class="text-center leading-none sm:text-left">
                        <h4
                          class="text-muted-800 dark:text-muted-100 font-sans text-base font-medium"
                        >
                          {{ data?.project.owner?.name }}
                        </h4>
                        <p class="text-muted-400 mb-2 font-sans text-xs">
                          {{ $t('Project owner') }}
                        </p>
                        <p
                          class="text-muted-500 dark:text-muted-400 font-sans text-xs"
                        >
                          {{ data?.project.owner?.bio }}
                        </p>
                      </div>
                    </div>
                  </div>
                </NuxtLink>
              </BaseCard>
              <BaseCard
                v-for="item in data?.project.team"
                :key="item.id"
                elevated-hover
                class="hover:!border-primary-500"
              >
                <NuxtLink to="#">
                  <div class="flex flex-col items-center p-5 sm:flex-row">
                    <div class="flex flex-col gap-3 sm:flex-row">
                      <BaseAvatar
                        :src="item.src"
                        :badge-src="item.badge"
                        :text="item.text"
                        size="lg"
                        class="bg-muted-500/20 text-muted-500"
                      />
                      <div class="text-center leading-none sm:text-left">
                        <h4
                          class="text-muted-800 dark:text-muted-100 font-sans text-base font-medium"
                        >
                          {{ item.tooltip }}
                        </h4>
                        <p class="text-muted-400 mb-2 font-sans text-xs">
                          {{ item.role }}
                        </p>
                        <p
                          class="text-muted-500 dark:text-muted-400 font-sans text-xs"
                        >
                          {{ item.bio }}
                        </p>
                      </div>
                    </div>
                  </div>
                </NuxtLink>
              </BaseCard>
            </div>
          </div>
          <!-- Tasks -->
          <div v-else-if="activeValue === 'tasks'">
            <div class="tasks grid gap-6 sm:grid-cols-3">
              <BaseCard
                v-for="item in data?.project.tasks"
                :key="item.id"
                elevated-hover
                class="hover:!border-primary-500 flex cursor-pointer flex-col"
                @click="
                  openTaskPanel(
                    item.id,
                    data?.project?.tasks,
                    data?.project,
                    refresh,
                  )
                "
              >
                <div class="flex flex-col items-center p-5 sm:flex-row">
                  <div class="flex flex-col gap-3 sm:flex-row">
                    <Icon
                      v-if="item.status === 0"
                      name="ph:plus-circle-duotone"
                      class="text-muted-400 size-6 shrink-0"
                    />
                    <Icon
                      v-else-if="item.status === 5"
                      name="ph:check-circle-duotone"
                      class="text-success-500 size-6 shrink-0"
                    />
                    <Icon
                      v-else-if="item.status === 1"
                      name="ph:timer-duotone"
                      class="text-muted-400 size-6 shrink-0"
                    />
                    <Icon
                      v-else-if="item.status === 2 || item.status === 3"
                      name="ph:warning-duotone"
                      class="text-warning-500 size-6 shrink-0"
                    />
                    <div class="text-center leading-none sm:text-left">
                      <h4
                        class="text-muted-800 dark:text-muted-100 mb-2 font-sans text-base font-medium leading-tight"
                      >
                        {{ item.name }}
                      </h4>
                      <p class="text-muted-400 line-clamp-2 font-sans text-xs">
                        {{ item.description }}
                      </p>
                    </div>
                  </div>
                </div>
                <div
                  class="bg-muted-50 dark:bg-muted-700/50 mt-auto flex items-center justify-between rounded-b-lg px-5 py-3"
                >
                  <div class="flex max-w-[180px] grow items-center gap-2">
                    <BaseAvatar
                      size="xxs"
                      :src="item.assignee.src"
                      :data-nui-tooltip="item.assignee.tooltip"
                    />
                    <!-- <BaseProgress
                      :value="item.completion"
                      size="xs"
                      :color="item.status === 5 ? 'success' : 'primary'"
                    /> -->
                    <ProgressComp
                      size="xs"
                      ref="progressComponent"
                      :wo_id="item.id"
                    />
                  </div>
                  <div class="text-muted-400 flex items-center gap-4">
                    <div class="flex items-center gap-1 text-sm">
                      <Icon name="ph:paperclip-duotone" class="size-4" />
                      <span class="font-sans">
                        {{ item.files.length }}
                      </span>
                    </div>
                    <div class="flex items-center gap-1 text-sm">
                      <Icon name="ph:chat-circle-duotone" class="size-4" />
                      <span class="font-sans">
                        {{ item.comments.length }}
                      </span>
                    </div>
                  </div>
                </div>
              </BaseCard>
              <!-- Invite -->
              <!-- <div>
                <button
                  type="button"
                  class="border-muted-300 dark:border-muted-800 hover:border-primary-500 dark:hover:border-primary-500 group flex size-full items-center justify-center gap-2 rounded-lg border-2 border-dashed p-6 transition-colors duration-300"
                >
                  <span class="block text-center font-sans">
                    <span
                      class="text-muted-800 dark:text-muted-100 group-hover:text-primary-500 dark:group-hover:text-primary-500 block transition-colors duration-300"
                    >
                      Create a new task
                    </span>
                    <span class="text-muted-400 block text-sm">
                      Add a new task to your project
                    </span>
                  </span>
                </button>
              </div> -->
            </div>
          </div>
        </template>
      </BaseTabs>
    </div>
  </div>
  <ModalItemsList
    :open="isModalCompanyOpen"
    :close="handleModalTeamClose"
    :setItem="setCompany"
    :header="[
      { title: t('Name'), key: 'name', align: 'start', width: '30%' },
      {
        title: t('Register'),
        key: 'register',
        align: 'start',
        sortable: false,
      },
      {
        title: t('Created'),
        key: 'user_created.first_name',
        align: 'start',
        sortable: false,
      },
      { title: t('Action'), key: 'action', align: 'start', sortable: false },
    ]"
    title="Company"
    class="company"
    collection="Contractors"
    fields="*,user_created.first_name, users.directus_users_id.first_name, users.directus_users_id.email"
  />
  <ModalItemsList
    :open="isModalTeamsOpen"
    :header="[
      { title: t('Name'), key: 'name', align: 'start', width: '30%' },
      {
        title: t('Users'),
        key: 'users',
        align: 'start',
        sortable: false,
      },
      {
        title: t('Created'),
        key: 'user_created.first_name',
        align: 'start',
        sortable: false,
      },
      { title: t('Action'), key: 'action', align: 'start', sortable: false },
    ]"
    :close="handleModalTeamClose"
    :setItem="setTeam"
    :title="t('Teams')"
    class="teams"
    collection="Teams"
    :useslot="['users']"
    fields="*,user_created.first_name, users.directus_users_id.first_name, users.directus_users_id.email"
  />

  <!-- <AddDocuments
    :project_work="task_id"
    :uploadedFiles="uploadedFiles"
    :editFiles="editFiles"
    title="File upload"
    :key="selectedItem"
    :open="isModalNewFile"
    :files="files"
    :handleUploadRead="handleUploadRead"
    :close="addFilesClose"
    :row="selectedItem"
    :refresh="loadFiles"
    size="lg"
  /> -->

  <!-- <ConfirmModalForm
      :itemsValue="wo_data"
      code="Completed"
      text="Do you agree to this action?"
      :open="isModalApproveConfirmOpen"
      :close="handleModalConfirmClose"
      :do_make="do_make"
      actionType="Completed"
      :row="wo_data.id"
      :refresh="close"
    /> -->
</template>

<style>
.overview .inputs .nui-listbox-label {
  padding-bottom: 8px !important;
}

.overview .project_teams {
  border: none !important;
}
.loader .nui-placeholder-page.nui-placeholder-xs .nui-placeholder-page-img {
  max-width: 30px !important;
}

.overview .wo_input {
  height: 40px !important;
}
</style>
