<script setup>
import { Menu, MenuButton, MenuItem, MenuItems } from '@headlessui/vue'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import WorkOrderDeletionModalForm from '~/components/form/WorkOrderDeletionModalForm.vue'

const { t } = useI18n({ useScope: 'global' })
const router = useRouter()
const toaster = useToaster()

const props = defineProps({
  id: {
    type: [String, Number],
    required: true
  },
  refresh: {
    type: Function,
    required: true
  },
  item: {
    type: Object,
    required: true
  },
  handleAssignTo: {
    type: Function,
    default: () => {}
  }
})

const isDropdownOpen = ref(false)
const isModalOpen = ref(false)

const onEditClick = () => {
  router.push(`/work-order/${props.id}`)
}

const onDeleteClick = () => {
  isModalOpen.value = true
}

const handleModalClose = () => {
  isModalOpen.value = false
}

const onApproveClick = () => {
  const data = {
    collection: 'Work_order',
    id: props.id,
    item: {
      status: 3
    }
  }
  updateItem(data).then(() => {
    props.refresh()
    toaster.show({
      title: t('Update success'),
      message: t('Record update successfully') + '!',
      color: 'success',
      icon: 'ph:check-circle-fill',
      closable: true
    })
  })
}

const onAssignClick = () => {
  props.handleAssignTo()
}
</script>

<template>
  <div class="relative">
    <Menu as="div" class="relative inline-block text-left">
      <MenuButton
        class="nui-focus relative inline-flex items-center justify-center gap-x-2 rounded-lg border border-muted-200 bg-white px-3 py-2 text-sm font-medium leading-normal text-muted-700 shadow-sm transition-colors duration-150 hover:bg-muted-50 hover:text-muted-600 dark:border-muted-700 dark:bg-muted-800 dark:text-muted-200 dark:hover:bg-muted-900 dark:hover:text-muted-100"
      >
        <Icon name="lucide:more-horizontal" class="h-4 w-4" />
      </MenuButton>

      <transition
        enter-active-class="transition duration-100 ease-out"
        enter-from-class="transform scale-95 opacity-0"
        enter-to-class="transform scale-100 opacity-100"
        leave-active-class="transition duration-75 ease-in"
        leave-from-class="transform scale-100 opacity-100"
        leave-to-class="transform scale-95 opacity-0"
      >
        <MenuItems
          class="nui-menu-content absolute right-0 z-50 mt-2 w-64 origin-top-right divide-y divide-muted-100 rounded-lg border border-muted-200 bg-white shadow-lg dark:divide-muted-700 dark:border-muted-700 dark:bg-muted-800"
        >
          <div class="p-2">
            <MenuItem v-slot="{ active }">
              <button
                :class="[
                  active ? 'bg-primary-500/10 text-primary-500' : 'text-muted-600 dark:text-muted-200',
                  'nui-focus group flex w-full items-center rounded-lg p-2 text-left text-sm'
                ]"
                @click="onApproveClick"
              >
                <Icon name="ph:check-circle-fill" class="me-2 block h-5 w-5" />
                <span class="block truncate">{{ t('Approve') }}</span>
              </button>
            </MenuItem>

            <MenuItem v-slot="{ active }">
              <button
                :class="[
                  active ? 'bg-primary-500/10 text-primary-500' : 'text-muted-600 dark:text-muted-200',
                  'nui-focus group flex w-full items-center rounded-lg p-2 text-left text-sm'
                ]"
                @click="onAssignClick"
              >
                <Icon name="ph:user-circle-fill" class="me-2 block h-5 w-5" />
                <span class="block truncate">{{ t('Assign to') }}</span>
              </button>
            </MenuItem>

            <MenuItem v-slot="{ active }">
              <button
                :class="[
                  active ? 'bg-primary-500/10 text-primary-500' : 'text-muted-600 dark:text-muted-200',
                  'nui-focus group flex w-full items-center rounded-lg p-2 text-left text-sm'
                ]"
                @click="onEditClick"
              >
                <Icon name="ph:pencil-line-fill" class="me-2 block h-5 w-5" />
                <span class="block truncate">{{ t('Edit') }}</span>
              </button>
            </MenuItem>

            <MenuItem v-slot="{ active }">
              <button
                :class="[
                  active ? 'bg-primary-500/10 text-primary-500' : 'text-muted-600 dark:text-muted-200',
                  'nui-focus group flex w-full items-center rounded-lg p-2 text-left text-sm'
                ]"
                @click="onDeleteClick"
              >
                <Icon name="ph:trash-duotone" class="me-2 block h-5 w-5" />
                <span class="block truncate">{{ t('Remove') }}</span>
              </button>
            </MenuItem>
          </div>
        </MenuItems>
      </transition>
    </Menu>

    <WorkOrderDeletionModalForm
      :key="props.id"
      :open="isModalOpen"
      :close="handleModalClose"
      :refresh="props.refresh"
      :row="props.id"
    />
  </div>
</template>

<style scoped>
.nui-menu-content {
  z-index: 100 !important;
}
</style> 