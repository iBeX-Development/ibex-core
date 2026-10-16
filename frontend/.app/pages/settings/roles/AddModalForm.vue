<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

const config = useRuntimeConfig()
const runtimeConfig = useRuntimeConfig()

const { deleteUsers } = useDirectusUsers()
const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const { token } = useDirectusToken()

// Scroll контейнерийг тодорхойлох ref
const rowsContainer = ref(null)
const type = ref('')
const editId = ref(false)
const role_name = ref('')
const description = ref('')

const isError = ref(false)
const success = ref(false)

const props = defineProps({
  open: Boolean,
  code: String,
  title: String,
  close: Function,
  refresh: Function,
  clear: Function,
  editRow: Object,
  row: Object,
})

const emits = defineEmits<{
  (event: 'reset'): void
}>()

const onSubmit = async () => {
  success.value = false
  let error = false
  let errorMsg = ''
  console.log('Submit хийх боломжтой!')

  let i_policies = {
    create: [
      {
        role: 'c92c2ac4-cc62-45b0-ae3c-f32aa7abb358',
        policy: {
          id: 'c92c2ac4-cc62-45b0-ae3c-f32aa7abb358',
          name: 'Simple',
        },
      },
      {
        role: 'abf8a154-5b1c-4a46-ac9c-7300570f4f17',
        policy: {
          id: 'abf8a154-5b1c-4a46-ac9c-7300570f4f17',
          name: 'Public',
        },
      },
    ],
    update: [],
    delete: [],
  }

  let items = {
    name: role_name.value,
    description: description.value,
    company_id: myCompanyId,
    // policies: i_policies,
  }

  if (props.editRow != null) {
    let url = `${runtimeConfig.public.directus.url}roles/${props.editRow.id}`
    const response = await fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.value}`,
      },
      body: JSON.stringify({
        name: role_name.value,
        description: description.value,
        company_id: myCompanyId,
        // policies: i_policies,
      }),
    })

    const result = await response.json()

    console.log('editRow_response', result)
    console.log('editRow_response', response)
    if (response.ok) {
      console.log('editRow_response', response)
    } else if (!response.ok) {
      toaster.show({
        title: t('Error'),
        message: t(`HTTP error! status: ${response.status}`),
        color: 'danger',
        closable: true,
      })
    }
  } else {
    let url =
      runtimeConfig.public.directus.url +
      'roles?filter[company_id][_eq]=' +
      myCompanyId
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.value}`,
      },
      body: JSON.stringify(items),
    })

    const result = await response.json()
    // console.log('add_response', response)
    if (response.statusText === 'OK') {
      console.log('OK', result)
      let url = `${runtimeConfig.public.directus.url}roles/${result.data.id}`

      if (window.location.hostname === 'smartgps.ibex.mn') {
        i_policies = {
          create: [
            {
              role: result.data.id,
              policy: {
                id: '0cc0daf3-8c1c-4261-b6dc-2c6398d00794',
                name: 'Simple',
              },
            },
            {
              role: result.data.id,
              policy: {
                id: '7e938c99-e48f-48aa-aa42-64326890102c',
                name: 'Public',
              },
            },
          ],
          update: [],
          delete: [],
        }
      } else {
        i_policies = {
          create: [
            {
              role: result.data.id,
              policy: {
                id: 'c92c2ac4-cc62-45b0-ae3c-f32aa7abb358',
                name: 'Simple',
              },
            },
            {
              role: result.data.id,
              policy: {
                id: 'abf8a154-5b1c-4a46-ac9c-7300570f4f17',
                name: 'Public',
              },
            },
          ],
          update: [],
          delete: [],
        }
      }

      const res = await fetch(url, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token.value}`,
        },
        body: JSON.stringify({ policies: i_policies }),
      })
      // console.log('res', res)
    } else {
      toaster.show({
        title: t('Error'),
        message: t(`HTTP error! status: ${response.status}`),
        color: 'danger',
        closable: true,
      })
    }
  }

  resetModal()
  toaster.clearAll()
  toaster.show({
    title: 'Success',
    message: `Record has been created`,
    color: 'success',
    icon: 'ph:check',
    closable: true,
  })
}

const resetModal = () => {
  role_name.value = ''
  description.value = ''
  success.value = false

  // Reset scroll position if needed
  if (rowsContainer.value) {
    rowsContainer.value.scrollTop = 0
  }

  // Close modal
  props.close()
  props.refresh()
}

onMounted(async () => {
  // console.log('props-edited', props)
  if (props.editRow) {
    role_name.value = props.editRow.name
    description.value = props.editRow.description
    editId.value = props.editRow.id
  }
})

if (props.editRow != null) {
  // console.log('props.==> ', props)
  role_name.value = props.editRow.name
  description.value = props.editRow.description
  editId.value = props.editRow.id
}
</script>

<template>
  <form
    action=""
    method="POST"
    @submit.prevent="onSubmit"
    class="mx-auto w-full"
  >
    <TairoModal :open="props.open" size="sm" @close="resetModal">
      <template #header>
        <!-- Header -->

        <div class="flex w-full items-center justify-between">
          <div class="flex items-center gap-2">
            <div
              class="flex size-8 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-900/30"
            >
              <Icon
                name="material-symbols:auto-mode-rounded"
                class="size-4 text-primary-500"
              />
            </div>
            <div class="flex items-center gap-2">
              <h3
                class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
              >
                {{ props.title }}
              </h3>
            </div>
          </div>
          <BaseButtonClose @click="resetModal" />
        </div>
      </template>

      <!-- Body -->
      <div class="rowsContainer grid mx-auto" ref="rowsContainer">
        <BaseInput
          v-model="role_name"
          :label="$t('Name')"
          rounded="md"
          style="width: 320px; border: 1px solid #cfcdcd"
          type="string"
        />
        <BaseTextarea
          v-model="description"
          contrast="default-contrast"
          size="sm"
          :label="$t('Description')"
          rounded="md"
          :placeholder="$t('Write a description')"
          color-focus
          style="width: 320px; border: 1px solid #cfcdcd"
        />
      </div>

      <!-- Modal Footer -->
      <div
        class="shadow-muted-300/30 dark:shadow-muted-800/30 flex items-center justify-end gap-2 m-[25px]"
      >
        <BaseButton type="reset" shape="rounded" @click="resetModal">
          <span>{{ $t('Close') }}</span>
        </BaseButton>
        <BaseButton
          type="submit"
          shape="rounded"
          color="primary"
          @click="
            () => {
              onSubmit()
            }
          "
        >
          <span>{{ $t('Save') }}</span>
        </BaseButton>
      </div>
    </TairoModal>
  </form>
</template>

<style>
.rowsContainer .templates,
.rowsContainer .options {
  margin-top: 10px;
}

.rowsContainer .templates .nui-radio {
  margin-bottom: 8px;
}
.rowsContainer .options {
  /* border-left: 1px solid gray; */
}
.rowsContainer .options .InputBox {
  width: 80%;
  margin: auto;
}

.rowsContainer .snackBox {
  width: 360px;
  border: 1px solid #cdd5e0;
  height: auto;
  min-height: 38px;
  max-height: 120px;
  overflow-y: auto;
  overflow-x: hidden;
  border-radius: 0.375rem;
  align-items: center;
  padding: 10px;
}
.rowsContainer .placeholder-leader {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}

.rowsContainer .placeholder-leader:empty::before {
  content: 'Team leader';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}

.rowsContainer .placeholder-members {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}
.rowsContainer .placeholder-members:empty::before {
  content: 'Team members';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}
.rowsContainer .snackBox .nui-snack {
  border: 1px solid #c1bebe;
}

.rowsContainer .snackBox .nui-button-close {
  height: 24px !important;
}

.team_description .nui-textarea-wrapper {
  width: 100%;
}
</style>
