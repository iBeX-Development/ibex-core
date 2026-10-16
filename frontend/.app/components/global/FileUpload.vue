<script setup>
import { defineComponent, ref, watchEffect } from 'vue'
import { useI18n } from 'vue-i18n'
// const _comp = ref()
const { t } = useI18n({ useScope: 'global' })
const uploadFiles = ref([])
const runtimeConfig = useRuntimeConfig()
const { token } = useDirectusToken()
const progress = ref(0)
const uploadedFileIds = ref([])
const uploadedFiles = ref([])

const readFile = ref(true)

const props = defineProps({
  code: String,
  field: String,
  id: String,
  result: Array,
  runResult: Function,
  remove: Function,
  multiple: Boolean,
  plus: Boolean,
  hideText: Boolean,
  disabled: Boolean,
  fileUrl: String || File,
  imageH: String,
  imageW: String,
  style: String,
  xstyle: String,
  buttonStyle: String,
  imgParentstyle: String,
  emptyStyle: String,
  widthSize: String,
})

defineComponent({
  name: 'FileUpload',
})

const uploadFile = async (file, upload_Files) => {
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
  // console.log(jsonData)
  if (props.result) {
    props.result.push(jsonData.data)
  }
  if (props.runResult) {
    props.runResult(jsonData.data)
  }
  console.log('Uploaded result: ', jsonData)
  uploadedFileIds.value.push(jsonData.data.id)
  uploadedFiles.value.push(jsonData.data)

  progress.value = 100
}

const isReadFile = (is_show) => {
  readFile.value = is_show
}

const removed = (file, remove) => {
  remove(file)
  props.remove(file)
}

watchEffect(() => {
  if (uploadFiles.value.length && readFile.value === false) {
    // console.log(uploadedFiles.value);
    // do something when data is loaded

    if (props.multiple) {
      const array = Object.values(uploadFiles.value)
      array.map((file, index) => {
        uploadFile(file, uploadFiles)
      })
    } else {
      uploadFile(uploadFiles.value[uploadFiles.value.length - 1], uploadFiles)
    }
  }
})
</script>

<template>
  <div
    :class="widthSize ? widthSize : 'max-w-2xl'"
    style="height: 100%; width: 100%"
  >
    <BaseInputFileHeadlessOverrided
      v-slot="{ open, remove, preview, drop, files, is_read }"
      v-model="uploadFiles"
      :multiple="props.multiple"
      ref="_comp"
      :fileUrl="props.fileUrl"
    >
      <!-- Controls -->
      <div class="mb-4 flex items-center gap-2" v-if="plus">
        <button
          type="button"
          class="nui-focus border-muted-200 hover:border-primary-500 text-muted-700 dark:text-muted-200 hover:text-primary-600 dark:border-muted-700 dark:bg-muted-800 dark:hover:border-primary-500 dark:hover:text-primary-600 relative flex size-8 cursor-pointer items-center justify-center rounded-full border bg-white transition-colors duration-300"
          tooltip="Select files"
          @click="open"
        >
          <Icon name="lucide:plus" class="size-4" />

          <span class="sr-only">{{ t('Select files') }}</span>
        </button>
      </div>

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
          :style="[props.emptyStyle ? `${props.emptyStyle}] ` : '']"
          class="nui-focus border-muted-300 dark:border-muted-700 hover:border-muted-400 focus:border-muted-400 dark:hover:border-muted-600 dark:focus:border-muted-700 group cursor-pointer rounded-lg border-[3px] border-dashed p-8 transition-colors duration-300"
          tabindex="0"
          role="button"
          @click="open"
          @keydown.enter.prevent="open"
        >
          <div v-if="props.hideText" class="flex justify-center -mt-[16px]">
            <Icon
              name="mdi-light:cloud-upload"
              class="text-muted-400 group-hover:text-primary-500 group-focus:text-primary-500 mb-2 size-6 transition-colors duration-300"
            />
          </div>
          <div v-if="!props.hideText" class="p-5 text-center">
            <Icon
              name="mdi-light:cloud-upload"
              class="text-muted-400 group-hover:text-primary-500 group-focus:text-primary-500 mb-2 size-10 transition-colors duration-300"
            />

            <h4 class="text-muted-400 font-sans text-sm">
              {{ t('Drag and drop files here') }}
            </h4>

            <div>
              <span
                class="text-muted-400 font-sans text-[0.7rem] font-semibold uppercase"
              >
                {{ t('Or') }}
              </span>
            </div>

            <label
              for="file"
              class="text-muted-400 group-hover:text-primary-500 group-focus:text-primary-500 cursor-pointer font-sans text-sm underline underline-offset-4 transition-colors duration-300"
            >
              {{ t('Select files') }}
            </label>
          </div>
        </div>

        <div v-else class="flex flex-wrap gap-3 fileBox">
          <div
            class="file"
            v-for="file in files"
            :key="file.name"
            :style="{
              width: props.imageW ? props.imageW : '',
              height: props.imageH ? props.imageH : '',
            }"
          >
            <div
              class="parent relative rounded-xl bg-white dark:bg-muted-800 border border-gray-200 dark:border-muted-700"
              :style="{
                width: props.imageW ? props.imageW : '80px',
                height: props.imageH ? props.imageH : '72px',
              }"
            >
              <img
                v-if="file.type.startsWith('image')"
                :class="[
                  'rounded-lg object-cover object-center h-full',
                  props.imageW ? '' : 'w-full',
                ]"
                :style="props.imageW ? { width: props.imageW } : {}"
                :src="preview(file).value"
                alt="Image preview"
              />
              <img
                v-else
                :class="[
                  'rounded-lg object-cover object-center h-full',
                  props.imageW ? '' : 'w-full',
                ]"
                :style="props.imageW ? { width: props.imageW } : {}"
                src="/img/avatars/placeholder-file.png"
                alt="Image preview"
              />
              <p class="text-[10px] text-muted-400 truncate mt-1 px-0.5">
                {{ file.name }}
              </p>
              <div class="file-status hidden">
                {{ isReadFile(is_read) }}
              </div>
              <button
                v-if="!props.disabled"
                class="fu-remove-btn"
                type="button"
                @click.prevent="removed(file, remove)"
              >
                <Icon name="lucide:x" class="size-2.5" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </BaseInputFileHeadlessOverrided>
    <FormKit :name="props.field" type="hidden" v-model="uploadedFileIds" />
  </div>
</template>

<style>
.fu-remove-btn {
  position: absolute;
  top: -6px;
  right: -6px;
  width: 18px;
  height: 18px;
  border-radius: 999px;
  background: #ef4444;
  color: #fff;
  border: 2px solid #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  z-index: 1;
}
.fu-remove-btn:hover {
  background: #dc2626;
}
</style>
