<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { isProxy, onMounted, ref, toRaw } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
// import { Calendar } from 'v-calendar'
// import AssetDropdown from "~/components/assets/AssetDropdown.vue";

import NestedDraggable from '~/components/assets/Nested.vue'

const { getItems, updateItem } = useDirectusItems()
const { t } = useI18n({ useScope: 'global' })

const user = useDirectusUser()
const loading = ref(true)
const refreshKey = ref(0)
const records = ref([])
const max_depth = 5
const movingItem = ref({})

const props = withDefaults(
  defineProps<{
    location: Number
    parent: Number
    is_more_click?: Boolean
  }>(),
  {
    is_more_click: false,
  },
)

const field_build = () => {
  let fields = []
  fields.push('id, name', 'description', 'asset_code', 'warranty_finish_date')
  for (let i = 0; i <= max_depth; i++) {
    const joined_string = Array.from({ length: i }, () => 'children').join('.')
    fields.push(
      [
        joined_string.concat('.id'),
        joined_string.concat('.name'),
        joined_string.concat('.description'),
        joined_string.concat('.asset_code'),
        joined_string.concat('.warranty_finish_date'),
      ].join(','),
    )
  }
  return fields
}

const findParent = async (records, targetId, parent = null) => {
  console.log(records.length)
  for (let record of records) {
    console.log(record)
    if (targetId && record.id.toString() === targetId.toString()) {
      return parent
    }

    if (record.children && record.children.length > 0) {
      const foundParent = await findParent(
        record.children,
        targetId,
        (parent = record),
      )
      console.log('Found parent : ', foundParent)
      if (foundParent) {
        return foundParent
      }
    }
  }
  return null
}

const loadItems = async ({}) => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      parent: {
        _null: true,
      },
    }
    if (props.location) {
      filters['location'] = props.location
    }
    if (props.parent) {
      filters['parent'] = props.parent
    }
    const fields = field_build()
    const items = await getItems<Assets>({
      collection: 'Assets',
      params: withCompanyFilter({
        filter: filters,
        limit: -1,
        meta: 'filter_count',
        fields: fields,
      }),
    })

    // console.log('telmen', items.data);

    records.value = items.data.map((item) => ({
      ...item,
      is_more_click: props.is_more_click,
    }))

    // records.value = items.data
    // console.log('telmen-1', records);
    loading.value = false
  } catch (e) {}
}

onMounted(async () => {
  await loadItems({})
})

const changeEvent = (event) => {
  setTimeout(async () => {
    let moving_object = event.item._underlying_vm_
    movingItem.value = moving_object
    let parent = null
    let rawData = []
    if (isProxy(records.value)) {
      rawData = toRaw(records.value)
    }
    console.log(rawData)
    parent = await findParent(rawData, moving_object.id, (parent = parent))
    console.log('My found parent : ', parent)
    if (parent) {
      const data = {
        collection: 'Assets',
        id: moving_object.id,
        item: {
          parent: parent.id,
        },
      }
      await updateItem(data)
    } else {
      const data = {
        collection: 'Assets',
        id: moving_object.id,
        item: {
          parent: null,
        },
      }
      await updateItem(data)
    }
  }, 1200)
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12 child-table">
        <!-- <TairoContentWrapper>
          <BaseInput
            icon="lucide:search"
            shape="curved"
            placeholder="Filter assets..."
            :classes="{
              wrapper: 'flex justify-end mb-[20px]',
            }"
          />
        </TairoContentWrapper> -->
        <BaseCard shape="rounded">
          <div class="flex w-full">
            <div
              class="grid grid-cols-4 w-full p-3 bg-gray-100 dark:bg-gray-700 border-b border-gray-300 text-left"
            >
              <div>
                <BaseHeading
                  tag="h3"
                  size="sm"
                  weight="medium"
                  class="text-muted-800 dark:text-muted-100"
                >
                  {{ t('Asset Code') }}
                </BaseHeading>
              </div>
              <div class="ml--5">
                <BaseHeading
                  tag="h3"
                  size="sm"
                  weight="medium"
                  class="text-muted-800 dark:text-muted-100"
                >
                  {{ t('Asset Name') }}
                </BaseHeading>
              </div>
              <div class="ml--5">
                <BaseHeading
                  tag="h3"
                  size="sm"
                  weight="medium"
                  class="text-muted-800 dark:text-muted-100"
                >
                  {{ t('Asset Description') }}
                </BaseHeading>
              </div>
              <div class="ml--5">
                <BaseHeading
                  tag="h3"
                  size="sm"
                  weight="medium"
                  class="text-muted-800 dark:text-muted-100"
                >
                  {{ t('Warranty Finish Date') }}
                </BaseHeading>
              </div>
            </div>
          </div>
          <nested-draggable
            :children="records"
            :is_child="false"
            @change="changeEvent"
          />
        </BaseCard>
      </div>
    </div>
  </div>
</template>
