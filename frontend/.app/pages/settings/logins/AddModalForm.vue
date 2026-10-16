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

const checkbox_base = ref('primary')
const type = ref('')
const name = ref('')
let UploadImg = []
let UploadVideo = []
let UploadedVideo = []
let imgId = ref(-1)
let videoId = ref(-1)
const sel_type = ref(null)
const sel_axis = ref(null)
let thumbnailUrl = ref('')

let positions = ref(['Top', 'Bottom', 'Left', 'Right', 'Center'])
let axis_types1 = ref(['Horizontal', 'Vertical'])
let axis_types2 = ref(['Center'])

let vertical_pos = ref(['Top', 'Bottom'])
let horizan_pos = ref(['Left', 'Right'])
let center_pos = ref(['Center'])
let types = ref([t('Only Image'), t('Only Video'), t('Image and Video')])
const chosedTemplate = ref('')
const filteredTemplates = ref([])

const templates = ref([
  {
    id: 1,
    name: t('Only Image'),
    _image_id: 0,
    _video_id: 0,
    _image_size: '',
    _video_size: '',
    _is_image: 1,
    _is_video: 0,
    _image_position: '',
    _video_position: 0,
  },
  {
    id: 2,
    name: t('Only Video'),
    _image_id: 0,
    _video_id: 0,
    _image_size: '',
    _video_size: '',
    _is_image: 0,
    _is_video: 1,
    _image_position: '',
    _video_position: 0,
  },
  {
    id: 3,
    name: t('Image and Video'),
    _image_id: 0,
    _video_id: 0,
    _image_size: '',
    _video_size: '',
    _is_image: 1,
    _is_video: 1,
    _image_position: '',
    _video_position: '',
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
          name: t('Work order'),
          text: t('Your location work order'),
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
    // const selectedTemplate = templates.value.find(
    //   (t) => t.name === sel_type.value,
    // )
    // console.log('Submit хийх selectedTemplate!', selectedTemplate)

    if (sel_type.value == t('Only Image')) {
      if (
        filteredTemplates.value[0]?._image_size == '' ||
        filteredTemplates.value[0]?._image_size == null ||
        filteredTemplates.value[0]?._image_size == 0
      ) {
        isModalConfirmOpen.value = true
        isModalConfirmText.value = t('Please enter size!')
        return
      }
    } else if (sel_type.value == t('Only Video')) {
      if (
        filteredTemplates.value[0]?._video_size == '' ||
        filteredTemplates.value[0]?._video_size == null ||
        filteredTemplates.value[0]?._video_size == 0
      ) {
        isModalConfirmOpen.value = true
        isModalConfirmText.value = t('Please enter video size!')
        return
      }
    } else if (sel_type.value == t('Image and Video')) {
      if (
        filteredTemplates.value[0]?._image_size == '' ||
        filteredTemplates.value[0]?._image_size == null ||
        filteredTemplates.value[0]?._image_size == 0 ||
        filteredTemplates.value[0]?._video_size == '' ||
        filteredTemplates.value[0]?._video_size == null ||
        filteredTemplates.value[0]?._video_size == 0
      ) {
        isModalConfirmOpen.value = true
        isModalConfirmText.value = t('Please enter sizes!')
        return
      }
    }

    let items = {
      company_id: myCompanyId,
      _name: name.value,
      type: sel_type.value,
      axis: sel_axis.value,
      _image_size:
        filteredTemplates.value[0]?._image_size == '' ||
        filteredTemplates.value[0]?._image_size == null
          ? 0
          : filteredTemplates.value[0]?._image_size,
      _video_size:
        filteredTemplates.value[0]?._video_size == '' ||
        filteredTemplates.value[0]?._video_size == null
          ? 0
          : filteredTemplates.value[0]?._video_size,
      _is_image: filteredTemplates.value[0]?._is_image ?? 0,
      _is_video: filteredTemplates.value[0]?._is_video ?? 0,
      _image_position: filteredTemplates.value[0]?._image_position ?? '',
      _video_position: filteredTemplates.value[0]?._video_position ?? '',
      _image: UploadImg.length //ids
        ? UploadImg[0].id
        : imgId.value != -1
        ? imgId.value
        : null,
      _video: UploadVideo.length
        ? UploadVideo[0].id
        : videoId.value != -1
        ? videoId.value
        : null,
    }

    console.log('items', items)

    if (props.editRow != -1) {
      const res = await updateItem({
        collection: 'Login_set',
        id: props.editRow.id,
        item: items,
      })
    } else {
      const res = await createItems({
        collection: 'Login_set',
        items: items,
      })
    }

    resetModal()
    toaster.clearAll()
    toaster.show({
      title: t('Success'),
      message: t('Record has been created'),
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
  type.value = ''
  name.value = ''
  sel_type.value = null
  sel_axis.value = null
  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  UploadImg.value = []
  UploadVideo.value = []
  imgId.value = -1
  videoId.value = -1

  // Reset form
  resetForm()

  // Reset other reactive variables
  success.value = false
  // Clear any errors
  setErrors({})

  // Reset scroll position if needed
  if (rowsContainer.value) {
    rowsContainer.value.scrollTop = 0
  }

  // Close modal
  props.close()
  props.refresh()
}

// // 🔹 `computed()` ашиглаж, шууд тооцоолох
const Thumbnail = computed(() => {
  return imgId.value != -1
    ? `${config.public.directus.url}assets/${imgId.value}`
    : false
})

const ThumbnailVideo = computed(() => {
  return videoId.value != -1 && props.editRow._video != null
    ? `/img/utils/uploaded.png`
    : false
  // return `/img/utils/uploaded.png`
})

const handleUploaded = (newValue) => {
  console.log('done:)', newValue)
  // UploadedVideo = newValue
  UploadedVideo.push(newValue)
  UploadVideo.push(newValue)
}

onMounted(async () => {
  if (props.editRow) {
    checkbox_base.value = props.editRow.template_id
    imgId.value = props.editRow._image
    videoId.value = props.editRow._video
    name.value = props.editRow._name
    sel_type.value = props.editRow.type
    sel_axis.value = props.editRow.axis
    updateFilteredTemplates('edit')
  }

  console.log('props', props)
})

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalConfirmText.value = ''
  isError.value = false
}

// Сонгосон type-д тохирох templates-г шүүх
// const filteredTemplates = computed(() => {
//   console.log('chosedTemplate1')

//   if (props.editRow) {
//     const foundTemplate = templates.value.find(
//       (t) => t.id === props.editRow.type,
//     )

//     // types.value индексээс гарахаас сэргийлэх
//     if (props.editRow.type > 0 && props.editRow.type <= types.value.length) {
//       sel_type.value = types.value[props.editRow.type - 1]
//     }

//     return foundTemplate ? [{ ...foundTemplate, ...props.editRow }] : []
//   }

//   console.log('chosedTemplate2')
//   return templates.value.filter((template) => template.name === sel_type.value)
// })

// ✅ filteredTemplates-ийг шинэчлэх функц
const updateFilteredTemplates = (action) => {
  console.log('Selected sel_type:', sel_type)

  if (!sel_type.value === null) {
    console.log('Selected 1:', sel_type)
    filteredTemplates.value = templates.value.filter(
      (template) => template.name === sel_type.value,
    )
    // filteredTemplates.value = templates.value // 🚀 Анхдагч үед бүх template-үүд харагдана
  } else {
    console.log('Selected 2:', sel_type.value, action)

    if (action == 'onchange') {
      if (props.editRow && sel_type.value == props.editRow.type) {
        const foundTemplate = templates.value.find(
          (t) => t.name === props.editRow.type,
        )

        imgId.value = props.editRow._image
        videoId.value = props.editRow._video
        filteredTemplates.value = [{ ...foundTemplate, ...props.editRow }]
      } else {
        imgId.value = -1
        videoId.value = -1
        filteredTemplates.value = templates.value.filter(
          (template) => template.name === sel_type.value,
        )
      }
    } else if (action == 'edit') {
      const foundTemplate = templates.value.find(
        (t) => t.name === props.editRow.type,
      )

      filteredTemplates.value = [{ ...foundTemplate, ...props.editRow }]
      console.log('filteredTemplates 2:', filteredTemplates)
    } else {
      filteredTemplates.value = templates.value.filter(
        (template) => template.name === sel_type.value,
      )
    }
  }
}

// ✅ @change event ажиллах
const onChange = (value) => {
  console.log('Selected Type:', value)
  sel_type.value = value // Сонгосон утгыг шинэчилнэ
  updateFilteredTemplates('onchange')

  // ✅ Edit үед бусад templates-ийг харуулах эсэхийг шийднэ
  if (props.editRow) {
    emits('update:editRow', null) // Edit горимоос гарах
  }
}
</script>

<template>
  <form
    action=""
    method="POST"
    @submit.prevent="onSubmit"
    class="mx-auto w-full max-w-3xl"
  >
    <TairoModal :open="props.open" size="xl" @close="resetModal">
      <template #header>
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
                {{ $t('Login page settings') }}
              </h3>
            </div>
          </div>
          <BaseButtonClose @click="resetModal" />
        </div>
      </template>

      <!-- Body -->
      <div
        class="rowsContainer body w-[680px] h-[440px] grid mx-auto overflow-scroll"
        ref="rowsContainer"
      >
        <div class="options">
          <!-- Dynamically rendered field based on radio selection -->
          <div class="InputBox">
            <div class="name mb-5">
              <BaseInput
                v-model="name"
                rounded="none"
                :placeholder="$t('Name')"
                style="
                  width: 485px;
                  border-style: inherit;
                  border: 1px solid #e5e7eb;
                  border-radius: 6px;
                "
                type="string"
                :error="name == '' ? $t('Please enter a valid name') : ''"
              />
            </div>
            <div class="type mb-5">
              <BaseListbox
                v-model="sel_type"
                :items="types"
                :placeholder="$t('Type')"
                rounded="none"
                style="width: 485px"
                @update:modelValue="onChange"
              />
            </div>
            <div class="type mb-5">
              <BaseListbox
                v-model="sel_axis"
                :items="
                  sel_type == 'Image and Video' ? axis_types1 : axis_types2
                "
                :placeholder="$t('Axis')"
                rounded="none"
                style="width: 485px"
              />
            </div>
            <div v-for="e in filteredTemplates" :key="e.id">
              <!-- Image upload -->
              <div class="flex flex-row mb-3" v-if="e._is_image === 1">
                <div class="LoginImg flex justify-center mb-3">
                  <AvatarUpload
                    code="LoginImg"
                    field="login"
                    height="100px"
                    width="260px"
                    :result="UploadImg"
                    :id="imgId"
                    xmargin="-80px 0px 0px -20px"
                    :fileUrl="Thumbnail"
                  />
                </div>
                <div class="w-[120px] ml-3">
                  <BaseListbox
                    v-model="e._image_position"
                    :items="
                      sel_axis == 'Horizontal'
                        ? horizan_pos
                        : sel_axis == 'Vertical'
                        ? vertical_pos
                        : center_pos
                    "
                    :placeholder="$t('Position')"
                    rounded="none"
                  />
                </div>
                <div class="image_size ml-3">
                  <BaseInput
                    v-model="e._image_size"
                    rounded="none"
                    type="number"
                    :placeholder="$t('Size')"
                    style="
                      width: 80px;
                      border-style: inherit;
                      border: 1px solid #e5e7eb;
                      border-radius: 6px;
                    "
                  />
                </div>
              </div>

              <!-- Video upload -->
              <div class="flex flex-row mb-3" v-if="e._is_video === 1">
                <div class="LoginVideo flex justify-center">
                  <AvatarUpload
                    code="Video"
                    field="login"
                    height="100px"
                    width="260px"
                    @update:UploadedVideo="handleUploaded"
                    :result="UploadVideo"
                    :id="videoId"
                    xmargin="-80px 0px 0px -20px"
                    :fileUrl="ThumbnailVideo"
                    :bgIcon="`/img/utils/uploaded.png`"
                  />
                </div>
                <div class="w-[120px] ml-3">
                  <BaseListbox
                    v-model="e._video_position"
                    :items="
                      sel_axis == 'Horizontal'
                        ? horizan_pos
                        : sel_axis == 'Vertical'
                        ? vertical_pos
                        : center_pos
                    "
                    :placeholder="$t('Position')"
                    rounded="none"
                  />
                </div>
                <div class="video_size ml-3">
                  <BaseInput
                    v-model="e._video_size"
                    rounded="none"
                    :placeholder="$t('Size')"
                    type="number"
                    style="
                      width: 80px;
                      border-style: inherit;
                      border: 1px solid #e5e7eb;
                      border-radius: 6px;
                    "
                  />
                </div>
              </div>
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
.rowsContainer .options .InputBox {
  width: 80%;
  margin: auto;
}
</style>
