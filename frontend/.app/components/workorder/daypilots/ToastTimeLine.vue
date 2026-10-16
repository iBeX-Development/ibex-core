<!-- <template>
  <div id="app">
    <calendar
      ref="calendar"
      :options="calendarOptions"
      :events="events"
      @selectDateTime="onSelectDateTime"
      @clickEvent="onClickEvent"
      @beforeCreateEvent="onBeforeCreateEvent"
      @beforeUpdateEvent="onBeforeUpdateEvent"
      @beforeDeleteEvent="onBeforeDeleteEvent"
    />
  </div>
</template>

<script>
import '@toast-ui/calendar/dist/toastui-calendar.min.css'
import Calendar from '@toast-ui/vue-calendar'

export default {
  name: 'App',

  components: {
    Calendar,
  },

  data() {
    return {
      calendarOptions: {
        defaultView: 'week',
        useCreationPopup: true,
        useDetailPopup: true,
        calendars: [
          {
            id: '1',
            name: 'My Calendar',
            color: '#ffffff',
            bgColor: '#9e5fff',
            dragBgColor: '#9e5fff',
            borderColor: '#9e5fff',
          },
        ],
      },
      events: [
        {
          id: '1',
          calendarId: '1',
          title: 'A schedule',
          category: 'time',
          dueDateClass: '',
          start: '2018-05-22T22:30:00+09:00',
          end: '2018-05-23T02:30:00+09:00',
        },
        {
          id: '2',
          calendarId: '1',
          title: 'Another schedule',
          category: 'time',
          dueDateClass: '',
          start: '2018-05-23T17:30:00+09:00',
          end: '2018-05-24T17:31:00+09:00',
          isReadOnly: true,
        },
      ],
    }
  },

  methods: {
    onSelectDateTime(info) {
      console.log('Selected:', info)
    },

    onClickEvent(info) {
      console.log('Event clicked:', info.event.title)
    },

    onBeforeCreateEvent(eventData) {
      console.log('Creating event:', eventData)
    },

    onBeforeUpdateEvent(updateData) {
      console.log('Updating event:', updateData)
    },

    onBeforeDeleteEvent(deleteData) {
      console.log('Deleting event:', deleteData)
    },

    // Method to programmatically add events
    addEvent(eventData) {
      this.events.push(eventData)
    },

    // Method to remove events
    removeEvent(eventId) {
      this.events = this.events.filter((event) => event.id !== eventId)
    },
  },

  mounted() {
    // You can access calendar instance methods here
    console.log('Calendar mounted')
  },
}
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  padding: 20px;
}

/* Custom calendar styling */
.toastui-calendar {
  height: 600px;
}
</style> -->
