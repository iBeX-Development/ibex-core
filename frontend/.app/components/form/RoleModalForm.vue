<template>
  <!-- New & Edit modal -->
  <TairoModal
    :key="props.key"
    :open="props.open"
    :size="props.size"
    @close="close"
  >
    <template #header>
      <!-- Header -->
      <div class="flex w-full items-center justify-between p-2 md:p-2">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-black pl-8"
        >
          Add role
        </h3>
        <BaseButtonClose @click="close" />
      </div>
    </template>

    <!-- Body -->
    <div class="mx-auto w-full px-10">
      <FormKit
        type="form"
        :actions="true"
        :submit-label="t('Save')"
        @submit="submitHandler"
        :submit-attrs="{
          inputClass:
            'text-sm px-10 mt-5 mb-10 py-3 is-button rounded bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-black hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
          ignore: false,
        }"
      >
        <div :class="props.schema_column">
          <FormKitSchema :schema="schema" />
        </div>
      </FormKit>
    </div>
  </TairoModal>
</template>

<script setup>
console.log('UserModalForm drawing')
import { FormKitSchema } from '@formkit/vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

import { ref } from 'vue'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
let fileId = ref(-1)
let thumbnailUrl = ref(-1)

const { token } = useDirectusToken()
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const route = useRoute()

const { createUsers, updateUser, deleteUsers } = useDirectusUsers()
const { getThumbnail: img } = useDirectusFiles()

const toaster = useToaster()

const props = defineProps({
  open: Boolean,
  title: String,
  code: String,
  task: String,
  path: {
    type: String,
    default: '',
  },
  row: Number,
  rowItems: Object,
  size: String,
  close: Function,
  refresh: Function,
  refresh_modal: Function,
  schema_column: String,
})

function checkType(value) {
  if (Array.isArray(value)) {
    return 'array'
  } else if (typeof value === 'object' && value !== null) {
    return 'object'
  } else {
    return typeof value
  }
}

const fetchData = async () => {
  try {
    let directusFields = []
    let locationUrl = runtimeConfig.public.directus.url + 'items/Location'
    let filters = {
      status: '1',
      company_id: { _eq: myCompanyId },
    }
    // const response = await fetch(locationUrl, {
    //   headers: {
    //     'Content-Type': 'application/json',
    //     Authorization: `Bearer ${token.value}`,
    //   },
    // })

    const response = await getItems({
      collection: 'Location',
      params: {
        filter: filters,
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    if (checkType(response.data) === 'object') locations = [locations]
    // console.log('directusFields response', response)

    const lo_Field = {
      field: 'location',
      type: 'uuid',
      required: true,
      value: response.data,
      options: response.data.map((location) => ({
        value: location,
        label: location.name,
      })),
    }

    directusFields.push(lo_Field)

    async function fetchRoles() {
      let roleUrl =
        runtimeConfig.public.directus.url +
        `roles?filter[company_id][_eq]=${myCompanyId}`

      const response = await fetch(roleUrl, {
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token.value}`,
        },
      })

      let { data: roles } = await response.json()

      if (checkType(roles) === 'object') roles = [roles]

      const roleField = {
        field: 'role',
        type: 'uuid',
        required: true,
        value: roles,
        options: roles.map((role) => ({
          value: role,
          label: role.name,
        })),
      }

      directusFields.push(roleField)
    }

    await fetchRoles()

    // Convert Directus fields to FormKit schema
    const formKitSchema = directusFields.map((field) => {
      let formKitField = {
        $formkit: 'text', // Default type is 'text'
        name: field.field,
        value: field.value,
        label: field.field.replace(/_/g, ' '),
        validation: field.required ? 'required' : '',
      }
      if (field.type === 'integer' && field.options) {
        formKitField.$formkit = 'select'
        formKitField.options = field.options.map((option) => ({
          value: option,
          label: option.charAt(0) + option.slice(1),
        }))
      } else if (field.type === 'uuid' && field.options) {
        formKitField.$formkit = 'select'
        formKitField.options = field.options.map((option) => ({
          value: option,
          label: option.label,
        }))
      }
      return formKitField
    })

    schema.value = formKitSchema
  } catch (error) {
    console.error('Error convert data:', error)
  }
}

onMounted(() => {
  fetchData()
})

const submitHandler = async (items) => {
  // let items = [values]

  toaster.clearAll()

  if (checkType(items['role']) === 'object') {
    items['role'] = items['role']['value']
  } else if (checkType(items['role']) === 'array') {
    items['role'] = items['role'][0]
  }

  if (checkType(items['location']) === 'object') {
    items['location'] = items['location']['value']
  } else if (checkType(items['location']) === 'array') {
    items['location'] = items['location'][0]
  }

  items['user_id'] = props.row
  items['company_id'] = myCompanyId

  try {
    const response = await fetch(
      runtimeConfig.public.directus.url + 'items/Users_perm',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token.value}`,
        },
        body: JSON.stringify(items),
      },
    )

    const res = await response.json()
    if (res.errors && res.errors.length > 0) {
      res.errors.forEach((error) => {
        toaster.show({
          title: t('Error'),
          message: t(error.message) + '!',
          color: 'Error',
          icon: 'ph:user-circle-fill',
          closable: true,
        })
      })
    } else
      toaster.show({
        title: t('Added'),
        message: t(`Record created`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
  } catch (error) {
    console.log('Error creating user:', error)
  }

  if (props.refresh) {
    console.log('Props refresh 2...')
    props.refresh()
  }

  if (props.refresh_modal) {
    console.log('Modal refresh 2...')
    props.refresh_modal()
  }

  props.close()
}
</script>
<style>
.two-column-form {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-column-gap: 20px; /* Adjust as needed */
}
.three-column-form {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-column-gap: 20px; /* Adjust as needed */
}
/* :is([class~='dark'] .nui-label) {
  color: #484747 !important;
}
:is([class~='dark'] .dark\:text-muted-200) {
  color: black !important;
} */
.v-overlay {
  z-index: 10001 !important;
}
</style>
