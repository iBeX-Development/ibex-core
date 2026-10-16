// АРХИВ — энэ composable ХААНА Ч ДУУДАГДАХГҮЙ.
//
// income_amount/outcome_amount нь одоо cache биш, Transaction_parts-аас
// (batlagдсан, status=2) тухай бүрд live тооцогддог болсон тул Parts_Amounts-ийг
// гараар "тэнцвэржүүлдэг" энэ логик хэрэггүй болсон. Хуучин дараах 6 файлд
// байсан давхардсан updateStock() хувилбарууд бүгд УСТГАГДСАН:
//   components/transaction/IncomeModalForm.vue
//   components/transaction/OutcomeModalForm.vue
//   pages/transaction/income/index.vue
//   pages/transaction/location/income/[id].vue
//   pages/transaction/outcome/index.vue
//   pages/transaction/location/outcome/[id].vue
// Энэ файлыг зөвхөн тэдгээрийн хуучин семантикийг (create/delete/edit delta
// тооцоолол) хожим лавлах шаардлага гарвал ашиглахаар архивласан.

export type PartsStockAmountField = 'income_amount' | 'outcome_amount'
export type PartsStockUpdateType = 'create' | 'delete' | 'edit'

export interface PartsStockItem {
  part: number
  qty: number
  old_qty?: number
}

export const usePartsStock = () => {
  const { getItems, updateItem, createItems } = useDirectusItems()
  const myCompanyId = getMyCompanyId()

  const updateAmounts = async (
    newParts: PartsStockItem[],
    locationId: number,
    type: PartsStockUpdateType,
    amountField: PartsStockAmountField,
  ) => {
    // Нэг part хэд хэдэн Transaction_parts мөрөнд орж болох тул нэгтгэж,
    // race condition-оос сэргийлнэ (нэг Parts_Amounts мөрийг олон удаа зэрэг
    // read-then-write хийхгүй)
    const grouped: Record<
      string,
      { part: number; qty: number; oldQty: number }
    > = {}
    for (const item of newParts) {
      const key = String(item.part)
      if (!grouped[key]) grouped[key] = { part: item.part, qty: 0, oldQty: 0 }
      grouped[key].qty += parseInt(String(item.qty)) || 0
      grouped[key].oldQty += parseInt(String(item.old_qty ?? 0)) || 0
    }

    for (const { part, qty, oldQty } of Object.values(grouped)) {
      const res = await getItems({
        collection: 'Parts_Amounts',
        params: {
          filter: { part: { _eq: part }, location: { _eq: locationId } },
          meta: 'filter_count',
          fields: ['id', amountField],
          limit: 1,
        },
      })
      const list = Array.isArray(res) ? res : (res as any)?.data ?? []

      if (list.length) {
        const current = parseInt(list[0][amountField]) || 0
        let next = current
        if (type === 'create') next = current + qty
        else if (type === 'delete') next = Math.max(0, current - qty)
        else if (type === 'edit') next = Math.max(0, current - oldQty + qty)

        await updateItem({
          collection: 'Parts_Amounts',
          id: list[0].id,
          item: { [amountField]: next },
        })
      } else if (qty > 0) {
        await createItems({
          collection: 'Parts_Amounts',
          items: {
            part,
            location: locationId,
            [amountField]: qty,
            company_id: myCompanyId,
          },
        })
      }
    }
  }

  return { updateAmounts }
}
