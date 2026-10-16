// Session идэвхгүй болоход (access + refresh token хоёулаа хугацаа дуусах үед)
// хэрэглэгчийг шууд /login руу шилжүүлнэ.
//
// useDirectus() бүрт дуудагддаг checkAutoRefresh() нь access token дуусахад
// автоматаар шинэчлэхийг оролддог; refresh token ч мөн дуусвал (жишээ нь
// таб удаан нээлттэй байсны дараа) энэ оролдлого амжилтгүй болж,
// refreshToken cookie-г null болгодог (node_modules/nuxt-directus).
// Гэвч энэ модуль үүнээс цааш юу ч хийдэггүй тул хуудас дээрх бүх дараагийн
// хүсэлт 401 өгсөөр байж, dashboard "нэвтэрсэн мэт" хоосон/эвдэрхий байдлаар
// зогсдог байв. Энд refreshToken null болох мөчийг ажигласнаар шууд /login
// руу шилжүүлнэ.

// Яаж ажилладаг вэ:
// Nuxt 3-т .app/plugins/ фолдер доtorh бүх .ts/.js файлыг автоматаар уншиж,
// апп эхлэхэд (nuxtApp үүсэх үед) дараалан ажиллуулдаг convention байдаг
// — ямар нэг nuxt.config.ts-д бүртгэх, эсвэл өөр файлаас import хийх шаардлагагүй.
// Яг адилхнаар энэ фолдер доторх бусад файлууд (startup.ts, dynamic-api.ts, vuetify.ts гэх мэт)
// бас ямар ч тусгай дуудалтгүйгээр л ажилладаг.
// defineNuxtPlugin(() => {...}) гэдэг export нь яг энэ механизмын гарын үсэг
// — Nuxt build хийхдээ plugins/ дэх бүх файлыг сканнердаад, appn үүсэх дарааллаараа
// (filename-ий цагаан толгойн дараалал, эсвэл enforce: 'pre'/'post' зэрэг тохиргоогоор өөрчилж болно) автоматаар register хийдэг.
// Тиймээс auth-session-guard.ts файлыг зүгээр л plugins/ фолдерт байрлуулснаар л
// (аль хэдийн байгаа шиг) апп ачаалах бүрд watch(refreshToken, ...) кодыг идэвхжүүлж,
// session-ийг байнга сонсдог болно — dev server-ийг дахин асаах (эсвэл build хийх)-аас өөр юу ч хийх шаардлагагүй.

export default defineNuxtPlugin(() => {
  const { token, refreshToken } = useDirectusToken()
  const { setUser } = useDirectusAuth()

  watch(refreshToken, (newValue, oldValue) => {
    if (oldValue && !newValue) {
      token.value = null
      setUser(null)
      navigateTo('/login')
    }
  })
})
