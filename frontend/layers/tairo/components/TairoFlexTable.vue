<template>
  <div class="relative">
    <div class="hidden justify-between md:flex md:items-center">
      <slot name="header"></slot>
    </div>

    <div class="flex flex-col">
      <slot></slot>
    </div>
  </div>
</template>
