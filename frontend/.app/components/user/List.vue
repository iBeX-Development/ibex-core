<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'

const user = useDirectusUser()
const { t } = useI18n({ useScope: 'global' })
const { getUsers } = useDirectusUsers()
const myCompanyId = getMyCompanyId()

const itemsPerPage = ref(10)
const getTableHeaders = () => {
  return [
    { title: t('First name'), key: 'first_name', align: 'start', width: '25%' },
    { title: t('Last name'), key: 'last_name', align: 'start', width: '25%' },
    { title: t('Email'), key: 'email', align: 'start', width: '30%' },
    { title: t('Action'), key: 'action', align: 'start', sortable: false },
  ]
}
const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)
const refreshKey = ref(0)

const props = withDefaults(
  defineProps<{
    open?: Boolean
    close?: Function
    setUser?: Function
    users?: Array
    title?: String
    text?: String
    searchInput?: Boolean
    chooseInput?: Boolean
  }>(),
  {
    open: true, // Boolean-ийн анхны утга
    close: () => {},
    setUser: () => {}, // Функцын анхны утга (хоосон функц)
    users: [],
    title: 'Assign user choose',
    text: '',
    searchInput: true,
    chooseInput: true,
  },
)

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

    if (props.users.length > 0) {
      filters.active = {
        _in: [0, 1],
      }
      filters.id = {
        _in: Array.isArray(props.users) ? props.users : [props.users],
      }
    }
    const items = await getUsers<any[]>({
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
    :size="'lg'"
    @close="close"
    :classes="{ wrapper: 'TairoModal' }"
  >
    <template #header>
      <div class="flex w-full items-center justify-between">
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
        v-if="props.searchInput"
        v-model="search"
        icon="lucide:search"
        :placeholder="$t('Search')"
        :classes="{ wrapper: 'w-full sm:w-auto Search' }"
      />
      <v-data-table-server
        v-model:items-per-page="itemsPerPage"
        :key="refreshKey"
        :headers="getTableHeaders()"
        :items-length="totalItems"
        :items="serverItems"
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
        <template v-slot:item.action="{ item }">
          <div v-if="props.chooseInput">
            <BaseButton
              :class="`Choose`"
              @click="
                () => {
                  props.setUser(item)
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
