<script setup lang="ts">
import SideBarNavigation from '~/components/global/SideBarNavigationSettings'
// import { getMyCompanyId } from '~/utils/storageKeys'
const companyId = getMyCompanyId()
// console.log('settings_companyId', companyId)

const visibleNavigation = computed(() =>
  SideBarNavigation.map((item) => ({
    ...item,
    children:
      companyId !== 1
        ? item.children.filter((child) => child.collection !== 'Companies')
        : item.children,
  })),
)
const openIndexes = ref(
  Array.from({ length: visibleNavigation.value.length }, (_, i) => i),
)

const toggleChildren = (index: number) => {
  if (openIndexes.value.includes(index)) {
    openIndexes.value = openIndexes.value.filter((i) => i !== index)
  } else {
    openIndexes.value.push(index)
  }
}

definePageMeta({
  title: 'Settings',
  preview: {
    title: 'Settings',
    description: 'For displaying account settings',
    categories: ['layouts', 'profile'],
    src: '/img/screens/layouts-subpages-settings.png',
    srcDark: '/img/screens/layouts-subpages-settings-dark.png',
    order: 81,
  },
})
</script>

<template>
  <div class="mx-auto w-full max-w-7xl">
    <br />
    <div class="">
      <div v-for="(item, index) in visibleNavigation" :key="index" class="item">
        <div
          @click="toggleChildren(index)"
          style="cursor: pointer; color: gray"
        >
          <span class="ml-2">{{ $t(item.name) }}</span>
          <span class="ml-2">
            <Icon
              :name="
                openIndexes.includes(index)
                  ? 'material-symbols:keyboard-arrow-down'
                  : 'material-symbols:keyboard-arrow-up'
              "
            />
          </span>
        </div>
        <div v-if="openIndexes.includes(index)" style="display: flex">
          <BaseCard
            v-for="(child, childIndex) in item.children"
            :key="childIndex"
            shape="curved"
            elevated-hover
            class="hover:!border-primary-500 group border-2 md:w-auto m-2.5"
          >
            <NuxtLink :to="child.to" class="block p-6">
              <div class="text-center">
                <Icon
                  :name="child.icon"
                  class="group-hover:text-primary-500 text-muted-400 h-8 w-8 transition-all duration-300 group-hover:rotate-6"
                />
                <BaseHeading
                  tag="h3"
                  size="sm"
                  weight="semibold"
                  class="mt-2 !text-[0.65rem] uppercase"
                >
                  {{ $t(child.name) }}
                </BaseHeading>
                <BaseText size="xs" class="text-muted-400">
                  {{ $t(`Manage ${child.name.toLowerCase()}`) }}
                </BaseText>
              </div>
            </NuxtLink>
          </BaseCard>
        </div>
      </div>
    </div>
  </div>
</template>
