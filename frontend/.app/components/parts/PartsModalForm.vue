<template>
  <!-- New & Edit modal -->
  <TairoModal
    :key="props.key"
    :open="props.open"
    :size="props.size"
    @close="close"
  >
    <template #header>
      <!-- Header -->
      <div class="flex w-full items-center justify-between p-2 md:p-2">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white pl-8"
        >
          {{ t(title) }}
        </h3>
        <BaseButtonClose @click="close" />
      </div>
    </template>

    <!-- Body -->
    <div class="mx-auto w-full max-h-[580px] h-auto overflow-y-auto px-10">
      <FormKit
        type="form"
        :actions="true"
        :submit-label="t('Save')"
        @submit="submitHandler"
        :submit-attrs="{
          inputClass:
            'text-sm px-10 mt-5 mb-10 py-3 is-button rounded bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
          ignore: false,
        }"
      >
        <div>
          <!-- ITEM Number and Description -->
          <div class="grid grid-cols-2 gap-4 mb-5">
            <div>
              <FormKit
                name="part_number"
                type="text"
                label="ITEM Number:"
                :validation="'required'"
                v-model="numbering"
              />
              <FormKit
                name="description"
                type="textarea"
                label="ITEM DESCRIPTION:"
                :validation="'required'"
                rows="4"
                v-model="item_description"
              />
            </div>
            <!-- Placeholder for the image upload -->
            <FileUpload
              field="picture"
              :plus="false"
              :fileUrl="pictureUrl"
              :imageH="'184px'"
              :imageW="'184px'"
              :style="'height: 184px; width: 184px;'"
              :imgParentstyle="'height: 184px; width: 184px;margin:30px 50px 0px 90px;'"
              :xstyle="'justify-content: flex-end;  margin: -193px -10px 0px 0px;'"
              :buttonStyle="'display:flex;justify-content: center;  margin-top: 20px;'"
            />
          </div>
          <!-- Segment, Family, Class, Commodity -->
          <div class="grid grid-cols-2 gap-4 mb-5">
            <FormKit
              name="segment"
              type="autocomplete2"
              collection_name="Segment"
              label="Segment"
              item_title="description"
              item_value="id"
              search="description"
              search_field="description"
              search_integer="codec"
              loading="loading"
              v-model="segment"
              :initial_filter="{
                status: 1,
              }"
              :no_company_filter="true"
            />
            <FormKit
              name="family"
              type="autocomplete2"
              collection_name="Family"
              label="Family"
              item_title="description"
              item_value="id"
              search="description"
              search_field="description"
              search_integer="codec"
              loading="loading"
              v-model="family"
              :initial_filter="{
                status: 1,
              }"
              :no_company_filter="true"
            />
            <FormKit
              name="class"
              type="autocomplete2"
              collection_name="Class"
              label="Class"
              item_title="description"
              item_value="id"
              search="description"
              search_field="description"
              search_integer="codec"
              loading="loading"
              v-model="_class"
              :initial_filter="{
                status: 1,
              }"
              :no_company_filter="true"
            />
            <FormKit
              name="commodity"
              type="autocomplete2"
              collection_name="Commodity"
              label="Commodity"
              item_value="id"
              item_title="description"
              search_field="description"
              search_integer="codec"
              loading="loading"
              :setParentValue="setCommodity"
              v-model="commodity"
              :initial_filter="{
                status: 1,
              }"
              :no_company_filter="true"
              :min_search_length="3"
            />
            <FormKit
              name="uom"
              type="autocomplete2"
              collection_name="uom"
              label="Unit of measure"
              item_value="id"
              item_title="description"
              search_field="description"
              v-model="parts_row.uom"
              :initial_filter="{
                active: '1',
              }"
              :no_company_filter="true"
              :min_search_length="3"
            />
            <FormKit
              name="price"
              type="number"
              label="Price:"
              v-model="parts_row.price"
            />
          </div>

          <!-- Item Information -->
          <div class="grid grid-cols-2 gap-4 mb-5">
            <FormKit
              name="name"
              type="text"
              label="Item Name:"
              v-model="parts_row.name"
              validation="required"
            />
            <FormKit
              name="mongolian_name"
              type="text"
              label="ITEM Mongolian name:"
              v-model="parts_row.mongolian_name"
              validation="required"
            />
            <FormKit
              name="manufacturer"
              type="text"
              label="Manufacturer"
              v-model="parts_row.manufacturer"
            />
            <FormKit
              name="model_no"
              type="text"
              label="Model No:"
              v-model="parts_row.model_no"
              validation="required"
            />
            <FormKit
              name="serial_no"
              type="text"
              label="Serial No:"
              v-model="parts_row.serial_no"
            />
            <FormKit
              name="material"
              type="text"
              label="Material:"
              v-model="parts_row.material"
            />
          </div>
          <FormKit
            name="technical_data"
            type="textarea"
            label="Technical data:"
            rows="3"
            v-model="parts_row.technical_data"
            validation="required"
          />
          <FormKit
            name="special_information"
            type="textarea"
            label="Special information:"
            rows="3"
            v-model="parts_row.special_information"
          />
          <!-- User Defined Fields -->
          <div class="grid grid-cols-2 gap-3 mb-5">
            <div>
              <FormKit
                name="user_defined_1"
                type="text"
                label="USER Defined 1:"
                class="pr-5"
                :disabled="user_defined1"
                v-model="parts_row.user_defined_1"
              />
            </div>
            <div>
              <br />
              <BaseCheckbox
                label="Check to include in the description section"
                rounded="none"
                color="success"
                v-model="user_defined1"
              />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-3 mb-5">
            <div>
              <FormKit
                name="user_defined_2"
                type="text"
                label="USER Defined 2:"
                class="pr-5"
                :disabled="user_defined2"
                v-model="parts_row.user_defined_2"
              />
            </div>
            <div>
              <br />
              <BaseCheckbox
                label="Check to include in the description section"
                rounded="none"
                color="success"
                v-model="user_defined2"
              />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-3 mb-5">
            <div>
              <FormKit
                name="user_defined_3"
                type="text"
                label="USER Defined 3:"
                class="pr-5"
                :disabled="user_defined3"
                v-model="parts_row.user_defined_3"
              />
            </div>
            <div>
              <br />
              <BaseCheckbox
                label="Check to include in the description section"
                rounded="none"
                color="success"
                v-model="user_defined3"
              />
            </div>
          </div>
        </div>
      </FormKit>
    </div>
  </TairoModal>
</template>

<script setup>
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

import { ref, watch } from 'vue'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
const { token } = useDirectusToken()
const route = useRoute()

const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()
const segment = ref('')
const family = ref('')
const _class = ref('')
const commodity = ref('')
const numbering = ref('')
const item_description = ref('')
const pictureUrl = ref(null)
const user_defined1 = ref(true)
const user_defined2 = ref(true)
const user_defined3 = ref(true)
const parts_row = reactive({
  name: '',
  mongolian_name: '',
  manufacturer: '',
  model_no: '',
  serial_no: '',
  material: '',
  technical_data: '',
  special_information: '',
  user_defined_1: '',
  user_defined_2: '',
  user_defined_3: '',
  uom: '',
  price: 0,
})

const props = defineProps({
  open: Boolean,
  title: String,
  close: Function,
  refresh: Function,
  row: Number,
  code: String,
})

const resetForm = () => {
  segment.value = ''
  family.value = ''
  _class.value = ''
  commodity.value = ''
  numbering.value = ''
  item_description.value = ''
  pictureUrl.value = null
  user_defined1.value = true
  user_defined2.value = true
  user_defined3.value = true
  parts_row.name = ''
  parts_row.mongolian_name = ''
  parts_row.manufacturer = ''
  parts_row.model_no = ''
  parts_row.serial_no = ''
  parts_row.material = ''
  parts_row.technical_data = ''
  parts_row.special_information = ''
  parts_row.user_defined_1 = ''
  parts_row.user_defined_2 = ''
  parts_row.user_defined_3 = ''
  parts_row.uom = ''
  parts_row.price = 0
}

const loadRow = async () => {
  await getItems({
    collection: props.code,
    params: {
      filter: { id: props.row },
      limit: 1,
      meta: 'filter_count',
      fields: [
        '*',
        'segment.*',
        'family.*',
        'class.*',
        'commodity.*',
        'uom.*',
        'picture.*',
      ],
    },
  }).then((res) => {
    if (res.data[0]) {
      parts_row.value = res.data[0]
      numbering.value = res.data[0].part_number
      segment.value = res.data[0].segment
      family.value = res.data[0].family
      _class.value = res.data[0].class
      commodity.value = res.data[0].commodity
      item_description.value = res.data[0].description
      if (res.data[0].user_defined_1) {
        user_defined1.value = false
      }
      if (res.data[0].user_defined_2) {
        user_defined2.value = false
      }
      if (res.data[0].user_defined_3) {
        user_defined3.value = false
      }
      parts_row.name = res.data[0].name
      parts_row.mongolian_name = res.data[0].mongolian_name
      parts_row.manufacturer = res.data[0].manufacturer
      parts_row.model_no = res.data[0].model_no
      parts_row.serial_no = res.data[0].serial_no
      parts_row.material = res.data[0].material
      parts_row.technical_data = res.data[0].technical_data
      parts_row.special_information = res.data[0].special_information
      parts_row.user_defined_1 = res.data[0].user_defined_1
      parts_row.user_defined_2 = res.data[0].user_defined_2
      parts_row.user_defined_3 = res.data[0].user_defined_3
      parts_row.uom = res.data[0].uom
      parts_row.price = res.data[0].price

      // Existing picture URL for preview
      if (res.data[0].picture?.id) {
        pictureUrl.value =
          runtimeConfig.public.directus.url + 'assets/' + res.data[0].picture.id
      }
    }
  })
}

onMounted(async () => {
  if (props.row && props.row !== -1) {
    await loadRow()
  } else {
    resetForm()
  }
})

// Modal дахин нээгдэх бүрд (parent талын :key нь shine/shine "-1" хооронд
// солигдоогүй тохиолдолд ч) өмнөх сессийн өгөгдлийг арилгах/шинээр ачаалах
watch(
  () => props.open,
  (isOpen) => {
    if (!isOpen) return
    if (props.row && props.row !== -1) {
      loadRow()
    } else {
      resetForm()
    }
  },
)

const generateNumber = async (codec) => {
  try {
    console.log(token.value, codec)
    let url =
      runtimeConfig.public.directus.url + `db/generate_number/?codec=${codec}`
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token.value}`,
      },
    })
    const jsonData = await response.json()
    numbering.value =
      jsonData.codec + jsonData.number.toString().padStart(3, '0')
  } catch (error) {
    console.error('Error fetching data:', error)
  }
}

const setItem = async (collection) => {
  if (commodity && commodity.value && commodity?.value.codec?.length > 0) {
    const filters = {}
    if (collection === 'segment') {
      filters['codec'] = commodity?.value.codec.slice(0, 2) + '000000'
    }
    if (collection === 'family') {
      filters['codec'] = commodity?.value.codec.slice(0, 4) + '0000'
    }
    if (collection === 'class') {
      filters['codec'] = commodity?.value.codec.slice(0, 6) + '00'
    }
    const items = await getItems({
      collection: collection.charAt(0).toUpperCase() + collection.slice(1),
      params: {
        filter: filters,
        limit: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    if (collection === 'segment') {
      segment.value = items.data[0]
    }
    if (collection === 'family') {
      family.value = items.data[0]
    }
    if (collection === 'class') {
      _class.value = items.data[0]
    }
  }
}

const setCommodity = async (_commodity) => {
  console.log('_commodity')
  console.log(_commodity)
  commodity.value = _commodity
  await setItem('segment')
  await setItem('family')
  await setItem('class')
  await generateNumber(_commodity?.codec)
  // item_description.value = numbering.value + ' ' + segment?.value.description + ' ' +
  //  family?.value.description + ' ' + _class?.value.description + ' ' + commodity?.value.description;
}

watch(parts_row, async (new_parts_row) => {
  // console.log(new_parts_row)
  if (new_parts_row) {
    if (new_parts_row.name) {
      let name = new_parts_row.name ? new_parts_row.name : ''
      let mongolian_name = new_parts_row.mongolian_name
        ? new_parts_row.mongolian_name
        : ''
      let model_no = new_parts_row.model_no ? new_parts_row.model_no : ''
      let technical_data = new_parts_row.technical_data
        ? new_parts_row.technical_data
        : ''
      let user_defined_1 = new_parts_row.user_defined_1
        ? new_parts_row.user_defined_1
        : ''
      let user_defined_2 = new_parts_row.user_defined_2
        ? new_parts_row.user_defined_2
        : ''
      let user_defined_3 = new_parts_row.user_defined_3
        ? new_parts_row.user_defined_3
        : ''
      item_description.value =
        name +
        ' ' +
        mongolian_name +
        ' ' +
        model_no +
        ' ' +
        technical_data +
        ' ' +
        user_defined_1 +
        ' ' +
        user_defined_2 +
        ' ' +
        user_defined_3
    }
  }
})

const submitHandler = async (values) => {
  console.log(values)
  values['active'] = 1
  //do something with the form data

  console.log(props, props.row)
  toaster.clearAll()
  values['segment'] =
    values['segment'] && values['segment'].id ? values['segment'].id : null
  values['family'] =
    values['family'] && values['family'].id ? values['family'].id : null
  values['class'] =
    values['class'] && values['class'].id ? values['class'].id : null
  console.log(values['commodity'])
  values['commodity'] =
    values['commodity'] && values['commodity'].id
      ? values['commodity'].id
      : null
  values['uom'] = values['uom'] && values['uom'].id ? values['uom'].id : null
  if (values.picture && values.picture.length > 0 && values.picture[0]) {
    values['picture'] = values.picture[0]
  } else {
    delete values['picture']
  }
  let items = [{ ...values, company_id: myCompanyId }]
  console.log(items)
  if (props.row === -1) {
    console.log('Item creating ...')
    await createItems({ collection: props.code, items })
    toaster.show({
      title: t('Added'),
      message: t(`Record created successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  } else {
    console.log('Item updateding ...')
    const data = {
      collection: props.code,
      id: props.row,
      item: values,
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
}
</script>
<style>
.v-overlay {
  z-index: 10001 !important;
}
</style>
