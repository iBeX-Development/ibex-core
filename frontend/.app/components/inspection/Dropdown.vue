<script setup>
const { updateItem } = useDirectusItems()
import { useI18n } from 'vue-i18n'
import DeletionModalForm from '~/components/form/DeletionModalForm.vue'
import { ref } from 'vue'
import WorkOrderDeletionModalForm from '~/components/form/WorkOrderDeletionModalForm.vue'
const { t } = useI18n({ useScope: 'global' })
const router = useRouter()
const toaster = useToaster()
const user = useDirectusUser()
const { params } = useRoute()

const props = defineProps({
  id: Number,
  refresh: Function,
  item: Object,
  handleAssignTo: Function,
})
const id = computed({
  get: () => {
    return props.id
  },
  set: (value) => {
    this.$emit('props.id', value)
  },
})
const isModalConfirmOpen = ref(false)
const handleModalConfirmClose = () => {
  isModalConfirmOpen.value = false
}

const handleAcceptRequest = () => {
  const updateData = {
    collection: 'Work_inspections',
    id: props.id,
    item: {
      type: 2, //????
    },
  }
  updateItem(updateData).then((res) => {
    // router.push(`/workorder/location/open/${res?.location}`);
    toaster.show({
      title: t('Update success'),
      message: t(`Record update successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  })
}
const handleAssign = () => {
  props.handleAssignTo()
}
const handleDecline = () => {
  const updateData = {
    collection: 'Work_inspections',
    id: props.id,
    item: {
      accepted_user: user.value.id,
      is_accepted: false,
    },
  }
  updateItem(updateData).then((res) => {
    props.refresh()
    toaster.show({
      title: t('Update success'),
      message: t(`Record update successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  })
}
const handleAccept = () => {
  const updateData = {
    collection: 'Work_inspections',
    id: props.id,
    item: {
      accepted_user: user.value.id,
      is_accepted: true,
    },
  }
  updateItem(updateData).then((res) => {
    props.refresh()
    toaster.show({
      title: t('Update success'),
      message: t(`Record update successfully`) + '!',
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  })
}
</script>
<template>
  <BaseDropdown
    flavor="context"
    label="Dropdown"
    orientation="end"
    condensed
    shape="curved"
    class="mt-[-18px]"
    v-if="props.item.status !== 5"
  >
    <div class="">
      <BaseDropdownItem
        :title="t('Accept request')"
        :text="t('Accept request and move to open work order')"
        @click="handleAcceptRequest"
        v-if="props.item?.type?.code_work_order === 'request'"
      >
        <template #start>
          <Icon
            name="material-symbols:check-rounded"
            class="me-2 block h-5 w-5"
          />
        </template>
      </BaseDropdownItem>
      <BaseDropdownItem
        :title="t('Accept request')"
        :text="t('Accept request')"
        @click="handleAccept"
        v-if="
          props.item?.assigned_to && props.item?.assigned_to?.id === user?.id
        "
      >
        <template #start>
          <Icon
            name="material-symbols:check-rounded"
            class="me-2 block h-5 w-5"
          />
        </template>
      </BaseDropdownItem>
      <BaseDropdownItem
        :title="t('Assign to')"
        :text="t('Assign to')"
        @click="handleAssign"
        v-if="props.item?.type?.code_work_order !== 'request'"
      >
        <template #start>
          <Icon
            name="material-symbols:assignment-ind-sharp"
            class="me-2 block h-5 w-5"
          />
        </template>
      </BaseDropdownItem>

      <BaseDropdownItem
        :title="t('Decline')"
        :text="t('Decline from list')"
        @click="handleDecline"
        v-if="
          props.item?.assigned_to && props.item?.assigned_to?.id === user?.id
        "
      >
        <template #start>
          <Icon
            name="material-symbols:cancel-presentation-outline-sharp"
            class="me-2 block h-5 w-5"
          />
        </template>
      </BaseDropdownItem>
    </div>
  </BaseDropdown>
  <WorkOrderDeletionModalForm
    :key="props.id"
    code="Work_order"
    :open="isModalConfirmOpen"
    :close="handleModalConfirmClose"
    :row="props.id"
    :refresh="props.refresh"
  />
</template>

<script>
export default {
  name: 'WorkorderDropdown',
}
</script>
