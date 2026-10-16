<script setup lang="ts">
import 'assets/css/vcalendar.css'
import 'v-calendar/dist/style.css'
import { useI18n } from 'vue-i18n'

import { open_status_id } from '~/components/workorder/WorkOrderStatus'

definePageMeta({
  middleware: ['auth'],
  title: 'New request',
  showback: true,
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})

const { t } = useI18n({ useScope: 'global' })
const uploadedFile = ref()
const requestSent = ref(false)
const response = ref(null)
const requestForm = ref()
const { getItems, createItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()
const params = useRoute()
const router = useRouter()
let name = ''
let phone = ''
let assign_id = null
const user = useDirectusUser()
name = user?.value.first_name + ' ' + user?.value.last_name
phone = user?.value.phone
assign_id = user?.value.id
const myId = window.localStorage.getItem('myId')

const work_order_ids = ref([])
const work_order_name = ref('')

// Setup initial filter based on permissions
const permissions_users = JSON.parse(
  window.localStorage.getItem('location_permissions'),
)

const initial_filter = ref(
  permissions_users &&
    permissions_users[1] &&
    permissions_users[1].includes('admin')
    ? { status: 1, company_id: myCompanyId }
    : {
        status: 1,
        company_id: myCompanyId,
        id: {
          _in: Object.keys(permissions_users || {}),
        },
      },
)

// console.log('initial_filter', initial_filter.value)

const submitHandler = async (values) => {
  console.log('submitHandler', values)
  requestSent.value = true
  var due_date = new Date()
  due_date.setDate(due_date.getDate() + 1)
  let request_info = `
        The following was reported through a Work Request Portal.<br/>
        <b>Problem</b>: ${values.problem}<br/>
        <b>Requester</b>: ${values.name}, ${values.phone}<br/>
        ${values.details}
    `

  let pictureId: string | null = null
  if (values.file) {
    if (Array.isArray(values.file) && values.file.length > 0) {
      if (
        values.file[0] &&
        typeof values.file[0] === 'object' &&
        values.file[0].id
      ) {
        pictureId = values.file[0].id
      } else if (
        typeof values.file[0] === 'string' &&
        values.file[0].length > 10
      ) {
        // Only use if it looks like a valid UUID (not a filename or empty string)
        pictureId = values.file[0]
      }
    } else if (!Array.isArray(values.file)) {
      if (typeof values.file === 'object' && values.file.id) {
        pictureId = values.file.id
      } else if (typeof values.file === 'string' && values.file.length > 10) {
        // Only use if it looks like a valid UUID (not a filename or empty string)
        pictureId = values.file
      }
    }
  }
  console.log('pictureId_in_here', pictureId)

  //  if (uploadedFiles.value && uploadedFiles.value.length > 0) {
  //     const fileIds = uploadedFiles.value.map((file) => file.id)
  //     pictureId.file = uploadedFiles.value[uploadedFiles.value.length - 1].id
  //   }
  const workOrderPayload: any = {
    due: due_date,
    priority: 1,
    created_type: 'request',
    mode: 'web',
    wo_prefix: 'REQ',
    action_status: 1,
    type: 2, //group_type
    work_type: 4, //work_type
    status: 1,
    wo_status: open_status_id,
    name: values.title,
    history_description: values.details,
    location: values?.location?.id,
    request_user: values?.request_user,
    // wo_number: '',
    company_id: myCompanyId,
  }

  // file attach хийсэн үед л picture field илгээх, үгүй бол payload-д оруулахгүй
  if (pictureId) {
    workOrderPayload.picture = pictureId
  }

  try {
    const work_order = await createItems({
      collection: 'Work_order',
      items: [workOrderPayload],
    })

    console.log('work_order_set', work_order)
    response.value = work_order[0]

    // await updateItem({
    //   collection: 'Work_order',
    //   id: work_order[0]?.id,
    //   item: {
    //     wo_number: String(work_order[0]?.id),
    //   },
    // })

    // actions
    createItems({
      collection: 'Work_order_actions',
      items: {
        wo_id: work_order[0]?.id,
        first_user: myId,
        action_status: 1,
        type: 'request',
        company_id: myCompanyId,
      },
    })

    // Work_order_item
    createItems({
      collection: 'Work_order_item',
      items: [
        {
          status: 1,
          label: 'Label',
          workorder: work_order[0]?.id,
          name: 'Resolve problem',
          request_info: request_info,
          created_type: 'request_info',
          company_id: myCompanyId,
        },
      ],
    })

    if (values.file) {
      const fileItems: any = {
        status: '1',
        work_order: work_order[0]?.id,
        company_id: myCompanyId,
      }

      if (pictureId) {
        fileItems.file = pictureId
      }

      await createItems({ collection: 'Work_order_files', items: fileItems })
    }

    // router.push(`/workorder/request/list`)
    toaster.clearAll()
    toaster.show({
      title: 'Success',
      message: t('Your work request was successfully submitted'),
      color: 'success',
      icon: 'ph:check',
      closable: true,
    })
  } catch (err: any) {
    console.error('create work order error', err)
    requestSent.value = false
    toaster.clearAll()
    toaster.show({
      title: 'Error',
      message: err?.message || t('Failed to create work request'),
      color: 'danger',
      icon: 'ph:x',
      closable: true,
    })
  }
}

const handleReset = () => {
  if (requestForm.value && requestForm.value.reset) {
    requestForm.value.reset()
  }
  requestSent.value = false
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-6 requestForm">
        <BaseCard color="default" rounded="md" class="p-6 nui-bg-white">
          <FormKit
            ref="requestForm"
            v-if="!requestSent"
            type="form"
            :actions="true"
            submit-label="Save"
            @submit="submitHandler"
            :submit-attrs="{
              inputClass:
                'savebttn text-sm px-10 mt-5 py-3 is-button rounded bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
              ignore: false,
              wrapperClass: 'submit flex justify-end mt-5',
            }"
          >
            <div class="flex items-center w-full max-w-md mb-1 m-auto">
              <div class="w-full mr-3">
                <FormKit
                  name="location"
                  type="autocomplete2"
                  :label="`${t('Location')}`"
                  :validation="'required'"
                  collection_name="Location"
                  item_value="id"
                  item_title="name"
                  :initial_filter="initial_filter"
                  search_field="name"
                />
                <FormKit
                  name="title"
                  type="text"
                  :label="`${t('Title of work request')}`"
                  :validation="'required'"
                />
                <FormKit
                  name="details"
                  type="textarea"
                  validation="length:0,120"
                  cols="20"
                  rows="5"
                  :label="`${t('Work request details')}`"
                  :validation="'required'"
                  :classes="{
                    input:
                      'detailstextarea nui-bg-gray-100 dark:nui-bg-muted-800',
                    outer: 'detailstextareaouter',
                    label: 'detailstextarealabel',
                  }"
                />
                <FormKit
                  name="name"
                  type="text"
                  :label="`${t('Requester name')}`"
                  v-model="name"
                  readonly="readonly"
                />
                <FormKit
                  name="phone"
                  type="text"
                  :label="`${t('Phone number')}`"
                  v-model="phone"
                  :validation="'required'"
                />
                <FormKit
                  name="problem"
                  type="text"
                  :label="`${t('Where or what is having the problem?')}`"
                  :validation="'required'"
                />
                <FileUpload
                  :result="uploadedFile"
                  field="file"
                  :plus="false"
                  :multiple="false"
                  :imageH="'184px'"
                  :imageW="'184px'"
                  :style="'height: 184px; width: 184px;'"
                  :imgParentstyle="'height: 184px; width: 184px;margin:30px 50px 0px 90px;'"
                  :xstyle="'justify-content: flex-end;  margin: -13px -33px 0px -22px;'"
                  :buttonStyle="'display:flex;justify-content: center;  margin-top: 20px;'"
                />
                <FormKit
                  type="hidden"
                  name="request_user"
                  v-model="assign_id"
                />
              </div>
            </div>
          </FormKit>
          <BaseCard color="info" rounded="md" class="p-6" v-if="requestSent">
            <BaseHeading
              as="h4"
              size="lg"
              weight="semibold"
              class="text-muted-800 dark:text-white"
            >
              {{ t('Thank you') }}!!
            </BaseHeading>
            <br />
            <BaseHeading
              as="h4"
              size="sm"
              weight="semibold"
              lead="tight"
              class="text-muted-800 mb-2 dark:text-white"
            >
              {{ t('Task') }} #{{ response?.id }}
            </BaseHeading>

            <BaseParagraph size="sm" lead="tight" class="text-muted-400">
              <label>{{ t('Description') }}</label
              >&nbsp;: {{ response?.name }}
            </BaseParagraph>
            <BaseHeading
              as="h4"
              size="lg"
              weight="semibold"
              class="text-muted-500 dark:text-white"
            >
              {{ t('Your work request was successfully submitted') }}
            </BaseHeading>
            <br />
            <BaseButton
              class="self-center"
              color="primary"
              @click="handleReset"
              >{{ t('Submit another request') }}</BaseButton
            >
          </BaseCard>
        </BaseCard>
      </div>
    </div>
  </div>
</template>

<style>
.requestForm .mb-1.max-w-md {
  margin: auto;
}

.dark .requestForm .detailstextarea {
  background-color: #0f172a !important;
  color: white !important;
}
</style>
