<script setup>
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
import AssetDropdown from '~/components/assets/AssetDropdown.vue'
const router = useRouter()

let childCnt = 0
const handleRedirectAsset = (el) => {
  if (el.is_more_click) router.push(`/asset/view/${el.id}`)
}
// Computed or method for dynamic margin-left class
const getMarginLeftClass = (is_child, index, children) => {
  if (is_child) {
    childCnt = childCnt + 1
  } else childCnt = 0
  console.log('childCntddd', childCnt, is_child)

  return is_child ? `-ml-${(index + 1) * 2}` : ''
}
</script>
<template>
  <div class="assetNested">
    <!-- <draggable class="pt-1" tag="div" :list="children" :group="{ name: 'g1' }"> -->
    <div
      v-for="(el, index) in children"
      :key="el.id"
      class="pt-1"
      :is_child="is_child"
    >
      <BaseCard shape="curved" class="p-3 dragArea">
        <div class="flex w-full items-center gap-2">
          <div class="grid grid-cols-4 gap-3 w-full">
            <div class="asset_box">
              <BaseTag
                tag="h3"
                size="sm"
                weight="medium"
                @click="handleRedirectAsset(el)"
                class="asset_code text-muted-800 dark:text-muted-100"
              >
                {{ el.asset_code }}
              </BaseTag>
            </div>
            <div class="asset_name">
              <BaseHeading
                tag="h3"
                size="sm"
                weight="medium"
                :class="{
                  'text-muted-800 dark:text-muted-100': true,
                  // [`-ml-${(index + 1) * 2}`]: is_child,
                  // [getMarginLeftClass(is_child, index, children)]: is_child,
                }"
                @click="
                  console.log(
                    `index: ${index}, ml class: -ml-${(index + 1) * 2}`,
                  )
                "
              >
                {{ el.name }}
              </BaseHeading>
            </div>
            <div class="description">
              <BaseHeading
                tag="h3"
                size="sm"
                weight="medium"
                class="text-muted-800 dark:text-muted-100"
              >
                {{ el.description }}
              </BaseHeading>
            </div>
            <div class="asset_date">
              <BaseHeading
                tag="h3"
                size="sm"
                weight="medium"
                class="text-muted-800 dark:text-muted-100"
              >
                {{ el.warranty_finish_date }}
              </BaseHeading>
            </div>
          </div>
        </div>
      </BaseCard>
      <nested-draggable
        :children="el.children"
        :is_child="true"
        class="pl-5 child"
      />
    </div>
    <!-- </draggable> -->
  </div>
</template>
<script>
import { VueDraggableNext } from 'vue-draggable-next'

export default {
  props: {
    children: {
      required: true,
      type: Array,
    },
    is_child: Boolean,
  },
  components: {
    draggable: VueDraggableNext,
  },
  name: 'nested-draggable',
}
</script>

<style>
.assetNested {
  width: 100%;
}
.assetNested .asset_box {
  /* background: red; */
}
.assetNested .nui-card {
  display: flex;
  align-items: center; /* Текстүүдийг босоо чиглэлд зэрэгцүүлэх */
  padding: 10px;
  border-bottom: 1px solid #ddd; /* Доод хил нэмэх */
}

.assetNested .nui-card p {
  flex: 1; /* Бүх нүдийг ижил хэмжээтэй болгоно */
  text-align: left; /* Зүүн тийш зэрэгцүүлэх (center эсвэл right болгож болно) */
  display: flex;
  align-items: center;
  vertical-align: middle; /* Босоо төвшинд зэрэгцүүлэх */
}
.assetNested .nui-card .asset_code {
  cursor: pointer;
  border-color: '#b0aeae';
  box-shadow: 1px 2px 4px 0px rgba(166, 166, 166, 0.25);
}
.assetNested .nui-card .asset_code:hover {
  cursor: pointer;
  border-color: gray;
  box-shadow: 2px 2px 4px 1px rgba(166, 166, 166, 0.35);
}
</style>
