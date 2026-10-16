<script setup lang="ts">
import { useTheme } from "vuetify";

const theme = useTheme()

function toggleTheme () {
  if (window && window.localStorage) {
    const color = window.localStorage.getItem('nuxt-color-mode')
    if (color == 'light'){
      theme.global.name.value = 'dark';
    }else{
      theme.global.name.value = 'light';
    }

  }
}
</script>

<template>
  <BaseThemeToggle @click="toggleTheme"/>
</template>

