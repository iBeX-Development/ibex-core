<script setup lang="ts">
const { close } = usePanels()
const activeTab = ref('tab-1')
const props = withDefaults(
  defineProps<{
    task?: any
    refresh?: any
    company?: any
  }>(),
  {
    task: undefined,
    refresh: undefined,
    company: undefined,
  },
)

const search = ref('')
const teams = ref([])
const projects = ref([])
const loading = ref(true)
const totalTeams = ref(0)
const totalProjects = ref(0)
const { getItems, updateItem } = useDirectusItems()
const user = useDirectusUser()
const config = useRuntimeConfig()

// console.log('props', props)
const loadContract = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array = []
  sortBy.map((sort_object) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })
  loading.value = true
  try {
    const filters = {
      active: 1,
      company: props.company,
    }

    const items = await getItems<any>({
      collection: 'Contracts',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: [
          '*',
          'currency.*',
          'payment.*',
          'income.*',
          'users.directus_users_id.first_name',
          'users.directus_users_id.avatar.*',
          'users.directus_users_id.id',
        ],
      },
    })
    teams.value = items.data
    totalTeams.value = items.meta.filter_count
    // console.log('serverItems-index', teams)
    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

const get_content_url = (file, type) => {
  // console.log('file ->', file)

  if (type == 'avatar') {
    if (file && file.type.includes('image')) {
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

function transformProjects(projects) {
  // // Reset counts
  // inTrack.value = 0
  // Overdue.value = 0
  // Total.value = projects.length

  const now = new Date()
  return projects.map((linkedItem, index) => {
    let project = linkedItem?.Project_works_id?.project
    let contactor_companys = []

    const leader = project.project_leaders[0]?.directus_users_id
    const team = project.users.map((user) => {
      const u = user.directus_users_id
      // console.log('file_u ->', u)

      return {
        id: u.id,
        src: get_content_url(u.avatar, 'avatar'), // `/assets/${u.avatar || '2.svg'}`, // avatar байхгүй байж болно
        badge: '/img/stacks/vuejs.svg',
        role: 'Developer',
        bio: 'Default bio...',
        tooltip: u.first_name,
        'data-nui-tooltip': u.first_name,
        text: u.first_name
          .split(' ')
          .map((n) => n[0])
          .join('')
          .toUpperCase(),
      }
    })

    contactor_companys = project.contactor_company.map((company) => {
      const com = company.Contractors_id
      return {
        id: com?.id,
        logo: '/img/icons/logos/clover.svg',
        name: com?.name || 'No Contractors',
        text: com?.code,
      }
    })

    // // --- Count status by dates ---
    // const dueDate = project.dueDate ? new Date(project.dueDate) : null
    // if (dueDate) {
    //   if (dueDate >= now) {
    //     inTrack.value += 1
    //   } else {
    //     Overdue.value += 1
    //   }
    // }

    // console.log('contactor_companys', contactor_companys)

    return {
      id: String(project.id),
      slug: project.id, //project.name.toLowerCase().replace(/\s+/g, '-'),
      name: project.name,
      code: project.code,
      dueDate: project.dueDate || 'No due date',
      updated: 'Just now',
      image: get_content_url(project._image, 'project'),
      completed: project.completed, // Та хүсвэл бодож тооцоолж болно
      filesCnt: project.files_cnt,
      recent: false,
      category: project.category || 'General',
      description: project.description || '',
      meta: {
        sprintPerWeek: 2,
        monthDuration: 1,
        budgetType: 'Fixed',
      },
      owner: {
        id: leader?.id || 0,
        avatar: get_content_url(leader?.avatar, 'leader'),
        badge: '/img/stacks/vuejs.svg',
        role: 'Project Leader',
        bio: 'Default leader bio...',
        name: leader?.first_name || 'Unknown',
        text: leader?.first_name
          ? leader.first_name
              .split(' ')
              .map((n) => n[0])
              .join('')
              .toUpperCase()
          : '',
      },
      team,
      tools: [
        {
          name: 'Vue',
          description: 'Frontend Framework',
          icon: '/img/stacks/vuejs.svg',
        },
        {
          name: 'Tailwind',
          description: 'CSS Framework',
          icon: '/img/stacks/tailwind.svg',
        },
        {
          name: 'Vite',
          description: 'Build Tool',
          icon: '/img/stacks/vite.svg',
        },
      ],
      customer:
        contactor_companys.length > 0
          ? contactor_companys[0]
          : {
              logo: '/img/icons/logos/clover.svg',
              name: project.customer || 'No Contractors',
              text: project.code,
            },
    }
  })
}

const loadProject = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array = []
  sortBy.map((sort_object) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })
  loading.value = true
  try {
    const filters = {
      // active: '1',
      Contractors_id: { _in: [parseInt(props.company)] }, // Ensure it's an integer
    }

    // console.log('filters', filters)

    const itemss = await getItems<any>({
      collection: 'Project_works_Contractors_1',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: [
          '*',
          'Project_works_id.*',
          'Project_works_id.project.*',
          'Project_works_id.project.project_leaders.directus_users_id.first_name',
          'Project_works_id.project.project_leaders.directus_users_id.avatar.*',
          'Project_works_id.project.project_leaders.directus_users_id.id',
          'Project_works_id.project.users.directus_users_id.first_name',
          'Project_works_id.project.users.directus_users_id.avatar.*',
          'Project_works_id.project.users.directus_users_id.id',
          'Project_works_id.project._image.*',
          'Project_works_id.project.team.*',
          'Project_works_id.project.team.Teams_id.*',
        ],
      },
    })
    totalProjects.value = itemss.meta.filter_count
    projects.value = transformProjects(itemss.data)
    // console.log('Project_works-index', itemss)

    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

onMounted(async () => {
  await loadContract({ page: 1, itemsPerPage: 4, sortBy: [] })
  await loadProject({ page: 1, itemsPerPage: 4, sortBy: [] })
})
</script>

<template>
  <div
    class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 border bg-white"
  >
    <div class="flex h-16 w-full items-center justify-between px-10">
      <h2
        class="font-heading text-muted-700 text-lg font-semibold dark:text-white"
      >
        Contracts info
      </h2>
      <button
        type="button"
        class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300 dark:hover:text-white"
        @click="close"
      >
        <Icon name="feather:chevron-right" class="h-6 w-6" />
      </button>
    </div>

    <div class="flex h-16 items-center px-10">
      <!-- Tabs -->
      <div
        class="bg-muted-100 dark:bg-muted-700 relative flex h-10 w-full items-center rounded-lg font-sans text-sm"
      >
        <button
          type="button"
          class="relative z-20 flex h-full flex-1 items-center justify-center"
          :class="activeTab === 'tab-1' ? 'text-white' : 'text-muted-400'"
          @click="activeTab = 'tab-1'"
        >
          <span>Contracts</span>
        </button>
        <button
          type="button"
          class="relative z-20 flex h-full flex-1 items-center justify-center"
          :class="activeTab === 'tab-2' ? 'text-white' : 'text-muted-400'"
          @click="activeTab = 'tab-2'"
        >
          <span>Projects</span>
        </button>
        <div
          class="bg-primary-600 absolute start-0 top-0 z-10 h-full w-1/2 rounded-lg transition-all duration-300"
          :class="[
            activeTab === 'tab-1' && 'ms-0',
            activeTab === 'tab-2' && 'ms-[50%]',
          ]"
        ></div>
      </div>
    </div>

    <div
      class="slimscroll relative h-[calc(100%_-_128px)] w-full overflow-y-auto px-10"
    >
      <div class="py-6">
        <!-- Team tab content -->
        <div v-if="activeTab === 'tab-1'" class="space-y-4">
          <!-- Team member -->
          <div
            v-for="(item, index) in teams"
            :key="index"
            class="border-muted-200 dark:border-muted-600 dark:bg-muted-700 flex items-center rounded-lg border bg-white p-4"
          >
            <!-- <div
              class="relative inline-flex h-9 w-9 items-center justify-center rounded-full"
            >
              <BaseAvatar
                :src="
                  item?._image
                    ? `${config.public.directus.url}assets/${item._image}`
                    : null
                "
                :text="item.name.slice(0, 2).toUpperCase()"
                class="bg-primary-100 dark:bg-primary-500/20 text-primary-500 shrink-0"
              />
            </div> -->
            <div class="ms-3">
              <h6
                class="font-heading text-muted-800 text-sm font-semibold dark:text-white"
              >
                {{ item.name }}
              </h6>
              <p class="text-muted-400 font-sans text-xs">
                {{
                  item.amount != null
                    ? item.code +
                      ' / ' +
                      item.amount +
                      ' ' +
                      item.currency?.code +
                      '/'
                    : item.code + ' / 0'
                }}
              </p>
            </div>
            <NuxtLink
              to="#"
              class="border-muted-200 text-muted-400 hover:border-primary-500 hover:text-primary-500 dark:border-muted-500 dark:hover:border-primary-500 ms-auto flex h-9 w-9 items-center justify-center rounded-full border transition-colors duration-300"
            >
              <Icon name="feather:arrow-right" class="h-4 w-4" />
            </NuxtLink>
          </div>
        </div>

        <!-- Project tab content -->
        <div v-else-if="activeTab === 'tab-2'" class="space-y-4">
          <!-- Project -->
          <div
            v-for="(item, index) in projects"
            :key="index"
            class="border-muted-200 dark:border-muted-600 dark:bg-muted-700 rounded-lg border bg-white p-4"
          >
            <div class="mb-4 flex items-center">
              <div
                class="relative inline-flex h-10 w-10 items-center justify-center rounded-xl"
              >
                <img
                  :src="item.image"
                  class="max-w-full h-[42px] rounded-xl object-cover shadow-sm dark:border-transparent"
                  alt=""
                />
              </div>
              <div class="ms-3">
                <h6
                  class="font-heading text-muted-800 text-sm font-semibold dark:text-white"
                >
                  {{ item.name }}
                </h6>
                <div class="text-muted-400 font-sans text-xs">
                  {{ item.code + ' | ' + (item.completed || 0) + '%' }}
                </div>
              </div>
              <NuxtLink
                to="#"
                class="border-muted-200 text-muted-400 hover:border-primary-500 hover:text-primary-500 dark:border-muted-500 dark:hover:border-primary-500 ms-auto flex h-9 w-9 items-center justify-center rounded-full border transition-colors duration-300"
              >
                <Icon name="feather:arrow-right" class="h-4 w-4" />
              </NuxtLink>
            </div>
            <div
              class="bg-muted-200 dark:bg-muted-800 relative mb-4 h-1 w-full overflow-hidden rounded-lg"
            >
              <div
                class="bg-primary-500 absolute start-0 top-0 h-full rounded-lg transition duration-300"
                :style="{ width: (item.completed || 0) + '%' }"
              ></div>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-muted-400 font-sans text-xs">{{
                item.dueDate.split('T')[0]
              }}</span>
              <div class="flex items-end users">
                <div>
                  <BaseAvatarGroup :avatars="item.team" size="xxs" :limit="3" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
