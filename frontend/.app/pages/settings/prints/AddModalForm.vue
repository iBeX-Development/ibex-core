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

const checkbox_base = ref('primary')
const type = ref('')
const name = ref('')
const UploadImg = ref([]) // ✅ reactive array

let imgId = ref(-1)
let thumbnailUrl = ref('')

const templates = ref([
  {
    id: 1,
    name: 'Only Image',
    _image_id: 0,
    _is_image: 1,
  },
])

const isModalConfirmText = ref('')
const isModalConfirmOpen = ref(false)
const isError = ref(false)

const props = defineProps({
  open: Boolean,
  code: String,
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
const rowsContainer = ref(null)

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
    // console.log('Submit хийх боломжтой!', values)

    if (name.value === '') {
      isModalConfirmOpen.value = true
      isModalConfirmText.value = 'Please enter name'
      return
    }

    if (UploadImg.value.length === 0) {
      isModalConfirmOpen.value = true
      isModalConfirmText.value = 'Please enter file'
      return
    }

    let items = {
      name: name.value,
      code: 'Hi',
      uploaded: UploadImg.value.length //ids
        ? UploadImg.value[0].id
        : imgId.value != -1
        ? imgId.value
        : null,
      company_id: myCompanyId,
    }

    console.log('items', items)

    if (props.editRow != -1) {
      const res = await updateItem({
        collection: 'Prints_tempates',
        id: props.editRow.id,
        item: items,
      })
    } else {
      const res = await createItems({
        collection: 'Prints_tempates',
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
  name.value = ''
  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  UploadImg.value = []
  imgId.value = -1

  resetForm()

  success.value = false
  setErrors({})

  if (rowsContainer.value) {
    rowsContainer.value.scrollTop = 0
  }

  props.close()
  props.refresh()
}

// // 🔹 `computed()` ашиглаж, шууд тооцоолох
const Thumbnail = computed(() => {
  return imgId.value != -1
    ? `${config.public.directus.url}assets/${imgId.value}`
    : false
})

onMounted(async () => {
  if (props.editRow) {
    checkbox_base.value = props.editRow.template_id
    imgId.value = props.editRow.uploaded
    name.value = props.editRow.name
  }

  console.log('props', props)
})

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  isError.value = false
}
</script>

<template>
  <form
    action=""
    method="POST"
    @submit.prevent="onSubmit"
    class="mx-auto w-full max-w-3xl"
  >
    <TairoModal :open="props.open" size="md" @close="resetModal">
      <template #header>
        <!-- Header -->
        <div class="flex w-full items-center justify-between">
          <div class="flex items-center gap-2">
            <div
              class="flex size-8 items-center justify-center rounded-lg bg-primary-100 dark:bg-primary-900/30"
            >
              <Icon
                name="material-symbols:photo-prints-outline-sharp"
                class="size-4 text-primary-500"
              />
            </div>
            <div class="flex items-center gap-2">
              <h3
                class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
              >
                {{ t('Template') }}
              </h3>
            </div>
          </div>
          <BaseButtonClose @click="resetModal" />
        </div>
      </template>

      <!-- Body -->
      <div
        class="rowsContainer body h-[240px] items-center justify-items-center"
        ref="rowsContainer"
      >
        <!-- Dynamically rendered field based on radio selection -->
        <div class="InputBox">
          <div class="name mb-5">
            <BaseInput
              v-model="name"
              rounded="none"
              :placeholder="t('Name')"
              style="
                width: 320px;
                border: 1px solid #e5e7eb;
                border-radius: 6px;
              "
              type="string"
              :error="name == '' ? t('Please enter a valid name') : ''"
            />
          </div>

          <!-- file upload -->
          <div class="flex flex-row mb-3">
            <div class="File flex justify-center mb-3">
              <AvatarUpload
                code="File"
                field="Prints"
                height="100px"
                width="320px"
                :result="UploadImg"
                :id="imgId"
                xmargin="-80px 0px 0px -20px"
                :fileUrl="Thumbnail"
              />
            </div>
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
</style>
