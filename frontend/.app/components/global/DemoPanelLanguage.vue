<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

const { close } = usePanels()
const colorMode = useColorMode()
const { locale } = useI18n({ useScope: 'global' })

type Language = { code: string; label: string; flag?: string; icon?: string }

const activeLangs = ref<string[]>(['en', 'mn'])
const languages = ref<Language[]>([])
const loading = ref(true)

const activeLanguages = computed(() =>
  activeLangs.value
    .map((code) => languages.value.find((language) => language.code === code))
    .filter((language): language is Language => Boolean(language)),
)

onMounted(async () => {
  try {
    const data = await $fetch<any>('/api/translations')
    if (data?.config?.active?.length) activeLangs.value = data.config.active
    languages.value = data?.config?.languages ?? []
  } catch {}
  loading.value = false
})
</script>

<template>
  <div
    class="border"
    :class="
      colorMode.value === 'dark'
        ? 'border-muted-700 bg-muted-800'
        : 'border-muted-200 bg-white'
    "
  >
    <!-- Header -->
    <div
      class="languagePanel flex h-16 w-full items-center justify-between px-10"
    >
      <h2
        class="font-heading text-lg font-semibold"
        :class="colorMode.value === 'dark' ? 'text-white' : 'text-muted-700'"
      >
        {{ $t('Select language') }}
      </h2>
      <button
        type="button"
        class="text-muted-400 flex h-10 w-10 items-center justify-center transition-colors duration-300"
        :class="
          colorMode.value === 'dark'
            ? 'hover:bg-muted-700 hover:text-white'
            : 'hover:bg-muted-100 hover:text-muted-600'
        "
        @click="close"
      >
        <Icon name="feather:chevron-right" class="h-6 w-6" />
      </button>
    </div>

    <!-- Body -->
    <div class="relative h-[calc(100%_-_64px)] w-full px-10">
      <!-- Loading -->
      <div
        v-if="loading"
        class="flex items-center justify-center py-12 text-muted-400"
      >
        <Icon name="ph:spinner" class="h-6 w-6 animate-spin" />
      </div>

      <form v-else>
        <div class="grid grid-cols-2 py-6 activeLanguages">
          <div
            v-for="language in activeLanguages"
            :key="language.code"
            class="relative my-4 flex flex-col items-center justify-center gap-2"
          >
            <div class="relative">
              <input
                type="radio"
                name="locale-select"
                class="langIcon peer absolute start-0 top-0 z-20 h-full w-full cursor-pointer opacity-0"
                :value="language.code"
                v-model="locale"
              />
              <!-- Circle -->
              <div
                class="peer-checked:border-primary-500 flex h-14 w-14 items-center justify-center rounded-full border-2 shadow-lg transition-all duration-300"
                :class="
                  colorMode.value === 'dark'
                    ? 'border-muted-600'
                    : 'border-muted-200'
                "
              >
                <!-- SVG flag -->
                <img
                  v-if="language.icon"
                  class="h-10 w-10 rounded-full object-cover"
                  :src="language.icon"
                  :alt="language.label"
                />
                <!-- Emoji flag fallback -->
                <span v-else class="text-2xl leading-none select-none">{{
                  language.flag ?? language.code
                }}</span>
              </div>
              <!-- Check badge -->
              <div
                class="bg-primary-500 absolute -end-1 -top-1 hidden h-7 w-7 items-center justify-center rounded-full border-4 text-white peer-checked:flex"
                :class="
                  colorMode.value === 'dark'
                    ? 'border-muted-800'
                    : 'border-white'
                "
              >
                <Icon name="feather:check" class="h-3 w-3" />
              </div>
            </div>
            <!-- Label -->
            <span
              class="text-xs font-medium"
              :class="
                locale === language.code
                  ? 'text-primary-500'
                  : colorMode.value === 'dark'
                  ? 'text-muted-400'
                  : 'text-muted-500'
              "
              >{{ language.label }}</span
            >
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
