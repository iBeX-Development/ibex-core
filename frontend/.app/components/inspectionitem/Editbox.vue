<template>
  <div class="flex items-center space-x-2 py-1 ml-10">
    <TairoPopover size="sm" placement="bottom-end">
      <span class="text-muted-500 flex items-center">
        <Icon name="material-symbols:edit-outline" class="me-1 size-4" />
        <span class="font-sans text-sm" v-if="textInput !== ''">{{
          textInput
        }}</span>
        <span
          class="font-sans text-sm"
          v-if="textInput === null || textInput === ''"
          >Empty label</span
        >
      </span>

      <template #content>
        <input
          type="text"
          class="border rounded-md p-2 focus:outline-none focus:border-grey-300 w-full"
          v-model="textInput"
          @input="handleTextInput"
          @blur="handleTextBlur"
          :disabled="this.$props.freeze"
          :task="task"
          itemtype="task_name"
          template="itemeditbox"
          placeholder="Here task name"
        />
      </template>
    </TairoPopover>
    <input
      type="text"
      class="border rounded-md pl-2 focus:outline-none focus:border-indigo-500"
      v-model="valueInput"
      @input="handleValueChange"
      @blur="handleValueBlur"
      :disabled="this.$props.freeze"
      :task="task"
      itemtype="task_value"
      template="itemeditbox"
      placeholder="Here task value"
    />
  </div>
</template>

<script>
const { updateItem } = useDirectusItems()

export default {
  props: {
    value: {
      type: Object,
      default: () => ({ textInput: '', valueInput: '', task: 0 }),
    },
    progress: {
      required: false,
      type: Function,
    },
    freeze: {
      required: false,
      type: Boolean,
    },
  },
  data() {
    return {
      textInput: this.value.textInput,
      valueInput: this.value.valueInput,
      task: this.value.task,
      timeout: null,
    }
  },
  methods: {
    handleValueChange() {
      // this.$emit('input', { valueInput: this.valueInput })
      this.$emit('update:value', {
        valueInput: this.valueInput,
      })
    },
    handleValueBlur() {
      if (this.$props.freeze == false) {
        const updateData = {
          collection: 'Work_inspection_item',
          id: this.task,
          item: {
            value: this.valueInput,
          },
        }
        updateItem(updateData).then((data) => {
          if (this.$props.progress) {
            this.$props.progress()
          }
        })
      }
    },
    handleTextInput() {
      // this.$emit('input', { textInput: this.textInput })
      this.$emit('update:value', {
        textInput: this.textInput,
      })
    },
    handleTextBlur() {
      if (this.$props.freeze == false) {
        const updateData = {
          collection: 'Work_inspection_item',
          id: this.task,
          item: {
            name: this.textInput,
          },
        }
        updateItem(updateData)
      }
    },
  },
  watch: {
    valueInput: {
      handler(newValue, oldValue) {
        // if (newValue !== oldValue) {
        //   if (this.timeout) {
        //     clearTimeout(this.timeout)
        //   }
        //   this.timeout = setTimeout(() => {
        //     if (this.$props.freeze == false) {
        //       const { updateItem } = useDirectusItems()
        //       const updateData = {
        //         collection: 'Work_inspection_item',
        //         id: this.task,
        //         item: {
        //           value: this.valueInput,
        //         },
        //       }
        //       console.log('valueInput_updated', this.valueInput)
        //       updateItem(updateData).then((data) => {
        //         // if (this.this.$props.progress) {
        //         //   this.this.$props.progress()
        //         // }
        //       })
        //     }
        //   }, 500)
        // }
      },
    },
    textInput: {
      handler(newValue, oldValue) {
        // if (newValue !== oldValue) {
        //   if (this.timeout) {
        //     clearTimeout(this.timeout)
        //   }
        //   this.timeout = setTimeout(() => {
        //     const { updateItem } = useDirectusItems()
        //     if (this.$props.freeze == false) {
        //       const updateData = {
        //         collection: 'Work_inspection_item',
        //         id: this.task,
        //         item: {
        //           name: this.textInput,
        //         },
        //       }
        //       console.log('textInput_updated', this.textInput)
        //       updateItem(updateData)
        //     }
        //   }, 500)
        // }
      },
    },
    //deep: true
  },
}
</script>

<style scoped>
/* Add your additional styles here if needed */
</style>
