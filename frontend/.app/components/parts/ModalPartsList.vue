<script setup lang="ts">
import 'v-calendar/dist/style.css'
import { ref } from 'vue'
import { useI18n } from 'vue-i18n'
import '~/assets/css/vcalendar.css'

const user = useDirectusUser()
const { t } = useI18n({ useScope: 'global' })
const { getItems } = useDirectusItems()
const myCompanyId = getMyCompanyId()

const itemsPerPage = ref(25)

const serverItems = ref<any[]>([])
const loading = ref(true)
const totalItems = ref(0)
const refreshKey = ref(0)

const props = defineProps({
  open: Boolean,
  close: Function,
  setPart: Function,
  location: [String, Number],
  module: String,
  index: Number,
  multiSelect: { type: Boolean, default: false },
  setMultipleParts: { type: Function, default: null },
  initialSearch: { type: String, default: '' },
})

const search = ref(props.initialSearch || '')

const selectedItems = ref<any[]>([])
const stateMap = ref<Record<string, string>>({})

const loadStates = async () => {
  try {
    const res = await getItems({
      collection: 'States',
      params: {
        filter: { company_id: { _eq: myCompanyId } },
        fields: ['id', 'name'],
        limit: -1,
      },
    })
    const items = Array.isArray(res) ? res : (res as any)?.data ?? []
    const map: Record<string, string> = {}
    for (const s of items) map[String(s.id)] = s.name || String(s.id)
    stateMap.value = map
  } catch (e) {
    console.warn('Failed to load states:', e)
  }
}
const stateName = (code: any) =>
  code != null ? stateMap.value[String(code)] ?? String(code) : '—'

const getTableHeaders = () => {
  let header: any[] = []

  if (props.module == 'Parts') {
    header = [
      { title: t('Name'), key: 'name', align: 'start', width: '40%' },
      {
        title: t('Supplier'),
        key: 'supplier.name',
        align: 'start',
        width: '30%',
      },
      {
        title: t('Part number'),
        key: 'part_number',
        align: 'start',
        width: '30%',
      },
      { title: t('Action'), key: 'action', align: 'start', sortable: false },
    ]
  }

  if (props.module == 'Work_order') {
    header = [
      { title: t('Name'), key: 'name', align: 'start', width: '40%' },
      {
        title: t('type'),
        key: 'type.name',
        align: 'start',
        width: '30%',
      },
      {
        title: t('Priority'),
        key: 'priority',
        align: 'start',
        width: '30%',
      },
      { title: t('Action'), key: 'action', align: 'start', sortable: false },
    ]
  }

  if (props.module == 'BinnedParts') {
    header = [
      {
        title: t('Part number'),
        key: 'part.part_number',
        align: 'start',
        width: '25%',
      },
      {
        title: t('Bin Location'),
        key: 'bin_location.name',
        align: 'start',
        width: '25%',
      },
      { title: t('State'), key: 'state', align: 'start', width: '20%' },
      { title: t('Available Qty'), key: 'qty', align: 'center', width: '15%' },
      { title: t('Action'), key: 'action', align: 'start', sortable: false },
    ]
  }

  return header
}
const loadItems = async ({ page, itemsPerPage, sortBy }: any) => {
  let sort_array: string[] = []
  ;(sortBy || []).map((sort_object: any) => {
    let sort_direction = sort_object?.order == 'asc' ? '' : '-'
    let sort_key = sort_object?.key
    sort_array.push(sort_direction.concat(sort_key))
  })

  loading.value = true

  try {
    const filters: Record<string, any> = { company_id: myCompanyId }
    console.log('Props', props)
    if (props.module == 'Parts') {
      if (props.location) {
        console.log('Parts_Amounts_filter', {
          location: props.location,
          company_id: myCompanyId,
        })

        const items = await getItems({
          collection: 'Parts_Amounts',
          params: {
            filter: {
              location: props.location,
              company_id: myCompanyId,
            },
            limit: itemsPerPage,
            page: page,
            sort: sort_array,
            meta: 'filter_count',
            search: search.value,
            fields: ['part.*', 'part.supplier.*'],
          },
        })

        serverItems.value = (items.data || [])
          .map((row: any) => row?.part)
          .filter(Boolean)
        totalItems.value = items.meta?.filter_count || serverItems.value.length
        loading.value = false
      } else if (props.asset) {
        console.log('Asset_Parts_filter', props)

        const items = await getItems({
          collection: 'Asset_Parts',
          params: {
            filter: {
              status: '1',
              location: props.location,
              company_id: myCompanyId,
            },
            limit: itemsPerPage,
            page: page,
            sort: sort_array,
            meta: 'filter_count',
            search: search.value,
            fields: ['part.*', 'part.supplier.*'],
          },
        })

        serverItems.value = (items.data || [])
          .map((row: any) => row?.part)
          .filter(Boolean)
        totalItems.value = items.meta?.filter_count || serverItems.value.length
        loading.value = false
      } else {
        // ene deer Asset parts
        const items = await getItems({
          collection: 'Parts',
          params: {
            filter: filters,
            limit: itemsPerPage,
            page: page,
            sort: sort_array,
            meta: 'filter_count',
            search: search.value,
            fields: ['*', 'supplier.*'],
          },
        })

        serverItems.value = items.data
        totalItems.value = items.meta?.filter_count || 0
        loading.value = false
      }
    }

    if (props.module == 'Work_order') {
      const items = await getItems({
        collection: 'Work_order',
        params: {
          filter: filters,
          limit: itemsPerPage,
          page: page,
          sort: sort_array,
          meta: 'filter_count',
          search: search.value,
          fields: ['*', 'asset.*', 'type.*'],
        },
      })

      serverItems.value = items.data
      totalItems.value = items.meta?.filter_count || 0
      loading.value = false

      console.log('items', items)
    }

    if (props.module == 'BinnedParts') {
      const binnedFilter: Record<string, any> = {
        company_id: myCompanyId,
        // Parts_Bin_location.location талбар зарим бичлэг дээр хуучирсан/зөрүүтэй
        // байж болзошгүй тул tuхайн bin-ийн жинхэнэ байршлыг bin_location
        // харилцаагаар (Bin_location.location) шалгана — OutcomeModalForm,
        // WorkPartsAddForm-той ижил конвенц.
        bin_location: { location: { _eq: props.location } },
        status: { _neq: 'archived' },
        qty: { _gt: 0 },
      }
      // Directus-ийн generic `search` нь part.part_number шиг nested
      // талбар дээр ажилладаггүй тул тодорхой filter-ээр хайна
      if (search.value) {
        binnedFilter.part = { part_number: { _icontains: search.value } }
      }

      const items = await getItems({
        collection: 'Parts_Bin_location',
        params: {
          filter: binnedFilter,
          limit: itemsPerPage,
          page: page,
          sort: sort_array,
          meta: 'filter_count',
          fields: [
            'id',
            'qty',
            'bin_location.id',
            'bin_location.name',
            'part.id',
            'part.part_number',
            'part.description',
            'transaction_parts.part_state',
          ],
        },
      })

      serverItems.value = (items.data || []).map((row: any) => ({
        ...row,
        part_state: row.transaction_parts?.part_state ?? null,
      }))
      totalItems.value = items.meta?.filter_count || 0
      loading.value = false
    }
  } catch (e) {}
}

const choose = (item: any) => {
  if (props.setPart) {
    props.setPart(item, props.index)
  }
  if (props.close) {
    props.close()
  }
}

const toggleSelect = (item: any) => {
  const idx = selectedItems.value.findIndex((s) => s.id === item.id)
  if (idx === -1) {
    selectedItems.value.push(item)
  } else {
    selectedItems.value.splice(idx, 1)
  }
}

const isSelected = (item: any) =>
  selectedItems.value.some((s) => s.id === item.id)

const addSelected = () => {
  if (props.setMultipleParts && selectedItems.value.length > 0) {
    props.setMultipleParts(selectedItems.value)
  }
  selectedItems.value = []
  if (props.close) {
    props.close()
  }
}

console.log('module', props.module)

onMounted(() => {
  if (props.module === 'BinnedParts') loadStates()
})
</script>

<template>
  <TairoModal
    :open="props.open"
    :size="'lg'"
    @close="props.close && props.close()"
    :classes="{ wrapper: 'TairoModal' }"
  >
    <template #header>
      <div class="flex w-full items-center justify-between">
        <h3
          class="font-heading text-muted-900 text-lg font-medium leading-6 dark:text-white"
        >
          &nbsp;{{ t(props.module || '') }}
        </h3>
        <BaseButtonClose @click="props.close && props.close()" />
      </div>
    </template>

    <div class="max-h-[580px] overflow-y-auto TairoModalBody">
      <BaseInput
        v-model="search"
        icon="lucide:search"
        :placeholder="$t('Search')"
        :classes="{ wrapper: 'w-full sm:w-auto Search' }"
      />
      <v-data-table-server
        v-model:items-per-page="itemsPerPage"
        :key="refreshKey"
        :headers="getTableHeaders()"
        :items-length="totalItems"
        :items="serverItems"
        :loading="loading"
        :search="search"
        class="elevation-1"
        item-value="name"
        :theme="$colorMode.value"
        @update:options="loadItems"
        :pageText="t('{0}-{1} of {2}', ['{0}', '{1}', '{2}'])"
        :items-per-page-options="[5, 10, 25, 50, 100, -1]"
        :items-per-page-text="t('Item per page')"
        :loading-text="t('loading')"
        :no-data-text="t('No records')"
      >
        <template v-slot:item.children="{ item }">
          <div v-if="item.children && item.children.length > 0">
            <BaseTag
              v-for="tag in item.children"
              :key="tag.id"
              shape="rounded"
              color="warning"
              class="mr-5 my-1"
            >
              {{ tag.name }}
            </BaseTag>
          </div>
        </template>
        <template v-slot:item.state="{ item }">
          {{ stateName(item.part_state) }}
        </template>
        <template v-slot:item.action="{ item }">
          <div v-if="props.multiSelect">
            <button
              type="button"
              class="modal-check-btn"
              :class="{ 'modal-check-btn--active': isSelected(item) }"
              @click="toggleSelect(item)"
            >
              <Icon
                v-if="isSelected(item)"
                name="ph:check-bold"
                class="size-3"
              />
            </button>
          </div>
          <div v-else>
            <BaseButton :class="`Choose`" @click="choose(item)">{{
              t('Choose')
            }}</BaseButton>
          </div>
        </template>
      </v-data-table-server>

      <!-- Multi-select footer -->
      <div v-if="props.multiSelect" class="modal-parts-footer">
        <span class="modal-parts-count">
          {{
            selectedItems.length > 0
              ? `${selectedItems.length}` + ' ' + t('selected')
              : t('Select parts below')
          }}
        </span>
        <BaseButton
          color="primary"
          :disabled="selectedItems.length === 0"
          @click="addSelected"
        >
          <Icon name="ph:plus-bold" class="me-1 size-3" />
          {{
            `${t('Add')}${
              selectedItems.length > 0 ? ` (${selectedItems.length})` : ''
            }`
          }}
        </BaseButton>
      </div>
    </div>
  </TairoModal>
</template>

<style>
.modal-check-btn {
  width: 22px;
  height: 22px;
  border-radius: 5px;
  border: 2px solid #d1d5db;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: border-color 0.15s, background 0.15s;
}
.modal-check-btn--active {
  border-color: #6366f1;
  background: #6366f1;
  color: #fff;
}
.modal-parts-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  border-top: 1px solid #e5e7eb;
  position: sticky;
  bottom: 0;
  background: #fff;
  z-index: 1;
}
.dark .modal-parts-footer {
  background: #18181b;
  border-top-color: #27272a;
}
.modal-parts-count {
  font-size: 13px;
  color: #6b7280;
}
</style>
