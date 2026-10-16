<script setup>
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'

import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
import WarningModalForm from '~/components/form/WarningModalForm.vue'

const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()
const { t } = useI18n({ useScope: 'global' })

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const toaster = useToaster()
const myCompanyId = getMyCompanyId()
const segment = ref('')
const family = ref('')
const _class = ref('')
const commodity = ref('')
const numbering = ref('')
const isModalPartOpen = ref(false)
const isModalConfirmText = ref('')
const inputSupplierValue = ref('')
const isModalConfirmOpen = ref(false)
const isModalOpen = ref(false)
const newVal = ref(false)
const isModalApproveConfirmOpen = ref(false)

const rows = ref([
  {
    text: '',
  },
])

// Scroll контейнерийг тодорхойлох rowsContainer
const rowsContainer = ref(null)
const project_id = ref(0)
const work_id = ref(0)

const props = defineProps({
  key: Number,
  title: String,
  code: String,
  open: Boolean,
  close: Function,
  refresh: Function,
  task: Object,
  project: Object,
  rowId: Number,
})

if (props.task) {
  project_id.value = props.project?.id
  work_id.value = props.task?.id
  // console.log('props-props', props)
}

const handleModalClose = () => {
  isModalPartOpen.value = false
  isModalApproveConfirmOpen.value = false

  setEmptyRow()
  props.close()
}

const handleAddRow = (item, index) => {
  const newRow = {
    text: '',
  }

  if (props.rowId === -1) {
    rows.value.splice(index + 1, 0, newRow)
  }

  // Scroll-ийг доош шилжүүлэх
  setTimeout(() => {
    if (rowsContainer.value) {
      rowsContainer.value.scrollTop = rowsContainer.value.scrollHeight
    }
  }, 0) // Ачааллыг баталгаажуулахын тулд бага зэрэг хүлээлт
}

const handleRemoveRow = (item, index) => {
  if (props.rowId === -1) {
    if (rows.value.length > 1) {
      rows.value.splice(index, 1)
    }
  }
}

const setEmptyRow = () => {
  rows.value = [
    {
      text: '',
    },
  ]
}

const submitHandler = async (values) => {
  // console.log('values ->', values)
  // console.log('rows', rows.value)
  // console.log('props.rowId', props.rowId)
  // console.log('project ->', props.project)
  // console.log('task ->', props.task)
  // console.log('uploadedFiles ->', uploadedFiles)
  // console.log('inputDateValue ->', inputDateValue.value)
  // console.log('inputLocationValue.value ->', inputLocationValue.value)

  toaster.clearAll()
  if (props.rowId === -1) {
    if (!rows.value[0].text || rows.value[0].text == '') {
      isModalConfirmOpen.value = true
      isModalConfirmText.value = 'Please insert task!'
      return
    }

    for (const task of rows.value) {
      let item = {
        // status: 0,
        active: '1',
        project_work: props.task?.id,
        parent: null,
        name: task.text,
        template_type: 5,
        company_id: myCompanyId,
      }

      await createItems({
        collection: 'Project_work_item',
        items: item,
      })
    }

    toaster.show({
      title: t('Added'),
      message: t(`Task created successfully`) + '!',
      color: 'success',
      closable: true,
    })
    if (props.refresh) {
      console.log('add refresh 2...')
      props.refresh('add')
    }
  } else {
    if (!values.text0 || values.text0 == '') {
      isModalConfirmOpen.value = true
      isModalConfirmText.value = 'Please insert task3!'
      return
    }

    let item = {
      // status: 1,
      active: '1',
      project_work: props.task?.id,
      parent: null,
      name: values.text0,
      template_type: 5,
    }

    const data = {
      collection: 'Project_work_item',
      id: props.rowId,
      item: item,
    }

    let done = await updateItem(data)

    if (props.refresh) {
      console.log('edit refresh 2...')
      props.refresh('edit')
    }
    toaster.show({
      title: t('Updated'),
      message: t(`Record updated successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }

  if (props.close) {
    props.close()
  }

  handleModalClose()
}

const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
  isModalApproveConfirmOpen.value = false
}

const do_make = async (item, type) => {
  handleModalClose()
}

const askModalClose = () => {
  isModalApproveConfirmOpen.value = true
}
onMounted(async () => {
  if (props.rowId != -1) {
    console.log('onMounted', props)
  }
})
</script>

<template>
  <!-- New & Edit modal -->
  <TairoModal
    :classes="{ dialog: 'addTask' }"
    :key="props.key"
    :open="props.open"
    @close="handleModalClose"
  >
    <template #header>
      <!-- Header -->
      <div class="flex items-center justify-between p-2 md:p-2">
        <div
          class="flex font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white pl-8"
        >
          {{ t(title) + `&nbsp;` }}
        </div>
        <BaseButtonClose @click="handleModalClose" />
      </div>
    </template>

    <!-- Body -->
    <div
      class="addTaskBody rows-container flex mx-auto max-h-[700px] h-[500px] px-5"
    >
      <FormKit
        type="form"
        :actions="true"
        :style="{ width: '100%' }"
        :submit-label="t('Save')"
        @submit="submitHandler"
        :submit-attrs="{
          inputClass:
            'text-sm px-5 mt-2 mb-5 py-2 is-button rounded bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
          ignore: false,
          wrapperClass: 'submit flex justify-end',
        }"
      >
        <div
          ref="rowsContainer"
          class="rowsContainer overflow-auto h-[380px] font-sans text-sm text-gray-500 dark:text-gray-400"
        >
          <div class="pt-3 parts">
            <div
              v-for="(item, index) in props.rowId === -1 ? rows : props.task"
              :key="index"
              class="row flex ml-1"
            >
              <div class="flex mr-3">
                <div
                  :class="
                    index > 0 ? 'w-[20px] mt-2 mr-1' : 'w-[20px] mt-8 mr-1'
                  "
                >
                  {{ `${index + 1}.` }}
                </div>
                <BaseButton
                  v-if="props.rowId === -1"
                  color="default"
                  :class="index > 0 ? 'mr-1' : 'mt-6 mr-1'"
                  @click="handleAddRow('Parts', index)"
                >
                  +
                </BaseButton>

                <FormKit
                  :name="'text' + index"
                  type="textarea"
                  :label="index > 0 ? '' : 'Task:'"
                  :validation="'required'"
                  :validation-messages="{ required: '*' }"
                  :style="{
                    width: '280px',
                    maxWidth: ' 280px',
                    height: '28px',
                    marginRight: '5px',
                    fontSize: '12px',
                  }"
                  v-model="item.text"
                />
              </div>

              <BaseButton
                v-if="props.rowId === -1"
                color="default"
                :class="index > 0 ? ' ml-1' : 'mt-6  ml-1'"
                @click="handleRemoveRow(item, index)"
              >
                -
              </BaseButton>
            </div>
          </div>
        </div>
      </FormKit>
    </div>
    <ConfirmModalForm
      code="Income"
      :text="$t('Do you close to this form?')"
      :successfullText="false"
      :open="isModalApproveConfirmOpen"
      :close="handleModalConfirmClose"
      :do_make="do_make"
    />
    <WarningModalForm
      :text="$t(isModalConfirmText)"
      code="Transaction"
      :open="isModalConfirmOpen"
      :close="handleModalConfirmClose"
    />
  </TairoModal>
</template>
<style>
.v-overlay {
  z-index: 10001 !important;
}
.addTask {
  width: 63%;
}
.addTaskBody .nui-button.nui-button-medium {
  padding: 0px 10px 0px 10px !important;
  height: 28px;
}
.addTaskBody .parts .vs__dropdown-toggle {
  height: 28px;
}

.addTaskBody .v-select.vs--single {
  /* width: 320px !important;
  margin-right: 10px; */
}
.addTaskBody .vs__selected-options {
  width: 150px !important;
  text-overflow: ellipsis !important;
}
.addTaskBody .vs__selected-options {
  width: 150px !important;
  text-overflow: ellipsis !important;
  font-size: 12px;
}
.addTaskBody .vs__actions .vs__clear {
  /* position: absolute;
  margin: 0px -20px;
  z-index: 10; */
  display: none;
}
.addTaskBody .text-danger-500 {
  width: 80px;
  overflow: hidden;
  white-space: nowrap;
}
.mb-1.max-w-md:has(.submit) {
  width: 100%;
  max-width: 100%;
  right: 22px;
  position: relative;
}
</style>
