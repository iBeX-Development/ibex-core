<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'

interface PricingPlan {
  id: number
  code?: string
  name: string
  description?: string
  price: number
  period: string
  features: string[]
  permissions: Object
  button_label?: string
  is_recommended: number
  sort?: number
  status: number
}

interface PricingPlanFormValues {
  name: string
  price: number | string
  period: string
  description: string
  features: string
  permissions: Object
  button_label: string
  is_recommended: boolean
}

const { t } = useI18n({ useScope: 'global' })
const runtimeConfig = useRuntimeConfig()
const { token } = useDirectusToken()
const toaster = useToaster()

const plans = ref<PricingPlan[]>([])
const isLoading = ref(false)
const isFormOpen = ref(false)
const selectedPlanId = ref<number | null>(null)
const planToDelete = ref<PricingPlan | null>(null)
const isDeleteModalOpen = ref(false)
const isMutating = ref(false)
const { open } = usePanels()
const { getItems, updateItem, createItems } = useDirectusItems()

const emptyFormValues: PricingPlanFormValues = {
  name: '',
  price: 0,
  period: 'month',
  description: '',
  features: '',
  button_label: '',
  permissions: {},
  is_recommended: false,
}

const formValues = ref<PricingPlanFormValues>({ ...emptyFormValues })

const isEditing = computed(() => selectedPlanId.value !== null)

const normalizePlan = (raw: any): PricingPlan => ({
  id: raw.id,
  code: raw.code,
  name: raw.name,
  description: raw.description,
  price: Number(raw.price) || 0,
  period: raw.period || 'month',
  features: Array.isArray(raw.features) ? raw.features : [],
  button_label: raw.button_label,
  is_recommended: Number(raw.is_recommended) || 0,
  sort: raw.sort,
  status: Number(raw.status) ?? 1,
  permissions: raw.permissions || {},
})

const loadPlans = async () => {
  isLoading.value = true

  try {
    const result = await getItems({
      collection: 'Pricing_packages',
      params: {
        filter: { status: { _eq: 1 } },
        sort: ['sort', 'id'],
        fields: ['*'],
        limit: 100,
      },
    })
    const data = Array.isArray(result) ? result : (result as any)?.data ?? []

    plans.value = data.map(normalizePlan)
  } catch (error) {
    console.error('Unable to load packages:', error)
    plans.value = []
    toaster.show({
      title: t('Unable to load packages'),
      message: t('Please try again'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
  } finally {
    isLoading.value = false
  }
}

const openAddModal = () => {
  selectedPlanId.value = null
  formValues.value = { ...emptyFormValues }
  isFormOpen.value = true
}

const openEditModal = (plan: PricingPlan) => {
  selectedPlanId.value = plan.id
  formValues.value = {
    name: plan.name,
    price: plan.price,
    period: plan.period,
    description: plan.description || '',
    features: plan.features.join('\n'),
    button_label: plan.button_label || '',
    is_recommended: Boolean(plan.is_recommended),
  }
  isFormOpen.value = true
}

const closeFormModal = () => {
  isFormOpen.value = false
  selectedPlanId.value = null
  formValues.value = { ...emptyFormValues }
}

const savePlan = async () => {
  if (!formValues.value.name.trim()) {
    toaster.show({
      title: t('Error'),
      message: t('Package name is required'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  if (isMutating.value) return
  isMutating.value = true

  const features = formValues.value.features
    .split('\n')
    .map((feature) => feature.trim())
    .filter(Boolean)

  const payload = {
    name: formValues.value.name.trim(),
    price: Number(formValues.value.price) || 0,
    period: formValues.value.period.trim() || 'month',
    description: formValues.value.description.trim(),
    features,
    button_label: formValues.value.button_label.trim() || t('Upgrade'),
    is_recommended: formValues.value.is_recommended ? 1 : 0,
  }

  try {
    if (isEditing.value) {
      await updateItem({
        collection: 'Pricing_packages',
        id: selectedPlanId.value as number,
        item: payload,
      })
    } else {
      await createItems({
        collection: 'Pricing_packages',
        items: [payload],
      })
    }

    toaster.show({
      title: t('Saved'),
      message: isEditing.value ? t('Package updated') : t('Package added'),
      color: 'success',
      icon: 'ph:check-circle-fill',
      closable: true,
    })
    closeFormModal()
    await loadPlans()
  } catch (error) {
    toaster.show({
      title: t('Error'),
      message: error instanceof Error ? error.message : t('Please try again'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
  } finally {
    isMutating.value = false
  }
}

const openDeleteModal = (plan: PricingPlan) => {
  planToDelete.value = plan
  isDeleteModalOpen.value = true
}

const closeDeleteModal = () => {
  isDeleteModalOpen.value = false
  planToDelete.value = null
}

const deletePlan = async () => {
  if (!planToDelete.value || isMutating.value) return

  isMutating.value = true

  try {
    await updateItem({
      collection: 'Pricing_packages',
      id: planToDelete.value.id,
      item: { status: 0 },
    })

    toaster.show({
      title: t('Deleted'),
      message: t('Package removed'),
      color: 'success',
      icon: 'ph:check-circle-fill',
      closable: true,
    })
    closeDeleteModal()
    await loadPlans()
  } catch (error) {
    toaster.show({
      title: t('Error'),
      message: error instanceof Error ? error.message : t('Please try again'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
  } finally {
    isMutating.value = false
  }
}

const configPermissions = (plan: PricingPlan) => {
  console.log('Config permissions for plan:', plan)
  open('packagePermissionMore', { role: plan })
}

onMounted(() => {
  loadPlans()
})

definePageMeta({
  title: 'Pricing packages',
  showback: true,
  preview: {
    title: 'Pricing',
    description: 'For viewing pricing',
    categories: ['layouts', 'forms'],
    src: '/img/screens/layouts-form-1.png',
    srcDark: '/img/screens/layouts-form-1-dark.png',
    order: 47,
  },
})
</script>

<template>
  <div class="mx-auto w-full max-w-7xl">
    <div class="mb-6 flex items-center justify-between">
      <BaseButton @click="openAddModal">
        <Icon name="lucide:plus" class="-ms-1 h-4 w-4" />
        <span class="text-[11px]">{{ $t('Add package') }}</span>
      </BaseButton>
    </div>

    <BasePlaceholderPage
      v-if="isLoading"
      title="Loading packages"
      subtitle=""
      class="min-h-96"
    />

    <BasePlaceholderPage
      v-else-if="plans.length === 0"
      title="No packages found"
      subtitle=""
      class="min-h-96"
    />

    <div v-else class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
      <BaseCard
        v-for="plan in plans"
        :key="plan.id"
        :class="[
          'relative flex flex-col p-6',
          plan.is_recommended ? 'border-2 border-primary-500' : '',
        ]"
        @click="configPermissions(plan)"
      >
        <BaseTag
          v-if="plan.is_recommended"
          color="primary"
          size="sm"
          class="absolute right-4 top-4"
        >
          {{ $t('RECOMMENDED') }}
        </BaseTag>

        <BaseText size="sm" class="text-muted-500">
          {{ plan.name }}
        </BaseText>
        <BaseHeading as="h3" size="lg" weight="medium" class="mt-1">
          {{ plan.description }}
        </BaseHeading>

        <div class="mt-4 flex items-end gap-1">
          <span class="font-heading text-3xl font-bold">
            ${{ plan.price }}
          </span>
          <span class="text-muted-500 mb-1 text-sm">
            / {{ $t(plan.period) }}
          </span>
        </div>

        <BaseButton
          :color="plan.is_recommended ? 'primary' : 'default'"
          class="mt-4 w-full"
        >
          {{ $t(plan.button_label || 'Upgrade') }}
        </BaseButton>

        <ul class="mt-5 flex-1 space-y-2.5">
          <li
            v-for="(feature, index) in plan.features"
            :key="index"
            class="flex items-center gap-2 text-sm"
          >
            <Icon
              name="lucide:check"
              class="h-4 w-4 shrink-0 text-primary-500"
            />
            <span class="text-muted-600 dark:text-muted-300">
              {{ feature }}
            </span>
          </li>
        </ul>

        <div
          class="mt-5 flex items-center justify-end gap-2 border-t border-muted-200 pt-3 dark:border-muted-700"
        >
          <BaseButtonIcon
            size="sm"
            data-tooltip="Edit"
            @click="openEditModal(plan)"
          >
            <Icon name="lucide:pencil" class="h-3.5 w-3.5" />
          </BaseButtonIcon>
          <BaseButtonIcon
            size="sm"
            data-tooltip="Delete"
            @click="openDeleteModal(plan)"
          >
            <Icon name="lucide:trash-2" class="h-3.5 w-3.5" />
          </BaseButtonIcon>
        </div>
      </BaseCard>
    </div>

    <TairoModal :open="isFormOpen" size="md" @close="closeFormModal">
      <template #header>
        <div class="flex w-full items-center justify-between">
          <h3 class="font-heading text-lg font-medium">
            {{ isEditing ? $t('Edit package') : $t('Add package') }}
          </h3>
          <BaseButtonClose @click="closeFormModal" />
        </div>
      </template>

      <div class="space-y-4 px-6 py-4">
        <BaseInput
          v-model="formValues.name"
          :label="$t('Package name')"
          class="w-full border rounded border-muted-200 dark:border-muted-700"
        />
        <BaseInput
          v-model="formValues.description"
          :label="$t('Description')"
          class="w-full border rounded border-muted-200 dark:border-muted-700"
        />
        <div class="grid grid-cols-2 gap-3">
          <BaseInput
            v-model="formValues.price"
            type="number"
            :label="$t('Price')"
            :placeholder="$t('20')"
            class="w-full border rounded border-muted-200 dark:border-muted-700"
          />
          <BaseInput
            v-model="formValues.period"
            :label="$t('Period')"
            :placeholder="$t('month')"
            class="w-full border rounded border-muted-200 dark:border-muted-700"
          />
        </div>
        <BaseInput
          v-model="formValues.button_label"
          :label="$t('Button label')"
          :placeholder="$t('Upgrade to Plus')"
          class="w-full border rounded border-muted-200 dark:border-muted-700"
        />
        <BaseTextarea
          v-model="formValues.features"
          :label="$t('Features (one per line)')"
          rows="5"
          :placeholder="$t('Advanced modules') + '\n' + $t('Priority support')"
          class="w-full border rounded border-muted-200 dark:border-muted-700"
        />
        <div class="flex items-center gap-2">
          <BaseSwitchBall v-model="formValues.is_recommended" />
          <span class="text-sm">{{ $t('Mark as recommended') }}</span>
        </div>
      </div>

      <template #footer>
        <div class="flex justify-end gap-2">
          <BaseButton @click="closeFormModal">
            {{ $t('Cancel') }}
          </BaseButton>
          <BaseButton color="primary" @click="savePlan">
            {{ $t('Save') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>

    <TairoModal :open="isDeleteModalOpen" size="sm" @close="closeDeleteModal">
      <template #header>
        <div class="flex w-full items-center justify-between">
          <h3 class="font-heading text-lg font-medium">
            {{ $t('Delete package') }}
          </h3>
          <BaseButtonClose @click="closeDeleteModal" />
        </div>
      </template>

      <div class="px-6 py-4 text-sm text-muted-600 dark:text-muted-300">
        {{ $t('Delete') }} {{ planToDelete?.name }}?
      </div>

      <template #footer>
        <div class="flex justify-end gap-2">
          <BaseButton @click="closeDeleteModal">
            {{ $t('Cancel') }}
          </BaseButton>
          <BaseButton color="danger" @click="deletePlan">
            {{ $t('Delete') }}
          </BaseButton>
        </div>
      </template>
    </TairoModal>
  </div>
</template>
