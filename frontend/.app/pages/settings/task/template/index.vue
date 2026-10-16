<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import '~/assets/css/vcalendar.css'
import DeletionModalForm from '~/components/form/DeletionModalForm.vue'
const { t } = useI18n({ useScope: 'global' })

const router = useRouter()
const { params } = useRoute()

const props = defineProps({
  back: String,
})

definePageMeta({
  middleware: ['auth'],
  title: 'Work Order Templates',
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

const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const itemsPerPage = ref(20)
const getTableHeaders = () => {
  return [
    { title: t('Name'), key: 'name', align: 'start', width: '30%' },
    { title: t('Status'), key: 'status', align: 'start', width: '30%' },
    { title: t('Code'), key: 'code', align: 'start', width: '30%' },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const refreshKey = ref(0)

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
      status: 'published',
      active: 1,
      company_id: myCompanyId,
    }
    const items = await getItems<any>({
      collection: 'Template',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: ['*'],
      },
    })
    serverItems.value = items.data
    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {}
}
// Modal new & edit form
const isModalOpen = ref(false)
const isModalConfirmOpen = ref(false)
const isRemoveAccepted = ref(false)
const selectedItem = ref(null)
const itemsValue = ref(-1)
const key = ref(1)

const success = ref(false)
const fieldsWithErrors = computed(() => Object.keys(errors.value).length)
const toaster = useToaster()

const regions = ref([])
onMounted(async () => {
  const filters = {
    status: 'published',
    active: 1,
    company_id: myCompanyId,
  }
  const items = await getItems<any>({
    collection: 'Template',
    params: {
      filter: filters,
    },
  })
  regions.value = items
  console.log(regions.value)
})

const do_create_or_update = async (item) => {
  if (item) {
    router.push(`template/update/${item.id}`)
  } else {
    router.push('template/add')
  }
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  itemsValue.value = -1
  selectedItem.value = -1
}

const do_make = async (item, type) => {
  let active = 0

  if (type == 'do_delete') {
    console.log('item', item)

    const data = {
      collection: 'Template',
      id: item.id,
      item: { active: active, status: 'draft' },
    }

    await updateItem(data)
  }

  // refreshGrid()
  handleChangeKey()
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const clearItem = () => {
  selectedItem.value = -1
}
</script>

<template>
  <div class="relative templates">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <BaseButton @click="do_create_or_update()">
          <Icon
            name="material-symbols:video-template-outline-sharp"
            class="-ms-1 h-4 w-4"
          />
          <span class="text-[11px]">{{ $t('PM template add') }}</span>
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
          <template v-slot:item="{ item }">
            <tr class="temp_row">
              <td @click="do_create_or_update(item)">{{ item.name }}</td>
              <td @click="do_create_or_update(item)">{{ item.status }}</td>
              <td @click="do_create_or_update(item)">{{ item.code }}</td>
              <td>
                <div class="temp_action">
                  <BaseDropdown
                    flavor="context"
                    label="Dropdown"
                    orientation="right"
                    condensed
                    shape="curved"
                    class="absolute mt-[-18px]"
                  >
                    <div class="">
                      <BaseDropdownItem
                        :title="t('Edit')"
                        :text="t('Edit record')"
                        @click="do_create_or_update(item)"
                      >
                        <template #start>
                          <Icon
                            name="ph:pencil-line-fill"
                            class="me-2 block h-5 w-5"
                          />
                        </template>
                      </BaseDropdownItem>
                      <BaseDropdownDivider />
                      <BaseDropdownItem
                        :title="t('Remove')"
                        :text="t('Remove from list')"
                        @click="
                          () => {
                            isModalConfirmOpen = true
                            selectedItem = item.id
                            itemsValue = item
                          }
                        "
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
              </td>
            </tr>
          </template>
        </v-data-table-server>
        <DeletionModalForm
          :key="selectedItem"
          code="Template"
          actionType="do_delete"
          :open="isModalConfirmOpen"
          :close="handleModalConfirmClose"
          :row="selectedItem"
          :itemsValue="itemsValue"
          :refresh="handleChangeKey"
          :clear="clearItem"
          :do_make="do_make"
        />
      </div>
    </div>
  </div>
</template>
<style>
.templates .temp_row:hover {
  cursor: pointer;
  background-color: #f5f5f5;
}
</style>
