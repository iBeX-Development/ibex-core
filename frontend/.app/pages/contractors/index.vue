<script setup lang="ts">
import AddModalForm from './AddModalForm.vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
definePageMeta({
  title: 'Contractors Work List',
  preview: {
    title: 'Contractors Work list',
    description: 'For list views and collections',
    categories: ['layouts', 'lists'],
    src: '/img/screens/layouts-table-list-3.png',
    srcDark: '/img/screens/layouts-table-list-3-dark.png',
    order: 46,
  },
})

const route = useRoute()
const router = useRouter()
const page = computed(() => parseInt((route.query.page as string) ?? '1'))
const { open } = usePanels()
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const user = useDirectusUser()
const config = useRuntimeConfig()

const data = ref([])
const filter = ref('')
const perPage = ref(10)

const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
//counts
const inTrack = ref(0)
const Overdue = ref(0)
const Total = ref(0)

const key = ref(1)
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const selectedItem = ref(-1)

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

function difficultyLabel(itemDifficulty: number) {
  switch (itemDifficulty) {
    case 1:
      return 'Very easy'
    case 2:
      return 'Easy'
    case 3:
      return 'Normal'
    case 4:
      return 'Hard'
    case 5:
      return 'Expert'
    default:
      break
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

function moneyFormat(value: number): string {
  if (isNaN(value) || !value) return ''
  return value.toLocaleString('mn-MN') + ' ₮'
}

async function transformContractors(coms) {
  Total.value = coms.length
  const now = new Date()

  const results = await Promise.all(
    coms.map(async (company) => {
      let amount = moneyFormat(await loadContracts(company.id))

      return {
        id: company.id,
        slug: company.id,
        name: company.name,
        register: company.register,
        picture: get_content_url(company._image, 'project'),
        category: company.category?.name || '',
        difficulty: company.rate,
        price: 26,
        skill: {
          icon: '',
          name: amount,
        },
        author: {
          id: company.user_created.id,
          picture: company.user_created.avatar
            ? `${config.public.directus.url}assets/${company.user_created.avatar?.filename_disk}`
            : null,
          username: company.user_created.first_name,
          last_name: company.user_created.last_name,
          initials: company.user_created.last_name,
          color: 'info',
        },
      }
    }),
  )

  return results
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
      company_id: myCompanyId,
    }
    const items = await getItems<any>({
      collection: 'Contractors',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: [
          '*',
          '_image.*',
          'category.*',
          'users.directus_users_id.first_name',
          'users.directus_users_id.avatar.*',
          'users.directus_users_id.id',
        ],
      },
    })
    serverItems.value = items.data
    data.value = await transformContractors(items.data)
    console.log('serverItems', data.value)

    // console.log('convertedProjects', inTrack.value, Overdue.value, Total.value)

    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}
const loadContracts = async (id) => {
  loading.value = true
  try {
    const filters = {
      active: 1,
      company: id,
      company_id: myCompanyId,
    }

    // console.log('filters', filters)

    const contracts_items = await getItems({
      collection: 'Contracts',
      params: {
        filter: filters,
        aggregate: {
          sum: 'amount',
        },
      },
    })
    console.log('docs', contracts_items)
    loading.value = false

    return contracts_items[0].sum.amount
    // if (contracts_items.data.length) {
    // serverItems.value = items.data
    // team.value = transformContracts(contracts_items.data)
    // }

    // totalItems.value = contracts_items.meta.filter_count
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

onMounted(async () => {
  // data.value = await getDemoData()
  await loadItems({ page: 1, itemsPerPage: -1, sortBy: [] })

  // console.log('onMounted_dada', data)
})

const goCompany = () => {
  // console.log('done')
  router.push(`/contractors/company`)
}

const refresh = (item) => {
  console.log('refreshed')
}
const onRowClicked = (item) => {
  // console.log('onRowClicked', item.id)

  open('demopanelcompany', {
    company: item.id,
    refresh: refresh,
  })
}
const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
  // console.log('isModalOpen', isModalOpen.value)
}

const handleModalClose = () => {
  isModalOpen.value = false
  console.log(isModalOpen.value)
}
const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleChangeModalKey = () => {
  selectedItem.value = -1
}
</script>

<template>
  <div style="margin-top: 128px">
    <TairoContentWrapperTabbed
      :labels="[t('All'), t('List')]"
      rounded="lg"
      style="padding-bottom: 32px"
    >
      <template #left>
        <div class="flex">
          <BaseInput
            v-model="filter"
            rounded="lg"
            icon="lucide:search"
            :placeholder="t('Filter')"
            :classes="{
              wrapper: 'w-full sm:w-auto',
            }"
          />
          <div class="ml-2">
            <BaseButtonIcon muted @click="handleModalOpen">
              <Icon name="lucide:plus" />
            </BaseButtonIcon>
          </div>
        </div>
      </template>

      <template #tab-1>
        <div v-if="data?.length === 0">
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
        </div>
        <div class="space-y-2 pt-6">
          <TransitionGroup
            enter-active-class="transform-gpu"
            enter-from-class="opacity-0 -translate-x-full"
            enter-to-class="opacity-100 translate-x-0"
            leave-active-class="absolute transform-gpu"
            leave-from-class="opacity-100 translate-x-0"
            leave-to-class="opacity-0 -translate-x-full"
          >
            <DemoFlexTableRow
              v-for="(item, index) in data"
              :key="index"
              rounded="sm"
            >
              <template #start>
                <DemoFlexTableStart
                  :label="t('Company')"
                  :hide-label="index > 0"
                  :title="item.name"
                  :subtitle="item.register"
                  :picture="item.picture"
                  :id="item.id"
                />
              </template>
              <template #end>
                <DemoFlexTableCell
                  :label="t('Direction')"
                  :hide-label="index > 0"
                  tablet-hidden
                  class="w-full sm:w-36"
                >
                  <span
                    class="overflow-hidden text-center h-[48px] text-muted-500 dark:text-muted-400 font-sans text-xs"
                  >
                    {{ item.category }}
                  </span>
                </DemoFlexTableCell>
                <DemoFlexTableCell
                  :label="t('Contract amount')"
                  :hide-label="index > 0"
                  class="w-full sm:w-32"
                >
                  <div
                    class="flex w-full items-center justify-end gap-1 sm:justify-center"
                  >
                    <Icon
                      :name="item.skill.icon"
                      class="text-primary-500 size-5"
                    />
                    <span
                      class="text-muted-500 dark:text-muted-400 font-sans text-sm"
                    >
                      {{ item.skill.name }}
                    </span>
                  </div>
                </DemoFlexTableCell>
                <DemoFlexTableCell
                  :label="t('KPA Performance')"
                  :hide-label="index > 0"
                  class="w-full sm:w-36"
                >
                  <div
                    class="flex w-full justify-end gap-1 sm:justify-center"
                    :data-nui-tooltip="difficultyLabel(item.difficulty)"
                  >
                    <span
                      class="block size-2 rounded-full"
                      :class="
                        item.difficulty >= 1
                          ? 'bg-primary-500'
                          : 'bg-muted-200 dark:bg-muted-700'
                      "
                    />
                    <span
                      class="block size-2 rounded-full"
                      :class="
                        item.difficulty >= 2
                          ? 'bg-primary-500'
                          : 'bg-muted-200 dark:bg-muted-700'
                      "
                    />
                    <span
                      class="block size-2 rounded-full"
                      :class="
                        item.difficulty >= 3
                          ? 'bg-primary-500'
                          : 'bg-muted-200 dark:bg-muted-700'
                      "
                    />
                    <span
                      class="block size-2 rounded-full"
                      :class="
                        item.difficulty >= 4
                          ? 'bg-primary-500'
                          : 'bg-muted-200 dark:bg-muted-700'
                      "
                    />
                    <span
                      class="block size-2 rounded-full"
                      :class="
                        item.difficulty === 5
                          ? 'bg-primary-500'
                          : 'bg-muted-200 dark:bg-muted-700'
                      "
                    />
                  </div>
                </DemoFlexTableCell>
                <DemoFlexTableCell :label="t('Action')" :hide-label="index > 0">
                  <BaseButtonAction color="muted" @click="onRowClicked(item)">
                    <span>{{ t('More') }}</span>
                  </BaseButtonAction>
                </DemoFlexTableCell>
              </template>
            </DemoFlexTableRow>
          </TransitionGroup>

          <div v-if="data?.length !== 0" class="pt-6">
            <BasePagination
              :total-items="data?.total ?? 0"
              :item-per-page="perPage"
              :current-page="page"
              rounded="full"
            />
          </div>
        </div>
      </template>
      <template #tab-2>
        <BasePlaceholderPage
          :title="t('No data')"
          :subtitle="t('Nothing to show')"
        >
          <template #image>
            <img
              class="block dark:hidden"
              src="/img/illustrations/placeholders/flat/placeholder-courses.svg"
              alt="Placeholder image"
            />
            <img
              class="hidden dark:block"
              src="/img/illustrations/placeholders/flat/placeholder-courses-dark.svg"
              alt="Placeholder image"
            />
          </template>
        </BasePlaceholderPage>
      </template>
    </TairoContentWrapperTabbed>
    <AddModalForm
      :key="key"
      :title="t('Add Company')"
      code="Contractors"
      :open="isModalOpen"
      :close="handleModalClose"
      :editRow="selectedItem"
      :refresh="handleChangeKey"
      :refresh_modal="handleChangeModalKey"
    />
  </div>
</template>
