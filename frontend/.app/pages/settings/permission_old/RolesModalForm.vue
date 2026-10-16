<script setup lang="ts">
import { useI18n } from 'vue-i18n'
const { t } = useI18n({ useScope: 'global' })
const { getItems, updateItem, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
import { ref } from 'vue'
const runtimeConfig = useRuntimeConfig()
const schema = ref([])
let fileId = ref(-1)
let thumbnailUrl = ref(-1)
const { token } = useDirectusToken()
const route = useRoute()
// const value = ref(true)
const values = reactive({
  role1: true,
  role2: true,
  role3: true,
  role4: true,
  role5: true,
})

const props = defineProps({
  open: Boolean,
  title: String,
  code: String,
  task: String,
  path: {
    type: String,
    default: '',
  },
  row: Array,
  rowItems: Array,
  size: String,
  close: Function,
  refresh: Function,
  refresh_modal: Function,
  schema_column: String,
})

const allMenus = ref([])
const userMenu = ref([])

const allRoles = ref([])
const userRole = ref([])

const all_locations = ref([])
const openIndexes = ref(1)

const toggleChildren = (index: number) => {
  if (openIndexes.value.includes(index)) {
    openIndexes.value = openIndexes.value.filter((i) => i !== index)
  } else {
    openIndexes.value.push(index)
  }
}

const onSubmit = async () => {
  if (props.task === 'menu') {
    try {
      const updatedMenus = Object.entries(menuValues.value).map(
        ([menuId, value]) => ({
          user_id: props.row.userId,
          menu_id: menuId,
          is_active: value ? 1 : 0,
        }),
      )
      deleteItems({
        collection: 'menu_users',
        items: {
          query: {
            filter: {
              user_id: props.row.userId,
            },
          },
        },
      }).then(() => {
        console.log('delete_items:', props.row.userId)
      })

      await Promise.all(
        updatedMenus.map(async (item) => {
          if (item.is_active === 1) {
            await createItems({
              collection: 'menu_users',
              items: [
                {
                  user_id: item.user_id,
                  menu_id: item.menu_id,
                  is_active: item.is_active,
                },
              ],
            })
            console.log(
              `Menu ID ${item.menu_id} activated for user ${item.user_id}`,
            )
          }
        }),
      )

      props.refresh()
      props.close()
    } catch (error) {
      console.error('Error saving menu data:', error)
    }
  }

  if (props.task === 'role') {
    try {
      const updatedRoles = []

      for (const [locationId, roles] of Object.entries(rolesValues.value)) {
        for (const [roleId, isActive] of Object.entries(roles)) {
          if (isActive) {
            updatedRoles.push({
              user_id: props.row.userId,
              location_id: locationId,
              role_id: roleId,
            })
          }
        }
      }

      deleteItems({
        collection: 'Users_perm',
        items: {
          query: {
            filter: {
              user_id: props.row.userId,
            },
          },
        },
      }).then(async () => {
        await Promise.all(
          updatedRoles.map(async (item) => {
            // main locationg oruulahgui
            if (props.row.mainLocation.id != item.location_id) {
              await createItems({
                collection: 'Users_perm',
                items: [
                  {
                    user_id: item.user_id,
                    location: item.location_id,
                    role: item.role_id,
                    company_id: myCompanyId,
                  },
                ],
              })
            }
          }),
        )

        console.log('Roles updated successfully!')
      })
      props.refresh?.()
      props.close?.()
    } catch (error) {
      console.error('Error saving role data:', error)
    }
  }

  if (props.task === 'location') {
    const updatedMenus = Object.entries(locationSubMenuValues.value).reduce(
      (acc, [menuId, value]) => {
        if (value) {
          acc.push({
            submenu_id: parseInt(menuId),
            location_id: props.row.locationId,
            role_id: props.row.roleId,
            user_id: props.row.userId,
          })
        }
        return acc
      },
      [],
    )

    try {
      // console.log('updatedMenus', updatedMenus)
      deleteItems({
        collection: 'Location_menus',
        items: {
          query: {
            filter: {
              user_id: props.row.userId,
              location_id: props.row.locationId,
              role_id: props.row.roleId,
            },
          },
        },
      }).then(() => {
        console.log('delete_items:', props.row.userId)
      })

      await Promise.all(
        updatedMenus.map(async (item) => {
          await createItems({
            collection: 'Location_menus',
            items: [
              {
                user_id: item.user_id,
                submenu_id: item.submenu_id,
                location_id: item.location_id,
                role_id: item.role_id,
              },
            ],
          })
          console.log(
            `Menu ID ${item.submenu_id} activated for user ${item.user_id}`,
          )
        }),
      )
      props.refresh()
      props.close()
    } catch (error) {
      console.error('Error saving menu data:', error)
    }
  }
}

if (Array.isArray(props.rowItems)) {
  allMenus.value = props.rowItems
  allRoles.value = props.rowItems
}

if (Array.isArray(props.row.allMenusDetails)) {
  userMenu.value = props.row.allMenusDetails
}

if (Array.isArray(props.row.allRolesDetails)) {
  userRole.value = props.row.allRolesDetails
}

if (Array.isArray(props.row.locations)) {
  all_locations.value = props.row.locations
  openIndexes.value = Array.from(
    { length: props.row.locations.length },
    (_, i) => i,
  )
}

let menuValues = ref([])
let locationMenus = ref([])
let locationSubMenuValues = ref([])
let switchStates = []
let displayedMenus = []

const isLocationInMyLocations = (locationId) => {
  return userRole.value.some((myLoc) => myLoc.locationId === locationId)
}

const rolesValues = ref({})
const updateRolesValues = () => {
  rolesValues.value = {}

  // console.log('updateRolesValues_allRoles', allRoles.value)
  // console.log('updateRolesValues_userRole', userRole.value)
  // console.log('updateRolesValues_all_locations', all_locations.value)

  all_locations.value.forEach((location) => {
    if (!rolesValues.value[location.id]) {
      rolesValues.value[location.id] = {}
    }

    allRoles.value.forEach((role) => {
      rolesValues.value[location.id][role.id] = false

      const isRoleAssigned = userRole.value.some(
        (userRoleItem) =>
          userRoleItem.roleId === role.id &&
          userRoleItem.locationId === location.id,
      )

      if (isRoleAssigned) {
        rolesValues.value[location.id][role.id] = true
      }
    })
  })
}

if (props.task == 'menu') {
  menuValues.value = allMenus.value.reduce((acc, menu) => {
    acc[menu.id] = userMenu.value.some(
      (userMenuItem) => userMenuItem.menu_id.id === menu.id,
    )
    return acc
  }, {})
}

if (props.task == 'role') {
  all_locations.value.forEach((location) => {
    return (switchStates[location.id] = isLocationInMyLocations(location.id))
  })

  updateRolesValues()
}

if (props.task == 'location') {
  locationMenus.value = props.row.locationSubMenuAll
  displayedMenus = props.row.locationSubMenu
  locationSubMenuValues.value = locationMenus.value.reduce((acc, menu) => {
    acc[menu.id] = displayedMenus.some((userMenuItem) => {
      if (userMenuItem.id === menu.id) return userMenuItem.is_show
    })
    return acc
  }, {})
}
</script>

<template>
  <!-- New & Edit modal -->
  <TairoModal
    :key="props.key"
    :open="props.open"
    :size="props.size"
    @close="close"
  >
    <template #header>
      <!-- Header -->
      <div class="flex w-full items-center justify-between p-2 md:p-2">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-black pl-8"
        >
          {{ t(title) }}
        </h3>
        <BaseButtonClose @click="close" />
      </div>
    </template>

    <!-- Body -->
    <div class="mx-auto w-full px-10 overflow-scroll" style="max-height: 500px">
      <form
        method="POST"
        action=""
        class="w-full pb-16"
        @submit.prevent="onSubmit"
      >
        <div v-if="props.task === 'menu'">
          <BaseFocusLoop class="md:max-w-lg">
            <div v-for="menu in props.rowItems" :key="menu.id" class="mb-3.5">
              <BaseSwitchThin
                v-model="menuValues[menu.id]"
                :label="menu.title"
                color="primary"
              />
            </div>
          </BaseFocusLoop>
        </div>
        <div v-if="props.task === 'role'">
          <div
            v-for="(location, index) in all_locations"
            :key="location.id"
            class="mb-3.5"
          >
            <div class="flex">
              <div>
                <BaseSwitchThin
                  v-model="switchStates[location.id]"
                  color="primary"
                />
              </div>
              <div style="color: gray">
                {{
                  location.name +
                  ' ' +
                  (userRole.find(
                    (role) => role.locationId === location.id && role.mainrole,
                  )
                    ? '(main)'
                    : '')
                }}
              </div>
              <div
                @click="toggleChildren(index)"
                class="ml-2"
                style="cursor: pointer; color: gray"
              >
                <Icon
                  :name="
                    openIndexes.includes(index)
                      ? 'material-symbols:keyboard-arrow-down'
                      : 'material-symbols:keyboard-arrow-up'
                  "
                />
              </div>
            </div>
            <div v-if="openIndexes.includes(index)" class="flex flex-col ml-12">
              <div v-for="role in props.rowItems" :key="role.id" class="mb-3.5">
                <BaseSwitchThin
                  v-model="rolesValues[location.id][role.id]"
                  :label="role.name"
                  color="primary"
                />
              </div>
            </div>
          </div>
        </div>
        <div v-if="props.task === 'location'">
          <BaseFocusLoop class="md:max-w-lg">
            <div v-for="menu in displayedMenus" :key="menu.id" class="mb-3.5">
              <BaseSwitchThin
                v-model="locationSubMenuValues[menu.id]"
                :label="menu.name"
                color="primary"
              />
            </div>
          </BaseFocusLoop>
        </div>

        <div
          style="
            float: right;
            background: #8e6ff5;
            border-radius: 8px;
            color: white;
            margin-top: -18px;
          "
        >
          <button
            type="submit"
            class="btn btn-primary m-4 w-24"
            color="primary"
          >
            Submit
          </button>
        </div>
      </form>
    </div>
  </TairoModal>
</template>
