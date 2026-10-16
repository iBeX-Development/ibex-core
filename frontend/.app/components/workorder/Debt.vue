<script setup lang="ts">
import { format } from 'date-fns'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'

const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const props = defineProps({
  work_order: Object,
})

const statuses = [
  { text: t('Active'), value: 1, color: '#4CAF50' },
  { text: t('Approved'), value: 2, color: '#0F87BC' },
  { text: t('Returned'), value: 3, color: '#FF9800' },
]

const itemsPerPage = ref(25)
const getTableHeaders = () => {
  return [
    {
      title: t('Number'),
      key: 'id',
      align: 'start',
      sortable: false,
    },
    {
      title: t('Location'),
      key: 'location.name',
      align: 'start',
      sortable: false,
    },
    {
      title: t('Name'),
      key: 'name',
      align: 'start',
      sortable: false,
    },
    {
      title: t('Approved'),
      key: 'approved_user.first_name',
      align: 'start',
      sortable: false,
    },
    {
      title: t('Transaction date'),
      key: 'transaction_date',
      align: 'start',
      sortable: false,
    },
    {
      title: t('Status'),
      key: 'status',
      align: 'start',
      sortable: false,
      filterable: false,
    },
  ]
}

const search = ref('')
const serverItems = ref([])
const loading = ref(true)
const totalItems = ref(0)

const statusText = (value) => {
  const status = statuses.find((s) => s.value === value)
  return status ? status.text : value
}
const statusColor = (value) => {
  const status = statuses.find((s) => s.value === value)
  return status ? status.color : '#999'
}

const loadItems = async () => {
  loading.value = true
  try {
    const woId = props.work_order?.id
    if (!woId) {
      serverItems.value = []
      totalItems.value = 0
      loading.value = false
      return
    }

    const items = await getItems<any>({
      collection: 'Transaction',
      params: {
        filter: {
          _and: [
            { company_id: { _eq: myCompanyId } },
            {
              transaction_type: 'OUTCOME',
              status: { _in: [2] },
              work_order: woId,
            },
          ],
        },
        meta: 'filter_count',
        sort: ['-transaction_date'],
        fields: ['*', 'location.name', 'approved_user.first_name'],
      },
    })

    serverItems.value = items.data
    totalItems.value = items.meta.filter_count
  } catch (e) {
    console.log(e)
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await loadItems()
})
</script>

<template>
  <div class="relative debt_list min-h-[450px]">
    <div class="grid grid-cols-12 gap-6 wo_debt">
      <div class="col-span-12 debt_table">
        <v-data-table-server
          v-model:items-per-page="itemsPerPage"
          :item-key="'id'"
          :headers="getTableHeaders()"
          :items-length="totalItems"
          :items="serverItems"
          :loading="loading"
          :search="search"
          class="elevation-1 -z-50 rounded"
          style="border-top: 1px solid #d5d5d5"
          :theme="$colorMode.value"
          :pageText="t('{0}-{1} of {2}', ['{0}', '{1}', '{2}'])"
          :items-per-page-options="[
            { value: 10, title: '10' },
            { value: 25, title: '25' },
            { value: 50, title: '50' },
            { value: 100, title: '100' },
            { value: -1, title: t('All') },
          ]"
          :items-per-page-text="t('Item per page')"
          :loading-text="t('loading')"
          :no-data-text="t('No records')"
        >
          <template v-slot:item.transaction_date="{ item }">
            <p class="text-xxs">
              {{
                item.transaction_date
                  ? format(new Date(item.transaction_date), 'yyyy-MM-dd HH:mm')
                  : '-'
              }}
            </p>
          </template>
          <template v-slot:item.status="{ item }">
            <span
              class="debt_status_badge"
              :style="{
                color: statusColor(item.status),
                borderColor: statusColor(item.status),
              }"
            >
              {{ statusText(item.status) }}
            </span>
          </template>
        </v-data-table-server>
      </div>
    </div>
  </div>
</template>

<style>
.debt_table {
  border-radius: 5px;
}
.debt_table .v-table {
  max-width: 100%;
}
.debt_table .v-data-table__thead {
  color: gray;
}
.debt_table .v-data-table {
  margin: auto;
}
.dark .debt_table .v-data-table {
  border-color: #e5e7eb !important;
}
.debt_table .v-table .v-table__wrapper > table > thead > tr > th {
  border-color: gray;
}
.debt_list .v-data-table thead th {
  white-space: nowrap;
}
.debt_list .v-data-table-footer {
  margin-top: 70px;
}
.debt_status_badge {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 12px;
  border: 1.5px solid;
  font-size: 12px;
  font-weight: 500;
}
</style>
