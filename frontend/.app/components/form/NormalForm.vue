<template>
  <!-- New & Edit modal -->
  <!-- Header -->
  <div class="flex w-full items-center justify-between p-2 md:p-2">
    <h3
      class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white pl-8"
    >
      {{ t(title) }}
    </h3>
  </div>

  <!-- Body -->
  <div class="mx-auto w-full px-10">
    <FormKit
      type="form"
      :actions="true"
      :submit-label="t('Save')"
      @submit="submitHandler"
      :submit-attrs="{
        inputClass:
          'text-sm px-10 mt-5 mb-10 py-3 is-button rounded bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
        ignore: false,
      }"
    >
      <div :class="props.schema_column">
        <FormKitSchema :schema="schema" />
      </div>
    </FormKit>
  </div>
</template>

<script setup>
import { FormKitSchema } from '@formkit/vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

import { ref } from 'vue'
import { useRouter } from 'vue-router'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()
const { createItems, updateItem, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()
const router = useRouter()

const props = defineProps({
  title: String,
  code: String,
  row: Number,
  schema_column: String,
  fields: String,
  location: Number,
  redirect: String,
})

console.log(props)
const fetchData = async () => {
  try {
    console.log('[NormalForm] Token:', token.value ? 'Present' : 'Missing')
    console.log(
      '[NormalForm] Runtime config URL:',
      runtimeConfig.public.directus.url,
    )

    let url = runtimeConfig.public.directus.url + `db/new/?code=${props.code}`
    if (props.fields) {
      url = url + '&fields=' + props.fields
    }
    if (props.row) {
      url = url + '&row=' + props.row
    }

    console.log('[NormalForm] Making request to:', url)
    console.log('[NormalForm] Current domain:', window.location.hostname)

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.value}`,
        Accept: 'application/json',
      },
      mode: 'cors', // Explicitly set CORS mode
      credentials: 'omit', // Don't send cookies for CORS requests
    })

    if (!response.ok) {
      console.error(
        '[NormalForm] HTTP Error:',
        response.status,
        response.statusText,
      )
      console.error(
        '[NormalForm] Response headers:',
        Object.fromEntries(response.headers.entries()),
      )
      throw new Error(`HTTP ${response.status}: ${response.statusText}`)
    }

    const jsonData = await response.json()
    console.log('[NormalForm] Data received:', jsonData)
    schema.value = jsonData
  } catch (error) {
    console.error('[NormalForm] Error fetching data:')
    console.error('- Error type:', error.constructor.name)
    console.error('- Error message:', error.message)
    console.error('- Full error:', error)

    // Show user-friendly error
    toaster.show({
      title: 'Connection Error',
      message:
        'Failed to load form data. Please check your connection or try again.',
      color: 'danger',
      icon: 'ph:warning-circle',
      closable: true,
    })
  }
}

onMounted(() => {
  console.log(props)
  fetchData()
})

const row = computed({
  get: () => {
    return props.row
  },
  set: (value) => {
    console.log(value)
    this.$emit('props.row', value)
  },
})

// watch(() => props.row, (newRow, oldRow) => {
//   /* ... */
//   console.log(newRow)
// })

const submitHandler = async (values) => {
  console.log(values)
  //do something with the form data
  let items = [{ ...values, company_id: myCompanyId }]
  if (props.location) {
    values.location = props.location
  }
  toaster.clearAll()
  const m2m_fields = schema.value.filter((field, index) => {
    // console.log(index, field)
    if (field.m2m) {
      return true
    }
  })

  if (!props.row || props.row === -1) {
    m2m_fields.map((field, index) => {
      let m2m_values = []
      if (values[field['name']] && values[field['name']].length > 0) {
        values[field['name']].map((val, index) => {
          let m2m_temp = {}
          m2m_temp[field['many_field']] = '+'
          m2m_temp[field['junction_field']] = val
          m2m_values.push(m2m_temp)
        })
      }
      // console.log(m2m_values)
      items[0][field['name']] = m2m_values
    })
    // console.log(items)
    createItems({ collection: props.code, items })
    toaster.show({
      title: t('Added'),
      message: t(`Record created successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
    if (props.redirect) {
      setTimeout(function () {
        router.push(props.redirect)
      }, 500)
    }
  } else {
    m2m_fields.map((field, index) => {
      let m2m_values = []
      if (values[field['name']] && values[field['name']].length > 0) {
        values[field['name']].map((val, index) => {
          let m2m_temp = {}
          m2m_temp[field['many_field']] = props.row
          m2m_temp[field['junction_field']] = val
          m2m_values.push(m2m_temp)
        })
      }
      // console.log(m2m_values)
      values[field['name']] = m2m_values
    })
    const data = {
      collection: props.code,
      id: props.row,
      item: values,
    }
    console.log(data)
    await updateItem(data)

    toaster.show({
      title: t('Updated'),
      message: t(`Record updated successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
    if (props.redirect) {
      setTimeout(function () {
        router.push(props.redirect)
      }, 500)
    }
  }
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
.four-column-form {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-column-gap: 20px; /* Adjust as needed */
}

.v-overlay {
  z-index: 10001 !important;
}
</style>
