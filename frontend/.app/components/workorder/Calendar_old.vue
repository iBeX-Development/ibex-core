<script>
import { Qalendar } from 'qalendar'
import { onMounted, ref, watch } from 'vue'
// import { useDirectusItems } from '@directus/sdk-js' // Import the Directus hook

export default {
  components: {
    Qalendar,
  },

  setup(props, { emit }) {
    const current_date = ref(new Date())
    const events = ref([])
    const loading = ref(false)
    const qalendarRef = ref(null)
    const { getItems, updateItem } = useDirectusItems()
    const isFullView = ref(true)
    const calendarKey = ref(0)

    const config = ref({
      defaultMode: 'month',
      mode: 'month',
      isSmall: false,
      eventClickEnabled: true,
      dragAndDropEnabled: true,
      dayBoundaries: {
        start: 0,
        end: 24,
      },
    })

    const toggleViewMode = async () => {
      isFullView.value = !isFullView.value

      // Set the appropriate mode
      config.value = {
        ...config.value,
        isSmall: !isFullView.value,
      }

      // Force re-render with a slight delay to ensure DOM updates
      calendarKey.value++

      // Allow time for component to re-render
      setTimeout(() => {
        // Manually trigger event resize/reposition if needed
        if (qalendarRef.value) {
          console.log('Refreshing calendar view after mode toggle')
        }

        // Force update CSS visibility
        const eventLists = document.querySelectorAll(
          '.agenda__content-events-list, .calendar-month__day_events',
        )
        eventLists.forEach((el) => {
          if (!isFullView.value) {
            el.style.display = 'block'
            el.style.visibility = 'visible'
          }
        })

        // Re-establish event listeners
        setupEventListeners()
      }, 300)
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
        0, // Last day of current month (changed from 1)
      ).toISOString()

      try {
        const filters = {
          status: { _neq: 3 },
          active: 1,
          due: {
            _gte: startOfMonth,
            _lte: endOfMonth,
          },
        }
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

        if (items && items.data) {
          events.value = transformEvents(items)
          console.log('Loaded events:', events.value)
        } else {
          console.error('No data received from API:', items)
          events.value = []
        }
      } catch (e) {
        console.error('Error loading items:', e)
        events.value = []
      } finally {
        loading.value = false
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
      if (!items || !items.data || !Array.isArray(items.data)) {
        console.error('Invalid items data format:', items)
        return []
      }

      return items.data
        .map((event) => {
          // Use due date for both start and end if start is missing
          const startDate = event.start
            ? new Date(event.start)
            : event.due
            ? new Date(event.due)
            : null
          const dueDate = event.due
            ? new Date(event.due)
            : event.start
            ? new Date(event.start)
            : null

          if (
            !startDate ||
            !dueDate ||
            isNaN(startDate.getTime()) ||
            isNaN(dueDate.getTime())
          ) {
            console.warn(`Skipping event due to invalid dates:`, event)
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

          // Ensure end date is not before start date
          const finalEndDate =
            new Date(formattedEnd) < new Date(formattedStart)
              ? formattedStart
              : formattedEnd

          const eventColor = getEventColor(startDate, dueDate)

          return {
            title: event.name || 'No Title',
            time: {
              start: formattedStart,
              end: finalEndDate,
            },
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

      try {
        // Convert string dates to Date objects
        const newStartDate = new Date(updatedEvent.time.start)
        const newDueDate = new Date(updatedEvent.time.end)

        // Update the data object with new dates
        updatedEvent.data.due = newDueDate.toISOString()
        if (updatedEvent.data.start) {
          updatedEvent.data.start = newStartDate.toISOString()
        }

        // Update the color based on new dates
        updatedEvent.color = getEventColor(newStartDate, newDueDate)

        const data = {
          collection: 'Work_order',
          id: updatedEvent.id,
          item: updatedEvent.data,
        }

        await updateItem(data)
        console.log('Event updated successfully in backend!')

        // Update the event in the local array
        const eventIndex = events.value.findIndex(
          (event) => event.id === updatedEvent.id,
        )

        if (eventIndex !== -1) {
          events.value[eventIndex] = { ...updatedEvent }
        }
      } catch (error) {
        console.error('Error updating event:', error)
      }
    }

    // Handle event click from Qalendar component
    const handleEventClick = (eventData) => {
      console.log('Event clicked via Qalendar event:', eventData)
      processEventClick(eventData)
    }

    // Unified event click processing function
    const processEventClick = (eventData) => {
      if (!eventData) {
        console.error('No event data provided to click handler')
        return
      }

      console.log('Processing event click for:', eventData)

      try {
        // Emit an event to parent component
        emit('event-clicked', eventData.data || eventData)

        // Alternative approach with direct navigation
        // router.push(`/work-orders/${eventData.id}`)

        // Alert for testing purposes
        const title =
          eventData.title ||
          (eventData.data && eventData.data.name) ||
          'Unknown'
        const id =
          eventData.id || (eventData.data && eventData.data.id) || 'Unknown'
        alert(`Event clicked: ${title} (ID: ${id})`)

        // You could also open a modal here
        // showEventModal.value = true
        // selectedEvent.value = eventData
      } catch (error) {
        console.error('Error processing event click:', error)
      }
    }

    // Custom event click handler for direct DOM events
    const handleCustomEventClick = (event, eventId) => {
      event.preventDefault()
      event.stopPropagation()

      console.log('Custom event click handler triggered for ID:', eventId)

      // Find the event data by ID
      const clickedEvent = events.value.find((e) => e.id === eventId)
      if (clickedEvent) {
        processEventClick(clickedEvent)
      } else {
        console.error('Could not find event with ID:', eventId)
      }
    }

    // Watch for current_date changes to reload events
    watch(current_date, () => {
      loadItems()
    })

    // Watch for events changes to set up listeners
    watch(
      events,
      () => {
        // Wait for DOM to update with new events
        setTimeout(() => {
          setupEventListeners()
        }, 200)
      },
      { deep: true },
    )

    // Handle month change event from Qalendar
    const handleMonthChange = (newDate) => {
      current_date.value = new Date(newDate)
    }

    onMounted(async () => {
      await loadItems()
      console.log('Final Events Array for Qalendar:', events.value)

      // Ensure events are visible and clickable in all views
      setTimeout(() => {
        setupEventListeners()
      }, 500)
    })

    // Setup global event listeners for calendar events
    const setupEventListeners = () => {
      console.log('Setting up direct event listeners')

      // First remove any existing listeners to avoid duplicates
      document.removeEventListener('click', globalEventClickHandler)

      // Add global click handler for event elements
      document.addEventListener('click', globalEventClickHandler)

      // Also directly attach to known event elements
      const eventElements = document.querySelectorAll(
        '.custom-event, .calendar-month__event, .agenda__event',
      )
      console.log('Found event elements:', eventElements.length)

      eventElements.forEach((el) => {
        // Ensure basic styling
        el.style.pointerEvents = 'auto'
        el.style.cursor = 'pointer'

        // Get event ID from data attribute if possible
        const eventId = el.dataset.eventId || el.getAttribute('data-event-id')

        // Remove existing listeners to avoid duplicates
        el.removeEventListener('click', directElementClickHandler)

        // Add direct click handler
        el.addEventListener('click', directElementClickHandler)
      })
    }

    // Global event click handler to catch all event clicks
    const globalEventClickHandler = (e) => {
      // Find the nearest event element
      const eventElement = e.target.closest(
        '.custom-event, .calendar-month__event, .agenda__event',
      )
      if (!eventElement) return

      console.log('Global click handler caught event element click')

      // Stop event propagation
      e.stopPropagation()
      e.preventDefault()

      // Try to get event ID
      const eventId =
        eventElement.dataset.eventId ||
        eventElement.getAttribute('data-event-id')
      if (eventId) {
        console.log('Found event ID from element:', eventId)
        const clickedEvent = events.value.find((e) => e.id === eventId)
        if (clickedEvent) {
          processEventClick(clickedEvent)
        }
      } else {
        console.log('Could not find event ID, trying title match')
        // Try to match by title if visible in the element
        const title = eventElement.textContent.trim()
        if (title) {
          const clickedEvent = events.value.find((e) => e.title === title)
          if (clickedEvent) {
            processEventClick(clickedEvent)
          }
        }
      }
    }

    // Direct element click handler
    const directElementClickHandler = (e) => {
      console.log('Direct element click handler triggered')
      e.stopPropagation()
      e.preventDefault()

      const element = e.currentTarget
      const eventId =
        element.dataset.eventId || element.getAttribute('data-event-id')

      if (eventId) {
        const clickedEvent = events.value.find((e) => e.id === eventId)
        if (clickedEvent) {
          processEventClick(clickedEvent)
        }
      }
    }

    return {
      events,
      config,
      calendarKey,
      isFullView,
      toggleViewMode,
      testEventWasDragged,
      handleMonthChange,
      handleEventClick,
      handleCustomEventClick,
      processEventClick,
    }
  },
}
</script>

<template>
  <div>
    <div class="flex justify-end mb-2">
      <button
        @click="toggleViewMode"
        class="px-3 py-1 text-sm rounded bg-gray-200 hover:bg-gray-300"
      >
        {{ isFullView ? 'Small' : 'Full' }}
      </button>
    </div>
    <div
      :class="[
        'calendar-container is-light-mode calendar-root',
        { 'qalendar-is-small': !isFullView },
      ]"
    >
      <Qalendar
        :events="events"
        :config="config"
        :key="calendarKey"
        @event-was-dragged="testEventWasDragged"
        @month-changed="handleMonthChange"
        @event-was-clicked="handleEventClick"
        @event-creation="setupEventListeners"
        @event-deletion="setupEventListeners"
        @event-restore="setupEventListeners"
        @day-was-clicked="setupEventListeners"
        @calendar-did-mount="setupEventListeners"
        ref="qalendarRef"
      >
        <template #event="{ event }">
          <div
            class="custom-event"
            :style="{ backgroundColor: event.color }"
            @click.stop.prevent="handleCustomEventClick($event, event.id)"
            :data-event-id="event.id"
          >
            {{ event.title }}
          </div>
        </template>
      </Qalendar>
    </div>
  </div>
</template>

<style>
@import 'qalendar/dist/style.css';

/* Small view дээр events-ийг гаргах */
.qalendar-is-small .agenda__content-events-list,
.qalendar-is-small .calendar-month__day_events {
  display: block !important;
  visibility: visible !important;
  max-height: none;
  overflow-y: visible;
}

.qalendar-is-small .agenda__event,
.qalendar-is-small .calendar-month__event {
  display: block !important;
  visibility: visible !important;
  padding: 2px 4px;
  white-space: nowrap;
  text-overflow: ellipsis;
  overflow: hidden;
  pointer-events: auto !important;
}

/* Make sure events are clickable in all views */
.custom-event,
.calendar-month__event,
.agenda__event,
.calendar-month__event-title {
  cursor: pointer !important;
  pointer-events: auto !important;
  position: relative;
  z-index: 999 !important;
}

/* Fix for events in small view */
.qalendar-is-small .calendar-month__day,
.qalendar-is-small .calendar-month__day_events,
.qalendar-is-small .agenda__event-wrapper {
  height: auto !important;
  min-height: 30px !important;
  overflow: visible !important;
  position: relative !important;
  z-index: 10 !important;
}

.calendar-container {
  width: 100%;
  height: 1200px;
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
