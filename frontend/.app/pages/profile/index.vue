<script setup lang="ts">
import 'v-calendar/dist/style.css'
import '~/assets/css/vcalendar.css'
const user = useDirectusUser()
const config = useRuntimeConfig()

import { FormKitSchema } from '@formkit/vue'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
const { t } = useI18n({ useScope: 'global' })
const runtimeConfig = useRuntimeConfig()
const myCompanyId = getMyCompanyId()

const router = useRouter()
const schema = ref([])
let Uploads = []
let fileId = ref(-1)
let thumbnailUrl = ref('')

const { token } = useDirectusToken()
const route = useRoute()
const { getThumbnail: img } = useDirectusFiles()
const toaster = useToaster()
const { createUsers, deleteUsers } = useDirectusUsers()

const appPermissions = JSON.parse(
  window.localStorage.getItem('app_permissions') || '{}',
)
const isAdmin = !!appPermissions?.[1]?.includes('admin')

const profileFieldLabels = {
  email: 'Email',
  first_name: 'First name',
  last_name: 'Last name',
  location: 'Location',
  active: 'Active',
  role: 'Roles',
}

function checkType(value) {
  if (Array.isArray(value)) {
    return 'array'
  } else if (typeof value === 'object' && value !== null) {
    return 'object'
  } else {
    return typeof value
  }
}

const Thumbnail = (id) => {
  thumbnailUrl.value = `${config.public.directus.url}assets/${id}`
  return thumbnailUrl.value
}

const fetchData = async () => {
  try {
    fileId.value = user.value.avatar ? user.value.avatar : 'undefined'
    if (fileId.value != 'undefined') {
      Thumbnail(fileId.value)
    } else thumbnailUrl.value = ''

    let directusFields = [
      {
        field: 'phone',
        type: 'string',
        required: true,
        value: user.value.phone ? user.value.phone : '',
      },

      {
        field: 'first_name',
        type: 'string',
        required: true,
        value: user.value.first_name ? user.value.first_name : '',
      },
      {
        field: 'last_name',
        type: 'string',
        required: true,
        value: user.value.last_name ? user.value.last_name : '',
      },
      {
        field: 'email',
        type: 'string',
        required: true,
        value: user.value.email ? user.value.email : '',
      },
      {
        field: 'location',
        type: 'string',
        required: false,
        value: user.value.location ? user.value.location : '',
      },
    ]

    directusFields.push({
      field: 'active',
      type: 'integer',
      required: false,
      options: ['active', 'inactive'],
      value: user.value.active === 0 ? 0 : 1,
      readonly: !isAdmin,
    })

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
          result: Uploads,
          id: fileId.value,
          fileUrl: thumbnailUrl.value,
        },
      },
    ]

    async function fetchRoles() {
      let roleUrl =
        runtimeConfig.public.directus.url +
        'roles?filter[company_id][_eq]=' +
        myCompanyId
      // if(user.value.role) roleUrl =roleUrl+'/'+user.value.role

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
        value: user.value.role,
        options: roles.map((role) => ({
          value: role.id, // Assuming 'id' is the UUID of the role
          label: role.name, // Assuming 'name' is the display label of the role
        })),
        readonly: !isAdmin,
      }

      directusFields.push(roleField)
    }
    await fetchRoles()

    const formKitSchema = directusFields.map((field) => {
      let formKitField = {
        $formkit: 'text',
        name: field.field,
        value: field.value,
        label: t(profileFieldLabels[field.field] || field.field),
        validation: field.required ? 'required' : '',
        readonly: !!field.readonly,
      }
      if (field.type === 'integer' && field.options) {
        formKitField.$formkit = 'select'
        formKitField.options = field.options.map((option) => ({
          value: option.value,
          label: t(option.charAt(0).toUpperCase() + option.slice(1)),
        }))
      } else if (field.type === 'uuid' && field.options) {
        formKitField.$formkit = 'select'
        formKitField.options = field.options.map((option) => ({
          value: option.value,
          label: option.label,
        }))
      }
      return formKitField
    })
    schema.value = [...directusFileField, ...formKitSchema]
  } catch (error) {
    console.error('Error convert data:', error)
  }
}

const submitHandler = async (values) => {
  toaster.clearAll()

  schema.value.filter((field) => {
    if (field.name === 'avatar') {
      if (Uploads.length) {
        values['avatar'] = Uploads[0].id
      } else if (field.props.fileUrl) {
        values['avatar'] = field.props.id
        thumbnailUrl.value = field.props.fileUrl
        // console.log('Updated thumbnailUrl to: ', thumbnailUrl.value)
      } else {
        console.log(
          'File URL is missing, file may not have uploaded correctly.',
        )
      }
    }
  })

  if (checkType(values['role']) === 'array') {
    values['role'] = values['role'][0].id
  }

  // Admin bishd active/role talbaruud zөvhön readonly haragdana,
  // ямар ч тохиолдолд submit-с skip хийнэ
  if (!isAdmin) {
    delete values['active']
    delete values['role']
  }

  // console.log('Uploadssssss', Uploads)
  // console.log('value_', values)
  // console.log('user_123', user)

  try {
    // Scope the response projection to exactly the submitted fields so
    // Directus doesn't try to read back fields (e.g. active/role) the
    // current role can't read, which would fail the whole request.
    const fieldsParam = Object.keys(values).join(',')
    const response = await fetch(
      `${runtimeConfig.public.directus.url}users/${user.value.id}?fields=${fieldsParam}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token.value}`,
        },
        body: JSON.stringify(values),
      },
    )
    const result = await response.json()
    if (!response.ok) {
      throw new Error(result?.errors?.[0]?.message || 'Update failed')
    }
    router.push(`/`)
  } catch (error) {
    console.log('Error updateUser item:', error)
  }

  toaster.show({
    title: t('Updated'),
    message: t('Record updated successfully!'),
    color: 'success',
    icon: 'ph:user-circle-fill',
    closable: true,
  })
}

definePageMeta({
  middleware: ['auth'],
  title: 'Profile',
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

onMounted(() => {
  fetchData()
})
</script>
<template>
  <div class="relative">
    <!-- Avatar Preview -->
    <!-- <div class="avatar-preview mb-4 text-center">
      <img
        v-if="thumbnailUrl"
        :src="thumbnailUrl"
        alt="User Avatar"
        class="avatar-img"
      />
    </div> -->

    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6 profile">
      <div class="col-span-12"></div>

      <!-- Form -->
      <div class="col-span-12">
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
            <div class="two-column-form profileForm">
              <FormKitSchema :schema="schema" />
            </div>
          </FormKit>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
/* .avatar-img {
  //width: 150px;
  //height: 150px;
  //border-radius: 50%;
  //object-fit: cover;
  //display: inline-block;
} */

/* .profileForm .space-y-2 .bg-white {
  background-color: red;
} */
</style>
