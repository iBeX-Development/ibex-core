<script setup>
import {useI18n} from "vue-i18n";
const { t } = useI18n({ useScope: "global" });
const props = defineProps({
  id: Number,
});
const id = computed({
  get: () => {
    return props.id;
  },
  set: (value) => {
    this.$emit('props.id', value);
  },
});


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
        :to="'/asset/update/' + props.id"
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
</template>

<script>

export default {
  name: "AssetDropdown.vue"
}
</script>
