<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'

const user = useDirectusUser()
const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const props = defineProps({
  open: Boolean,
  close: Function,
  setItem: Function,
  location: String,
  title: String,
  size: String || 'xl',
  header: Array,
  class: String,
  filter: Object,
  collection: String,
  fields: String,
  useslot: Array,
})

const itemsPerPage = ref(10)
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const refreshKey = ref(0)

const getTableHeaders = () => {
  return props.header
}

const loadItems = async ({ page, itemsPerPage, sortBy }) => {
  let sort_array: string[] = []
  sortBy.map((sort_object) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })
  loading.value = true
  try {
    let item_fields = ['*']
    let item_slot = []
    let filters = { company_id: { _eq: myCompanyId } }

    if (props.filter) {
      filters = { ...filters, ...props.filter }
    }

    if (props.fields) {
      item_fields = props.fields.split(',').map((item) => item.trim())
    }

    // if (props.useslot) {
    //   item_slot = props.useslot.split(',').map((item) => item.trim())
    // }

    const items = await getItems({
      collection: props.collection || '',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        sort: sort_array,
        meta: 'filter_count',
        search: search.value,
        fields: item_fields,
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
    :size="props.size ? props.size : 'xl'"
    @close="close"
    :classes="{ wrapper: 'TairoModal' }"
  >
    <template #header>
      <div :class="['flex w-full items-center justify-between', props.class]">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
        >
          &nbsp;{{ props.title }}
        </h3>
        <BaseButtonClose @click="close()" />
      </div>
    </template>

    <div class="max-h-[580px] overflow-y-auto TairoModalBody">
      <BaseInput
        v-model="search"
        icon="lucide:search"
        :placeholder="$t('Search')"
        :classes="{ wrapper: `w-full sm:w-auto Search ${props.class}` }"
      />
      <v-data-table-server
        v-model:items-per-page="itemsPerPage"
        :key="refreshKey"
        :headers="getTableHeaders()"
        :items-length="totalItems"
        :items="serverItems"
        :loading="loading"
        :search="search"
        :class="`elevation-1 ${props.class}`"
        item-value="name"
        :theme="$colorMode.value"
        @update:options="loadItems"
        :pageText="t('{0}-{1} of {2}', ['{0}', '{1}', '{2}'])"
        :items-per-page-options="[5, 10, 25, 50, 100, -1]"
        :items-per-page-text="t('Item per page')"
        :loading-text="t('loading')"
        :no-data-text="t('No records')"
      >
        <template
          v-if="props.useslot && props.useslot.includes('children')"
          v-slot:item.children="{ item }"
        >
          <BaseTag
            v-for="tag in item.children"
            :key="tag.id"
            shape="rounded"
            color="warning"
            class="mr-5 my-1"
          >
            {{ tag.name }}
          </BaseTag>
        </template>

        <template
          v-if="props.useslot && props.useslot.includes('users')"
          v-slot:item.users="{ item }"
        >
          <div
            v-for="(user, ind) in item.users"
            :key="ind"
            shape="rounded"
            class="mr-5 my-1"
          >
            {{
              user?.directus_users_id?.first_name
                .toLowerCase()
                .replace(/^\w/, (c) => c.toUpperCase())
            }}
          </div>
        </template>

        <template v-slot:item.action="{ item }">
          <div>
            <BaseButton
              :class="`Choose`"
              @click="
                () => {
                  props.setItem(item)
                  close()
                }
              "
              >{{ t('Choose') }}</BaseButton
            >
          </div>
        </template>
      </v-data-table-server>
    </div>
  </TairoModal>
</template>
