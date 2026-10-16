<template>
  <!-- New & Edit modal -->
  <TairoModal
    :key="props.key"
    :open="props.open"
    :size="props.size"
    :title="props.title"
    :icon="props.icon"
    @close="close"
  >
    <template #header>
      <!-- Header -->

      <!-- Header -->
      <div class="flex w-full items-center justify-between">
        <div class="flex items-center gap-2">
          <div
            v-if="props.icon"
            class="flex size-8 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-900/30"
          >
            <Icon :name="props.icon" class="size-4 text-primary-500" />
          </div>
          <div class="flex items-center gap-2">
            <h3
              class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
            >
              {{ t(props.title) }}
            </h3>
          </div>
        </div>
        <BaseButtonClose @click="close" />
      </div>
    </template>

    <!-- Body -->
    <div :class="['mx-auto w-full px-10 max-h-[70vh] overflow-y-auto']">
      <FormKit
        type="form"
        :actions="true"
        :submit-label="t('Save')"
        @submit="submitHandler"
        :submit-attrs="{
          inputClass:
            'text-sm px-10 mt-5 mb-10 py-3 is-button rounded bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
          ignore: false,
          wrapperClass: 'submit flex justify-end',
        }"
      >
        <div :class="[props.schema_column, props.class]">
          <FormKitSchema v-if="isSchemaReady" :schema="schema" />
        </div>
      </FormKit>
    </div>
  </TairoModal>
</template>

<script setup>
import { FormKitSchema } from '@formkit/vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

import { ref } from 'vue'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
// Row-ийн бодит утга (edit горимд) ирэхээс өмнө FormKitSchema-г mount
// хийвэл select зэрэг талбарууд schema-ийн анхны (жишээ нь static default)
// утгаараа "царайлагдаад" үлддэг тул, schema бүрэн бэлэн болтол
// FormKitSchema-г огт render хийхгүй байхаар хамгаална.
const isSchemaReady = ref(false)
const { token } = useDirectusToken()
const route = useRoute()

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const toaster = useToaster()

const props = defineProps({
  open: Boolean,
  title: String,
  code: String,
  row: Number,
  size: String,
  filters: Object,
  close: Function,
  refresh: Function,
  refresh_modal: Function,
  schema_column: String,
  class: String,
  icon: String,
  schema_order: Array,
  fields: Array,
  create: Function,
})

const translateSchemaField = (field) => ({
  ...field,
  label: field.label ? t(field.label) : '',
  help: field.help ? t(field.help) : '',
  options: Array.isArray(field.options)
    ? field.options.map((option) =>
        typeof option === 'object'
          ? { ...option, label: t(option.label) }
          : option,
      )
    : field.options,
})

// console.log(props)
const convertFieldsToFormKitSchema = (fields) => {
  return (
    fields?.map((field) => {
      const schemaField = {
        $formkit: field.type || 'text',
        label: field.label,
        name: field.name,
        help: field.help || '',
      }

      if (field.required) {
        schemaField.validation = 'required'
      }

      if (field.type === 'number') {
        schemaField.step = field.step || '1'
      }

      if (field.options) {
        schemaField.options = field.options
      }

      if (field.value !== undefined) {
        schemaField.value = field.value
      }

      // schema_column-ийн grid дотор тухайн field-ийг хэдэн баганад
      // харуулахаа тохируулах (ж: "col-span-2" бүтэн мөр эзлүүлнэ)
      if (field.class) {
        schemaField.outerClass = field.class
      }

      return translateSchemaField(schemaField)
    }) || []
  )
}

const fetchData = async () => {
  isSchemaReady.value = false
  try {
    let jsonData = []

    // Use provided fields or fetch from API
    if (props.fields && props.fields.length > 0) {
      jsonData = convertFieldsToFormKitSchema(props.fields)
    } else {
      let url =
        runtimeConfig.public.directus.url +
        `db/new/?code=${props.code}` +
        (props.filters ? `&filter=${JSON.stringify(props.filters)}` : '')

      if (props.row) {
        url = url + '&row=' + props.row
      }
      // console.log(url)
      const response = await fetch(url, {
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token.value}`,
        },
      })

      jsonData = await response.json()
      console.log('jsonData', jsonData)

      if (props.schema_order?.length) {
        // Define the schema order (1-based indexing)
        const orderedSchemas = props.schema_order.map(
          (index) => jsonData[index - 1],
        )
        jsonData = orderedSchemas
      }

      if (props.code === 'Location') {
        // const regionsResponse = await fetch(
        //   `${runtimeConfig.public.directus.url}items/Region?filter[status][_eq]=1&fields=id,name&sort=id`,
        //   {
        //     headers: {
        //       Authorization: `Bearer ${token.value}`,
        //     },
        //   },
        // )
        // const regionsResult = await regionsResponse.json()
        // const activeRegions =
        //   regionsResponse.ok && Array.isArray(regionsResult.data)
        //     ? regionsResult.data
        //     : []

        // if (!regionsResponse.ok) {
        //   console.error('Unable to load active regions:', regionsResult)
        // }

        jsonData = jsonData.map((field) => {
          const fieldName = field.name?.toLowerCase() || ''
          const isRegionField =
            fieldName.includes('region') ||
            field.label === 'Бүлэг' ||
            field.label === 'Group'

          if (!isRegionField) return field

          return {
            ...field,
            filter: { status: 1 },
            no_company_filter: true,
          }
        })
      }
    }

    // If editing an existing row, fetch the row data to populate initial values
    if (props.row && props.row !== -1) {
      try {
        const rowUrl = `${runtimeConfig.public.directus.url}items/${props.code}/${props.row}`
        const rowResponse = await fetch(rowUrl, {
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token.value}`,
          },
        })
        const rowData = await rowResponse.json()
        const data = rowData.data || rowData

        // Merge row data into schema by setting initial values
        jsonData = jsonData.map((field) => {
          if (data[field.name] !== undefined) {
            return {
              ...field,
              value: data[field.name],
            }
          }
          return field
        })
      } catch (error) {
        console.warn('Error fetching row data for initial values:', error)
      }
    }

    schema.value = jsonData
      .filter((field) => field.name?.toLowerCase() !== 'company_id')
      .map((field) => {
        if (field.$formkit !== 'autocomplete') {
          return translateSchemaField(field)
        }

        return translateSchemaField({
          ...field,
          $formkit: 'autocomplete2',
          item_value: field.item_value || 'id',
          item_title: field.item_title || 'name',
          search_field: field.search_field || 'name',
          initial_filter: field.filter || field.initial_filter || {},
          placeholder: field.placeholder || t(`Choose ${field.label || ''}`),
        })
      })

    // console.log('jsonData', jsonData)
  } catch (error) {
    console.error('Error fetching data:', error)
  } finally {
    isSchemaReady.value = true
  }
}

onMounted(() => {
  fetchData()
})

const submitHandler = async (values) => {
  console.log(values)
  schema.value
    .filter((field) => field.$formkit === 'autocomplete2')
    .forEach((field) => {
      const value = values[field.name]
      if (Array.isArray(value)) {
        values[field.name] = value[0]?.id || value[0]
      } else if (value && typeof value === 'object') {
        values[field.name] = value.id
      }
    })

  values['active'] = 1
  //do something with the form data
  // let items = [values]

  let items = [{ ...values, company_id: myCompanyId }]

  toaster.clearAll()
  // Teams change
  if (props.code !== 'team') {
    if (props.row === -1) {
      if (props.create) {
        await props.create(values)
      } else {
        await createItems({ collection: props.code, items })
      }
      toaster.show({
        title: t('Added'),
        message: t(`Record created successfully`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
    } else {
      const data = {
        collection: props.code,
        id: props.row,
        item: values,
      }
      await updateItem(data)

      toaster.show({
        title: t('Updated'),
        message: t(`Record updated successfully`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
    }
  } else {
    if (props.row === -1) {
      items = {
        users: {
          create: [],
        },
      }
      items['name'] = values['name']
      items['company_id'] = myCompanyId
      values['users'].map((id) => {
        items['users']['create'].push({
          Teams_id: '+',
          directus_users_id: {
            id: id,
          },
        })
      })
      await createItems({ collection: props.code, items })
      toaster.show({
        title: t('Added'),
        message: t(`Record created successfully`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
    } else {
      items = {
        users: {
          create: [],
        },
      }
      items['name'] = values['name']
      values['users'].map((id) => {
        items['users']['create'].push({
          Teams_id: props.row,
          directus_users_id: {
            id: id,
          },
        })
      })
      deleteItems({
        collection: 'Teams_directus_users',
        items: {
          query: {
            filter: {
              Teams_id: props.row,
            },
          },
        },
      }).then(() => {
        const data = {
          collection: props.code,
          id: props.row,
          item: items,
        }

        updateItem(data)
        if (props.refresh) {
          console.log('Props refresh 1...')
          props.refresh()
        }

        if (props.refresh_modal) {
          console.log('Modal refresh 1...')
          props.refresh_modal()
        }
      })

      toaster.show({
        title: t('Updated'),
        message: t(`Record updated successfully`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
      })
    }
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
.four-column-form {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  grid-column-gap: 20px; /* Adjust as needed */
}

.v-overlay {
  z-index: 10001 !important;
}
.mb-1.max-w-md:has(.submit) {
  width: 100%;
  max-width: 100%;
  /* right: 22px; */
  position: relative;
}
</style>
