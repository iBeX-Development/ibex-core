<template>
  <div class="demo-search relative -mt-[60px]">
    <TairoContentWrapper>
      <template #left>
        <BaseInput
          icon="lucide:search"
          :placeholder="t('Name')"
          :classes="{
            wrapper: 'w-[340px]',
          }"
          @input="onFilterTextBoxChanged"
        />
      </template>
    </TairoContentWrapper>
  </div>
  <div
    :class="`demo-app-main timeline${
      $colorMode.value === 'light' ? '' : '-dark'
    }`"
  >
    <div style="display: flex">
      <div style="flex-grow: 1">
        <div class="flex justify-between p-4">
          <div class="flex">
            <div class="buttons" style="width: 168px">
              <button id="previous" v-on:click="previous"><<</button>
              <button id="today" v-on:click="setTday">{{ t('Today') }}</button>
              <button id="next" v-on:click="next">>></button>
            </div>
            <div
              class="date_range_filter"
              style="
                display: flex;
                width: 274px;
                justify-content: space-between;
                margin-left: 30px;
                height: 32px;
              "
            >
              <div class="start_date">
                <FormKit
                  type="date"
                  name="started_date"
                  @change="onChange('started_date', $event)"
                  v-model="customFrom"
                  validation-visibility="live"
                  :classes="{
                    input: 'date_input',
                    outer: 'sdate_wrapper',
                    label: 'sdate_label',
                  }"
                />
              </div>
              <div class="end_date">
                <FormKit
                  type="date"
                  name="end_date"
                  @change="onChange('end_date', $event)"
                  v-model="customTo"
                  validation-visibility="live"
                  :classes="{
                    input: 'date_input',
                    outer: 'edate_wrapper',
                    label: 'edate_label',
                  }"
                />
              </div>
            </div>
          </div>
          <div class="flex items-center">
            <div class="titles" style="margin-right: 10px; font-weight: bold">
              {{ viewDateText }}
            </div>
            <div class="buttons">
              <button
                @click="viewType = 'Resource'"
                :class="{ selected: viewType === 'Resource' }"
              >
                {{ t('Month') }}
              </button>
              <button
                @click="viewType = 'ResourceWeek'"
                :class="{ selected: viewType === 'ResourceWeek' }"
              >
                {{ t('Week') }}
              </button>
              <button
                @click="viewType = 'Day'"
                :class="{ selected: viewType === 'Day' }"
              >
                {{ t('Day') }}
              </button>
            </div>
          </div>
        </div>
        <div v-if="viewType === 'Resource'">
          <DayPilotScheduler :config="config" ref="schedulerRef" />
        </div>
        <div v-if="viewType === 'ResourceWeek'">
          <DayPilotScheduler :config="configResourceWeek" ref="schedulerRef" />
        </div>

        <div v-if="viewType === 'Day'">
          <DayPilotScheduler :config="configResourceDay" ref="schedulerRef" />
        </div>
      </div>
    </div>

    <!-- Event Modal -->
    <div
      v-if="isEventModalOpen"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
    >
      <div class="bg-white p-6 rounded-lg w-96">
        <p>
          <strong>{{ t('Task') }} :#</strong> {{ selectedEvent.id }}
        </p>
        <p>
          <strong>{{ t('Name') }}:</strong> {{ selectedEvent.name }}
        </p>
        <br />
        <div>
          <strong>{{ t('Start date') }}:</strong>
          <div class="start_date">
            <FormKit
              type="date"
              name="started_date"
              @change="onChange('edit_started_date', $event)"
              v-model="selectedEvent.start"
            />
          </div>
        </div>
        <div>
          <strong>{{ t('Due date') }}:</strong>
          <div class="end_date">
            <FormKit
              type="date"
              name="end_date"
              @change="onChange('edit_end_date', $event)"
              v-model="selectedEvent.end"
            />
          </div>
        </div>
        <div class="flex justify-end mt-4">
          <button
            @click="onSave()"
            class="bg-blue-500 text-white px-4 py-2 rounded"
          >
            {{ t('Save') }}
          </button>
          <button
            @click="isEventModalOpen = false"
            class="bg-blue-500 text-white px-4 py-2 rounded ml-2"
          >
            {{ t('Close') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { DayPilot, DayPilotScheduler } from '@daypilot/daypilot-lite-vue'
import { onMounted, reactive, ref, watch } from 'vue'
import * as XLSX from 'xlsx'
import { useI18n } from 'vue-i18n'
const { t } = useI18n()
const { params } = useRoute()

const events = ref([])
const viewType = ref('Resource')
const eventType = ref('TimeLine')
const startDate = ref(DayPilot.Date.today())
// const startDate = ref(new Date())

// import dayjs from 'dayjs'

const dayRef = ref(null)
const weekRef = ref(null)
const monthRef = ref(null)
const quickFilterText = ref('')
const today = new Date()
const currentdate = ref(new Date())
const isEventModalOpen = ref(false)
const selectedEvent = ref({})

const colId = ref(null)
const sort = ref(null)

const current_date = ref(new Date())
const datas = ref([])
const org_datas = ref([])
const loading = ref(false)
const qalendarRef = ref(null)
const { getItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const columnState = ref(JSON.parse(localStorage.getItem('open')))

const sortedColumns = columnState.value?.filter((col) => col.sort !== null)
if (sortedColumns?.length) {
  colId.value = sortedColumns[0].colId
  sort.value = sortedColumns[0].sort
  // console.log('sort_changes', colId.value, sort.value)
}

const customFrom = ref(
  new Date(today.getFullYear(), today.getMonth(), 2)
    .toISOString()
    .split('T')[0],
)

const customTo = ref(
  new Date(today.getFullYear(), today.getMonth() + 1, 1)
    .toISOString()
    .split('T')[0],
)

const onTimeRangeSelected = async (args) => {
  const modal = await DayPilot.Modal.prompt('Create a new event:', 'Event 1')
  const calendar = args.control
  calendar.clearSelection()
  if (modal.canceled) {
    return
  }
  calendar.events.add({
    start: args.start,
    end: args.end,
    id: DayPilot.guid(),
    text: modal.result,
  })
}

const onBeforeEventRender = (args) => {
  args.data.barHidden = true
  args.data.borderRadius = '5px'
  args.data.backColor = args.data.color
  args.data.borderColor = args.data.borderColor
  args.data.fontColor = '#ffffff'
  // args.data.areas = [
  //   {
  //     top: 10,
  //     right: 6,
  //     width: 20,
  //     height: 20,
  //     symbol: 'icons/daypilot.svg#minichevron-down-4',
  //     fontColor: '#999999',
  //     backColor: '#f9f9f9',
  //     borderRadius: '50%',
  //     visibility: 'Visible',
  //     action: 'ContextMenu',
  //     padding: 1,
  //     style: 'border: 2px solid #ccc; cursor:pointer;',
  //   },
  // ]
}

const colors = [
  { name: 'Green', id: '#93c47d' },
  { name: 'Blue', id: '#6fa8dc' },
  { name: 'Orange', id: '#f6b26b' },
  { name: 'Yellow', id: '#ffd966' },
  { name: 'Gray', id: '#cccccc' },
]

const onEventEdit = async (event) => {
  const form = [
    { name: 'Text', id: 'text', type: 'text' },
    { name: 'Color', id: 'color', type: 'select', options: colors },
  ]
  const modal = await DayPilot.Modal.form(form, event.data)
  if (modal.canceled) {
    return
  }
  event.data.text = modal.result.text
  event.data.color = modal.result.color
}

const onEventDelete = (event) => {
  const data = event.data
  events.value = events.value.filter((e) => e.id !== data.id)
}

const configResourceDay = reactive({
  timeHeaders: [
    { groupBy: 'Day', format: 'yyyy/MM/dd' },
    { groupBy: 'Hour', format: 'h tt' },
  ],
  scale: 'Hour',
  days: 1,
  startDate: DayPilot.Date.today(),
  cellWidthSpec: 'Fixed',
  cellWidth: 60,
  rowHeight: 50,
  durationBarVisible: false,
  rowHeaderWidth: 280,
  timeRangeSelectedHandling: 'Disabled',
  onTimeRangeSelected: async (args) => {
    const scheduler = args.control
    const modal = await DayPilot.Modal.prompt('Create a new event:', 'Event 1')
    scheduler.clearSelection()
    if (modal.canceled) {
      return
    }
    scheduler.events.add({
      start: args.start,
      end: args.end,
      id: DayPilot.guid(),
      resource: args.resource,
      text: modal.result,
    })
  },
  eventMoveHandling: 'Update',
  onEventMoved: (args) => {
    console.log('Event moved: ' + args.e.text())
    const dp = args.control

    let wo_id = args.e.data.id
    let newStart = args.newStart.value
    let newEnd = args.newEnd.value

    let formattedStart = formatEventDate(new Date(newStart))
    let formattedEnd = formatEventDate(new Date(newEnd), 'down')
    let eventColor = getEventColor(new Date(newStart), new Date(newEnd))
    let eventBorderColor = getEventBorderColor(
      new Date(newStart),
      new Date(newEnd),
    )

    let start = formattedStart + 'T00:00:00'
    let end = formattedEnd + 'T23:59:59.999'

    // // DayPilot дотор event-ийг шинэчлэх
    dp.events.update({
      id: wo_id,
      text: args.e.data.text,
      name: args.e.data.name,
      start: newStart, // ISO datetime format
      end: newEnd, // ISO datetime format
      resource: args.e.data.resource,
      isEditable: true,
      color: eventColor,
      borderColor: eventBorderColor,
      backColor: eventColor,
      fontColor: '#333',
    })
    dp.update()

    const updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: {
        started_at: newStart,
        due: newEnd,
      },
    }

    updateItem(updateData).then((res) => {
      console.log('done')
    })
  },
  eventResizeHandling: 'Update',
  onEventResized: (args) => {
    console.log('configResourceDay resized: ')

    const dp = args.control

    let wo_id = args.e.data.id
    let newStart = args.newStart.value
    let newEnd = args.newEnd.value
    let formattedStart = formatEventDate(new Date(newStart))
    let formattedEnd = formatEventDate(new Date(newEnd), 'down')
    let eventColor = getEventColor(new Date(newStart), new Date(newEnd))
    let eventBorderColor = getEventBorderColor(
      new Date(newStart),
      new Date(newEnd),
    )

    let start = formattedStart + 'T00:00:00'
    let end = formattedEnd + 'T23:59:59.999'

    // // DayPilot дотор event-ийг шинэчлэх
    dp.events.update({
      id: wo_id,
      text: args.e.data.text,
      name: args.e.data.name,
      start: newStart, // ISO datetime format
      end: newEnd, // ISO datetime format
      resource: args.e.data.resource,
      isEditable: true,
      color: eventColor,
      borderColor: eventBorderColor,
      backColor: eventColor,
      fontColor: '#333',
    })
    dp.update()

    const updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: {
        started_at: newStart,
        due: newEnd,
      },
    }

    updateItem(updateData).then((res) => {
      console.log('res')
    })
  },
  eventDeleteHandling: 'Disabled',
  onEventDeleted: (args) => {
    console.log('Event deleted: ' + args.e.text())
  },
})

const configResourceWeek = reactive({
  timeHeaders: [
    // { groupBy: 'Month' },
    // { groupBy: 'Week' },
    { groupBy: 'Day', format: 'yyyy/MM/dd' }, // Full: June 10, 2025
  ],
  scale: 'Day',
  days: 7, // 7 өдөр буюу 1 долоо хоног
  startDate: DayPilot.Date.today().firstDayOfWeek(), // Долоо хоногийн эхнээс эхэлнэ (ихэвчлэн Monday)
  cellWidthSpec: 'Auto', // эсвэл "Fixed"
  cellWidth: 150, // өдрийн өргөн (adjust based on screen)
  rowHeight: 50,
  timeRangeSelectedHandling: 'Disabled',
  durationBarVisible: false,
  rowHeaderWidth: 280,
  onTimeRangeSelected: async (args) => {
    const scheduler = args.control
    const modal = await DayPilot.Modal.prompt('Create a new event:', 'Event 1')
    scheduler.clearSelection()
    if (modal.canceled) {
      return
    }
    scheduler.events.add({
      start: args.start,
      end: args.end,
      id: DayPilot.guid(),
      resource: args.resource,
      text: modal.result,
    })
  },
  eventMoveHandling: 'Update',
  onEventMoved: (args) => {
    console.log('Event moved: ' + args.e.text())
    const dp = args.control

    let wo_id = args.e.data.id
    let newStart = args.newStart.value
    let newEnd = args.newEnd.value

    let formattedStart = formatEventDate(new Date(newStart))
    let formattedEnd = formatEventDate(new Date(newEnd), 'down')
    let eventColor = getEventColor(new Date(newStart), new Date(newEnd))
    let eventBorderColor = getEventBorderColor(
      new Date(newStart),
      new Date(newEnd),
    )

    let start = formattedStart + 'T00:00:00'
    let end = formattedEnd + 'T23:59:59.999'

    // // DayPilot дотор event-ийг шинэчлэх
    dp.events.update({
      id: wo_id,
      text: args.e.data.text,
      name: args.e.data.name,
      start: newStart, // ISO datetime format
      end: newEnd, // ISO datetime format
      resource: args.e.data.resource,
      isEditable: true,
      color: eventColor,
      borderColor: eventBorderColor,
      backColor: eventColor,
      fontColor: '#333',
    })
    dp.update()

    const updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: {
        started_at: start,
        due: end,
      },
    }

    updateItem(updateData).then((res) => {
      console.log('res')
    })
  },
  eventResizeHandling: 'Update',
  onEventResized: (args) => {
    console.log('configResourceWeek resized: ' + args.e.text())

    const dp = args.control

    let wo_id = args.e.data.id
    let newStart = args.newStart.value
    let newEnd = args.newEnd.value
    let formattedStart = formatEventDate(new Date(newStart))
    let formattedEnd = formatEventDate(new Date(newEnd), 'down')
    let eventColor = getEventColor(new Date(newStart), new Date(newEnd))
    let eventBorderColor = getEventBorderColor(
      new Date(newStart),
      new Date(newEnd),
    )

    let start = formattedStart + 'T00:00:00'
    let end = formattedEnd + 'T23:59:59.999'

    // // DayPilot дотор event-ийг шинэчлэх
    dp.events.update({
      id: wo_id,
      text: args.e.data.text,
      name: args.e.data.name,
      start: newStart, // ISO datetime format
      end: newEnd, // ISO datetime format
      resource: args.e.data.resource,
      isEditable: true,
      color: eventColor,
      borderColor: eventBorderColor,
      backColor: eventColor,
      fontColor: '#333',
    })
    dp.update()

    const updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: {
        started_at: start,
        due: end,
      },
    }

    updateItem(updateData).then((res) => {
      console.log('res')
    })
  },
  eventDeleteHandling: 'Disabled',
  onEventDeleted: (args) => {
    console.log('Event deleted: ' + args.e.text())
  },
  eventRightClickHandling: 'ContextMenu',
  contextMenu: new DayPilot.Menu({
    items: [
      {
        text: 'Edit',
        onClick: (args) => {
          onClick(args)
        },
      },
    ],
    // const dp = args.source.calendar; dp.events.remove(args.source);
  }),
})

const config = reactive({
  timeHeaders: [
    { groupBy: 'Month' },
    { groupBy: 'Week' },
    { groupBy: 'Day', format: 'd' },
  ],
  scale: 'Day',
  rowHeight: 50,
  days: DayPilot.Date.today().daysInMonth(),
  startDate: DayPilot.Date.today().firstDayOfMonth(),
  durationBarVisible: false,
  rowHeaderWidth: 280,
  cellWidthSpec: 'Auto', // эсвэл "Fixed"
  rowHeaderColumns: [
    { title: 'Id', display: 'id' },
    { title: 'Name', display: 'name' },
    { title: 'Task', display: 'task' },
  ],

  timeRangeSelectedHandling: 'Disabled',
  onTimeRangeSelected: async (args) => {
    const scheduler = args.control
    const modal = await DayPilot.Modal.prompt('Create a new event:', 'Event 1')
    scheduler.clearSelection()
    if (modal.canceled) {
      return
    }
    scheduler.events.add({
      start: args.start,
      end: args.end,
      id: DayPilot.guid(),
      resource: args.resource,
      text: modal.result,
    })
  },
  eventMoveHandling: 'Update',
  onEventMoved: (args) => {
    console.log('Event moved_m: ' + args.e.text())
    const dp = args.control

    let wo_id = args.e.data.id
    let newStart = args.newStart.value
    let newEnd = args.newEnd.value

    let formattedStart = formatEventDate(new Date(newStart))
    let formattedEnd = formatEventDate(new Date(newEnd), 'down')
    let eventColor = getEventColor(new Date(newStart), new Date(newEnd))
    let eventBorderColor = getEventBorderColor(
      new Date(newStart),
      new Date(newEnd),
    )

    let start = formattedStart + 'T00:00:00'
    let end = formattedEnd + 'T23:59:59.999'
    console.log('start', start)
    console.log('end', end)

    // DayPilot дотор event-ийг шинэчлэх
    dp.events.update({
      id: wo_id,
      text: args.e.data.text,
      name: args.e.data.name,
      start: newStart, // ISO datetime format
      end: newEnd, // ISO datetime format
      resource: args.e.data.resource,
      isEditable: true,
      color: eventColor,
      borderColor: eventBorderColor,
      backColor: eventColor,
      fontColor: '#333',
    })
    dp.update()

    const updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: {
        started_at: start,
        due: end,
      },
    }

    updateItem(updateData).then((res) => {
      console.log('res')
    })
  },
  eventResizeHandling: 'Update',
  onEventResized: (args) => {
    // console.log('Event resized: ' + args.e.text())
    // console.log('Event resized month: ', args)
    const dp = args.control

    let wo_id = args.e.data.id
    let newStart = args.newStart.value
    let newEnd = args.newEnd.value

    // console.log(' resized.newStart: ', args.newStart.value)
    // console.log(' resized.newEnd1 ', args.newEnd.value)
    // console.log(' resized.newEnd_2 ', newEnd)

    let formattedStart = formatEventDate(new Date(newStart))
    let formattedEnd = formatEventDate(new Date(newEnd), 'down')
    let eventColor = getEventColor(new Date(newStart), new Date(newEnd))
    let eventBorderColor = getEventBorderColor(
      new Date(newStart),
      new Date(newEnd),
    )

    let start = formattedStart + 'T00:00:00'
    let end = formattedEnd + 'T23:59:59.999'

    // console.log('start???', start)
    // console.log('end????', end)

    // // DayPilot дотор event-ийг шинэчлэх
    dp.events.update({
      id: wo_id,
      text: args.e.data.text,
      name: args.e.data.name,
      start: newStart, // ISO datetime format
      end: newEnd, // ISO datetime format
      resource: args.e.data.resource,
      isEditable: true,
      color: eventColor,
      borderColor: eventBorderColor,
      backColor: eventColor,
      fontColor: '#333',
    })
    dp.update()

    const updateData = {
      collection: 'Work_order',
      id: wo_id,
      item: {
        started_at: start,
        due: end,
      },
    }

    updateItem(updateData).then((res) => {
      console.log('res')
    })
  },
  eventDeleteHandling: 'Disabled',
  onEventDeleted: (args) => {
    console.log('Event deleted: ' + args.e.text())
  },
  eventRightClickHandling: 'ContextMenu',
  contextMenu: new DayPilot.Menu({
    items: [
      {
        text: 'Edit',
        onClick: (args) => {
          onClick(args)
        },
      },
    ],
    // const dp = args.source.calendar; dp.events.remove(args.source);
  }),
})
const schedulerRef = ref(null)

const setTday = async () => {
  const today = DayPilot.Date.today()
  startDate.value = today
  config.startDate = today
  configResourceWeek.startDate = today
  configResourceDay.startDate = today

  // const newDate = new Date(today.getFullYear(), today.getMonth() + 1, 2)
  // const dpDate = new DayPilot.Date(newDate)
  // config.startDate = dpDate

  config.days = today.daysInMonth()
  await loadItems(startDate.value, null, 'today')

  if (datas.value.length > 0) {
    // console.log('arr', quickFilterText.value)

    const resources = datas.value.map((item, ind) => ({
      id: item.id || item.resource, //item.resourceId ||
      name: `${++ind}. ${item.name}`, // \n ашиглана
      task: 'task Title',
    }))

    config.events = datas.value
    configResourceWeek.events = datas.value
    configResourceDay.events = datas.value

    config.resources = resources
    configResourceWeek.resources = resources
    configResourceDay.resources = resources
  }
}
const addDays = (date, days) => {
  const jsDate = date.toDate()
  jsDate.setDate(jsDate.getDate() + days)
  return new DayPilot.Date(jsDate)
}

const addMonths = (date, months) => {
  const jsDate = date.toDate()
  jsDate.setMonth(jsDate.getMonth() + months)
  return new DayPilot.Date(jsDate)
}

const startOfWeek = (date) => {
  const jsDate = date.toDate()
  const day = jsDate.getDay()
  const diff = jsDate.getDate() - day + (day === 0 ? -6 : 1) // Monday эхлэл
  const monday = new Date(jsDate.setDate(diff))
  return new DayPilot.Date(monday)
}

const getDaysInMonth = (date) => {
  const year = date.getFullYear()
  const month = date.getMonth()
  return new Date(year, month + 1, 0).getDate()
}

const getDaysInDuration = (sdate, edate) => {
  const start = new Date(sdate)
  const end = new Date(edate)

  // Огнооны хоорондын зөрүү (миллисекундээр)
  const diffInMs = end.getTime() - start.getTime()

  // 1 хоног = 1000 * 60 * 60 * 24 миллисекунд
  const diffInDays = diffInMs / (1000 * 60 * 60 * 24)

  // Хэрэв бүхэл тоон утга хэрэгтэй бол Math.floor эсвэл Math.ceil ашиглана
  // console.log('getDaysInDuration', Math.ceil(diffInDays))
  return Math.ceil(diffInDays + 1)
}

const previous = async () => {
  if (viewType.value === 'ResourceWeek') {
    const newDate = startOfWeek(addDays(startDate.value, -7))
    startDate.value = newDate
    config.startDate = newDate
    configResourceWeek.startDate = newDate
    config.days = 7
  } else if (viewType.value === 'Day') {
    const newDate = addDays(startDate.value, -1)
    startDate.value = newDate
    config.startDate = newDate
    configResourceWeek.startDate = newDate
    config.days = 1
  } else {
    const current = startDate.value.toDate()
    const newDate = new Date(current.getFullYear(), current.getMonth() - 1, 2)
    const dpDate = new DayPilot.Date(newDate)

    startDate.value = dpDate
    config.startDate = dpDate
    configResourceWeek.startDate = dpDate
    config.days = getDaysInMonth(newDate)
  }

  await loadItems(startDate.value, null, 'previous')

  if (datas.value.length > 0) {
    // console.log('arr', quickFilterText.value)

    const resources = datas.value.map((item, ind) => ({
      id: item.id || item.resource, //item.resourceId ||
      name: `${++ind}. ${item.name}`, // \n ашиглана
      task: 'task Title',
    }))

    config.events = datas.value
    configResourceWeek.events = datas.value
    configResourceDay.events = datas.value

    config.resources = resources
    configResourceWeek.resources = resources
    configResourceDay.resources = resources
  }
}

const next = async () => {
  if (viewType.value === 'ResourceWeek') {
    const newDate = startOfWeek(addDays(startDate.value, 7))
    startDate.value = newDate
    config.startDate = newDate
    configResourceWeek.startDate = newDate
    config.days = 7
  } else if (viewType.value === 'Day') {
    const newDate = addDays(startDate.value, 1)
    startDate.value = newDate
    config.startDate = newDate
    configResourceWeek.startDate = newDate
    configResourceDay.startDate = newDate
    config.days = 1
  } else {
    const current = startDate.value.toDate() //sariin
    const newDate = new Date(current.getFullYear(), current.getMonth() + 1, 2)
    const dpDate = new DayPilot.Date(newDate)

    startDate.value = dpDate
    config.startDate = dpDate
    configResourceWeek.startDate = dpDate
    config.days = getDaysInMonth(newDate)
  }

  await loadItems(startDate.value, null, 'next')

  if (datas.value.length > 0) {
    // console.log('arr', quickFilterText.value)

    const resources = datas.value.map((item, ind) => ({
      id: item.id || item.resource, //item.resourceId ||
      name: `${++ind}. ${item.name}`, // \n ашиглана
      task: 'task Title',
    }))

    config.events = datas.value
    configResourceWeek.events = datas.value
    configResourceDay.events = datas.value

    config.resources = resources
    configResourceWeek.resources = resources
    configResourceDay.resources = resources
  }
}

const exportToExcelTable = () => {
  const scheduler = schedulerRef.value.control
  const resources = scheduler.resources
  // console.log('scheduler', scheduler)
  const daysCount = scheduler.days
  const startDate = scheduler.startDate

  // Толгой хэсэг: Эхний багана - Resource, дараагийн баганууд нь өдөр бүр
  const headers = ['Resource']
  for (let i = 0; i < daysCount; i++) {
    const day = startDate.addDays(i)
    headers.push(day.toString('yyyy-MM-dd'))
  }

  // Мэдээлэл үүсгэх: resource бүрийн мөрүүд
  const data = resources.map((resource) => {
    const row = { Resource: resource.name }

    // Өдөр бүрийн event-г хайж оруулах
    for (let i = 0; i < daysCount; i++) {
      const day = startDate.addDays(i).value
      console.log('day', day, typeof day)
      //  DayPilot.Date
      // Тухайн resource дээр энэ өдөр эхэлсэн event-үүдийг авах
      const eventsOnDay = scheduler.events.list.filter((e) => {
        // Convert string to Date object
        const eventDate = new Date(e.start)
        const compareDay = new Date(day)

        return (
          e.resource === resource.id &&
          eventDate.getDate() === compareDay.getDate() &&
          eventDate.getMonth() === compareDay.getMonth() &&
          eventDate.getFullYear() === compareDay.getFullYear()
        )
      })

      // Хэрвээ олон event байвал тэдний текстүүдийг таслалж нийлүүлнэ
      row[day.toString('yyyy-MM-dd')] = eventsOnDay
        .map((e) => e.text)
        .join(', ')
    }
    return row
  })

  // Толгой болон өгөгдлийг хамтад нь өгч worksheet үүсгэнэ
  const worksheet = XLSX.utils.json_to_sheet(data, { header: headers })
  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, 'ResourceSchedule')

  // Файлыг хадгалах
  XLSX.writeFile(workbook, 'ResourceSchedule.xlsx')
}

const exportToExcel = () => {
  console.log('exportToExcel')
  const scheduler = schedulerRef.value.control
  const resources = scheduler.resources
  const events = scheduler.events.list

  const data = events.map((e) => {
    return {
      ID: e.id,
      Text: e.text,
      Resource: resources.find((r) => r.id === e.resource)?.name || e.resource,
      Start: e.start.toString(),
      End: e.end.toString(),
    }
  })

  const worksheet = XLSX.utils.json_to_sheet(data)
  const workbook = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(workbook, worksheet, 'Schedule')

  XLSX.writeFile(workbook, 'schedule.xlsx')
}

const onSave = async (event = null) => {
  isEventModalOpen.value = false
  console.log('onSave', selectedEvent.value)

  let end = selectedEvent.value.end + 'T23:59:59.999'
  let start = selectedEvent.value.start + 'T00:00:00'
  console.log('end', end)
  console.log('start', start)

  // selectedEvent.value = {
  //   title: workItem.name,
  //   id: workItem.id,
  //   start: workItem.start,
  //   end: end,
  // }

  let updateData = {
    collection: 'Work_order',
    id: selectedEvent.value.id,
    item: { started_at: start, due: end },
  }

  const res = await updateItem(updateData)
  refresh(selectedEvent)
}
const refresh = (item) => {
  const dp = schedulerRef.value.control
  let start = new DayPilot.Date(
    new Date(selectedEvent.value.start + 'T00:00:00'),
  )
  let end = new DayPilot.Date(
    new Date(selectedEvent.value.end + 'T23:59:59.999'),
  )

  const found = dp.events.list.find((e) => e.id === selectedEvent.value.id)
  if (!found) {
    console.warn('Event not found. Try using dp.events.add() instead')
    return
  }

  let formattedStart = formatEventDate(new Date(selectedEvent.value.start))
  let formattedEnd = formatEventDate(new Date(selectedEvent.value.end), 'up')
  let eventColor = getEventColor(
    new Date(selectedEvent.value.start),
    new Date(selectedEvent.value.end),
  )
  let eventBorderColor = getEventBorderColor(
    new Date(selectedEvent.value.start),
    new Date(selectedEvent.value.end),
  )

  // console.log('formattedStart', formattedStart)
  // console.log('formattedEnd', formattedEnd)

  // DayPilot дотор event-ийг шинэчлэх
  dp.events.update({
    id: selectedEvent.value.id,
    text: selectedEvent.value.text,
    name: selectedEvent.value.name,
    start: formattedStart, // ISO datetime format
    end: formattedEnd, // ISO datetime format
    resource: selectedEvent.value.resource,
    isEditable: true,
    color: eventColor,
    borderColor: eventBorderColor,
    // data: selectedEvent.value.data,
    backColor: eventColor,
    fontColor: '#333',
  })
  dp.update()
}

const newLoading = async () => {
  const newColumnState = JSON.parse(localStorage.getItem('open'))
  const sortedColumns = newColumnState?.filter((col) => col.sort !== null)
  // console.log('newLoading', colId.value, sort.value)

  if (sortedColumns?.length) {
    colId.value = sortedColumns[0].colId
    sort.value = sortedColumns[0].sort
    // console.log('newLoading-found', colId.value, sort.value)
  }

  await loadItems()
  const resources = datas.value.map((item, ind) => ({
    id: item.id || item.resource,
    name: `${++ind}. ${item.name}`, // \n ашиглана
    task: 'task Title',
  }))

  // this.events = datas.value
  config.events = datas.value
  configResourceWeek.events = datas.value
  configResourceDay.events = datas.value

  config.resources = resources
  configResourceWeek.resources = resources
  configResourceDay.resources = resources
  const dp = schedulerRef.value.control
}

async function onChange(type, event) {
  let items = {}
  let keyName = ''

  if (type == 'started_date' || type == 'end_date') {
    if (event.target.name == 'started_date') {
      keyName = 'started_date'
      customFrom.value = event.target.value
    } else if (event.target.name == 'end_date') {
      keyName = 'end_date'
      customTo.value = event.target.value
    }
  }

  if (type == 'edit_started_date' || type == 'edit_end_date') {
    if (event.target.name == 'started_date') {
      keyName = 'started_date'
      selectedEvent.value.start = event.target.value
    } else if (event.target.name == 'end_date') {
      keyName = 'end_date'
      selectedEvent.value.end = event.target.value
    }
    // console.log('heey', selectedEvent.value)

    return
  }

  // console.log('selectedEvent', selectedEvent.value)
  await loadItems(customFrom, customTo, 'range')
  const resources = datas.value.map((item, ind) => ({
    id: item.id || item.resource,
    name: `${++ind}. ${item.name}`, // \n ашиглана
    task: 'task Title',
  }))

  config.events = datas.value
  configResourceWeek.events = datas.value
  configResourceDay.events = datas.value

  config.resources = resources
  configResourceWeek.resources = resources
  configResourceDay.resources = resources

  // const scurrent = customFrom.value.toDate()
  // const ecurrent = customTo.value.toDate()

  const sdpDate = new DayPilot.Date(customFrom.value)
  const edpDate = new DayPilot.Date(customTo.value)
  // console.log('sdpDate', sdpDate, edpDate)

  startDate.value = sdpDate
  config.startDate = sdpDate
  configResourceWeek.startDate = sdpDate
  config.days = getDaysInDuration(customFrom.value, customTo.value)
}

const onClick = (item) => {
  // console.log('onClick', item)
  let workItem = item.source.data
  isEventModalOpen.value = true
  //event zurahdaa neg odor dutuu uchraas
  let start = formatEventDate(new Date(workItem.start))
  let end = formatEventDate(new Date(workItem.end), 'down')

  selectedEvent.value = {
    id: workItem.id,
    name: workItem.name,
    text: workItem.text,
    start: start,
    end: end,
    resource: workItem.resource,
    data: item.data,
  }

  // console.log('onClicked', selectedEvent)
  // console.log('workItem', workItem)
}

const loadItems = async (
  sDate = null,
  eDate = null,
  type = 'default',
  sortField = null,
  sortOrder = null,
) => {
  loading.value = true
  // const today = new Date().toISOString().slice(0, 10); // '2025-06-09'

  let startOfMonth = new Date(
    current_date.value.getFullYear(),
    current_date.value.getMonth(),
    1,
  ).toISOString()

  let endOfMonth = new Date(
    current_date.value.getFullYear(),
    current_date.value.getMonth() + 1,
    1,
  ).toISOString()
  // console.log('sDate-run1', sDate)

  if (type == 'range') {
    let sFilter = new Date(sDate.value)
    let eFilter = new Date(eDate.value)
    startOfMonth = new Date(sFilter).toISOString()
    endOfMonth = new Date(eFilter).toISOString()
  } else if (sDate) {
    let dateFilter = new Date(sDate.value)
    startOfMonth = new Date(
      dateFilter.getFullYear(),
      dateFilter.getMonth(),
      1,
    ).toISOString()

    endOfMonth = new Date(
      dateFilter.getFullYear(),
      dateFilter.getMonth() + 1,
      1,
    ).toISOString()

    // console.log('startOfMonth', startOfMonth)
    // console.log('endOfMonth', endOfMonth)
  }

  try {
    let filters = {
      wo_status: { _neq: 3 },
      company_id: { _eq: myCompanyId },
      active: '1',
      due: {
        _gte: startOfMonth,
        _lte: endOfMonth,
      },
    }

    if (params.id != null) {
      filters['location'] = { _eq: parseInt(params.id, 10) }
    }

    if (quickFilterText.value.length > 3) {
      filters = {
        company_id: { _eq: myCompanyId },
      }
    }

    // console.log('filters-colId', colId.value, sort.value)
    const items = await getItems({
      collection: 'Work_order',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        // sortField: colId.value,
        // sortOrder: sort.value,
        sort: `${sort.value === 'asc' ? '' : '-'}${
          colId.value === null ? 'id' : colId.value
        }`,
        search: quickFilterText.value,
        meta: 'filter_count',
        fields: ['*', 'assigned_to.first_name', 'assigned_team.name'],
      },
    })

    // console.log('filters-items', items)
    org_datas.value = items.data
    datas.value = transformEvents(items.data)
    loading.value = false
  } catch (e) {
    console.error(e)
  }
}
function subtractTime(datetimeString) {
  const date = new Date(datetimeString)

  // 8 цаг 1 минут хасах
  date.setHours(date.getHours() - 8)
  date.setMinutes(date.getMinutes() - 1)

  // Улаанбаатарын цагаар форматлаж буцаах
  return date.toLocaleString('en-US', {
    timeZone: 'Asia/Ulaanbaatar',
    hour12: false,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  })
}

const getEventColor = (startDate, dueDate) => {
  //Хугацаа нь хэтэрсэн ажил улаан өнгө
  //Хугацаа нь болоогүй ажил хөх өнгө
  //Хугацаандаа байгаа нь ногоон өнгөтэй
  const now = new Date()
  // console.log('getEventColor', now, startDate, dueDate)
  if (now > dueDate) {
    return '#cc0000'
  } else if (now < startDate) {
    return '#3c78d8'
  } else {
    // const daysUntilDue = Math.floor(
    //   (dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24),
    // )
    // return daysUntilDue <= 3 ? '#6aa84f' : '#3c78d8'
    return '#6aa84f'
  }
}

const getEventBorderColor = (startDate, dueDate) => {
  const now = new Date()
  if (now > dueDate) {
    return '#eb2d07'
  } else if (now < startDate) {
    return '#0a5aa2'
  } else {
    // const daysUntilDue = Math.floor(
    //   (dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24),
    // )
    // return daysUntilDue <= 3 ? '#59e01c' : '#0a5aa2'
    return '#59e01c'
  }
}
const formatDateString = (input) => {
  const date = new Date(input)
  if (isNaN(date.getTime())) {
    return 'Invalid date'
  }
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0') // Months start from 0
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}
const formatEventDate = (date, type = 'all') => {
  let year = date.getFullYear()
  let month = String(date.getMonth() + 1).padStart(2, '0')
  let day = String(
    date.getDate() + (type == 'up' ? 1 : type == 'down' ? -1 : 0),
  ).padStart(2, '0')
  return `${year}-${month}-${day}`
}

const transformEvents = (items, type = null) => {
  return items
    .map((event) => {
      const startDate = event.started_at
        ? new Date(event.started_at) //due
        : new Date(event.due)
      const dueDate = event.due ? new Date(event.due) : null

      if (
        !dueDate ||
        isNaN(dueDate.getTime()) ||
        !startDate ||
        isNaN(startDate.getTime())
      ) {
        console.warn(`Skipping event due to invalid dates: ${event}`)
        return null
      }

      // if (event.id == 408) {
      //   console.log('startDate', startDate)
      //   console.log('dueDate', dueDate)
      // }

      const formattedStart =
        type == 'day' ? event.started_at : formatEventDate(startDate)
      const formattedEnd =
        type == 'day' ? event.due : formatEventDate(dueDate, 'up')
      const eventColor = getEventColor(startDate, dueDate)
      const eventBorderColor = getEventBorderColor(startDate, dueDate)

      // if (event.id == 408) {
      //   console.log('viewType', viewType.value)

      //   console.log(
      //     'formattedStart',
      //     event.id,
      //     formattedStart,
      //     event.started_at,
      //   )
      //   console.log(
      //     'formattedEnd',
      //     formattedEnd,
      //     new DayPilot.Date(event.due, true),
      //   )
      // }

      return {
        text:
          event.wo_percent !== undefined
            ? `#${event.id} (${event.wo_percent}%)`
            : '0%',
        name: event.name || 'No Title',
        time: { start: formattedStart, end: formattedEnd },
        start: new DayPilot.Date(event.started_at, true),
        end: new DayPilot.Date(event.due, true),
        resource: event.id,
        allDay: false,
        isEditable: true,
        color: eventColor,
        borderColor: eventBorderColor,
        id: event.id || Math.random().toString(36).substr(2, 9),
        data: event,
        backColor: eventColor,
        fontColor: '#333',
      }
    })
    .filter((event) => event !== null)
}

onMounted(async () => {
  await loadItems()
  // console.log('onMounted:', datas.value)
  const resources = datas.value.map((item, ind) => ({
    id: item.id || item.resource,
    name: `${++ind}. ${item.name}`, // \n ашиглана
    task: 'task Title',
  }))

  // this.events = datas.value
  config.events = datas.value
  configResourceWeek.events = datas.value
  configResourceDay.events = datas.value

  config.resources = resources
  configResourceWeek.resources = resources
  configResourceDay.resources = resources
  const dp = schedulerRef.value.control

  // Calendar-ийн options-д дахин өгнө
  // this.calendarOptions.resources = this.resources
  // this.calendarOptions.events = this.events
  // const rows = document.querySelectorAll('.scheduler_default_rowheader')
  // rows.forEach((row) => {
  //   row.style.height = '50px'
  //   row.style.lineHeight = '50px'
  // })
})

const formatDate = (date, options) => {
  return new Intl.DateTimeFormat('en-US', options).format(date)
}

const formatedDate = (date) => {
  const year = new Date(date).getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

const viewDateText = computed(() => {
  const start = startDate.value.toDate() // JS Date болгож хөрвүүлж авна

  if (viewType.value === 'ResourceWeek') {
    const end = new Date(start)
    end.setDate(start.getDate() + 6)
    // Зөвхөн сарын нэр + жил харуулах

    const startFormatted = formatDate(start, { month: 'short', day: 'numeric' }) // Jun 15
    const endFormatted = formatDate(end, { month: 'short', day: 'numeric' }) // 21, 2025
    const formattedDays = formatDate(end, { year: 'numeric' }) // 21, 2025

    return `${startFormatted} – ${endFormatted} ${formattedDays}`
  } else if (viewType.value === 'Day') {
    return formatDate(start, { month: 'long', day: 'numeric', year: 'numeric' }) // June 16, 2025
  } else
    return formatDate(start, {
      year: 'numeric',
      month: 'short',
    }) // нөөц
})

watch(viewType, (newVal) => {
  console.log('startDate', startDate.value)
  if (newVal === 'Resource') {
    const current = startDate.value.toDate() //sariin

    const newDate = new Date(current.getFullYear(), current.getMonth(), 2)
    // console.log('current', current)
    // console.log('newDate', newDate)

    const dpDate = new DayPilot.Date(newDate)
    startDate.value = dpDate
    config.startDate = dpDate
    config.days = getDaysInMonth(newDate)
  } else if (newVal === 'ResourceWeek') {
    configResourceWeek.startDate = startDate.value.firstDayOfWeek()

    // const newDate = startOfWeek(addDays(startDate.value, 7))
    // startDate.value = newDate
    // config.startDate = newDate
    // configResourceWeek.startDate = newDate
    // config.days = 7
  } else if (newVal === 'Day') {
    // console.log('org_date', org_datas.value)
    // configResourceDay.startDate = startDate.value.firstDayOfWeek()
    // datas.value = transformEvents(org_datas.value, 'day')
    // const resources = datas.value.map((item, ind) => ({
    //   id: item.id || item.resource,
    //   name: `${++ind}. ${item.name}`, // \n ашиглана
    //   task: 'task Title',
    // }))
    // configResourceDay.events = datas.value
    // configResourceDay.resources = resources
    // const newDate = startOfWeek(addDays(startDate.value, 7))
    // startDate.value = newDate
    // config.startDate = newDate
    // configResourceWeek.startDate = newDate
    // config.days = 7
  }
})

const onFilterTextBoxChanged = async (event) => {
  quickFilterText.value = event.target.value
  // console.log('quickFilterText', quickFilterText.value)

  await loadItems(null, null, 'filter')
  if (datas.value.length > 0) {
    // console.log('arr', quickFilterText.value)

    const resources = datas.value.map((item, ind) => ({
      id: item.id || item.resource, //item.resourceId ||
      name: `${++ind}. ${item.name}`, // \n ашиглана
      task: 'task Title',
    }))

    const st = new DayPilot.Date(datas.value[0].start)

    startDate.value = st
    config.startDate = st
    configResourceWeek.startDate = st
    configResourceDay.startDate = st

    config.events = datas.value
    configResourceWeek.events = datas.value
    configResourceDay.events = datas.value

    config.resources = resources
    configResourceWeek.resources = resources
    configResourceDay.resources = resources

    // setTimeout(() => {
    //   const rows = document.querySelectorAll('.scheduler_default_rowheader')
    //   rows.forEach((row, index) => {
    //     row.addEventListener('click', () => {
    //       if (schedulerRef.value.control.events.list.length) {
    //         const resource = schedulerRef.value.control.events.list[index - 1] // DayPilot config-д өгсөн resources
    //         console.log('Clicked resource:', resource, resource.start)

    //         const st = new DayPilot.Date(resource.start)
    //         startDate.value = st
    //         config.startDate = st
    //         configResourceWeek.startDate = st
    //         configResourceDay.startDate = st
    //       }
    //     })
    //   })
    // }, 300)
  }
}

defineExpose({
  schedulerRef,
  exportToExcel,
  eventType,
  newLoading,
  // gridOptions,
})
</script>

<style>
/* override the built-in theme, must not be scoped */
.demo-app {
  display: flex;
  min-height: 100vh;
  font-family: Arial, Helvetica Neue, Helvetica, sans-serif;
  font-size: 14px;
}

.demo-app-main {
  /* flex-grow: 1;
  padding: 3em;
  min-height: 80vh; */
  width: 100%;
  background: white;
}

.timeline-dark {
  background: #20293a;
  color: white;
}

.timeline-dark .scheduler_default_timeheader_scroll {
  background: #20293a;
  color: white;
}

.timeline-dark .scheduler_default_timeheadergroup,
.timeline-dark .scheduler_default_timeheadercol {
  background: #20293a;
  color: white;
}

.timeline-dark .scheduler_default_timeheadergroup,
.timeline-dark .scheduler_default_timeheadercol {
  background: #20293a;
  color: white;
}

.timeline-dark .scheduler_default_cell.scheduler_default_cell_business,
.timeline-dark .scheduler_default_cell {
  background: #20293a;
  color: white;
}

.timeline-dark .scheduler_default_rowheader,
.timeline-dark .scheduler_default_corner {
  background: #20293a;
  color: white;
}

.timeline-dark .buttons button {
  background: #20293a;
  color: white;
}
.calendar-wrapper {
  width: 100%;
  height: 600px;
  overflow: hidden;
}

.fullcalendar-container,
.daypilot-container {
  width: 100%;
  height: 100%;
}

.demo-app-calendar {
  min-height: 600px;
  height: 600px;
  width: 100%;
}

.demo-app-main .fc {
  max-width: 100%;
  margin: 0 auto;
  height: 100%;
}

.demo-app-main .fc-license-message {
  display: none;
}

body .calendar_default_event_inner {
  padding: 0px;
}
.buttons {
  /* margin-bottom: 20px; */
  /*margin-top: 20px;*/
  display: inline-flex;
}

.buttons button {
  background-color: #f3f3f3;
  color: #333333;
  border: 1px solid #cccccc;
  padding: 5px;
  width: 80px;
  font-size: 14px;
  cursor: pointer;
  margin-right: 1px;
  transition: all 0.2s;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.08);
  box-sizing: border-box;
}

.buttons button.selected {
  background-color: #e3e3e3;
  box-shadow: 0 3px 5px rgba(0, 0, 0, 0.1);
}

.buttons button:first-child {
  border-top-left-radius: 30px;
  border-bottom-left-radius: 30px;
}

.buttons button:last-child {
  border-top-right-radius: 30px;
  border-bottom-right-radius: 30px;
}

.buttons button:hover {
  background-color: #e3e3e3;
  box-shadow: 0 5px 7px rgba(0, 0, 0, 0.1);
}

.buttons button:active {
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

body .scheduler_default_event_inner {
  color: white !important;
  height: 16px;
}

.scheduler_default_rowheader_inner_text {
  font-weight: 600 !important;
}

.date_range_filter .date_label,
.date_range_filter .sdate_label,
.date_range_filter .edate_label {
  font-size: 12px;
}

.date_range_filter .date_input,
.date_range_filter .sdate_input,
.date_range_filter .edate_input {
  font-size: 12px;
  width: 132px;
  height: 34px;
}

/* .scheduler_default_rowheader {
  height: 40px !important;
  line-height: 40px !important;
}
.scheduler_default_cell,
.scheduler_default_cell_business,
.scheduler_default_cell {
  height: 50px !important;
}
.scheduler_default_event {
  height: 50px !important;
  line-height: 50px !important;
} */

/* .scheduler_default_event_float {
  inset: -25px 0px 0px 100px !important;
} */

/* scheduler_default_event_inner */
</style>
