import { VueDraggableNext} from "vue-draggable-next";

export default defineNuxtPlugin(async (nuxtApp) => {
  nuxtApp.vueApp.use(VueDraggableNext)
})
