<script setup>
import {useI18n} from "vue-i18n";
import DeletionModalForm from "~/components/form/DeletionModalForm.vue";
import {ref} from "vue";
import PmDeletionModalForm from "~/components/form/PmDeletionModalForm.vue";
const { t } = useI18n({ useScope: "global" });
const props = defineProps({
  id: Number,
  refresh: Function
});
const id = computed({
  get: () => {
    return props.id;
  },
  set: (value) => {
    this.$emit('props.id', value);
  },
});
const isModalConfirmOpen = ref(false)
const handleModalConfirmClose = () =>{
  isModalConfirmOpen.value = false;
}


</script>
<template>
  <BaseDropdown
    flavor="context"
    label="Dropdown"
    orientation="end"
    condensed
    shape="curved"
    class="absolute mt-[-18px]"
  >
    <div class="">
      <BaseDropdownItem
        :title="t('Edit')"
        :text="t('Edit record')"
        :to="'/pm/update/' + props.id"
      >
        <template #start>
          <Icon
            name="ph:pencil-line-fill"
            class="me-2 block h-5 w-5"
          />
        </template>
      </BaseDropdownItem>
      <BaseDropdownDivider />
      <BaseDropdownItem
        :title="t('Remove')"
        :text="t('Remove from list')"
        @click="isModalConfirmOpen = true;"
      >
        <template #start>
          <Icon
            name="ph:trash-duotone"
            class="me-2 block h-5 w-5"
          />
        </template>
      </BaseDropdownItem>
    </div>
  </BaseDropdown>
  <PmDeletionModalForm
      :key=props.id
      code="Pm"
      :open="isModalConfirmOpen"
      :close="handleModalConfirmClose"
      :row=props.id
      :refresh=props.refresh
  />

</template>

<script>

export default {
  name: "WorkorderDropdown"
}
</script>
