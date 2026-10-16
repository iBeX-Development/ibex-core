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
  locationId: Number,
})

const binLocations = ref([])
const stateMap = ref({})
const activeTab = ref('assign')
const tabs = [
  { label: t('Assign'), value: 'assign' },
  { label: t('Placed items'), value: 'placed' },
]

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
    const items = Array.isArray(res) ? res : res?.data ?? []
    const map = {}
    for (const s of items) map[String(s.id)] = s.name || String(s.id)
    stateMap.value = map
  } catch (e) {
    console.warn('Failed to load states:', e)
  }
}

// allItems: aggregated stock rows { id (synthetic), partId, partNumber, stateId, qty (remaining), latestIncomeTpId }
const allItems = ref([])
// binRows: { [rowId]: [{ bin_location, qty }, ...] } — нэг part/state дээр олон
// bin location + тоо ширхэг хос зэрэг зааж болно
const binRows = ref({})
// existingAssignments: { [rowId]: [{ id, qty, bin_location }, ...] }
const existingAssignments = ref({})
// placedItems: аль хэдийн bin-д байрлуулсан бичлэгүүд (солих/шилжүүлэх зориулалттай)
const placedItems = ref([])
const selectedForSwap = ref([])
const swapping = ref(false)
const movingId = ref(null)
const loading = ref(false)
const saving = ref(false)

watch(
  () => props.open,
  async (val) => {
    if (!val) return
    loading.value = true
    activeTab.value = 'assign'
    allItems.value = []
    binRows.value = {}
    existingAssignments.value = {}
    placedItems.value = []
    selectedForSwap.value = []
    await loadStates()

    const partIds = props.selectedRows.map((r) => r.part?.id).filter(Boolean)
    if (!partIds.length) {
      loading.value = false
      return
    }

    // ── 1. Load ALL approved Transaction_parts for these parts at this location ──
    try {
      const tpRes = await getItems({
        collection: 'Transaction_parts',
        params: {
          filter: {
            company_id: { _eq: myCompanyId },
            part: { _in: partIds },
            transaction_id: {
              location: { _eq: props.locationId },
              status: { _eq: 2 },
            },
          },
          fields: [
            'id',
            'qty',
            'part_state',
            'transaction_type',
            'part.id',
            'part.part_number',
            'transaction_id.transaction_date',
          ],
          sort: ['transaction_id.transaction_date'],
          limit: -1,
        },
      })
      const tpList = Array.isArray(tpRes) ? tpRes : tpRes?.data ?? []

      // ── 2. Aggregate by (part, state) → remaining stock ──
      const stockMap = {}
      for (const tp of tpList) {
        const partId = tp.part?.id
        const stateId = tp.part_state ?? null
        const key = `${partId}_${stateId ?? 'null'}`
        if (!stockMap[key]) {
          stockMap[key] = {
            id: key,
            partId,
            partNumber: tp.part?.part_number ?? '—',
            stateId,
            income: 0,
            outcome: 0,
            latestIncomeTpId: null,
          }
        }
        const qty = parseInt(tp.qty) || 0
        const isIncome =
          tp.transaction_type === 'income' || tp.transaction_type === 'INCOME'
        if (isIncome) {
          stockMap[key].income += qty
          stockMap[key].latestIncomeTpId = tp.id
        } else {
          stockMap[key].outcome += qty
        }
      }

      // ── 1b. Shift-ээр орж/гарсан тоог нэмнэ (Transaction_parts мөр
      // үүсгэдэггүй тул дээрх нэгтгэлд орохгүй, тусад нь тооцно) ──
      try {
        const shiftRes = await getItems({
          collection: 'Parts_shift_history',
          params: {
            filter: {
              company_id: { _eq: myCompanyId },
              part: { _in: partIds },
              _or: [
                { from_location: { _eq: props.locationId } },
                { to_location: { _eq: props.locationId } },
              ],
            },
            fields: [
              'part',
              'part_state',
              'qty',
              'from_location',
              'to_location',
            ],
            limit: -1,
          },
        })
        const shiftList = Array.isArray(shiftRes)
          ? shiftRes
          : shiftRes?.data ?? []
        for (const sh of shiftList) {
          const partId = typeof sh.part === 'object' ? sh.part?.id : sh.part
          const stateId = sh.part_state ?? null
          const key = `${partId}_${stateId ?? 'null'}`
          const qty = parseInt(sh.qty) || 0
          const toId =
            typeof sh.to_location === 'object'
              ? sh.to_location?.id
              : sh.to_location
          const fromId =
            typeof sh.from_location === 'object'
              ? sh.from_location?.id
              : sh.from_location

          if (!stockMap[key]) {
            stockMap[key] = {
              id: key,
              partId,
              partNumber: '—',
              stateId,
              income: 0,
              outcome: 0,
              latestIncomeTpId: null,
            }
          }
          if (String(toId) === String(props.locationId)) {
            stockMap[key].income += qty
          }
          if (String(fromId) === String(props.locationId)) {
            stockMap[key].outcome += qty
          }
        }

        // Хэрэв зөвхөн shift-ээр орж ирсэн (Transaction_parts-д огт байхгүй)
        // part байвал part.part_number хоосон үлдэх тул тусад нь бөглөнө
        const needName = Object.values(stockMap).filter(
          (v) => v.partNumber === '—',
        )
        if (needName.length) {
          const missingIds = [...new Set(needName.map((v) => v.partId))]
          const partsRes = await getItems({
            collection: 'Parts',
            params: {
              filter: { id: { _in: missingIds } },
              fields: ['id', 'part_number'],
              limit: -1,
            },
          })
          const partsList = Array.isArray(partsRes)
            ? partsRes
            : partsRes?.data ?? []
          const nameById = {}
          for (const p of partsList) nameById[p.id] = p.part_number
          for (const v of needName) {
            v.partNumber = nameById[v.partId] ?? '—'
          }
        }
      } catch (e) {
        console.warn('Failed to load shift history:', e)
      }

      allItems.value = Object.values(stockMap)
        .map((v) => ({ ...v, qty: v.income - v.outcome }))
        .filter((v) => v.qty > 0)
        .sort((a, b) => a.partNumber.localeCompare(b.partNumber))

      for (const row of allItems.value) {
        binRows.value[row.id] = [{ bin_location: null, qty: null }]
      }
    } catch (e) {
      console.warn('Failed to load transaction parts:', e)
    }

    // ── 3. Load existing Parts_Bin_location assignments ──
    if (allItems.value.length) {
      try {
        const binAssignRes = await getItems({
          collection: 'Parts_Bin_location',
          params: {
            filter: {
              part: { _in: partIds },
              location: { _eq: props.locationId },
              status: { _neq: 'archived' },
            },
            fields: [
              'id',
              'qty',
              'bin_location',
              'part.id',
              'part.part_number',
              'transaction_parts.id',
              'transaction_parts.part_state',
            ],
            limit: -1,
          },
        })
        const binAssignList = Array.isArray(binAssignRes)
          ? binAssignRes
          : binAssignRes?.data ?? []

        placedItems.value = []
        for (const row of binAssignList) {
          const partId = row.part?.id
          const stateId = row.transaction_parts?.part_state ?? null
          const key = `${partId}_${stateId ?? 'null'}`
          if (!existingAssignments.value[key])
            existingAssignments.value[key] = []
          existingAssignments.value[key].push({
            id: row.id,
            qty: row.qty,
            bin_location: row.bin_location,
          })
          placedItems.value.push({
            id: row.id,
            partId,
            partNumber: row.part?.part_number ?? '—',
            stateId,
            transactionPartsId: row.transaction_parts?.id ?? null,
            qty: row.qty,
            bin_location: row.bin_location,
            pendingBin: row.bin_location,
            // Хоосон орхивол бүтэн (item.qty) шилжинэ — placeholder-оор
            // харагдана, урьдчилан бөглөхгүй
            pendingQty: null,
          })
        }
        placedItems.value.sort((a, b) =>
          (a.partNumber || '').localeCompare(b.partNumber || ''),
        )
      } catch (e) {
        console.warn('Failed to load existing bin assignments:', e)
      }

      // Бүрэн binned болсон (үлдэгдэлгүй) мөрийг Assign tab-аас арилгана —
      // цаашид зөвхөн binned болоогүй/хэсэгчлэн binned part-ууд харагдана
      allItems.value = allItems.value.filter(
        (row) => row.qty - binnedQty(row.id) > 0,
      )
    }

    // ── 4. Load bin locations ──
    try {
      const binRes = await getItems({
        collection: 'Bin_location',
        params: {
          filter: {
            location: { _eq: props.locationId },
            status: { _neq: 'archived' },
          },
          fields: ['id', 'name'],
          sort: ['name'],
          limit: -1,
        },
      })
      binLocations.value = Array.isArray(binRes) ? binRes : binRes?.data ?? []
    } catch (e) {
      console.warn('Failed to load bin locations:', e)
    }

    loading.value = false
  },
)

const stateName = (code) =>
  code != null ? stateMap.value[String(code)] ?? String(code) : '—'

const isNew = (code) => {
  const label = stateName(code).toLowerCase()
  return label.includes('шинэ') || label.includes('new')
}

const binnedQty = (rowId) =>
  (existingAssignments.value[rowId] ?? []).reduce((s, r) => s + (r.qty || 0), 0)

// Тухайн мөрөнд сервер дээр аль хэдийн binned-гүй, одоо зааж болох үлдэгдэл
const remainingQty = (rowId) => {
  const row = allItems.value.find((r) => r.id === rowId)
  if (!row) return 0
  return row.qty - binnedQty(rowId)
}

// Тухайн мөрийн draft (сонгоод хараахан хадгалаагүй) хос бүрийн нийт тоо
const draftQty = (rowId) =>
  (binRows.value[rowId] ?? []).reduce(
    (s, pair) => s + (Number(pair.qty) || 0),
    0,
  )

const isOverAssigned = (rowId) => draftQty(rowId) > remainingQty(rowId)

const addBinRow = (rowId) => {
  if (!binRows.value[rowId]) binRows.value[rowId] = []
  binRows.value[rowId].push({ bin_location: null, qty: null })
}

const removeBinRow = (rowId, index) => {
  binRows.value[rowId]?.splice(index, 1)
  if (!binRows.value[rowId]?.length) {
    binRows.value[rowId] = [{ bin_location: null, qty: null }]
  }
}

// ── Placed items: аль хэдийн байрлуулсан parts-ыг өөр bin рүү шилжүүлэх/солих ──
const isSelectedForSwap = (item) =>
  selectedForSwap.value.some((i) => i.id === item.id)

const toggleSwapSelect = (item) => {
  const idx = selectedForSwap.value.findIndex((i) => i.id === item.id)
  if (idx !== -1) {
    selectedForSwap.value.splice(idx, 1)
    return
  }
  if (selectedForSwap.value.length >= 2) {
    selectedForSwap.value.shift()
  }
  selectedForSwap.value.push(item)
}

const handleSwap = async () => {
  if (selectedForSwap.value.length !== 2) return
  const [a, b] = selectedForSwap.value
  if (a.bin_location === b.bin_location) {
    toaster.show({
      title: t('Warning'),
      message: t('These two items are already in the same bin'),
      color: 'warning',
      icon: 'ph:warning-circle',
      closable: true,
    })
    return
  }
  swapping.value = true
  try {
    await updateItem({
      collection: 'Parts_Bin_location',
      id: Number(a.id),
      item: { bin_location: b.bin_location },
    })
    await updateItem({
      collection: 'Parts_Bin_location',
      id: Number(b.id),
      item: { bin_location: a.bin_location },
    })
    const tmp = a.bin_location
    a.bin_location = b.bin_location
    a.pendingBin = a.bin_location
    b.bin_location = tmp
    b.pendingBin = b.bin_location
    selectedForSwap.value = []

    toaster.show({
      title: t('Saved'),
      message: t('Bin locations swapped') + '!',
      color: 'success',
      icon: 'ph:check-circle',
      closable: true,
    })
    if (props.refresh) props.refresh()
  } catch (e) {
    toaster.show({
      title: t('Error'),
      message: String(e),
      color: 'danger',
      closable: true,
    })
  } finally {
    swapping.value = false
  }
}

const handleMove = async (item) => {
  if (!item.pendingBin || item.pendingBin === item.bin_location) return
  // Хоосон орхивол бүтэн (item.qty) шилжинэ
  const requestedQty =
    item.pendingQty != null && item.pendingQty !== ''
      ? Number(item.pendingQty)
      : Number(item.qty)
  const moveQty = Math.min(requestedQty || 0, Number(item.qty) || 0)
  if (moveQty <= 0) return

  movingId.value = item.id
  try {
    if (moveQty >= item.qty) {
      // Бүтэн шилжүүлэг — мөрийг өөрчлөөд шилжүүлнэ (шинэ мөр үүсгэх
      // шаардлагагүй)
      await updateItem({
        collection: 'Parts_Bin_location',
        id: Number(item.id),
        item: { bin_location: item.pendingBin },
      })
      item.bin_location = item.pendingBin
      item.pendingQty = null
    } else {
      // Хэсэгчилсэн шилжүүлэг — эх мөрөөс шилжүүлсэн тоог хасаад, зорилтот
      // bin дээр байгаа (ижил part+state) мөрийг нэмэгдүүлэх, эсвэл шинэ
      // мөр үүсгэнэ
      const remaining = item.qty - moveQty
      await updateItem({
        collection: 'Parts_Bin_location',
        id: Number(item.id),
        item: { qty: remaining },
      })
      item.qty = remaining
      item.pendingQty = null

      const existingAtTarget = placedItems.value.find(
        (p) =>
          p.id !== item.id &&
          p.partId === item.partId &&
          p.stateId === item.stateId &&
          p.bin_location === item.pendingBin,
      )

      if (existingAtTarget) {
        const newQty = existingAtTarget.qty + moveQty
        await updateItem({
          collection: 'Parts_Bin_location',
          id: Number(existingAtTarget.id),
          item: { qty: newQty },
        })
        existingAtTarget.qty = newQty
        existingAtTarget.pendingQty = null
      } else {
        const created = await createItems({
          collection: 'Parts_Bin_location',
          items: [
            {
              transaction_parts: item.transactionPartsId ?? null,
              bin_location: item.pendingBin,
              location: props.locationId,
              qty: moveQty,
              part: item.partId,
              status: 'published',
              company_id: myCompanyId,
            },
          ],
        })
        const createdRow = Array.isArray(created)
          ? created[0]
          : created?.data?.[0]
        if (createdRow?.id) {
          placedItems.value.push({
            id: createdRow.id,
            partId: item.partId,
            partNumber: item.partNumber,
            stateId: item.stateId,
            transactionPartsId: item.transactionPartsId,
            qty: moveQty,
            bin_location: item.pendingBin,
            pendingBin: item.pendingBin,
            pendingQty: null,
          })
        }
      }

      // Эх мөрийн үлдэгдэл 0 болсон бол жагсаалтаас арилгана (мөр нь DB дээр
      // qty:0-тэйгээр үлдэнэ, шаардвал дараа нь цэвэрлэж болно)
      if (remaining <= 0) {
        placedItems.value = placedItems.value.filter((p) => p.id !== item.id)
      }
    }

    toaster.show({
      title: t('Saved'),
      message: t('Bin location updated') + '!',
      color: 'success',
      icon: 'ph:check-circle',
      closable: true,
    })
    if (props.refresh) props.refresh()
  } catch (e) {
    toaster.show({
      title: t('Error'),
      message: String(e),
      color: 'danger',
      closable: true,
    })
  } finally {
    movingId.value = null
  }
}

const assignedCount = computed(() =>
  Object.values(binRows.value).reduce(
    (count, pairs) =>
      count + pairs.filter((p) => p.bin_location && Number(p.qty) > 0).length,
    0,
  ),
)

const hasOverAssignment = computed(() =>
  allItems.value.some((row) => isOverAssigned(row.id)),
)

const allAssigned = computed(() => {
  if (!allItems.value.length) return false
  return allItems.value.every((item) => {
    const list = existingAssignments.value[item.id]
    if (!list || !list.length) return false
    const totalAssigned = list.reduce((sum, r) => sum + (r.qty || 0), 0)
    return totalAssigned >= item.qty
  })
})

const handleSave = async () => {
  // (rowId, pair) хосуудыг хавтгайруулах — зөвхөн bin_location + qty>0 бүхий хосууд
  const toSave = []
  for (const [rowId, pairs] of Object.entries(binRows.value)) {
    for (const pair of pairs) {
      if (pair.bin_location && Number(pair.qty) > 0) {
        toSave.push([rowId, pair.bin_location, Number(pair.qty)])
      }
    }
  }

  if (!toSave.length) {
    toaster.show({
      title: t('Warning'),
      message: t('Please assign at least one bin location'),
      color: 'warning',
      icon: 'ph:warning-circle',
      closable: true,
    })
    return
  }

  if (hasOverAssignment.value) {
    toaster.show({
      title: t('Warning'),
      message: t(
        'Assigned quantity exceeds available stock for one or more parts',
      ),
      color: 'warning',
      icon: 'ph:warning-circle',
      closable: true,
    })
    return
  }

  saving.value = true
  try {
    for (const [rowId, binId, qty] of toSave) {
      const row = allItems.value.find((r) => r.id === rowId)
      if (!row) continue

      const existingList = existingAssignments.value[rowId] ?? []
      const matching = existingList.find((r) => r.bin_location === binId)

      if (matching) {
        const newQty = (matching.qty || 0) + qty
        await updateItem({
          collection: 'Parts_Bin_location',
          id: Number(matching.id),
          item: { qty: newQty, status: 'published' },
        })
        matching.qty = newQty
        console.log('matching', matching)
      } else {
        await createItems({
          collection: 'Parts_Bin_location',
          items: [
            {
              transaction_parts: row.latestIncomeTpId ?? null,
              bin_location: binId,
              location: props.locationId,
              qty,
              part: row.partId,
              status: 'published',
              company_id: myCompanyId,
            },
          ],
        })
      }
    }

    toaster.show({
      title: t('Saved'),
      message: `${toSave.length} ` + t('records updated') + '!',
      color: 'success',
      icon: 'ph:check-circle',
      closable: true,
    })
    if (props.refresh) props.refresh()
    if (props.close) props.close()
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
        <Icon
          name="fluent:board-split-16-filled"
          class="h-5 w-5 text-primary-500"
        />
        <h3
          class="font-heading text-lg font-medium leading-6 text-muted-900 dark:text-white"
        >
          {{ $t('Set Bin Location') }}
        </h3>
      </div>
    </template>

    <div class="p-4">
      <div v-if="loading" class="flex items-center justify-center py-10">
        <Icon
          name="mdi:loading"
          class="h-7 w-7 animate-spin text-primary-500"
        />
      </div>

      <template v-else>
        <BaseTabs
          :model-value="activeTab"
          :tabs="tabs"
          type="box"
          @update:model-value="activeTab = $event"
        >
          <template #tab="{ activeValue }">
            <div v-if="activeValue === 'assign'">
              <!-- All assigned alert -->
              <div
                v-if="allAssigned"
                class="flex items-center gap-3 rounded-lg border border-success-200 bg-success-50 px-4 py-3 dark:border-success-800 dark:bg-success-900/20"
              >
                <Icon
                  name="ph:check-circle-fill"
                  class="h-5 w-5 shrink-0 text-success-500"
                />
                <p class="text-sm text-success-700 dark:text-success-400">
                  {{ $t('All items are already assigned to bin locations.') }}
                </p>
              </div>

              <!-- Stock-based assignment table -->
              <div
                v-else
                class="max-h-596 h-[396px] overflow-y-auto rounded-lg border border-muted-200 dark:border-muted-700"
              >
                <table class="w-full text-sm">
                  <thead class="sticky top-0 bg-muted-100 dark:bg-muted-800">
                    <tr>
                      <th
                        class="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-500"
                      >
                        {{ $t('Part Number') }}
                      </th>
                      <th
                        class="Stock px-3 py-2 text-center text-xs font-semibold uppercase text-muted-500"
                      >
                        {{ $t('Stock') }}
                      </th>
                      <th
                        class="Binned px-3 py-2 text-center text-xs font-semibold uppercase text-muted-500"
                      >
                        {{ $t('Binned') }}
                      </th>
                      <th
                        class="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-500"
                      >
                        {{ $t('State') }}
                      </th>
                      <th colspan="2" class="px-3 py-2">
                        <div class="flex items-center gap-1">
                          <span
                            class="w-[240px] shrink-0 text-left text-xs font-semibold uppercase text-muted-500"
                          >
                            {{ $t('Bin Location') }}
                          </span>
                          <span
                            class="w-20 shrink-0 text-center text-xs font-semibold uppercase text-muted-500"
                          >
                            {{ $t('Assign Qty') }}
                          </span>
                        </div>
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr
                      v-for="row in allItems"
                      :key="row.id"
                      class="border-t border-muted-200 dark:border-muted-700"
                      :class="
                        binRows[row.id]?.some((p) => p.bin_location)
                          ? 'bg-primary-50/50 dark:bg-primary-900/10'
                          : ''
                      "
                    >
                      <td
                        class="px-3 py-2 font-medium text-muted-800 dark:text-muted-200"
                      >
                        {{ row.partNumber }}
                      </td>
                      <td class="px-3 py-2 text-center">
                        <span class="font-bold text-primary-600">{{
                          row.qty
                        }}</span>
                        <span class="ml-1 text-xs text-muted-400"
                          >(↑{{ row.income }} ↓{{ row.outcome }})</span
                        >
                      </td>
                      <td class="px-3 py-2 text-center">
                        <span
                          class="font-semibold"
                          :class="
                            binnedQty(row.id) >= row.qty
                              ? 'text-success-600'
                              : binnedQty(row.id) > 0
                              ? 'text-warning-500'
                              : 'text-muted-400'
                          "
                        >
                          {{ binnedQty(row.id) }}
                        </span>
                        <span class="ml-1 text-xs text-muted-300"
                          >/ {{ row.qty }}</span
                        >
                      </td>
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
                      <td class="w-[300px] px-3 py-1.5" colspan="2">
                        <div
                          v-for="(pair, index) in binRows[row.id]"
                          :key="index"
                          class="mb-1 flex items-center gap-1"
                        >
                          <v-select-dropdown
                            v-model="pair.bin_location"
                            :options="binLocations"
                            label="name"
                            :reduce="(b) => b.id"
                            :clearable="true"
                            placeholder="—"
                            :class="`${$colorMode.value} style-chooser w-[240px] shrink-0`"
                          />
                          <input
                            v-model.number="pair.qty"
                            @input="pair.qty = pair.qty < 0 ? null : pair.qty"
                            type="number"
                            :min="1"
                            :placeholder="String(row.qty)"
                            :disabled="!pair.bin_location"
                            class="w-20 rounded border border-muted-300 bg-white px-2 py-1 text-center text-xs text-muted-800 focus:outline-none focus:ring-1 focus:ring-primary-500 disabled:opacity-40 dark:border-muted-600 dark:bg-muted-900 dark:text-muted-200"
                          />
                          <button
                            type="button"
                            class="rounded p-1 text-muted-400 hover:text-danger-500"
                            :disabled="binRows[row.id].length <= 1"
                            @click="removeBinRow(row.id, index)"
                          >
                            <Icon name="ph:trash" class="h-3.5 w-3.5" />
                          </button>
                          <button
                            v-if="index === binRows[row.id].length - 1"
                            type="button"
                            class="rounded p-1 text-primary-500 hover:text-primary-600"
                            @click="addBinRow(row.id)"
                          >
                            <Icon name="ph:plus-circle" class="h-4 w-4" />
                          </button>
                        </div>
                        <p
                          class="text-xs"
                          :class="
                            isOverAssigned(row.id)
                              ? 'text-danger-500'
                              : 'text-muted-400'
                          "
                        >
                          {{ draftQty(row.id) }} / {{ remainingQty(row.id) }}
                          {{ $t('remaining') }}
                        </p>
                      </td>
                    </tr>
                    <tr v-if="!allItems.length">
                      <td
                        colspan="5"
                        class="px-3 py-8 text-center text-muted-400"
                      >
                        {{ $t('No stock found for selected parts') }}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <p
                v-if="!binLocations.length"
                class="mt-2 text-xs text-warning-500"
              >
                {{
                  $t(
                    'No bin locations found for this location. Please add bin locations first.',
                  )
                }}
              </p>
            </div>

            <div v-else-if="activeValue === 'placed'">
              <p class="mb-2 text-xs text-muted-400">
                {{
                  $t(
                    'Select any two rows to swap their bin locations, or change a single row and click Move.',
                  )
                }}
              </p>
              <div
                class="max-h-596 h-[396px] overflow-y-auto rounded-lg border border-muted-200 dark:border-muted-700"
              >
                <table class="w-full text-sm">
                  <thead class="sticky top-0 bg-muted-100 dark:bg-muted-800">
                    <tr>
                      <th class="w-8 px-3 py-2"></th>
                      <th
                        class="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-500"
                      >
                        {{ $t('Part Number') }}
                      </th>
                      <th
                        class="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-500"
                      >
                        {{ $t('State') }}
                      </th>
                      <th
                        class="px-3 py-2 text-center text-xs font-semibold uppercase text-muted-500"
                      >
                        {{ $t('Qty') }}
                      </th>
                      <th
                        class="px-3 py-2 text-left text-xs font-semibold uppercase text-muted-500"
                      >
                        {{ $t('Bin Location') }}
                      </th>
                      <th
                        class="px-3 py-2 text-center text-xs font-semibold uppercase text-muted-500"
                      >
                        {{ $t('Move Qty') }}
                      </th>
                      <th class="px-3 py-2"></th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr
                      v-for="item in placedItems"
                      :key="item.id"
                      class="border-t border-muted-200 dark:border-muted-700"
                      :class="
                        isSelectedForSwap(item)
                          ? 'bg-primary-50/50 dark:bg-primary-900/10'
                          : ''
                      "
                    >
                      <td class="px-3 py-2">
                        <input
                          type="checkbox"
                          :checked="isSelectedForSwap(item)"
                          @change="toggleSwapSelect(item)"
                        />
                      </td>
                      <td
                        class="px-3 py-2 font-medium text-muted-800 dark:text-muted-200"
                      >
                        {{ item.partNumber }}
                      </td>
                      <td class="px-3 py-2">
                        <span
                          class="rounded px-2 py-0.5 text-xs font-medium"
                          :class="
                            isNew(item.stateId)
                              ? 'bg-success-100 text-success-700 dark:bg-success-900/30 dark:text-success-400'
                              : 'bg-muted-100 text-muted-600 dark:bg-muted-700 dark:text-muted-300'
                          "
                        >
                          {{ stateName(item.stateId) }}
                        </span>
                      </td>
                      <td
                        class="px-3 py-2 text-center font-semibold text-primary-600"
                      >
                        {{ item.qty }}
                      </td>
                      <td class="w-[260px] px-3 py-1.5">
                        <v-select-dropdown
                          v-model="item.pendingBin"
                          :options="binLocations"
                          label="name"
                          :reduce="(b) => b.id"
                          :clearable="false"
                          :class="`${$colorMode.value} style-chooser w-[240px]`"
                        />
                      </td>
                      <td class="px-3 py-1.5 text-center">
                        <input
                          v-model.number="item.pendingQty"
                          @input="
                            item.pendingQty =
                              item.pendingQty < 0 ? null : item.pendingQty
                          "
                          type="number"
                          :min="1"
                          :max="item.qty"
                          :placeholder="String(item.qty)"
                          class="w-20 rounded border border-muted-300 bg-white px-2 py-1 text-center text-xs text-muted-800 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-muted-600 dark:bg-muted-900 dark:text-muted-200"
                        />
                      </td>
                      <td class="px-3 py-1.5">
                        <BaseButton
                          size="sm"
                          color="default"
                          :disabled="
                            item.pendingBin === item.bin_location ||
                            movingId === item.id ||
                            (item.pendingQty != null &&
                              item.pendingQty !== '' &&
                              item.pendingQty <= 0)
                          "
                          :loading="movingId === item.id"
                          @click="handleMove(item)"
                        >
                          {{ $t('Move') }}
                        </BaseButton>
                      </td>
                    </tr>
                    <tr v-if="!placedItems.length">
                      <td
                        colspan="7"
                        class="px-3 py-8 text-center text-muted-400"
                      >
                        {{ $t('No placed items yet') }}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </template>
        </BaseTabs>
      </template>
    </div>

    <template #footer>
      <div class="flex w-full items-center justify-end gap-2 p-4">
        <BaseButton @click="close" color="default" size="sm">
          {{ $t('Cancel') }}
        </BaseButton>
        <BaseButton
          v-if="activeTab === 'assign'"
          @click="handleSave"
          color="primary"
          size="sm"
          :loading="saving"
          :disabled="!assignedCount || hasOverAssignment"
        >
          <Icon name="ph:floppy-disk" class="-ms-1 h-4 w-4" />
          {{ $t('Save') }}
          <span v-if="assignedCount" class="ms-1 opacity-75"
            >({{ assignedCount }})</span
          >
        </BaseButton>
        <BaseButton
          v-else
          @click="handleSwap"
          color="primary"
          size="sm"
          :loading="swapping"
          :disabled="selectedForSwap.length !== 2"
        >
          <Icon name="ph:arrows-left-right" class="-ms-1 h-4 w-4" />
          {{ $t('Swap Selected') }}
          <span v-if="selectedForSwap.length" class="ms-1 opacity-75"
            >({{ selectedForSwap.length }}/2)</span
          >
        </BaseButton>
      </div>
    </template>
  </TairoModal>
</template>
