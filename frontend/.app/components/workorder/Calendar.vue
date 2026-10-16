<template>
  <div class="calendar-container is-light-mode">
    <Qalendar
      :events="events"
      :config="config"
      @event-was-dragged="testEventWasDragged"
    >
      <template #event="{ event }">
        <div class="custom-event" :style="{ backgroundColor: event.color }">
          {{ event.title }}
        </div>
      </template>
    </Qalendar>
  </div>
</template>

<script>
import { Qalendar } from 'qalendar'
import { onMounted, ref } from 'vue'

export default {
  components: {
    Qalendar,
  },

  setup() {
    const current_date = ref(new Date())
    const events = ref([])
    const loading = ref(false)
    const qalendarRef = ref(null)
    const { getItems, updateItem } = useDirectusItems()

    const config = {
      defaultMode: 'month',
      dayBoundaries: {
        start: 6,
        end: 3,
      },
    }

    const loadItems = async () => {
      loading.value = true
      const startOfMonth = new Date(
        current_date.value.getFullYear(),
        current_date.value.getMonth(),
        1,
      ).toISOString()
      const endOfMonth = new Date(
        current_date.value.getFullYear(),
        current_date.value.getMonth() + 1,
        1,
      ).toISOString()
      try {
        const filters = {
          wo_status: { _neq: 3 },
          active: 1,
          due: {
            _gte: startOfMonth,
            _lte: endOfMonth,
          },
        }
        console.log('hie', filters)
        const items = await getItems({
          collection: 'Work_order',
          params: {
            filter: filters,
            limit: -1,
            page: 1,
            meta: 'filter_count',
            fields: ['*', 'assigned_to.first_name', 'assigned_team.name'],
          },
        })
        events.value = transformEvents(items)
        loading.value = false
      } catch (e) {
        console.error(e)
      }
    }

    const getEventColor = (startDate, dueDate) => {
      const now = new Date()
      if (now > dueDate) {
        return 'red'
      } else if (now < startDate) {
        return 'blue'
      } else {
        const daysUntilDue = Math.floor(
          (dueDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24),
        )
        return daysUntilDue <= 3 ? 'green' : 'blue'
      }
    }

    const transformEvents = (items) => {
      return items.data
        .map((event) => {
          const startDate = event.start
            ? new Date(event.start)
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

          const formatDate = (date) => {
            const year = date.getFullYear()
            const month = String(date.getMonth() + 1).padStart(2, '0')
            const day = String(date.getDate()).padStart(2, '0')
            return `${year}-${month}-${day}`
          }

          const formattedStart = formatDate(startDate)
          const formattedEnd = formatDate(dueDate)

          const eventColor = getEventColor(startDate, dueDate)

          return {
            title: event.name || 'No Title',
            time: { start: formattedStart, end: formattedEnd },
            isEditable: true,
            color: eventColor,
            id: event.id || Math.random().toString(36).substr(2, 9),
            data: event,
          }
        })
        .filter((event) => event !== null)
    }

    const testEventWasDragged = async (updatedEvent) => {
      console.log('Event was dragged:', updatedEvent)

      updatedEvent.data.due = updatedEvent.time.end

      const newStartDate = new Date(updatedEvent.time.start)
      const newDueDate = new Date(updatedEvent.time.end)
      updatedEvent.color = getEventColor(newStartDate, newDueDate)

      const data = {
        collection: 'Work_order',
        id: updatedEvent.id,
        item: updatedEvent.data,
      }

      try {
        await updateItem(data)
        console.log('Event updated successfully in backend!')
      } catch (error) {
        console.error('An unexpected error occurred:', error)
      }

      const eventIndex = events.value.findIndex(
        (event) => event.id === updatedEvent.id,
      )
      if (eventIndex !== -1) {
        events.value[eventIndex].color = updatedEvent.color
      }
    }

    onMounted(async () => {
      await loadItems()
      console.log('Final Events Array for Qalendar:', events.value)
    })

    return {
      events,
      config,
      testEventWasDragged,
    }
  },
}
</script>

<style>
@import 'qalendar/dist/style.css';

.calendar-container {
  width: 100%;
  height: 800px;
}

.custom-event {
  padding: 4px;
  border-radius: 4px;
  font-size: 0.875rem;
  font-weight: bold;
  display: inline-block;
  text-align: center;
  width: 100%;
  box-sizing: border-box;
}
</style>
