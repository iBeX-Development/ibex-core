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
const myCompanyId = getMyCompanyId()

const { token } = useDirectusToken()

const type = ref('')
const news_name = ref('')
const content = ref('')

const imgId = ref(-1)
let UploadImg: any[] = []
const thumbnailUrl = ref('')
const news_options = ref(['published', 'draft', 'archived'])
const news_status = ref('published')

const isModalLeaderOpen = ref(false)
const isModalMemberOpen = ref(false)
const isModalConfirmText = ref('')
const isModalConfirmOpen = ref(false)
const isError = ref(false)

const props = defineProps({
  open: Boolean,
  code: String,
  title: String,
  icon: String,
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
const rowsContainer = ref<HTMLElement | null>(null)
// Modify initial values to handle dynamic rows
const initialValues = computed(() => ({
  module: props.editRow
    ? [
        {
          id: 1,
          title: 'Work order',
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
  // initialValues,
})

const emits = defineEmits<{
  (event: 'reset'): void
}>()

const onSubmit = handleSubmit(
  async (values) => {
    success.value = false
    let error = false
    let errorMsg = ''
    // console.log('Submit хийх боломжтой!', values)
    console.log('UploadImg!', UploadImg)

    // Prepare image data for one-to-many relationship through junction table
    let imageData = null
    if (UploadImg.length) {
      // New image uploaded
      imageData = [{ directus_files_id: UploadImg[0].id }]
    } else if (imgId.value != -1 && !props.editRow) {
      // Creating with existing image
      imageData = [{ directus_files_id: imgId.value }]
    }
    // For updates, if no new image, we don't send the image field to keep existing

    let items: any = {
      title: news_name.value,
      content: content.value,
      company_id: myCompanyId,
    }

    // Only add image field if there's new image data
    if (imageData) {
      items.image = imageData
    }

    if (props.editRow) {
      const res = await updateItem({
        collection: 'news',
        id: props.editRow.id,
        item: items,
      })
      console.log('updateItem', res)
    } else {
      // console.log('create', items)
      const res = await createItems({
        collection: 'news',
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
  news_name.value = ''
  content.value = ''

  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  imgId.value = -1
  UploadImg = []

  // Reset form
  resetForm()
  success.value = false
  setErrors({})

  // Reset scroll position if needed
  if (rowsContainer.value) {
    rowsContainer.value.scrollTop = 0
  }

  // Close modal
  props.close?.()
  props.refresh?.()
}

// 🔹 `computed()` ашиглаж, шууд тооцоолох
const Thumbnail = computed(() => {
  return imgId.value != -1
    ? `${config.public.directus.url}assets/${imgId.value}`
    : '/img/avatars/placeholder-file.png'
})

const imgIdString = computed(() => String(imgId.value))

const handleUploaded = (newValue: any) => {
  console.log('done:)', newValue)
}

const handleModalLeaderOpen = (type: any) => {
  isModalLeaderOpen.value = true
}

const handleModalMemberOpen = (type: any) => {
  isModalMemberOpen.value = true
}

onMounted(async () => {
  console.log('props-edited', props)

  if (props.editRow) {
    news_name.value = props.editRow.title
    content.value = props.editRow.content

    // Handle one-to-many image relationship - image comes as array
    if (
      props.editRow.image &&
      Array.isArray(props.editRow.image) &&
      props.editRow.image.length > 0
    ) {
      // Extract the file ID from the junction table
      imgId.value =
        props.editRow.image[0]?.directus_files_id?.id ||
        props.editRow.image[0]?.directus_files_id ||
        -1
    } else if (props.editRow.image && !Array.isArray(props.editRow.image)) {
      // Fallback if image is returned as object
      imgId.value = props.editRow.image?.id || -1
    } else {
      imgId.value = -1
    }
  }
})

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  isError.value = false
}

const handleModalLeaderClose = () => {
  isModalLeaderOpen.value = false
}

const handleModalMemberClose = () => {
  isModalMemberOpen.value = false
}
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
        <!-- Header -->
        <div class="flex w-full items-center justify-between">
          <div class="flex items-center gap-2">
            <div
              class="flex size-8 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-900/30"
            >
              <Icon
                name="material-symbols:tv-signin-outline-rounded"
                class="size-4 text-primary-500"
              />
            </div>
            <div class="flex items-center gap-2">
              <h3
                class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
              >
                {{ $t(props.title) }}
              </h3>
            </div>
          </div>
          <BaseButtonClose @click="resetModal" />
        </div>
      </template>

      <!-- Body -->
      <div
        class="newsContainer body h-[440px] grid mx-auto overflow-y-auto overflow-x-hidden"
        ref="rowsContainer"
      >
        <div class="newsBody w-[580px] mx-auto">
          <div class="news_about flex justify-around">
            <div class="w-[354px]">
              <BaseInput
                v-model="news_name"
                :label="$t('title')"
                style="
                  width: 320px;
                  border: 1px solid #cbd5e1;
                  border-radius: 7px;
                "
                type="string"
              />

              <div class="w-[320px]">
                <BaseListbox
                  :label="$t('Status')"
                  style="width: 320px"
                  v-model="news_status"
                  :items="news_options"
                />
              </div>
            </div>

            <div
              class="LoginImg w-[210px] h-[266px] flex items-center justify-center"
            >
              <AvatarUpload
                code="users"
                field="login"
                height="210px"
                width="194px"
                :result="UploadImg"
                :id="imgIdString"
                xmargin="-208px 0px 0px -20px"
                :fileUrl="Thumbnail"
              />
            </div>
          </div>
          <div class="team_content w-[560px] flex mb-5 ml-1">
            <BaseTextarea
              v-model="content"
              contrast="default-contrast"
              size="sm"
              :label="$t('content')"
              rounded="md"
              :placeholder="$t('Write a content')"
              color-focus
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
.newsContainer .templates,
.newsContainer .options {
  margin-top: 10px;
}

.newsContainer .nui-input-outer,
.newsContainer .nui-listbox-outer,
.newsContainer .nui-textarea-outer {
  border: 1px solid #d1d5db !important;
  border-radius: 6px;
}

.newsContainer .templates .nui-radio {
  margin-bottom: 8px;
}
.newsContainer .options .InputBox {
  width: 80%;
  margin: auto;
}

.newsContainer .snackBox {
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
.newsContainer .placeholder-leader {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}

.newsContainer .placeholder-leader:empty::before {
  content: 'Team leader';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}

.newsContainer .placeholder-members {
  position: relative;
  color: #97a3b6;
  font-size: 12px;
}
.newsContainer .placeholder-members:empty::before {
  content: 'Team members';
  color: #97a3b6;
  position: absolute;
  top: 50%;
  left: 10px;
  transform: translateY(-50%);
}
.newsContainer .snackBox .nui-snack {
  border: 1px solid #c1bebe;
}

.newsContainer .snackBox .nui-button-close {
  height: 24px !important;
}

.team_content .nui-textarea-wrapper {
  width: 100%;
}

/* Input border styles */
.news_about :deep(.nui-input-wrapper),
.news_about :deep(.nui-listbox) {
  border: 1px solid #d1d5db !important;
  border-radius: 0.375rem;
}

.news_about :deep(.nui-input-wrapper:focus-within),
.news_about :deep(.nui-listbox:focus-within) {
  border-color: #6366f1 !important;
  box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
}

.team_content :deep(.nui-textarea-wrapper) {
  border: 1px solid #d1d5db !important;
  border-radius: 0.375rem;
}

.team_content :deep(.nui-textarea-wrapper:focus-within) {
  border-color: #6366f1 !important;
  box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.1);
}
</style>
