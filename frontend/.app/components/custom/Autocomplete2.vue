<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
const { getItems } = useDirectusItems()
const { getUsers } = useDirectusUsers()
const runtimeConfig = useRuntimeConfig()
const { token } = useDirectusToken()
const myCompanyId = getMyCompanyId()

const options = ref([])

const observer = ref<IntersectionObserver | null>(null)
const limit = ref(20)
const page = ref(1)
const search = ref('')
const hasNextPage = ref(false)

const load = ref()

// Properties my added variables
const props = defineProps({
  context: Object,
})

const collection_name = props.context?.collection_name
const item_value = props.context?.item_value
const item_title = props.context?.item_title
let item_fields = props.context?.item_fields
  ? props.context?.item_fields.split(',').map((item) => item.trim())
  : ['*']

let search_field = props.context?.search_field
let search_collection = props.context?.search_collection
let check_field = props.context?.check_field || 'qty'
const search_integer = props.context?.search_integer
const setValue = props.context?.setValue
const setEmplyValue = props.context?.setEmplyValue

const item_index = ref(props.context?.item_index || 0)
const setParentValue = props.context?.setParentValue
const initial_filter = props.context?.initial_filter
const originalInitialFilter = ref(props.context?.initial_filter || {}) // Анхны утгыг хадгална
const currentFilter = ref(originalInitialFilter.value) // Одоогийн шүүлт
const placeholder = props.context?.placeholder
const disabled = props.context?.disabled || false
const selectedItems = props.context?.selectedItems || []
const option_class = props.context?.option_class || ''
const label_extra = props.context?.label_extra || ''
const placement = props.context?.placement || 'bottom'

const initial_break = props.context?.initial_break
  ? props.context?.initial_break
  : false

const no_company_filter = props.context?.no_company_filter || false
const min_search_length = props.context?.min_search_length ?? 0

const value = computed({
  get: () => {
    return props.context?._value
  },
  set: (newValue) => {
    if (newValue == null && setEmplyValue) {
      newValue = setEmplyValue
    }

    if (newValue && typeof newValue === 'object' && check_field in newValue) {
      props.context?.node.input(newValue[check_field])
    } else {
      props.context?.node.input(newValue)
    }
  },
})

onMounted(async () => {
  observer.value = new IntersectionObserver(infiniteScroll)

  if (initial_break) return
  else await loadItems(false, 'onMounted')
})

async function infiniteScroll(entries: IntersectionObserverEntry[]) {
  const { isIntersecting, target } = entries[0]
  if (isIntersecting) {
    const scrollTop = (target as HTMLElement).offsetParent?.scrollTop
    if (hasNextPage.value == true) {
      page.value += 1
    }

    await loadItems(props.context?.change_filter, 'infiniteScroll')

    const ul = (target as HTMLElement).offsetParent

    if (ul) {
      ul.scrollTop = scrollTop ? scrollTop : 0
    }
  }
}

async function onOpen() {
  options.value = []
  page.value = 1
  if (props.context?.change_filter) {
    const changed_filter = props.context?.change_filter
    await loadItems(changed_filter, 'onOpen')
    if (load.value && observer.value) {
      observer.value.observe(load.value)
    }
  } else if (hasNextPage.value == true || search.value == '') {
    await loadItems(false, 'onOpen')
    if (load.value && observer.value) {
      observer.value.observe(load.value)
    }
  }
}

function onClose() {
  search.value = ''
  options.value = []
  observer.value?.disconnect()
}

const onSearch = (query) => {
  search.value = query
}

const getUniques = (listArray, searchCollection) => {
  const uniques = listArray.filter((value, index, self) => {
    if (value[searchCollection]) {
      return (
        index ===
        self.findIndex(
          (tt) => tt[searchCollection]?.id === value[searchCollection]?.id,
        )
      )
    }
  })
  return uniques
}
const loadItems = async (is_filtered = false, type = 'None') => {
  //load.value = true;
  try {
    if (collection_name === 'roles') {
      // let roles_filters = { company_id: myCompanyId }
      const response = await fetch(
        `${runtimeConfig.public.directus.url}roles?filter[company_id][_eq]=${myCompanyId}`,
        {
          headers: {
            Authorization: `Bearer ${token.value}`,
          },
        },
      )
      const result = await response.json()

      if (!response.ok || !Array.isArray(result.data)) {
        throw new Error('Unable to load roles')
      }

      const normalizedSearch = search.value.trim().toLowerCase()
      options.value = result.data.filter(
        (role) =>
          !normalizedSearch ||
          role.name?.toLowerCase().includes(normalizedSearch),
      )
      hasNextPage.value = false
      return
    }

    if (collection_name === 'users') {
      // directus_users нь system collection тул /items/... биш /users
      // эндпойнтоор дамждаг (roles-той адил зарчим)
      const params = new URLSearchParams()
      params.set(
        'filter',
        JSON.stringify({
          status: { _eq: 'active' },
          company_id: { _eq: myCompanyId },
        }),
      )
      params.set('fields', 'id,first_name,last_name')
      const response = await fetch(
        `${runtimeConfig.public.directus.url}users?${params.toString()}`,
        {
          headers: {
            Authorization: `Bearer ${token.value}`,
          },
        },
      )
      const result = await response.json()

      if (!response.ok || !Array.isArray(result.data)) {
        throw new Error('Unable to load users')
      }

      const normalizedSearch = search.value.trim().toLowerCase()
      const withFullName = result.data.map((u) => ({
        ...u,
        full_name: `${u.first_name || ''} ${u.last_name || ''}`.trim(),
      }))
      options.value = normalizedSearch
        ? withFullName.filter((u) =>
            u.full_name.toLowerCase().includes(normalizedSearch),
          )
        : withFullName
      hasNextPage.value = false
      return
    }

    let filters = no_company_filter
      ? { ...currentFilter.value }
      : { ...currentFilter.value, company_id: myCompanyId } // Эхний шүүлт

    if (is_filtered) {
      filters = { ...is_filtered }
    }

    if (search.value.length) {
      // if (is_filtered) {
      //   filters = is_filtered
      // }

      if (search_field) {
        if (search_collection) {
          filters[search_collection] = {
            [search_field]: {
              _icontains: search.value.trim(),
            },
          }
        } else {
          filters[search_field] = {
            _icontains: search.value.trim(),
          }
        }
      }
    }

    const items = await getItems({
      collection: collection_name,
      params: {
        filter: filters,
        limit: limit.value,
        page: page.value,
        meta: 'filter_count',
        fields: item_fields,
      },
    })

    let itemsObj = items.data
    let total_count = items.meta?.filter_count

    if (items.data.length > 0 && items.data[0]?.[search_collection]) {
      let uniques = items.data
      if (search_collection) {
        uniques = getUniques(items.data, search_collection)

        itemsObj = uniques
          .map((item) => {
            if (item?.[search_collection]) {
              if (typeof item[search_collection][check_field] === 'object')
                return item[search_collection][check_field]
              else return item[search_collection]
            }
          })
          .filter((coll, index, self) => {
            return index === self.findIndex((p) => p.id === coll.id)
          })
      }

      if (total_count > uniques.length) {
        total_count = total_count - uniques.length
      }
    } else itemsObj = items.data

    if (type == 'onOpen' && is_filtered) {
      options.value = [...itemsObj]
    } else options.value = [...options.value, ...itemsObj]

    if (options.value.length !== 0) {
      hasNextPage.value = total_count > options.value.length ? true : false
    } else {
      hasNextPage.value = false
    }

    // if (hasNextPage.value == true) {
    //   page.value += 1 // Increment offset for next request
    // }
  } catch (e) {
    console.log('Error fetching data:', e)
  } finally {
    //load.value = false;
  }
}

watch(search, async (newSearch) => {
  if (newSearch && newSearch.length > min_search_length) {
    page.value = 1 // Reset offset for a new search
    options.value = [] // Clear previous options
    await loadItems(props.context?.change_filter, 'search')
  } else {
    options.value = [] // Clear options if search query is too short
  }
})

const changeCodec = async (newValue) => {
  // const formattedValue =
  //   newValue && typeof newValue === 'object' ? newValue.part_number : newValue

  if (newValue && setParentValue) {
    setParentValue(newValue)
  }

  if (setValue) {
    setValue(newValue, item_index)
  }
}
// End of my properties
</script>

<template>
  <section>
    <!-- :calculate-position="withPopper" -->
    <v-select-dropdown
      :class="`${$colorMode.value} ${option_class} style-chooser`"
      :options="options"
      :filterable="false"
      :append-to-body="true"
      @open="onOpen"
      @close="onClose"
      @search="(query: any) => onSearch(query)"
      v-model="value"
      :label="item_title"
      :value="item_value"
      @update:modelValue="changeCodec"
      :placeholder="placeholder"
      :disabled="disabled"
      :placement="placement"
    >
      <template #option="option">
        <template v-if="label_extra && option[label_extra]">
          <span class="text-xs font-mono text-primary-500"
            >#{{ option[label_extra] }}</span
          >
          <span class="ml-1">{{ option[item_title] }}</span>
        </template>
        <template v-else>{{ option[item_title] }}</template>
      </template>
      <template #selected-option="option">
        <template v-if="label_extra && option[label_extra]">
          <span class="text-xs font-mono text-primary-500"
            >#{{ option[label_extra] }}</span
          >
          <span class="ml-1">{{ option[item_title] }}</span>
        </template>
        <template v-else>{{ option[item_title] }}</template>
      </template>
      <template #list-footer>
        <li
          v-show="hasNextPage"
          ref="load"
          class="loader"
          style="height: 4px; padding: 0; margin: 0; list-style: none"
        />
      </template>
    </v-select-dropdown>
  </section>
</template>

<style scoped>
/* Custom CSS for vue-select */
.vs__search,
.vs__search:focus,
.light.style-chooser .vs__searchable::placeholder,
.light.style-chooser .vs__search::placeholder,
.light.style-chooser .vs__search,
.light.style-chooser .vs__dropdown-toggle,
.light.style-chooser .vs__dropdown-menu {
  background: #dfe5fb;
  border: none;
}
.light.style-chooser .vs__searchable::placeholder,
.light.style-chooser .vs__search::placeholder {
  color: #e1e0e0 !important;
  opacity: 1;
}
.vs__dropdown-menu {
  z-index: 9999 !important;
}

.light.style-chooser svg.vs__open-indicator > path,
.light.style-chooser .vs__clear svg > path {
  fill: #394066;
}

.dark.style-chooser .vs__search::placeholder,
.dark.style-chooser .vs__dropdown-toggle,
.dark.style-chooser .vs__dropdown-menu {
  background: #323232;
  color: #ffc66d;
}

.dark.style-chooser svg.vs__open-indicator > path,
.dark.style-chooser .vs__clear svg > path {
  fill: #629755;
}
</style>
