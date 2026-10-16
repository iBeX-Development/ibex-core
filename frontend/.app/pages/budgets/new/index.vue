<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'

const { t } = useI18n({ useScope: 'global' })
const { getItems, createItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()
const router = useRouter()

definePageMeta({
  middleware: ['auth'],
  title: 'New Budget',
  showback: true,
})

const loading = ref(false)
const parentOptions = ref<{ label: string; value: string }[]>([])
const locationOptions = ref<{ label: string; value: string }[]>([])
const locationObj = ref<{ id: number | string; name: string } | null>(null)

const form = ref({
  budget_code: '',
  budget_name: '',
  description: '',
  notes: '',
  total_amount: '',
  start_date: new Date().toISOString().substr(0, 10),
  end_date: new Date().toISOString().substr(0, 10),
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
  try {
    const [bResp, lResp] = await Promise.all([
      getItems<any>({
        collection: 'Budget',
        params: {
          filter: { company_id: { _eq: myCompanyId } },
          limit: -1,
          fields: ['id', 'budget_code', 'budget_name'],
          sort: ['budget_code'],
        },
      }),
      getItems<any>({
        collection: 'Location',
        params: {
          filter: { company_id: { _eq: myCompanyId } },
          limit: -1,
          fields: ['id', 'name'],
          sort: ['name'],
        },
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
  } catch (e) {
    console.error('loadOptions error', e)
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
      location: locationObj.value ? Number(locationObj.value.id) : null,
      account_number: form.value.account_number || null,
      company_id: myCompanyId,
    }

    console.log('Submitting budget', payload)
    await createItems({ collection: 'Budget', items: [payload] })
    toaster.show({
      title: t('Created'),
      message: t('Budget created successfully') + '!',
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

onMounted(loadOptions)
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
            <!-- Left column: main fields -->
            <div class="flex flex-col gap-3">
              <!-- Budget Code -->
              <div>
                <label class="nui-label pb-1 text-[0.825rem]">
                  {{ t('Budget Code') }}:
                </label>
                <input
                  v-model="form.budget_code"
                  type="text"
                  required
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                />
              </div>

              <!-- Budget Name -->
              <div>
                <label class="nui-label pb-1 text-[0.825rem]">
                  {{ t('Budget Name') }}:
                </label>
                <input
                  v-model="form.budget_name"
                  type="text"
                  required
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                />
              </div>

              <!-- Status -->
              <div>
                <label class="nui-label pb-1 text-[0.825rem]">
                  {{ t('Status') }}:
                </label>
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
                  :value="locationObj"
                  @input="
                    (v) => {
                      locationObj = v
                    }
                  "
                />
              </div>
            </div>

            <!-- Right column: secondary fields -->
            <div class="flex flex-col gap-3">
              <!-- Total Amount -->
              <div>
                <label class="nui-label pb-1 text-[0.825rem]">
                  {{ t('Total Amount') }} (₮):
                </label>
                <input
                  v-model="form.total_amount"
                  type="number"
                  min="0"
                  step="1"
                  placeholder="0"
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                />
              </div>

              <!-- Account Number -->
              <div>
                <label class="nui-label pb-1 text-[0.825rem]">
                  {{ t('Account Number') }}:
                </label>
                <input
                  v-model="form.account_number"
                  type="text"
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                />
              </div>

              <!-- Start Date -->
              <div>
                <label class="nui-label pb-1 text-[0.825rem]">
                  {{ t('Start Date') }}:
                </label>
                <input
                  v-model="form.start_date"
                  type="date"
                  class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
                />
              </div>

              <!-- End Date -->
              <div>
                <label class="nui-label pb-1 text-[0.825rem]">
                  {{ t('End Date') }}:
                </label>
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
            <label class="nui-label pb-1 text-[0.825rem]">
              {{ t('Description') }}:
            </label>
            <textarea
              v-model="form.description"
              rows="3"
              class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full resize-none"
            />
          </div>

          <!-- Notes -->
          <!-- <div class="mb-3">
            <label class="nui-label pb-1 text-[0.825rem]">
              {{ t('Safety Notes') }}:
            </label>
            <textarea
              v-model="form.notes"
              rows="3"
              class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full resize-none"
            />
          </div> -->

          <!-- Parent Budget -->
          <div class="mb-5">
            <label class="nui-label pb-1 text-[0.825rem]">
              {{ t('Parent Budget') }}:
            </label>
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
  padding: 10px;
}
input:focus,
select:focus,
textarea:focus {
  border-color: #6366f1 !important;
  outline: none;
}
</style>
