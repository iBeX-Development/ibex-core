<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import ModalAssetsList from '~/components/workorder/ModalAssetsList.vue'

const { t } = useI18n({ useScope: 'global' })
const { createItems, updateItem, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const config = useRuntimeConfig()
const { params } = useRoute()

const runtimeConfig = useRuntimeConfig()
const serverItems = ref([])
const loading = ref(false)
const uploadedFiles = ref([])

const { token } = useDirectusToken()
const route = useRoute()
const toaster = useToaster()
const router = useRouter()
const isModalAssetOpen = ref(false)
const asset = ref({
  id: null,
  name: '',
})

// Байршлын ID-г route-оос авах: :location, :id, эсвэл идэвхтэй route-ийн location параметр
// route.params үргэлж string байдаг тул Number-т хөрвүүлнэ
const locationId = computed(() => {
  const raw = params.location || params.id || route.params.location
  return raw ? Number(raw) : null
})
// autocomplete2-д нэрээр нь харуулахын тулд {id, name} хэлбэрт татаж авна
const locationOption = ref(null)

const fetchLocationOption = async () => {
  if (!locationId.value) return
  try {
    const items = await getItems({
      collection: 'Location',
      params: {
        filter: { id: locationId.value },
        fields: ['id', 'name'],
        limit: 1,
      },
    })
    locationOption.value = items?.[0] || null
    console.log(
      'Fetching locationOption ',
      locationOption.value,
      items,
      locationId.value,
    )
  } catch (error) {
    console.error('Error fetching location option:', error)
  }
}

const props = defineProps({
  open: Boolean,
  close: Function,
  refresh: Function,
  title: String,
  code: String,
  row: Number,
  fields: String,
  location: Number,
  redirect: String,
})

const submitHandler = async (values) => {
  toaster.clearAll()
  if (uploadedFiles.value && uploadedFiles.value.length > 0) {
    const fileIds = uploadedFiles.value.map((file) => file.id)
    values.file = uploadedFiles.value[uploadedFiles.value.length - 1].id

    // values.files = uploadedFiles.value.map((file) => ({
    //   id: file.id,
    // }))
  }

  // if (values.parent && values.parent?.id) {
  //   values.parent = values.parent?.id
  // } else {
  //   values.parent = null
  // }

  if (values.parent) {
    values.parent = asset.value.id
  } else {
    values.parent = null
  }
  if (values.manufacturer) {
    values.manufacturer = values.manufacturer.id
  }
  if (values.reading_type && typeof values.reading_type === 'object') {
    values.reading_type = values.reading_type.id
  } else if (!values.reading_type || values.reading_type === '') {
    values.reading_type = null
  }

  if (values.department) {
    values.department = values.department.id
  }
  if (values.location) {
    values.location = values.location.id
  }
  if (values.assigned_user) {
    values.assigned_user = values.assigned_user.id
  }
  if (values.asset_type && typeof values.asset_type === 'object') {
    values.asset_type = values.asset_type.id
  } else if (!values.asset_type || values.asset_type === '') {
    values.asset_type = null
  }

  // Convert empty strings to null for numeric fields
  if (values.available_hour === '') {
    values.available_hour = null
  }
  if (values.purchase_cost === '') {
    values.purchase_cost = null
  }

  if (values.status == 2) {
    values.status = 0
  } else values.status = 1

  let items = [{ ...values, company_id: myCompanyId }]
  if (props.row === -1) {
    console.log('Item creating ...')

    try {
      const res = await createItems({ collection: props.code, items })

      toaster.show({
        title: t('Added'),
        message: t(`Record created successfully`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
        duration: 1000,
      })
    } catch (error) {
      toaster.show({
        title: t('Error'),
        message: 'Field type!',
        color: 'Error',
        icon: 'ph:user-circle-fill',
        closable: true,
        duration: 1000,
      })
      console.log('Error add item:', error)
    }
  } else {
    const data = {
      collection: props.code,
      id: props.row,
      item: values,
    }

    try {
      console.log('submitHandler_hello', data)
      // return
      const res = await updateItem(data)
      toaster.show({
        title: t('Updated'),
        message: t(`Record updated successfully`) + '!',
        color: 'success',
        icon: 'ph:user-circle-fill',
        closable: true,
        duration: 1000,
      })
    } catch (error) {
      toaster.show({
        title: t('Error'),
        message: 'Field type!',
        color: 'Error',
        icon: 'ph:user-circle-fill',
        closable: true,
        duration: 1000,
      })
      console.log('Error update item:', error)
    }
  }

  if (typeof props.refresh === 'function') {
    console.log('Props refresh running...')

    props.refresh()
  }

  if (props.close) {
    props.close()
  }

  if (props.row === -1) {
    router.push(`/asset/location/${locationId.value}`)
  }
}

const get_content_url = (file) => {
  if (file?.type?.includes('image')) {
    return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
  } else {
    return ''
  }
}

const fetchData = async () => {
  try {
    if (props.row !== -1) {
      const filters = { id: props.row }
      const items = await getItems({
        collection: 'Assets',
        params: withCompanyFilter({
          filter: filters,
          meta: 'filter_count',
          fields: [
            '*',
            'children.*',
            'file.*',
            'files.*',
            'parent.id',
            'parent.name',
            'location.id',
            'location.name',
            'manufacturer.id',
            'manufacturer.name',
            'department.*',
            'reading_type.*',
            'asset_type.*',
            'assigned_user.id',
            'assigned_user.first_name',
            'assigned_user.last_name',
          ],
        }),
      })

      if (items?.data?.[0]) {
        console.log('items.data[0]', items.data[0])
        serverItems.value = items.data[0]

        serverItems.value.warranty_start_date = new Date(
          items.data[0].warranty_start_date,
        )
          .toISOString()
          .split('T')[0]

        serverItems.value.warranty_finish_date = new Date(
          items.data[0].warranty_finish_date,
        )
          .toISOString()
          .split('T')[0]

        serverItems.value.inspection_done_date = new Date(
          items.data[0].inspection_done_date,
        )
          .toISOString()
          .split('T')[0]

        serverItems.value.inspection_next_due_date = new Date(
          items.data[0].inspection_next_due_date,
        )
          .toISOString()
          .split('T')[0]

        if (serverItems.value.parent) {
          asset.value = serverItems.value.parent
        }

        if (serverItems.value.assigned_user) {
          serverItems.value.assigned_user.full_name = `${
            serverItems.value.assigned_user.first_name || ''
          } ${serverItems.value.assigned_user.last_name || ''}`.trim()
        }
      }
    }
    loading.value = false
  } catch (error) {
    console.error('Error fetching data:', error)
  }
}
const handleModalAssetClose = () => {
  isModalAssetOpen.value = false
}
const setAsset = (obj: any) => {
  asset.value = obj
  // serverItems.parent = obj
  // console.log('setAsset', obj)
}
onMounted(async () => {
  if (props.row !== -1) {
    loading.value = true
    await fetchData()
  } else {
    await fetchLocationOption()
  }
})
</script>

<template>
  <BaseCard
    color="default"
    rounded="md"
    class="assetmore p-10 nui-bg-white shadow-lg"
  >
    <div v-if="loading && props.row !== -1">Loading...</div>

    <FormKit
      v-else
      type="form"
      :actions="true"
      :submit-label="t('Save')"
      @submit="submitHandler"
      :submit-attrs="{
        inputClass:
          'text-sm px-10 mt-5 py-3 rounded bg-primary-500 dark:bg-primary-500 text-white hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400',
        ignore: false,
      }"
    >
      <div class="asset-grid grid grid-cols-2 gap-4 mb-5">
        <div>
          <FormKit
            name="asset_code"
            type="text"
            :label="t('Asset Code')"
            :validation="'required'"
            class="text-lg"
            :value="serverItems?.asset_code || ''"
          />
          <FormKit
            name="name"
            type="text"
            :label="t('Name')"
            :validation="'required'"
            class="text-lg"
            :value="serverItems?.name || ''"
          />
          <FormKit
            name="status"
            type="select"
            :label="t('Status')"
            class="text-lg"
            :options="[
              { label: 'Enabled', value: 1 },
              { label: 'Disabled', value: 2 },
            ]"
            :value="serverItems?.status || ''"
          />

          <FormKit
            name="location"
            type="autocomplete2"
            collection_name="Location"
            :label="t('Location')"
            item_value="id"
            item_title="name"
            search_field="name"
            :validation="'required'"
            :value="props.row !== -1 ? serverItems?.location : locationOption"
            :initial_filter="{ company_id: myCompanyId }"
          />
          <FormKit
            name="assigned_user"
            type="autocomplete2"
            collection_name="users"
            :label="t('Assigned user')"
            item_value="id"
            item_title="full_name"
            search_field="full_name"
            :placeholder="t('Choose a user')"
            :value="serverItems?.assigned_user || null"
            :initial_filter="{ company_id: myCompanyId }"
          />
        </div>

        <div
          class="h-72 mt-3.5 border-2 border-dashed rounded-lg flex items-center justify-center"
        >
          <FileUpload
            :plus="false"
            :result="uploadedFiles"
            :imageH="'284px'"
            :imageW="'100%'"
            :emptyStyle="'width: 250px; margin: 30px auto;'"
            :style="'height: 284px; width: 100%;'"
            :xstyle="'justify-content: flex-end;  margin: -9px -32px 0px -20px;'"
            :fileUrl="get_content_url(serverItems?.file)"
          />
        </div>
      </div>

      <div class="mb-5 custom-safety-note-wrapper">
        <FormKit
          name="description"
          type="textarea"
          :label="t('Description')"
          rows="3"
          class="text-lg"
          :value="serverItems?.description || ''"
        />
      </div>

      <div class="mb-5 custom-safety-note-wrapper">
        <FormKit
          name="safety_notes"
          type="textarea"
          :label="t('Safety Notes')"
          rows="2"
          class="text-lg"
          :value="serverItems?.safety_notes || ''"
        />
      </div>

      <div class="grid grid-cols-2 gap-4 mb-5">
        <FormKit
          name="manufacturer"
          type="autocomplete2"
          collection_name="Manufacturer"
          :label="t('Manufacturer')"
          item_value="id"
          item_title="name"
          search_field="name"
          :validation="'required'"
          :value="serverItems?.manufacturer || ''"
          :initial_filter="{ company_id: myCompanyId }"
        />
        <FormKit
          name="department"
          type="autocomplete2"
          collection_name="Department"
          :label="t('Department')"
          item_value="id"
          item_title="name"
          search_field="name"
          :validation="'required'"
          :value="serverItems?.department || ''"
          :initial_filter="{ company_id: myCompanyId }"
        />
        <FormKit
          name="reading_type"
          type="autocomplete2"
          collection_name="Reading_type"
          :label="t('Reading Type')"
          item_value="id"
          item_title="description"
          search_field="description"
          :validation="'required'"
          :value="serverItems?.reading_type || null"
          :initial_filter="{ status: 'published' }"
          :no_company_filter="true"
        />

        <div class="flex">
          <FormKit
            name="parent"
            type="autocomplete2"
            collection_name="Assets"
            :label="t('Parent')"
            item_value="id"
            item_title="asset_code"
            search_field="asset_code"
            v-model="asset.asset_code"
            :initial_filter="{
              status: 1,
              company_id: myCompanyId,
              location: locationId,
            }"
            :setParentValue="setAsset"
          />
          <BaseButton
            color="default"
            class="mt-5 ml-5"
            @click="isModalAssetOpen = true"
          >
            {{ t('Choose') }}
          </BaseButton>
          <FormKit v-model="asset.id" name="asset" type="hidden" />
        </div>
      </div>

      <div class="grid grid-cols-2 gap-4 mb-5">
        <FormKit
          name="model_number"
          type="text"
          :label="t('Model Number')"
          class="text-lg"
          :value="serverItems?.model_number || ''"
        />
        <FormKit
          name="serial_number"
          type="text"
          :label="t('Serial Number')"
          class="text-lg"
          :value="serverItems?.serial_number || ''"
        />
        <FormKit
          name="barcode"
          type="text"
          :label="t('Barcode')"
          class="text-lg"
          :value="serverItems?.barcode || ''"
        />
        <FormKit
          name="available_hour"
          type="text"
          :label="t('Available Hour')"
          class="text-lg"
          :value="serverItems?.available_hour || ''"
        />
      </div>

      <div class="grid grid-cols-2 gap-4 mb-5">
        <FormKit
          name="asset_type"
          type="autocomplete2"
          collection_name="Asset_type"
          :label="t('Asset Type')"
          item_value="id"
          item_title="name"
          search_field="name"
          :value="serverItems?.asset_type || null"
          :initial_filter="{ status: '1' }"
          :no_company_filter="true"
        />
        <FormKit
          name="purchase_cost"
          type="text"
          :label="t('Purchase Cost')"
          class="text-lg"
          :value="serverItems?.purchase_cost || ''"
        />
      </div>

      <div class="grid grid-cols-2 gap-4 mb-5">
        <FormKit
          name="warranty_start_date"
          type="date"
          :label="t('Warranty Start Date')"
          class="text-lg"
          :value="
            serverItems?.warranty_start_date ||
            new Date().toISOString().split('T')[0]
          "
        />
        <FormKit
          name="warranty_finish_date"
          type="date"
          :label="t('Warranty Finish Date')"
          class="text-lg"
          :value="
            serverItems?.warranty_finish_date ||
            new Date().toISOString().split('T')[0]
          "
        />
        <FormKit
          name="inspection_done_date"
          type="date"
          :label="t('Inspection Done Date')"
          class="text-lg"
          :value="
            serverItems?.inspection_done_date ||
            new Date().toISOString().split('T')[0]
          "
        />
        <FormKit
          name="inspection_next_due_date"
          type="date"
          :label="t('Inspection Next Due Date')"
          class="text-lg"
          :value="
            serverItems?.inspection_next_due_date ||
            new Date().toISOString().split('T')[0]
          "
        />
      </div>
    </FormKit>

    <ModalAssetsList
      :open="isModalAssetOpen"
      :close="handleModalAssetClose"
      :setAsset="setAsset"
      :location="locationId"
    />
  </BaseCard>
</template>

<style scoped>
.dark .assetmore span {
  color: white;
}

.dark .assetmore .vs--disabled .vs__dropdown-toggle,
.dark .assetmore .vs--disabled .vs__clear,
.dark .assetmore .vs--disabled .vs__search,
.dark .assetmore .vs--disabled .vs__selected,
.dark .assetmore .vs--disabled .vs__open-indicator {
  background-color: unset !important;
}
.custom-safety-note-wrapper .max-w-md {
  max-width: none !important;
  width: 100% !important;
}
</style>
