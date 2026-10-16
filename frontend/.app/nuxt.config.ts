export default defineNuxtConfig({
  extends: [
    '../layers/tairo',
    // enable the sidebar layout
    '../layers/tairo-layout-sidebar',
    '@shuriken-ui/nuxt',
  ],

  vite: {
    define: {
      'process.test': false,
    },
    build: {
      target: 'esnext',
      // Reduce concurrent operations to prevent file descriptor exhaustion
      chunkSizeWarningLimit: 1000,
      rollupOptions: {
        output: {
          manualChunks: undefined,
          inlineDynamicImports: false,
        },
        // Limit parallel builds - very conservative
        maxParallelFileOps: 10,
      },
    },
    optimizeDeps: {
      include: ['vue3-carousel', 'vue3-apexcharts', 'mapbox-gl', 'pdfjs-dist'],
      // Force dependencies to be included to reduce dynamic imports
      force: true,
    },
    worker: {
      // Limit worker threads
      rollupOptions: {
        maxParallelFileOps: 5,
      },
    },
    server: {
      hmr: {
        clientPort: 3001,
        overlay: false,
      },
      watch: {
        usePolling: false,
        // Reduce file watchers
        ignored: [
          '**/node_modules/**',
          '**/.git/**',
          '**/dist/**',
          '**/.nuxt/**',
        ],
      },
      fs: {
        // Reduce concurrent file system operations
        strict: false,
      },
    },
    // Reduce concurrent file transformations
    esbuild: {
      logOverride: { 'this-is-undefined-in-esm': 'silent' },
    },
  },

  modules: [
    'nuxt-directus',
    '@formkit/nuxt',
    'vuetify-nuxt-module',
    '@nuxt/devtools',
  ],

  formkit: {
    configFile: 'formkit.config.ts',
  },

  css: [
    '@mdi/font/css/materialdesignicons.min.css',
    '@/assets/global.scss',
    '@/utils/global.css',
    'ag-grid-community/styles/ag-grid.css',
    'ag-grid-community/styles/ag-theme-quartz.css',
  ],

  build: {
    transpile: [
      //'vuetify',
      'ag-grid-vue',
    ],
  },

  vuetify: {
    vuetifyOptions: {
      // @TODO: list all vuetify options
    },

    moduleOptions: {
      styles: true,
      autoImport: true,
      useVuetifyLabs: true,
    },
  },

  runtimeConfig: {
    public: {
      firebase: {
        apiKey: '',
        authDomain: '',
        projectId: '',
        storageBucket: '',
        messagingSenderId: '',
        appId: '',
        measurementId: '',
        vapidKey: '',
      },
      mapboxToken: process.env.NUXT_PUBLIC_MAPBOX_TOKEN,
      directus: {
        // Default URL (dynamic-api.ts plugin автоматаар domain-оос хамааруулж солино)
        url: process.env.API_BASE_URL || 'https://api.ibex.mn/',
        autoFetch: true,
        autoRefresh: true,
      },
    },
  },

  router: {
    options: {
      strict: true,
    },
  },

  ssr: false,


  devtools: {
    timeline: {
      enabled: true,
    },
  },

  nitro: {
    compatibilityDate: '2024-04-03',
  },
})
