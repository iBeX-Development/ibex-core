import { createVuetify } from 'vuetify'
import { VCalendar } from 'vuetify/labs/VCalendar'
export default defineNuxtPlugin(async (nuxtApp) => {

    const vuetify = createVuetify({
      styles: { configFile: "assets/global.scss" },
      theme: {
        defaultTheme: 'light',
        options: {
          customProperties: true,
        }
      },
      components: {
          VCalendar,
      },
    });

    nuxtApp.vueApp.use(vuetify)

})
