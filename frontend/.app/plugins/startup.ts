import {DirectusUser} from "@directus/sdk";
export default defineNuxtPlugin(async (nuxtApp) => {

  // Doing something with nuxtApp
  /*
  const { refreshTokens } = useDirectusToken();
  const directus = useDirectus()
  const { fetchUser, setUser } = useDirectusAuth();
  refreshTokens().then((auth) => {
    console.log("Startup .... loaded ........................")
    console.log(auth)
    if (auth?.refresh_token && auth?.refresh_token.length > 10){
      console.log(auth?.refresh_token)
      const res = directus<{ data: DirectusUser }>('/users/me', {
      }, false);
      res.then((res) => {
        setUser(res.data)
      })
      navigateTo('/')
    }
  });*/
})
