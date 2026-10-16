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
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white pl-8"
        >
          {{ t(title) }}
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
            'text-sm px-10 mt-5 mb-10 py-3 is-button rounded bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
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
import { FormKitSchema } from '@formkit/vue'
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

import { ref } from 'vue'
import TaskCheckbox from '~/components/global/TaskCheckbox.vue'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()

const { createItems, updateItem, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()

const props = defineProps({
  open: Boolean,
  title: String,
  code: String,
  row: Number,
  size: String,
  close: Function,
  refresh: Function,
  refresh_modal: Function,
  schema_column: String,
})

console.log(props)
const fetchData = async () => {
  try {
    console.log(token.value)
    let url = runtimeConfig.public.directus.url + `db/new/?code=${props.code}`
    if (props.row) {
      url = url + '&row=' + props.row
    }
    console.log(url)
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.value}`,
      },
    })
    const jsonData = await response.json()
    schema.value = jsonData
  } catch (error) {
    console.error('Error fetching data:', error)
  }
}

onMounted(() => {
  console.log(props)
  fetchData()
})

const submitHandler = async (values) => {
  console.log(values)
  values['active'] = 1
  //do something with the form data
  let items = [{ ...values, company_id: myCompanyId }]

  toaster.clearAll()
  // Teams change
  if (props.row === -1) {
    items = {
      users: {
        create: [],
      },
    }
    items['name'] = values['name']
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
</style>
