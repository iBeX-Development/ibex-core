<template>
  <v-autocomplete
    :label="''"
    :items="options"
    variant="solo"
    :name="name"
    :multiple="multiline"
    v-model="value"
    :item-title="(item) => item.name"
    :item-value="(item) => item.id"
  ></v-autocomplete>
</template>

<script setup>
import { onMounted } from 'vue'
const { getItems } = useDirectusItems()
const { getUsers } = useDirectusUsers()
const myCompanyId = getMyCompanyId()

const props = defineProps({
  context: Object,
})

const value = computed({
  get: () => {
    return props.context?._value
  },
  set: (value) => {
    props.context?.node.input(value)
  },
})

const label = props.context?.label
const name = props.context?.name
const collection_name = props.context?.collection_name
const multiline = props.context?.multiline
const filter = props.context?.filter || {}
const options = ref([])

onMounted(async () => {
  if (collection_name !== 'directus_users') {
    const items = await getItems({
      collection: collection_name,
      params: {
        ...filter,
        company_id: myCompanyId,
      },
    })
    console.log('AC', items)
    options.value = items
  } else {
    const items = await getUsers()
    console.log(items)
    options.value = transformUser(items)
  }
})

const transformUser = (items) => {
  console.log(items)
  const transformed_users = items.map((item) => ({
    name: item.first_name + ' ' + item.last_name,
    id: item.id,
  }))
  return transformed_users
}
</script>

<style>
/* Custom CSS for vue-select */
/* .light .style-chooser .vs__searchable::placeholder,
.light .style-chooser .vs__dropdown-toggle,
.light .style-chooser .vs__dropdown-menu {
  background: #dfe5fb;
  border: none;
  color: #394066;
}

.light .style-chooser svg.vs__open-indicator > path,
.light .style-chooser .vs__clear svg > path {
  fill: #394066;
} */

.dark .style-chooser .vs__search::placeholder,
.dark .style-chooser .vs__dropdown-toggle,
.dark .style-chooser .vs__dropdown-menu {
  background: #101729;
  color: white;
}

.dark .style-chooser svg.vs__open-indicator > path,
.dark .style-chooser .vs__clear svg > path {
  fill: white;
}
</style>
