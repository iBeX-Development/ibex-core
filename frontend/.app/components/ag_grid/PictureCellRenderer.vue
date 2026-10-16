<script setup lang="ts">
const { params } = defineProps(['params'])
const { value, data } = params
const config = useRuntimeConfig()
const items = ref(null)
const selectedItem = ref(null)
const isOpenImg = ref(false)
import ImageViewerModal from '~/components/form/ImageViewerModal.vue'

// console.log('params ->', params)
// console.log('data ->', data)

const get_content_url = (file) => {
  // console.log('file ->', file)

  if (file && file.type.includes('image')) {
    return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
  } else {
    return ``
  }
}

if (data && 'picture' in data) {
  items.value = data.picture
} else if (data && 'part' in data) {
  items.value = data.part.picture
} else if (data && 'file' in data) {
  items.value = data.file
}

const showImg = (file) => {
  // console.log('file ->', file)
  isOpenImg.value = true
  selectedItem.value = file
}
const handleModalClose = () => {
  isOpenImg.value = false
}
</script>

<template>
  <div class="productCell" @click="showImg(items)">
    <div v-if="items != null" class="image">
      <img :src="get_content_url(items)" alt="part" />
    </div>
    <!-- <div>
      <div>{{ value }}</div>
      <div class="stockCell">{{ data.email }}</div>
    </div> -->
  </div>
  <ImageViewerModal
    :itemsValue="selectedItem"
    :open="isOpenImg"
    :close="handleModalClose"
  />
</template>

<style>
.productCell {
  height: 100%;
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: start;
}

.image {
  max-width: 100%;
  max-height: 100px;
  background-color: rgba(201, 201, 201, 0.2);
  border-radius: 8px;
  /* margin: 8px; */
}

.image img {
  width: 37px;
  height: 37px;
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
