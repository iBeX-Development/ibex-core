<script setup>
const { params } = defineProps(['params'])
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })

const permissions = JSON.parse(
  window.localStorage.getItem('app_permissions') || '{}',
)

const isDropdownOpen = ref(true)
if (
  !params.onApproveClick &&
  !params.onReturnClick &&
  !params.onAssignClick &&
  !params.onAcceptClick &&
  !params.onDeclinedClick &&
  !params.onCompleteClick &&
  !params.onCloseClick &&
  !params.onDeleteClick &&
  !params.onEditClick &&
  !params.onStart
)
  isDropdownOpen.value = false
// console.log('isDropdownOpen', params)
// if (permissions && permissions[1] && permissions[1].includes('admin')) {
//   isDropdownOpen.value = true
// }
const onClick = () => {
  const rowData = params.node.data
  // console.log('onClick', params.node.id)
  // isDropdownOpen.value = !isDropdownOpen.value
  const rowNode = params.api?.getRowNode?.(params.node?.id)
  const rowElement = rowNode?.rowIndex
  if (rowElement === undefined) {
    return
  }
  const row = document.querySelectorAll('.ag-row-focus')[rowElement]
  if (row && params.node.id == 0) {
    let _style = row.style
    _style['z-index'] = 1
    // row.style = isDropdownOpen.value ? '999' : '2'
    row.style = _style
    // let menu = row.querySelectorAll('.Menu .nui-dropdown-menu')
    // if (menu) {
    //   console.log('Margin-top updated')
    // } else {
    //   console.log('Menu element not found')
    // }
  }
}

const onApproveClick = () => {
  const rowData = params.node.data
  console.log('onApproveClick')
  params.onApproveClick(rowData)
}

const onStart = () => {
  const rowData = params.node.data
  console.log('onStart')
  params.onStart(rowData)
}

const onReturnClick = () => {
  const rowData = params.node.data
  console.log('onReturnClick', params)
  params.onReturnClick(rowData, params.module)
}

const onAssignClick = () => {
  const rowData = params.node.data
  console.log('onAssignClick')
  params.onAssignClick(rowData)
}

const onAcceptClick = () => {
  const rowData = params.node.data
  params.onAcceptClick(rowData)
}

const onDeclinedClick = () => {
  const rowData = params.node.data
  console.log('onDeclinedClick', params)
  params.onDeclinedClick(rowData)
}

const onEditClick = () => {
  const rowData = params.node.data
  console.log('onEditClick')
  params.onEditClick(rowData)
}

const onCompleteClick = () => {
  const rowData = params.node.data
  console.log('onCompleteClick')
  params.onCompleteClick(rowData)
}

const onCloseClick = () => {
  const rowData = params.node.data
  console.log('onCloseClick')
  params.onCloseClick(rowData)
}

const onDeleteClick = () => {
  const rowData = params.node.data
  console.log('onDeleteClick')
  params.onDeleteClick(rowData)
}
</script>
<template>
  <Suspense>
    <div v-if="isDropdownOpen" class="Menu z-200 actionBttn">
      <BaseDropdown
        flavor="context"
        label="Dropdown"
        orientation="end"
        placement="left-end"
        condensed
        shape="curved"
        class="z-200 BaseDropdown"
        @click="onClick"
      >
        <template v-if="params.onStart">
          <BaseDropdownItem
            :title="t('Start')"
            :text="t('Create generated work')"
            @click="onStart"
          >
            <template #start>
              <Icon
                name="bpmn:start-event-non-interrupting-condition"
                class="me-2 block h-5 w-5 text-success-800"
              />
            </template>
          </BaseDropdownItem>
          <BaseDropdownDivider />
        </template>

        <template v-if="params.onAcceptClick">
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
        <template v-if="params.onDeclinedClick">
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
        <template v-if="params.onAssignClick">
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
        <template v-if="params.onApproveClick">
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

        <template v-if="params.onReturnClick">
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

        <template v-if="params.onCompleteClick">
          <BaseDropdownItem
            :title="t('Complete')"
            :text="t('Mark as completed')"
            @click="onCompleteClick"
          >
            <template #start>
              <Icon
                name="octicon:tracked-by-closed-completed-24"
                class="me-2 block h-5 w-5"
              />
            </template>
          </BaseDropdownItem>
          <BaseDropdownDivider />
        </template>

        <template v-if="params.onCloseClick">
          <BaseDropdownItem
            :title="t('Close')"
            :text="t('Close work order')"
            @click="onCloseClick"
          >
            <template #start>
              <Icon name="ph:x-circle-fill" class="me-2 block h-5 w-5" />
            </template>
          </BaseDropdownItem>
          <BaseDropdownDivider />
        </template>

        <template v-if="params.onEditClick">
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

        <template v-if="params.onDeleteClick">
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
    <div
      v-else
      class="flex h-full items-center justify-center text-xs text-muted-400"
    >
      {{ t('No actions') }}
    </div>
  </Suspense>
</template>
<style>
.nui-menu-content {
  z-index: 100 !important;
}
div:has(> .nui-dropdown-menu) {
  z-index: 100 !important;
}
</style>
