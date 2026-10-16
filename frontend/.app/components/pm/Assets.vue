<script setup lang="ts">
import { ClientSideRowModelModule, ModuleRegistry } from 'ag-grid-community'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { RichSelectModule } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import ModalAssetsList from '~/components/inspection/ModalAssetsList.vue'

const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()

const { updateItem, createItems, deleteItems } = useDirectusItems()
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
  'collection',
  'work_order',
  'location',
  'locationName',
  'freeze',
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
const { getItems } = useDirectusItems()
const { params } = useRoute()
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
    animateRows: false,
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

const getAssetRelation = (data: any) => {
  return data?.assets || data?.asset || {}
}

const columnDefs = ref([
  {
    headerName: '',
    checkboxSelection: true,
    headerCheckboxSelection: true,
    filter: false,
    sortable: false,
    resizable: false,
    width: 52,
    maxWidth: 52,
    pinned: 'left',
  },
  {
    headerName: t('Asset name'),
    field: 'assets.name',
    sortable: true,
    filter: true,
    editable: false,
    valueGetter: (params) => getAssetRelation(params.data)?.name || '',
  },
  {
    headerName: t('Name'),
    field: 'name',
    sortable: true,
    filter: true,
    editable: false,
    valueGetter: (params) =>
      params.data?.name || getAssetRelation(params.data)?.name || '',
  },
  {
    headerName: t('Asset Code'),
    field: 'asset_code',
    sortable: true,
    filter: true,
    editable: false,
    valueGetter: (params) =>
      params.data?.asset_code ||
      getAssetRelation(params.data)?.asset_code ||
      '',
  },
  {
    headerName: t('Manufacturer'),
    field: 'manufacturer.name',
    sortable: true,
    filter: true,
    editable: false,
    valueGetter: (params) => {
      return (
        params.data?.manufacturer?.name ||
        getAssetRelation(params.data)?.manufacturer?.name ||
        ''
      )
    },
  },
  {
    field: 'date_created',
    headerName: t('Created'),
    sortable: true,
    resizable: true,
    editable: false,
    valueGetter: (params) => {
      if (params.data?.date_created) {
        const date = new Date(params.data.date_created)
        const mm = String(date.getMonth() + 1).padStart(2, '0') // Months are zero-based
        const dd = String(date.getDate()).padStart(2, '0')
        const yyyy = date.getFullYear()

        return yyyy + '/' + mm + '/' + dd
      } else {
        return ''
      }
    },
  },
])

const loadItems = async ({ page, itemsPerPage }) => {
  loading.value = true
  try {
    const filters: any = {
      work_order: props.work_order?.id,
    }

    console.log('props.collection', props.collection)

    const publishedCollections = [
      'Work_order_assets',
      'Work_pm_assets',
      'Predictive_assets',
    ]

    if (publishedCollections.includes(String(props.collection).trim())) {
      filters.status = 'published'
    } else {
      filters.status = 1
    }

    const items = await getItems<any>({
      collection: props.collection,
      params: {
        filter: filters,
        limit: itemsPerPage,
        page: page,
        meta: 'filter_count',
        fields: ['*', 'assets.*', 'assets.manufacturer.*', 'work_order.* '],
      },
    })
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

const normalizeSelectedAsset = (selected: any) => {
  // v-data-table return-object can return raw row wrappers in some modes.
  return selected?.raw || selected?.value || selected?.item || selected
}

const setAsset = async (obj: any) => {
  const workOrderId = props.work_order?.id
  if (!workOrderId || !obj) {
    return
  }

  const selectedAssets = Array.isArray(obj) ? obj : [obj]
  const isWorkOrderAssets =
    String(props.collection || '').toLowerCase() === 'work_order_assets'

  let createdCount = 0
  let duplicateCount = 0

  const existingIds = new Set(
    rowData.value
      .map(
        (item: any) =>
          item?.asset?.id || item?.assets?.id || item?.asset || item?.assets,
      )
      .filter(Boolean),
  )

  const rowsToCreate: any[] = []
  const selectedIds = new Set<number | string>()

  try {
    for (const selected of selectedAssets) {
      const normalized = normalizeSelectedAsset(selected)
      const selectedId = normalized?.id

      if (!selectedId) {
        continue
      }

      const exists = existingIds.has(selectedId) || selectedIds.has(selectedId)

      if (exists) {
        duplicateCount += 1
        continue
      }

      rowsToCreate.push({
        work_order: workOrderId,
        assets: selectedId,
        status: 'published',
        company_id: myCompanyId,
      })
      selectedIds.add(selectedId)
    }

    if (rowsToCreate.length > 0) {
      await createItems({
        collection: props.collection,
        items: rowsToCreate,
      })
      createdCount = rowsToCreate.length
    }
  } catch (e) {
    console.log('setAsset create error', e)
    toaster.show({
      title: t('Error'),
      message: t('Failed to add asset'),
      color: 'danger',
      icon: 'mdi:alert',
      closable: true,
    })
    return
  }

  if (createdCount === 0 && duplicateCount > 0) {
    toaster.show({
      title: t('Warning'),
      message: t('Selected assets are already added'),
      color: 'warning',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  if (createdCount === 0 && duplicateCount === 0) {
    toaster.show({
      title: t('Warning'),
      message: t('No valid asset selected'),
      color: 'warning',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  asset.value = Array.isArray(obj) ? obj[0] : obj
  await loadItems({ page: 1, itemsPerPage: -1 })
  handleModalClose()

  if (createdCount > 0) {
    toaster.show({
      title: t('Updated'),
      message:
        duplicateCount > 0
          ? t('Assets added: ') +
            createdCount +
            ', ' +
            t('duplicates skipped: ') +
            duplicateCount
          : t('Asset added successfully!'),
      color: 'success',
      icon: 'ph:user-circle-fill',
      closable: true,
    })
  }
}

const deleteRows = async () => {
  if (!gridApi.value) {
    return
  }

  const sel = gridApi.value.getSelectedRows()

  if (!sel || sel.length === 0) {
    toaster.show({
      title: t('Warning'),
      message: t('Please select at least one asset'),
      color: 'warning',
      icon: 'ph:warning-circle-fill',
      closable: true,
    })
    return
  }

  const ids = sel.map((item) => item.id).filter(Boolean)

  if (ids.length === 0) {
    return
  }

  try {
    await deleteItems({
      collection: props.collection,
      items: ids,
    })

    gridApi.value.applyTransaction({ remove: sel })
    rowData.value = rowData.value.filter((row: any) => !ids.includes(row.id))

    toaster.show({
      title: t('Deleted'),
      message: t('Selected assets deleted successfully'),
      color: 'success',
      icon: 'ph:check-circle-fill',
      closable: true,
    })
  } catch (e) {
    toaster.show({
      title: t('Error'),
      message: t('Failed to delete selected assets'),
      color: 'danger',
      icon: 'mdi:alert',
      closable: true,
    })
  }
}

const saveUser = async (users) => {
  console.log('saveUser', users)
  // isModalMemberOpen.value = false
  // isModalOpen.value = false

  // // Хэрэглэгч тус бүрт createItems дуудаж, амжилттай хариу авсан мөрүүдийг ag-Grid руу нэмнэ
  // const responses = await Promise.all(
  //   users.map(async (user) => {
  //     const insertData = {
  //       work_order: props.work_order?.id,
  //       assets: user.id,
  //     }

  //     const [response] = await createItems({
  //       collection: 'Predictive_assets',
  //       items: [insertData],
  //     })
  //   }),
  // )

  // await loadItems(1, -1)
  // inspection_members.value = users
}

onMounted(async () => {
  await loadItems({ page: 1, itemsPerPage: -1 })
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
          !props.freeze &&
          props.work_order?.completed_at === null &&
          props.work_order?.action_status !== 2
        "
        class="col-span-12 mr-6"
      >
        <BaseButton class="float-right" @click="deleteRows">
          <Icon name="octicon:trash-24" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Asset delete') }}</span>
        </BaseButton>

        <BaseButton class="float-right mr-10" @click="handleModalOpen">
          <Icon name="octicon:tasklist-16" class="-ms-1 h-4 w-4" />
          <span class="text-[11px]">{{ $t('Asset add') }}</span>
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

      <ModalAssetsList
        :open="isModalOpen"
        :close="handleModalClose"
        :setAsset="setAsset"
        :location="props.location"
        :locationName="props.locationName"
        :multiple="true"
      />
    </div>
  </div>
</template>

<style>
.grid_ag_list .edit_duration .ag-header-cell-text {
  color: #04a504;
}
</style>
