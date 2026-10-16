<script setup>
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'

const { getItems, createItems, updateItem } = useDirectusItems()
const myCompanyId = getMyCompanyId()
const { t } = useI18n({ useScope: 'global' })
const toaster = useToaster()

const props = defineProps({
  open: Boolean,
  close: Function,
  refresh: Function,
  selectedRows: { type: Array, default: () => [] },
  currentLocationId: [String, Number],
})

// Мөр бүр = яг тодорхой ГАНЦ Parts_Bin_location бичлэг (тухайн bin дэх
// тодорхой part+state-ийн үлдэгдэл). Тиймээс row.id = Parts_Bin_location.id.
const targetLocationMap = ref({}) // { [rowId]: { id, name } | null }
const shiftQtyMap = ref({}) // { [rowId]: number }
const saving = ref(false)
const loading = ref(false)

// Bin-level мөрүүд: { id, partId, partNumber, stateId, binLocationId,
// binLocationName, qty }
const allItems = ref([])
// partId → эх Parts_Amounts мөрийн { amountId }
const partAmountMeta = ref({})
const stateMap = ref({})

// Available locations (excluding current)
const locationOptions = ref([])

const loadStates = async () => {
  try {
    const res = await getItems({
      collection: 'States',
      params: {
        filter: { company_id: myCompanyId },
        fields: ['id', 'name'],
        limit: -1,
      },
    })
    const items = Array.isArray(res) ? res : res?.data ?? []
    const map = {}
    for (const s of items) map[String(s.id)] = s.name || String(s.id)
    stateMap.value = map
  } catch (e) {
    console.warn('Failed to load states:', e)
  }
}

const stateName = (code) =>
  code != null ? stateMap.value[String(code)] ?? String(code) : '—'

const isNew = (code) => {
  const label = stateName(code).toLowerCase()
  return label.includes('шинэ') || label.includes('new')
}

const loadLocations = async () => {
  try {
    const res = await getItems({
      collection: 'Location',
      params: {
        filter: { status: { _eq: '1' }, company_id: myCompanyId },
        fields: ['id', 'name'],
        sort: ['name'],
        limit: -1,
      },
    })
    const all = Array.isArray(res) ? res : res?.data ?? []
    locationOptions.value = all.filter(
      (l) => String(l.id) !== String(props.currentLocationId),
    )
  } catch (e) {
    console.warn('Failed to load locations:', e)
  }
}

// Эх байршилд тухайн part-уудыг барьж буй bin бичлэг бүрийг (тус бүрийг
// тусад нь мөр болгож) ачаална — ингэснээр хэрэглэгч яг АЛЬ bin-ээс
// шилжүүлэхээ өөрөө сонгоно (автомат FIFO биш)
const loadStock = async () => {
  allItems.value = []
  partAmountMeta.value = {}

  for (const r of props.selectedRows) {
    const partId = r.part?.id
    if (partId == null) continue
    partAmountMeta.value[partId] = { amountId: r.id }
  }

  const partIds = props.selectedRows.map((r) => r.part?.id).filter(Boolean)
  if (!partIds.length) return

  try {
    const binRes = await getItems({
      collection: 'Parts_Bin_location',
      params: {
        filter: {
          company_id: myCompanyId,
          part: { _in: partIds },
          location: { _eq: props.currentLocationId },
          status: { _neq: 'archived' },
          qty: { _gt: 0 },
        },
        fields: [
          'id',
          'qty',
          'part.id',
          'part.part_number',
          'bin_location.id',
          'bin_location.name',
          'transaction_parts.part_state',
        ],
        sort: ['part.part_number'],
        limit: -1,
      },
    })
    const binList = Array.isArray(binRes) ? binRes : binRes?.data ?? []
    allItems.value = binList
      .map((b) => ({
        id: b.id,
        partId: b.part?.id,
        partNumber: b.part?.part_number ?? '—',
        stateId: b.transaction_parts?.part_state ?? null,
        binLocationId: b.bin_location?.id ?? null,
        binLocationName: b.bin_location?.name ?? '—',
        qty: Number(b.qty) || 0,
      }))
      .sort((a, b) => String(a.partNumber).localeCompare(String(b.partNumber)))
  } catch (e) {
    console.warn('Failed to load bin stock:', e)
  }
}

// Count rows that have both a target location AND qty > 0
const shiftCount = computed(
  () =>
    allItems.value.filter(
      (r) =>
        targetLocationMap.value[r.id]?.id != null &&
        Number(shiftQtyMap.value[r.id] ?? 0) > 0,
    ).length,
)

watch(
  () => props.open,
  async (val) => {
    if (!val) return
    targetLocationMap.value = {}
    shiftQtyMap.value = {}
    loading.value = true
    await Promise.all([loadStates(), loadLocations(), loadStock()])
    loading.value = false
  },
)

const handleShift = async () => {
  const toProcess = allItems.value.filter(
    (r) =>
      targetLocationMap.value[r.id]?.id != null &&
      Number(shiftQtyMap.value[r.id] ?? 0) > 0,
  )
  if (!toProcess.length) {
    toaster.show({
      title: t('Warning'),
      message: t(
        'Please set target location and quantity for at least one part',
      ),
      color: 'warning',
      icon: 'ph:warning-circle',
      closable: true,
    })
    return
  }

  // Validate: shift qty must not exceed this specific bin's available qty
  const overStock = toProcess.find(
    (r) => Number(shiftQtyMap.value[r.id]) > Number(r.qty),
  )
  if (overStock) {
    toaster.show({
      title: t('Warning'),
      message:
        `${overStock.partNumber}: ` +
        t('Shift quantity cannot exceed available stock') +
        ` (${overStock.qty})`,
      color: 'warning',
      icon: 'ph:warning-circle',
      closable: true,
    })
    return
  }

  saving.value = true
  try {
    // ── Сонгосон bin бичлэгийг яг тодорхой хасна (FIFO таамаглал шаардлагагүй,
    // учир нь мөр бүр аль хэдийн ГАНЦ bin-тэй тохирдог) ──
    for (const row of toProcess) {
      const qty = Number(shiftQtyMap.value[row.id])
      await updateItem({
        collection: 'Parts_Bin_location',
        id: row.id,
        item: { qty: Math.max(0, row.qty - qty) },
      })
    }

    // income_amount/outcome_amount цаашид Parts_Amounts дээр cache хийгддэггүй
    // (parts/location жагсаалт дээр Transaction_parts+Parts_shift_history-аас
    // live тооцогддог) тул эх байршлын Parts_Amounts-ийг шинэчлэх шаардлагагүй.
    // Харин зорилтот байршилд энэ part-ын Parts_Amounts мөр огт байхгүй бол
    // жагсаалтад харагдахын тулд зөвхөн бүртгэлийн мөрийг үүсгэнэ — тоо
    // хадгалахгүй, учир нь шилжсэн хэсэг тухайн газартаа UNBINNED (тавиурт
    // байрлуулаагүй) орлого мэт орж ирнэ, дараа нь SetBinLocationModal-оор
    // гараар байрлуулна.
    const targetAdd = {} // `${toLoc}_${partId}` -> { toLoc, partId }
    for (const row of toProcess) {
      const toLocId = targetLocationMap.value[row.id].id
      const tKey = `${toLocId}_${row.partId}`
      targetAdd[tKey] = { toLoc: toLocId, partId: row.partId }
    }
    const targetPartIds = [
      ...new Set(Object.values(targetAdd).map(({ partId }) => partId)),
    ]
    if (targetPartIds.length) {
      const existRes = await getItems({
        collection: 'Parts_Amounts',
        params: {
          filter: {
            part: { _in: targetPartIds },
            location: { _in: Object.values(targetAdd).map((t) => t.toLoc) },
          },
          fields: ['part', 'location'],
          limit: -1,
        },
      })
      const existList = Array.isArray(existRes)
        ? existRes
        : existRes?.data ?? []
      const existKeys = new Set(
        existList.map((r) => {
          const pid = typeof r.part === 'object' ? r.part?.id : r.part
          const lid =
            typeof r.location === 'object' ? r.location?.id : r.location
          return `${lid}_${pid}`
        }),
      )
      for (const { toLoc, partId } of Object.values(targetAdd)) {
        if (existKeys.has(`${toLoc}_${partId}`)) continue
        await createItems({
          collection: 'Parts_Amounts',
          items: [{ part: partId, location: toLoc, company_id: myCompanyId }],
        })
      }
    }

    // ── Log shift history per bin row ──
    for (const row of toProcess) {
      const qty = Number(shiftQtyMap.value[row.id])
      const toLocId = targetLocationMap.value[row.id].id
      await createItems({
        collection: 'Parts_shift_history',
        items: [
          {
            parts_amounts: partAmountMeta.value[row.partId]?.amountId,
            part: row.partId,
            part_state: row.stateId,
            from_location: props.currentLocationId,
            to_location: toLocId,
            qty,
            company_id: myCompanyId,
          },
        ],
      })
    }

    toaster.show({
      title: t('Success'),
      message: `${toProcess.length} ` + t('part(s) shifted successfully') + '!',
      color: 'success',
      icon: 'ph:check-circle',
      closable: true,
    })
    props.refresh?.()
    props.close?.()
  } catch (e) {
    toaster.show({
      title: t('Error'),
      message: String(e),
      color: 'danger',
      closable: true,
    })
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <TairoModal :open="open" size="3xl" @close="close">
    <template #header>
      <div class="flex items-center gap-2">
        <Icon name="octicon:arrow-right-16" class="h-5 w-5 text-primary-500" />
        <h3
          class="font-heading text-lg font-medium leading-6 text-muted-900 dark:text-white"
        >
          {{ $t('Shift Location') }}
        </h3>
      </div>
    </template>

    <div class="p-4 h-[400px]">
      <div v-if="loading" class="flex items-center justify-center py-10">
        <Icon
          name="mdi:loading"
          class="h-7 w-7 animate-spin text-primary-500"
        />
      </div>
      <!-- Parts table -->
      <div
        v-else
        class="rounded-lg border border-muted-200 dark:border-muted-700"
      >
        <table class="w-full text-sm">
          <thead class="sticky top-0 bg-muted-100 dark:bg-muted-800 z-10">
            <tr>
              <th
                class="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-500 w-32"
              >
                {{ $t('Part Number') }}
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-500 w-28"
              >
                {{ $t('State') }}
              </th>
              <th
                class="px-3 py-2 text-center text-xs font-semibold uppercase text-muted-500 w-20"
              >
                {{ $t('Qty') }}
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-500 w-32"
              >
                {{ $t('Bin Location') }}
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-500"
              >
                {{ $t('Target Location') }}
              </th>
              <th
                class="px-3 py-2 text-center text-xs font-semibold uppercase text-muted-500 w-28"
              >
                {{ $t('Shift Qty') }}
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="row in allItems"
              :key="row.id"
              class="border-t border-muted-200 dark:border-muted-700"
              :class="
                targetLocationMap[row.id]?.id &&
                Number(shiftQtyMap[row.id] ?? 0) > 0
                  ? 'bg-primary-50/50 dark:bg-primary-900/10'
                  : ''
              "
            >
              <!-- Part Number -->
              <td
                class="px-3 py-2 font-medium text-muted-800 dark:text-muted-200"
              >
                {{ row.partNumber }}
              </td>

              <!-- State -->
              <td class="px-3 py-2">
                <span
                  class="rounded px-2 py-0.5 text-xs font-medium"
                  :class="
                    isNew(row.stateId)
                      ? 'bg-success-100 text-success-700 dark:bg-success-900/30 dark:text-success-400'
                      : 'bg-muted-100 text-muted-600 dark:bg-muted-700 dark:text-muted-300'
                  "
                >
                  {{ stateName(row.stateId) }}
                </span>
              </td>

              <!-- Qty (available in this bin) -->
              <td class="px-3 py-2 text-center">
                <span class="font-bold text-primary-600">{{ row.qty }}</span>
              </td>

              <!-- Bin Location (source — уншихад л, солигдохгүй) -->
              <td class="px-3 py-2 text-muted-600 dark:text-muted-300">
                {{ row.binLocationName }}
              </td>

              <!-- Target Location -->
              <td class="px-2 py-1.5">
                <v-select-dropdown
                  v-model="targetLocationMap[row.id]"
                  :options="locationOptions"
                  label="name"
                  :reduce="(l) => l"
                  :clearable="true"
                  :placeholder="$t('Select location')"
                  :disabled="row.qty <= 0"
                  :class="`${$colorMode.value} style-chooser`"
                />
              </td>

              <!-- Shift Qty -->
              <td class="px-3 py-1.5 text-center">
                <input
                  v-model.number="shiftQtyMap[row.id]"
                  type="number"
                  :min="1"
                  :max="row.qty"
                  :placeholder="String(row.qty)"
                  :disabled="row.qty <= 0 || !targetLocationMap[row.id]?.id"
                  class="w-24 rounded border border-muted-300 bg-white px-2 py-1 text-center text-xs text-muted-800 focus:outline-none focus:ring-1 focus:ring-primary-500 disabled:opacity-40 dark:border-muted-600 dark:bg-muted-900 dark:text-muted-200"
                />
              </td>
            </tr>
            <tr v-if="!allItems.length">
              <td colspan="6" class="px-3 py-8 text-center text-muted-400">
                {{ $t('No parts selected') }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <template #footer>
      <div class="flex w-full items-center justify-end gap-2 p-4">
        <BaseButton @click="close" color="default" size="sm">
          {{ $t('Cancel') }}
        </BaseButton>
        <BaseButton
          @click="handleShift"
          color="primary"
          size="sm"
          :loading="saving"
          :disabled="shiftCount === 0"
        >
          <Icon name="octicon:arrow-right-16" class="-ms-1 h-4 w-4" />
          {{ $t('Shift') }}
          <span v-if="shiftCount" class="ms-1 opacity-75"
            >({{ shiftCount }})</span
          >
        </BaseButton>
      </div>
    </template>
  </TairoModal>
</template>

<style scoped>
/* Custom CSS for vue-select */
.vs__dropdown-menu {
  z-index: 9999 !important;
}
</style>
