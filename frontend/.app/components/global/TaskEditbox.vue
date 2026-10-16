<template>
  <div class="flex items-center space-x-2 py-1 ml-10">
    <input
      type="text"
      class="editBox1 border rounded-md pl-2 focus:outline-none focus:border-indigo-500"
      :style="width ? { width } : { width: '200px' }"
      v-model="textInput"
      @input="handleInput"
      placeholder="Task name"
      validation="required"
    />
    <input
      type="text"
      class="editBox2 border rounded-md focus:outline-none focus:border-indigo-500"
      :style="width ? { width } : { width: '180px' }"
      v-model="textInputValue"
      @input="handleInput"
      placeholder="Text"
      validation="required"
    />
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
        textInputValue: '',
      }),
    },
    width: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      isChecked: this.value.isChecked,
      textInput: this.value.textInput,
      textInputValue: this.value.textInputValue,
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
            const { updateItem } = useDirectusItems()
            const updateData = {
              collection: 'Template_header',
              id: this.task,
              item: {
                data_label: this.textInput,
              },
            }
            updateItem(updateData)
          }, 500)
        }
      },
    },
    // deep: true
  },
}
</script>

<style scoped>
/* Add your additional styles here if needed */
</style>
