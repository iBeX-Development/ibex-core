import { toRaw } from 'vue'
const { getItems } = useDirectusItems()

let open_status_id: any = 1
let draft_status_id: any = 8
let open_status_ids: any = []
let completed_status_ids: any = []
let all_wo_status_ids: any = []

let wo_status: any = false
let open_wo_status: any = false
let completed_wo_status: any = false

let wo_status_items: any = false

const getStatus = async (wo_type: string) => {
  try {
    const filters = { active: 1 }
    const status_items = await getItems({
      collection: 'Module_status',
      params: {
        filter: filters,
        sort: ['position'],
        meta: 'filter_count',
        fields: ['*', 'code_color.*'],
      },
    })

    if (status_items.data.length) {
      wo_status_items = status_items.data.map((status: any) => {
        if (status.id == 1) open_status_id = status.id
        if (status.id == 8) draft_status_id = status.id

        all_wo_status_ids.push(status.id)
        if (status.type == 'open') open_status_ids.push(status.id)
        else if (status.type == 'completed')
          completed_status_ids.push(status.id)

        return {
          id: status.id,
          name: status.status_text,
          icon: status.icon,
          type: status.type,
        }
      })

      wo_status = {
        _in: toRaw(all_wo_status_ids),
      }

      open_wo_status = {
        _in: toRaw(open_status_ids),
      }

      completed_wo_status = {
        _in: toRaw(completed_status_ids),
      }
    }

    return {
      draft_status_id,
      open_status_id,
      open_status_ids,
      open_wo_status,
      completed_status_ids,
      completed_wo_status,
      wo_status,
      wo_status_items,
    }
  } catch (e) {
    console.log('err', e)
  }
}

// if (!wo_status) {
//   console.log('called_get')
//   getStatus('open')
// }

// `wo_status` бол энэ модулийн орон нутгийн (module-scope) хувьсагч тул
// Vite/webpack код хуваахад (code-splitting) энэ файл хэд хэдэн тусдаа
// chunk-д давхар bundle болвол тус бүр өөрийн `wo_status = false`-оос эхэлж,
// заавал дахин Module_status-ыг дуудна. globalThis дээр хадгалсан НЭГ л
// promise ашигласнаар апп даяар (бүх chunk-үүдэд) зөвхөн НЭГ л удаа fetch хийнэ.
const g = globalThis as any
if (!g.__wo_status_open_fetch__) {
  console.log('called_get')
  g.__wo_status_open_fetch__ = getStatus('open')
}

export {
  completed_status_ids,
  completed_wo_status,
  draft_status_id,
  getStatus,
  open_status_id,
  open_status_ids,
  open_wo_status,
  wo_status,
  wo_status_items,
}
