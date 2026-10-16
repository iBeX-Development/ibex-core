<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'

const user = useDirectusUser()
const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const itemsPerPage = ref(25)
const getTableHeaders = () => {
  return [
    { title: t('Name'), key: 'name', align: 'start', minWidth: '150px' },
    { title: t('Code'), key: 'asset_code', align: 'start', minWidth: '100px' },
    {
      title: t('Location'),
      key: 'location.name',
      align: 'start',
      minWidth: '120px',
    },
    {
      title: t('Child asset'),
      key: 'children',
      align: 'start',
      minWidth: '160px',
    },
    {
      title: t('Action'),
      key: 'action',
      align: 'start',
      sortable: false,
      minWidth: '80px',
    },
  ]
}
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const refreshKey = ref(0)
const selectedItems = ref([])

const props = defineProps({
  open: Boolean,
  close: Function,
  setAsset: Function,
  location: Number,
  locationName: String,
  multiple: {
    type: Boolean,
    default: false,
  },
})

const closeModal = () => {
  if (props.close) {
    props.close()
  }
}

const applySelected = () => {
  if (!selectedItems.value?.length || !props.setAsset) {
    return
  }

  if (props.multiple) {
    props.setAsset(selectedItems.value)
  } else {
    props.setAsset(selectedItems.value[0])
  }

  selectedItems.value = []
  closeModal()
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
      status: '1',
      company_id: { _eq: myCompanyId },
    }
    console.log('Props', props.location)
    if (props.location) {
      filters['location'] = props.location
    }
    const items = await getItems({
      collection: 'Assets',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: ['*', 'children.*', 'location.*', 'location.name'],
      },
    })
    serverItems.value = items.data
    totalItems.value = items.meta.filter_count
    loading.value = false
  } catch (e) {}
}
</script>

<template>
  <TairoModal
    :open="props.open"
    :style="{ padding: '20px', minWidth: '1000px' }"
    :size="'xl'"
    @close="closeModal"
    :classes="{ wrapper: 'TairoModal Assets' }"
  >
    <template #header>
      <div class="flex w-full items-center justify-between">
        <div class="flex items-center gap-2">
          <div
            class="flex size-8 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-900/30"
          >
            <Icon
              name="lucide:package-search"
              class="size-4 text-primary-500"
            />
          </div>
          <div>
            <div class="flex items-center gap-2">
              <h3
                class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
              >
                {{ props.multiple ? t('Select assets') : t('Select asset') }}
              </h3>
              <span
                v-if="props.locationName"
                class="inline-flex items-center gap-1 rounded-full bg-info-100 px-2 py-0.5 text-xs font-medium text-info-600 dark:bg-info-900/30 dark:text-info-400"
              >
                <Icon name="lucide:map-pin" class="size-3" />
                {{ props.locationName }}
              </span>
            </div>
            <p class="text-muted-500 mt-1 text-xs">
              {{ t('Choose asset from the list below') }}
            </p>
          </div>
        </div>
        <BaseButtonClose @click="closeModal" />
      </div>
    </template>

    <div class="TairoModalBody">
      <BaseInput
        v-model="search"
        icon="lucide:search"
        :placeholder="$t('Search')"
        :classes="{ wrapper: 'mb-3 w-full sm:w-auto Search' }"
      />
      <div class="max-h-[470px] overflow-y-auto">
        <v-data-table-server
          v-model="selectedItems"
          v-model:items-per-page="itemsPerPage"
          :key="refreshKey"
          :headers="getTableHeaders()"
          :items-length="totalItems"
          :items="serverItems"
          :show-select="props.multiple"
          return-object
          :loading="loading"
          :search="search"
          class="elevation-1"
          item-value="name"
          :theme="$colorMode.value"
          @update:options="loadItems"
          :pageText="t('{0}-{1} of {2}', ['{0}', '{1}', '{2}'])"
          :items-per-page-options="[5, 10, 25, 50, 100, -1]"
          :items-per-page-text="t('Item per page')"
          :loading-text="t('loading')"
          :no-data-text="t('No records')"
        >
          <template v-slot:item.children="{ item }">
            <div v-if="item.children?.length" class="flex flex-wrap gap-1 py-1">
              <template v-for="(tag, i) in item.children" :key="tag.id">
                <span
                  v-if="i < 3"
                  class="inline-flex items-center gap-1 rounded-full bg-warning-100 px-2 py-0.5 text-xs font-medium text-warning-700 dark:bg-warning-900/30 dark:text-warning-400"
                >
                  <span class="size-1.5 rounded-full bg-warning-500"></span>
                  {{ tag.name }}
                </span>
              </template>
              <span
                v-if="item.children.length > 3"
                class="inline-flex items-center rounded-full bg-muted-100 px-2 py-0.5 text-xs font-medium text-muted-500 dark:bg-muted-800 dark:text-muted-400"
              >
                +{{ item.children.length - 3 }}
              </span>
            </div>
            <span v-else class="text-muted-400 text-xs">—</span>
          </template>
          <template v-slot:item.action="{ item }">
            <div>
              <BaseButton
                :class="`Choose`"
                :disabled="props.multiple"
                @click="
                  () => {
                    if (props.setAsset) {
                      props.setAsset(item)
                    }
                    closeModal()
                  }
                "
                >{{ t('Choose') }}</BaseButton
              >
            </div>
          </template>
        </v-data-table-server>
      </div>

      <div
        class="mt-3 flex items-center justify-between border-t border-muted-200 pt-3 dark:border-muted-700"
      >
        <p class="text-muted-500 text-xs">
          {{ props.multiple ? selectedItems.length : 0 }} {{ t('selected') }}
        </p>
        <div class="flex items-center gap-2">
          <BaseButton @click="closeModal">{{ t('Cancel') }}</BaseButton>
          <BaseButton
            v-if="props.multiple"
            color="primary"
            :disabled="selectedItems.length === 0"
            @click="applySelected"
          >
            {{ t('Choose selected') }} ({{ selectedItems.length }})
          </BaseButton>
        </div>
      </div>
    </div>
  </TairoModal>
</template>

<style scoped>
.TairoModal.Assets .TairoModalBody {
  padding: 20px !important;
}
</style>
