<script setup>
// const { props } = defineProps(['props'])
const props = defineProps({
  onApproveClick: Function,
  onStart: Function,
  onReturnClick: Function,
  onAssignClick: Function,
  onAcceptClick: Function,
  onDeclinedClick: Function,
  onDeleteClick: Function,
  actions: Function,
  type: String,
  ids: Array,
})
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const isDropdownOpen = ref(false)

const onClick = () => {
  const rowData = props.ids
  // console.log('onClick', props)
  isDropdownOpen.value = !isDropdownOpen.value
}

const onApproveClick = () => {
  const rowData = props.ids
  // console.log('onApproveClick')
  props.onApproveClick(rowData)
}

const onStart = () => {
  // const rowData = props.ids
  // console.log('onStart')
  props.onStart(rowData)
}

const onReturnClick = () => {
  const rowData = props.ids
  // console.log('onReturnClick', props)
  props.onReturnClick(rowData, props.module)
}

const onAssignClick = () => {
  const rowData = props.ids
  // console.log('onAssignClick')
  props.onAssignClick(rowData)
}

const onAcceptClick = () => {
  const rowData = props.ids
  props.onAcceptClick(rowData)
}

const onDeclinedClick = () => {
  const rowData = props.ids
  // console.log('onDeclinedClick', props)
  props.onDeclinedClick(rowData)
}

const onEditClick = () => {
  const rowData = props.ids
  // console.log('onEditClick')
  props.onEditClick(rowData)
}

const onDeleteClick = () => {
  const rowData = props.ids
  // console.log('onDeleteClick')
  props.onDeleteClick(rowData)
}
</script>
<template>
  <Suspense>
    <div class="Menu z-200 multi_actions">
      <BaseDropdown
        flavor="context"
        label="Dropdown"
        orientation="end"
        placement="left-end"
        condensed
        shape="curved"
        class="z-200"
        @click="onClick"
      >
        <template v-if="props.onStart">
          <BaseDropdownItem
            :title="t('Start')"
            :text="t('Create generated work')"
            @click="onStart"
          >
            <template #start>
              <Icon
                name="bpmn:start-event-non-interrupting-condition"
                class="me-2 block h-5 w-5"
              />
            </template>
          </BaseDropdownItem>
          <BaseDropdownDivider />
        </template>

        <template v-if="props.onAcceptClick">
          <BaseDropdownItem
            :title="t('Accept')"
            :text="t('Shift to Open work order')"
            @click="onAcceptClick"
          >
            <template #start>
              <Icon name="ph:check-circle-fill" class="me-2 block h-5 w-5" />
            </template>
          </BaseDropdownItem>
        </template>
        <template v-if="props.onDeclinedClick">
          <BaseDropdownItem
            :title="t('Decline')"
            :text="t('Back to Request list')"
            @click="onDeclinedClick"
          >
            <template #start>
              <Icon
                name="solar:close-circle-linear"
                class="me-2 block h-5 w-5"
              />
            </template>
          </BaseDropdownItem>
        </template>
        <template v-if="props.onAssignClick">
          <BaseDropdownItem
            :title="t('Assign to')"
            :text="t('Assign to control')"
            @click="onAssignClick"
          >
            <template #start>
              <Icon
                name="material-symbols:assignment-ind-sharp"
                class="me-2 block h-5 w-5"
              />
            </template>
          </BaseDropdownItem>
          <BaseDropdownDivider />
        </template>
        <template v-if="props.onApproveClick">
          <BaseDropdownItem
            :title="t('Approve')"
            :text="t('Lock item')"
            @click="onApproveClick"
          >
            <template #start>
              <Icon name="ph:check-circle-fill" class="me-2 block h-5 w-5" />
            </template>
          </BaseDropdownItem>
          <BaseDropdownDivider />
        </template>

        <template v-if="props.onReturnClick">
          <BaseDropdownItem
            :title="t('Return')"
            :text="t('Cancel only approved status')"
            @click="onReturnClick"
          >
            <template #start>
              <Icon name="oui:return-key" class="me-2 block h-5 w-5" />
            </template>
          </BaseDropdownItem>
        </template>

        <template v-if="props.onEditClick">
          <BaseDropdownItem
            :title="t('Edit')"
            :text="t('Edit record')"
            @click="onEditClick"
          >
            <template #start>
              <Icon name="ph:pencil-line-fill" class="me-2 block h-5 w-5" />
            </template>
          </BaseDropdownItem>
          <BaseDropdownDivider />
        </template>

        <template v-if="props.onDeleteClick">
          <BaseDropdownItem
            :title="t('Remove')"
            :text="t('Remove from list')"
            @click="onDeleteClick"
          >
            <template #start>
              <Icon name="ph:trash-duotone" class="me-2 block h-5 w-5" />
            </template>
          </BaseDropdownItem>
        </template>
      </BaseDropdown>
    </div>
  </Suspense>
</template>
<style>
.nui-menu-content {
  z-index: 100 !important;
}
.multi_actions .nui-dropdown .nui-context-button .nui-context-button-inner {
  border: none !important;
}
.multi_actions .nui-context-button.nui-focus:focus-within {
  outline-style: none !important;
  /* outline-color: #cbd5e1; */
}

.multi_actions .nui-dropdown:hover .nui-context-button {
  --tw-ring-color: none !important;
}
</style>
