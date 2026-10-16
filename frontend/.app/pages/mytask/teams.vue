<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { onMounted, ref } from 'vue'

import '~/assets/css/vcalendar.css'
import AddModalForm from './AddModalForm.vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'My Teams',
  showback: true,
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})
const myId = window.localStorage.getItem('myId')
const { getItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const user = useDirectusUser()
const config = useRuntimeConfig()
const search = ref('')
const serverItems = ref([])
const transformedTeams = ref([])
const loading = ref(true)
const totalItems = ref(0)

const data = ref([])
const my_teams_ids = ref([])

const loadItems = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array = []
  sortBy.map((sort_object) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })
  loading.value = true
  try {
    const filters_member = {
      directus_users_id: { _in: [myId] },
    }

    const member_items = await getItems({
      collection: 'Teams_directus_users',
      params: {
        filter: filters_member,
        // limit: itemsPerPage,
        // page: page,
        meta: 'filter_count',
        search: search.value,
        fields: ['*'],
      },
    })

    const leaders_items = await getItems({
      collection: 'Teams_directus_users_1',
      params: {
        filter: filters_member,
        // limit: itemsPerPage,
        // page: page,
        meta: 'filter_count',
        search: search.value,
        fields: ['*'],
      },
    })

    my_teams_ids.value = [
      ...new Set([
        ...(member_items.data?.map((item) => item.Teams_id) || []),
        ...(leaders_items.data?.map((item) => item.Teams_id) || []),
      ]),
    ]

    // if (isProxy(my_teams_ids.value)) {
    //   my_teams_ids.value = toRaw(my_teams_ids.value)
    // }
    const filters = {
      active: 1,
      id: { _in: my_teams_ids.value },
      company_id: { _eq: myCompanyId },
    }

    const items = await getItems<any>({
      collection: 'Teams',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: [
          '*',
          'team_leaders.directus_users_id.last_name',
          'team_leaders.directus_users_id.first_name',
          'team_leaders.directus_users_id.avatar',
          'team_leaders.directus_users_id.id',
          'users.*',
          'users.directus_users_id.first_name',
          'users.directus_users_id.last_name',
          'users.directus_users_id.avatar',
          'users.directus_users_id.id',
        ],
      },
    })
    serverItems.value = items.data
    totalItems.value = items.meta.filter_count

    data.value = serverItems?.value.map((team) => {
      // team_leaders болон users-ийг нэгтгэнэ
      const allMembers = [
        ...team.team_leaders.map((leader) => leader.directus_users_id),
        ...team.users.map((user) => user.directus_users_id),
      ]

      return {
        id: team.id.toString(),
        name: team.name,
        description: team.description,
        _image: team._image,
        stats: {
          projects: team.id + 14,
          replies: team.id + 97,
          posts: team.id + 16,
        },
        teams: allMembers.map((member) => ({
          id: member.id,
          first_name: member.first_name,
          src: member.avatar
            ? `${config.public.directus.url}assets/${member.avatar}`
            : '/img/avatars/14.svg',
        })),
      }
    })
    // console.log('transformedTeams', data)
    // console.log('teasm_more', serverItems)

    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

// Modal new & edit form
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)
const key = ref(1)
const key_update_modal = ref(-2)
const toaster = useToaster()

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
  console.log('isModalOpen', isModalOpen.value)
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log(isModalOpen.value)
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const do_edit = async (item) => {
  // console.log('do_edit : ', item)
  selectedItem.value = item
  isModalOpen.value = true
}

const handleChangeKey = async () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
  await loadItems({ page: 1, itemsPerPage: -1, sortBy: [] })
}

const handleChangeModalKey = () => {
  selectedItem.value = -1
}

const clearItem = () => {
  selectedItem.value = -1
}

const route = useRoute()
const router = useRouter()
const page = computed(() => parseInt((route.query.page as string) ?? '1'))

const filter = ref('')
const perPage = ref(10)

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

onMounted(async () => {
  // data.value = await getDemoData()
  // console.log('projectsprojects', data)
  await loadItems({ page: 1, itemsPerPage: -1, sortBy: [] })
})
</script>

<template>
  <div class="mt-[60px]">
    <TairoContentWrapper>
      <template #left>
        <BaseInput
          v-model="filter"
          icon="lucide:search"
          :placeholder="t('Filter')"
          :classes="{
            wrapper: 'w-[340px]',
          }"
        />
      </template>
      <template #right>
        <BaseButton class="w-full sm:w-32" @click="handleModalOpen">
          <Icon name="lucide:plus" class="size-4" />
          <span>{{ t('Add Team') }}</span>
        </BaseButton>
      </template>
      <div class="mt-[22px]">
        <div v-if="data?.length === 0">
          <BasePlaceholderPage
            title="No matching results"
            subtitle="Looks like we couldn't find any matching results for your search terms. Try other search terms."
          >
            <template #image>
              <img
                class="block dark:hidden"
                src="/img/illustrations/placeholders/flat/placeholder-search-1.svg"
                alt="Placeholder image"
              />
              <img
                class="hidden dark:block"
                src="/img/illustrations/placeholders/flat/placeholder-search-1-dark.svg"
                alt="Placeholder image"
              />
            </template>
          </BasePlaceholderPage>
        </div>
        <div v-else class="space-y-4">
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
              :key="item.id"
              rounded="lg"
              class="flex flex-col p-5 sm:flex-row sm:items-center"
            >
              <div
                class="flex flex-col items-center justify-center gap-3 text-center sm:flex-row sm:justify-start sm:text-left"
              >
                <BaseAvatar
                  size="lg"
                  :src="
                    item?._image
                      ? `${config.public.directus.url}assets/${item._image}`
                      : null
                  "
                  :text="item.name.slice(0, 2).toUpperCase()"
                  class="bg-primary-100 dark:bg-primary-500/20 text-primary-500 shrink-0"
                />
                <div>
                  <BaseHeading
                    tag="h3"
                    size="sm"
                    weight="medium"
                    class="text-muted-800 dark:text-muted-100"
                  >
                    {{ item.name }}
                  </BaseHeading>
                  <BaseParagraph
                    size="xs"
                    lead="none"
                    class="text-muted-400 flex items-end text-sm"
                  >
                    <!-- <Icon name="lucide:map-pin" class="size-4" /> -->
                    <span>{{ item.description }}</span>
                  </BaseParagraph>
                </div>
              </div>
              <div
                class="flex flex-col gap-4 pt-4 sm:ms-auto sm:flex-row sm:items-center sm:justify-end sm:pt-0"
              >
                <div
                  class="flex w-full items-center justify-center sm:w-[160px] sm:justify-end"
                >
                  <BaseTag
                    size="sm"
                    color="primary"
                    variant="pastel"
                    rounded="full"
                  >
                    <!-- {{ item.role }} -->
                    {{ t('Team') }}
                  </BaseTag>
                </div>
                <div
                  class="divide-muted-200 dark:divide-muted-700 flex items-center justify-center divide-x"
                >
                  <div class="flex flex-col gap-1 px-4 text-center">
                    <BaseHeading
                      tag="h3"
                      size="md"
                      weight="semibold"
                      class="text-muted-800 dark:text-muted-100"
                    >
                      <span>{{ item.stats.projects }}</span>
                    </BaseHeading>
                    <BaseParagraph
                      lead="none"
                      weight="semibold"
                      class="text-muted-400 !text-[0.65rem] uppercase"
                    >
                      <span>{{ t('Projects') }}</span>
                    </BaseParagraph>
                  </div>
                  <div class="flex flex-col gap-1 px-4 text-center">
                    <BaseHeading
                      tag="h3"
                      size="md"
                      weight="semibold"
                      class="text-muted-800 dark:text-muted-100"
                    >
                      <span>{{ item.stats.replies }}</span>
                    </BaseHeading>
                    <BaseParagraph
                      lead="none"
                      weight="semibold"
                      class="text-muted-400 !text-[0.65rem] uppercase"
                    >
                      <span>{{ t('Replies') }}</span>
                    </BaseParagraph>
                  </div>
                  <div class="flex flex-col gap-1 px-4 text-center">
                    <BaseHeading
                      tag="h3"
                      size="md"
                      weight="semibold"
                      class="text-muted-800 dark:text-muted-100"
                    >
                      <span>{{ item.stats.posts }}</span>
                    </BaseHeading>
                    <BaseParagraph
                      lead="none"
                      weight="semibold"
                      class="text-muted-400 !text-[0.65rem] uppercase"
                    >
                      <span>{{ t('Posts') }}</span>
                    </BaseParagraph>
                  </div>
                </div>
                <div
                  class="ptablet:hidden flex w-full items-center justify-center gap-1 py-3 sm:w-[160px] sm:justify-end sm:py-0"
                >
                  <BaseAvatarGroup size="xs" :avatars="item.teams" :limit="3" />
                  <p class="text-muted-400 font-sans text-xs">
                    {{ t('In Team') }}
                  </p>
                </div>
                <div class="sm:ms-6">
                  <BaseButtonAction
                    class="w-full sm:w-auto"
                    @click="do_edit(serverItems[index])"
                  >
                    {{ t('View') }}
                  </BaseButtonAction>
                </div>
              </div>
            </BaseCard>
          </TransitionGroup>

          <div>
            <BasePagination
              :total-items="totalItems?.value ?? 0"
              :item-per-page="perPage"
              :current-page="page"
              rounded="full"
            />
          </div>
        </div>
      </div>
    </TairoContentWrapper>
  </div>
  <AddModalForm
    :key="selectedItem"
    title="Teams"
    code="Teams"
    :open="isModalOpen"
    :close="handleModalClose"
    :editRow="selectedItem"
    :refresh="handleChangeKey"
    :refresh_modal="handleChangeModalKey"
  />
</template>
