<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'

import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
import AddModalForm from './AddModalForm.vue'

const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'News Settings',
  showback: true,
  preview: {
    title: 'Health dashboard',
    content: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})

const { getItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const user = useDirectusUser()
const config = useRuntimeConfig()
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)

const data = ref([])

const loadItems = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array = []
  sortBy.map((sort_object) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })
  loading.value = true
  try {
    console.log('🔍 Loading news from API...')
    const filters = {
      status: 'published',
      company_id: myCompanyId,
    }
    const items = await getItems<any>({
      collection: 'news',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: ['*', 'image.*', 'image.directus_files_id.*'],
      },
    })
    console.log('✅ API Response:', items)
    console.log('📊 News count:', items?.data?.length)

    serverItems.value = items.data
    totalItems.value = items.meta.filter_count

    data.value = serverItems?.value.map((news) => {
      // team_leaders болон users-ийг нэгтгэнэ

      return {
        id: news.id.toString(),
        title: news.title,
        content: news.content,
        image: news.image,
        date_created: news.date_created,
      }
    })

    console.log('data', data)

    loading.value = false
  } catch (e) {
    console.error('❌ Error loading news:', e)
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
  await loadItems({ page: 1, itemsPerPage: -1, sortBy: [] })
  // console.log('projectsprojects', data)
})
</script>

<template>
  <div class="mt-2">
    <TairoContentWrapper>
      <template #right>
        <BaseInput
          v-model="filter"
          icon="lucide:search"
          :placeholder="$t('Filter')"
          :classes="{
            wrapper: 'w-full sm:w-auto',
          }"
        />
      </template>
      <template #left>
        <BaseButton class="w-full sm:w-32" @click="handleModalOpen">
          <Icon name="lucide:plus" class="size-4" />
          <span>{{ $t('Add news') }}</span>
        </BaseButton>
      </template>
      <div class="mt-[62px]">
        <div v-if="data?.length === 0">
          <BasePlaceholderPage
            :title="$t('No matching results')"
            :subtitle="$t(`No data for the current filter`) + '.'"
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
                    item?.image &&
                    Array.isArray(item.image) &&
                    item.image.length > 0
                      ? `${config.public.directus.url}assets/${
                          item.image[0]?.directus_files_id?.id ||
                          item.image[0]?.directus_files_id
                        }`
                      : null
                  "
                  :text="item.title.slice(0, 2).toUpperCase()"
                  class="bg-primary-100 dark:bg-primary-500/20 text-primary-500 shrink-0"
                />
                <div>
                  <BaseHeading
                    tag="h3"
                    size="sm"
                    weight="medium"
                    class="text-muted-800 flex items-end dark:text-muted-100"
                  >
                    {{ item.title }}
                  </BaseHeading>
                  <BaseParagraph
                    size="xs"
                    lead="none"
                    class="text-muted-400 flex items-end text-sm"
                  >
                    <!-- <Icon name="lucide:map-pin" class="size-4" /> -->
                    <span>{{ item.content }}</span>
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
                    {{ $t('News') }}
                  </BaseTag>
                </div>

                <div class="sm:ms-6">
                  <BaseButtonAction
                    class="w-full sm:w-auto"
                    @click="do_edit(serverItems[index])"
                  >
                    {{ $t('View') }}
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
    title="News Form"
    code="News"
    :open="isModalOpen"
    :close="handleModalClose"
    :editRow="selectedItem"
    :refresh="handleChangeKey"
    :refresh_modal="handleChangeModalKey"
    icon="material-symbols:newsmode-outline-rounded"
  />
</template>
