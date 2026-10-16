<script>
import { VueDraggableNext } from 'vue-draggable-next'
import TaskTemplateChooseModalForm from '~/components/form/TaskTemplateChooseModalForm.vue'

export default {
  data() {
    return {
      selectedItem: -1,
      key: -1,
      isModalOpen: false,
      parent: -1,
      localChildren: [],
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
    parentId: {
      required: false,
      default: null,
    },
  },
  components: {
    TaskTemplateChooseModalForm,
    draggable: VueDraggableNext,
  },

  name: 'template-nested-draggable',
  watch: {
    children: {
      immediate: true,
      handler(val) {
        this.localChildren = [...val].sort(
          (a, b) => (a.pos ?? Infinity) - (b.pos ?? Infinity),
        )
      },
    },
  },
  methods: {
    async handleDragChange(event) {
      const { updateItem } = useDirectusItems()

      // Update parent for moved item (cross-list drag)
      if (event.added) {
        await updateItem({
          collection: 'Template_header',
          id: event.added.element.id,
          item: { parent: this.parentId ?? null },
        })
      }

      // Update pos for all items in this level using current localChildren order
      if (event.added || event.moved || event.removed) {
        for (let i = 0; i < this.localChildren.length; i++) {
          await updateItem({
            collection: 'Template_header',
            id: this.localChildren[i].id,
            item: { pos: i + 1, parent: this.parentId ?? null },
          })
        }
      }
      // Do NOT call refresh here — localChildren already reflects new order
    },
    async handleAddTask(template_type) {
      const { createItems } = useDirectusItems()
      const myCompanyId = getMyCompanyId()
      const template = this.$route.params.id
      if (template_type !== -1) {
        createItems({
          collection: 'Template_header',
          items: [
            {
              status: 'published',
              label: 'Label',
              template_type: template_type,
              template: template,
              parent: this.parent,
              help: 'Help',
              data_label: 'Default text',
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
      if (this.selectedItem !== -1) {
        this.handleAddTask(this.selectedItem)
      }
    },
    handleChangeRow(row_value) {
      this.selectedItem = row_value
    },
    handleChangeKey() {
      this.key =
        Math.random().toString(36).substring(2) + Date.now().toString(36)
    },
  },
}
</script>
<template>
  <div>
    <draggable
      class="pt-1"
      tag="div"
      :list="localChildren"
      :group="{ name: 'g1' }"
      @change="handleDragChange"
    >
      <div v-for="el in localChildren" :key="el.id">
        <BaseCard shape="curved" class="p-1 dragArea">
          <div class="flex w-full items-center gap-2">
            <div>
              <BaseHeading
                tag="h3"
                size="sm"
                weight="medium"
                class="text-muted-800 dark:text-muted-100"
              >
                <TaskCheckbox
                  v-if="el.template_type?.name === 'cmms-checkbox'"
                  width="400px"
                  :value="{
                    isChecked: true,
                    textInput: el.data_label,
                    task: el.id,
                  }"
                />
                <TaskEditbox
                  v-if="el.template_type?.name === 'cmms-editbox'"
                  width="220px"
                  :value="{
                    isChecked: true,
                    textInput: el.data_label,
                    task: el.id,
                  }"
                />
              </BaseHeading>
            </div>
            <div class="ms-auto mr-10">
              <TemplateDropdown
                :parent="el.id"
                :refresh="$props.refresh"
                :addtask="() => handleModalOpen(el.id)"
              />
            </div>
          </div>
        </BaseCard>
        <template-nested-draggable
          :children="el.children"
          :parentId="el.id"
          class="pl-5"
          :refresh="$props.refresh"
        />
      </div>
    </draggable>
    <TaskTemplateChooseModalForm
      :key="selectedItem"
      :open="isModalOpen"
      :close="handleModalClose"
      :row="selectedItem"
      :setRow="handleChangeRow"
      :refresh="handleChangeKey"
      size="lg"
      :title="$t('Choose template type')"
    />
  </div>
</template>
