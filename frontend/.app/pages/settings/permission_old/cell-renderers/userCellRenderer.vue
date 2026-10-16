<script setup>
const { params } = defineProps(['params'])
const { value, data } = params

const get_content_url = (file) => {
  if (file.type.includes('image')) {
    return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
  } else {
    return `/img/avatars/man.jpg`
  }
}
</script>

<template>
  <div class="productCell">
    <div class="image">
      <img :src="`${data.image}`" :alt="data.image" />
    </div>
    <div>
      <div>{{ value }}</div>
      <div class="stockCell">{{ data.email }}</div>
    </div>
  </div>
</template>

<style>
.productCell {
  height: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
}

.image {
  max-width: 100%;
  max-height: 100px;
  background-color: rgba(201, 201, 201, 0.2);
  border-radius: 8px;
  margin: 8px;
}

.image img {
  width: 60px;
  height: 60px;
}

.productCell div:first-child {
  font-weight: 500;
}

.productCell div {
  padding-bottom: 0;
  line-height: 1.5;
}

.productCell img {
  border-radius: 8px;
}

.stockCell {
  background-color: var(--color-bg-secondary);
  color: var(--color-text-secondary);
  width: fit-content;
  padding-top: 2px;
  margin-top: 4px;
  padding-right: 4px;
  padding-left: 4px;
  font-size: 12px;
}
</style>
