// Version: 2.0.0
// Main Application Entry Point

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import i18n from './i18n'
import './assets/main.css'

const app = createApp(App)

// Use Pinia for state management
app.use(createPinia())

// Use Vue Router
app.use(router)

// Use Vue I18n for internationalization
app.use(i18n)

// Mount the app
app.mount('#app')

