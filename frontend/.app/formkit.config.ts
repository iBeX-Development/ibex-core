import { DefaultConfigOptions, createInput } from '@formkit/vue'
import Autocomplete from './components/custom/Autocomplete.vue'
import Autocomplete2 from './components/custom/Autocomplete2.vue'
import OneTimePassword from './components/custom/OneTimePassword.vue'

const config: DefaultConfigOptions = {
  config: {
    rootClasses(sectionKey, node) {
      const type = node.props.type
      const classConfig = {
        outer: 'mb-1 max-w-md',
        legend: 'block mb-1',
        label() {
          if (type === 'radio') {
            return 'text-sm text-gray-600 mt-0.5 nui-label'
          }
          if (type === 'checkbox') {
            return 'text-sm text-gray-600 nui-label mr-5'
          }

          //if (type === 'text') {
          return 'mb-1 nui-label text-sm'
          //}
        },
        options() {
          if (type === 'radio') {
            return 'flex flex-col flex-grow mt-2'
          }
          return 'my-class'
        },
        input() {
          if (type === 'text') {
            return 'nui-focus border-muted-300 text-muted-600 placeholder:text-muted-300 focus:border-muted-300 focus:shadow-muted-300/50 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 dark:placeholder:text-muted-600 dark:focus:border-muted-700 dark:focus:shadow-muted-800/50 peer w-full cursor-pointer appearance-none border font-sans focus:shadow-lg px-2 pe-3 h-12 text-sm leading-5 pe-4 ps-3 rounded'
          }
          if (type === 'select') {
            return 'nui-focus border-muted-300 text-muted-600 placeholder:text-muted-300 focus:border-muted-300 focus:shadow-muted-300/50 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 dark:placeholder:text-muted-600 dark:focus:border-muted-700 dark:focus:shadow-muted-800/50 peer w-full cursor-pointer appearance-none border font-sans focus:shadow-lg px-2 pe-3 h-12 text-sm leading-5 pe-4 ps-3 rounded'
          }
          if (type === 'email') {
            return 'nui-focus border-muted-300 text-muted-600 placeholder:text-muted-300 focus:border-muted-300 focus:shadow-muted-300/50 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 dark:placeholder:text-muted-600 dark:focus:border-muted-700 dark:focus:shadow-muted-800/50 peer w-full cursor-pointer appearance-none border font-sans focus:shadow-lg px-2 pe-3 h-12 text-sm leading-5 pe-4 ps-3 rounded'
          }
          if (type === 'radio') {
            return 'mr-2'
          }
          if (type === 'checkbox') {
            return 'form-checkbox h-5 w-5 text-indigo-600 mr-5 focus:border-muted-300 focus:shadow-muted-300/50 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 dark:placeholder:text-muted-600 dark:focus:border-muted-700 dark:focus:shadow-muted-800/50'
          }
          if (type === 'textarea') {
            return 'px-2 bg-gray-100 border border-gray-300 nui-focus rounded w-full focus:border-muted-300 focus:shadow-muted-300/50 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 dark:placeholder:text-muted-600 dark:focus:border-muted-700 dark:focus:shadow-muted-800/50'
          }

          if (type === 'number') {
            return 'px-2 bg-gray-100 border border-gray-300 nui-focus rounded w-full !h-11 focus:border-muted-300 focus:shadow-muted-300/50 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 dark:placeholder:text-muted-600 dark:focus:border-muted-700 dark:focus:shadow-muted-800/50'
          }

          if (type === 'datetime-local') {
            return 'nui-focus border-muted-300 text-muted-600 placeholder:text-muted-300 focus:border-muted-300 focus:shadow-muted-300/50 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 dark:placeholder:text-muted-600 dark:focus:border-muted-700 dark:focus:shadow-muted-800/50 peer w-full cursor-pointer appearance-none border font-sans focus:shadow-lg px-2 pe-3 h-12 text-sm leading-5 pe-4 ps-3 rounded'
          }
          if (type === 'date') {
            return 'nui-focus border-muted-300 text-muted-600 placeholder:text-muted-300 focus:border-muted-300 focus:shadow-muted-300/50 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 dark:placeholder:text-muted-600 dark:focus:border-muted-700 dark:focus:shadow-muted-800/50 peer w-full cursor-pointer appearance-none border font-sans focus:shadow-lg px-2 pe-3 h-12 text-sm leading-5 pe-4 ps-3 rounded'
          }
          if (type === 'datetime') {
            return 'nui-focus border-muted-300 text-muted-600 placeholder:text-muted-300 focus:border-muted-300 focus:shadow-muted-300/50 dark:border-muted-700 dark:bg-muted-900/75 dark:text-muted-200 dark:placeholder:text-muted-600 dark:focus:border-muted-700 dark:focus:shadow-muted-800/50 peer w-full cursor-pointer appearance-none border font-sans focus:shadow-lg px-2 pe-3 h-12 text-sm leading-5 pe-4 ps-3 rounded'
          }
        },
        wrapper() {
          if (type === 'radio') {
            return 'flex flex-row flex-grow '
          }
          if (type === 'number') {
            return 'nui-input-number-wrapper'
          }
        },
        message: 'text-danger-500 text-xs',
        help: 'text-xs text-gray-300 nui-label',
      }

      function createClassObject(classesArray) {
        if (!classesArray) return ''
        const classList = {}
        classesArray.split(' ').forEach((className) => {
          classList[className] = true
        })
        return classList
      }

      const target = classConfig[sectionKey]
      if (typeof target === 'string') {
        return createClassObject(target)
      } else if (typeof target === 'function') {
        return createClassObject(classConfig[sectionKey]())
      }
    },
  },
  inputs: {
    otp: createInput(OneTimePassword, {
      props: ['digits'],
    }),
    autocomplete: createInput(Autocomplete, {
      props: ['collection_name', 'multiline', 'filter'],
    }),
    autocomplete2: createInput(Autocomplete2, {
      props: [
        'collection_name',
        'multiline',
        'item_title',
        'item_value',
        'search',
        'search_integer',
        'search_field',
        'search_collection',
        'setValue',
        'setEmplyValue',
        'item_index',
        'setParentValue',
        'initial_filter',
        'change_filter',
        'initial_break',
        'item_fields',
        'placeholder',
        'check_field',
        'disabled',
        'selectedItems',
        'option_class',
        'label_extra',
        'placement',
        'no_company_filter',
      ],
    }),
  },
  locale: 'en',
}

export default config
