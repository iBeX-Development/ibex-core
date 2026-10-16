<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'

const user = useDirectusUser()
const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()

const itemsPerPage = ref(25)
const getTableHeaders = () => {
  return [
    { title: t('Name'), key: 'name', align: 'start', width: '40%' },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const refreshKey = ref(0)

const props = defineProps({
  open: Boolean,
  close: Function,
  setSchedule: Function,
})

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
    const items = await getItems<any>({
      collection: 'Schedule',
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
</script>

<template>
  <TairoModal
    :open="props.open"
    :size="props.size"
    @close="close"
    :classes="{ wrapper: 'TairoModal' }"
  >
    <template #header>
      <!-- Header -->
      <div class="flex w-full items-center justify-between">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
        >
          &nbsp;{{ t('Schedule choose') }}
        </h3>

        <BaseButtonClose @click="close()" />
      </div>
    </template>

    <div class="relative">
      <!-- Grid -->
      <div class="grid grid-cols-12 gap-6 TairoModalBody">
        <!-- Header -->
        <div class="col-span-12">
          <BaseInput
            v-model="search"
            icon="lucide:search"
            :placeholder="$t('Search')"
            :classes="{
              wrapper: 'w-full sm:w-auto Search',
            }"
          />
          <v-data-table-server
            v-model:items-per-page="itemsPerPage"
            :key="refreshKey"
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
                <BaseButton
                  :class="`Choose`"
                  @click="
                    props.setSchedule(item)
                    close()
                  "
                  >{{ t('Choose') }}</BaseButton
                >
              </div>
            </template>
          </v-data-table-server>
        </div>
      </div>
    </div>
  </TairoModal>
</template>
