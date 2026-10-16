<script setup lang="ts">
import { AvatarUpload } from '#components'
import { toTypedSchema } from '@vee-validate/zod'
import { Field, useForm } from 'vee-validate'
import { onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
const config = useRuntimeConfig()

import { z } from 'zod'
const { t } = useI18n({ useScope: 'global' })
const { getItems, updateItem } = useDirectusItems()
const { getUsers } = useDirectusUsers()
const runtimeConfig = useRuntimeConfig()
const { token } = useDirectusToken()
const { open } = usePanels()
const companyId = getMyCompanyId()

definePageMeta({
  title: 'Company',
  showback: true,
  preview: {
    title: 'Company',
    description: 'For forms and input fields',
    categories: ['layouts', 'forms'],
    src: '/img/screens/layouts-form-1.png',
    srcDark: '/img/screens/layouts-form-1-dark.png',
    order: 47,
  },
})

// This is the computed value that will be used to display the current avatar
const currentAvatar = computed(() => '/img/avatars/company.svg')
const currentPackage = ref<{ id: number; name: string } | null>(null)
const currentActiveUserCnt = ref(0)
const currentInactiveUserCnt = ref(0)

// Тухайн бүлгийн idэвхтэй/idэвхгүй хэрэглэгчийн бодит тоог directus_users-аас авах
const loadCurrentUserCounts = async (compId: number | string) => {
  if (!compId) return

  try {
    const [activeRes, inactiveRes] = await Promise.all([
      getUsers({
        params: {
          filter: { company_id: { _eq: compId }, active: { _eq: 1 } },
          meta: 'filter_count',
          limit: 1,
          fields: ['id'],
        },
      }),
      getUsers({
        params: {
          filter: { company_id: { _eq: compId }, active: { _neq: 1 } },
          meta: 'filter_count',
          limit: 1,
          fields: ['id'],
        },
      }),
    ])

    currentActiveUserCnt.value = activeRes?.meta?.filter_count ?? 0
    currentInactiveUserCnt.value = inactiveRes?.meta?.filter_count ?? 0
  } catch (error) {
    console.error('Unable to load current user counts:', error)
  }
}

const loadCurrentPackage = async (packageId: number | string) => {
  if (!packageId) {
    currentPackage.value = null
    return
  }

  try {
    const result = await getItems({
      collection: 'Pricing_packages',
      params: {
        filter: { id: packageId },
        fields: ['id', 'name'],
      },
    })
    const data = Array.isArray(result) ? result : (result as any)?.data ?? []

    currentPackage.value = data[0] || null
  } catch (error) {
    console.error('Unable to load pricing package:', error)
    currentPackage.value = null
  }
}
interface Company {
  id?: string | number
  name: string
  logo: Image
  email: string
  website: string
  type: string
  note: string
  active_asset_cnt?: string | number
  active_user_cnt?: number
  inactive_user_cnt?: number
  package: {}
}

interface Image {
  id?: number
  embed: string
}

let Uploads = []
let fileId = ref(-1)
let thumbnailUrl = ref('')

const VALIDATION_TEXT = {
  TITLE_REQUIRED: t('Name is required'),
}

const zodSchema = z.object({
  company: z.object({
    id: z.number().optional(),
    name: z
      .string({ required_error: VALIDATION_TEXT.TITLE_REQUIRED })
      .min(2, VALIDATION_TEXT.TITLE_REQUIRED),
    email: z.string(),
    website: z.string(),
    type: z.string(),
    note: z.string(),
    logo: z.string(),
    active_asset_cnt: z.number().optional(),
    active_user_cnt: z.number().optional(),
    inactive_user_cnt: z.number().optional(),

    // logo: z.object({
    //   id: z.number().optional(),
    //   embed: z.string().optional(),
    // }).optional()
  }),
})
type FormInput = z.infer<typeof zodSchema>
const validationSchema = toTypedSchema(zodSchema)
const initialValues = computed<FormInput>(() => ({
  company: {
    name: '',
    email: '',
    website: '',
    type: '',
    note: '',
    logo: '',
    active_asset_cnt: 0,
    active_user_cnt: 0,
    inactive_user_cnt: 0,
    package: {},
    // logo: {
    //   id: 0,
    //   embed: '',
    // },
  },
}))

const {
  handleSubmit,
  isSubmitting,
  setFieldError,
  meta,
  values,
  errors,
  resetForm,
  setFieldValue,
  setErrors,
  setValues,
} = useForm({
  validationSchema,
  initialValues,
})

const success = ref(false)
const fieldsWithErrors = computed(() => Object.keys(errors.value).length)
const toaster = useToaster()

const onSubmit = handleSubmit(
  async (values) => {
    // console.log('values', values)
    // console.log('Company Email:', values.company.email)

    success.value = false
    const companyId = values.company?.id
    if (!companyId) {
      toaster.show({
        title: t('Company not found'),
        message: t('Unable to update company information'),
        color: 'danger',
        icon: 'ph:warning-circle-fill',
        closable: true,
      })
      return
    }

    const items = {
      name: values.company.name,
      email: values.company?.email,
      website: values.company?.website,
      type: values.company?.type,
      note: values.company?.note,
      logo: Uploads.length ? Uploads[0].id : fileId.value ? fileId.value : null,
    }

    const response = await fetch(
      `${runtimeConfig.public.directus.url}items/Companies/${encodeURIComponent(
        String(companyId),
      )}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token.value}`,
        },
        body: JSON.stringify(items),
      },
    )
    const result = await response.json()

    if (!response.ok || !result.data) {
      console.error('Unable to update company information:', result)
      toaster.show({
        title: t('Update failed'),
        message: t('Unable to update company information'),
        color: 'danger',
        icon: 'ph:warning-circle-fill',
        closable: true,
      })
      return
    }

    const updatedCompany = result.data
    fileId.value = updatedCompany.logo || -1
    setValues({ company: updatedCompany })
    window.localStorage.setItem('comInfo', JSON.stringify([updatedCompany]))

    success.value = true
    toaster.clearAll()
    toaster.show({
      title: t('Success'),
      message: t('Record has been updated'),
      color: 'success',
      icon: 'ph:check',
      closable: true,
    })
  },
  (error) => {
    // this callback is optional and called only if the form has errors
    success.value = false

    // here you have access to the error
    console.log('event-create-error', error)

    // you can use it to scroll to the first error
    document.documentElement.scrollTo({
      top: 0,
      behavior: 'smooth',
    })
  },
)

// const Thumbnail = (id) => {
//   thumbnailUrl.value = `${config.public.directus.url}assets/${id}`
//   return thumbnailUrl.value
// }

// // 🔹 `computed()` ашиглаж, шууд тооцоолох
const Thumbnail = computed(() => {
  return fileId.value != null && fileId.value != -1
    ? `${config.public.directus.url}assets/${fileId.value}`
    : false
})

const onClick = (plan) => {
  if (!currentPackage.value) {
    toaster.show({
      title: t('No package assigned'),
      message: t('This company has no pricing package assigned'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  open('packagePermissionMore', { role: currentPackage.value, readonly: true })
}

onMounted(async () => {
  if (!companyId) {
    toaster.show({
      title: t('Company not found'),
      message: t('No company is assigned to this user'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  const response = await fetch(
    `${runtimeConfig.public.directus.url}items/Companies/${encodeURIComponent(
      companyId,
    )}?fields=*`,
    {
      headers: {
        Authorization: `Bearer ${token.value}`,
      },
    },
  )
  const result = await response.json()

  if (!response.ok || !result.data) {
    console.error('Unable to load company information:', result)
    toaster.show({
      title: t('Company not found'),
      message: t('Unable to load company information'),
      color: 'danger',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  const item = result.data as Company

  fileId.value = item.logo != '' && item.logo != null ? item.logo : null

  await loadCurrentPackage(item.package as unknown as number)
  await loadCurrentUserCounts(companyId)

  setValues({
    company: {
      ...item,
      email: item.email || '',
      website: item.website || '',
      type: item.type || '',
      note: item.note || '',
      logo: item.logo || '',
      active_asset_cnt: item.active_asset_cnt || 0,
      active_user_cnt: item.active_user_cnt || 0,
      inactive_user_cnt: item.inactive_user_cnt || 0,
    },
  })
})
</script>

<template>
  <div>
    <BaseCard>
      <form
        method="POST"
        action=""
        class="divide-muted-200 dark:divide-muted-700 grid divide-x sm:grid-cols-2"
        @submit.prevent="onSubmit"
      >
        <div
          shape="curved"
          class="bg-muted-50 dark:bg-muted-800/60 space-y-8 p-10"
        >
          <div class="mx-auto flex w-full max-w-[410px] flex-col">
            <div>
              <div>
                <div
                  class="relative mb-5 flex flex-col items-center justify-center gap-4"
                >
                  <AvatarUpload
                    code="Company"
                    field="logo"
                    height="200px"
                    width="180px"
                    :result="Uploads"
                    :id="fileId"
                    xmargin="-168px 0px 0px -20px"
                    :fileUrl="Thumbnail"
                  />
                  <!-- <BaseFullscreenDropfile
                    icon="ph:image-duotone"
                    :filter-file-dropped="
                      (file) => file.type.startsWith('image')
                    "
                    @drop="
                      (value) => {
                        inputFile = value
                      }
                    "
                  />
                  <BaseInputFileHeadless
                    accept="image/*"
                    v-model="inputFile"
                    v-slot="{ open, remove, preview, files }"
                  >
                    <div class="relative h-20 w-20">
                      <img
                        v-if="files?.length && files.item(0)"
                        :src="preview(files.item(0)!).value"
                        alt="Upload preview"
                        class="bg-muted-200 dark:bg-muted-700/60 h-20 w-20 rounded-full object-cover object-center"
                      />
                      <img
                        v-else
                        :src="currentAvatar"
                        alt="Upload preview"
                        class="bg-muted-200 dark:bg-muted-700/60 h-20 w-20 rounded-full object-cover object-center dark:invert"
                      />
                      <div
                        v-if="files?.length && files.item(0)"
                        class="absolute bottom-0 end-0 z-20"
                      >
                        <BaseButtonIcon
                          condensed
                          shape="full"
                          @click="remove(files.item(0)!)"
                          data-tooltip="Remove image"
                          class="scale-90"
                        >
                          <Icon name="lucide:x" class="h-4 w-4" />
                        </BaseButtonIcon>
                      </div>
                      <div v-else class="absolute bottom-0 end-0 z-20">
                        <div class="relative" data-tooltip="Upload image">
                          <BaseButtonIcon condensed shape="full" @click="open">
                            <Icon name="lucide:plus" class="h-4 w-4" />
                          </BaseButtonIcon>
                        </div>
                      </div>
                    </div>
                  </BaseInputFileHeadless>
                  <div
                    v-if="fileError"
                    class="text-danger-600 inline-block font-sans text-[.8rem]"
                  >
                    {{ fileError }}
                  </div> -->
                </div>
                <div class="grid grid-cols-12 gap-4">
                  <div class="ltablet:col-span-6 col-span-12 lg:col-span-6">
                    <Field
                      v-slot="{ field, errorMessage, handleChange, handleBlur }"
                      name="company.name"
                    >
                      <BaseInput
                        :label="$t('Company Name')"
                        placeholder="Ex: Acme Inc."
                        :model-value="field.value"
                        :error="errorMessage"
                        :disabled="isSubmitting"
                        type="text"
                        @update:model-value="handleChange"
                        @blur="handleBlur"
                      />
                    </Field>
                  </div>
                  <div class="ltablet:col-span-6 col-span-12 lg:col-span-6">
                    <Field
                      v-slot="{ field, errorMessage, handleChange, handleBlur }"
                      name="company.email"
                    >
                      <BaseInput
                        :label="$t('Company Email')"
                        placeholder="Ex: hello@acme.co"
                        :model-value="field.value"
                        :error="errorMessage"
                        :disabled="isSubmitting"
                        type="email"
                        @update:model-value="handleChange"
                        @blur="handleBlur"
                      />
                    </Field>
                  </div>
                  <div class="col-span-12">
                    <Field
                      v-slot="{ field, errorMessage, handleChange, handleBlur }"
                      name="company.website"
                    >
                      <BaseInput
                        icon="lucide:globe"
                        :label="$t('Company website')"
                        placeholder="Ex: https://acme.co"
                        :model-value="field.value"
                        :error="errorMessage"
                        :disabled="isSubmitting"
                        type="text"
                        @update:model-value="handleChange"
                        @blur="handleBlur"
                      />
                    </Field>
                  </div>
                  <div class="col-span-12">
                    <Field
                      v-slot="{ field, errorMessage, handleChange, handleBlur }"
                      name="company.package"
                    >
                      <BaseButton
                        @click="onClick(field)"
                        :color="'primary'"
                        class="mt-4 w-full"
                      >
                        {{ currentPackage?.name || $t('Pricing') }}
                      </BaseButton>
                    </Field>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div shape="curved" class="w-full space-y-8 p-10">
          <div class="mx-auto w-full max-w-[410px]">
            <div class="grid grid-cols-12 gap-4">
              <div class="col-span-12">
                <label class="nui-label pb-2 text-[0.825rem]">{{
                  $t('Company type')
                }}</label>
                <div
                  class="ptablet:grid-cols-2 ltablet:grid-cols-3 grid gap-4 lg:grid-cols-3"
                >
                  <Field
                    v-slot="{ field, errorMessage, handleChange, handleBlur }"
                    name="company.type"
                  >
                    <BaseRadioHeadless
                      value="team_member_1"
                      :model-value="field.value"
                      :error="errorMessage"
                      :disabled="isSubmitting"
                      @update:model-value="handleChange"
                      @blur="handleBlur"
                    >
                      <BaseCard
                        shape="rounded"
                        class="text-muted-400 peer-checked:!border-primary-500 peer-checked:[&_.child]:!text-primary-500 relative border-2 px-2 py-4 grayscale peer-checked:grayscale-0"
                      >
                        <div
                          class="flex w-full flex-col items-center gap-2 text-center"
                        >
                          <Icon
                            name="ph:house-simple-duotone"
                            class="child mx-auto h-5 w-5"
                          />

                          <div>
                            <BaseHeading
                              as="h4"
                              size="sm"
                              weight="medium"
                              lead="none"
                            >
                              {{ $t('Solo') }}
                            </BaseHeading>

                            <BaseText size="xs" class="text-muted-400">{{
                              $t('Small company')
                            }}</BaseText>
                          </div>

                          <div
                            class="child text-muted-300 absolute right-2 top-2 ms-auto"
                          >
                            <div class="h-2 w-2 rounded-full bg-current"></div>
                          </div>
                        </div>
                      </BaseCard>
                    </BaseRadioHeadless>
                  </Field>

                  <Field
                    v-slot="{ field, errorMessage, handleChange, handleBlur }"
                    name="company.type"
                  >
                    <BaseRadioHeadless
                      value="team_member_2"
                      :model-value="field.value"
                      :error="errorMessage"
                      :disabled="isSubmitting"
                      @update:model-value="handleChange"
                      @blur="handleBlur"
                    >
                      <BaseCard
                        shape="rounded"
                        class="text-muted-400 peer-checked:!border-primary-500 peer-checked:[&_.child]:!text-primary-500 relative border-2 px-2 py-4 grayscale peer-checked:grayscale-0"
                      >
                        <div
                          class="flex w-full flex-col items-center gap-2 text-center"
                        >
                          <Icon
                            name="ph:storefront-duotone"
                            class="child mx-auto h-5 w-5"
                          />

                          <div>
                            <BaseHeading
                              as="h4"
                              size="sm"
                              weight="medium"
                              lead="none"
                            >
                              {{ $t('LLC') }}
                            </BaseHeading>

                            <BaseText size="xs" class="text-muted-400">{{
                              $t('Medium company')
                            }}</BaseText>
                          </div>

                          <div
                            class="child text-muted-300 absolute right-2 top-2 ms-auto"
                          >
                            <div class="h-2 w-2 rounded-full bg-current"></div>
                          </div>
                        </div>
                      </BaseCard>
                    </BaseRadioHeadless>
                  </Field>

                  <Field
                    v-slot="{ field, errorMessage, handleChange, handleBlur }"
                    name="company.type"
                  >
                    <BaseRadioHeadless
                      value="team_member_3"
                      :model-value="field.value"
                      :error="errorMessage"
                      :disabled="isSubmitting"
                      @update:model-value="handleChange"
                      @blur="handleBlur"
                    >
                      <BaseCard
                        shape="rounded"
                        class="text-muted-400 peer-checked:!border-primary-500 peer-checked:[&_.child]:!text-primary-500 relative border-2 px-2 py-4 grayscale peer-checked:grayscale-0"
                      >
                        <div
                          class="flex w-full flex-col items-center gap-2 text-center"
                        >
                          <Icon
                            name="ph:buildings-duotone"
                            class="child mx-auto h-5 w-5"
                          />

                          <div>
                            <BaseHeading
                              as="h4"
                              size="sm"
                              weight="medium"
                              lead="none"
                            >
                              {{ $t('Corp') }}
                            </BaseHeading>

                            <BaseText size="xs" class="text-muted-400">{{
                              $t('Bigger company')
                            }}</BaseText>
                          </div>

                          <div
                            class="child text-muted-300 absolute right-2 top-2 ms-auto"
                          >
                            <div class="h-2 w-2 rounded-full bg-current"></div>
                          </div>
                        </div>
                      </BaseCard>
                    </BaseRadioHeadless>
                  </Field>
                </div>
              </div>
              <div class="col-span-12">
                <Field
                  v-slot="{ field, errorMessage, handleChange, handleBlur }"
                  name="company.note"
                >
                  <BaseTextarea
                    :label="$t('Company notes')"
                    :placeholder="$t('Write some notes...')"
                    :model-value="field.value"
                    :error="errorMessage"
                    :disabled="isSubmitting"
                    @update:model-value="handleChange"
                    @blur="handleBlur"
                    :class="['border border-[#d9d9d9] rounded-[6px]']"
                  />
                </Field>
              </div>

              <div class="col-span-12">
                <Field v-slot="{ field }" name="company.active_asset_cnt">
                  <BaseInput
                    :label="$t('Active assets')"
                    :model-value="field.value > 0 ? field.value : '-'"
                    type="number"
                    readonly
                    :class="['border border-[#d9d9d9] rounded-[6px]']"
                  />
                </Field>
              </div>
              <div class="ltablet:col-span-6 col-span-12 lg:col-span-6">
                <Field v-slot="{ field }" name="company.active_user_cnt">
                  <BaseInput
                    :label="$t('Active users')"
                    :model-value="field.value"
                    type="number"
                    readonly
                    :class="['border border-[#d9d9d9] rounded-[6px]']"
                  />
                </Field>
              </div>
              <div class="ltablet:col-span-6 col-span-12 lg:col-span-6">
                <Field v-slot="{ field }" name="company.inactive_user_cnt">
                  <BaseInput
                    :label="$t('Inactive users')"
                    :model-value="field.value"
                    type="number"
                    readonly
                    :class="['border border-[#d9d9d9] rounded-[6px]']"
                  />
                </Field>
              </div>
              <div class="ltablet:col-span-6 col-span-12 lg:col-span-6">
                <BaseInput
                  :label="$t('Current active users')"
                  :model-value="currentActiveUserCnt"
                  type="number"
                  readonly
                  :class="['border border-[#d9d9d9] rounded-[6px]']"
                />
              </div>
              <div class="ltablet:col-span-6 col-span-12 lg:col-span-6">
                <BaseInput
                  :label="$t('Current inactive users')"
                  :model-value="currentInactiveUserCnt"
                  type="number"
                  readonly
                  :class="['border border-[#d9d9d9] rounded-[6px]']"
                />
              </div>
            </div>
            <div
              class="mt-5 flex flex-col-reverse text-right md:block md:space-x-3"
            >
              <BaseButton
                type="submit"
                color="primary"
                class="!h-12 w-full sm:w-40"
              >
                {{ $t('Save') }}
              </BaseButton>
            </div>
          </div>
        </div>
      </form>
    </BaseCard>
  </div>
</template>
