<template>
  <div class="checkBoxItem flex items-center space-x-2 py-1 ml-10">
    <label class="flex items-center space-x-2">
      <input
        type="checkbox"
        class="form-checkbox h-5 w-5 text-indigo-600"
        v-model="isChecked"
        :disabled="this.$props.freeze"
        @change="handleChange"
        @blur="handleBlur"
        :task="task"
        itemtype="task_value"
        template="itemcheckbox"
      />
    </label>
    <TairoPopover size="sm" placement="bottom-end">
      <span class="text-muted-500 flex items-center">
        <span class="font-sans text-sm" v-if="textInput !== ''">{{
          textInput
        }}</span>
        <span
          class="font-sans text-sm"
          v-if="textInput === null || textInput === ''"
          >Empty label</span
        >
        <Icon
          v-if="this.$props.freeze === false"
          name="material-symbols:edit-outline"
          class="me-1 size-4 ml-2"
        />
      </span>

      <template #content>
        <textarea
          type="text"
          :disabled="this.$props.freeze"
          class="resizable-textarea border rounded-md p-2 focus:outline-none focus:border-grey-500 w-full"
          v-model="textInput"
          @input="handleInput"
          @blur="handleInputBlur"
          placeholder="Here task name"
          :task="task"
          itemtype="task_name"
          template="itemcheckbox"
        />
      </template>
    </TairoPopover>
  </div>
</template>

<script>
export default {
  props: {
    value: {
      type: Object,
      default: () => ({ isChecked: false, textInput: '', task: 0 }),
    },
    progress: {
      required: false,
      type: Function,
    },
    freeze: {
      required: false,
      type: Boolean,
    },
    collection: {
      required: false,
      type: String,
      default: 'Work_order_item',
    },
  },
  data() {
    return {
      isChecked: this.value.isChecked,
      textInput: this.value.textInput,
      task: this.value.task,
      timeout: null,
    }
  },
  methods: {
    handleChange() {
      this.$emit('update:value', {
        isChecked: this.isChecked,
        textInput: this.textInput,
        task: this.task,
      })
    },
    handleBlur() {},
    handleInput() {
      this.$emit('update:value', {
        isChecked: this.isChecked,
        textInput: this.textInput,
        task: this.task,
      })
    },
    handleInputBlur() {
      console.log('okk')
      if (this.$props.freeze == false) {
        const { updateItem } = useDirectusItems()
        const updateData = {
          collection: this.$props.collection || 'Work_order_item',
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
    textInput: {
      handler(newValue, oldValue) {
        // console.log(newValue, oldValue)
      },
    },
    isChecked: {
      handler(newValue, oldValue) {
        if (newValue !== oldValue) {
          if (this.timeout) {
            clearTimeout(this.timeout)
          }
          this.timeout = setTimeout(() => {
            if (this.$props.freeze == false) {
              const { updateItem } = useDirectusItems()
              const updateData = {
                collection: this.$props.collection || 'Work_order_item',
                id: this.task,
                item: {
                  value: this.isChecked ? 1 : 0,
                },
              }

              updateItem(updateData).then((data) => {
                if (this.$props.progress) {
                  this.$props.progress()
                }
              })
            }
          }, 500)
        }
      },
    },
    //deep: true
  },
}
</script>

<style>
.checkBoxItem .popover {
  border: none;
  line-height: 0.8;
}

.checkBoxItem .after\:content-\[\'\'\]::after {
  border-color: #868181;
}
.checkBoxItem .resizable-textarea {
  width: 100%; /* Өргөнийг 100% болгож болно */
  min-width: 250px; /* Хамгийн бага өргөн */
  max-width: 600px; /* Хамгийн их өргөн */
  resize: horizontal; /* Зөвхөн өргөнөөр өөрчлөх */
  line-height: 1;
  border: 1px solid #9c9999;
}
</style>
