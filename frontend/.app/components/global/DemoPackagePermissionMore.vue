<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    role?: any
    readonly?: boolean
  }>(),
  {
    role: undefined,
    readonly: false,
  },
)

const { close } = usePanels()

import { useI18n } from 'vue-i18n'
import SubsidebarLocationMenus from '~/components/global/SubsidebarLocationMenus'

import { action_status } from '~/components/workorder/WorkOrderConstants'

const toaster = useToaster()
const { t } = useI18n({ useScope: 'global' })
const route = useRoute()
const router = useRouter()
const { params } = useRoute()

const { getItems, updateItem, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const key = ref(1)
const user = useDirectusUser()
const config = useRuntimeConfig()

const myId = window.localStorage.getItem('myId')
const userImgId = ref(null)
const task_id = ref(-1)
const project_id = ref(-1)
const my_name = ref('')
const my_id = ref('')

const loading = ref(false)
const selected = ref([])
const selectAll = ref(false)
const selectedItem = ref([])
const menusItem = ref([])
const locationItem = ref([])
const locationMenus = ref([])
const actions_type = ref([])
const tr_actions_type = ref([])
const openIndexes = ref([])

const additional_items = ref([
  {
    id: 7,
    name: t('Shared sections'),
    children: [
      {
        name: 'Requests',
        icon: 'codicon:git-pull-request-go-to-changes',
        to: '/works/requests',
        action: 'read',
        collection: 'Work_order',
      },
      {
        name: 'Work Orders',
        icon: 'octicon:tasklist-16',
        to: '/works/workorders',
        action: 'read',
        collection: 'Work_order',
        exact: true,
      },
      {
        name: 'Completed Works',
        icon: 'mdi:check-all',
        to: '/works/completed',
        action: 'read',
        collection: 'Work_order',
      },
      {
        name: 'All Works',
        icon: 'fluent:briefcase-search-24-regular',
        to: '/works/allworks',
        action: 'read',
        collection: 'Work_order',
      },
      {
        name: 'Parts',
        icon: 'material-symbols-light:upload',
        to: '/shared/parts',
        action: 'read',
        collection: 'Parts',
        exact: true,
      },
      {
        name: 'Datahub',
        icon: 'material-symbols-light:upload-2-rounded',
        to: '/shared/datahub',
        action: 'read',
        collection: 'Parts',
      },
      {
        name: 'Formats',
        icon: 'material-symbols-light:upload-2-rounded',
        to: '/shared/formats',
        action: 'read',
        collection: 'Parts',
      },
    ],
  },
  {
    id: 8,
    name: t('Inventory'),
    children: [
      {
        name: 'Budget List',
        icon: 'mdi:cash-multiple',
        to: '/budgets',
        action: 'read',
        collection: 'Budget',
      },
      {
        name: 'Parts list',
        icon: 'prime:list',
        to: '/parts/list',
        action: 'read',
        collection: 'Parts',
      },
      {
        name: 'Warehouse',
        icon: 'mdi:warehouse',
        to: '/warehouse',
        action: 'read',
        collection: 'Warehouse',
      },
      {
        name: 'Income',
        icon: 'material-symbols-light:arrow-circle-right-outline-rounded',
        to: '/transaction/income',
        action: 'read',
        collection: 'Transaction',
      },
      {
        name: 'Debt',
        icon: 'material-symbols-light:arrow-circle-left-outline-rounded',
        to: '/transaction/outcome',
        action: 'read',
        collection: 'Transaction',
      },
    ],
  },
])

const sub_items = ref([
  { id: 1, name: t('Menus'), children: [] },
  // { id: 2, name: 'Locations', children: [] },
  { id: 3, name: t('Locations subMenus'), children: [] },
  // { id: 4, name: t('Work Actions'), children: [] },
  // { id: 5, name: t('Transaction Actions'), children: [] },
  {
    id: 6,
    name: t('Dashboard'),
    children: [
      {
        name: t('Costs'),
        key: 'cost',
        tab: 'Tab1',
        icon: 'solar:money-bag-outline',
        color: 'text-green-600',
        hoverColor: 'group-hover:bg-green-400 dark:group-hover:bg-green-400',
        id: 1,
        is_checked: false,
      },
      {
        name: t('Works'),
        key: 'performance',
        tab: 'Tab2',
        icon: 'fluent:wrench-settings-24-regular',
        color: 'text-red-400',
        hoverColor: 'group-hover:bg-rose-500 dark:group-hover:bg-rose-500',
        id: 2,
        is_checked: false,
      },
      {
        name: t('Tasks'),
        key: 'task',
        tab: 'Tab3',
        icon: 'carbon:operations-record',
        color: 'text-sky-500',
        hoverColor: ' group-hover:bg-sky-500 dark:group-hover:bg-sky-500',
        id: 3,
        is_checked: false,
      },
      {
        name: t('Monitoring'),
        key: 'monitoring',
        icon: 'material-symbols:monitoring',
        color: 'text-orange-500',
        hoverColor: ' group-hover:bg-orange-500 dark:group-hover:bg-orange-500',
        id: 6,
      },
      // {
      //   name: t('Performance'),
      //   key: 'private',
      //   icon: 'carbon:operations-record',
      //   color: 'text-orange-500',
      //   hoverColor: ' group-hover:bg-orange-500 dark:group-hover:bg-orange-500',
      //   id: 5,
      // },
      {
        name: t('Safety'),
        key: 'safety',
        tab: 'Tab4',
        icon: 'ph:bank-duotone',
        color: 'text-indigo-500',
        hoverColor: ' group-hover:bg-indigo-500 dark:group-hover:bg-indigo-500',
        id: 4,
        is_checked: false,
      },
    ],
  },
])

const statusValue = ref({
  id: 1,
  text: 'Status',
  icon: 'mdi:progress-clock',
})

const get_content_url = (file, type = 'avatar') => {
  // if (!file?.type.includes('image') && !is_path) {
  //   return `/img/avatars/placeholder-file.png`
  // }

  // console.log('get_content_url', file)
  if (file?.type) {
    return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
  } else {
    return `/img/avatars/16.svg`
  }
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

const loadMenus = async (type) => {
  const menusRes = await getItems({
    collection: 'Menus',
    params: {
      filter: { position: 'start', is_active: 1 },
      meta: 'filter_count',
      fields: ['*'],
    },
  })

  menusItem.value = menusRes.data
}

const loadLocations = async (type) => {
  let filters = {
    status: '1',
    company_id: myCompanyId,
  }
  const locationRes = await getItems({
    collection: 'Location',
    params: {
      filter: filters,
      meta: 'filter_count',
      fields: ['*'],
    },
  })
  locationItem.value = locationRes.data
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
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

const toggleChildren = (index: number) => {
  if (openIndexes.value.includes(index)) {
    openIndexes.value = openIndexes.value.filter((i) => i !== index)
  } else {
    openIndexes.value.push(index)
  }
}

// "Menus" (sub_items id=1) доторх checkbox-ийн шошго (t-ээр орчуулсан)
// additional_items[].name-той (мөн t-ээр орчуулсан) таарч байгаа эсэхийг шалгана
const findAdditionalItem = (menuChild) => {
  const label = menuChild.name ? t(menuChild.name) : t(menuChild.title)
  return additional_items.value.find((group) => group.name === label)
}

// Menus доторх "Inventory"/"Shared sections" цэсийг check хийхэд тохирох
// additional_items бүлгийг sub_items дотор нэмж харуулна, uncheck хийхэд хасна (hide)
const syncAdditionalItem = (menuChild) => {
  const group = findAdditionalItem(menuChild)
  if (!group) return

  const existingIndex = sub_items.value.findIndex((i) => i.id === group.id)

  if (menuChild.is_checked) {
    if (existingIndex === -1) {
      sub_items.value.push({
        id: group.id,
        name: group.name,
        children: group.children.map((child) => ({
          ...child,
          is_checked: false,
        })),
      })
      openIndexes.value = sub_items.value.map((_, i) => i)
    }
  } else if (existingIndex !== -1) {
    sub_items.value.splice(existingIndex, 1)
    openIndexes.value = sub_items.value.map((_, i) => i)
  }
}

const onChildCheck = (item, child, val) => {
  child.is_checked = val
  if (item.id === 1) {
    syncAdditionalItem(child)
  }
}

const windowClose = async (type) => {
  if (props.readonly) {
    if (type == 'bttn') close()
    return
  }

  if (!props.role?.id) {
    if (type == 'bttn') close()
    return
  }

  const access_data = sub_items.value.map((item) => ({
    id: item.id,
    name: item.name,
    children: (item.children || []).map((child) => ({
      id: child.id,
      key: child.key,
      title: child.title,
      name: child.name,
      is_checked: !!child.is_checked,
      tab: child.tab,
      icon: child.icon,
      color: child.color,
      hoverColor: child.hoverColor,
    })),
  }))

  try {
    loading.value = true
    await updateItem({
      collection: 'Pricing_packages',
      id: props.role.id,
      item: { permissions: access_data },
    })

    toaster.show({
      title: t('Saved'),
      message: t('Package permissions updated'),
      color: 'success',
      icon: 'ph:check-circle-fill',
      closable: true,
    })
  } catch (error) {
    toaster.show({
      title: t('Error'),
      message: t('Unable to save package permissions'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
  } finally {
    loading.value = false
  }

  if (type == 'bttn') close()
}

const disabler = document.querySelector('.disabler')
if (disabler) {
  disabler.addEventListener(
    'click',
    (e) => {
      e.stopPropagation()
      windowClose('disabler')
    },
    { once: true }, // 🎯 Зөвхөн нэг удаа ажиллана
  )
}

onMounted(async () => {
  try {
    // console.log('onMounted', props)

    locationMenus.value = SubsidebarLocationMenus(null)

    await loadMenus()
    await loadLocations()

    // Set children for specific sub_items by ID
    const setChildrenById = (id: number, children: any) => {
      const item = sub_items.value.find((i) => i.id === id)
      if (item) item.children = children
    }

    setChildrenById(1, menusItem.value)
    setChildrenById(3, locationMenus.value)

    // setChildrenById(2, locationItem.value)
    // setChildrenById(4, actions_type.value)
    // setChildrenById(5, tr_actions_type.value)
    sub_items.value.forEach((item) => {
      item.children.forEach((child) => {
        if (child.is_checked === undefined) {
          child.is_checked = false
        }
      })
    })

    if (props.role?.id) {
      const packageRes = await getItems({
        collection: 'Pricing_packages',
        params: {
          filter: { id: props.role.id },
          fields: ['*'],
        },
      })
      const packageData = Array.isArray(packageRes)
        ? packageRes
        : packageRes?.data ?? []
      const savedPermissions = packageData[0]?.permissions

      if (Array.isArray(savedPermissions)) {
        sub_items.value.forEach((item) => {
          const savedItem = savedPermissions.find((p) => p.id === item.id)
          if (!savedItem) return

          item.children.forEach((child) => {
            const savedChild = savedItem.children?.find(
              (c) => c.id === child.id,
            )
            if (savedChild) child.is_checked = !!savedChild.is_checked
          })
        })

        // Дээрх restore-оор Menus (id=1) доторх "Inventory"/"Shared sections"
        // check болсон бол тохирох additional_items бүлгийг sub_items-д нэмнэ
        const menusGroup = sub_items.value.find((i) => i.id === 1)
        menusGroup?.children.forEach((child) => {
          if (child.is_checked) syncAdditionalItem(child)
        })

        // Дээрх алхмаар шинээр нэмэгдсэн бүлгүүдийн (7, 8) children-ий
        // is_checked-ийг ч мөн saved permissions-ээс сэргээнэ (id байхгүй тул name-ээр match хийнэ)
        additional_items.value.forEach((group) => {
          const addedItem = sub_items.value.find((i) => i.id === group.id)
          const savedItem = savedPermissions.find((p) => p.id === group.id)
          if (!addedItem || !savedItem) return

          addedItem.children.forEach((child) => {
            const savedChild = savedItem.children?.find(
              (c) => c.name === child.name,
            )
            if (savedChild) child.is_checked = !!savedChild.is_checked
          })
        })
      }
    }

    openIndexes.value = sub_items.value.map((_, index) => index)

    // console.log('sub_items', sub_items)
  } catch (error) {
    console.error('Error parsing :', error)
  }
})

if (props.role) {
  console.log('Packagessssss', props)
}
</script>

<template>
  <div
    class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 w-[40%] border bg-white rolePanel"
  >
    <div class="rolePanel flex h-16 w-full items-center justify-between px-10">
      <BaseParagraph size="xs" class="text-muted-400">
        {{ t('Package') + ':' }}
        <b style="color: black">{{ props.role.name }}</b>
      </BaseParagraph>
      <button
        type="button"
        class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300 dark:hover:text-white"
        @click="windowClose('bttn')"
      >
        <Icon name="feather:chevron-right" class="h-6 w-6" />
      </button>
    </div>

    <div
      class="slimscroll relative h-[calc(100%_-_64px)] w-full overflow-y-auto px-10 py-5"
    >
      <div>
        <div v-for="(item, index) in sub_items" :key="item.id" class="mb-3.5">
          <div class="flex" @click="toggleChildren(index)">
            <div style="cursor: pointer; color: gray; font-size: 13px">
              {{ t(item.name) }}
            </div>
            <div class="ml-2" style="cursor: pointer; color: gray">
              <Icon
                :name="
                  openIndexes.includes(index)
                    ? 'material-symbols:keyboard-arrow-down'
                    : 'material-symbols:keyboard-arrow-up'
                "
              />
            </div>
          </div>
          <div v-if="openIndexes.includes(index)" class="flex flex-col ml-12">
            <div
              v-for="child in item.children"
              :key="child.id ?? child.name"
              class="mb-1"
            >
              <BaseCheckbox
                v-model="child.is_checked"
                :label="child.name ? t(child.name) : t(child.title)"
                :model-value="child.is_checked || false"
                :disabled="props.readonly"
                @update:model-value="(val) => onChildCheck(item, child, val)"
                rounded="none"
                color="success"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.status_item .nui-listbox .nui-listbox-option {
  padding: 0px !important;
}
</style>
