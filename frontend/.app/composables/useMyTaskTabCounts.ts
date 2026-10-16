// mytask.vue (эцэг layout) толгой хэсэгт "/mytask/*" доорх бүх nav item
// (Tasks-ийн 3 дэд tab + Assign/Inspections/Teams/Projects/Equipments)-ын
// тоог зэрэг харуулахын тулд ашиглана. mytask.vue өөрөө (аль ч дэд route
// идэвхтэй байгаагаас үл хамааран, эцэг байдлаараа үргэлж mount хийгддэг
// цорын ганц компонент тул) эдгээрийг тооцож бичнэ.
export function useMyTaskTabCounts() {
  return useState<{
    tab1: number | null
    tab2: number | null
    tab3: number | null
    wallet: number | null
    inspection: number | null
    teams: number | null
    projects: number | null
    equipments: number | null
  }>('mytask-work-order-tab-counts', () => ({
    tab1: null,
    tab2: null,
    tab3: null,
    wallet: null,
    inspection: null,
    teams: null,
    projects: null,
    equipments: null,
  }))
}
