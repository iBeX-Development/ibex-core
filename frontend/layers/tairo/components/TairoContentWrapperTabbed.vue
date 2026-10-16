<script setup lang="ts">
import { computed, reactive, ref } from 'vue'

const props = withDefaults(
  defineProps<{
    title?: string
    class?: string
    style?: string
    shape?: 'straight' | 'rounded' | 'curved' | 'full'
    labels: string[]
    reverse?: boolean
  }>(),
  {
    class: '',
    style: '',
    shape: 'rounded',
    title: undefined,
  },
)

const activeTab = ref('tab-1')
// Зөвхөн нэг удаа ч гэсэн идэвхжсэн tab-уудыг л render хийнэ (lazy mount).
// Ингэснээр анх ачаалахад идэвхгүй tab-ын component-ууд (жишээ нь Performance,
// DayPilot) шаардлагагүй Directus request илгээхээс сэргийлнэ. Идэвхжсэний
// дараа v-show ашиглаж component-ийн state-ийг хадгална (дахин fetch хийхгүй).
const visitedTabs = reactive(new Set(['tab-1']))
const emit = defineEmits(['update:modelValue'])

const marginClass = computed(() => {
  const length = props.labels.length
  if (length === 3) {
    return activeTab.value === 'tab-1'
      ? 'ms-0'
      : activeTab.value === 'tab-2'
      ? 'ms-[33%]'
      : 'ms-[66%]'
  } else {
    return activeTab.value === 'tab-1' ? 'ms-0' : 'ms-[50%]'
  }
})

// 🚀 `widthStyle`-ийг динамикаар оноох
const widthStyle = computed(() => {
  return { width: `${100 / props.labels.length}%` }
})

// Watch for activeTab changes to emit the update
watch(activeTab, (newTab) => {
  visitedTabs.add(newTab)
  emit('update:modelValue', newTab)
})
</script>

<template>
  <div>
    <div
      class="mb-6 flex w-full flex-col items-center justify-between gap-4 sm:flex-row"
      :class="props.reverse && 'sm:flex-row-reverse'"
      :style="props.style"
    >
      <slot name="left"></slot>
      <slot name="right">
        <div :class="['w-full sm:w-auto', props.class]">
          <div
            class="dark:bg-muted-800 relative flex h-9 w-full bg-white"
            :class="[
              props.shape === 'rounded' ? 'rounded-md' : '',
              props.shape === 'curved' ? 'rounded-xl' : '',
              props.shape === 'full' ? 'rounded-full' : '',
              props.labels.length === 2
                ? 'sm:w-60'
                : props.labels.length === 3
                ? 'sm:w-80'
                : props.labels.length === 4
                ? 'sm:w-100'
                : props.labels.length === 5
                ? 'sm:w-120'
                : 'w-full',
            ]"
          >
            <button
              v-for="(label, index) in props.labels"
              :key="index"
              type="button"
              :class="[
                'nui-focus relative z-10 whitespace-nowrap flex flex-1 cursor-pointer items-center justify-center font-sans text-sm transition-colors duration-300',
                props.class, // dynamic external class
                activeTab === `tab-${index + 1}`
                  ? 'text-white'
                  : 'text-muted-400',
                props.shape === 'rounded' ? 'rounded-md' : '',
                props.shape === 'curved' ? 'rounded-xl' : '',
                props.shape === 'full' ? 'rounded-full' : '',
              ]"
              @click="activeTab = `tab-${index + 1}`"
            >
              {{ label }}
            </button>

            <div
              class="bg-primary-500 absolute start-0 top-0 h-full transition-all duration-300 ease-in-out"
              :class="[
                marginClass,
                props.shape === 'rounded' ? 'rounded-md' : '',
                props.shape === 'curved' ? 'rounded-xl' : '',
                props.shape === 'full' ? 'rounded-full' : '',
              ]"
              :style="widthStyle"
            ></div>
          </div>
        </div>
      </slot>
    </div>

    <div>
      <div
        v-for="(label, index) in props.labels"
        :key="index"
        :value="props.value"
        v-show="activeTab === `tab-${index + 1}`"
      >
        <slot
          v-if="visitedTabs.has(`tab-${index + 1}`)"
          :name="`tab-${index + 1}`"
        ></slot>
      </div>
    </div>

    <slot></slot>
  </div>
</template>
