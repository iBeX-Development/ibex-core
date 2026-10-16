<script setup lang="ts">
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'

import { Field, useForm } from 'vee-validate'
import WarningModalForm from '~/components/form/WarningModalForm.vue'

const { deleteUsers } = useDirectusUsers()
const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const { token } = useDirectusToken()

const isModalConfirmText = ref('')
const isModalConfirmOpen = ref(false)
const isError = ref(false)

const isRemoveAccepted = ref(false)
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
const colors = ref(false)
const selectedModule = ref('work_order')

const choose_options = [
  {
    id: 1,
    name: t('Work order'),
    text: t('Your location work order'),
    icon: 'ph:buildings-duotone',
    module_key: 'work_order',
  },
]

const type_options = [t('Open'), t('Completed')]

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

    // here you have access to the validated form values
    // console.log('meeting-create-success', values)

    if (!values.module) {
      isModalConfirmOpen.value = true
      isModalConfirmText.value = 'Please select module!'
      isError.value = true
    }

    // Clean and filter rows to remove empty ones
    const cleanedRows = values.rows
      .filter(
        (row) => row.meeting && (row.meeting.title || row.meeting.colorCode),
      ) // Remove empty rows
      .map((row) => ({
        meeting: {
          title: row.meeting.title || '',
          type: row.meeting.type || '',
          position: row.meeting.position || '',
          colorCode: row.meeting.colorCode || '',
        },
      }))

    // Function to check for duplicate color codes
    function checkDuplicateColors(rows) {
      let colorSet = new Set()

      for (let row of rows) {
        let colorCode = row.meeting.colorCode

        // Давхцаж байгаа эсэхийг шалгах
        if (colorCode && colorSet.has(colorCode)) {
          return false
        }

        // Өнгийг Set-д нэмэх
        colorSet.add(colorCode)
      }

      return true // Хэрэв давхцал байхгүй бол submit хийх боломжтой
    }

    if (checkDuplicateColors(cleanedRows)) {
      console.log('Submit хийх боломжтой!')
    } else {
      console.log('Submit хийхийг болиуллаа!')
      isModalConfirmOpen.value = true
      isModalConfirmText.value = 'Colors are same!'
      isError.value = true
    }

    if (cleanedRows.length <= 0) {
      isModalConfirmOpen.value = true
      isModalConfirmText.value = 'Choose status!'
      isError.value = true
    }

    // Create final submission data
    const submissionData = {
      rows: cleanedRows,
    }

    const formattedItems = cleanedRows.map((item, index) => {
      if (
        item.meeting.colorCode === '' ||
        item.meeting.colorCode === null ||
        item.meeting.position === '' ||
        item.meeting.position === null ||
        item.meeting.title === '' ||
        item.meeting.title === null ||
        item.meeting.type === '' ||
        item.meeting.type === null
      ) {
        isModalConfirmOpen.value = true
        isModalConfirmText.value = 'Items!'

        isError.value = true
        console.log('empty ')
        return false
      } else {
        return {
          module_key: 'work_order',
          status_text: item.meeting.title,
          position: item.meeting.position || 1,
          default_status: 0,
          type: item.meeting.type || 'open',
          status_value: parseInt(
            item.meeting.colorCode.split('color_code_')[1],
          ),
          status_color: item.meeting.colorCode,
          code_color: parseInt(item.meeting.colorCode.split('color_code_')[1]),
          company_id: myCompanyId,
        }
      }
    })

    if (isError.value) return

    try {
      // console.log('formattedItems', formattedItems)

      if (props.editRow != -1) {
        // Update existing record
        const res = await updateItem({
          collection: 'Module_status',
          id: props.editRow.id,
          item: formattedItems[0], // Since we're editing a single record
        })
      } else {
        const res = await createItems({
          collection: 'Module_status',
          items: formattedItems,
        })
      }

      toaster.clearAll()
      toaster.show({
        title: 'Success',
        message: `Record has been created`,
        color: 'success',
        icon: 'ph:check',
        closable: true,
      })

      resetModal()
    } catch (error: any) {
      console.log('error1', error)
      return
    }
    document.documentElement.scrollTo({
      top: 0,
      behavior: 'smooth',
    })

    success.value = true
    setTimeout(() => {
      success.value = false
    }, 3000)
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

const computeNextPosition = async () => {
  const remoteNext = await fetchNextPosition()
  const localMax = rows.value.reduce((max, r) => {
    const p = Number(r.meeting.position) || 0
    return p > max ? p : max
  }, 0)
  return Math.max(remoteNext, localMax + 1)
}

const handleAddRow = async () => {
  const newRow = {
    meeting: {
      title: '',
      position: await computeNextPosition(),
      type: '',
      colorCode: '',
    },
  }

  rows.value = [...rows.value, newRow]

  const currentValues = values.rows || []
  setFieldValue('rows', [...currentValues, newRow])

  // Scroll to new row
  setTimeout(() => {
    if (rowsContainer.value) {
      rowsContainer.value.scrollTop = rowsContainer.value.scrollHeight
    }
  }, 0)
}

const handleRemoveRow = (index: number) => {
  // Only proceed if we have more than one row
  if (rows.value.length > 1) {
    // Create new array without the removed row but keeping other values
    const updatedRows = [...rows.value]
    updatedRows.splice(index, 1)
    rows.value = updatedRows

    // Update form values while preserving other values
    const currentValues = [...(values.rows || [])]
    currentValues.splice(index, 1)
    setFieldValue('rows', currentValues)
  } else {
    // If it's the last row, show a warning or prevent deletion
    toaster.show({
      title: 'Warning',
      message: 'Cannot remove the last row',
      color: 'warning',
      icon: 'ph:warning',
      closable: true,
    })
  }
}

const resetModal = () => {
  // Reset rows to initial state
  rows.value = [
    {
      meeting: {
        title: '',
        type: '',
        position: '',
        colorCode: '',
      },
    },
  ]

  // Reset form
  resetForm()

  // Reset other reactive variables
  success.value = false
  isRemoveAccepted.value = false
  selectedModule.value = 'work_order' // Reset module selection if needed

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

const fetchNextPosition = async () => {
  try {
    const res = await getItems({
      collection: 'Module_status',
      params: {
        // filter: { company_id: myCompanyId, module_key: 'work_order' },
        limit: -1,
        fields: ['position'],
      },
    })
    const items = Array.isArray(res) ? res : res?.data ?? []
    // position нь string хэлбэрээр хадгалагддаг тул DB sort лексикограф
    // байдаг (жишээ нь "9" > "10"); тиймээс бүгдийг татаад тоогоор
    // харьцуулж max-ийг олно
    const maxPosition = items.reduce((max, item) => {
      const p = Number(item.position) || 0
      return p > max ? p : max
    }, 0)
    // console.log(
    //   'fetchNextPosition items ->',
    //   items,
    //   'maxPosition ->',
    //   maxPosition,
    // )
    return maxPosition + 1
  } catch (e) {
    return 1
  }
}

const loadItems = async ({ page, itemsPerPage }) => {
  try {
    const filters = {}

    const items = await getItems({
      collection: 'Colors',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    colors.value = items.data
  } catch (e) {}
}

onMounted(async () => {
  await loadItems(1, -1)

  if (props.editRow && props.editRow !== -1) {
    rows.value = [
      {
        meeting: {
          title: props.editRow.status_text,
          type: props.editRow.type.toLowerCase(), // Ensure type matches your options case
          position: props.editRow.position,
          colorCode: props.editRow.code_color.code,
        },
      },
    ]

    // Set form values
    setFieldValue('rows', rows.value)

    // Set module value
    setFieldValue('module', [
      {
        id: 1,
        name: 'Work order',
        text: 'Your location work order',
        icon: 'ph:buildings-duotone',
        module_key: 'work_order',
      },
    ])
  } else {
    rows.value[0].meeting.position = await fetchNextPosition()
    setFieldValue('rows', rows.value)
  }
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
    <TairoModal :open="props.open" size="xl" @close="resetModal">
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
                {{ t('Add status') }}
              </h3>
            </div>
          </div>
          <BaseButtonClose @click="resetModal" />
        </div>
      </template>

      <!-- Body -->
      <div
        class="status-form rowsContainer body w-[548px] h-[280px] mx-auto nui-slimscroll overflow-x-hidden overflow-y-auto"
        ref="rowsContainer"
      >
        <div class="module flex">
          <div class="flex items-center w-[65px]">
            <label class="nui-label text-[0.825rem]">{{ t('Module') }}</label>
          </div>
          <div class="w-[250px]">
            <Field
              v-slot="{ field, errorMessage, handleChange, handleBlur }"
              name="module"
            >
              <BaseListbox
                :items="choose_options"
                :placeholder="t('Select a module')"
                :properties="{
                  value: 'id',
                  label: 'name',
                  sublabel: 'text',
                  icon: 'icon',
                }"
                :model-value="field.value"
                :error="errorMessage"
                :disabled="isSubmitting"
                @update:model-value="handleChange"
                @blur="handleBlur"
              />
            </Field>
          </div>
          <BaseButton
            v-if="props.editRow === -1"
            color="default"
            :class="'ml-1'"
            @click="handleAddRow()"
          >
            +
          </BaseButton>
        </div>
        <div class="pt-3 rows">
          <div v-for="(item, index) in rows" :key="index" class="row mt-[40px]">
            <div class="color flex mb-[15px]">
              <div class="flex items-center w-[65px]">
                <label class="nui-label text-[0.825rem]">{{
                  t('Colors')
                }}</label>
              </div>
              <div class="flex items-center gap-3">
                <Field
                  v-slot="{ field, errorMessage, handleChange, handleBlur }"
                  v-for="(coloritem, cindex) in colors"
                  :key="coloritem.id"
                  :name="`rows.${index}.meeting.colorCode`"
                >
                  <BaseRadioHeadless
                    :name="coloritem.code"
                    :value="coloritem.code"
                    :model-value="field.value"
                    :error="errorMessage"
                    :disabled="isSubmitting"
                    @update:model-value="handleChange"
                    @blur="handleBlur"
                  >
                    <div
                      :class="[
                        'peer-checked:bg-[${coloritem.text_color}]',
                        'h-4 w-4 rounded-full border-2 transition-colors duration-300',
                      ]"
                      :style="{
                        borderColor:
                          coloritem.text_color === 'white'
                            ? 'black'
                            : coloritem.text_color,
                        backgroundColor:
                          field.value === coloritem.code
                            ? coloritem.bg_color
                            : '',
                      }"
                    ></div>
                  </BaseRadioHeadless>
                </Field>
              </div>
            </div>

            <div class="name flex">
              <div class="flex items-center w-[65px]">
                <label class="nui-label text-[0.825rem]">Status</label>
              </div>
              <div class="w-[195px] mr-[5px]">
                <Field
                  v-slot="{ field, errorMessage, handleChange, handleBlur }"
                  :name="`rows.${index}.meeting.title`"
                >
                  <BaseInput
                    type="text"
                    shape="rounded"
                    :placeholder="t('Status name')"
                    :model-value="field.value"
                    :error="errorMessage"
                    :disabled="isSubmitting"
                    @update:model-value="handleChange"
                    @blur="handleBlur"
                  />
                </Field>
              </div>

              <div class="w-[50px] mr-[5px]">
                <Field
                  v-slot="{ field, errorMessage, handleChange, handleBlur }"
                  :name="`rows.${index}.meeting.position`"
                >
                  <BaseInput
                    type="text"
                    shape="rounded"
                    :placeholder="t('Position')"
                    :model-value="field.value"
                    :error="errorMessage"
                    :disabled="isSubmitting"
                    readonly
                    @update:model-value="handleChange"
                    @blur="handleBlur"
                  />
                </Field>
              </div>
              <div class="w-[180px]">
                <Field
                  v-slot="{ field, errorMessage, handleChange, handleBlur }"
                  :name="`rows.${index}.meeting.type`"
                >
                  <BaseListbox
                    :items="type_options"
                    :placeholder="t('Type')"
                    :model-value="field.value"
                    :error="errorMessage"
                    :disabled="isSubmitting"
                    @update:model-value="handleChange"
                    @blur="handleBlur"
                  />
                </Field>
              </div>

              <BaseButton
                color="default"
                class="ml-1"
                @click="handleRemoveRow(index)"
              >
                -
              </BaseButton>
            </div>
          </div>
        </div>
      </div>

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
.status-form .nui-input {
  border: 1px solid #e2e2e2 !important;
}
.status-form .nui-input:focus {
  border-color: #6366f1 !important;
}
</style>
