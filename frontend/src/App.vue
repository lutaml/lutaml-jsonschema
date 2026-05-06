<template>
  <div class="app-layout">
    <AppSidebar />
    <div class="main-content">
      <AppHeader />
      <div class="content-area">
        <HomeView />
      </div>
    </div>
    <DetailPanel v-if="uiStore.detailPanelOpen" />
    <SearchModal v-if="uiStore.searchOpen" />
  </div>
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { useSchemaStore } from './stores/schemaStore'
import { useUiStore } from './stores/uiStore'
import AppHeader from './components/AppHeader.vue'
import AppSidebar from './components/AppSidebar.vue'
import DetailPanel from './components/DetailPanel.vue'
import SearchModal from './components/SearchModal.vue'
import HomeView from './views/HomeView.vue'

const schemaStore = useSchemaStore()
const uiStore = useUiStore()

onMounted(() => {
  uiStore.initTheme()
  schemaStore.loadFromWindow()

  if (schemaStore.metadata?.theme) {
    uiStore.theme = schemaStore.metadata.theme as 'light' | 'dark'
    uiStore.updateResolvedTheme()
  }

  document.addEventListener('keydown', handleKeydown)
})

function handleKeydown(e: KeyboardEvent) {
  if (e.key === '/' && !isInputFocused()) {
    e.preventDefault()
    uiStore.openSearch()
  }
  if (e.key === 'Escape') {
    if (uiStore.searchOpen) {
      uiStore.closeSearch()
    } else if (uiStore.detailPanelOpen) {
      uiStore.closeDetailPanel()
    }
  }
}

function isInputFocused(): boolean {
  const active = document.activeElement
  return active instanceof HTMLInputElement || active instanceof HTMLTextAreaElement
}
</script>

<style scoped>
.app-layout {
  display: flex;
  height: 100vh;
  overflow: hidden;
}

.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.content-area {
  flex: 1;
  overflow: auto;
  padding: var(--space-6);
  background: var(--bg-primary);
}
</style>
