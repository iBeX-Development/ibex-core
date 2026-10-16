<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { format } from 'date-fns'
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import ModalAssetUsersList from '~/components/inspection/ModalAssetUsersList.vue'

const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()

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
const { getItems, createItems, deleteItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const props = defineProps(['work_order', 'location', 'active_tab'])
const trade_codes = ref([])
const isModalOpen = ref(false)
const selectedItem = ref(-1)
const selectedRow = ref(-1)
const detailRowAutoHeight = true

const isModalMemberOpen = ref(false)

const loading = ref(true)
const gridApi = ref()
const rowData = ref<any[]>([])
const key = ref<string | number>(1)
const asset = ref({
  id: null,
  name: '',
})
const template = ref({
  id: null,
  name: '',
})
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
  rowSelection: 'multiple' as const,
  groupDefaultExpanded: -1,
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

const columnDefs = computed(() => [
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
    headerName: t('Asset'),
    field: 'asset.name',
    sortable: true,
    filter: true,
    editable: false,
  },
  {
    headerName: t('Code'),
    field: 'asset.asset_code',
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
    valueGetter: (params: any) => {
      if (params.data?.date_created) {
        const date = new Date(params.data.date_created)
        return format(date, 'yyyy-MM-dd HH:mm')
      } else {
        return ''
      }
    },
  },
])

const loadItems = async ({
  page,
  itemsPerPage,
}: {
  page: number
  itemsPerPage: number
}) => {
  loading.value = true

  if (!props.work_order?.id) {
    rowData.value = []
    loading.value = false
    return
  }

  try {
    const filters: any = {
      work_order: props.work_order?.id,
      type: 'user',
      status: '1',
    }

    // if (asset.value?.id) {
    //   filters.asset = asset.value.id
    // }

    console.log('filters_Work_inspection_users', filters)

    const items = await getItems<any>({
      collection: 'Work_inspection_users',
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*', 'user.*', 'asset.*', 'work_order.*'],
      },
    })

    console.log('Work_inspection_users', items)
    rowData.value = items.data || []
    loading.value = false
  } catch (e) {
    rowData.value = []
    loading.value = false
  }
}

const onGridReady = async (grid_params: any) => {
  gridApi.value = grid_params.api
  grid_params.api.sizeColumnsToFit({
    defaultMinWidth: 600,
    columnLimits: [{ key: 'name', minWidth: 100 }],
  }) // Багануудыг дэлгэцэнд тааруулах

  grid_params.api.autoSizeAllColumns()

  // const datasource = createServerSideDatasource()
  // await gridApi.value.setGridOption('serverSideDatasource', datasource)
}

const getRowNodeId = (data: any) => {
  return data.id || Math.random().toString(36).substring(7)
}

const handleModalOpen = () => {
  // if (!asset.value?.id) {
  //   toaster.show({
  //     title: t('Warning'),
  //     message: t('Choose asset first'),
  //     color: 'warning',
  //     icon: 'ph:warning-circle-fill',
  //     closable: true,
  //   })
  //   return
  // }

  selectedItem.value = -1
  isModalOpen.value = true
}

const handleModalClose = () => {
  isModalOpen.value = false
  selectedItem.value = -1
  selectedRow.value = -1
  // console.log(isModalOpen.value)
}

const setAsset = async (obj: any) => {
  asset.value = obj
  handleModalClose()
  await loadItems({ page: 1, itemsPerPage: -1 })
}

const deleteRows = async () => {
  const sel = gridApi.value.getSelectedRows()
  if (sel && sel.length > 0) {
    const ids = sel.map((item: any) => item.id)
    gridApi.value.applyTransaction({ remove: sel })
    await deleteItems({
      collection: 'Work_inspection_users',
      items: ids,
    })
    await loadItems({ page: 1, itemsPerPage: -1 })
  }
}

const saveUser = async (payload: any) => {
  const users = payload?.users || []
  const selectedAsset = payload?.asset

  if (!props.work_order?.id || !selectedAsset?.id || !users?.length) {
    return
  }

  asset.value = selectedAsset

  const existingPairs = new Set(
    rowData.value
      .map(
        (row: any) =>
          `${row?.asset?.id || row?.asset}-${row?.user?.id || row?.user}`,
      )
      .filter((v: string) => !!v),
  )

  const rowsToCreate: any[] = []
  for (const user of users as any[]) {
    const row = {
      work_order: props.work_order.id,
      asset: selectedAsset.id,
      user: user.id,
      status: '1',
      type: 'user',
      company_id: myCompanyId,
    }

    if (!existingPairs.has(`${row.asset}-${row.user}`)) {
      rowsToCreate.push(row)
    }
  }

  if (!rowsToCreate.length) {
    toaster.show({
      title: t('Warning'),
      message: t('Selected users already linked for this asset'),
      color: 'warning',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    handleModalClose()
    return
  }

  await createItems({
    collection: 'Work_inspection_users',
    items: rowsToCreate,
  })

  handleModalClose()
  await loadItems({ page: 1, itemsPerPage: -1 })

  toaster.show({
    title: t('Updated'),
    message: t('Users linked to asset successfully'),
    color: 'success',
    icon: 'ph:check-circle-fill',
    closable: true,
  })
}

onMounted(async () => {
  console.log('inspection.work_order', props.work_order)

  if (props.work_order?.asset?.id) {
    asset.value = props.work_order.asset
  }
  await loadItems({ page: 1, itemsPerPage: -1 })
})

watch(
  () => props.work_order?.id,
  async (id) => {
    if (!id) {
      return
    }

    if (props.work_order?.asset?.id) {
      asset.value = props.work_order.asset
    }

    await loadItems({ page: 1, itemsPerPage: -1 })
  },
)

const getDefaultRow = () => {
  return trade_codes.value
    ? trade_codes.value[0]
    : { id: null, name: '', rate: 0, total: 0 }
}

const refresh = (newData: any) => {
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
          props.work_order?.action_status !== 2 &&
          props.active_tab == 'inspection_templates'
        "
        class="col-span-12 flex justify-end gap-3"
      >
        <BaseButton @click="handleModalOpen" class="mr-6">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Asset add') }}</span>
        </BaseButton>
        <BaseButton @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Asset delete') }}</span>
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

      <ModalAssetUsersList
        :open="isModalOpen"
        :close="handleModalClose"
        :saveUsers="saveUser"
        :location="props.location"
        :currentAsset="asset"
      />
    </div>
  </div>
</template>

<style>
.grid_ag_list .edit_duration .ag-header-cell-text {
  color: #04a504;
}
</style>
