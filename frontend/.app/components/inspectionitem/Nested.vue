<script>
import { VueDraggableNext } from 'vue-draggable-next'
import TaskTemplateChooseModalForm from '~/components/form/TaskTemplateChooseModalForm.vue'
import WorkItemDropdown from './Dropdown.vue'
import ImageViewerModal from '~/components/form/ImageViewerModal.vue'
const config = useRuntimeConfig()
const { createItems, updateItem, getItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
let roots = []
export default {
  data() {
    return {
      key: -1,
      selectedItem: -1,
      selectedPhoto: -1,
      isModalOpen: false,
      isOpenImg: false,
      work: -1,
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
  },
  components: {
    TaskTemplateChooseModalForm,
    draggable: VueDraggableNext,
    WorkItemDropdown,
    ImageViewerModal,
  },
  name: 'work-inspection-item-nested',
  // created() {
  //   console.log('Component Created:', this.$props)
  // },
  mounted() {
    // console.log('Component Created:', this.$props)

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
          collection: 'Work_inspection_item',
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
            collection: 'Work_inspection_item',
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
      const draggedItem = evt.item._underlying_vm_

      // Modify the dragged item values directly after the drag event
      draggedItem.value = this.getNewValueAfterDrag(draggedItem)
      draggedItem.name = this.getNewNameAfterDrag(draggedItem)

      // Optionally emit the update event to notify the parent component
      this.$emit('update:item', draggedItem)
      // console.log('Dragged item updated:', draggedItem)

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

    getNewValueAfterDrag(item) {
      // Logic to get new value after drag
      return item.value + 1 // Example of updating the value after drag
    },

    showImg(file, work) {
      this.work = work
      this.isOpenImg = true
      this.key =
        Math.random().toString(36).substring(2) + Date.now().toString(36)
      this.selectedPhoto = file
    },
    get_content_url(file) {
      if (file && file.type.includes('image')) {
        return `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
      } else {
        return ``
      }
    },
    get_file_type(file) {
      let type = ''

      // console.log('get_file_type', file)
      if (!file) type = false
      else if (file?.type.includes('image')) {
        type = `${config.public.directus.url}assets/${file.id}/${file.filename_disk}`
      } else if (file?.type.includes('video')) {
        type = '/img/icons/files/video.svg'
      } else if (file?.type.includes('doc')) {
        type = '/img/icons/files/doc-2.svg'
      } else if (file?.type.includes('pdf')) {
        type = '/img/icons/files/pdf.svg'
      } else if (file?.type.includes('xlsx')) {
        type = '/img/icons/files/sheet.svg'
      } else if (file?.type.includes('pptx')) {
        type = '/img/icons/files/ppt.svg'
      }

      return type
    },

    closeWindow() {
      this.isModalOpen = false
      this.isOpenImg = false
    },
    async deleteFile(item, work_order) {
      // console.log('Deleting specific file relationship', work_order)

      try {
        const { getItems, deleteItems } = useDirectusItems()

        // Find the exact junction table record for this specific file
        const junctionRecords = await getItems({
          collection: 'Work_inspection_item_directus_files',
          filter: {
            _and: [
              { Work_inspection_item_id: { _eq: work_order.id } },
              { directus_files_id: { _eq: item.id } },
            ],
          },
        })

        // console.log('Found junction records to delete:', junctionRecords)

        if (junctionRecords && junctionRecords.length > 0) {
          // Delete only the specific junction record(s)
          for (const record of junctionRecords) {
            if (record.directus_files_id == item.id) {
              await deleteItems({
                collection: 'Work_inspection_item_directus_files',
                items: [record.id], // Delete one record at a time
              })
              // console.log('Deleted junction record:', record.id)
            }
          }

          // ✅ UI-гаас тухайн файлыг устгах
          const taskIndex = this.$props.children.findIndex(
            (task) => task.id === work_order.id,
          )

          if (taskIndex !== -1) {
            const task = this.$props.children[taskIndex]
            task.photos = task.photos.filter(
              (photo) => photo.directus_files_id.id !== item.id,
            )
            // console.log(`Removed file from task ${work_order.id}`)
          }
          // Хэрэв props refresh функц байгаа бол дуудаж болно
          if (this.$props.refresh) {
            this.$props.refresh()
          }
        } else {
          console.warn('No junction record found for this file')
        }
      } catch (error) {
        console.error('Error deleting specific file relationship:', error)
      }
    },
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
                  <InspectionitemCheckbox
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
                  />
                  <InspectionitemEditbox
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
              <div
                class="action_photos flex flex-row absolute items-center right-[62px]"
              >
                <div
                  v-if="el.photos?.length > 0"
                  v-for="(file, c) in el.photos.slice(0, 5)"
                  :key="c"
                  class="task_image cursor-pointer ml-2"
                  @click="showImg(file.directus_files_id, el)"
                >
                  <img
                    :src="get_file_type(file.directus_files_id)"
                    alt="part"
                  />
                </div>
              </div>
              <div class="ms-auto mr-10 action_bttns">
                <WorkItemDropdown
                  v-if="el.template_type != null"
                  :freeze="$props.freeze"
                  :work_item="el"
                  :parent="el.id"
                  :code="el.workorder"
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
                      if (type == 'file') {
                        //addfiles

                        el.photos = [...el.photos, ...item]
                        $props.refresh()
                        handleChangeKey()
                      }
                    }
                  "
                />
              </div>
            </div>
            <ImageViewerModal
              :work_order="work"
              :itemsValue="selectedPhoto"
              :key="key"
              :open="isOpenImg"
              :close="closeWindow"
              :deleteFile="deleteFile"
              :refresh="$props.refresh"
            />
          </BaseCard>
        </transition>
        <work-inspection-item-nested
          :children="el.children"
          :parentItem="children"
          class="pl-5"
          :refresh="$props.refresh"
          :changeFn="$props.changeFn"
          :progress="$props.progress"
          :freeze="$props.freeze"
          :template_types="$props.template_types"
        />
      </div>
    </draggable>
    <div
      v-if="isOpenImg"
      style="
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.5);
        z-index: 10000;
      "
    ></div>
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

.task_image {
  max-width: 100%;
  max-height: 100px;
  background-color: rgba(201, 201, 201, 0.2);
  border-radius: 8px;
  /* margin: 8px; */
}

.task_image img {
  width: 30px;
  height: 30px;
  border: 1px solid;
  border-radius: 4px;
}
</style>
