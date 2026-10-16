<script setup lang="ts">
const config = useRuntimeConfig()
const { close, currentProps, open } = usePanels()

const props = defineProps({
  open: Boolean,
  wo_ids: Array,
  close: Function,
})
import { useI18n } from 'vue-i18n'
import { renderAsync } from 'docx-preview'
import * as pdfjsLib from 'pdfjs-dist'
import { nextTick, onMounted, ref, toRaw } from 'vue'

import * as XLSX from 'xlsx'

import mammoth from 'mammoth/mammoth.browser'
import { priorities } from '~/components/workorder/WorkOrderConstants'
import { wo_status_items } from '~/components/workorder/WorkOrderStatus'

// Worker-ийг динамикаар тохируулах
// pdfjsLib.GlobalWorkerOptions.workerSrc = new URL(
//   'pdfjs-dist/build/pdf.worker.min.mjs',
//   import.meta.url,
// ).toString()

if (typeof window !== 'undefined') {
  pdfjsLib.GlobalWorkerOptions.workerSrc = `https://cdn.jsdelivr.net/npm/pdfjs-dist@${pdfjsLib.version}/build/pdf.worker.min.mjs`
}
const { getItems, updateItem, createItems } = useDirectusItems()
const { t } = useI18n({ useScope: 'global' })

const loading = ref(true)
const records = ref([])
const rowFiles = ref([])
const work_orders = ref([]) // Бүх work order-ууд
const selectedWorkOrders = ref([]) // сонгогдсон work_order.id-ууд
const isDocxLoaded = ref(false) // DOCX ачааллын төлөв
const Prints_tempates = ref([])

const wo_ids = currentProps?.value?.wo_ids || null
const paramId = currentProps?.value?.wo_id || null
const progress_data = currentProps?.value?.progress_data || null
const wo_statuses = currentProps?.value?.wo_statuses || null
const wo_type = currentProps?.value?.wo_type || null
const refresh = currentProps?.value?.refresh || null
const Isopen = currentProps?.value?.open || false

const printArea = ref(null)
const pdfCanvas = ref(null)
const htmlContent = ref('<h1>HTML хэсэг</h1>')
const docxContent = ref('')
const excelTable = ref('')
const pdfCanvases = ref([]) // Олон PDF хуудас хадгалах

let priority = null
let wo_status = null
const now = new Date()
const formattedDate = ref(
  `${now.getFullYear()}/${String(now.getMonth() + 1).padStart(2, '0')}/${String(
    now.getDate(),
  ).padStart(2, '0')}`,
)

const status = [
  'Бүрэн дууссан',
  'Дахин үргэлжлэх',
  'Сэлбэг байхгүй',
  'Цуцалсан',
  'Аюулгүй ажиллагааны нөхцөл хангалтгүй тул ажлыг зогсоосон',
]

const breakdown = [
  'Хэвийн',
  'Хуучирсан',
  'Халалттай',
  'Хэвийн бус дуутай',
  'Элэгдсэн',
  'Хэмжээ алдагдсан',
  'Зуурсан',
  'Хэмжээсгүй',
  'Цоорсон',
  'Бөглөрсөн',
  'Гацсан',
  'Хэт ачаалсан',
  'Нурсан',
  'Зүсэгдсэн',
  'Суларсан',
  'Тосолгоогүй',
  'Ханзарсан',
  'Буруу угсралт',
  'Гүйлттэй',
  'Тасарсан',
  'Түвшин их',
  'Цуурсан',
  'Гулзайсан',
  'Хагарсан',
  'Шатсан',
  'Түвшин бага',
  'Бохирдол их',
  'Бохирдол бага',
  'Газардлага',
  'Удирдлага гэмтсэн',
  'Хүчдэлгүй',
  'Богино залгаа',
  'Сигнал байхгүй',
  'Хэмжүүрийн алдаа',
  'Өндөр гүйдэл',
  'Буруу холболт',
]
const formatDates = (cdate) => {
  if (!cdate) return '-'
  const date = new Date(cdate)
  if (isNaN(date.getTime())) return '-'
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(
    2,
    '0',
  )}-${String(now.getDate()).padStart(2, '0')}`
}

//  Text node-уудыг олж солих функц
const replaceTextPlaceholders = (container, placeholders) => {
  const walker = document.createTreeWalker(
    container,
    NodeFilter.SHOW_TEXT,
    null,
    false,
  )

  const textNodes = []
  let node
  while ((node = walker.nextNode())) {
    textNodes.push(node)
  }

  textNodes.forEach((textNode) => {
    let text = textNode.textContent
    let hasReplacement = false

    Object.entries(placeholders).forEach(([key, value]) => {
      // HTML block placeholder-уудыг алгасах
      if (
        key.includes('CN12') ||
        key.includes('CN13') ||
        key.includes('CN14') ||
        key.includes('CN15')
        // key.includes('CN16')
      )
        return

      if (text.includes(key)) {
        text = text.replace(
          new RegExp(key.replace(/[{}]/g, '\\$&'), 'g'),
          value,
        )
        hasReplacement = true
      }
    })

    if (hasReplacement) {
      textNode.textContent = text
    }
  })
}

// HTML block-уудыг солих функц
const replaceHtmlBlocks = (container, placeholders) => {
  const htmlBlocks = {
    '{{CN12}}': placeholders['{{CN12}}'],
    '{{CN13}}': placeholders['{{CN13}}'],
    '{{CN14.1}}': placeholders['{{CN14.1}}'],
    '{{CN14.2}}': placeholders['{{CN14.2}}'],
    '{{CN14.3}}': placeholders['{{CN14.3}}'],
    '{{CN15.1}}': placeholders['{{CN15.1}}'],
    '{{CN15.2}}': placeholders['{{CN15.2}}'],
    '{{CN15.3}}': placeholders['{{CN15.3}}'],
    '{{CN15.4}}': placeholders['{{CN15.4}}'],
    '{{CN15.5}}': placeholders['{{CN15.5}}'],
    // '{{CN16}}': placeholders['{{CN16}}'], // Transaction table
  }

  Object.entries(htmlBlocks).forEach(([placeholder, htmlContent]) => {
    const walker = document.createTreeWalker(
      container,
      NodeFilter.SHOW_TEXT,
      null,
      false,
    )

    const textNodes = []
    let node
    while ((node = walker.nextNode())) {
      if (node.textContent.trim() === placeholder) {
        textNodes.push(node)
      }
    }

    textNodes.forEach((textNode) => {
      const parentElement = textNode.parentElement
      const parentTd = parentElement.closest('td')

      if (parentTd) {
        parentTd.innerHTML = htmlContent || ''
      } else {
        const wrapper = document.createElement('div')
        wrapper.innerHTML = htmlContent || ''
        parentElement.replaceWith(...wrapper.childNodes)
      }
    })
  })
}

// Template generation functions
const generateOrderItemsHTML = (order_items) => {
  if (!order_items?.length) return ''

  return `
    <div class="tasks">
      <div class="mt-3 grid grid-cols-3 gap-1 mb-4 border border-gray-300 p-2">
        ${order_items
          .map(
            (item, index) => `
          <div class="flex flex-row items-center">
            <input type="checkbox" class="mr-1" id="task-${index}" 
                   ${item.value == '1' ? 'checked' : ''} />
            <label for="task-${index}">${item.name || ''}</label>
          </div>
        `,
          )
          .join('')}
      </div>
    </div>
  `
}

const generateTradeHTML = (work_trade, field) => {
  if (!work_trade?.length) return ''

  const fieldMap = {
    name: (item) => item.trade?.name || '-',
    code: (item) => item.trade?.code || '-',
    duration: (item) => item.duration || '-',
  }

  const getValue = fieldMap[field] || (() => '-')

  return `
    <div class="trade_${field} flex flex-col mt-3 grid gap-1 mb-4 border border-gray-300 p-2">
      ${work_trade
        .map(
          (item, index) => `
        <div class="flex flex-row items-center">
          <label for="trade-${field}-${index}">${getValue(item)}</label>
        </div>
      `,
        )
        .join('')}
    </div>
  `
}

const generatePartsHTML = (work_parts, field) => {
  if (!work_parts?.length) return ''

  const fieldMap = {
    number: (item) => item.parts?.part_number || '-',
    description: (item) => item.parts?.description || '-',
    quantity: (item) => item.quantity || '-',
    price: (item) => item.price || '-',
    amount: (item) => item.amount || '-',
  }

  const getValue = fieldMap[field] || (() => '-')

  return `
    <div class="part_${field} flex flex-col mt-3 grid gap-1 mb-4 border border-gray-300 p-2">
      ${work_parts
        .map(
          (item, index) => `
        <div class="flex flex-row items-center">
          <label class="border-b border-b-[#d0cccc]" for="part-${field}-${index}">
            ${getValue(item)}
          </label>
        </div>
      `,
        )
        .join('')}
    </div>
  `
}

const loadDocxB = async (fileObj) => {
  if (!fileObj || !fileObj.id) {
    console.error('Invalid file object:', fileObj)
    return
  }

  try {
    let wo_items = null
    console.log('Starting DOCX load...', work_orders.value)

    if (work_orders.value.length) {
      wo_items = toRaw(work_orders.value)

      const printDoc = document.getElementById('printDoc')
      if (!printDoc) return
      printDoc.innerHTML = '' // clear

      for (let idx = 0; idx < wo_items.length; idx++) {
        const wo = wo_items[idx]

        let priority = priorities.find(
          (p) => p.value === wo.work_order.priority,
        )
        let wo_status = wo_status_items.find(
          (s) => s.id == wo.work_order.wo_status,
        )

        let cn12HTML = ''
        if (wo.order_items) {
          cn12HTML = `
              <div class="tasks">
                <div class="mt-3 grid grid-cols-3 gap-1 mb-4 border border-gray-300 p-2">
                  ${wo.order_items
                    .map(
                      (item, index) => `
                    <div class="flex flex-row items-center">
                      <input type="checkbox" class="mr-1" id="task-${index}" value="${
                        item.value == '1' ? true : false
                      }" ${item.value == '1' ? 'checked' : ''} />
                      <label for="task-${index}">${item.name}</label>
                    </div>`,
                    )
                    .join('')}
                </div>
              </div>`
        }

        // trade fields ----
        let cn14_1HTML = '' // name
        let cn14_2HTML = '' // code
        let cn14_3HTML = '' // duration

        if (wo.work_trade) {
          cn14_1HTML = `
            <div class="trade_name flex flex-col mt-3 grid gap-1 mb-4 border border-gray-300 p-2">
              ${wo.work_trade
                .map(
                  (item, index) => `
                  <div class="flex flex-row items-center">
                    <label for="task-${index}">${item.trade.name}</label>
                  </div>`,
                )
                .join('')}
            </div>`

          // code (if you have item.code field in your API)
          cn14_2HTML = `
            <div class="trade_code flex flex-col  mt-3 grid gap-1 mb-4 border border-gray-300 p-2">
              ${wo.work_trade
                .map(
                  (item, index) => `
                  <div class="flex flex-row items-center">
                    <label for="task-code-${index}">${
                    item.trade.code ?? '-'
                  }</label>
                  </div>`,
                )
                .join('')}
              </div>`

          // duration
          cn14_3HTML = `
            <div class="duration flex flex-col  mt-3 grid gap-1 mb-4 border border-gray-300 p-2">
              ${wo.work_trade
                .map(
                  (item, index) => `
                  <div class="flex flex-row items-center">
                    <label for="task-duration-${index}">${item.duration}</label>
                  </div>`,
                )
                .join('')}
            </div>`
        }

        // ----parts fields ----
        let cn15_1HTML = '' // number
        let cn15_2HTML = '' // description
        let cn15_3HTML = '' // quantity
        let cn15_4HTML = '' // price
        let cn15_5HTML = '' // amount

        if (wo.work_parts) {
          cn15_1HTML = `
            <div class="part_number flex flex-col mt-3 grid gap-1 mb-4 border border-gray-300 p-2">
              ${wo.work_parts
                .map(
                  (item, index) => `
                  <div class="flex flex-row items-center">
                    <label for="task-${index}">${item.parts.part_number}</label>
                  </div>`,
                )
                .join('')}
            </div>`

          // description (if you have item.code field in your API)
          cn15_2HTML = `
            <div class="description flex flex-col  mt-3 grid gap-1 mb-4 border border-gray-300 p-2">
              ${wo.work_parts
                .map(
                  (item, index) => `
                  <div class="flex flex-row items-center">
                    <label class ="border-b border-b-[#d0cccc]" for="task-code-${index}">${
                    item.parts.description ?? '-'
                  }</label>
                  </div>`,
                )
                .join('')}
              </div>`

          // quantity
          cn15_3HTML = `
            <div class="duration flex flex-col  mt-3 grid gap-1 mb-4 border border-gray-300 p-2">
              ${wo.work_parts
                .map(
                  (item, index) => `
                  <div class="flex flex-row items-center">
                    <label for="task-duration-${index}">${
                    item.quantity ?? '-'
                  }</label>
                  </div>`,
                )
                .join('')}
            </div>`

          // quantity
          cn15_4HTML = `
            <div class="duration flex flex-col  mt-3 grid gap-1 mb-4 border border-gray-300 p-2">
              ${wo.work_parts
                .map(
                  (item, index) => `
                  <div class="flex flex-row items-center">
                    <label for="task-duration-${index}">${
                    item.price ?? '-'
                  }</label>
                  </div>`,
                )
                .join('')}
            </div>`

          // quantity
          cn15_5HTML = `
            <div class="duration flex flex-col  mt-3 grid gap-1 mb-4 border border-gray-300 p-2">
              ${wo.work_parts
                .map(
                  (item, index) => `
                  <div class="flex flex-row items-center">
                    <label for="task-duration-${index}">${
                    item.amount ?? '-'
                  }</label>
                  </div>`,
                )
                .join('')}
            </div>`
        }

        // DOM элемент бэлэн болтол хүлээх
        await nextTick()

        // DOCX template бүрийг дахин render хийх
        const response = await fetch(
          `${config.public.directus.url}assets/${fileObj.id}`,
        )
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }

        const blob = await response.blob()

        // Container элемент үүсгэх
        const container = document.createElement('div')
        container.className = 'docx-content docx-block docx-page'
        container.id = `print-section-${wo.work_order.id}`

        try {
          const arrayBuffer = await blob.arrayBuffer()
          await renderAsync(arrayBuffer, container, undefined, {
            className: 'docx',
            inWrapper: true,
            ignoreWidth: false,
            ignoreHeight: false,
            ignoreFonts: false,
            breakPages: true, // Page break-г унтрааж бүх агуулгыг харуулах
            ignoreLastRenderedPageBreak: false,
            experimental: true,
            trimXmlDeclaration: true,
            useBase64URL: true,
            useMathMLPolyfill: false,
            showChanges: false,
            debug: true,
            renderHeaders: true,
            renderFooters: true,
            renderFootnotes: true,
            renderEndnotes: true,
            renderComments: false,
            // Зураг болон элементүүдийг илүү сайн харуулах
            renderDrawings: true,
            renderShapes: true,
            renderMath: true,
          })

          // DOM-д нэмэх
          await nextTick()
          const print_body = document.getElementById('print-body')
          // console.log(`Found `, print_body)

          //DOCX render → container append
          const printDoc = document.getElementById('printDoc')
          if (!printDoc) return

          isDocxLoaded.value = true

          // ➤ Render болсон DOM доторх бүх element-уудыг шалгаж placeholder-ийг textContent-оор арилгана
          let request_info = null
          request_info = wo.order_items[0]?.request_info
            ? wo.order_items[0]?.request_info.replace(/<[^>]*>/g, '')
            : null
          if (request_info && request_info.includes('undefined')) {
            request_info = request_info.replace('undefined', '').trim()
          }

          // ---- placeholders mapping ----
          const placeholders = {
            '{{CN1.1}}': wo.work_order.wo_number ?? '#',
            '{{CN1.2}}': wo.work_order.name ?? 'No name',
            '{{CN2}}': wo.work_order.safety_notes ?? 'No Safety Notes',
            '{{CN3}}': wo.work_order.history_description ?? 'No description',
            '{{CN4}}': wo.work_order.asset?.name ?? 'No Asset-info',
            '{{CN5}}':
              `location:${wo.work_order.location?.name}` ?? 'No location-info',
            '{{CN6.1}}':
              `${formatDates(wo.work_order.created_at)}` ?? 'No Created',
            '{{CN6.2}}':
              `${formatDates(wo.work_order.started_at)}` ?? 'No started_at',
            '{{CN6.3}}': `Due: ${formatDates(wo.work_order.due)}` ?? 'No due',
            '{{CN6.4}}':
              `${formatDates(wo.work_order.completed_at)}` ?? 'No completed_at',
            '{{CN7}}': `${priority.label}` ?? 'No priority',
            '{{CN8}}': `${wo_status.name}` ?? 'No wo_status',
            '{{CN9}}': request_info ?? 'No RequestInfo',
            '{{CN10}}': wo.work_order.assigned_team?.name ?? 'No teams',
            '{{CN11.1}}': wo.work_order.user_created?.first_name ?? 'No user',
            '{{CN11.2}}': wo.work_order.user_created?.role.name ?? 'No role',
            '{{CN11.3}}':
              wo.work_order.assigned_to?.first_name ?? 'No assigned_to',
            '{{CN11.4}}': wo.work_order.assigned_to?.role.name ?? 'No role',
            '{{CN12}}': cn12HTML,
            '{{CN13}}': '', //StaticValue breakdown
            '{{CN14.1}}': cn14_1HTML,
            '{{CN14.2}}': cn14_2HTML,
            '{{CN14.3}}': cn14_3HTML,
            '{{CN15.1}}': cn15_1HTML,
            '{{CN15.2}}': cn15_2HTML,
            '{{CN15.3}}': cn15_3HTML,
            '{{CN15.4}}': cn15_4HTML,
            '{{CN15.5}}': cn15_5HTML,
          }

          // Шинэ replacement функцуудыг ашиглах
          replaceTextPlaceholders(container, placeholders)
          replaceHtmlBlocks(container, placeholders)
          // Append this WO block
          printDoc.appendChild(container)

          // Add page break хооронд нь
          if (idx < wo_items.length - 1) {
            const pageBreak = document.createElement('div')
            pageBreak.style.pageBreakAfter = 'always'
            printDoc.appendChild(pageBreak)
          }
        } catch (renderError) {
          console.error('Error during DOCX rendering:', renderError)

          // Резерв арга - mammoth ашиглах
          console.log('Trying fallback method with mammoth...')
          await loadDocxMammoth(fileObj)
        }
      }
    }
  } catch (error) {
    console.error('Error loading DOCX file:', error)
  }
}

// Mammoth функц - резерв арга - сайжруулсан
const loadDocxMammoth = async (fileObj) => {
  try {
    console.log('Loading with mammoth...')

    const response = await fetch(
      `${config.public.directus.url}assets/${fileObj.id}`,
    )
    const blob = await response.blob()

    const reader = new FileReader()
    reader.onload = async () => {
      try {
        const result = await mammoth.convertToHtml({
          arrayBuffer: reader.result,
          // Mammoth-ын тохиргоо нэмэх
          convertImage: mammoth.images.imgElement(function (image) {
            return image.read('base64').then(function (imageBuffer) {
              return {
                src: 'data:' + image.contentType + ';base64,' + imageBuffer,
              }
            })
          }),
          includeDefaultStyleMap: true,
          includeEmbeddedStyleMap: true,
        })

        if (result.value) {
          // HTML агуулгыг сайжруулах
          let htmlContent = result.value

          // Checkbox-уудыг зөв харуулах
          htmlContent = htmlContent.replace(
            /☐/g,
            '<input type="checkbox" style="margin-right: 5px;">',
          )
          htmlContent = htmlContent.replace(
            /☑/g,
            '<input type="checkbox" checked style="margin-right: 5px;">',
          )
          htmlContent = htmlContent.replace(
            /✓/g,
            '<input type="checkbox" checked style="margin-right: 5px;">',
          )

          docxContent.value = `
            <div class="docx-block docx-content docx-page mammoth-content">
              ${htmlContent}
            </div>
          `

          await nextTick()

          const printBody = document.getElementById('print-body')
          const printDoc = document.getElementById('printDoc')
          // const printDoc = printBody.querySelector('#printDoc')
          if (printDoc) {
            printDoc.innerHTML = docxContent.value
            isDocxLoaded.value = true
            console.log('Mammoth content loaded successfully')

            // Зураг load болсон эсэхийг шалгах
            const images = printDoc.querySelectorAll('img')
            console.log(`Mammoth loaded ${images.length} images`)

            // CSS style нэмэх зургуудад
            images.forEach((img) => {
              img.style.maxWidth = '100%'
              img.style.height = 'auto'
            })
          }
        }

        if (result.messages && result.messages.length > 0) {
          console.log('Mammoth messages:', result.messages)
        }
      } catch (convertError) {
        console.error('Mammoth conversion error:', convertError)

        // Хамгийн сүүлийн арга - HTML template ашиглах
        await loadFallbackTemplate()
      }
    }

    reader.onerror = () => {
      console.error('FileReader error')
      loadFallbackTemplate()
    }

    reader.readAsArrayBuffer(blob)
  } catch (error) {
    console.error('Error in mammoth fallback:', error)
    await loadFallbackTemplate()
  }
}

// Fallback template - DOCX load амжилтгүй бол энийг ашиглах
const loadFallbackTemplate = async () => {
  console.log('Using fallback template...')

  const fallbackContent = `
    <div class="docx-block docx-content docx-page fallback-content">
      <div style="text-align: center; margin-bottom: 20px;">
        <h2>Ажлын захиалгын маягт</h2>
        <p>Ажлын захиалга: <input type="text" style="border: 1px solid #ccc; padding: 2px;" /></p>
        <p>Огноо: <input type="text" style="border: 1px solid #ccc; padding: 2px;" /></p>
      </div>

      <div style="margin: 15px 0;">
        <h3>Ажлын тайлбар</h3>
        <textarea style="width: 100%; height: 60px; border: 1px solid #ccc; padding: 5px;"></textarea>
      </div>

      <div style="margin: 15px 0;">
        <h3>Ажилтны мэдээлэл</h3>
        <table style="width: 100%; border-collapse: collapse;">
          <tr>
            <td style="border: 1px solid #ccc; padding: 5px;">Хэсэг:</td>
            <td style="border: 1px solid #ccc; padding: 5px;"></td>
            <td style="border: 1px solid #ccc; padding: 5px;">Нэр:</td>
            <td style="border: 1px solid #ccc; padding: 5px;"></td>
          </tr>
          <tr>
            <td style="border: 1px solid #ccc; padding: 5px;">Утас:</td>
            <td style="border: 1px solid #ccc; padding: 5px;"></td>
            <td style="border: 1px solid #ccc; padding: 5px;">Засварчин:</td>
            <td style="border: 1px solid #ccc; padding: 5px;"></td>
          </tr>
        </table>
      </div>

      <div style="margin: 15px 0;">
        <h3>Ажил гүйцэтгэсэн статус</h3>
        <div style="display: grid; grid-template-columns: repeat(5, 1fr); gap: 10px;">
          <label><input type="checkbox"> Бүрэн дууссан</label>
          <label><input type="checkbox"> Дахин үргэлжлэх</label>
          <label><input type="checkbox"> Сэлбэг байхгүй</label>
          <label><input type="checkbox"> Цуцалсан</label>
          <label><input type="checkbox"> Аюулгүй ажиллагаа</label>
        </div>
      </div>

      <div style="margin: 15px 0;">
        <h3>Ажлын дүгнэлт</h3>
        <div style="margin: 10px 0;">
          <label><input type="checkbox"> Хувийн цоож пайзаа авсан уу?</label>
        </div>
        <div style="margin: 10px 0;">
          <label><input type="checkbox"> Ажлын дараа хог хаягдлаа цэвэрлэсэн үү?</label>
        </div>
        <div style="margin: 10px 0;">
          <label><input type="checkbox"> Ажил дуусаад ажлын байраа шалгаж баталгаажуулсан уу?</label>
        </div>
      </div>

      <div style="margin: 15px 0;">
        <h3>Ажлыг хаах баталгаажуулалт</h3>
        <table style="width: 100%; border-collapse: collapse; margin-top: 10px;">
          <tr>
            <td style="border: 1px solid #ccc; padding: 5px;">Нэр:</td>
            <td style="border: 1px solid #ccc; padding: 5px;"></td>
            <td style="border: 1px solid #ccc; padding: 5px;">Ажилласан цаг:</td>
            <td style="border: 1px solid #ccc; padding: 5px;"></td>
          </tr>
          <tr>
            <td style="border: 1px solid #ccc; padding: 5px;">Ажил дууссан огноо:</td>
            <td style="border: 1px solid #ccc; padding: 5px;"></td>
            <td style="border: 1px solid #ccc; padding: 5px;">Гарын үсэг:</td>
            <td style="border: 1px solid #ccc; padding: 5px;"></td>
          </tr>
        </table>
      </div>

      <div style="text-align: center; margin-top: 20px; color: #666; font-size: 12px;">
        <p>DOCX файл load хийхэд алдаа гарсан тул энгийн маягт харуулж байна.</p>
      </div>
    </div>
  `

  const printBody = document.getElementById('print-body')
  const printDoc = document.getElementById('printDoc')

  if (printDoc) {
    printDoc.innerHTML = fallbackContent
    isDocxLoaded.value = true
    console.log('Fallback template loaded')
  }
}

const get_file_type = (file) => {
  let type = ''
  if (file?.type.includes('image')) {
    type = `image`
  } else if (file?.type.includes('video')) {
    type = 'video'
  } else if (file?.type.includes('word')) {
    type = 'doc'
  } else if (file?.type.includes('pdf')) {
    type = 'pdf'
  } else if (file?.type.includes('sheet')) {
    type = 'xlsx'
  } else if (file?.type.includes('pptx')) {
    type = 'pptx'
  }
  return type
}

const preparePagesForPdf = () => {
  // 1. Хуучин pagebreak-үүдийг устгана
  document.querySelectorAll('.pagebreak').forEach((el) => el.remove())

  // 2. Хэвлэх шаардлагатай бүх хуудсыг цуглуулна
  const allPages = Array.from(
    document.querySelectorAll(
      '.canvas-page, .image-page, .print-page, .docx-page, .excel-page',
    ),
  ).filter((el) => {
    const parent = el.parentElement
    return parent && getComputedStyle(parent).display !== 'No'
  })

  // 3. Сүүлчийн элементээс бусдад pagebreak нэмэх
  allPages.forEach((page, index) => {
    if (index !== allPages.length - 1) {
      const pageBreak = document.createElement('div')
      pageBreak.className = 'pagebreak'
      page.parentNode.insertBefore(pageBreak, page.nextSibling)
    }
  })
}

const printBodyTemplate = (tailwinds, content) => `
  <html>
      <head>
      <title>Print Preview</title>
          ${tailwinds}
          <style>
            @media print {
              body { margin: 0; padding: 0; }
                .print-body    {
                  padding: 10px 50px;
                  width: 210mm;
                  display: table;
                  border: 1px solid gray;
                  height: 100%;
                  margin: auto;
              }
              .pdf-container canvas {
                max-width: 100%;
                width: 210mm !important;
                height: 297mm !important;
                page-break-inside: avoid;
              }
               .pdf-container img {
                width: 210mm !important;
                height: 297mm !important;
                max-width: 100%;
                page-break-inside: avoid;
              }
              .print-page { page-break-after: always; }
              .print-page:last-child { page-break-after: auto; }
              @page { margin: 2px; }
              .pdf-container { margin: 10px 0; }
              .pdf-container h3 { margin-bottom: 10px; }
              .pagebreak {
                page-break-before: always;
                break-before: page;
                height: 0 !important;
                margin: 0 !important;
                padding: 0 !important;
              }
              .docx {

                width: 100% !important;
                height: 100% !important;
                max-width: 210mm !important;
                margin: 0 !important;
                padding: 0 !important;
                background: white;
                border: none  !important;
                box-shadow: none  !important;
              }
              .print-page:last-child,
              .a4-page:last-child {
                page-break-after: auto;
              }

              .pagebreak {
                page-break-before: always;
                break-before: page;
                height: 0 !important;
                margin: 0 !important;
                padding: 0 !important;
              }

              .pdf-container canvas {
                width: 210mm !important;
                max-width: 210mm !important;
                height: 297mm !important;
                page-break-inside: avoid;
                display: block;
              }

              .pdf-container img {
                width: 210mm !important;
                max-width: 210mm !important;
                height: 297mm !important;
                page-break-inside: avoid;
                display: block;
                margin: 0 auto;
                object-fit: contain;
              }

              .image-container img {
                width: 200mm !important;
                max-width: 210mm !important;
                max-height: 297mm !important;
                height: 600px !important;
                margin: 0 auto;
                object-fit: contain;
              }

              table {
                width: 100% !important;
                font-size: 9pt !important;
                border-collapse: collapse;
                page-break-inside: avoid;
              }

              table td, table th {
                padding: 2mm !important;
                border: 0.5pt solid #000;
                font-size: 9pt !important;
                word-wrap: break-word;
                vertical-align: top;
              }

              h1 { font-size: 14pt !important; margin: 3mm 0; }
              h2 { font-size: 12pt !important; margin: 2.5mm 0; }
              h3 { font-size: 11pt !important; margin: 2mm 0; }
              p, div, span { font-size: 10pt !important; }
              label { font-size: 9pt !important; font-weight: bold; }

              .grid {
                display: flex !important;
                flex-wrap: wrap;
                gap: 2mm;
              }

              .grid-cols-1 > div { width: 100%; }
              .grid-cols-2 > div { width: calc(50% - 1mm); }
              .grid-cols-3 > div { width: calc(33.333% - 1.33mm); }
              .grid-cols-4 > div { width: calc(25% - 1.5mm); }

              input[type="checkbox"] {
                width: 3mm !important;
                height: 3mm !important;
                margin-right: 2mm !important;
              }

              textarea {
                border: 0.5pt solid #000 !important;
                padding: 2mm !important;
                font-size: 9pt !important;
                width: 100% !important;
                box-sizing: border-box;
                resize: none;
              }

              .filsName {
                margin-top: 20px;
                font-weight: bold;
                font-size: 12pt;
                color: #333;
              }

              .docx-content, .excel-block, .image-block, .pdfTocanvas-block, .canvasToImg-block  {
                padding: 10mm;
                background-color: white;
                font-size: 10pt;
                word-wrap: break-word;
                overflow-wrap: break-word;
              }

              .canvasToImg-block img {
                width: 210mm;
                height: 297mm;
                display: block;
                margin: 0 auto;
                page-break-inside: avoid;
                break-inside: avoid;
              }
            }

            .excel-block  {
                margin-bottom: 50px;
              }

            .printBttn {
              text-align: center;
              position: absolute;
              width: 80px;
              border: 1px solid gray;
              border-radius: 6px;
              cursor:pointer;
            }

            .docx-wrapper {
              background: none !important;
            }

            .docx {
              width: 100% !important;
              height: 100% !important;
              max-width: 210mm !important;
              margin: 0 !important;
              padding: 0 !important;
              background: white;
              border: none  !important;
              box-shadow: none  !important;
            }
            .pdf-container img {
                width: 210mm !important;
                max-width: 297mm !important;
                height: 297mm !important;
                page-break-inside: avoid;
                display: block;
                margin: 0 auto;
                object-fit: contain;
            }
            .pdf-container .pagebreak {
                page-break-before: always;
                break-before: page;
                height: 0px !important;
                margin: 0 !important;
                padding: 0 !important;
                border-bottom: 0.5px solid red;
                border-style: dashed;
              }
            .pagebreak {
              page-break-before: always;
              break-before: page;
              height: 0 !important; /* илүү зай авхыг хориглоно */
              margin: 0 !important;
              padding: 0 !important;
            }

          @page {
            size: A4;
            margin: 0;
            padding: 0;
          }
          </style>
      <body class="bg-white">
        <div class="print-body" style="
                padding: 10px 50px;
                  width: 210mm;
                  display: table;
                  border: 1px solid #d1cbcb;
                  height: 100%;
                  margin: auto;">
          ${content}
        </div>
      </body>
    </html>
  `

const previews = async () => {
  // console.log('print', selectedWorkOrders.value)

  // if (selectedWorkOrders.value.length === 0) {
  //   alert('Хэвлэх work order сонгоно уу!')
  //   return
  // }

  selectedWorkOrders.value.forEach((workOrderId) => {
    convertCanvasToImage(workOrderId)
  })

  // ✅ Page-үүдийг цэгцлэх
  preparePagesForPdf()

  // realtime
  const printContents = document.getElementById('printDoc').innerHTML

  const tailwindCDN =
    '<link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">'
  const printBody = printBodyTemplate(tailwindCDN, printContents)

  const printWindow = window.open('', '_blank')
  if (printWindow) {
    printWindow.document.open()
    printWindow.document.write(printBody)
    printWindow.document.close()
    printWindow.onload = () => {
      // printWindow.print()
      // printWindow.close()
      console.log('by3')
      const ImgBlock = document.querySelector('.canvasToImg-block')
      const canvasBlock = document.querySelector('.pdfTocanvas-block')

      document.querySelectorAll('.canvasToImg-block').forEach((block) => {
        block.style.display = 'block'
      })

      document.querySelectorAll('.pdfTocanvas-block').forEach((block) => {
        block.style.display = 'none'
      })

      // if (canvasBlock) {
      //   canvasBlock.style.display = 'block'
      // }

      // if (ImgBlock) {
      //   ImgBlock.style.display = 'none'
      // }

      // const printBttn = document.createElement('div')
      // printBttn.className = 'printBttn'
      // printBttn.textContent = `Print`
      // printBttn.style.textAlign = 'center'
      // printWindow.document.body.prepend(printBttn)

      // const printBtn = document.querySelector('.printBttn')
      // printBtn.addEventListener('click', () => {
      //   console.log('hey')
      //   printWindow.print()
      // })
    }
  } else {
    console.error('Failed to open the print window.')
  }
}

const convertCanvasToImage = (workOrderId) => {
  // Тухайн ажилд харгалзах print section-г олно
  const printSection = document.getElementById('printDoc')

  if (!printSection) {
    console.log('Print section олдсонгүй:', workOrderId)
    return
  }

  // Тухайн print section доторх canvas-уудыг авна
  const canvases = printSection.querySelectorAll('canvas')

  // canvasToImg-block-ийг тухайн print section дотроос авна
  const ImgBlock = printSection.querySelector('.canvasToImg-block')
  const canvasBlock = printSection.querySelector('.pdfTocanvas-block')

  // console.log('ImgBlock', ImgBlock)
  if (!ImgBlock) {
    console.log('canvasToImg-block олдсонгүй:', workOrderId)
    return
  }

  ImgBlock.innerHTML = ''
  ImgBlock.style.display = 'block'

  if (canvasBlock) {
    canvasBlock.style.display = 'none'
  }

  document.querySelectorAll('.canvasToImg-block').forEach((block) => {
    block.style.display = 'block'
  })

  document.querySelectorAll('.pdfTocanvas-block').forEach((block) => {
    block.style.display = 'none'
  })

  // ✅ PDF гарчиг нэмж DOM-д оруулна
  // const pdfTitle = document.createElement('div')
  // pdfTitle.className = 'filsName'
  // pdfTitle.textContent = `PDF файл: WO#${workOrderId}`
  // pdfTitle.style.textAlign = 'center'
  // pdfTitle.style.margin = '20px 0'
  // ImgBlock.appendChild(pdfTitle)

  canvases.forEach((originalCanvas) => {
    const a4Canvas = document.createElement('canvas')
    a4Canvas.width = 790
    a4Canvas.height = 1110
    const a4Ctx = a4Canvas.getContext('2d')
    a4Ctx.drawImage(originalCanvas, 0, 0, a4Canvas.width, a4Canvas.height)

    const image = new Image()
    image.src = a4Canvas.toDataURL('image/png')
    image.style.width = '790px'
    image.style.height = '1110px'
    image.style.display = 'block'
    image.style.margin = '0 auto'
    image.style.pageBreakInside = 'avoid'
    image.style.breakInside = 'avoid'
    image.className = 'image-page'

    ImgBlock.appendChild(image)
  })
}

const convertPdtToCanvas = async (pdfUrl, containerElement, title) => {
  try {
    const response = await fetch(pdfUrl)
    const blob = await response.blob()
    const arrayBuffer = await blob.arrayBuffer()

    const loadingTask = pdfjsLib.getDocument({ data: arrayBuffer })
    const pdf = await loadingTask.promise

    containerElement.innerHTML = ''

    // ✅ Title-г canvas-уудаас өмнө хадгалж нэмж өгнө
    if (title) {
      containerElement.appendChild(title)
    }

    const A4_WIDTH = 790
    const A4_HEIGHT = 1110

    for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {
      const page = await pdf.getPage(pageNum)

      const unscaledViewport = page.getViewport({ scale: 1 })
      const scaleX = A4_WIDTH / unscaledViewport.width
      const scaleY = A4_HEIGHT / unscaledViewport.height
      const scale = Math.min(scaleX, scaleY)

      const viewport = page.getViewport({ scale })
      const canvas = document.createElement('canvas')
      canvas.width = A4_WIDTH
      canvas.height = A4_HEIGHT
      canvas.className = 'uploaded-file canvas-page'

      canvas.style.display = 'block'
      canvas.style.margin = '-20px 0px 0px 0px'
      canvas.style.border = '1px solid #ddd'
      canvas.style.width = '100%'

      const context = canvas.getContext('2d')
      context.save()
      const offsetX = (A4_WIDTH - viewport.width) / 2
      const offsetY = (A4_HEIGHT - viewport.height) / 2
      context.translate(offsetX, offsetY)

      await page.render({
        canvasContext: context,
        viewport: viewport,
      }).promise
      context.restore()

      containerElement.appendChild(canvas)
    }
  } catch (error) {
    console.error('Error rendering PDF pages:', error)
  }
}

const onAfterPrint = () => {
  console.log('Хэвлэх дууссан!')
}

// Зөвхөн сонгогдсон work order-уудын файлуудыг render хийх функц
const renderSelectedFiles = async () => {
  await nextTick()

  try {
    // // Бүх файл container-уудыг цэвэрлэх
    work_orders.value.forEach((entry) => {
      const containerId = `print-section-${entry.work_order.id}`
      const parentContainer = document.getElementById(containerId)
      if (parentContainer) {
        // Зөвхөн файлын container-уудыг цэвэрлэх (үндсэн мэдээллийг хадгалах)
        const fileContainers =
          parentContainer.querySelectorAll('.uploaded-file')
        fileContainers.forEach((container) => container.remove())
      }
    })

    // console.log('selectedWorkOrders', selectedWorkOrders)
    // Зөвхөн сонгогдсон work order-уудын файлуудыг render хийх
    const renderPromises = work_orders.value
      .filter((entry) => selectedWorkOrders.value.includes(entry.work_order.id))
      .map(async (entry) => {
        const { files } = entry
        const containerId = `print-section-${entry.work_order.id}`
        const parentContainer_file = document.getElementById(containerId)
        const parentContainer = document.getElementById('printDoc')

        console.log('parentContainer_file', parentContainer_file)

        if (!parentContainer_file) {
          console.log(
            'Container not found for work_order:',
            entry.work_order.id,
          )
          return
        }

        // Файлуудыг parallel загвараар боловсруулах
        const filePromises = files.map(async (item) => {
          const file = item.file
          const type = get_file_type(file)

          try {
            switch (type) {
              case 'doc':
                await loadDocxFile(file, item, parentContainer_file)
                break
              case 'xlsx':
                await loadExcelFile(file, item, parentContainer_file)
                break
              case 'pdf':
                await loadPdfFile(file, item, parentContainer_file)
                break
              case 'image':
                await loadImageFile(file, item, parentContainer_file)
                break
              default:
                console.log('Unsupported file type:', type, file)
            }
          } catch (error) {
            console.error(`Error loading ${type} file:`, error, file)
          }
        })

        await Promise.all(filePromises)
      })

    await Promise.all(renderPromises)
    console.log('All selected files rendered successfully')
  } catch (error) {
    console.error('Error in renderSelectedFiles:', error)
  }
}

// DOCX файл ачаалах функц
const loadDocxFile = async (fileObj, item, parentContainer) => {
  const response = await fetch(
    `${config.public.directus.url}assets/${fileObj.id}`,
  )
  const blob = await response.blob()
  const container = document.createElement('div')
  container.className = 'docx-content docx-block docx-page uploaded-file'

  const title = document.createElement('div')
  title.className = 'filsName'
  const filename =
    fileObj.filename_download || fileObj.name || `Файл ID: ${fileObj.id}`
  title.textContent = `DOC файл: WO#${item.work_order} - ${filename}`

  const previewContainer = document.createElement('div')
  const arrayBuffer = await blob.arrayBuffer()
  await renderAsync(arrayBuffer, previewContainer)

  container.appendChild(title)
  container.appendChild(previewContainer)
  parentContainer.appendChild(container)
}

// Excel файл ачаалах функц
const loadExcelFile = async (fileObj, item, parentContainer) => {
  return new Promise((resolve, reject) => {
    fetch(`${config.public.directus.url}assets/${fileObj.id}`)
      .then((response) => response.blob())
      .then((blob) => {
        const reader = new FileReader()
        reader.onload = () => {
          try {
            const workbook = XLSX.read(reader.result, { type: 'binary' })
            const html = XLSX.utils.sheet_to_html(
              workbook.Sheets[workbook.SheetNames[0]],
            )

            const excelDiv = document.createElement('div')
            excelDiv.className = 'excel-block excel-page a4-page uploaded-file'
            excelDiv.innerHTML = `
              <h3 class="filsName">Excel файл: WO#${item.work_order} - ${fileObj.filename_download}</h3>
              ${html}
            `
            parentContainer.appendChild(excelDiv)
            resolve()
          } catch (error) {
            reject(error)
          }
        }
        reader.onerror = () => reject(new Error('Failed to read Excel file'))
        reader.readAsBinaryString(blob)
      })
      .catch(reject)
  })
}

// PDF файл ачаалах функц
const loadPdfFile = async (file, item, parentContainer) => {
  const url_pdf = `${config.public.directus.url}assets/${file.id}`
  const pdfContainer = document.createElement('div')
  pdfContainer.className = 'pdf-container pdfTocanvas-block  uploaded-file'

  const title = document.createElement('div')
  title.className = 'filsName'
  title.textContent = `PDF файл: WO#${item.work_order} - ${file.filename_download}`
  pdfContainer.appendChild(title)

  await convertPdtToCanvas(url_pdf, pdfContainer, title)

  // canvasToImg-block үүсгэх
  const imgContainer = document.createElement('div')
  imgContainer.className =
    'pdf-container canvasToImg-block hidden uploaded-file'

  parentContainer.appendChild(pdfContainer)
  parentContainer.appendChild(imgContainer)
}

// Зураг файл ачаалах функц
const loadImageFile = async (file, item, parentContainer) => {
  return new Promise((resolve, reject) => {
    const url = `${config.public.directus.url}assets/${file.id}`
    const imageContainer = document.createElement('div')
    imageContainer.className =
      'image-container image-block a4-page uploaded-file'

    const title = document.createElement('div')
    title.className = 'filsName'
    title.textContent = `Зураг файл: WO#${item.work_order} - ${file.filename_download}`

    const img = document.createElement('img')
    img.src = url
    img.alt = file.filename_download
    img.style.maxWidth = '100%'
    img.style.margin = '0 auto'
    img.className = 'image-page'

    // Зураг ачаалагдахыг хүлээх
    img.onload = () => {
      imageContainer.appendChild(title)
      imageContainer.appendChild(img)
      parentContainer.appendChild(imageContainer)
      resolve()
    }

    img.onerror = () => {
      console.error('Failed to load image:', url)
      reject(new Error(`Failed to load image: ${file.filename_download}`))
    }
  })
}

// Optimized watcher with debouncing
const debouncedRenderSelectedFiles = debounce(renderSelectedFiles, 300)

onMounted(async () => {
  console.log('wo_ids', wo_ids)

  if (wo_ids) {
    loading.value = true
    isDocxLoaded.value = false

    let rawData = []
    rawData = [...new Set(wo_ids)]
    console.log('rawDatas', rawData)

    // ⚠️ Promise.all ашиглаж бүгдийг зэрэг татах
    const promises = rawData.map(async (id) => {
      try {
        console.log('promisesid', id)

        const [work_order] = await getItems({
          collection: 'Work_order',
          params: {
            filter: { id: { _eq: id } },
            fields: [
              '*',
              'assigned_team.name',
              'assigned_to.*',
              'assigned_to.role.name',
              'location.name',
              'asset.name',
              'user_created.first_name',
              'user_created.role.name',
              'request_user.first_name',
              'request_user.role.name',
            ],
          },
        })

        const order_items = await getItems({
          collection: 'Work_order_item',
          params: {
            filter: { workorder: { _eq: id } },
            fields: ['*'],
          },
        })

        const work_trade = await getItems({
          collection: 'Work_order_Tradecode',
          params: {
            filter: { work_order: { _eq: id } },
            fields: ['*', 'trade.*'],
          },
        })

        const work_parts = await getItems({
          collection: 'Work_order_Parts',
          params: {
            filter: { work_order: { _eq: id } },
            fields: ['*', 'parts.*'],
          },
        })

        const files = await getItems({
          collection: 'Work_order_files',
          params: {
            filter: { work_order: { _eq: id } },
            fields: ['*', 'file.*'],
          },
        })
        loading.value = false
        return {
          work_order,
          order_items,
          files,
          work_trade,
          work_parts,
        }
      } catch (error) {
        console.error('Алдаа:', error)
        return null
      }
    })

    const result = await Promise.all(promises)
    console.log('result', result)

    // Зөвхөн null биш утгуудыг хадгалах
    work_orders.value = result.filter((r) => r !== null)
    console.log('work_orderswork_orders', work_orders)

    try {
      const filters = { active: 1 }
      const items = await getItems<any>({
        collection: 'Prints_tempates',
        params: {
          filter: filters,
          limit: 1,
          meta: 'filter_count',
          fields: ['*', 'uploaded.*'],
        },
      })
      Prints_tempates.value = items.data
      console.log('Templates loaded:', items.data)

      if (items.data.length && items.data[0].uploaded) {
        const url_template = `${config.public.directus.url}assets/${items.data[0].uploaded.id}`
        console.log('Loading template from:', url_template)

        // DOCX файл ачаалах
        await loadDocxB(items.data[0].uploaded)
      } else {
        console.log('No template file found')
      }
    } catch (e) {
      console.error('Error loading templates:', e)
    }

    loading.value = false
  }
})

// Computed properties нэмэх
// const filteredWorkOrders = computed(() =>
//   work_orders.value.filter((item) =>
//     selectedWorkOrders.value.includes(item.work_order.id),
//   ),
// )

// realtime Checkbox өөрчлөгдөх үед файлуудыг дахин render хийх watcher
watch(
  selectedWorkOrders,
  async (newValue, oldValue) => {
    console.log('Selected work orders changed:', newValue)
    await debouncedRenderSelectedFiles()
  },
  { deep: true },
)

// Debounce utility function
function debounce(func, wait) {
  let timeout
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout)
      func(...args)
    }
    clearTimeout(timeout)
    timeout = setTimeout(later, wait)
  }
}

const back = () => {
  open('workorderopenmore', {
    id: wo_ids,
    data: work_orders.value[0].work_order,
    wo_statuses: wo_statuses,
    type: wo_type,
    refresh: refresh,
  })
}

window.onafterprint = onAfterPrint
</script>

<template>
  <div
    id="print-body"
    class="print-body htmlContent border-muted-200 dark:border-muted-700 dark:bg-muted-800 border bg-white w-[80%] overflow-y-scroll"
  >
    <div class="flex h-16 w-full items-center justify-start px-10 no-print">
      <button
        type="button"
        class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300 dark:hover:text-white"
        @click="close"
      >
        <Icon name="line-md:close" class="h-5 w-5" />
      </button>
      <button
        type="button"
        class="text-muted-400 hover:bg-muted-100 hover:text-muted-600 dark:hover:bg-muted-700 flex h-10 w-10 items-center justify-center rounded-full transition-colors duration-300 dark:hover:text-white"
        @click="back"
      >
        <Icon name="feather:chevron-right" class="h-6 w-6" />
      </button>

      <BaseButton color="primary" class="ml-5" @click="previews">{{
        t('Print')
      }}</BaseButton>
    </div>

    <div
      v-if="loading"
      class="flex items-center justify-center h-32 w-full text-gray-500"
    >
      <div class="flex flex-col items-center">
        <div
          class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"
        ></div>
        <p class="mt-2">{{ t('Loading work orders...') }}</p>
      </div>
    </div>
    <div id="prints">
      <div class="chooseFile">
        <div
          v-if="work_orders.length"
          v-for="(items, index) in work_orders"
          :key="items.work_order.id"
          :id="`print-wo-files-${items.work_order.id}`"
          class="print-wo-files"
        >
          <div class="flex text-base cursor-pointer items-center">
            <div class="text-black">WO:&nbsp;</div>
            <div class="text-black">#{{ items.work_order.wo_number }}</div>
            <div class="text-blue-500 text-xs">
              ( {{ items.files.length }} {{ t('file') }} )
            </div>

            <div class="checkBox ml-2 mt-2">
              <input
                type="checkbox"
                :id="'status-' + index"
                :value="items.work_order.id"
                v-model="selectedWorkOrders"
                class="w-4 h-4 cursor-pointer"
              />
            </div>
          </div>
        </div>
      </div>

      <div ref="printArea" class="printArea" id="printDoc">
        <div
          v-if="work_orders.length"
          v-for="(items, index) in work_orders"
          :key="items.work_order.id"
          :id="`print-section-${items.work_order.id}`"
          class="print-container print-section"
        >
          <!-- DOCX контент энд харагдана -->
        </div>
        <!-- Mammoth fallback content -->
        <div
          v-if="docxContent && !isDocxLoaded"
          class="print-container mt-8 p-4 border"
          v-html="docxContent"
        ></div>
        <div class="pdf-container canvasToImg-block hidden"></div>
      </div>
    </div>
  </div>
</template>

<style>
.chooseFile {
  max-width: 193mm;
  margin: 0px auto 40px auto;
}
.printArea {
  max-width: 265mm;
  margin: 0 auto;
  box-sizing: border-box;
  page-break-after: avoid;
  break-after: avoid;
  overflow: hidden;
  font-size: 11pt;

  /* background: #f5f5f5; */
  /* padding: 10mm; */
}
#print-body {
  /* width: 100% !important; */
  margin: 0 !important;
  padding: 0 !important;
  visibility: visible;
  /* overflow: visible; */
  border: none;
  background: white;
}
.print-container {
  width: 100%;
  margin: 0;
  padding: 10px 40px;
  font-size: 11pt;
}
/* A4 Page Dimensions  A4-ийн стандарт өндөр*/
.a4-page {
  width: 210mm;
  height: 295mm;
  max-height: 295mm;
  max-width: 210mm;
  /* margin: 0 auto 10mm auto; */
  padding: 8mm;
  background: white;
  font-size: 11pt;
  line-height: 1.4;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
  page-break-inside: avoid;
  box-sizing: border-box !important;
  page-break-after: auto !important;
  break-after: auto !important;
  overflow: hidden !important;
}

/* File content styling */
.docx-block,
.excel-block,
.image-block,
.pdfTocanvas-block {
  padding: 20px;
  background-color: white;
  font-size: 10pt;
  word-wrap: break-word;
  overflow-wrap: break-word;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
  border: 1px solid #ccc;
  width: 100%;
}

.pdfTocanvas-block {
  padding: 0px !important;
}

.filsName {
  margin-bottom: 5mm;
  font-weight: bold;
  font-size: 10pt;
  color: #333;
}

.docx-block .filsName {
  margin-bottom: 0mm !important;
}

/* excel content adjustments */
.excel-block {
  white-space: normal;
  width: 100%;
  overflow: hidden;
  padding: 20px;
  box-shadow: none;
  margin: 0;
  margin-bottom: 50px;
  page-break-after: avoid;
  break-after: avoid;
  /* height: auto;
    overflow: visible;
    min-height: auto; */
}

.excel-block table {
  width: 100%;
  font-size: 8pt;
  border-collapse: collapse;
  page-break-inside: avoid;
  break-inside: avoid;
}

.excel-block table td {
  padding: 1mm;
  border: 0.5pt solid #ccc;
  font-size: 8pt;
  word-break: break-word;
}

/* DOCX content adjustments */
.docx-wrapper {
  background: none !important;
  padding: 0 !important;
  margin: 0;
  width: 100% !important;
  height: 100% !important;
}

.docx-wrapper .docx {
  width: 100% !important;
  max-width: 240mm !important;
  padding: 0 !important;
  margin: 0;
}

.docx-wrapper .docx p {
  margin: 2mm 0 !important;
  font-size: 10pt !important;
  line-height: 1.3;
}

.docx-wrapper .docx table {
  width: 95% !important;
  font-size: 9pt !important;
}

.docx-wrapper .docx table tr {
  height: auto !important;
}

.docx-wrapper > section.docx {
  background: none !important;
  box-shadow: none !important;
  padding: 0 !important;
  margin: 0;
}

/* Image container */
.image-container {
  text-align: center;
  margin: 0;
  padding: 20px;
  display: flex;
  flex-direction: column;
  justify-content: flex-start;
  /* height: auto;
  min-height: auto; */
  page-break-after: avoid;
  break-after: avoid;
}

.image-container img {
  max-width: 100%;
  height: 600px;
  width: auto;
  /* border: 0.5pt solid #ccc; */
  /* width: 794px;
  height: 1122px; */
  display: block;
  margin: 0 auto;
  page-break-inside: avoid;
  break-inside: avoid;
  object-fit: contain;
}

/* PDF container */
.pdf-container {
  /* margin: 5mm 0; */
  text-align: center;
  page-break-inside: avoid;
  break-inside: avoid;
  object-fit: contain;
  height: auto;
  min-height: auto;
}

.pdf-container h3 {
  margin-top: 5mm;
  margin-bottom: 5mm;
}

.canvasToImg-block img {
  width: 790px;
  height: 1110px;
  margin: 0 auto;
  page-break-inside: avoid;
  break-inside: avoid;
}

/* Page break засах */
.pagebreak {
  page-break-before: always;
  break-before: page;
  display: block;
  height: 0 !important;
  margin: 0 !important;
  padding: 0 !important;
  border: none !important;
  background: none !important;
}
/* Checkbox and form styling */
.askBox {
  border: 0.5pt solid #000;
  padding: 3mm;
}

.ask {
  font-size: 9pt;
  text-align: center;
  padding: 1mm;
}

/* Better spacing for grid layouts */
.grid-cols-3 > div {
  flex: 1;
  min-width: 0;
}

.grid-cols-2 > div {
  flex: 1;
  min-width: 0;
}

/* Print specific styles */
@media print {
  html,
  body {
    width: 210mm;
    height: 297mm;
    margin: 0;
    padding: 0;
    font-size: 11pt;
  }

  .no-print {
    display: none !important;
  }

  #print-body {
    /* width: 100% !important; */
    margin: 0 !important;
    padding: 0 !important;
    visibility: visible;
    /* overflow: visible; */
    border: none;
    background: white;
  }

  .print-container {
    width: 100%;
    margin: 0;
    padding: 10px 70px;
  }

  .a4-page {
    width: 210mm !important;
    height: 297mm !important;
    max-width: 210mm !important;
    max-height: 297mm !important;
    margin: 0 !important;
    padding: 8mm !important;
    box-sizing: border-box !important;
    page-break-after: always;
    page-break-inside: avoid;
    break-before: page;
    overflow: hidden;
    line-height: 1.4;
  }
  /*
  .print-page:last-child,
  .a4-page:last-child {
    page-break-after: auto;
  } */

  .pagebreak {
    /* page-break-after: auto; */
    page-break-before: always;
    break-before: page;
    height: 0 !important; /* илүү зай авхыг хориглоно */
    margin: 0 !important;
    padding: 0 !important;
    border: none !important;
  }

  /* PDF Canvas sizing for print */
  .pdf-container canvas {
    max-width: 210mm !important;
    height: auto !important;
    page-break-inside: avoid;
    break-inside: avoid;
    margin: 5mm 0;
    display: block;
  }

  /* Image sizing for print */
  .image-container img {
    max-width: 200mm !important;
    max-height: 250mm !important;
    height: 600px !important;
    /* width: 794px;
    height: 1122px; */
    display: block;
    margin: 0 auto;
    page-break-inside: avoid;
    break-inside: avoid;
    object-fit: contain;
  }

  /* Table adjustments */
  table {
    width: 100% !important;
    font-size: 9pt !important;
    border-collapse: collapse;
  }

  table td,
  table th {
    padding: 2mm !important;
    border: 0.5pt solid #000;
    font-size: 9pt !important;
    word-wrap: break-word;
  }

  /* Text sizing adjustments */
  h1 {
    font-size: 14pt !important;
  }
  h2 {
    font-size: 12pt !important;
  }
  h3 {
    font-size: 11pt !important;
  }
  p,
  div,
  span {
    font-size: 10pt !important;
  }
  label {
    font-size: 9pt !important;
  }

  /* Grid adjustments for print */
  .grid {
    display: block !important;
  }

  .grid-cols-1,
  .grid-cols-2,
  .grid-cols-3,
  .grid-cols-4 {
    display: block !important;
  }

  .grid > div {
    display: block !important;
    margin-bottom: 2mm;
  }

  /* Form elements */
  input[type='checkbox'] {
    width: 3mm !important;
    height: 3mm !important;
    margin-right: 2mm !important;
  }

  textarea {
    border: 0.5pt solid #000 !important;
    padding: 1mm !important;
    font-size: 9pt !important;
    min-height: 8mm !important;
  }

  @page {
    size: A4;
    margin: 0;
    padding: 0;
  }
}

/* Responsive text sizing */
@media print and (max-width: 210mm) {
  .a4-page {
    font-size: 9pt !important;
  }

  h1 {
    font-size: 12pt !important;
  }
  h2 {
    font-size: 11pt !important;
  }
  h3 {
    font-size: 10pt !important;
  }
}
</style>
