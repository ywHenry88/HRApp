<!-- Version: 2.0.0 -->
<!-- Root Application Component -->

<template>
  <div id="app" class="min-h-screen bg-gray-100">
    <router-view />
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useAuthStore } from './stores/auth'

const authStore = useAuthStore()

onMounted(async () => {
  // Check if user is logged in on app load
  const token = localStorage.getItem('token')
  if (token) {
    try {
      await authStore.getCurrentUser()
    } catch (error) {
      // Token invalid or expired, will redirect to login
      console.error('Failed to load user:', error)
    }
  }
})
</script>

<style>
/* Global styles handled by Tailwind */
</style>

