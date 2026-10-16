<script setup lang="ts">
import 'v-calendar/dist/style.css'
import '~/assets/css/vcalendar.css'
import AddContractForm from './AddContractForm.vue'
import AddModalForm from './AddModalForm.vue'

definePageMeta({
  title: 'Company details',
  showback: true,
  preview: {
    title: 'Company dashboard',
    description: 'For corporate business',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-company.png',
    srcDark: '/img/screens/dashboards-company-dark.png',
    order: 11,
  },
})

const props = defineProps({
  open: Boolean,
  code: String,
  title: String,
  close: Function,
  refresh: Function,
  clear: Function,
  editRow: Object,
  row: Object,
})

const gaugePersonal = reactive(useGaugePersonal())
const barSalesProfit = reactive(useBarSalesProfit())

const route = useRoute()
const router = useRouter()
const page = computed(() => parseInt((route.query.page as string) ?? '1'))
const { open } = usePanels()
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
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
const isModalEditWork = ref(false)

// contracts vars
const isAddContract = ref(false)
const isEditContract = ref(false)

const company = computed(() => route.params.company)
const query = computed(() => {
  return {
    company: company.value,
  }
})

// console.log('company', company)
function useGaugePersonal() {
  const { primary } = useTailwindColors()
  const type = 'radialBar'
  const height = 220

  const options = {
    title: {
      text: undefined,
    },
    chart: {
      sparkline: {
        enabled: true,
      },
      toolbar: {
        show: false,
      },
    },
    colors: [primary.value],
    plotOptions: {
      radialBar: {
        startAngle: -90,
        endAngle: 90,
        track: {
          background: '#e7e7e7',
          strokeWidth: '97%',
          margin: 5, // margin is in pixels
          dropShadow: {
            enabled: false,
            top: 2,
            left: 0,
            color: '#999',
            opacity: 1,
            blur: 2,
          },
        },
        hollow: {
          margin: 0,
          size: '35%',
        },
        dataLabels: {
          name: {
            show: false,
          },
          value: {
            offsetY: -2,
            fontSize: '22px',
          },
        },
      },
    },
    fill: {
      type: 'gradient',
      gradient: {
        shade: 'light',
        shadeIntensity: 0.1,
        inverseColors: false,
        opacityFrom: 1,
        opacityTo: 1,
        stops: [0, 50, 53, 91],
      },
    },
    labels: ['Average Results'],
  }

  const series = shallowRef([76])

  return {
    type,
    height,
    options,
    series,
  }
}

function useBarSalesProfit() {
  const { primary, info, success } = useTailwindColors()
  const type = 'bar'
  const height = 250

  const options = {
    chart: {
      toolbar: {
        show: false,
      },
    },
    colors: [primary.value, info.value, success.value],
    legend: {
      position: 'top',
    },
    plotOptions: {
      bar: {
        horizontal: false,
        endingShape: 'rounded',
        columnWidth: '55%',
      },
    },
    dataLabels: {
      enabled: false,
    },
    stroke: {
      show: true,
      width: 2,
      colors: ['transparent'],
    },
    xaxis: {
      categories: [
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
      ],
    },
    yaxis: {
      labels: {
        formatter: function (val: string) {
          return val + 70
        },
      },
    },
    fill: {
      opacity: 1,
    },
    tooltip: {
      y: {
        formatter: function (val: string) {
          return val + 70
        },
      },
    },
  }

  const series = shallowRef([
    {
      name: 'Net Profit',
      data: [-26, -15, -13, -14, -9, -12, -7, -10, -4],
    },
    {
      name: 'Revenue',
      data: [6, 15, 31, 28, 17, 35, 21, 44, 24],
    },
    {
      name: 'Free Cash Flow',
      data: [-35, -29, -34, -44, -25, -22, -18, -17, -29],
    },
  ])

  return {
    type,
    height,
    options,
    series,
  }
}

const team = shallowRef([])

const selected = ref<string[]>([])

const isAllVisibleSelected = computed(() => {
  return selected.value.length === team.value?.length
})

function toggleAllVisibleSelection() {
  if (isAllVisibleSelected.value) {
    selected.value = []
  } else {
    selected.value = team.value?.map((item) => item.id) ?? []
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

function transformContractors(coms) {
  // Reset counts
  Total.value = coms.length
  const now = new Date()

  return coms.map((company, index) => {
    // console.log('company', company)

    return {
      id: company.id,
      slug: company.id, //project.name.toLowerCase().replace(/\s+/g, '-'),
      name: company.name,
      register: company.register,
      phone: company.phone,
      email: company.email,
      user_cnt: company.user_cnt,
      picture: get_content_url(company._image, 'project'),
      category: company.category?.name || '',
      difficulty: company.rate,
      price: 26,
      skill: {
        icon: 'uiw:html5',
        name: '$1,000.0',
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
  })
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
      id: parseInt(company.value, 0),
      company_id: { _eq: myCompanyId },
    }

    // console.log('filters', filters)

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

    if (items.data.length) {
      serverItems.value = items.data
      data.value = transformContractors(items.data)[0]
    }

    // console.log('transformContractors.value', data.value)
    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

function transformContracts(coms) {
  // Reset counts
  Total.value = coms.length
  const now = new Date()

  return coms.map((docs, index) => {
    return {
      id: docs.id,
      name: docs.name,
      code: docs.code,
      income: docs.income?.id,
      income_code: docs.income?.code,
      currency: docs.currency?.id,
      currency_code: docs.currency?.code,
      payment: docs.payment?.id,
      payment_code: docs.payment?.code,
      agreement: docs.agreement,
      tax_rate: docs.tax_rate,
      amount: docs.amount,
      start_date: docs.start_date.split('T')[0],
      status: docs.status,
      // delegate_name: docs.delegate_name,
      description: docs.description,
      due_date: docs.due_date.split('T')[0],
      files: [],
      author: {
        id: docs.user_created.id,
        picture: docs.user_created.avatar
          ? `${config.public.directus.url}assets/${docs.user_created.avatar?.filename_disk}`
          : null,
        username: docs.user_created.first_name,
        last_name: docs.user_created.last_name,
        initials: docs.user_created.last_name,
        color: 'info',
      },
    }
  })
}
const loadContracts = async ({ page, itemsPerPage, sortBy }) => {
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
      company: company.value,
      company_id: { _eq: myCompanyId },
    }

    // console.log('filters', filters)

    const contracts_items = await getItems<any>({
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

    if (contracts_items.data.length) {
      // serverItems.value = items.data
      team.value = transformContracts(contracts_items.data)
      // console.log('docs', team)
    }

    totalItems.value = contracts_items.meta.filter_count
    loading.value = false
  } catch (e) {
    loading.value = false
    console.log('eeee', e)
  }
}

const editInfo = (type) => {
  if (type == 'edit') {
    selectedItem.value = serverItems.value[0]
    isModalEditWork.value = true
  }
}

const handleModalClose = () => {
  isModalEditWork.value = false
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const handleChangeKey = async () => {
  // selectedItem.value = -1
  isModalEditWork.value = false
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)

  await loadItems({ page: 1, itemsPerPage: -1, sortBy: [] })
  await loadContracts({ page: 1, itemsPerPage: -1, sortBy: [] })
}

//  <!-- contracts sections -->

const addContract = (type) => {
  selectedItem.value = -1

  if (type == 'add') {
    isAddContract.value = true
  }
  if (type == 'edit') {
    isEditContract.value = true
  }
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}
const editContract = (item) => {
  isEditContract.value = true
  selectedItem.value = item
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const deleteContract = async (item) => {
  selectedItem.value = item
  let items = {
    active: 0,
  }

  const data = {
    collection: 'Contracts',
    id: item.id,
    item: items,
  }

  let deleted = await updateItem(data)
  // console.log('deleted', deleted)
  await loadContracts({ page: 1, itemsPerPage: -1, sortBy: [] })
}

const closeContract = (type) => {
  isAddContract.value = false
  isEditContract.value = false
  selectedItem.value = -1

  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

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

onMounted(async () => {
  // data.value = await getDemoData()
  await loadItems({ page: 1, itemsPerPage: -1, sortBy: [] })
  await loadContracts({ page: 1, itemsPerPage: -1, sortBy: [] })
})
</script>

<template>
  <div class="relative overflow-hidden">
    <div class="flex flex-col gap-6">
      <div class="relative">
        <BaseButton class="" @click="addContract('add')">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Add Contract') }}</span>
        </BaseButton>
      </div>
      <!-- Header -->
      <BaseCard class="p-6">
        <div
          class="xs:divide-y divide-muted-200 dark:divide-muted-700 flex w-full flex-col items-center sm:flex-row sm:divide-x"
        >
          <!-- Item -->
          <div class="flex-1">
            <div class="flex flex-col p-4 text-center sm:py-0">
              <Icon
                name="ph:coins-duotone"
                class="text-primary-500 mx-auto size-8"
              />

              <h4
                class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
              >
                12
              </h4>
              <p class="text-muted-400 font-sans text-sm">
                {{ $t('Contracts') }}
              </p>
            </div>
          </div>
          <!-- Item -->
          <div class="flex-1">
            <div class="flex flex-col p-4 text-center sm:py-0">
              <Icon
                name="ph:users-duotone"
                class="text-primary-500 mx-auto size-8"
              />
              <h4
                class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
              >
                162
              </h4>
              <p class="text-muted-400 font-sans text-sm">{{ $t('Users') }}</p>
            </div>
          </div>

          <!-- Item -->
          <div class="flex-1">
            <div class="flex flex-col p-4 text-center sm:py-0">
              <Icon
                name="ph:briefcase-duotone"
                class="text-primary-500 mx-auto size-8"
              />
              <h4
                class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
              >
                192
              </h4>
              <p class="text-muted-400 font-sans text-sm">
                {{ $t('Completed Projects') }}
              </p>
            </div>
          </div>
          <!-- Item -->
          <div class="flex-1">
            <div class="flex flex-col p-4 text-center sm:py-0">
              <Icon
                name="ph:ticket-duotone"
                class="text-primary-500 mx-auto size-8"
              />
              <h4
                class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
              >
                32
              </h4>
              <p class="text-muted-400 font-sans text-sm">
                {{ $t('Active Projects') }}
              </p>
            </div>
          </div>
        </div>
      </BaseCard>
      <!-- Grid -->
      <div class="grid grid-cols-12 gap-6">
        <!-- Widget Overview -->
        <div class="ptablet:col-span-6 col-span-12 sm:col-span-4">
          <BaseCard class="h-full p-6">
            <div class="flex h-full flex-col">
              <div class="relative mx-auto mb-4 size-20">
                <BaseAvatar size="xl" :src="data?.picture" />
                <div class="absolute bottom-0 end-0">
                  <BaseButtonIcon
                    shape="full"
                    size="sm"
                    data-tooltip="Edit "
                    condensed
                    @click="editInfo('edit')"
                  >
                    <Icon name="lucide:edit-3" />
                  </BaseButtonIcon>
                </div>
              </div>
              <div class="text-center">
                <BaseHeading
                  size="md"
                  weight="medium"
                  class="text-muted-800 dark:text-muted-100"
                >
                  <span>{{ data?.name }}</span>
                </BaseHeading>
                <BaseParagraph size="xs" class="text-muted-400 mb-2">
                  <span>{{ data?.register }}</span>
                </BaseParagraph>
                <BaseParagraph
                  size="sm"
                  class="text-muted-500 dark:text-muted-400 mx-auto max-w-[320px]"
                >
                  <span>
                    {{ data?.category }}
                  </span>
                </BaseParagraph>
              </div>
              <div
                class="border-muted-200 dark:border-muted-700 mt-auto border-t pt-6 text-center"
              >
                <div
                  class="divide-muted-200 dark:divide-muted-700 flex w-full items-center divide-x"
                >
                  <!-- Item -->
                  <div class="flex-1">
                    <div class="flex flex-col px-4 text-center">
                      <p
                        class="text-muted-800 dark:text-muted-100 font-sans text-sm font-semibold"
                      >
                        {{ data?.phone }}
                      </p>
                      <p
                        class="font-sansfont-semibold text-muted-400 text-[0.65rem] uppercase"
                      >
                        {{ $t('Phone') }}
                      </p>
                    </div>
                  </div>
                  <!-- Item -->
                  <div class="flex-1">
                    <div class="flex flex-col px-4 text-center">
                      <p
                        class="text-muted-800 dark:text-muted-100 font-sans text-sm font-semibold"
                      >
                        {{ data?.email }}
                      </p>
                      <p
                        class="text-muted-400 font-sans text-[0.65rem] font-semibold uppercase"
                      >
                        {{ $t('Email') }}
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </BaseCard>
        </div>
        <!-- Widget -->
        <div class="ptablet:col-span-6 col-span-12 sm:col-span-8">
          <BaseCard class="relative h-full">
            <DemoChartAreaStats />
          </BaseCard>
        </div>

        <!-- Widget -->
        <div class="col-span-12">
          <TairoTable rounded="sm" v-if="team.length > 0">
            <template #header>
              <TairoTableHeading uppercase class="px-4 py-6">
                <div class="flex items-center">
                  <!-- <BaseCheckbox
                    :model-value="isAllVisibleSelected"
                    :indeterminate="
                      selected.length > 0 && !isAllVisibleSelected
                    "
                    name="table-1-main"
                    rounded="sm"
                    color="primary"
                    @click="toggleAllVisibleSelection"
                  /> -->
                  №
                </div>
              </TairoTableHeading>
              <TairoTableHeading uppercase>
                {{ $t('Contract Name') }}
              </TairoTableHeading>
              <TairoTableHeading uppercase>
                {{ $t('Amount') }}
              </TairoTableHeading>
              <TairoTableHeading uppercase> {{ $t('Tax') }} </TairoTableHeading>
              <TairoTableHeading uppercase>
                {{ $t('Status') }}
              </TairoTableHeading>
              <TairoTableHeading uppercase>
                {{ $t('Start') }}
              </TairoTableHeading>
              <TairoTableHeading uppercase> {{ $t('Due') }} </TairoTableHeading>
              <TairoTableHeading uppercase class="px-4 py-6">
                <span class="sr-only">View</span>
              </TairoTableHeading>
            </template>

            <TairoTableRow v-for="(member, index) in team" :key="member.id">
              <TairoTableCell class="p-4">
                <div class="flex items-center">
                  <p class="font-heading text-sm font-semibold">
                    {{ index + 1 }}.
                  </p>
                  <!-- <BaseCheckbox
                    v-model="selected"
                    :value="member.id"
                    :name="member.id"
                    rounded="sm"
                    color="primary"
                  /> -->
                </div>
              </TairoTableCell>
              <TairoTableCell>
                <div class="flex items-center max-w-[242px] overflow-hidden">
                  <div class="ms-3 leading-none">
                    <h4 class="font-heading text-sm font-semibold">
                      {{ member.name }}
                    </h4>
                    <p class="text-muted-400 font-sans text-xs">
                      {{ member.code }}
                    </p>
                  </div>
                </div>
              </TairoTableCell>

              <!-- <TairoTableCell>
                <div
                  class="flex w-full justify-end gap-1 sm:justify-start"
                  :data-nui-tooltip="difficultyLabel(member.rate)"
                >
                  <span
                    class="block size-2 rounded-full"
                    :class="
                      member.rate >= 1
                        ? 'bg-primary-500'
                        : 'bg-muted-200 dark:bg-muted-700'
                    "
                  />
                  <span
                    class="block size-2 rounded-full"
                    :class="
                      member.rate >= 2
                        ? 'bg-primary-500'
                        : 'bg-muted-200 dark:bg-muted-700'
                    "
                  />
                  <span
                    class="block size-2 rounded-full"
                    :class="
                      member.rate >= 3
                        ? 'bg-primary-500'
                        : 'bg-muted-200 dark:bg-muted-700'
                    "
                  />
                  <span
                    class="block size-2 rounded-full"
                    :class="
                      member.rate >= 4
                        ? 'bg-primary-500'
                        : 'bg-muted-200 dark:bg-muted-700'
                    "
                  />
                  <span
                    class="block size-2 rounded-full"
                    :class="
                      member.rate === 5
                        ? 'bg-primary-500'
                        : 'bg-muted-200 dark:bg-muted-700'
                    "
                  /></div
              ></TairoTableCell> -->
              <TairoTableCell light>
                {{
                  member.amount != null
                    ? member.amount + '/' + member.currency_code
                    : 0
                }}
              </TairoTableCell>
              <TairoTableCell light>
                {{ member.tax_rate != null ? member.tax_rate + '%' : '0%' }}
              </TairoTableCell>
              <TairoTableCell>
                <BaseTag
                  v-if="member.status === 5"
                  color="success"
                  variant="pastel"
                  rounded="full"
                  class="font-medium"
                >
                  {{ $t('Done') }}
                </BaseTag>
                <BaseTag
                  v-else-if="member.status === 0"
                  color="muted"
                  variant="pastel"
                  rounded="full"
                  class="font-medium"
                >
                  {{ $t('New') }}
                </BaseTag>
                <BaseTag
                  v-else-if="member.status === 1"
                  color="info"
                  variant="pastel"
                  rounded="full"
                  class="font-medium"
                >
                  {{ $t('In process') }}
                </BaseTag>
                <BaseTag
                  v-else-if="member.status === 3"
                  color="warning"
                  variant="pastel"
                  rounded="full"
                  class="font-medium"
                >
                  {{ $t('On Hold') }}
                </BaseTag>
              </TairoTableCell>
              <TairoTableCell light>
                {{ member.start_date }}
              </TairoTableCell>
              <TairoTableCell light>
                {{ member.due_date }}
              </TairoTableCell>
              <TairoTableCell>
                <div class="flex commentCell absolute mt-[-10px]">
                  <div
                    @click="editContract(member)"
                    class="hover:text-[#532fcb] cursor-pointer"
                  >
                    <Icon name="tabler:edit" class="h-5 w-5" />
                  </div>
                  <div
                    @click="deleteContract(member)"
                    class="hover:text-[#532fcb] cursor-pointer ml-1"
                  >
                    <Icon name="mdi-light:delete" class="h-5 w-5" />
                  </div>
                </div>
              </TairoTableCell>
            </TairoTableRow>
          </TairoTable>
        </div>

        <!-- Widget Personal -->
        <!-- <div class="ptablet:col-span-6 col-span-12 sm:col-span-3">
          <BaseCard class="flex h-full flex-col p-6">
            <div class="mb-6 flex items-center justify-between">
              <BaseHeading
                as="h3"
                size="md"
                weight="semibold"
                lead="tight"
                class="text-muted-800 dark:text-white"
              >
                <span>Personal Score</span>
              </BaseHeading>
            </div>
            <div class="py-16">
              <AddonApexcharts v-bind="gaugePersonal" class="-mt-14" />
            </div>
            <div class="mt-auto text-center">
              <BaseParagraph size="sm">
                <span class="text-muted-400">
                  Your score has been calculated based on the latest metrics
                </span>
              </BaseParagraph>
            </div>
          </BaseCard>
        </div> -->
        <!-- Chart Profit -->
        <!-- <div class="ptablet:col-span-6 col-span-12 sm:col-span-6">
          <BaseCard class="relative p-6">
            <div class="mb-6">
              <BaseHeading
                as="h3"
                size="md"
                weight="semibold"
                lead="tight"
                class="text-muted-800 dark:text-white"
              >
                <span>Profit</span>
              </BaseHeading>
            </div>
            <AddonApexcharts v-bind="barSalesProfit" />
          </BaseCard>
        </div> -->
        <!-- Widget Date -->
        <!-- <div class="ptablet:hidden col-span-12 sm:col-span-3">
          <BaseCard class="flex h-full flex-col p-2">
            <Calendar
              :attributes="[
                {
                  key: 'today',
                  highlight: true,
                  order: 0,
                  dates: [new Date()],
                },
              ]"
              title-position="left"
              expanded
              borderless
              transparent
              trim-weeks
              class="max-w-full rounded-md"
            />
          </BaseCard>
        </div> -->
      </div>
    </div>
    <AddContractForm
      :key="key"
      title="Edit Contract"
      code="Contract"
      :open="isEditContract"
      :close="closeContract"
      :editRow="selectedItem"
      :company="company"
      :refresh="handleChangeKey"
    />
    <AddContractForm
      :key="key"
      title="Add Contract"
      code="Contract"
      :open="isAddContract"
      :close="closeContract"
      :editRow="selectedItem"
      :company="company"
      :refresh="handleChangeKey"
    />
    <AddModalForm
      :key="selectedItem"
      title="Edit Company"
      code="Contractors"
      :open="isModalEditWork"
      :close="handleModalClose"
      :editRow="selectedItem"
      :refresh="handleChangeKey"
    />
  </div>
</template>
