<script setup lang="ts">
const props = defineProps<{
  actions?: boolean
}>()

const members = [
  {
    id: 0,
    firstName: 'Clarke',
    lastName: 'Smith',
    image: '/img/avatars/3.svg',
    text: 'EC',
    role: 'UI/UX designer',
  },
  {
    id: 1,
    firstName: 'Sara',
    lastName: 'Connor',
    image: undefined,
    text: 'SC',
    role: 'Frontend developer',
  },
  {
    id: 2,
    firstName: 'Tara',
    lastName: 'Svenson',
    image: '/img/avatars/4.svg',
    text: 'TS',
    role: 'Software architect',
  },
  {
    id: 3,
    firstName: 'Naomi',
    lastName: 'Liversky',
    image: undefined,
    text: 'NL',
    role: 'UI/UX designer',
  },
]

const search = ref('')
const teams = ref([])
const loading = ref(true)
const totalItems = ref(0)
const { getItems, updateItem } = useDirectusItems()
const user = useDirectusUser()
const config = useRuntimeConfig()

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
    }
    const items = await getItems({
      collection: 'Teams',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: '',
        fields: [
          '*',
          'team_leaders.directus_users_id.first_name',
          'team_leaders.directus_users_id.last_name',
          'team_leaders.directus_users_id.avatar',
          'team_leaders.directus_users_id.id',
          'users.*',
          'users.directus_users_id.first_name',
          'users.directus_users_id.id',
        ],
      },
    })
    teams.value = items.data
    totalItems.value = items.meta.filter_count
    // console.log('serverItems-index', teams)
    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

onMounted(async () => {
  await loadItems({ page: 1, itemsPerPage: 4, sortBy: [] })
})
</script>

<template>
  <div class="mb-2 space-y-5">
    <div
      v-for="member in teams"
      :key="member.id"
      class="flex items-center gap-3"
    >
      <BaseAvatar
        :src="
          member?._image
            ? `${config.public.directus.url}assets/${member._image}`
            : null
        "
        :text="member.name.slice(0, 2).toUpperCase()"
        class="bg-primary-100 dark:bg-primary-500/20 text-primary-500 shrink-0"
      />
      <div>
        <BaseHeading
          as="h4"
          size="sm"
          weight="light"
          lead="tight"
          class="text-muted-800 dark:text-white"
        >
          <span>{{ member.name }} </span>
        </BaseHeading>
        <BaseParagraph size="xs">
          <span class="text-muted-400">
            {{ member.description }}
          </span>
        </BaseParagraph>
      </div>
      <div v-if="props.actions" class="ms-auto flex items-center">
        <BaseButtonIcon rounded="lg" muted class="scale-75">
          <Icon name="ph:phone-duotone" class="size-5" />
        </BaseButtonIcon>
        <BaseButtonIcon rounded="lg" muted class="scale-75">
          <Icon name="ph:video-camera-duotone" class="size-5" />
        </BaseButtonIcon>
      </div>
    </div>
  </div>
</template>
