<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

import { useForm } from 'vee-validate'
import WarningModalForm from '~/components/form/WarningModalForm.vue'

const config = useRuntimeConfig()
const { deleteUsers } = useDirectusUsers()
const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const { token } = useDirectusToken()
const myCompanyId = getMyCompanyId()

const type = ref('')
const project_name = ref('')
const project_code = ref('')
const loading = ref(true)

const project_phone = ref('')
const project_mail = ref('')
const project_users = ref(1)
const project_rate = ref(1)
const project_rate_options = ref([1, 2, 3, 4, 5])

const description = ref('')
const project_status = ref('published')
let project_options = ref(['published', 'draft', 'archived'])

const category_status = ref(1)
let category_options = ref(['Mining', 'Software', 'Foods', 'Education'])

let imgId = ref(-1)
let UploadImg = []
let thumbnailUrl = ref('')

const isModalLeaderOpen = ref(false)
const isModalMemberOpen = ref(false)
const isModalTeamOpen = ref(false)
const isModalConfirmText = ref('')
const isModalConfirmOpen = ref(false)
const isError = ref(false)

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
const success = ref(false)
const rows = ref([
  {
    meeting: {
      title: '',
      type: '',
      position: '',
      colorCode: '',
    },
  },
])

// Scroll контейнерийг тодорхойлох ref
const projectContainer = ref(null)

// Modify initial values to handle dynamic rows
const initialValues = computed(() => ({
  module: props.editRow
    ? [
        {
          id: 1,
          name: 'Work order',
          text: 'Your location work order',
          icon: 'ph:buildings-duotone',
          module_key: 'work_order',
        },
      ]
    : '',
  rows: rows.value.map((row) => ({
    meeting: {
      title: row.meeting.title,
      position: row.meeting.position,
      type: row.meeting.type,
      colorCode: row.meeting.colorCode,
    },
  })),
}))

const {
  handleSubmit,
  isSubmitting,
  setFieldError,
  meta,
  values,
  errors,
  resetForm,
  setFieldValue,
  setErrors,
} = useForm({
  initialValues,
})

const emits = defineEmits<{
  (event: 'reset'): void
}>()

const onSubmit = handleSubmit(
  async (values) => {
    success.value = false
    let error = false
    let errorMsg = ''
    console.log('Submit хийх боломжтой!', values)
    // console.log('project_leaders!', project_leaders)

    if (!project_code.value || project_code.value == '') {
      error = true
      isModalConfirmText.value = 'Register is empty!'
    }
    if (!project_name.value || project_name.value == '') {
      error = true
      isModalConfirmText.value = 'Name is empty!'
    }
    if (!project_phone.value || project_phone.value == '') {
      error = true
      isModalConfirmText.value = 'Phone is empty!'
    }

    if (error == true) {
      isModalConfirmOpen.value = true
      return
    }

    let items = {
      name: project_name.value,
      register: project_code.value,
      description: description.value,
      category: category_status.value,
      phone: project_phone.value,
      email: project_mail.value,
      user_cnt: project_users.value,
      rate: project_rate.value,
      _image: UploadImg.length //ids
        ? UploadImg[0].id
        : imgId.value != -1
        ? imgId.value
        : null,
      company_id: myCompanyId,
    }
    // console.log('items', items)

    if (props.editRow != -1) {
      const res = await updateItem({
        collection: 'Contractors',
        id: props.editRow.id,
        item: items,
      })
      // console.log('res', res)
    } else {
      const res = await createItems({
        collection: 'Contractors',
        items: items,
      })
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
  },
  (error) => {
    // this callback is optional and called only if the form has errors
    success.value = false

    // here you have access to the error
    console.log('error2', error)

    // you can use it to scroll to the first error
    document.documentElement.scrollTo({
      top: 0,
      behavior: 'smooth',
    })
  },
)

const resetModal = () => {
  // Reset rows to initial state
  project_name.value = ''
  project_code.value = ''
  description.value = ''
  category_status.value = ''

  project_name.value = ''
  project_phone.value = ''
  project_mail.value = ''
  project_code.value = ''
  project_users.value = 1
  project_rate.value = 1

  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  imgId.value = -1
  UploadImg.value = []

  // Reset form
  resetForm()
  success.value = false
  setErrors({})

  // Reset scroll position if needed
  if (projectContainer.value) {
    projectContainer.value.scrollTop = 0
  }

  // Close modal
  props.close()
  props.refresh()
}

// 🔹 `computed()` ашиглаж, шууд тооцоолох
const Thumbnail = computed(() => {
  return imgId.value != -1
    ? `${config.public.directus.url}assets/${imgId.value}`
    : '/img/avatars/placeholder-file.png'
})

const handleUploaded = (newValue) => {
  console.log('done:)', newValue)
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  isError.value = false
}

const transformType = (items) => {
  // console.log(items)
  const transformed_types = items.map((item) => ({
    label: item.name,
    value: item.id,
  }))
  transformed_types.unshift({
    label: '',
    value: '',
  })
  return transformed_types
}

const loadTypes = async () => {
  try {
    const filters = {}
    const items = await getItems<any>({
      collection: 'Categories',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    category_options.value = transformType(items.data)
    loading.value = false
  } catch (e) {
    console.log(e)
  }
}

const get_content_url = (file, type) => {
  // console.log('file ->', file)

  if (type == 'avatar') {
    if (file && file.type.includes('image')) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else {
      return `/img/avatars/3.svg`
    }
  }

  if (type == 'project') {
    if (file && file.type.includes('image')) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else {
      return `/img/projects/15.jpg`
    }
  }

  if (type == 'leader') {
    if (file && file.type.includes('image')) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else {
      return `/img/avatars/1.svg`
    }
  }
}
onMounted(async () => {
  await loadTypes()
  // console.log('props-edited', props.editRow)

  if (props.editRow) {
    project_name.value = props.editRow.name
    project_phone.value = props.editRow.phone
    project_mail.value = props.editRow.email
    project_code.value = props.editRow.register
    project_users.value = props.editRow.user_cnt
    project_rate.value = props.editRow.rate
    description.value = props.editRow.description
    category_status.value = props.editRow.category

    // imgId.value = get_content_url(props.editRow._image, 'avatar')
    imgId.value = props.editRow._image?.id
  }
})
</script>

<template>
  <form
    action=""
    method="POST"
    @submit.prevent="onSubmit"
    class="mx-auto w-full max-w-3xl"
  >
    <TairoModal :open="props.open" size="2xl" @close="resetModal">
      <template #header>
        <!-- Header -->
        <div class="flex w-full items-center justify-between">
          <h3
            class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
          >
            {{ $t(props.title) }}
          </h3>

          <BaseButtonClose @click="resetModal" />
        </div>
      </template>

      <!-- Body -->
      <div
        class="projectContainer body h-[500px] grid mx-auto overflow-y-auto overflow-x-hidden"
        ref="projectContainer"
      >
        <div class="projectsBody w-[580px] mx-auto">
          <div class="project_about flex">
            <div>
              <BaseInput
                v-model="project_name"
                :label="$t('Name')"
                rounded="none"
                style="
                  width: 320px;
                  border: 1px solid #cbd5e1;
                  border-radius: 7px;
                "
                type="string"
              />
              <BaseInput
                v-model="project_code"
                :label="$t('Register')"
                rounded="none"
                style="
                  width: 320px;
                  border: 1px solid #cbd5e1;
                  border-radius: 7px;
                "
                type="string"
              />
              <div class="w-[320px]">
                <BaseListbox
                  :label="$t('Category')"
                  :items="category_options"
                  :model-value="category_status"
                  :properties="{
                    value: 'value',
                    label: 'label',
                  }"
                  size="md"
                  rounded="md"
                />
              </div>
              <div class="w-[320px]">
                <BaseListbox
                  :label="$t('Status')"
                  style="width: 320px"
                  v-model="project_status"
                  :items="project_options"
                  rounded="none"
                />
              </div>
            </div>

            <div
              class="LoginImg w-[250px] h-[260px] flex items-center justify-center"
            >
              <AvatarUpload
                code="users"
                field="login"
                height="210px"
                width="194px"
                :result="UploadImg"
                :id="imgId"
                xmargin="-208px 0px 0px -20px"
                :fileUrl="Thumbnail"
              />
            </div>
          </div>

          <div class="flex w-[544px]">
            <BaseInput
              v-model="project_phone"
              :label="$t('Phone')"
              rounded="none"
              style="
                width: 280px;
                border: 1px solid #cbd5e1;
                border-radius: 7px;
              "
              type="string"
            />
            <BaseInput
              v-model="project_mail"
              :label="$t('Email')"
              rounded="none"
              style="
                width: 260px;
                margin-left: 5px;
                border: 1px solid #cbd5e1;
                border-radius: 7px;
              "
              type="string"
            />
          </div>

          <div class="flex w-[544px]">
            <BaseInput
              v-model="project_users"
              :label="$t('Users count')"
              rounded="none"
              style="
                width: 280px;
                border: 1px solid #cbd5e1;
                border-radius: 7px;
              "
              type="string"
            />
            <BaseListbox
              :label="$t('Rate')"
              style="width: 280px; margin-left: 5px"
              v-model="project_rate"
              :items="project_rate_options"
              rounded="none"
            />
          </div>
          <div class="project_description w-[544px] flex">
            <BaseTextarea
              v-model="description"
              contrast="default-contrast"
              size="sm"
              :label="$t('Description')"
              rounded="md"
              :placeholder="$t('Write a description...')"
              color-focus
              style="border: 1px solid #cbd5e1; border-radius: 7px"
            />
          </div>
        </div>
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

      <WarningModalForm
        :text="$t(isModalConfirmText)"
        code="Status"
        :open="isModalConfirmOpen"
        :close="handleModalConfirmClose"
      />
    </TairoModal>
  </form>
</template>

<style>
.projectContainer .templates,
.projectContainer .options {
  margin-top: 10px;
}

.projectContainer .templates .nui-radio {
  margin-bottom: 8px;
}
.projectContainer .options {
  /* border-left: 1px solid gray; */
}
.projectContainer .options .InputBox {
  width: 80%;
  margin: auto;
}

.projectContainer .snackLeaderBox {
  width: 360px;
  border: 1px solid #cdd5e0;
  height: 38px;
  /* height: auto;
  min-height: 38px;
  max-height: 120px; */
  overflow-y: auto;
  overflow-x: hidden;
  border-radius: 0.375rem;
  align-items: flex-start;
  padding: 5px;
}
.projectContainer .snackMemberBox {
  width: 530px;
  border: 1px solid #cdd5e0;
  height: 38px;
  overflow-y: auto;
  overflow-x: hidden;
  border-radius: 0.375rem;
  align-items: flex-start;
  padding: 5px;
}
.projectContainer .snackTeamBox {
  width: 530px;
  border: 1px solid #cdd5e0;
  height: 38px;
  overflow-y: auto;
  overflow-x: hidden;
  border-radius: 0.375rem;
  align-items: flex-start;
  padding: 5px;
}
.projectContainer .placeholder-leader {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}

.projectContainer .placeholder-leader:empty::before {
  content: 'Project leader';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}

.projectContainer .placeholder-members {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}
.projectContainer .placeholder-members:empty::before {
  content: 'Project members';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}

.projectContainer .placeholder-teams {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}
.projectContainer .placeholder-teams:empty::before {
  content: 'Project teams';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}
.projectContainer .snackBox .nui-snack {
  border: 1px solid #c1bebe;
}

.projectContainer .snackBox .nui-button-close {
  height: 24px !important;
}

.project_description .nui-textarea-wrapper {
  width: 100%;
}
</style>
