<script setup lang="ts">
definePageMeta({
  title: 'Project List',
  middleware: ['auth'],
  preview: {
    title: 'Project list 3',
    description: 'For displaying a list of projects',
    categories: ['layouts', 'projects'],
    src: '/img/screens/layouts-projects-3.png',
    srcDark: '/img/screens/layouts-projects-3-dark.png',
    order: 70,
  },
})

const route = useRoute()
const router = useRouter()
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

// import { getDemoData } from './projects'
const page = computed(() => parseInt((route.query.page as string) ?? '1'))

// import AddModalFormTab from './AddModalFormTab.vue'
import AddModalForm from './AddModalForm.vue'
const user = useDirectusUser()
const config = useRuntimeConfig()

const filter = ref('')
const data = ref([])
const perPage = ref(25)

const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)

// Modal new & edit form
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const key = ref(1)
const key_update_modal = ref(-2)
const toaster = useToaster()

//counts
const inTrack = ref(0)
const Overdue = ref(0)
const Total = ref(0)

const category_status = ref('Mining')
let category_options = ref(['Mining', 'Software', 'Foods', 'Education'])

watch([filter, perPage], () => {
  router.push({
    query: {
      page: undefined,
    },
  })
})

const query = computed(() => {
  return {
    filter: filter.value,
    perPage: perPage.value,
    page: page.value,
  }
})

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
  // console.log('isModalOpen', isModalOpen.value)
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log(isModalOpen.value)
}

const do_edit = (item) => {
  console.log('Team : ', item)
  console.log('Team : ', item)
  // Perform your action here
  selectedItem.value = item
  console.log(selectedItem.value)
  isModalOpen.value = true
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleChangeModalKey = () => {
  selectedItem.value = -1
}

const clearItem = () => {
  selectedItem.value = -1
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
  // Reset counts
  inTrack.value = 0
  Overdue.value = 0
  Total.value = projects.length

  const now = new Date()
  return projects.map((project, index) => {
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

    // --- Count status by dates ---
    const dueDate = project.dueDate ? new Date(project.dueDate) : null
    if (dueDate) {
      if (dueDate >= now) {
        inTrack.value += 1
      } else {
        Overdue.value += 1
      }
    }

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

const loadFileItems = async (project) => {
  try {
    const filters = {
      project: { _in: project.id },
    }
    let items_count = await getItems<any>({
      collection: 'Project_work_files',
      params: {
        filter: filters,
        aggregate: {
          count: '*',
        },
        // groupBy: 'value',
        meta: 'filter_count',
      },
    })
    // console.log('loadFileItems', items_count)
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
      active: 1,
      state: { _in: [0, 1, 3] },
      company_id: myCompanyId,
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
          'project_leaders.directus_users_id.first_name',
          'project_leaders.directus_users_id.avatar.*',
          'project_leaders.directus_users_id.id',
          'users.*',
          '_image.*',
          'team.*',
          'team.Teams_id.*',
          'users.directus_users_id.first_name',
          'users.directus_users_id.avatar.*',
          'users.directus_users_id.id',
          'contactor_company.*',
          'contactor_company.Contractors_id.*',
          'contactor_company.Contractors_id._image.*',
        ],
      },
    })
    serverItems.value = items.data
    data.value = transformProjects(items.data)
    // console.log('serverItems', serverItems.value)

    // console.log('convertedProjects', inTrack.value, Overdue.value, Total.value)

    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

onMounted(async () => {
  await loadItems({ page: 1, itemsPerPage: -1, sortBy: [] })
  // data.value = await getDemoData()
  // console.log('projectsprojects', data)
  // console.log('projectsprojects', data)s
})
</script>

<template>
  <!-- <div class="col-span-12">
    <BaseButton>
      <Icon name="mynaui:plus" class="-ms-1 h-4 w-4" />
      <span class="text-[11px]">{{ $t('Project add') }}</span>
    </BaseButton>
  </div> -->

  <div class="relative mt-2">
    <!-- Header -->
    <TairoContentWrapper>
      <template #left>
        <BaseInput
          v-model="filter"
          icon="lucide:search"
          rounded="lg"
          :placeholder="$t('Filter projects...')"
          :classes="{
            wrapper: 'w-full sm:w-auto mt-[-42px]',
          }"
        />
      </template>
      <template #right>
        <BaseCard rounded="lg" class="min-w-[340px]">
          <div class="grid grid-cols-4 p-4">
            <div class="addProject flex items-center justify-center">
              <BaseButtonIcon muted @click="handleModalOpen">
                <Icon name="lucide:plus" />
              </BaseButtonIcon>
            </div>
            <div class="relative flex flex-col text-center">
              <span
                class="text-muted-800 dark:text-muted-100 font-sans text-2xl font-bold"
              >
                {{ inTrack }}
              </span>
              <p class="text-muted-400 font-sans text-xs">
                {{ $t('On Track') }}
              </p>
              <span
                class="bg-primary-500 absolute end-0 top-0 size-2 rounded-full"
              />
            </div>
            <div class="relative flex flex-col text-center">
              <span
                class="text-muted-800 dark:text-muted-100 font-sans text-2xl font-bold"
              >
                {{ Overdue }}
              </span>
              <p class="text-muted-400 font-sans text-xs">
                {{ $t('Overdue') }}
              </p>
              <span
                class="absolute end-0 top-0 size-2 rounded-full bg-amber-500"
              />
            </div>
            <div class="relative flex flex-col text-center">
              <span
                class="text-muted-800 dark:text-muted-100 font-sans text-2xl font-bold"
              >
                {{ Total }}
              </span>
              <p class="text-muted-400 font-sans text-xs">{{ $t('Total') }}</p>
              <span
                class="bg-success-500 absolute end-0 top-0 size-2 rounded-full"
              />
            </div>
          </div>
        </BaseCard>
      </template>
      <div class="space-y-10">
        <div class="mt-[32px]">
          <!-- <div v-if="data?.length === 0">
            <BasePlaceholderPage
              title="No matching results"
              subtitle="Looks like we couldn't find any matching results for your search terms. Try other search terms."
            >
              <template #image>
                <img
                  class="block dark:hidden"
                  src="/img/illustrations/placeholders/flat/placeholder-search-4.svg"
                  alt="Placeholder image"
                />
                <img
                  class="hidden dark:block"
                  src="/img/illustrations/placeholders/flat/placeholder-search-4-dark.svg"
                  alt="Placeholder image"
                />
              </template>
            </BasePlaceholderPage>
          </div> -->

          <div v-if="loading.value === true">
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

            <div>
              <div
                class="text-muted-400 mt-10 flex items-center justify-center"
              >
                <Icon name="ph:kanban-thin" class="size-8" />
              </div>
              <div class="mt-2 text-center">
                <BaseParagraph
                  size="xs"
                  lead="tight"
                  class="text-muted-500 dark:text-muted-400 mx-auto max-w-[200px] !font-sans"
                >
                  <span>{{ $t('Nothing to show') }}</span>
                </BaseParagraph>
              </div>
            </div>
          </div>

          <div
            v-if="data?.length === 0"
            class="h-[350px] flex flex-col justify-center items-center"
          >
            <div>
              <div
                class="text-muted-400 mt-10 flex items-center justify-center"
              >
                <Icon name="ph:kanban-thin" class="size-8" />
              </div>
              <div class="mt-2 text-center">
                <BaseParagraph
                  size="xs"
                  lead="tight"
                  class="text-muted-500 dark:text-muted-400 mx-auto max-w-[200px] !font-sans"
                >
                  <span>{{ $t('No data') }}</span>
                </BaseParagraph>
              </div>
            </div>
          </div>
          <div v-else>
            <div>
              <h4
                class="text-muted-400 mb-4 font-sans text-xs font-semibold uppercase"
              >
                {{ $t('All Projects') }}
              </h4>
            </div>
            <div
              class="ltablet:grid-cols-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-4"
            >
              <TransitionGroup
                enter-active-class="transform-gpu"
                enter-from-class="opacity-0 -translate-x-full"
                enter-to-class="opacity-100 translate-x-0"
                leave-active-class="absolute transform-gpu"
                leave-from-class="opacity-100 translate-x-0"
                leave-to-class="opacity-0 -translate-x-full"
              >
                <BaseCard
                  v-for="(item, index) in data"
                  :key="index"
                  rounded="lg"
                  elevated-hover
                  class="hover:!border-primary-500"
                >
                  <NuxtLink
                    class="group"
                    :to="`/projects/details/${item.slug}`"
                  >
                    <div class="p-5">
                      <div class="relative mb-4">
                        <img
                          :src="item.image"
                          :alt="item.name"
                          class="w-full rounded-lg"
                          style="height: 210px; min-width: auto"
                        />
                      </div>
                      <div class="mb-6 flex gap-2">
                        <BaseAvatar
                          :src="item.customer?.logo"
                          size="sm"
                          :data-nui-tooltip="item.name"
                          class="bg-muted-100 dark:bg-muted-700"
                        />
                        <div>
                          <BaseHeading
                            tag="h5"
                            size="sm"
                            weight="medium"
                            class="line-clamp-1"
                          >
                            {{ item.name }}
                          </BaseHeading>
                          <BaseParagraph size="xs" class="text-muted-400">
                            {{ item.code }}
                          </BaseParagraph>
                          <BaseParagraph size="xs" class="text-muted-400">
                            {{ item.customer?.name }} |
                            {{ item.customer?.text }}
                          </BaseParagraph>
                        </div>
                      </div>
                      <div class="flex items-center justify-between">
                        <!-- <div class="flex items-center gap-2">
                          <BaseAvatar
                            v-for="stack in item.stacks"
                            :key="stack.name"
                            :src="stack.icon"
                            size="xxs"
                            :data-nui-tooltip="stack.name"
                            class="bg-muted-100 dark:bg-muted-700"
                          />
                        </div> -->
                        <div class="text-muted-400 flex items-center gap-4">
                          <div class="flex items-center gap-1 text-sm">
                            <Icon name="ph:paperclip-duotone" class="size-4" />
                            <span class="font-sans">
                              {{ item.filesCnt || 0 }}
                            </span>
                          </div>
                          <div class="flex items-center gap-1 text-sm">
                            <Icon name="ph:users-duotone" class="size-4" />
                            <span class="font-sans">
                              {{ item.team?.length || 0 }}
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                    <div
                      class="border-muted-200 dark:border-muted-700 bg-muted-50 dark:bg-muted-700/50 flex items-center justify-between rounded-b-xl border-t px-5 py-3"
                    >
                      <div>
                        <p
                          class="text-success text-muted-400 font-sans text-sm"
                        >
                          {{ item.completed || 0 }} %
                        </p>
                      </div>
                      <div>
                        <BaseAvatarGroup
                          :avatars="item.team"
                          size="xs"
                          :limit="3"
                        />
                      </div>
                    </div>
                  </NuxtLink>
                </BaseCard>
              </TransitionGroup>
            </div>
          </div>
        </div>
      </div>
    </TairoContentWrapper>
  </div>
  <AddModalForm
    :key="selectedItem"
    title="Add Project"
    code="Projects"
    :open="isModalOpen"
    :close="handleModalClose"
    :editRow="selectedItem"
    :refresh="handleChangeKey"
    :refresh_modal="handleChangeModalKey"
  />
</template>
