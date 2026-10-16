<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
const runtimeConfig = useRuntimeConfig()
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const template_types = ref([])

const props = defineProps({
  open: Boolean,
  title: String,
  code: String,
  types: String,
  row: Number,
  size: String,
  close: Function,
  setRow: Function,
  refresh: Function,
  template_types: Object,
})
const current_row = ref(-1)
const types = ref([])
const defaultType = ref(null)

const submitHandler = (values) => {
  let chosenType = types.value.find((item) => item.id === values.template_type)

  props.setRow(values.template_type, chosenType)
  if (props.close) {
    props.close()
  }
}

const transformType = (items) => {
  // console.log(items)
  const transformed_types = items.map((item) => ({
    label: item.name,
    value: item.id,
    custom_code: item.code.$cmp,
  }))
  return transformed_types
}

const loadTypes = async () => {
  try {
    const filters = {
      enabled: true,
      code: {
        _nnull: true,
      },
    }
    const items = await getItems<any>({
      collection: 'Template_type',
      params: {
        filter: filters,
        limit: -1,
        page: 1,
        meta: 'filter_count',
        fields: ['*'],
      },
    })
    types.value = items.data
    template_types.value = transformType(items.data)
    if (template_types.value.length > 0) {
      defaultType.value = template_types.value[0].value
    }
  } catch (e) {
    console.log(e)
  }
}

onMounted(async () => {
  await loadTypes()
})
</script>

<template>
  <!-- New & Edit modal -->
  <TairoModal :open="props.open" :size="props.size" @close="close">
    <template #header>
      <!-- Header -->
      <div class="flex w-full items-center justify-between p-2 md:p-2">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white pl-8"
        >
          {{ t(title) }}
        </h3>
        <BaseButtonClose @click="close" />
      </div>
    </template>

    <!-- Body -->
    <div class="mx-auto w-full px-8 py-4 templatetype">
      <p class="text-xs text-gray-400 mb-4 uppercase tracking-wide font-medium">
        {{ t('Select a task type') }}
      </p>
      <FormKit
        type="form"
        :actions="true"
        :submit-label="t('Select')"
        @submit="submitHandler"
        :submit-attrs="{
          inputClass:
            'submit text-sm px-8 py-2 mt-4 mb-6 is-button rounded-lg bg-primary-500 dark:bg-primary-500 hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 text-white hover:enabled:shadow-lg hover:enabled:shadow-primary-500/50 dark:hover:enabled:shadow-primary-800/20 focus-visible:outline-primary-400/70 focus-within:outline-primary-400/70 focus-visible:bg-primary-500 active:enabled:bg-primary-500 dark:focus-visible:outline-primary-400 dark:focus-within:outline-primary-400 dark:focus-visible:bg-primary-500 dark:active:enabled:bg-primary-500',
          ignore: false,
        }"
      >
        <div class="grid grid-cols-1 gap-3">
          <FormKit
            name="template_type"
            type="radio"
            :options="template_types"
            :value="defaultType"
            option-class="radios"
            :validation="'required'"
          >
            <template #label="context">
              <div class="type-option-label">
                <div
                  v-if="context.option.label === 'cmms-editbox'"
                  class="type-card"
                >
                  <Icon
                    name="ph:text-aa-duotone"
                    class="type-icon text-primary-500"
                  />
                  <div>
                    <p class="type-name">{{ t('Edit Box') }}</p>
                    <p class="type-desc">{{ t('Free text input field') }}</p>
                  </div>
                </div>
                <div
                  v-else-if="context.option.label === 'cmms-checkbox'"
                  class="type-card"
                >
                  <Icon
                    name="ph:check-square-duotone"
                    class="type-icon text-success-500"
                  />
                  <div>
                    <p class="type-name">{{ t('Checkbox') }}</p>
                    <p class="type-desc">{{ t('Checkable task item') }}</p>
                  </div>
                </div>
                <div v-else class="type-card">
                  <Icon
                    name="ph:squares-four-duotone"
                    class="type-icon text-muted-400"
                  />
                  <div>
                    <p class="type-name">{{ context.option.label }}</p>
                  </div>
                </div>
              </div>
            </template>
          </FormKit>
        </div>
      </FormKit>
    </div>
  </TairoModal>
</template>

<style>
.templatetype {
  max-width: 480px;
  margin: auto;
}

/* Radio option card */
.radios {
  margin-bottom: 10px;
}
.templatetype .radios span {
  align-items: center;
  display: flex;
}

.type-option-label {
  width: 100%;
}

.type-card {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 14px;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
  background: #f9fafb;
  cursor: pointer;
  transition: border-color 0.15s, background 0.15s;
}

.dark .type-card {
  border-color: #334155;
  background: #1e293b;
}

.type-card:hover {
  border-color: #6366f1;
  background: #eef2ff;
}

.dark .type-card:hover {
  border-color: #6366f1;
  background: #1e1b4b;
}

.type-icon {
  font-size: 28px;
  flex-shrink: 0;
}

.type-name {
  font-size: 13px;
  font-weight: 600;
  color: #1f2937;
  line-height: 1.3;
}

.dark .type-name {
  color: #f1f5f9;
}

.type-desc {
  font-size: 11px;
  color: #6b7280;
  margin-top: 1px;
}

/* Submit button row */
.templatetype .mb-1.max-w-md:has(.submit) {
  justify-content: flex-end;
  display: flex;
  width: 100%;
  margin-top: 8px;
}
</style>
