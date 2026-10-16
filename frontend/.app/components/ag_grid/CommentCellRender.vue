<script setup lang="ts">
const { params } = defineProps(['params'])
const { value, data } = params
const config = useRuntimeConfig()
const file_items = ref(null)
const selectedItem = ref(null)
const isOpenImg = ref(false)
const key = ref(1)

const isOpenComment = ref(false)

import CommentModalForm from '~/components/form/CommentModalForm.vue'

// console.log('params ->', params)
// console.log('data ->', data)

const get_content_url = (file) => {
  console.log('file ->', file)
  console.log('config.public.directus.url ->', config.public.directus.url)

  // Check if file is just an ID string or a full object
  if (typeof file === 'string') {
    // If it's just an ID, assume it's an image and return the URL
    return `${config.public.directus.url}assets/${file}`
  } else if (file && typeof file === 'object') {
    // If it's an object, check if it has type property and includes image
    if (file.type && file.type.includes('image')) {
      return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
    } else {
      return ``
    }
  } else {
    return ``
  }
}

if (data && 'picture' in data) {
  file_items.value = data.picture
} else if (data && 'part' in data) {
  file_items.value = data.part.picture
} else if (data && 'file' in data) {
  file_items.value = data.file
}

const showImg = (file) => {
  // console.log('file ->', file)
  isOpenImg.value = true
  selectedItem.value = file
}

const showComment = (item) => {
  // console.log('showComment ->', item)
  isOpenComment.value = true
  selectedItem.value = item
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}

const refresh = () => {
  console.log('refresh -->')
  // params.refreshCell({ force: true })
  // params.api.refreshCells({ force: true })
}

const handleModalClose = () => {
  isOpenImg.value = false
  isOpenComment.value = false
  // selectedItem.value = false
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}
</script>

<template>
  <div class="productCell" @click="showComment(data)">
    <div class="comment_cnt">{{ data.comment_cnt }}</div>
    <!-- <div v-if="file_items != null" class="image">
      <img :src="get_content_url(file_items)" alt="part" />
    </div> -->
  </div>
  <CommentModalForm
    :key="key"
    :itemsValue="selectedItem"
    :open="isOpenComment"
    :close="handleModalClose"
    collection="Work_order_comments"
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
  border: 1px solid;
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
