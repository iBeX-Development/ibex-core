<script setup lang="ts">
import type { ColDef } from 'ag-grid-enterprise'
import { AgGridVue } from 'ag-grid-vue3'
import 'ag-grid-community/styles/ag-grid.css'
import 'ag-grid-community/styles/ag-theme-quartz.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { fetchPageData } from '~/components/ag_grid/ag_grid_directus'
import MoreActionCellRenderer from '~/components/ag_grid/MoreActionCellRenderer.vue'

definePageMeta({
  title: 'My Equipments',
})

const { t } = useI18n({ useScope: 'global' })
const { open } = usePanels()
const myId = window.localStorage.getItem('myId')

const gridApi = ref(null)
const dataSource = ref({})
const quickFilterText = ref('')
const paginationPageSize = ref(10)
const windowHeight = ref(560)

const refreshGrid = () => {
  gridApi.value?.refreshServerSide()
  gridApi.value?.onFilterChanged()
}

const onMoreClick = (item) => {
  open('asset', {
    id: item.id,
    data: item,
    refresh: refreshGrid,
  })
}

const statusFormatter = ({ value }) => {
  return value == 1 || value == '1' ? t('Enabled') : t('Disabled')
}

const columnDefs: ColDef[] = ref([
  {
    field: 'asset_code',
    headerName: t('Asset Code'),
    sortable: true,
    filter: false,
    onCellClicked: (params) => onMoreClick(params.data),
  },
  {
    field: 'name',
    headerName: t('Name'),
    sortable: true,
    filter: false,
  },
  {
    field: 'location.name',
    headerName: t('Location'),
    sortable: false,
    filter: false,
  },
  {
    field: 'department.name',
    headerName: t('Department'),
    sortable: false,
    filter: false,
  },
  {
    field: 'status',
    headerName: t('Status'),
    sortable: false,
    filter: false,
    valueFormatter: statusFormatter,
  },
  {
    field: 'actions',
    headerName: t('Actions'),
    width: 120,
    sortable: false,
    filter: false,
    pinned: 'right',
    cellRenderer: MoreActionCellRenderer,
    cellRendererParams: {
      onMoreClick: onMoreClick,
    },
    cellClass: 'actions-cell',
  },
])

const gridOptions = {
  rowModelType: 'serverSide',
  paginationPageSize: 10,
  cacheBlockSize: 10,
  pagination: true,
  paginationPageSizeSelector: [10, 20, 30, 50, 70, 100],
  serverSideDatasource: dataSource.value,
  localeText: {
    noRowsToShow: t('No Rows To Show'),
    page: t('Page'),
    to: t('to'),
    of: t('of'),
    pageSizeSelectorLabel: t('Page Size:'),
    sortAscending: t('Sort Ascending'),
    sortDescending: t('Sort Descending'),
  },
  defaultColDef: {
    flex: 1,
  },
  onPaginationChanged: (params) => {
    changePaginationSize(params.api.paginationGetPageSize())
  },
}

const changePaginationSize = (newSize) => {
  paginationPageSize.value = newSize
  gridOptions.cacheBlockSize = newSize
  gridOptions.paginationPageSize = newSize

  if (gridApi.value) {
    gridApi.value.setGridOption('cacheBlockSize', newSize)
    gridApi.value.setGridOption('paginationPageSize', newSize)
  }
}

const onGridReady = (params) => {
  gridApi.value = params.api

  dataSource.value = {
    getRows: async (params) => {
      const { startRow, sortModel } = params.request
      const sortField = sortModel.length ? sortModel[0].colId : null
      const sortOrder = sortModel.length ? sortModel[0].sort : null

      try {
        const result = await fetchPageData({
          currentPage: Math.floor(startRow / paginationPageSize.value) + 1,
          pageSize: paginationPageSize.value,
          sortField,
          sortOrder,
          search: quickFilterText.value,
          searchField: 'asset_code,name',
          collection: 'Assets',
          filters: {
            assigned_user: { _eq: myId },
            status: { _eq: '1' },
          },
          fields: [
            'id',
            'asset_code',
            'name',
            'status',
            'location.name',
            'department.name',
          ],
        })

        params.success({
          rowData: result.data,
          rowCount: result.totalCount,
        })

        if (result.totalCount === 0) params.api.showNoRowsOverlay()
        else params.api.hideOverlay()
      } catch (e) {
        console.error('Error fetching my equipments:', e)
        params.fail()
      }
    },
  }

  params.api.setGridOption('serverSideDatasource', dataSource.value)
}

const onFilterTextBoxChanged = ({ target: { value } }) => {
  setTimeout(() => {
    quickFilterText.value = value
    refreshGrid()
  }, 300)
}
</script>

<template>
  <div class="my_equipments pb-20 mt-[60px]">
    <TairoContentWrapper>
      <template #left>
        <BaseInput
          icon="lucide:search"
          :placeholder="t('Search')"
          :classes="{ wrapper: 'w-[340px]' }"
          @input="onFilterTextBoxChanged"
        />
      </template>
    </TairoContentWrapper>

    <ag-grid-vue
      :style="{ width: '100%', height: windowHeight + 'px' }"
      :class="`ag-theme-quartz${
        $colorMode.value === 'light' ? '' : '-dark'
      } grid_ag_list`"
      :columnDefs="columnDefs"
      :gridOptions="gridOptions"
      @grid-ready="onGridReady"
    >
    </ag-grid-vue>
  </div>
</template>

<style>
.my_equipments .grid_ag_list {
  min-height: 560px !important;
}
.my_equipments .ag-row .actions-cell {
  overflow: visible;
}
</style>
