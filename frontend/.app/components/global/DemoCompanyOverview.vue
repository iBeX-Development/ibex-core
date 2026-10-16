<script setup lang="ts">
import 'v-calendar/dist/style.css'
import '~/assets/css/vcalendar.css'

const props = defineProps({
  open: Boolean,
  data: Object,
})

const route = useRoute()
const router = useRouter()
const page = computed(() => parseInt((route.query.page as string) ?? '1'))
const { open } = usePanels()
const { getItems } = useDirectusItems()
const user = useDirectusUser()
const config = useRuntimeConfig()

const filter = ref('')
const perPage = ref(10)

const search = ref('')
const serverItems = ref<Record<string, any> | null>(null)
let picture = '/img/icons/logos/slicer.svg'

// console.log('props_over', props)

if (props.data) {
  serverItems.value = props.data[0]
  picture = props.data[0]?.picture
}
</script>
<template>
  <div class="flex h-full flex-col">
    <div class="relative mx-auto mb-4 size-20">
      <BaseAvatar size="xl" :src="picture" />
    </div>
    <div class="text-center">
      <BaseHeading
        size="md"
        weight="medium"
        class="text-muted-800 dark:text-muted-100"
      >
        <span>{{ serverItems?.name }}</span>
      </BaseHeading>
      <BaseParagraph size="xs" class="text-muted-400 mb-2">
        <span>{{ serverItems?.register }}</span>
      </BaseParagraph>
      <BaseParagraph
        size="sm"
        class="text-muted-500 dark:text-muted-400 mx-auto max-w-[320px]"
      >
        <span>
          {{ serverItems?.category }}
        </span>
      </BaseParagraph>
    </div>
    <div
      class="border-muted-200 dark:border-muted-700 mt-auto border-t pt-6 text-center"
    >
      <div
        class="divide-muted-200 dark:divide-muted-700 flex w-full items-center divide-x"
      >
        <!-- Item -->
        <div class="flex-1">
          <div class="flex flex-col px-4 text-center">
            <h4
              class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
            >
              864
            </h4>
            <p
              class="font-sansfont-semibold text-muted-400 text-[0.65rem] uppercase"
            >
              Posts
            </p>
          </div>
        </div>
        <!-- Item -->
        <div class="flex-1">
          <div class="flex flex-col px-4 text-center">
            <h4
              class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
            >
              247
            </h4>
            <p
              class="text-muted-400 font-sans text-[0.65rem] font-semibold uppercase"
            >
              Projects
            </p>
          </div>
        </div>
        <!-- Item -->
        <div class="flex-1">
          <div class="flex flex-col px-4 text-center">
            <h4
              class="text-muted-800 dark:text-muted-100 font-sans text-xl font-semibold"
            >
              19k
            </h4>
            <p
              class="font-sansfont-semibold text-muted-400 text-[0.65rem] uppercase"
            >
              Followers
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
