<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
import TemplateNestedDraggable from '~/components/template/TemplateNested.vue'
const { getItems } = useDirectusItems()
const { t } = useI18n({ useScope: 'global' })

const user = useDirectusUser()

const loading = ref(true)
const records = ref([])
const max_depth = 5

const key = ref(11)
const props = defineProps(['refresh', 'code'])

const field_build = () => {
  let fields = []
  fields.push(
    'id, name, pos, data_label, template_type.code, template.id, template_type.name',
  )
  for (let i = 0; i <= max_depth; i++) {
    const joined_string = Array.from({ length: i }, () => 'children').join('.')
    if (joined_string != '')
      fields.push(
        [
          joined_string.concat('.id'),
          joined_string.concat('.name'),
          joined_string.concat('.pos'),
          joined_string.concat('.data_label'),
          joined_string.concat('.template_type.code'),
          joined_string.concat('.template.id'),
          joined_string.concat('.template_type.name'),
        ].join(','),
      )
  }
  return fields
}

const loadItems = async () => {
  loading.value = true
  try {
    const filters = {
      status: 'published',
      parent: {
        _null: true,
      },
      template: props.code,
    }
    const fields = field_build()
    const items = await getItems<any>({
      collection: 'Template_header',
      params: {
        filter: filters,
        limit: -1,
        meta: 'filter_count',
        fields: fields,
        sort: 'pos',
      },
    })

    console.log(items)
    records.value = items.data.sort(
      (a, b) => (a.pos ?? Infinity) - (b.pos ?? Infinity),
    )
    loading.value = false
  } catch (e) {}
}

onMounted(async () => {
  await loadItems()
})

const handleRefresh = async () => {
  await loadItems()
  if (props.refresh) props.refresh()
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12">
      <!-- Header -->
      <div class="col-span-12">
        <BaseCard shape="rounded">
          <div class="flex w-full">
            <div
              class="grid grid-cols-2 w-full p-3 bg-gray-100 dark:bg-gray-700 border-b border-gray-300 text-left"
            >
              <div>
                <BaseHeading
                  tag="h3"
                  size="sm"
                  weight="medium"
                  class="text-muted-800 dark:text-muted-100"
                >
                  {{ t('Task name') }}
                </BaseHeading>
              </div>
            </div>
          </div>
          <template-nested-draggable
            :children="records"
            :refresh="handleRefresh"
          />
        </BaseCard>
      </div>
    </div>
  </div>
</template>
