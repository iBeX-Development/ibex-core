<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
const { getItems, createItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const toaster = useToaster()

const props = defineProps<{
  open: boolean
  budgetId?: number | null // null = create, number = edit
  close: () => void
  refresh: () => void
}>()

const loading = ref(false)
const parentOptions = ref<{ label: string; value: string }[]>([])
const locationObj = ref<{ id: number | string; name: string } | null>(null)

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

const isEdit = computed(() => !!props.budgetId && props.budgetId > 0)

// Load parent budgets & locations for selects
const loadOptions = async () => {
  try {
    const [bResp] = await Promise.all([
      getItems<any>({
        collection: 'Budget',
        params: {
          filter: props.budgetId ? { id: { _neq: props.budgetId } } : {},
          limit: -1,
          fields: ['id', 'budget_code', 'budget_name'],
          sort: ['budget_code'],
        },
      }),
    ])

    const budgets = Array.isArray(bResp) ? bResp : (bResp as any)?.data || []

    parentOptions.value = [
      { label: '— ' + t('None') + ' —', value: '' },
      ...budgets.map((b: any) => ({
        label: `${b.budget_code} — ${b.budget_name}`,
        value: String(b.id),
      })),
    ]
  } catch (e) {
    console.error('loadOptions error', e)
  }
}

// Load existing record when editing
const loadRecord = async () => {
  if (!props.budgetId) return
  try {
    const resp = await getItems<any>({
      collection: 'Budget',
      params: {
        filter: { id: { _eq: props.budgetId } },
        limit: 1,
        fields: ['*'],
      },
    })
    const row = (Array.isArray(resp) ? resp : (resp as any)?.data || [])[0]
    if (!row) return
    // Fetch full location object so autocomplete2 can display it
    if (row.location) {
      const locId =
        typeof row.location === 'object' ? row.location.id : row.location
      try {
        const locResp = await getItems<any>({
          collection: 'Location',
          params: {
            filter: { id: { _eq: locId } },
            fields: ['id', 'name'],
            limit: 1,
          },
        })
        const locArr = Array.isArray(locResp)
          ? locResp
          : (locResp as any)?.data || []
        locationObj.value = locArr[0] || null
      } catch {
        locationObj.value = null
      }
    } else {
      locationObj.value = null
    }
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
  } catch (e) {
    console.error('loadRecord error', e)
  }
}

const resetForm = () => {
  locationObj.value = null
  form.value = {
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
  }
}

watch(
  () => [props.open, props.budgetId] as const,
  async ([isOpen]) => {
    if (isOpen) {
      await loadOptions()
      if (isEdit.value) {
        await loadRecord()
      } else {
        resetForm()
      }
    }
  },
)

const submitHandler = async () => {
  loading.value = true
  try {
    const payload: any = {
      budget_code: form.value.budget_code,
      budget_name: form.value.budget_name,
      description: form.value.description || null,
      notes: form.value.notes || null,
      total_amount: form.value.total_amount
        ? parseFloat(form.value.total_amount)
        : 0,
      start_date: form.value.start_date || null,
      end_date: form.value.end_date || null,
      status: form.value.status,
      parent: form.value.parent ? Number(form.value.parent) : null,
      location: locationObj.value
        ? Number(locationObj.value.id)
        : form.value.location
        ? Number(form.value.location)
        : null,
      account_number: form.value.account_number || null,
      company_id: myCompanyId,
    }

    if (isEdit.value) {
      await updateItem({
        collection: 'Budget',
        id: props.budgetId!,
        item: payload,
      })
      toaster.show({
        title: t('Updated'),
        message: t('Budget updated successfully') + '!',
        color: 'success',
        icon: 'ph:check-circle-fill',
        closable: true,
      })
    } else {
      await createItems({ collection: 'Budget', items: [payload] })
      toaster.show({
        title: t('Created'),
        message: t('Budget created successfully') + '!',
        color: 'success',
        icon: 'ph:check-circle-fill',
        closable: true,
      })
    }

    props.refresh()
    props.close()
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
</script>

<template>
  <TairoModal :open="open" size="xl" @close="close">
    <template #header>
      <div class="flex w-full items-center justify-between">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white pl-8"
        >
          {{ isEdit ? t('Edit Budget') : t('New Budget') }}
        </h3>
        <BaseButtonClose @click="close" />
      </div>
    </template>

    <div
      class="mx-auto w-full min-h-0 flex-1 overflow-y-auto px-8 pb-4 slimscroll"
    >
      <div class="grid grid-cols-1 gap-4 md:grid-cols-2 mt-4">
        <!-- Budget Code -->
        <div>
          <label class="nui-label pb-1 text-[0.825rem]"
            >{{ t('Budget Code') }} *</label
          >
          <input
            v-model="form.budget_code"
            type="text"
            required
            class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
            :placeholder="t('e.g. BDG-2026-001')"
          />
        </div>

        <!-- Budget Name -->
        <div>
          <label class="nui-label pb-1 text-[0.825rem]"
            >{{ t('Budget Name') }} *</label
          >
          <input
            v-model="form.budget_name"
            type="text"
            required
            class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
            :placeholder="t('Budget name')"
          />
        </div>

        <!-- Total Amount -->
        <div>
          <label class="nui-label pb-1 text-[0.825rem]"
            >{{ t('Total Amount') }} (₮)</label
          >
          <input
            v-model="form.total_amount"
            type="number"
            min="0"
            step="1"
            class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
            placeholder="0"
          />
        </div>

        <!-- Account Number -->
        <div>
          <label class="nui-label pb-1 text-[0.825rem]">{{
            t('Account Number')
          }}</label>
          <input
            v-model="form.account_number"
            type="text"
            class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
            :placeholder="t('Account code')"
          />
        </div>

        <!-- Start Date -->
        <div>
          <label class="nui-label pb-1 text-[0.825rem]">{{
            t('Start Date')
          }}</label>
          <input
            v-model="form.start_date"
            type="date"
            class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
          />
        </div>

        <!-- End Date -->
        <div>
          <label class="nui-label pb-1 text-[0.825rem]">{{
            t('End Date')
          }}</label>
          <input
            v-model="form.end_date"
            type="date"
            class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full"
          />
        </div>

        <!-- Parent Budget -->
        <div>
          <label class="nui-label pb-1 text-[0.825rem]">{{
            t('Parent Budget')
          }}</label>
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

        <!-- Location -->
        <div>
          <FormKit
            name="location"
            type="autocomplete2"
            :label="t('Location')"
            collection_name="Location"
            item_value="id"
            item_title="name"
            :initial_filter="{ status: 1, company_id: myCompanyId }"
            search_field="name"
            :value="locationObj"
            @input="
              (v) => {
                locationObj = v
                form.location = v
                  ? String(typeof v === 'object' ? v.id : v)
                  : ''
              }
            "
          />
        </div>

        <!-- Status -->
        <div>
          <label class="nui-label pb-1 text-[0.825rem]">{{
            t('Status')
          }}</label>
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

        <!-- Description -->
        <div class="md:col-span-2">
          <label class="nui-label pb-1 text-[0.825rem]">{{
            t('Description')
          }}</label>
          <textarea
            v-model="form.description"
            rows="2"
            class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full resize-none"
            :placeholder="t('Short description')"
          />
        </div>

        <!-- Notes -->
        <div class="md:col-span-2">
          <label class="nui-label pb-1 text-[0.825rem]">{{ t('Notes') }}</label>
          <textarea
            v-model="form.notes"
            rows="2"
            class="nui-input nui-input-md nui-input-rounded-sm nui-input-white w-full resize-none"
            :placeholder="t('Additional notes')"
          />
        </div>
      </div>
    </div>

    <template #footer>
      <div
        class="shrink-0 border-t border-muted-200 flex justify-end gap-3 dark:border-muted-700"
      >
        <BaseButton shape="rounded" @click="close">
          {{ t('Cancel') }}
        </BaseButton>
        <BaseButton
          color="primary"
          shape="rounded"
          :loading="loading"
          :disabled="!form.budget_code || !form.budget_name"
          @click="submitHandler"
        >
          <Icon name="ph:floppy-disk" class="size-4 mr-1" />
          {{ t('Save') }}
        </BaseButton>
      </div>
    </template>
  </TairoModal>
</template>

<style scoped>
input,
select,
textarea {
  border: 1px solid #d1d5db !important;
  border-radius: 6px !important;
  padding: 10px;
}
input:focus,
select:focus,
textarea:focus {
  border-color: #6366f1 !important;
  outline: none !important;
  box-shadow: 0 0 0 2px rgba(99, 102, 241, 0.15) !important;
}
</style>
