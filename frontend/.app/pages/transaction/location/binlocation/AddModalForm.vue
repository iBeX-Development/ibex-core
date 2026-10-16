<script setup>
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import ConfirmModalForm from '~/components/form/ConfirmModalForm.vue'
const { t } = useI18n({ useScope: 'global' })

import WarningModalForm from '~/components/form/WarningModalForm.vue'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()
const { params } = useRoute()

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()
const segment = ref('')
const family = ref('')
const _class = ref('')
const commodity = ref('')
const numbering = ref('')
const item_description = ref('')
const isModalPartOpen = ref(false)
const uploadedFiles = ref([])
const editFiles = ref([])
const chosedLocation = ref([])
const inputNameValue = ref('')
const inputDateValue = ref('')
const inputLocationValue = ref('')
const isModalConfirmText = ref('')
const inputSupplierValue = ref('')
const locationDisable = ref(false)
const isModalConfirmOpen = ref(false)
const isModalOpen = ref(false)
const newVal = ref(false)
const isModalApproveConfirmOpen = ref(false)

const stateOptions = ref([])

const rows = ref([
  {
    choose_part: {
      part_number: { part_number: '', description: '' },
      id: null,
    },
    price: 0,
    qty: 0,
    part_state: '',
  },
])

const serverItems = ref([])
const loading = ref(false)
const locationId = ref(1)
const loadItem = ref('')

const props = defineProps({
  open: Boolean,
  title: String,
  module: String,
  close: Function,
  refresh: Function,
  row: Number,
  location: Number,
  item: Object,
  code: String,
  last: Object,
  editPartRow: Object,
})

// Scroll контейнерийг тодорхойлох ref
const rowsContainer = ref(null)

const handleModalPartClose = () => {
  isModalPartOpen.value = false
}

const handleModalPartOpen = (item) => {
  isModalPartOpen.value = true
  loadItem.value = item
}

const handleModalClose = () => {
  isModalPartOpen.value = false
  isModalApproveConfirmOpen.value = false
  locationDisable.value = false

  inputNameValue.value = ''
  inputDateValue.value = ''
  inputLocationValue.value = ''
  props.close()
}

const submitHandler = async (values) => {
  // console.log('values ->', values)
  // console.log('rows', rows.value)
  // console.log('editPartRow ->', props.editPartRow)

  // console.log('inputDateValue ->', inputDateValue.value)
  // console.log('params.value ->', params)

  toaster.clearAll()
  let itemsValue = {}

  if (!inputNameValue.value) {
    isModalConfirmOpen.value = true
    isModalConfirmText.value = 'Please insert name!'

    return
  }
  const locationValue = props.location ? props.location : params.id
  itemsValue['location'] = locationValue
  itemsValue['name'] = inputNameValue.value

  // Duplicate name check
  const existingItems = await getItems({
    collection: 'Bin_location',
    params: {
      filter: {
        name: { _eq: inputNameValue.value },
        location: { _eq: locationValue },
        status: { _neq: 'archived' },
      },
      fields: ['id'],
      limit: 1,
    },
  })
  const existingList = Array.isArray(existingItems)
    ? existingItems
    : existingItems?.data ?? []
  const isDuplicate = existingList.some((d) => d.id !== props.row)
  if (isDuplicate) {
    isModalConfirmOpen.value = true
    isModalConfirmText.value = `"${inputNameValue.value}" нэртэй bin location аль хэдийн бүртгэлтэй байна!`
    return
  }

  let items = [itemsValue]

  if (props.row === -1) {
    const res = await createItems({
      collection: props.code,
      items: items.map((it) => ({ ...it, company_id: myCompanyId })),
    })

    toaster.show({
      title: t('Added'),
      message: t(`Record created successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  } else {
    const data = {
      collection: props.code,
      id: props.row,
      item: itemsValue,
    }

    await updateItem(data)

    toaster.show({
      title: t('Updated'),
      message: t(`Record updated successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }

  if (props.refresh) {
    console.log('Props refresh 2...')
    props.refresh()
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

onMounted(async () => {
  // Load Part_state options
  try {
    const stateRes = await getItems({
      collection: 'States',
      params: {
        filter: { company_id: myCompanyId },
        fields: ['code', 'name'],
        sort: ['name'],
        limit: -1,
      },
    })
    const stateList = Array.isArray(stateRes) ? stateRes : stateRes?.data ?? []
    stateOptions.value = [
      { value: '', label: '—' },
      ...stateList.map((s) => ({ value: s.code, label: s.name })),
    ]
  } catch (e) {
    console.warn('Failed to load States:', e)
  }

  if (props.row) {
    inputNameValue.value = props.item?.name
    inputDateValue.value = props.item?.transaction_date?.split('T')[0]
    inputLocationValue.value = props.item?.location
    inputSupplierValue.value = props.item?.supplier
  }
  console.log('props.location', props.location)
  if (props.location) {
    const locationRes = await getItems({
      collection: 'Location',
      params: {
        filter: { status: '1', id: props.location },
        meta: 'filter_count',
        fields: ['*'],
      },
    })

    inputLocationValue.value = locationRes.data[0]
    setLocation(locationRes.data[0])

    locationDisable.value = true

    console.log('inputLocationValue', inputLocationValue)
  }
})

watch(locationDisable, async () => {
  console.log('watch changed:', locationDisable.value)
  const locationRes = await getItems({
    collection: 'Location',
    params: {
      filter: { status: '1', id: props.location },
      meta: 'filter_count',
      fields: ['*'],
    },
  })

  inputLocationValue.value = locationRes.data[0]
  setLocation(locationRes.data[0])

  locationDisable.value = true

  console.log('inputLocationValue', inputLocationValue)
})

const setLocation = (obj) => {
  chosedLocation.value = obj

  console.log(
    'setLocationsdsdsdsd',
    chosedLocation.value,
    inputLocationValue.value?.id,
  )

  newVal.value = changeFilter1(
    chosedLocation.value?.id,
    inputLocationValue.value?.id,
  )
}

const setValue = (obj, item_index) => {
  console.log('setValue', obj, item_index)
  if (!obj) {
    let index = item_index.value

    if (rows.value[index]) {
      let newValue = {
        choose_part: {
          part_number: {
            part_number: '',
            description: '',
          },
          id: 1,
        },
        price: 0,
        qty: 0,
      }

      rows.value[index] = {
        ...rows.value[index],
        ...newValue,
      }
    }
  }
}

const changeFilter1 = (newId, oldId) => {
  console.log('changeFilter1', newId, oldId)

  if (newId !== oldId) {
    return {
      status: '1',
      location: newId,
    }
  } else {
    if (props.location) {
      return {
        status: '1',
        location: props.location,
      }
    } else return false
  }
}

const changeFilter = computed(() => {
  console.log(
    'changeFilter_fn',
    chosedLocation.value?.id,
    inputLocationValue.value?.id,
  )

  if (chosedLocation.value?.id) {
    return {
      status: '1',
      location: chosedLocation.value?.id,
    }
  } else {
    return false
  }
})

const do_make = async (item, type) => {
  handleModalClose()
}

const askModalClose = () => {
  isModalApproveConfirmOpen.value = true
  console.log('askModalClose', rows.value.length)
}

// watch(chosedLocation, () => {
//   console.log('watch changed:', chosedLocation.value?.id)

//   return {
//     'chosedLocation.value.id': function (newId, oldId) {
//       console.log('watch changed2:', newId, oldId)

//       if (newId !== oldId) {
//         console.log('newId changed:', newId, oldId)
//       }
//     },
//   }
// })
</script>

<template>
  <!-- New & Edit modal -->
  <TairoModal
    :classes="{ dialog: 'addModal' }"
    :key="props.key"
    :open="props.open"
    @close="askModalClose"
  >
    <template #header>
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div
          class="flex font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
        >
          <Icon
            name="ph:gear-six-duotone"
            class="h-5 w-5 text-primary-500 mr-3"
          />
          {{ t(title) + `&nbsp;` }}
          <p :style="{ color: 'red' }"></p>
        </div>
        <BaseButtonClose @click="handleModalClose" />
      </div>
    </template>

    <!-- Body -->
    <div class="income rows-container flex mx-auto px-5">
      <FormKit
        type="form"
        :actions="true"
        :incomplete-message="false"
        :style="{ width: '100%' }"
        :submit-label="t('Save')"
        @submit="submitHandler"
        :submit-attrs="{
          inputClass:
            'text-sm px-6 py-2 mt-2 mb-4 is-button rounded-lg bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
          ignore: false,
          wrapperClass: 'submit flex justify-end',
        }"
      >
        <div
          ref="rowsContainer"
          class="rowsContainer h-[220px] font-sans text-sm"
        >
          <FormKit
            name="name"
            type="text"
            label="Name:"
            :validation="'required'"
            validation-label="*"
            v-model="inputNameValue"
            :classes="{
              input: 'inc-input',
              outer: 'inc-outer',
              label: 'inc-label',
            }"
          />
        </div>
      </FormKit>
    </div>
    <ConfirmModalForm
      code="Dialog"
      :text="$t('Do you close to this form?')"
      :successfullText="false"
      :open="isModalApproveConfirmOpen"
      :close="handleModalConfirmClose"
      :do_make="do_make"
    />
    <WarningModalForm
      :text="$t(isModalConfirmText)"
      code="Dialog"
      :open="isModalConfirmOpen"
      :close="handleModalConfirmClose"
    />
  </TairoModal>
</template>
<style>
.v-overlay {
  z-index: 10001 !important;
}

/* Income form inputs */
.income .inc-outer {
  margin-bottom: 0 !important;
}
.income .inc-part-outer {
  width: 150px !important;
}
.income .inc-label label,
.income .inc-outer [data-type] label,
.income [class*='formkit-label'] {
  font-size: 11px !important;
  font-weight: 500;
  margin-bottom: 2px !important;
}
.income .inc-input input,
.income .inc-input textarea {
  height: 32px;
  font-size: 12px;
}

/* Parts table layout */
.inc-table-head {
  display: flex;
  align-items: center;
}
.inc-col-label {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #9ca3af;
}
.inc-row {
  display: flex;
  align-items: flex-start;
}
.inc-add-btn {
  height: 28px !important;
  font-size: 12px !important;
  padding: 0 10px !important;
}

/* Row +/- buttons */
.inc-row-btn {
  width: 22px;
  height: 22px;
  line-height: 1;
  border-radius: 4px;
  font-size: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #e5e7eb;
  color: #374151;
  border: none;
  cursor: pointer;
  transition: background 0.15s;
}
.inc-row-btn:hover {
  background: #d1d5db;
}
.inc-row-btn-danger {
  background: #fee2e2;
  color: #dc2626;
}
.inc-row-btn-danger:hover {
  background: #fecaca;
}

.income .text-danger-500 {
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
