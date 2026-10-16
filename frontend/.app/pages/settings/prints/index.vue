<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
import DeletionActiveModalForm from '~/components/form/DeletionActiveModalForm.vue'

// import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import AddModalForm from './AddModalForm.vue'
const { t } = useI18n({ useScope: 'global' })

definePageMeta({
  middleware: ['auth'],
  title: 'Prints tempates',
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

import { ref } from 'vue'

const { getItems, updateItem, updateItems } = useDirectusItems()
const config = useRuntimeConfig()
const myCompanyId = getMyCompanyId()

const runtimeConfig = useRuntimeConfig()
const itemsPerPage = ref(10)
const getTableHeaders = () => {
  return [
    { title: t('Name'), key: 'name', align: 'start', width: '30%' },
    { title: t('Created'), key: 'date_created', align: 'start', width: '30%' },
    { title: t('Activated'), key: 'active', align: 'start', width: '30%' },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)

const loadItems = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array = []
  sortBy.map((sort_object) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })
  loading.value = true
  try {
    const filters = { status: 'published', company_id: myCompanyId }
    const items = await getItems<any>({
      collection: 'Prints_tempates',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: ['*', 'uploaded.*'],
      },
    })
    serverItems.value = items.data

    const url_pdf = `${config.public.directus.url}assets/${items.data[0].uploaded.id}`
    console.log('url_pdf', url_pdf)

    totalItems.value = items.meta.filter_count
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

const do_download = (item) => {
  console.log('do_download : ', item)
  const file_path = `${config.public.directus.url}assets/${item.uploaded.id}`
  window.open(file_path)
}

const do_delete = (item) => {
  console.log('do_delete : ', item)
  selectedItem.value = item.id
  console.log(selectedItem.value)
  isModalConfirmOpen.value = true
}

const do_active = async (item) => {
  // console.log('do_active : ', item)
  const { token } = useDirectusToken()
  let url = runtimeConfig.public.directus.url + `items/Prints_tempates`

  const up_data = {
    query: { id: { _neq: item.id } }, // <-- filter rows
    data: { active: 0 }, // <-- set active to 0
  }

  const response = await fetch(url, {
    method: 'PATCH', // Use PATCH method for updates
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token.value}`,
    },
    body: JSON.stringify(up_data), // Convert data to JSON string
  })

  if (!response.ok) {
    const error = await response.json()
    console.error('Bulk update failed:', error)
  }

  // activate selected one
  await updateItem({
    collection: 'Prints_tempates',
    id: item.id,
    item: {
      active: 1,
    },
  })

  handleChangeKey()
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
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <!-- <div v-if="serverItems.length === 0">
      <BasePlaceholderPage
        title="No matching results or  Maybe you don't have permission to access this."
        subtitle="Try other search terms."
      >
        <template #image>
          <img
            class="block dark:hidden"
            src="/img/illustrations/placeholder-search-4.svg"
            alt="Placeholder image"
          />
          <img
            class="hidden dark:block"
            src="/img/illustrations/placeholder-search-4-dark.svg"
            alt="Placeholder image"
          />
        </template>
      </BasePlaceholderPage>
    </div> -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton @click="handleModalOpen">
          <Icon
            name="material-symbols:photo-prints-outline-sharp"
            class="-ms-1 h-4 w-4"
          />
          <span class="text-[11px]">{{ $t('Add template') }}</span>
        </BaseButton>
      </div>
      <!-- Grid -->
      <div class="col-span-12">
        <BaseInput
          v-model="search"
          icon="lucide:search"
          :placeholder="$t('Search')"
          :classes="{
            wrapper: 'w-full sm:w-auto Searching',
          }"
        />
        <v-data-table-server
          v-model:items-per-page="itemsPerPage"
          :key="key"
          :headers="getTableHeaders()"
          :items-length="totalItems"
          :items="serverItems"
          :loading="loading"
          :search="search"
          class="elevation-1 -z-50"
          item-value="name"
          :theme="$colorMode.value"
          @update:options="loadItems"
          :pageText="t('{0}-{1} of {2}', ['{0}', '{1}', '{2}'])"
          :items-per-page-options="[
            { value: 5, title: '5' },
            { value: 10, title: '10' },
            { value: 25, title: '25' },
            { value: 50, title: '50' },
            { value: 100, title: '100' },
            { value: -1, title: t('All') },
          ]"
          :items-per-page-text="t('Item per page')"
          :loading-text="t('loading')"
          :no-data-text="t('No records')"
        >
          <template v-slot:item.action="{ item }">
            <div class="">
              <BaseDropdown
                flavor="context"
                label="Dropdown"
                orientation="end"
                condensed
                shape="curved"
                class="absolute mt-[-18px]"
              >
                <div class="">
                  <BaseDropdownItem
                    :title="t('Download')"
                    :text="t('Download from list')"
                    @click="do_download(item)"
                  >
                    <template #start>
                      <Icon
                        name="bxs:down-arrow-circle"
                        class="me-2 block h-5 w-5"
                      />
                    </template>
                  </BaseDropdownItem>
                  <BaseDropdownDivider />

                  <BaseDropdownItem
                    :title="t('Active')"
                    :text="t('Actived from list')"
                    @click="do_active(item)"
                  >
                    <template #start>
                      <Icon
                        name="mynaui:select-multiple"
                        class="me-2 block h-5 w-5"
                      />
                    </template>
                  </BaseDropdownItem>
                  <BaseDropdownDivider />
                  <BaseDropdownItem
                    :title="t('Remove')"
                    :text="t('Remove from list')"
                    @click="do_delete(item)"
                  >
                    <template #start>
                      <Icon
                        name="ph:trash-duotone"
                        class="me-2 block h-5 w-5"
                      />
                    </template>
                  </BaseDropdownItem>
                </div>
              </BaseDropdown>
            </div>
          </template>
          <template v-slot:item.date_created="{ item }">
            <p class="text-xxs">{{ item.date_created?.split('T')[0] }}</p>
          </template>
        </v-data-table-server>
        <AddModalForm
          :key="selectedItem"
          title="Status"
          code="Status"
          :open="isModalOpen"
          :close="handleModalClose"
          :editRow="selectedItem"
          :refresh="handleChangeKey"
          :refresh_modal="handleChangeModalKey"
        />
        <DeletionActiveModalForm
          :key="selectedItem"
          code="Prints_tempates"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :row="selectedItem"
          :refresh="handleChangeKey"
          :clear="clearItem"
        />
      </div>
    </div>
  </div>
</template>
