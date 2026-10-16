<script setup>
import { defineComponent, ref, watchEffect } from 'vue'
import { useI18n } from 'vue-i18n'

// const _comp = ref()
const uploadFiles = ref([])
const readFile = ref(true)

const { t } = useI18n({ useScope: 'global' })
const runtimeConfig = useRuntimeConfig()
const { token } = useDirectusToken()
const progress = ref(0)
const loading = ref(true)
const isUploaded = ref(false)

const uploadedFiles = ref([])
const currentAvatar = computed(() => '/img/avatars/company.svg')

const props = defineProps({
  code: String,
  height: String || '240px',
  width: String || '240px',
  xmargin: String,
  field: String,
  id: String,
  result: Array,
  fileUrl: String || File,
  UploadedVideo: Object || File,
  clearItem: Function,
})

defineComponent({
  name: 'AvatarUpload',
})

// const emit = defineEmits(['update:UploadedVideo'])

const uploadFile = async (file) => {
  // loading.value = true
  let url = runtimeConfig.public.directus.url + `files`
  // const fileReference = toRef(file)
  progress.value = 0
  const formData = new FormData()
  formData.append('file', file)
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token.value}`,
    },
    body: formData,
  })
  const jsonData = await response.json()
  console.log('uploadedFile')
  // loading.value = false
  // isUploaded.value = true

  if (props.result) {
    props.result.push(jsonData.data)
    // emit('update:UploadedVideo', jsonData.data)
  }
  // uploadFiles.value = []
  // readFile.value = true
  progress.value = 100
}

const isReadFile = (is_show) => {
  readFile.value = is_show
}

watchEffect(() => {
  if (uploadFiles.value.length && readFile.value === false) {
    uploadFile(uploadFiles.value[uploadFiles.value.length - 1])
  }
})

const ThumbnailVideo = computed(() => {
  if (loading.value) {
    return '/img/utils/loading.gif' // Show loading image while uploading
  } else if (isUploaded.value) {
    return '/img/utils/uploaded.png' // Show uploaded image when done
  }
  return '/img/utils/uploaded.png' // Default state (you can change this if needed)
})
</script>

<template>
  <div class="max-w-xl">
    <BaseInputFileHeadlessOverrided
      v-slot="{ open, remove, preview, drop, files, is_read }"
      v-model="uploadFiles"
      multiple
      ref="_comp"
      :id="props.id"
      :fileUrl="props.fileUrl"
    >
      <div
        role="button"
        tabindex="-1"
        class=""
        @dragenter.stop.prevent
        @dragover.stop.prevent
        @drop="drop"
      >
        <div
          v-if="!files?.length"
          :style="{ height: props.height, width: props.width }"
          :class="[
            `h-[${props.height}] w-[${props.width}]`,
            'mb-3 nui-focus border-muted-300 dark:border-muted-700 hover:border-muted-400 focus:border-muted-400 dark:hover:border-muted-600 dark:focus:border-muted-700',
            'group cursor-pointer rounded-lg border-[3px] border-dashed p-8 transition-colors duration-300',
          ]"
          tabindex="0"
          role="button"
          @click="open"
          @keydown.enter.prevent="open"
        >
          <div v-if="code == 'users'" class="p-5 text-center">
            <Icon
              name="mdi-light:cloud-upload"
              class="text-muted-400 group-hover:text-primary-500 group-focus:text-primary-500 mb-2 size-10 transition-colors duration-300"
            />

            <h4 class="text-muted-400 font-sans text-sm">{{ t('Avatar') }}</h4>
          </div>

          <div v-if="code == 'Company'" class="p-5 text-center">
            <img
              :src="currentAvatar"
              alt="Upload preview"
              class="bg-muted-200 dark:bg-muted-700/60 h-20 w-20 rounded-full object-cover object-center dark:invert"
            />
            <h4 class="text-muted-400 font-sans text-sm">{{ t('Logo') }}</h4>
          </div>
          <div v-if="code == 'LoginImg'" class="text-center">
            <h4 class="text-muted-400 font-sans text-sm">{{ t('Image') }}</h4>
          </div>
          <div v-if="code == 'Video'" class="text-center">
            <h4 class="text-muted-400 font-sans text-sm">{{ t('Video') }}</h4>
          </div>
          <div v-if="code == 'File'" class="text-center">
            <h4 class="text-muted-400 font-sans text-sm">{{ t('File') }}</h4>
          </div>
        </div>

        <ul v-else class="space-y-2">
          <li v-for="file in files" :key="file.name">
            <div class="relative flex items-center justify-start rounded-xl">
              <div
                class="flex items-center border border-muted-300 rounded-[13px]"
              >
                <div class="shrink-0">
                  <img
                    v-if="file.type.startsWith('image')"
                    :style="{ height: props.height, width: props.width }"
                    :class="['rounded-xl object-cover object-center']"
                    :src="preview(file).value"
                    alt="Image preview"
                  />

                  <div
                    v-else
                    class="ms-auto w-[260px] px-4 transition-opacity duration-300"
                    :class="'opacity-100'"
                  >
                    <!-- <BaseProgress
                      :value="progress"
                      size="xs"
                      :color="'success'"
                    /> -->
                    <img
                      :style="{
                        height: progress == 100 ? props.height : '30px',
                        width: progress == 100 ? props.width : '30px',
                        margin: progress == 100 ? '0px' : '36px auto',
                      }"
                      :class="['rounded-xl object-contain object-center']"
                      :src="
                        progress == 100
                          ? '/img/utils/uploaded.png'
                          : '/img/utils/loading.gif'
                      "
                      alt="Image preview"
                    />
                  </div>
                </div>

                <div class="file-status">
                  {{ isReadFile(is_read) }}
                </div>
              </div>

              <div class="flex" :style="{ margin: props.xmargin }">
                <button
                  class="border-muted-200 hover:border-primary-500 text-muted-700 dark:text-muted-200 hover:text-primary-600 dark:border-muted-700 dark:bg-muted-900 dark:hover:border-primary-500 dark:hover:text-primary-600 relative flex size-8 cursor-pointer items-center justify-center rounded-full border bg-white transition-colors duration-300"
                  type="button"
                  tooltip="Remove"
                  @click.prevent="remove(file)"
                >
                  <Icon name="lucide:x" class="size-4" />
                  <span class="sr-only">{{ t('Remove') }}</span>
                </button>
              </div>
            </div>
          </li>
        </ul>
      </div>
    </BaseInputFileHeadlessOverrided>
    <FormKit :name="props.field" type="hidden" />
  </div>
</template>
