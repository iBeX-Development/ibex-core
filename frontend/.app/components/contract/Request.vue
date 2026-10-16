<template>
  <div class="flex items-center space-x-2 py-1 ml-10">
    <!-- <label class="flex items-center space-x-2">
      <input
        type="checkbox"
        class="form-checkbox h-5 w-5 text-indigo-600"
        v-model="isChecked"
        @change="handleChange"
      />
    </label> -->
    <TairoPopover size="sm" placement="bottom-end">
      <span class="text-muted-500 flex items-center requestInfo">
        <div v-html="requestInfo"></div>
      </span>

      <template #content>
        <input
          type="text"
          class="border rounded-md p-2 focus:outline-none focus:border-grey-500 w-full"
          v-model="textInput"
          @input="handleInput"
          placeholder="Request work"
          disabled
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
      default: () => ({
        isChecked: false,
        textInput: '',
        task: 0,
        requestInfo: null,
      }),
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
      isChecked: this.value.isChecked,
      textInput: this.value.textInput,
      requestInfo: this.value.requestInfo,
      task: this.value.task,
      timeout: null,
    }
  },
  methods: {
    handleChange() {
      this.$emit('input', {
        isChecked: this.isChecked,
        textInput: this.textInput,
      })
    },
    handleInput() {
      console.log('Input changed', this.task)
      this.$emit('input', {
        isChecked: this.isChecked,
        textInput: this.textInput,
      })
    },
  },
  watch: {
    textInput: {
      handler(newValue, oldValue) {
        if (newValue !== oldValue) {
          if (this.timeout) {
            clearTimeout(this.timeout)
          }
          this.timeout = setTimeout(() => {
            if (this.freeze == false) {
              const { updateItem } = useDirectusItems()
              const updateData = {
                collection: 'Work_order_item',
                id: this.task,
                item: {
                  name: this.textInput,
                },
              }
              updateItem(updateData)
            }
          }, 500)
        }
      },
    },
    isChecked: {
      handler(newValue, oldValue) {
        if (newValue !== oldValue) {
          if (this.timeout) {
            clearTimeout(this.timeout)
          }
          this.timeout = setTimeout(() => {
            if (this.freeze == false) {
              const { updateItem } = useDirectusItems()
              const updateData = {
                collection: 'Work_order_item',
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

<style scoped>
/* Add your additional styles here if needed */
</style>
