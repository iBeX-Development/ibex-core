<script>
import { VueDraggableNext } from 'vue-draggable-next'
import TaskTemplateChooseModalForm from '~/components/form/TaskTemplateChooseModalForm.vue'
import WorkItemDropdown from './Dropdown.vue'

const { createItems, updateItem, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
let roots = []
export default {
  data() {
    return {
      selectedItem: -1,
      key: -1,
      isModalOpen: false,
      parent: -1,
      draggingItem: null,
      targetIndex: null,
      highlight: false,
    }
  },
  props: {
    children: {
      required: true,
      type: Array,
    },
    refresh: {
      required: false,
      type: Function,
    },
    changeFn: {
      required: false,
      type: Function,
    },
    progress: {
      required: false,
      type: Function,
    },
    freeze: {
      required: false,
      type: Boolean,
    },
    code: {
      required: false,
      type: Number,
    },
    rootItems: {
      required: false,
      type: Array,
    },
    parentItem: {
      required: false,
      type: Array,
    },
    template_types: {
      required: false,
      type: Array,
    },
    collection: {
      required: false,
      type: String,
      default: 'Work_order_item',
    },
  },
  components: {
    TaskTemplateChooseModalForm,
    draggable: VueDraggableNext,
    WorkItemDropdown,
  },
  name: 'work-order-item-dynamic-nested',
  // created() {
  //   console.log('Component Created:', this.$props)
  // },
  mounted() {
    if (this.$props.rootItems) {
      roots = this.$props.rootItems
    }
  },
  methods: {
    async handleAddTask(template_type) {
      console.log(template_type)
      const workorder = this.$route.params.id
      if (template_type !== -1) {
        createItems({
          collection: this.collection || 'Work_order_item',
          items: [
            {
              status: 1,
              label: 'Label',
              workorder: workorder,
              parent: this.parent,
              name: '',
              template_type: template_type,
              created_type: 'user',
              company_id: myCompanyId,
            },
          ],
        }).then(() => {
          if (this.$props.refresh) this.$props.refresh()
        })
      } else {
        const toaster = useToaster()
        toaster.show({
          title: this.$t('Failed'),
          message:
            this.$t(`Record task failed please fill template type`) + '!',
          color: 'failed',
          icon: 'ph:user-circle-fill',
          closable: true,
        })
      }
    },
    handleModalOpen(parent_id) {
      this.selectedItem = -1
      this.isModalOpen = true
      this.parent = parent_id
    },
    handleModalClose() {
      this.isModalOpen = false
      // if (this.selectedItem) {
      //   this.handleAddTask(this.selectedItem)
      // }
    },
    handleChangeRow(row_value) {
      this.selectedItem = row_value
    },
    handleChangeKey() {
      this.key =
        Math.random().toString(36).substring(2) + Date.now().toString(36)
    },

    findParentIndex(tree, parentId) {
      for (let i = 0; i < tree.length; i++) {
        if (tree[i].id === parentId) {
          return i // Parent found at this index
        }

        // Recursively search inside children
        if (tree[i].children && tree[i].children.length > 0) {
          let index = this.findParentIndex(tree[i].children, parentId)
          if (index !== -1) {
            return index // Found in children, return index
          }
        }
      }
      return -1 // Not found
    },
    handleTasksRoot(item) {
      // console.log('localRoot-good', roots)
      // console.log('parentItem', this.$props.parentItem)
      // console.log('item', item)
      let myparent = this.$props.parentItem
      roots.push(item)

      // if (myparent && myparent[0].parent) {
      //   let parentIndex = this.findParentIndex(roots, myparent[0].parent)
      //   console.log('h21')

      //   if (parentIndex !== -1 && parentIndex + 1 < roots.length) {
      //     let temp = roots[parentIndex + 1]
      //     roots[parentIndex + 1] = item
      //     roots[parentIndex] = temp
      //   }
      // }

      // $props.refresh()
    },

    async handleInactiveChilds(item, me) {
      console.log('localRoot-childs', item)

      function updateInactiveItems(item) {
        console.log('updateInactiveItems-childs')

        // Хэрвээ item.id байгаа бол өөрчилнө
        if (item.id) {
          const updateData = {
            collection: this.collection || 'Work_order_item',
            id: item.id,
            item: { active: 0, value: '0' },
          }

          updateItem(updateData).then((res) => {
            console.log('Updated item', item.id, res)
          })
        }

        // Хэрвээ хүүхэдтэй бол дахин дуудаж рекурсивээр явна
        if (item.children && item.children.length > 0) {
          item.children.forEach((child) => {
            updateInactiveItems(child)
          })
        }
      }
      await updateInactiveItems(item)

      // console.log('parentItem', this.$props.parentItem)
      // console.log('item', item)
      // let myparent = this.$props.parentItem

      // if (myparent && myparent[0].parent) {
      //   let parentIndex = this.findParentIndex(roots, myparent[0].parent)
      //   console.log('h21')

      //   if (parentIndex !== -1 && parentIndex + 1 < roots.length) {
      //     let temp = roots[parentIndex + 1]
      //     roots[parentIndex + 1] = item
      //     roots[parentIndex] = temp
      //   }
      // }

      // $props.refresh()
    },
    handleDragStart(evt) {
      // Do something before dragging starts
      // console.log('started:', evt)
      this.draggingItem = evt.item._underlying_vm_.id
    },

    handleDragEnd(evt) {
      // Handle logic after drag ends
      // console.log('event', evt)
      // const draggedItem = evt.item._underlying_vm_

      // // Modify the dragged item values directly after the drag event
      // draggedItem.value = this.getNewValueAfterDrag(draggedItem)
      // draggedItem.name = this.getNewNameAfterDrag(draggedItem)

      // Optionally emit the update event to notify the parent component
      // this.$emit('update:item', draggedItem)
      // console.log('Dragged item updated:', draggedItem)
      // Call the parent's changeFn to update positions

      this.$props.changeFn(evt)

      this.draggingItem = null
      this.targetIndex = null // Reset target index after drag
    },

    handleTasksUpdate(newValue, item, type) {
      if (type == 'checkbox') {
        item.value = newValue.isChecked ? 1 : 0
        item.name = newValue.textInput // or any other value update
      } else {
        if (newValue.valueInput) {
          item.value = newValue.valueInput
        }
        if (newValue.textInput) {
          item.name = newValue.textInput
        }
      }
    },

    // getNewValueAfterDrag(item) {
    //   // Logic to get new value after drag
    //   return item.value + 1 // Example of updating the value after drag
    // },
  },
}
</script>
<template>
  <div>
    <draggable
      class="pt-1 task_container"
      tag="div"
      :list="children"
      :group="{ name: 'children' }"
      @start="handleDragStart"
      @end="handleDragEnd"
      @dragenter="highlight = false"
      @dragleave="highlight = false"
      :class="{ highlight: highlight }"
      :disabled="$props.freeze"
    >
      <div
        v-for="(el, iindex) in children"
        :key="el.id"
        :taskId="el.id"
        v-show="el.active == 1 && el.created_type != 'request_info'"
        class="row"
        :class="[
          el?.deleted ? 'hide' : 'show',
          'task-item',
          {
            dragging: draggingItem === el.id,
          },
          el.created_type == 'request_info' ? 'request_info' : '',
        ]"
      >
        <transition name="fade">
          <BaseCard v-if="!el.deleted" shape="curved" class="p-1 dragArea task">
            <div class="flex w-full items-center gap-2">
              <div>
                <BaseHeading
                  tag="h3"
                  size="sm"
                  weight="medium"
                  class="text-muted-800 dark:text-muted-100"
                >
                  <WorkorderitemCheckbox
                    v-if="el.template_type?.name === 'cmms-checkbox'"
                    @update:value="
                      (newValue) => handleTasksUpdate(newValue, el, 'checkbox')
                    "
                    :value="{
                      isChecked: el.value == 1,
                      textInput: el.name,
                      task: el.id,
                    }"
                    :progress="$props.progress"
                    :freeze="$props.freeze"
                    :collection="$props.collection"
                  />
                  <WorkorderitemEditbox
                    v-if="el.template_type?.name === 'cmms-editbox'"
                    @update:value="
                      (newValue) => handleTasksUpdate(newValue, el, 'editbox')
                    "
                    :value="{
                      textInput: el.name,
                      task: el.id,
                      valueInput: el.value,
                    }"
                    :progress="$props.progress"
                    :freeze="$props.freeze"
                    :collection="$props.collection"
                  />
                  <!-- <WorkorderitemRequest
                    v-if="el.template_type == null"
                    :value="{
                      isChecked: el.value == 1,
                      requestInfo: el.request_info,
                      task: el.id,
                    }"
                    :progress="$props.progress"
                    :freeze="$props.freeze"
                  /> -->
                </BaseHeading>
              </div>
              <div class="ms-auto mr-10 action_bttns">
                <WorkItemDropdown
                  v-if="el.template_type != null"
                  :freeze="$props.freeze"
                  :parent="el.id"
                  :code="el.workorder"
                  :collection="$props.collection"
                  :children="children"
                  :template_type="el.template_type"
                  :template_types="$props.template_types"
                  :item="el.id"
                  :name="el.name"
                  :setSubRow="$props.setSubRow"
                  :addtask="() => handleModalOpen(el.id)"
                  :refresh="
                    (type, item) => {
                      if (type == 'remove') {
                        el.deleted = true
                        el.active = 0
                        handleInactiveChilds(el, el.id)

                        // $props.refresh()
                      }
                      if (type == 'add') {
                        el.children[el.children.length] = item
                        // $props.refresh()
                      }
                      if (type == 'root') {
                        const index = children.findIndex(
                          (child) => child.id === item.id,
                        )

                        if (index !== -1) {
                          children.splice(index, 1)
                          handleTasksRoot(item)
                          // $props.children.push(item)
                        }
                        // $props.refresh()
                      }
                    }
                  "
                />
              </div>
            </div>
          </BaseCard>
        </transition>
        <work-order-item-dynamic-nested
          :children="el.children"
          :parentItem="children"
          class="pl-5"
          :refresh="$props.refresh"
          :changeFn="$props.changeFn"
          :progress="$props.progress"
          :freeze="$props.freeze"
          :template_types="$props.template_types"
          :collection="$props.collection"
        />
      </div>
    </draggable>
  </div>
</template>

<style>
.task_container .row.hide,
.task_container .row.hide .pl-5 {
  display: none;
}
.task_container .row:hover {
  cursor: pointer;
}
.task_container .row .task:hover {
  border-color: #938e8e;
}

.highlight {
  background-color: #93cfb9; /* Green highlight for valid drop zone */
}

.row.dragging {
  background-color: #d8f2e2fc;
  border-radius: 4px;
  padding: 4px;
  cursor: pointer;
}

/* Define the fade-out animation */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s ease;
}
.fade-enter,
.fade-leave-to {
  opacity: 0;
}
</style>
