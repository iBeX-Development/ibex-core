<template>
  <!-- New & Edit modal -->
  <TairoModal
    :key="props.key"
    :open="props.open"
    :size="props.size"
    :class="props.class"
    @close="close"
  >
    <template #header>
      <!-- Header -->
      <div class="flex w-full items-center justify-between p-2 md:p-2">
        <div class="flex items-center gap-2">
          <div
            v-if="props.icon"
            class="flex size-8 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-900/30"
          >
            <Icon :name="props.icon" class="size-4 text-primary-500" />
          </div>
          <div class="flex items-center gap-2">
            <h3
              class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-black"
            >
              {{ t(title) }}
            </h3>
          </div>
        </div>
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
            'saveUser justify-items-end text-sm px-10 mt-5 mb-10 py-3 is-button rounded bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
          ignore: false,
        }"
      >
        <div class="grid grid-cols-2 gap-4">
          <div v-if="avatarSchema.length">
            <FormKitSchema :schema="avatarSchema" />
          </div>
          <div class="flex flex-col gap-2">
            <div v-if="countsSchema.length" class="flex gap-2 counts_input">
              <FormKitSchema :schema="countsSchema" />
            </div>
            <div
              v-if="topRowSchema.length"
              class="flex flex-col gap-2 email_input"
            >
              <FormKitSchema :schema="topRowSchema" />
            </div>
          </div>
        </div>
        <div :class="props.schema_column">
          <FormKitSchema :schema="schema" />
        </div>
      </FormKit>
    </div>
  </TairoModal>
</template>

<script setup lang="ts">
console.log('UserModalForm drawing')
import { FormKitSchema } from '@formkit/vue'
import { useI18n } from 'vue-i18n'
import { ref } from 'vue'

const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const topRowSchema = ref([])
const countsSchema = ref([])
const avatarSchema = ref([])
let fileId = ref(-1)
let thumbnailUrl = ref(-1)

const loc_items = ref([])
const { token } = useDirectusToken()
const route = useRoute()

const { createUsers, updateUser, deleteUsers, getUsers } = useDirectusUsers()
const { getThumbnail: img } = useDirectusFiles()
const config = useRuntimeConfig()

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
  icon: String,
  close: Function,
  refresh: Function,
  refresh_modal: Function,
  schema_column: String,
})

const fieldLabel = (field: string) => t(field.replace(/_/g, ' '))

function checkType(value) {
  if (Array.isArray(value)) {
    return 'array'
  } else if (typeof value === 'object' && value !== null) {
    return 'object'
  } else {
    return typeof value
  }
}

const clearItem = () => {
  thumbnailUrl = -1
  fileId = -1
}

const Thumbnail = (id) => {
  // `https://limble-api.horecasoft.mn/assets/${id}`
  thumbnailUrl = `${config.public.directus.url}assets/${id}`
  return thumbnailUrl
}

// Companies.active_user_cnt (хязгаар) болон одоогийн идэвхтэй хэрэглэгчийн тоог авах
const loadActiveUserCounts = async () => {
  const companyRes = await getItems({
    collection: 'Companies',
    params: {
      filter: { id: myCompanyId },
      fields: ['id', 'active_user_cnt'],
    },
  })
  const companyData = Array.isArray(companyRes)
    ? companyRes
    : companyRes?.data ?? []
  const activeUserLimit = Number(companyData[0]?.active_user_cnt) || 0

  const activeUsersRes = await getUsers({
    params: {
      filter: { company_id: { _eq: myCompanyId }, active: { _eq: 1 } },
      meta: 'filter_count',
      limit: 1,
      fields: ['id'],
    },
  })
  const nowActiveUserCnt = activeUsersRes?.meta?.filter_count ?? 0

  return { activeUserLimit, nowActiveUserCnt }
}

// Submit хийсний дараа active_user_cnt/current_active_user-г дахин
// шинэчлэн зөв тоогоор харуулах болгоор reset хийнэ
const refreshActiveUserCounts = async () => {
  try {
    const { activeUserLimit, nowActiveUserCnt } = await loadActiveUserCounts()

    countsSchema.value = countsSchema.value.map((field) => {
      if (field.name === 'active_user_cnt') {
        return { ...field, value: String(activeUserLimit) }
      }
      if (field.name === 'current_active_user') {
        return { ...field, value: String(nowActiveUserCnt) }
      }
      return field
    })
  } catch (error) {
    console.error('Unable to refresh active user counts:', error)
  }
}

const fetchData = async () => {
  try {
    fileId = props.rowItems.avatar ? props.rowItems.avatar : 'undefined'
    if (fileId != 'undefined') {
      thumbnailUrl = Thumbnail(fileId)
    } else fileId = -1

    // Companies.active_user_cnt (хязгаар) болон одоогийн идэвхтэй хэрэглэгчийн
    // тоог зөвхөн харуулах зорилгоор (readonly) авах
    const companyRes = await getItems({
      collection: 'Companies',
      params: {
        filter: { id: myCompanyId },
        fields: ['id', 'active_user_cnt'],
      },
    })
    const companyData = Array.isArray(companyRes)
      ? companyRes
      : companyRes?.data ?? []
    const activeUserLimit = Number(companyData[0]?.active_user_cnt) || 0

    const activeUsersRes = await getUsers({
      params: {
        filter: { company_id: { _eq: myCompanyId }, active: { _eq: 1 } },
        meta: 'filter_count',
        limit: 1,
        fields: ['id'],
      },
    })
    const nowActiveUserCnt = activeUsersRes?.meta?.filter_count ?? 0

    let directusFields = [
      {
        field: 'active_user_cnt',
        type: 'string',
        required: false,
        readonly: true,
        label: t('active users'),
        value: String(activeUserLimit),
      },
      {
        field: 'current_active_user',
        type: 'string',
        required: false,
        readonly: true,
        value: String(nowActiveUserCnt),
      },
      {
        field: 'email',
        type: 'string',
        required: true,
        class: 'email_input',
        id: 'id_email_input',
        value: props.rowItems.email ? props.rowItems.email : '',
      },
      {
        field: 'first_name',
        type: 'string',
        required: true,
        value: props.rowItems.first_name ? props.rowItems.first_name : '',
      },
      {
        field: 'last_name',
        type: 'string',
        required: true,
        value: props.rowItems.last_name ? props.rowItems.last_name : '',
      },
      // {
      //   field: 'location',
      //   type: 'string',
      //   required: false,
      //   value: props.rowItems.location ? props.rowItems.location : '',
      // },
      // {
      //   field: 'password',
      //   type: 'string',
      //   required: true,
      //   value: props.rowItems.password ? props.rowItems.password : '',
      // },

      //  {
      //   field: 'password',
      //   type: 'string',
      //   required: true,
      //   value: props.rowItems.password ? props.rowItems.password : '',
      // },

      {
        field: 'phone',
        type: 'string',
        required: true,
        value: props.rowItems.phone ? props.rowItems.phone : '',
      },
      {
        field: 'active',
        type: 'integer',
        required: false,
        options: ['active', 'inactive'],
        // options-ийн value нь 'active'/'inactive' STRING тул сонголтын утга нь
        // тэдгээртэй яг тохирч байх ёстой (0/1 өгвөл select зөв утгыг сонгож
        // чадахгүй, үргэлж эхний сонголт "Active" харагдах алдаа гарч байсан)
        value:
          props.task === 'edit'
            ? Number(props.rowItems.active) === 1
              ? 'active'
              : 'inactive'
            : 'active',
      },
    ]

    let directusFileField = [
      {
        $cmp: 'AvatarUpload',
        name: 'avatar',
        props: {
          code: 'users',
          field: 'avatar',
          height: '240px',
          width: '240px',
          xmargin: ' -224px 0px 0px -20px',
          result: [],
          id: fileId,
          fileUrl: thumbnailUrl,
          clearItem: clearItem,
        },
      },
    ]

    async function fetchLocation() {
      let filters = {
        status: '1',
        company_id: myCompanyId,
      }
      let all_location_option = {
        address: 'all',
        city_name: 'all',
        date_created: new Date().toISOString(),
        name: t('Choose location'),
        region: 'all',
        status: '1',
        id: 0,
        location_id: { id: null },
      }

      const _items = await getItems({
        collection: 'Location',
        params: {
          filter: filters,
          meta: 'filter_count',
          fields: ['*'],
          limit: -1,
        },
      })

      let locations = _items.data

      if (checkType(locations) === 'object') locations = [locations]
      locations = [all_location_option, ...locations]
      loc_items.value = locations

      const locationField = {
        field: 'location_id',
        type: 'autocomplete2',
        required: true,
        value:
          props.task === 'edit' ? props.rowItems.location_id || null : null,
        collection_name: 'Location',
        item_value: 'id',
        item_title: 'name',
        initial_filter: filters,
        search_field: 'name',
        label: t('location'),

        // placeholder: t('Choose location'),
      }

      directusFields.push(locationField)
    }
    await fetchLocation()

    async function fetchRoles() {
      let roleUrl = `${runtimeConfig.public.directus.url}roles?filter[company_id][_eq]=${myCompanyId}`
      // if(props.rowItems.role) roleUrl =roleUrl+'/'+props.rowItems.role

      const response = await fetch(roleUrl, {
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token.value}`,
        },
      })

      let jsonData = await response.json()
      let roles = jsonData.data

      console.log('roles', roles)

      if (checkType(roles) === 'object') roles = [roles]

      const currentRoleId =
        props.rowItems.role?.id ?? props.rowItems.role ?? null

      const roleField = {
        field: 'role',
        type: 'autocomplete2',
        required: true,
        value:
          props.task === 'edit'
            ? roles.find((role) => role.id === currentRoleId) ??
              (typeof props.rowItems.role === 'object'
                ? props.rowItems.role
                : null)
            : null,
        collection_name: 'roles',
        item_value: 'id',
        item_title: 'name',
        search_field: 'name',
        label: t('role'),

        // placeholder: t('Choose role'),
      }

      directusFields.push(roleField)
    }
    await fetchRoles()

    if (myCompanyId === '1') {
      directusFields.push({
        field: 'company_id',
        type: 'autocomplete2',
        required: true,
        collection_name: 'Companies',
        item_value: 'id',
        item_title: 'name',
        initial_filter: { status: 1 },
        search_field: 'name',
        value:
          props.rowItems.company_id?.id || props.rowItems.company_id || null,
      })
    }

    if (props.task === 'add') {
      const passwordField = {
        field: 'password',
        type: 'string',
        required: true,
        class: 'pass_input',
        value: props.rowItems.password ? props.rowItems.password : '',
      }
      directusFields.push(passwordField)
    }

    // Convert Directus fields to FormKit schema
    const buildFormKitField = (field) => {
      let formKitField = {
        $formkit: 'text', // Default type is 'text'
        name: field.field,
        value: field.value,
        label: field.label || fieldLabel(field.field),
        validation: field.required ? 'required' : '',
      }
      if (field.readonly) {
        formKitField.disabled = true
        formKitField.ignore = true
      }
      if (['active_user_cnt', 'current_active_user'].includes(field.field)) {
        formKitField.outerClass = 'max-w-[140px]'
        formKitField.inputClass =
          'text-green-600 dark:text-green-400 border-green-400 font-semibold'
      }
      if (field.type === 'integer' && field.options) {
        formKitField.$formkit = 'select'
        formKitField.options = field.options.map((option) => ({
          value: option,
          label: t(option.charAt(0).toUpperCase() + option.slice(1)),
        }))
      } else if (field.type === 'uuid' && field.options) {
        formKitField.$formkit = 'select'
        formKitField.options = field.options.map((option) => ({
          value: option.value,
          label: option.label,
        }))
      } else if (field.type === 'autocomplete') {
        formKitField.$formkit = 'autocomplete'
        formKitField.collection_name = field.collection_name
        formKitField.filter = field.filter
      } else if (field.type === 'autocomplete2') {
        formKitField.$formkit = 'autocomplete2'
        formKitField.collection_name = field.collection_name
        formKitField.item_value = field.item_value
        formKitField.item_title = field.item_title
        formKitField.initial_filter = field.initial_filter
        formKitField.search_field = field.search_field
        formKitField.placeholder = field.placeholder
      }
      // else if (field.type === 'string' && field.field === 'password') {
      //   formKitField.$formkit = 'password';
      // }

      return formKitField
    }

    // Avatar-ийн ард харагдах талбарууд: тоолуурууд (green, нарийн, 1 мөрөнд)
    // болон email, password (тус тусдаа мөр, email-ийн доор password)
    const countsFieldNames = ['active_user_cnt', 'current_active_user']
    const topRowFieldNames = ['email', 'password']
    const countsFields = directusFields.filter((field) =>
      countsFieldNames.includes(field.field),
    )
    const topRowFields = directusFields.filter((field) =>
      topRowFieldNames.includes(field.field),
    )
    const restFields = directusFields.filter(
      (field) =>
        !countsFieldNames.includes(field.field) &&
        !topRowFieldNames.includes(field.field),
    )

    avatarSchema.value = directusFileField
    countsSchema.value = countsFields.map(buildFormKitField)
    topRowSchema.value = topRowFields.map(buildFormKitField)
    schema.value = restFields.map(buildFormKitField)
  } catch (error) {
    console.error('Error convert data:', error)
  }
}

const change_pass = () => {
  const directusFields = [{ field: 'password', type: 'string', required: true }]

  schema.value = directusFields.map((field) => {
    return {
      $formkit: 'text',
      name: field.field,
      label: fieldLabel(field.field),
      validation: field.required ? 'required' : '',
    }
  })
}
onMounted(() => {
  if (props.task === 'add' || props.task === 'edit') fetchData()
  else if (props.task === 'change_pass') change_pass()
})

// Company.active_user_cnt (багцын хязгаар) -оос давахгүй эсэхийг шалгах.
// Хязгаар тохируулаагүй (0/хоосон) бол шалгалтгүй өнгөрнө.
const checkActiveUserLimit = async () => {
  try {
    const companyRes = await getItems({
      collection: 'Companies',
      params: {
        filter: { id: myCompanyId },
        fields: ['id', 'active_user_cnt'],
      },
    })
    const companyData = Array.isArray(companyRes)
      ? companyRes
      : companyRes?.data ?? []
    const limit = Number(companyData[0]?.active_user_cnt)

    if (!limit) return true

    const usersRes = await getUsers({
      params: {
        filter: { company_id: { _eq: myCompanyId }, active: { _eq: 1 } },
        meta: 'filter_count',
        limit: 1,
        fields: ['id'],
      },
    })
    const activeCount = usersRes?.meta?.filter_count ?? 0

    if (activeCount >= limit) {
      toaster.clearAll()
      toaster.show({
        title: t('Limit reached'),
        message: t('Active user limit reached for this company'),
        color: 'danger',
        icon: 'ph:warning-circle-fill',
        closable: true,
      })
      return false
    }

    return true
  } catch (error) {
    console.error('Unable to verify active user limit:', error)
    return true
  }
}

const submitHandler = async (values) => {
  let items = [{ ...values, company_id: myCompanyId }]

  toaster.clearAll()
  const _fields = schema.value.filter((field, index) => {
    if (field.name === 'avatar' && field.props.result.length) {
      values['avatar'] = field.props.result[0].id
    }
  })

  if (checkType(values['role']) === 'array') {
    values['role'] = values['role'][0].id
  }

  if (checkType(values['location_id']) === 'array') {
    values['location_id'] = values['location_id'][0].id
  } else if (checkType(values['location_id']) === 'object') {
    values['location_id'] = values['location_id'].id
  }

  if (checkType(values['company_id']) === 'array') {
    values['company_id'] = values['company_id'][0].id
  } else if (checkType(values['company_id']) === 'object') {
    values['company_id'] = values['company_id'].id
  }

  // Root Company=1
  if (myCompanyId && myCompanyId !== 1) {
    values['company_id'] = myCompanyId
  }

  // console.log('loc_items.length', loc_items.value.length)

  if (loc_items.value.length) {
    values['location'] = loc_items.value.filter((item, index) => {
      if (values['location_id'] === 0) {
        item.id = null
        item.location_id = null
        values['location_id'] = null
        item.name = 'all'
        return item
      } else {
        return item.id === values['location_id']
      }
    })[0].name
  }

  if (props.task === 'add' || props.task === 'edit') {
    if (values['active'] === 'active' || values['active'] === 1)
      values['active'] = 1
    else values['active'] = 0
  }

  const wasActive = Number(props.rowItems?.active) === 1
  const willBeActive = Number(values['active']) === 1
  const isNewActivation =
    (props.task === 'add' || props.task === 'edit') &&
    willBeActive &&
    !wasActive

  if (isNewActivation && !(await checkActiveUserLimit())) {
    return
  }

  if (props.row === -1 && props.task === 'add') {
    try {
      // const user = await createUsers(values);
      // console.log('user --->>', user);

      const response = await fetch(
        runtimeConfig.public.directus.url + 'users',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token.value}`,
          },
          body: JSON.stringify(values),
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
          message: t(`Record created successfully`) + '!',
          color: 'success',
          icon: 'ph:user-circle-fill',
          closable: true,
        })
    } catch (error) {
      console.error('Error creating user:', error)
    }
  } else {
    //change_pass or edit
    const data = {
      collection: props.code,
      id: props.row,
      item: values,
    }

    const user = await updateUser({
      id: props.row,
      user: values,
    })

    let alert_msg = 'Record updated successfully'
    if (props.task === 'change_pass') alert_msg = 'Reset password successfully'

    toaster.show({
      title: t('Updated'),
      message: t(alert_msg) + '!',
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

  await refreshActiveUserCounts()

  props.close()
}
</script>
<style>
/* .userForm .two-column-form {
  display: grid;
  grid-template-columns: 180px minmax(0, 1fr);
  gap: 12px 20px;
  align-items: start;
}

.userForm .two-column-form > :first-child {
  grid-row: span 8;
}

.userForm .two-column-form .mb-1.max-w-md {
  width: 100%;
  max-width: none;
  margin-bottom: 0;
}

.userForm .two-column-form .vs__dropdown-toggle {
  min-height: 48px;
}

.userForm .two-column-form .vs__search,
.userForm .two-column-form .vs__selected {
  line-height: 46px;
} */

/* @media (max-width: 640px) {
  .userForm .two-column-form {
    grid-template-columns: 1fr;
  }

  .userForm .two-column-form > :first-child {
    grid-row: auto;
  }
} */

.userForm .mb-1.max-w-md {
  float: right;
}

/* .user-form .saveUser {
  float: right;
  position: relative;
  right: 0px;
} */
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
select[name='location_id'] option:first-child {
  color: red;
  font-weight: bold;
}
.email_input input,
.pass_input input {
  max-width: 290px;
  width: 290px;
}
.counts_input input {
  border-color: green !important;
}
</style>
