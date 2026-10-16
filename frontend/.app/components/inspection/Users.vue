<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { format } from 'date-fns'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })

const { params } = useRoute()
const { updateItem, createItems, deleteItems, getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

definePageMeta({
  middleware: ['auth'],
  title: 'Preview asset',
  preview: {
    title: 'Health dashboard',
    description: 'For health and fitness',
    categories: ['dashboards'],
    src: '/img/screens/dashboards-health.png',
    srcDark: '/img/screens/dashboards-health-dark.png',
    order: 17,
  },
})
ModuleRegistry.registerModules([ClientSideRowModelModule, RichSelectModule])

const props = defineProps([
  'estimated_edit',
  'actual_edit',
  'work_order',
  'active_tab',
])
const trade_codes = ref([])
const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selectedRow = ref(-1)
const detailRowAutoHeight = true

const isModalMemberOpen = ref(false)
const inspection_members = ref([])

const loading = ref(true)
const gridApi = ref()
const rowData = ref([])
const key = ref(1)

const autoSizeStrategy = {
  type: 'fitGridWidth',
}

const gridOptions = ref({
  defaultColDef: {
    sortable: true,
    filter: false,
    resizable: true,
    suppressAutoSize: true,
    autoSizeAllColumns: true,
    suppressHeaderMenuButton: true,
    autoSizeStrategy: {
      type: 'fitCellContents',
    },

    // wrapHeaderText: true, // Header name багтахгүй бол багана дотор хугалж бичих
    // autoHeaderHeight: true, // Толгойн өндөр автоматаар тохирох
    flex: 0,
  },
  rowSelection: 'multiple',
  localeText: {
    noRowsToShow: t('No Rows To Show'),
    page: t('Page'),
    to: t('to'),
    of: t('of'),
    pageSizeSelectorLabel: t('Page Size:'),
    sortAscending: t('Sort Ascending'),
    sortDescending: t('Sort Descending'),
    clearColumn: t('Clear Sort'),
    pinColumn: t('Pin Column'),
    pinLeft: t('Pin Left'),
    pinRight: t('Pin Right'),
    noPin: t('No Pin'),
    autosizeThisColumn: t('Autosize This Column'),
    autosizeAllColumns: t('Autosize All Columns'),
    columnChooser: t('Choose Columns'),
    resetColumns: t('Reset Columns'),
    alertButton: t('Click Alert Button and Close Menu'),
  },
  // suppressHorizontalScroll: true, // Хэвтээ scroll идэвхгүй болгох
})

const columnDefs = ref([
  {
    headerName: '',
    checkboxSelection: true,
    headerCheckboxSelection: true,
    width: 40,
  },
  {
    headerName: t('UserName'),
    field: 'user.first_name',
    sortable: true,
    filter: true,
    editable: false,
  },
  {
    headerName: t('lastName'),
    field: 'user.last_name',
    sortable: true,
    filter: true,
    editable: false,
  },
  {
    headerName: t('Created'),
    field: 'date_created',
    sortable: true,
    filter: true,
    editable: false,
    width: 150,
    valueGetter: (params) => {
      if (params.data?.date_created) {
        const date = new Date(params.data.date_created)
        return format(date, 'yyyy-MM-dd HH:mm') // Format the date
      } else {
        return ''
      }
    },
  },
])

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    const filters = {
      status: '1',
      work_order: props.work_order?.id,
      // type: 'generated',
    }
    const items = await getItems<any>({
      collection: 'Work_inspection_users',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*', 'user.*', 'shift_user.*', 'work_order.* '],
      },
    })
    console.log('generated Items: ', items)
    rowData.value = items.data
    loading.value = false
  } catch (e) {}
}

const onGridReady = async (grid_params) => {
  gridApi.value = grid_params.api
  grid_params.api.sizeColumnsToFit({
    defaultMinWidth: 600,
    columnLimits: [{ key: 'name', minWidth: 100 }],
  }) // Багануудыг дэлгэцэнд тааруулах

  grid_params.api.autoSizeAllColumns()

  // const datasource = createServerSideDatasource()
  // await gridApi.value.setGridOption('serverSideDatasource', datasource)
}

const getRowNodeId = (data) => {
  return data.id
}

const handleModalOpen = () => {
  selectedItem.value = -1
  isModalOpen.value = true
}

const handleModalClose = () => {
  isModalOpen.value = false
  selectedItem.value = -1
  selectedRow.value = -1
  // console.log(isModalOpen.value)
}

const deleteRows = async () => {
  const sel = gridApi.value.getSelectedRows()
  if (sel && sel.length > 0) {
    const ids = sel.map((item) => item.id)
    gridApi.value.applyTransaction({ remove: sel })
    // console.log('ids', ids)
    deleteItems({
      collection: 'Work_inspection_users',
      items: ids,
    })
  }
}

const saveUser = async (users) => {
  // console.log('saveUser', users)
  isModalMemberOpen.value = false
  isModalOpen.value = false

  // Хэрэглэгч тус бүрт createItems дуудаж, амжилттай хариу авсан мөрүүдийг ag-Grid руу нэмнэ
  const responses = await Promise.all(
    users.map(async (user) => {
      const insertData = {
        work_order: props.work_order?.id,
        type: 'user',
        user: user.id,
        company_id: myCompanyId,
        user_info: {
          first_name: user.first_name,
          last_name: user.last_name,
        },
      }

      const [response] = await createItems({
        collection: 'Work_inspection_users',
        items: [insertData],
      })
    }),
  )

  await loadItems(1, -1)
  inspection_members.value = users
}

onMounted(async () => {
  await loadItems(1, -1)
  console.log('loadedUsers', props)
})

const getDefaultRow = () => {
  return trade_codes.value
    ? trade_codes.value[0]
    : { id: null, name: '', rate: 0, total: 0 }
}

const refresh = (newData) => {
  gridApi.value.refreshClientSideRowModel()
  // gridApi.value.applyTransaction({ add: [newData] });
}

const handleChangeKey = () => {
  key.value = Math.random().toString(36).substring(2) + Date.now().toString(36)
}
</script>

<template>
  <div class="relative">
    <!-- Grid -->
    <div class="grid grid-cols-12 gap-6">
      <div
        v-if="
          props.work_order?.completed_at === null &&
          props.work_order?.action_status !== 2 &&
          props.active_tab == 'inspection_templates'
        "
        class="col-span-12"
      >
        <BaseButton class="float-right" @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('User delete') }}</span>
        </BaseButton>

        <BaseButton class="float-right mr-10" @click="handleModalOpen">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('User add') }}</span>
        </BaseButton>
      </div>
      <!-- Header -->
      <div class="col-span-12">
        <ag-grid-vue
          :key="key"
          style="width: 100%; height: 560px"
          :class="`ag-theme-quartz${
            $colorMode.value === 'light' ? '' : '-dark'
          } grid_ag_list`"
          :columnDefs="columnDefs"
          :gridOptions="gridOptions"
          :autoSizeStrategy="autoSizeStrategy"
          @grid-ready="onGridReady"
          :rowData="rowData"
        >
        </ag-grid-vue>
      </div>
      <UserCheckList
        collection="Users"
        :open="isModalOpen"
        :close="handleModalClose"
        :saveUser="saveUser"
        :chooseBttn="false"
        :saveBttn="true"
      />
    </div>
  </div>
</template>

<style>
.grid_ag_list .edit_duration .ag-header-cell-text {
  color: #04a504;
}
</style>
