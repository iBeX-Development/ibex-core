<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { isProxy, onMounted, ref, toRaw } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'
import ModalItemsList from '~/components/form/ModalItemsList.vue'
import TaskTemplateChooseModalForm from '~/components/form/TaskTemplateChooseModalForm.vue'
import WorkInspectionItemNested from '~/components/inspectionitem/Nested.vue'

const { getItems, updateItem, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const user = useDirectusUser()

const loading = ref(true)
const records = ref([])
const templates = ref([])
const typeItem = ref([])
const max_depth = 5
const movingItem = ref({})
const temp_types = ref([])
const key = ref(11)

// for modal variable Declare start
const isModalOpen = ref(false)
const isModalTemplateOpen = ref(false)
const selectedItem = ref(-1)
const toaster = useToaster()
const route = useRoute()

const props = defineProps([
  'refresh',
  'code',
  'progress',
  'freeze',
  'loadTasks',
  'TempTypes',
  'progressData',
  'changePos',
])
const { t } = useI18n({ useScope: 'global' })

const field_build = () => {
  let fields = []
  fields.push(
    'id, name, status',
    'active',
    'request_info',
    'template_type.code',
    'template_type.name',
    'template_type.id',
    'value',
    'parent',
    'workorder',
    'created_type',
    'pos',
    'photos.directus_files_id.*',
  )
  for (let i = 0; i <= max_depth; i++) {
    const joined_string = Array.from({ length: i }, () => 'children').join('.')
    if (joined_string != '')
      fields.push(
        [
          joined_string.concat('.id'),
          joined_string.concat('.name'),
          joined_string.concat('.pos'),
          joined_string.concat('.status'),
          joined_string.concat('.active'),
          joined_string.concat('.template_type.code'),
          joined_string.concat('.template_type.name'),
          joined_string.concat('.template_type.id'),
          joined_string.concat('.value'),
          joined_string.concat('.parent'),
          joined_string.concat('.workorder'),
          joined_string.concat('.created_type'),
          joined_string.concat('.photos.directus_files_id.*'),
        ].join(','),
      )
  }
  return fields
}

const emit = defineEmits(['update:loadTasks'])

const findParent = async (records, targetId, parent = null) => {
  // console.log(records.length)
  for (let record of records) {
    // console.log(record)
    if (targetId && record.id.toString() === targetId.toString()) {
      return parent
    }

    if (record.children && record.children.length > 0) {
      const foundParent = await findParent(
        record.children,
        targetId,
        (parent = record),
      )
      // console.log('Found parent : ', foundParent)
      if (foundParent) {
        return foundParent
      }
    }
  }
  return null
}

function generateFilter(depth) {
  let filter = { active: { _eq: 1 } } // Үндсэн `active=1` шүүлт

  let current = filter
  for (let i = 0; i < depth; i++) {
    current.children = { active: { _eq: 1 } }
    current = current.children
  }

  return filter
}

function sortByPos(items: any[]) {
  return items
    .sort((a, b) => (a.pos ?? 0) - (b.pos ?? 0) || a.id - b.id)
    .map((item) => {
      if (item.children && item.children.length > 0) {
        item.children = sortByPos(item.children)
      }
      return item
    })
}

const loadItems = async ({}) => {
  loading.value = true
  try {
    const filters = {
      parent: {
        _null: true,
      },
      workorder: props.code,
      active: 1,
      // created_type: {
      //   _nin: ['request_info'], // Зөвхөн request_info-оос бусад утгуудыг авна
      // },
    }
    const fields = field_build()
    const items = await getItems<any>({
      collection: 'Work_inspection_item',
      params: {
        filter: filters,
        limit: -1,
        meta: 'filter_count',
        fields: fields,
        sort: ['pos', 'id'],
      },
    })
    // records.value = items.data
    records.value = sortByPos(items.data)

    console.log('component babes', items)
    emit('update:loadTasks', items.data)

    loading.value = false
  } catch (e) {}
}

const loadTypes = async () => {
  try {
    const filters = {
      enabled: true,
      code: {
        _nnull: true,
      },
    }
    const items = await getItems({
      collection: 'Template_type',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    temp_types.value = items.data
  } catch (e) {
    console.log(e)
  }
}

onMounted(async () => {
  if (props.loadTasks) {
    records.value = props.loadTasks
    loading.value = false

    // console.log('tasks-loaded', props.loadTasks)
  } else {
    await loadItems({})
  }
  // await loadTypes()
})

const handleAdd = async () => {
  isModalOpen.value = true
  console.log('handleAdd-task')
  selectedItem.value = -1
  typeItem.value = -1
}

const chooseTemplete = async () => {
  isModalTemplateOpen.value = true
}

const field_templates = () => {
  let fields = []
  fields.push('id, name, parent, data_label, template_type.*, template.id')
  for (let i = 0; i <= max_depth; i++) {
    const joined_string = Array.from({ length: i }, () => 'children').join('.')
    if (joined_string != '')
      fields.push(
        [
          joined_string.concat('.id'),
          joined_string.concat('.name'),
          joined_string.concat('.parent'),
          joined_string.concat('.data_label'),
          joined_string.concat('.template_type.*'),
          joined_string.concat('.template.id'),
        ].join(','),
      )
  }
  return fields
}

const convertTemplate = async (
  template,
  workorder,
  parentId = null,
  pos = 0,
) => {
  const addedItem = await createItems({
    collection: 'Work_inspection_item',
    items: [
      {
        status: 1,
        active: 1,
        label: 'Label',
        workorder: workorder,
        parent: parentId, // ✅ Эцэг ID-г зөв оноох
        name: template.data_label ?? template.name,
        template_type: template?.template_type?.id,
        created_type: 'user',
        company_id: myCompanyId,
        pos: pos, // ✅ Template-ийн дарааллыг хадгалж, дараа нь эрэмбийг зөв харуулах
      },
    ],
  })

  // console.log('addedItem', addedItem)

  // ✅ Шинэ үүссэн item-ийн ID-г авах
  const newItemId = Array.isArray(addedItem) ? addedItem[0]?.id : addedItem?.id

  // ✅ Хэрэв ID байхгүй бол алдаа гаргана
  if (!newItemId) {
    throw new Error('Failed to create item, no ID returned')
  }

  // ✅ Хүүхдүүдийг жинхэнэ async байдлаар боловсруулах
  const childrens =
    template.children && template.children.length > 0
      ? await Promise.all(
          template.children.map((child, childIndex) =>
            convertTemplate(child, workorder, newItemId, childIndex),
          ),
        )
      : []

  return {
    id: newItemId,
    name: template.data_label ?? template.name,
    active: 1,
    request_info: null,
    value: null,
    parent: parentId,
    workorder: workorder,
    template_type: template.template_type,
    children: childrens, // ✅ Шинээр үүссэн хүүхдүүдийг хадгалах
  }
}

const setTemplate = async (obj: any) => {
  isModalTemplateOpen.value = false

  const filters = {
    status: 'published',
    parent: {
      _null: true,
    },
    template: obj.id,
  }
  const fields_tem = field_templates()
  const items = await getItems({
    collection: 'Template_header',
    params: {
      filter: filters,
      limit: -1,
      meta: 'filter_count',
      fields: fields_tem,
      sort: 'pos',
    },
  })

  const basePos = records.value.length
  const processedTemplates = await Promise.all(
    items.data.map((template, index) =>
      convertTemplate(template, props.code, null, basePos + index),
    ),
  )
  records.value = [...records.value, ...processedTemplates]
}

const changeEvent = async (event) => {
  // console.log('Move : ', event)
  let moving_object = { id: null }

  try {
    moving_object = event.item._underlying_vm_
    // console.log('Move_2 : ', event)
  } catch (e) {
    moving_object.id = null
  }
  movingItem.value = moving_object
  let parent = null
  let rawData = []
  if (isProxy(records.value)) {
    rawData = toRaw(records.value)
  }
  // console.log('rawData_1', rawData)
  props.changePos(rawData)
  // parent = await findParent(rawData, moving_object.id, (parent = parent))
  // console.log('My found parent : ', parent)
  // console.log('My  moving_object : ', moving_object)

  //tur comment hiiw
  {
    // if (parent && moving_object.id) {
    //   // console.log('Work_inspection_item1_update:', moving_object)
    //   const data = {
    //     collection: 'Work_inspection_item',
    //     id: moving_object.id,
    //     item: {
    //       parent: parent.id,
    //     },
    //   }
    //   await updateItem(data)
    // } else {
    //   console.log('Work_inspection_item2_update : ', moving_object)
    //   const data = {
    //     collection: 'Work_inspection_item',
    //     id: moving_object.id,
    //     item: {
    //       parent: null,
    //     },
    //   }
    //   if (moving_object.id) await updateItem(data)
    // }
  }

  {
    // if (event.target.attributes?.template?.value == 'itemcheckbox') {
    //   let itemtype = event.target.attributes?.itemtype?.value
    //   let taskId = event.target.attributes.task.value
    //   if (itemtype == 'task_value') {
    //     if (taskId) {
    //       let isChecked = event.target.checked
    //       const updateData = {
    //         collection: 'Work_inspection_item',
    //         id: taskId,
    //         item: {
    //           value: isChecked ? 1 : 0,
    //         },
    //       }
    //       updateItem(updateData)
    //     }
    //   } else if (itemtype == 'task_name') {
    //     let valueInput = event.target.value
    //     const updateData = {
    //       collection: 'Work_inspection_item',
    //       id: taskId,
    //       item: {
    //         name: valueInput,
    //       },
    //     }
    //     updateItem(updateData)
    //   }
    // }
    // if (event.target.attributes?.template?.value == 'itemeditbox') {
    //   let itemtype = event.target.attributes?.itemtype?.value
    //   let taskId = event.target.attributes.task.value
    //   let valueInput = event.target.value
    //   if (itemtype == 'task_value') {
    //     const updateData = {
    //       collection: 'Work_inspection_item',
    //       id: taskId,
    //       item: {
    //         value: valueInput,
    //       },
    //     }
    //     updateItem(updateData)
    //   } else if (itemtype == 'task_name') {
    //     const updateData = {
    //       collection: 'Work_inspection_item',
    //       id: taskId,
    //       item: {
    //         name: valueInput,
    //       },
    //     }
    //     updateItem(updateData)
    //   }
    // }
  }
}

const handleAddTask = async (template_type) => {
  console.log('handleAddTask', template_type, props.code)
  if (template_type !== -1) {
    createItems({
      collection: 'Work_inspection_item',
      items: [
        {
          status: 1,
          label: 'Label',
          workorder: props.code,
          parent: null,
          name: 'Default text',
          template_type: template_type,
          created_type: 'user',
          company_id: myCompanyId,
        },
      ],
    }).then((addItem) => {
      let type = typeItem.value
      if (isProxy(typeItem.value)) {
        type = toRaw(typeItem.value)
      }
      addItem[0].template_type = type
      records.value.push(addItem[0])
      // if (props.refresh) props.refresh()
    })
  } else {
    // const toaster = useToaster()
    // toaster.show({
    //   title: t('Failed'),
    //   message: t(`Task creation failed please fill template type`) + '!',
    //   color: 'failed',
    //   icon: 'ph:user-circle-fill',
    //   closable: true,
    // })
  }
}

const handleModalOpen = (parent_id) => {
  selectedItem.value = -1
  typeItem.value = -1
  isModalOpen.value = true
  console.log(isModalOpen.value)
  console.log(parent_id)
  parent.value = parent_id
}

const handleModalClose = () => {
  isModalOpen.value = false
  isModalTemplateOpen.value = false

  if (selectedItem.value) {
    // Here is create task
    handleAddTask(selectedItem.value)
  }
}

const handleChangeRow = (row_value, item) => {
  selectedItem.value = row_value
  typeItem.value = item
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

// for modal variable Declare end
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <div class="flex col-span-12 justify-end gap-6">
        <!-- <BaseButton
              v-if="!freeze"
              color="primary"
              class="mb-5"
              @click="handleAdd"
              >Add task</BaseButton 
            >
            <BaseButton
              v-if="!freeze"
              color="muted"
              class="mb-5"
              @click="chooseTemplete"
              >Add template</BaseButton
            > -->
        <BaseButton v-if="!freeze" @click="handleAdd">
          <Icon name="ic:twotone-add-task" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Add task') }}</span>
        </BaseButton>

        <BaseButton v-if="!freeze" @click="chooseTemplete">
          <Icon name="wordpress:add-template" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Add template') }}</span>
        </BaseButton>
      </div>
      <!-- Header -->
      <div class="col-span-12">
        <BaseCard v-if="!loading">
          <div class="flex w-full"></div>
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
          <work-inspection-item-nested
            :code="props.code"
            :template_types="props.TempTypes"
            :children="records"
            :rootItems="records"
            :changeFn="changeEvent"
            :refresh="props.refresh"
            :progress="props.progress"
            :freeze="props.freeze"
          />
          <TaskTemplateChooseModalForm
            :key="selectedItem"
            :open="isModalOpen"
            :template_types="props.TempTypes"
            types="hi"
            :close="handleModalClose"
            :row="selectedItem"
            :setRow="handleChangeRow"
            :refresh="handleChangeKey"
            size="lg"
            :title="t('Choose template type')"
          />

          <ModalItemsList
            :open="isModalTemplateOpen"
            :header="[
              { title: t('Name'), key: 'name', align: 'start', width: '30%' },
              {
                title: t('Created'),
                key: 'user_created.first_name',
                align: 'start',
                sortable: false,
              },
              {
                title: t('Date'),
                key: 'created_at',
                align: 'start',
                sortable: false,
              },
              {
                title: t('Action'),
                key: 'action',
                align: 'start',
                sortable: false,
              },
            ]"
            :close="handleModalClose"
            :setItem="setTemplate"
            :filter="{}"
            title="Template"
            class="templates"
            collection="Template"
            fields="*,user_created.first_name, users.directus_users_id.first_name"
          />
        </BaseCard>
      </div>
    </div>
  </div>
</template>
