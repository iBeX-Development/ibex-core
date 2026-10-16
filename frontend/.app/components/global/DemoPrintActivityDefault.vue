<script setup lang="ts">
const { close, currentProps, open } = usePanels()
const activeTab = ref('tab-1')
let selectedStatuses = []
import { priorities } from '~/components/workorder/WorkOrderConstants'

const { getItems, updateItem, createItems } = useDirectusItems()

const loading = ref(true)
const records = ref([])

const paramId = currentProps?.value?.wo_id || null
const work_order = currentProps?.value?.work_order || null
const progress_data = currentProps?.value?.progress_data || null
const wo_statuses = currentProps?.value?.wo_statuses || null
const wo_type = currentProps?.value?.wo_type || null
const refresh = currentProps?.value?.refresh || null

let priority = null
const now = new Date()
const formattedDate = ref(
  `${now.getFullYear()}/${String(now.getMonth() + 1).padStart(2, '0')}/${String(
    now.getDate(),
  ).padStart(2, '0')}`,
)
if (work_order) {
  priority = priorities.filter(
    (p) => p.value || p.__original === work_order.priority,
  )[0]
  // console.log('priority => ', priority, work_order.priority)
}

const sdate = new Date(work_order.started_at)
const formattedSdate = `${sdate.getFullYear()}-${String(
  sdate.getMonth() + 1,
).padStart(2, '0')}-${String(sdate.getDate()).padStart(2, '0')} ${String(
  sdate.getHours(),
).padStart(2, '0')}:${String(sdate.getMinutes()).padStart(2, '0')}:${String(
  sdate.getSeconds(),
).padStart(2, '0')}`

const cdate = new Date(work_order.created_at)
const formattedCdate = `${cdate.getFullYear()}-${String(
  cdate.getMonth() + 1,
).padStart(2, '0')}-${String(cdate.getDate()).padStart(2, '0')} ${String(
  cdate.getHours(),
).padStart(2, '0')}:${String(cdate.getMinutes()).padStart(2, '0')}:${String(
  cdate.getSeconds(),
).padStart(2, '0')}`

const loadItems = async () => {
  loading.value = true

  try {
    const filters = {
      workorder: paramId,
      active: 1,
    }

    if (!paramId) {
      console.log('Cannot load items without param_id.')
      return
    }

    const items = await getItems<any>({
      collection: 'Work_order_item',
      params: {
        filter: filters,
        limit: -1,
        meta: 'filter_count',
        fields: ['*'],
        sort: ['priority'],
      },
    })

    // console.log('items.data', items.data)

    records.value = items.data
    loading.value = false
  } catch (e) {}
}

onMounted(async () => {
  loading.value = true
  const dt = await loadItems()
  loading.value = false
})

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
  'Бохирдол их ',
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

const pics1 = [
  { photo: '/img/inventory/print/1.png', name: 'Хязгаарлагдмал орчин' },
  { photo: '/img/inventory/print/2.png', name: 'Өргөлтийн ажил' },
  { photo: '/img/inventory/print/3.png', name: 'Цах.хүчдэлд нэрвэгдэх' },
  { photo: '/img/inventory/print/4.png', name: 'Орооцолдох хавчуулагдах' },
]

const pics2 = [
  { photo: '/img/inventory/print/5.png', name: 'Аюултай химийн бодист өртөх' },
  { photo: '/img/inventory/print/6.png', name: 'Өндрөөс унах' },
  {
    photo: '/img/inventory/print/7.png',
    name: 'Тэсрэх бодисын төлөвлөөгүй дэлбэрэлт',
  },
  { photo: '/img/inventory/print/8.png', name: 'Халуун хүйтний нөлөөнд өртөх' },
]

const pics3 = [
  {
    photo: '/img/inventory/print/9.png',
    name: 'Хүн тээврийн хэрэгсэлд мөргүүлэх',
  },
  { photo: '/img/inventory/print/10.png', name: 'Дээрээс биет унах' },
  { photo: '/img/inventory/print/11.png', name: 'Налуугийн нуралт' },
  { photo: '/img/inventory/print/12.png', name: 'Энерги хяналтгүй алдагдах' },
]

const pics4 = [
  {
    photo: '/img/inventory/print/13.png',
    name: 'Тээврийн хэрэгсэлд мөргөлдөх, онхолдох',
  },
  { photo: '/img/inventory/print/14.png', name: 'Цацрагийн үүсгүүр' },
  { photo: '/img/inventory/print/15.png', name: 'Галын аюул, дэлбэрэлт' },
  { photo: '/img/inventory/print/16.png', name: 'Их усны хажууд ажиллах' },
  { photo: '/img/inventory/print/17.png', name: 'Даралтат сав' },
]
const tableText1 = [
  {
    text1: 'JSA, SLAM болон шаардлагатай зөвшөөрлийн хуудсуудыг бөглөх.',
    text2: 'Эрсдлийг дутуу үнэлэх. Зөвшөөрлийн хуудсыг бөглөхгүй гүйцэтгэх.',
    text3: '',
    text4: '',
  },
  {
    text1:
      'Ажлын байртай танилцаж зөв тохирсон сэлбэг материал, багаж хэрэгслийг бэлдэх.',
    text2:
      'Халтирч унах, бүдрэх.Гар хөлөө цохих. Шаарлага хангаагүй багаж хэрэгсэл бэлдэх.',
    text3: '',
    text4: '',
  },
  {
    text1: 'Тоног төхөөрөмжийг тусгаарлах.',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: 'Үзлэгийн таг болон хавхлагыг нээх',
    text2: 'Гар хуруугаа гэмтээх, язлах',
    text3: '',
    text4: '',
  },
  {
    text1: 'Хязгаарлагдмал орон зайд орох',
    text2: 'Хүчил төрөгч дутагдаж унах ',
    text3:
      'Тусгай зөвшөөрлийг авах, зөвшөөрөлд тусгагдсан алхам, аргам хэмжээг дагаж мөрдөх. Агаарын найрлагыг хэмжиж, агаар сэлгэлт хийх, усаар цэврэлгээ хийх',
    text4: '',
  },
  {
    text1: 'Плита наах гадргууг цэвэрлэх',
    text2: 'Нүдрүү юм оруулах, цахилгаан багажинд гар хуруугаа тасдах',
    text3:
      'Нүүрний хамгаалалт ашиглах, хамгаалалтай гриндэр ашиглах цахилгаан багажны эргэлт бүрэн зогссон тохиолдолд, хамгаалалтаар доош харуулж тавих.',
    text4: '',
  },
  {
    text1: 'Цавуу зуурах',
    text2: 'Хордох , гар хурууны арьс гэмтээх ',
    text3:
      'ХАЛМ-тай танилцсан байх, хувийн хамгаалах хэрэгсэл болон шүүлтүүртэй баг хэрэглэх, резинэн гадаргуутай бээлий ашигалах',
    text4: '',
  },
  {
    text1: 'Плита наах',
    text2: 'Хордох',
    text3:
      'ХАЛМ-тай танилцсан байх, хувийн хамгаалах хэрэгсэл болон шүүлтүүртэй баг хэрэглэх',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
]

const tableText2 = [
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
  {
    text1: '',
    text2: '',
    text3: '',
    text4: '',
  },
]

const print = () => {
  console.log('print')
  const printContents = document.getElementById('print-body').innerHTML
  // const originalContents = document.body.innerHTML

  // document.body.innerHTML = printContents
  // window.print()
  // document.body.innerHTML = originalContents

  const tailwindCDN =
    '<link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">'

  const printBody = `
    <html>
      <head>
        <title>Print Preview</title>
        ${tailwindCDN}
        <style>
          @media print {
            body {
              margin: 0;
              padding: 0;
            }

            #print-body {
              width: 100%;
              margin: 0 10px;
              visibility: visible;
              position: absolute;
              top: 0;
              left: 0;
              width: 100%;
            }

            .print-page {
              page-break-after: always;
              margin: 0;
              padding: 0;
              border: none !important;

            }

            .print-page:last-child {
              page-break-after: auto;
            }
            .print-page .tasks {
            }
            .print-page .taskResult {
              height: 30px;
            }
            .print-page .title {
              background-color: #406293;
              color:black;
            }
            .print-page .emptyRow {
              height:50px
            }
            .print-page .ask {
              height: 50px;
            }
            @page {
              margin: 10px;
            }
          }
        </style>
      </head>
      <body class="bg-white">
        <div class="print-container p-6">
          ${printContents}
        </div>
      </body>
    </html>
  `

  const printWindow = window.open('', '_blank')

  if (printWindow) {
    printWindow.document.open()
    printWindow.document.write(printBody)
    printWindow.document.close()

    printWindow.onload = () => {
      printWindow.print()
      printWindow.close()
    }
  } else {
    console.error('Failed to open the print window.')
  }
}
const onAfterPrint = () => {
  console.log('Хэвлэх дууссан!')
  // window.location.reload()
}

const back = () => {
  open('workorderopenmore', {
    id: paramId,
    data: work_order,
    wo_statuses: wo_statuses,
    type: wo_type,
    refresh: refresh,
  })
}
window.onafterprint = onAfterPrint
</script>

<template>
  <div
    class="border-muted-200 dark:border-muted-700 dark:bg-muted-800 border bg-white w-[80%] overflow-y-scroll"
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
      <BaseButton color="primary" class="ml-5" @click="print">Print</BaseButton>
    </div>
    <div
      v-if="loading"
      class="flex items-center justify-center h-16 w-full text-gray-500"
    >
      Loading...
    </div>

    <div v-else class="print-body" id="print-body">
      <div class="max-w-4xl mx-auto bg-white print-page">
        <div class="flex justify-between items-center mb-4">
          <h1 class="text-xl font-bold">
            АЖЛЫН ЗАХИАЛГА:
            <span class="text-black"> {{ work_order.wo_number }}</span>
          </h1>
          <div>
            <p class="text-sm font-medium">Date: {{ formattedDate }}</p>
            <p class="text-sm font-medium">
              Бүлэг А/З дугаар: {{ work_order.wo_number }}
            </p>
          </div>
        </div>
        <!-- Page 1 -->
        <div
          class="p-8 mt-5 max-w-6xl mx-auto bg-white shadow-md border border-gray-200 print-page"
        >
          <!-- Field 1 -->
          <div class="grid grid-cols-1 gap-2 mb-4">
            <div>
              <label class="block text-sm font-medium text-gray-700"
                >Ажлын нэр</label
              >
              <div class="border border-gray-300 p-2 bg-gray-100">
                {{ work_order.name }}
              </div>
            </div>

            <!-- Field 2 -->
            <div>
              <label class="block text-sm font-medium text-gray-700"
                >ХАБ-ын санамж</label
              >
              <div class="border border-gray-300 p-2 bg-gray-100">
                Шаардлагатай гар, хөл, нүд, толгойн хамгаалах хэрэгслийг ямагт
                хэрэглэх. Гаргаж муутай болон алга болсон анхааруулах тэмдгийг
                сольж тавь. Бүх анхааруулах тэмдгийг мөрд.
              </div>
            </div>

            <!-- Field 3 -->
            <div>
              <label class="block text-sm font-medium text-gray-700"
                >Ажлын тайлбар</label
              >
              <textarea
                class="w-full border border-gray-300 p-2"
                rows="3"
              ></textarea>
            </div>
          </div>

          <!-- Field 4 -->
          <div>
            <label class="block text-sm font-medium text-gray-700"
              >Хуваарилалт</label
            >
            <div
              class="grid grid-cols-3 gap-2 mb-4 border border-gray-300 p-2 bg-gray-100"
            >
              <div class="">
                <p><strong>Ач холбогдол:</strong> {{ priority.label }}</p>
              </div>
              <div class="">
                <p><strong>Ажлын төрөл:</strong> {{ work_order.type.name }}</p>
              </div>
              <div class="">
                <p><strong>Хэсэг:</strong> Механик</p>
              </div>
              <div class="">
                <p><strong>Бүрэлдэхүүн:</strong> Not Applicable</p>
              </div>
              <div class="">
                <p>
                  <strong>Үүсгэсэн огноо:</strong>
                  {{ formattedCdate }}
                </p>
              </div>
              <div class="">
                <p><strong>Эхэлсэн огноо:</strong>{{ formattedSdate }}</p>
              </div>
            </div>
          </div>

          <!-- Field 5 -->
          <div>
            <label class="block text-sm font-medium text-gray-700"
              >Захиалагчийн мэдээлэл</label
            >
            <div
              class="grid grid-cols-3 gap-2 mb-4 border border-gray-300 p-2 bg-gray-100"
            >
              <div class="">
                <div><strong>Захиалагч:</strong></div>
                <div>...............</div>
              </div>
              <div class="">
                <div><strong>Хүсэлт баталсан:</strong></div>
                <div>...............</div>
              </div>
              <div class="">
                <div><strong>Ажил үүсгэсэн:</strong></div>
                <div>{{ formattedCdate }}</div>
              </div>
            </div>
          </div>

          <!-- Field 6 -->
          <div>
            <label class="block text-sm font-medium text-gray-700"
              >Ажилтан</label
            >
            <div
              class="grid grid-cols-3 gap-3 mb-4 border border-gray-300 p-2 bg-gray-100"
            >
              <div class="">
                <div><strong>Хэсэг:</strong></div>
                <div>
                  {{
                    work_order.assigned_to
                      ? work_order.assigned_to.location
                      : '-'
                  }}
                </div>
                <div>
                  {{
                    work_order.assigned_to
                      ? work_order.assigned_to.role?.name
                      : '-'
                  }}
                </div>
              </div>
              <div class="">
                <div><strong>Нэр:</strong></div>
                <div>
                  {{
                    work_order.assigned_to?.first_name
                      ? (work_order.assigned_to.last_name
                          ? work_order.assigned_to.last_name
                          : '.....') +
                        ' овогтой ' +
                        work_order.assigned_to.first_name
                      : 'Хуваарилсан хүн байхгүй'
                  }}
                </div>
              </div>
              <div class="">
                <div><strong>Утас:</strong></div>
                <div>.........</div>
                <div>
                  {{
                    work_order.assigned_to?.email
                      ? work_order.assigned_to.email
                      : ''
                  }}
                </div>
              </div>
            </div>
          </div>

          <!-- Field 7 -->
          <div>
            <label class="block text-sm font-medium text-gray-700"
              >Ажил гүйцэтгэсэн статус</label
            >
            <div class="grid grid-cols-3 gap-1 mb-4 border border-gray-300 p-2">
              <div v-for="(item, index) in status" :key="index">
                <input
                  type="checkbox"
                  class="mr-1"
                  :id="'status-' + index"
                  v-model="selectedStatuses"
                  :value="item"
                />
                <label :for="'status-' + index">{{ item }}</label>
              </div>
            </div>
          </div>

          <!-- Field 8 -->
          <div class="tasks">
            <label class="block text-sm font-medium text-gray-700"
              >Ажил гүйцэтгэсэн байдал</label
            >
            <div class="grid grid-cols-3 gap-1 mb-4 border border-gray-300 p-2">
              <div v-for="(item, index) in records" :key="index">
                <input
                  type="checkbox"
                  class="mr-1"
                  :id="'task-' + index"
                  :value="item.value ? true : false"
                  :checked="item.value ? true : false"
                />
                <label :for="'status-' + index">{{ item.name }}</label>
              </div>
            </div>
          </div>
        </div>

        <!-- Page 2 -->

        <div
          class="p-8 mt-5 max-w-6xl mx-auto bg-white shadow-md border border-gray-200 print-page"
        >
          <!-- Field 8 -->

          <div>
            <label class="block text-sm font-medium text-gray-700"
              >Эвдрэлийн шалтгаан</label
            >
            <div class="grid grid-cols-3 gap-1 mb-4 border border-gray-300 p-2">
              <div v-for="(item, index) in breakdown" :key="index">
                <input
                  type="checkbox"
                  class="mr-1"
                  :id="'status-' + index"
                  :value="item"
                />
                <label :for="'status-' + index">{{ item }}</label>
              </div>
            </div>
          </div>

          <!-- Field 9 -->
          <div>
            <label class="block text-sm font-medium text-gray-700 taskResult"
              >Ажлын дүгнэлт</label
            >
            <textarea
              class="w-full border border-gray-300 p-2 h-[50px]"
              rows="2"
            ></textarea>
          </div>

          <!-- Field 10 -->
          <div>
            <div
              class="grid grid-cols-3 gap-1 mb-4 border border-gray-300 askBox"
            >
              <div class="">
                <div class="h-[50px] flex justify-center ask">
                  Хувийн цоож пайзаа авсан уу?
                </div>
                <div class="flex justify-center">
                  <img
                    class="w-[50px] h-[50px]"
                    src="/img/inventory/print/photo1.png"
                  />
                </div>
                <div class="flex justify-center mt-1.5 ask">
                  <input type="checkbox" id="lock" />
                </div>
              </div>
              <div class="">
                <div class="h-[50px] flex justify-center ask">
                  Ажлын дараа хог хаягдлаа цэвэрлэсэн үү?
                </div>
                <div class="flex justify-center">
                  <img
                    class="w-[50px] h-[50px]"
                    src="/img/inventory/print/photo2.png"
                  />
                </div>
                <div class="flex justify-center mt-1.5">
                  <input type="checkbox" id="lock" />
                </div>
              </div>
              <div class="">
                <div class="h-[50px] flex justify-center">
                  Ажил дуусаад ажлын байраа шалгаж баталгаажуулсан уу?
                </div>
                <div class="flex justify-center">
                  <img
                    class="w-[50px] h-[50px]"
                    src="/img/inventory/print/photo3.png"
                  />
                </div>
                <div class="flex justify-center mt-1.5">
                  <input type="checkbox" id="lock" />
                </div>
              </div>
            </div>
          </div>

          <!-- Field 11 -->
          <div>
            <label class="block text-sm font-medium text-gray-700"
              >Ажлыг хаах баталгаажуулалт</label
            >
            <div class="grid grid-cols-2 gap-3 mb-4">
              <div
                class="grid grid-cols-3 gap-2 mb-1 border border-gray-300 p-2 bg-gray-100"
              >
                <div>Нэрс:</div>
                <div></div>
                <div>Ажилласан&nbsp;цаг:</div>

                <div>1&nbsp;___________________</div>
                <div></div>
                <div>________</div>

                <div>2&nbsp;___________________</div>
                <div></div>
                <div>________</div>

                <div>3&nbsp;___________________</div>
                <div></div>
                <div>________</div>

                <div>4&nbsp;___________________</div>
                <div></div>
                <div>________</div>
              </div>

              <div
                class="grid grid-cols-3 gap-2 mb-1 border border-gray-300 p-2 bg-gray-100"
              >
                <div>Нэрс:</div>
                <div></div>
                <div>Ажилласан&nbsp;цаг:</div>

                <div>5&nbsp;___________________</div>
                <div></div>
                <div>________</div>

                <div>6&nbsp;___________________</div>
                <div></div>
                <div>________</div>

                <div>7&nbsp;___________________</div>
                <div></div>
                <div>________</div>

                <div>8&nbsp;___________________</div>
                <div></div>
                <div>________</div>
              </div>
            </div>

            <div class="grid grid-cols-4 gap-2 mb-2">
              <div class="col-span-2">
                Ажил&nbsp;дууссан&nbsp;огноо:&nbsp;______/______/______
              </div>
              <div>Нэр:</div>
              <div>Гарын үсэг:</div>
            </div>

            <div class="grid grid-cols-4 gap-2 mb-2">
              <div class="col-span-2">
                Ажлын байрыг шалгаж, хүлээн авсан ажилтан:
              </div>
              <div>________________</div>
              <div>________________</div>
            </div>

            <div class="grid grid-cols-4 gap-2 mb-2">
              <div class="col-span-2">
                Ажлын байрыг шалгаж, хүлээн авсан ажилтан:
              </div>
              <div>________________</div>
              <div>________________</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Page 3 -->
      <div
        class="p-8 mt-5 max-w-6xl mx-auto bg-white shadow-md border border-gray-200 print-page"
      >
        <div class="grid grid-cols-4 gap-0 border border-black">
          <!-- Header -->
          <div
            class="col-span-3 border-b border-r border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            OHSE.ER.100.00.01 АЖЛЫН АЮУЛЫН ДҮН ШИНЖИЛГЭЭНИЙ МАЯГТ <br />
            JOB HAZARD ANALYSIS FORM
          </div>
          <div class="border-b border-black p-2 text-center">
            <label>No:</label>
          </div>
        </div>

        <div class="grid grid-cols-4 gap-0 border border-black">
          <!-- Row 1 -->
          <div class="border-b border-r border-black p-2 text-center">
            <label>Даалгавар/ Activity/Task:</label>
          </div>
          <div class="border-b border-r border-black p-2 text-center">
            <label>Плита наах</label>
          </div>
          <div class="border-b border-r border-black p-2 text-center">
            <label>Огноо/Date:</label>
          </div>
          <div class="border-b border-black p-2 text-center">
            <label></label>
          </div>

          <!-- Row 2 -->
          <div class="border-b border-r border-black p-2 text-center">
            <label>Байршил/ Location: </label>
          </div>
          <div class="border-b border-r border-black p-2 text-center">
            <label></label>
          </div>
          <div class="border-b border-r border-black p-2 text-center">
            <label>Ээлж/ Crew:</label>
          </div>
          <div class="border-b border-black p-2 text-center">
            <label></label>
          </div>

          <!-- Row 3 -->
          <div class="border-r border-black p-2 text-center">
            <label>Ашиглах тоног төхөөрөмжийн мэдээлэл/ Equipment:</label>
          </div>
          <div class="border-r border-black p-2 text-center">
            <label></label>
          </div>
          <div class="border-r border-black p-2 text-center">
            <label>Ажлын дугаар/Work order:</label>
          </div>
          <div class="p-2 text-center">
            <label></label>
          </div>

          <!-- Row 4 -->
          <div class="border-r border-black p-2 text-center">
            <label></label>
          </div>
          <div class="border-r border-black p-2 text-center">
            <label></label>
          </div>
          <div class="border-r border-black p-2 text-center">
            <label></label>
          </div>
          <div class="p-2 text-center">
            <label></label>
          </div>
        </div>

        <div class="grid grid-cols-4 gap-0">
          <div
            class="col-span-4 text-left bg-blue-900 text-white text-sm p-2 title"
          >
            1. Асуулгын хуудсыг бөглөнө үү / Complete the JHA Questionnaire
          </div>
        </div>

        <div class="grid grid-cols-5 gap-0 border border-black">
          <div
            class="col-span-2 border-b border-r border-black text-left text-sm p-2"
          >
            <div>
              <label class="font-bold"
                >1.1 Тухайн ажилд зөвшөөрөл шаардлагатай юу?</label
              ><br />
              <label class="font-bold"
                >1.1 Does the task require a permit?</label
              >

              <div class="flex items-center space-x-4">
                <label><input type="radio" name="permit" /> Тийм/Yes</label>
                <label><input type="radio" name="permit" /> Үгүй/No</label>
              </div>
            </div>
            <br />
            <br />
            <div>
              <label class="font-bold"
                >1.2. Шаардагдах зөвшөөрлийг тэмдэглэнэ үү</label
              ><br />
              <label class="font-bold">1.2. Indicate which permit</label><br />
              <br />
              <br />
              <label class="leading-loose"
                >Өндөрт ажиллах /Working at Height</label
              ><br />
              <label class="leading-loose">Өндөр хэмийн ажил / Hot Work</label
              ><br />
              <label class="leading-loose"
                >Өргөн тээвэрлэх машин механизм ашиглах /Critical lifting</label
              ><br />
              <label class="leading-loose"
                >Газар шорооны ажил / Excavation</label
              ><br />
              <label class="leading-loose"
                >Өндөр хүчдэлтэй ойр ажиллах / Working Near HV area</label
              ><br />
              <label class="leading-loose"
                >Даралтат савтай харьцаж ажиллах / Pressurized Vessels</label
              ><br />
              <label class="leading-loose"
                >Хязгаарлагдмал орчинд ажиллах / Confined Space</label
              ><br />
              <label class="leading-loose"
                >Их усны хажууд/ Working near water</label
              ><br />
              <label class="leading-loose">Цацраг/ Radiation</label><br />
            </div>
          </div>

          <div class="col-span-3 border-b border-black text-left text-sm p-2">
            <div>
              <label class="font-bold"
                >1.3. Тухайн ажилд үүсэж болох 1-р зэргийн эрсдлийг тодорхойлно
                уу?</label
              ><br />
              <label class="font-bold"
                >1.3. Critical risk 1 check in task?</label
              >
            </div>

            <div class="grid grid-cols-4 gap-2">
              <div
                v-for="(item, index) in pics1"
                :key="index"
                class="flex flex-col items-center"
              >
                <img :src="item.photo" :alt="item.photo" class="w-12 h-12" />
                <div class="w-[140px] text-center">
                  {{ item.name }}
                </div>
                <div>
                  <input type="checkbox" />
                </div>
              </div>
            </div>

            <div class="border-t border-black"></div>
            <div class="grid grid-cols-4 gap-2 my-2.5">
              <div
                v-for="(item, index) in pics2"
                :key="index"
                class="flex flex-col items-center"
              >
                <img :src="item.photo" :alt="item.photo" class="w-12 h-12" />
                <div class="w-[140px] text-center">
                  {{ item.name }}
                </div>
                <div>
                  <input type="checkbox" />
                </div>
              </div>
            </div>
            <div class="border-t border-black"></div>

            <div class="grid grid-cols-4 gap-2 my-2.5">
              <div
                v-for="(item, index) in pics3"
                :key="index"
                class="flex flex-col items-center"
              >
                <img :src="item.photo" :alt="item.photo" class="w-12 h-12" />
                <div class="w-[140px] text-center">
                  {{ item.name }}
                </div>
                <div>
                  <input type="checkbox" />
                </div>
              </div>
            </div>
            <div class="border-t border-black"></div>

            <div class="grid grid-cols-4 gap-2 my-2.5">
              <div
                v-for="(item, index) in pics4"
                :key="index"
                class="flex flex-col items-center"
              >
                <img :src="item.photo" :alt="item.photo" class="w-12 h-12" />
                <div class="w-[140px] text-center">
                  {{ item.name }}
                </div>
                <div>
                  <input type="checkbox" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Page 4 -->
      <div
        class="p-8 mt-5 max-w-6xl mx-auto bg-white shadow-md border border-gray-200 print-page"
      >
        <div class="grid grid-cols-4 gap-0 border border-black">
          <!-- Header -->
          <div
            class="border-b border-r border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            2. Ажил гүйцэтгэх дараалал /<br />
            Step in Task
          </div>
          <div
            class="border-b border-r border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Болзошгүй аюул (Ямар алдаа гарч, Ямар хор хөнөөл, аюулд хүргэж болох
            вэ?) Unwanted Event / Hazard (What could go wrong, What harm could
            result?)
          </div>
          <div
            class="border-b border-r border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Шаардагдах хяналтууд. Аюулыг багасгах эсвэл урьдчилан сэргийлэхэд
            ямар арга хэмжээ авах вэ? What controls are required to manage the
            hazard? What must be in place to prevent or minimise harm?
          </div>
          <div
            class="border-b border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Аюулын хяналт тохирсон эсэх? Is the hazard controlled adequately?
          </div>

          <!-- Table Rows -->
          <div v-for="(row, index) in tableText1" :key="index" class="contents">
            <!-- Column 1 -->
            <div
              :class="[
                'border-b border-r border-black p-2 text-center min-h-[50px]',
                !row.text1 ? 'emptyRow' : '',
              ]"
            >
              {{ row.text1 || '' }}
            </div>
            <!-- Column 2-->
            <div
              :class="[
                'border-b border-r border-black p-2 text-center min-h-[50px]',
              ]"
            >
              {{ row.text2 || '' }}
            </div>
            <!-- Column 3 -->
            <div
              :class="[
                'border-b border-r border-black p-2 text-center min-h-[50px]',
              ]"
            >
              {{ row.text3 || '' }}
            </div>
            <!-- Column 4 -->
            <div
              :class="[
                'border-b border-black p-2 text-center min-h-[50px]',
                index !== tableText1.length - 1 ? '' : '',
              ]"
            >
              {{ row.text4 || '' }}
            </div>
          </div>
        </div>
      </div>

      <!-- Page 5 -->
      <div
        class="p-8 mt-5 max-w-6xl mx-auto bg-white shadow-md border border-gray-200 print-page"
      >
        <div class="grid grid-cols-4 gap-0 border border-black">
          <!-- Header -->
          <div
            class="col-span-4 border-b border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            3. ААДШ-н баг: Бид учирч болох ХАБЭА-н аюулууд болон тэдгээрт
            тохирсон хяналтын арга хэмжээнүүдийг тодорхойлсон болно.<br />
            3. JHA Team: We believe that all HSE hazards have been identified
            and the controls listed will enable us to manage them.
          </div>

          <div
            class="border-b border-r border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Нэр/Name:
          </div>
          <div
            class="border-b border-r border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Үүрэг/Role:
          </div>
          <div
            class="border-b border-r border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Огноо/Date:
          </div>
          <div
            class="border-b border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Гарын үсэг/Signature:
          </div>

          <!-- Table Rows -->
          <div v-for="(row, index) in tableText2" :key="index" class="contents">
            <!-- Column 1 -->
            <div
              :class="[
                'border-r border-black p-2 text-center min-h-[50px]',
                index !== tableText2.length - 1 ? 'border-b' : '',
                !row.text1 ? 'emptyRow' : '',
              ]"
            >
              {{ row.text1 || '' }}
            </div>
            <!-- Column 2-->
            <div
              :class="[
                'border-r border-black p-2 text-center min-h-[50px]',
                index !== tableText2.length - 1 ? 'border-b' : '',
              ]"
            >
              {{ row.text2 || '' }}
            </div>
            <!-- Column 3 -->
            <div
              :class="[
                'border-r border-black p-2 text-center min-h-[50px]',
                index !== tableText2.length - 1 ? 'border-b' : '',
              ]"
            >
              {{ row.text3 || '' }}
            </div>
            <!-- Column 4 -->
            <div
              :class="[
                ' border-black p-2 text-center min-h-[50px]',
                index !== tableText2.length - 1 ? 'border-b' : '',
              ]"
            >
              {{ row.text4 || '' }}
            </div>
          </div>
        </div>

        <div class="grid grid-cols-4 gap-0">
          <div
            class="border-b border-r border-l border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Ахлах ажилтны нэр/ Supervisors Name:
          </div>
          <div class="border-b border-r border-black text-center"></div>
          <div
            class="border-b border-r border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Огноо/Date:
          </div>
          <div
            class="border-b border-r border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Гарын үсэг/Signature:
          </div>
        </div>

        <div class="grid grid-cols-6 gap-0">
          <div
            class="col-span-4 border-b border-r border-l border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            4. Хэрвээ ажил дуусаагүй, үргэлжилж байгаа бол: Дараагийн мастертай
            энэхүү ААДШ-ний талаар ярилцаж ажлаа хүлээлцсэн үү? If job is still
            in progress, incomplete: Have you discussed this JHA and hand overed
            job with the oncoming Supervisor?
          </div>
          <div
            class="border-b border-r border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Тийм/ Yes
          </div>
          <div
            class="border-b border-r border-black text-center bg-blue-900 text-white font-bold text-sm p-2 title"
          >
            Үгүй/ No
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
@media print {
  .no-print {
    display: none !important;
  }

  /* body {
    margin: 0;
    padding: 0;
    height: auto;
    overflow: visible !important;
  } */

  #print-body {
    width: 100%;
    margin: 0 auto;
    visibility: visible;
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
  }

  .print-page {
    page-break-after: always;
    margin: 0;
    padding: 0;
    border: none;
  }

  .print-page:last-child {
    page-break-after: auto;
  }

  @page {
    margin: 1cm;
  }
}
</style>
