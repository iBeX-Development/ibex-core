<script setup lang="ts">

import NormalForm from "~/components/form/NormalForm.vue";

definePageMeta({
  middleware: ["auth"],
  title: 'Work request',
})

</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <!-- Header -->
      <div class="col-span-12">
        <NormalForm
          title="Work request"
          code="Work_request"
          schema_column="three-column-form"
        />
      </div>
    </div>
  </div>
</template>
