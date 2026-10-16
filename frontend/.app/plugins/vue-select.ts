import VueSelect from "vs-vue3-select";
import 'vs-vue3-select/dist/vs-vue3-select.css'

export default defineNuxtPlugin(async (nuxtApp) => {
  // nuxtApp.vueApp.use(vSelect)
  nuxtApp.vueApp.component('v-select-dropdown', VueSelect);
})
