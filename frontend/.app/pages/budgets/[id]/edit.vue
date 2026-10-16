<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'

const { t } = useI18n({ useScope: 'global' })
const { getItems, updateItem } = useDirectusItems()
const toaster = useToaster()
const router = useRouter()
const route = useRoute()

definePageMeta({
  middleware: ['auth'],
  title: 'Edit Budget',
  showback: true,
})

const budgetId = computed(() => Number(route.params.id))
const loading = ref(false)
const parentOptions = ref<{ label: string; value: string }[]>([])
const locationOptions = ref<{ label: string; value: string }[]>([])

const form = ref({
  budget_code: '',
  budget_name: '',
  description: '',
  notes: '',
  total_amount: '',
  start_date: '',
  end_date: '',
  status: 'Active',
  parent: '',
  location: '',
  account_number: '',
})

const statusOptions = [
  { label: t('Active'), value: 'Active' },
  { label: t('Approved'), value: 'Approved' },
  { label: t('Closed'), value: 'Closed' },
  { label: t('Inactive'), value: 'Inactive' },
]

const loadOptions = async () => {
  const [bResp, lResp] = await Promise.all([
    getItems<any>({
      collection: 'Budget',
      params: {
        filter: { id: { _neq: budgetId.value } },
        limit: -1,
        fields: ['id', 'budget_code', 'budget_name'],
        sort: ['budget_code'],
      },
    }),
    getItems<any>({
      collection: 'Location',
      params: { limit: -1, fields: ['id', 'name'], sort: ['name'] },
    }),
  ])
  const budgets = Array.isArray(bResp) ? bResp : (bResp as any)?.data || []
  const locs = Array.isArray(lResp) ? lResp : (lResp as any)?.data || []
  parentOptions.value = [
    { label: '— ' + t('None') + ' —', value: '' },
    ...budgets.map((b: any) => ({
      label: `${b.budget_code} — ${b.budget_name}`,
      value: String(b.id),
    })),
  ]
  locationOptions.value = [
    { label: '— ' + t('None') + ' —', value: '' },
    ...locs.map((l: any) => ({ label: l.name, value: String(l.id) })),
  ]
}

const loadRecord = async () => {
  const resp = await getItems<any>({
    collection: 'Budget',
    params: {
      filter: { id: { _eq: budgetId.value } },
      limit: 1,
      fields: ['*'],
    },
  })
  const row = (Array.isArray(resp) ? resp : (resp as any)?.data || [])[0]
  if (!row) return
  form.value = {
    budget_code: row.budget_code ?? '',
    budget_name: row.budget_name ?? '',
    description: row.description ?? '',
    notes: row.notes ?? '',
    total_amount: row.total_amount != null ? String(row.total_amount) : '',
    start_date: row.start_date ? String(row.start_date).slice(0, 10) : '',
    end_date: row.end_date ? String(row.end_date).slice(0, 10) : '',
    status: row.status != null ? String(row.status) : 'Active',
    parent: row.parent
      ? String(typeof row.parent === 'object' ? row.parent.id : row.parent)
      : '',
    location: row.location
      ? String(
          typeof row.location === 'object' ? row.location.id : row.location,
        )
      : '',
    account_number: row.account_number ?? '',
  }
}

const submitHandler = async () => {
  if (!form.value.budget_code || !form.value.budget_name) return
  loading.value = true
  try {
    const payload: any = {
      budget_code: form.value.budget_code,
      budget_name: form.value.budget_name,
      description: form.value.description || null,
      notes: form.value.notes || null,
      total_amount: form.value.total_amount
        ? parseFloat(form.value.total_amount) || null
        : null,
      start_date: form.value.start_date || null,
      end_date: form.value.end_date || null,
      status: form.value.status,
      parent: form.value.parent ? parseInt(form.value.parent, 10) : null,
      location: form.value.location ? parseInt(form.value.location, 10) : null,
      account_number: form.value.account_number || null,
    }
    await updateItem({
      collection: 'Budget',
      id: budgetId.value,
      item: payload,
    })
    toaster.show({
      title: t('Updated'),
      message: t('Budget updated successfully') + '!',
      color: 'success',
      icon: 'ph:check-circle-fill',
      closable: true,
      duration: 2000,
    })
    router.push('/budgets')
  } catch (e: any) {
    console.error('submit error', e)
    toaster.show({
      title: t('Error'),
      message: e?.message || t('Something went wrong'),
      color: 'danger',
      icon: 'ph:warning-fill',
      closable: true,
    })
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await Promise.all([loadOptions(), loadRecord()])
})
</script>

<template>
  <div class="relative">
    <div class="grid grid-cols-12 gap-6">
      <div class="col-span-8">
        <BaseCard
          color="default"
          rounded="md"
          class="p-10 shadow-lg"
          style="background-color: white; border-radius: 8px"
        >
          <div class="grid grid-cols-2 gap-4 mb-5">
            <!-- Left column -->
            <div class="flex flex-col gap-3">
              <div>
                <label class="nui-label pb-1 text-[0.825rem]"
                  >{{ t('Budget Code') }}:</label
                >
                <input
                  v-model="form.budget_code"
                  type="text"
                  required
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                />
              </div>
              <div>
                <label class="nui-label pb-1 text-[0.825rem]"
                  >{{ t('Budget Name') }}:</label
                >
                <input
                  v-model="form.budget_name"
                  type="text"
                  required
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                />
              </div>
              <div>
                <label class="nui-label pb-1 text-[0.825rem]"
                  >{{ t('Status') }}:</label
                >
                <select
                  v-model="form.status"
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                >
                  <option
                    v-for="opt in statusOptions"
                    :key="opt.value"
                    :value="opt.value"
                  >
                    {{ opt.label }}
                  </option>
                </select>
              </div>
              <div>
                <!-- Location -->
                <div>
                  <FormKit
                    name="location"
                    type="autocomplete2"
                    :label="`${t('Location')}`"
                    collection_name="Location"
                    item_value="id"
                    item_title="name"
                    :initial_filter="{ status: 1 }"
                    search_field="name"
                    :value="form.location"
                    @input="form.location = $event"
                  />
                </div>
              </div>
            </div>

            <!-- Right column -->
            <div class="flex flex-col gap-3">
              <div>
                <label class="nui-label pb-1 text-[0.825rem]"
                  >{{ t('Total Amount') }} (₮):</label
                >
                <input
                  v-model="form.total_amount"
                  type="number"
                  min="0"
                  step="1"
                  placeholder="0"
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                />
              </div>
              <div>
                <label class="nui-label pb-1 text-[0.825rem]"
                  >{{ t('Account Number') }}:</label
                >
                <input
                  v-model="form.account_number"
                  type="text"
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                />
              </div>
              <div>
                <label class="nui-label pb-1 text-[0.825rem]"
                  >{{ t('Start Date') }}:</label
                >
                <input
                  v-model="form.start_date"
                  type="date"
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                />
              </div>
              <div>
                <label class="nui-label pb-1 text-[0.825rem]"
                  >{{ t('End Date') }}:</label
                >
                <input
                  v-model="form.end_date"
                  type="date"
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                />
              </div>
            </div>
          </div>

          <!-- Description -->
          <div class="mb-3">
            <label class="nui-label pb-1 text-[0.825rem]"
              >{{ t('Description') }}:</label
            >
            <textarea
              v-model="form.description"
              rows="3"
              class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full resize-none"
            />
          </div>

          <!-- Notes -->
          <div class="mb-3">
            <label class="nui-label pb-1 text-[0.825rem]"
              >{{ t('Safety Notes') }}:</label
            >
            <textarea
              v-model="form.notes"
              rows="3"
              class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full resize-none"
            />
          </div>

          <!-- Parent Budget -->
          <div class="mb-5">
            <label class="nui-label pb-1 text-[0.825rem]"
              >{{ t('Parent Budget') }}:</label
            >
            <select
              v-model="form.parent"
              class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
            >
              <option
                v-for="opt in parentOptions"
                :key="opt.value"
                :value="opt.value"
              >
                {{ opt.label }}
              </option>
            </select>
          </div>

          <!-- Save button -->
          <button
            type="button"
            :disabled="loading || !form.budget_code || !form.budget_name"
            class="text-sm px-10 mt-2 py-3 rounded bg-primary-500 dark:bg-primary-500 text-white hover:enabled:bg-primary-400 dark:hover:enabled:bg-primary-400 disabled:opacity-50 disabled:cursor-not-allowed"
            @click="submitHandler"
          >
            <span v-if="loading">{{ t('Saving') }}...</span>
            <span v-else>{{ t('Save') }}</span>
          </button>
        </BaseCard>
      </div>
    </div>
  </div>
</template>

<style scoped>
input,
select,
textarea {
  border: 1px solid #d1d5db !important;
  border-radius: 8px !important;
}
input:focus,
select:focus,
textarea:focus {
  border-color: #6366f1 !important;
  outline: none;
}
</style>
