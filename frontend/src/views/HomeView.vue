<template>
  <div class="home-view">
    <!-- Schema Detail Mode -->
    <div v-if="schemaStore.selectedSchema" class="selected-schema">
      <div class="schema-header">
        <div>
          <h1>{{ schemaStore.selectedSchema.title || schemaStore.selectedSchema.name }}</h1>
          <p v-if="schemaStore.selectedSchema.description" class="schema-desc text-secondary">{{ schemaStore.selectedSchema.description }}</p>
          <div class="schema-meta-row">
            <span class="badge badge-type">{{ schemaStore.selectedSchema.type || 'any' }}</span>
            <span class="text-muted">{{ schemaStore.selectedSchema.properties.length }} properties</span>
            <span v-if="schemaStore.selectedSchema.required.length" class="text-muted">&middot; {{ schemaStore.selectedSchema.required.length }} required</span>
            <span v-if="schemaStore.selectedSchema.definitions.length" class="text-muted">&middot; {{ schemaStore.selectedSchema.definitions.length }} definitions</span>
          </div>
        </div>
      </div>

      <div class="schema-tabs">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          class="tab-btn"
          :class="{ active: activeTab === tab.id }"
          @click="activeTab = tab.id"
        >
          {{ tab.label }}
          <span class="tab-count">{{ tab.count }}</span>
        </button>
      </div>

      <div class="tab-content">
        <!-- Builder Tab -->
        <div v-if="activeTab === 'builder'" class="tab-pane">
          <SchemaBuilder
            :properties="schemaStore.selectedSchema.properties"
            :required="schemaStore.selectedSchema.required"
            :schema="schemaStore.selectedSchema"
          />
        </div>

        <!-- Definitions Tab -->
        <div v-if="activeTab === 'definitions'" class="tab-pane">
          <div v-if="schemaStore.selectedSchema.definitions.length" class="def-list">
            <div
              v-for="def in schemaStore.selectedSchema.definitions"
              :key="def.name"
              class="def-card card"
            >
              <div class="def-card-header" @click="toggleDef(def.name)">
                <span class="def-chevron" :class="{ expanded: expandedDefs.has(def.name) }">&#9654;</span>
                <span class="def-card-title">{{ def.title || def.name }}</span>
                <span class="def-card-name font-mono text-muted">{{ def.name }}</span>
                <span v-if="def.type" class="def-type-badge">{{ def.type }}</span>
                <span class="text-muted">{{ def.properties.length }} props</span>
                <span v-if="def.required?.length" class="text-muted">&middot; {{ def.required.length }} required</span>
              </div>
              <p v-if="def.description" class="def-card-desc text-secondary">{{ def.description }}</p>
              <div v-if="expandedDefs.has(def.name)" class="def-card-body">
                <SchemaBuilder
                  :properties="def.properties"
                  :required="def.required"
                  :schema="schemaStore.selectedSchema"
                />
              </div>
            </div>
          </div>
          <div v-else class="empty-state">
            <p class="text-muted">No definitions.</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Landing Page -->
    <div v-else class="landing-page">
      <div class="landing-header">
        <h1>{{ schemaStore.metadata?.title || 'JSON Schema Documentation' }}</h1>
        <p v-if="schemaStore.metadata?.description" class="landing-description">{{ schemaStore.metadata.description }}</p>
        <div class="landing-subtitle">
          <span>{{ schemaStore.schemaCounts.schemas }} schemas</span>
          <span class="separator">&middot;</span>
          <span>{{ schemaStore.schemaCounts.properties }} properties</span>
          <span class="separator">&middot;</span>
          <span>{{ schemaStore.schemaCounts.definitions }} definitions</span>
        </div>
      </div>

      <div class="schema-grid">
        <div
          v-for="schema in schemaStore.schemas"
          :key="schema.name"
          class="schema-card card"
          @click="selectSchema(schema.name)"
        >
          <div class="schema-card-icon">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
              <rect x="3" y="3" width="18" height="18" rx="2" stroke="currentColor" stroke-width="1.5"/>
              <path d="M7 8h10M7 12h6M7 16h8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
            </svg>
          </div>
          <div class="schema-card-content">
            <h3>{{ schema.title || schema.name }}</h3>
            <p v-if="schema.description" class="schema-card-desc text-secondary">{{ schema.description }}</p>
            <div class="schema-card-meta">
              <span class="badge badge-type-sm">{{ schema.type || 'any' }}</span>
            </div>
            <div class="schema-card-stats">
              <span>{{ schema.properties.length }} properties</span>
              <span>{{ schema.definitions.length }} definitions</span>
              <span v-if="schema.required.length">{{ schema.required.length }} required</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, reactive } from 'vue'
import { useSchemaStore } from '../stores/schemaStore'
import SchemaBuilder from '../components/SchemaBuilder.vue'

type TabId = 'builder' | 'definitions'

const schemaStore = useSchemaStore()
const activeTab = ref<TabId>('builder')
const expandedDefs = reactive(new Set<string>())

const tabs = computed(() => {
  const s = schemaStore.selectedSchema
  if (!s) return []
  return [
    { id: 'builder' as TabId, label: 'Builder', count: s.properties.length },
    { id: 'definitions' as TabId, label: 'Definitions', count: s.definitions.length },
  ]
})

function selectSchema(name: string) {
  schemaStore.selectSchema(name)
  activeTab.value = 'builder'
}

function toggleDef(name: string) {
  if (expandedDefs.has(name)) {
    expandedDefs.delete(name)
  } else {
    expandedDefs.add(name)
  }
}
</script>

<style scoped>
.home-view {
  max-width: 1400px;
  margin: 0 auto;
}

.schema-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  margin-bottom: var(--space-6);
  gap: var(--space-4);
}

.schema-header h1 {
  font-size: var(--text-2xl);
  margin-bottom: var(--space-1);
}

.schema-desc {
  font-size: var(--text-base);
  margin-bottom: var(--space-2);
  line-height: var(--leading-relaxed);
}

.schema-meta-row {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-top: var(--space-2);
}

.schema-tabs {
  display: flex;
  gap: var(--space-1);
  margin-bottom: var(--space-4);
  border-bottom: 1px solid var(--border-light);
  padding-bottom: var(--space-2);
}

.tab-btn {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-2) var(--space-3);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-muted);
  border-radius: var(--radius-md);
  transition: all var(--transition-fast);
}

.tab-btn:hover {
  color: var(--text-primary);
  background: var(--bg-hover);
}

.tab-btn.active {
  color: var(--color-primary);
  background: var(--color-primary-alpha);
}

.tab-count {
  font-size: var(--text-xs);
  background: var(--bg-secondary);
  padding: 1px 6px;
  border-radius: var(--radius-sm);
}

/* Definitions */
.def-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.def-card {
  padding: 0;
  overflow: hidden;
}

.def-card-header {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-3) var(--space-4);
  cursor: pointer;
  transition: background var(--transition-fast);
}

.def-card-header:hover {
  background: var(--bg-hover);
}

.def-chevron {
  font-size: 10px;
  color: var(--text-muted);
  transition: transform var(--transition-fast);
  flex-shrink: 0;
}

.def-chevron.expanded {
  transform: rotate(90deg);
}

.def-card-title {
  font-weight: 600;
  font-size: var(--text-sm);
}

.def-card-name {
  font-size: var(--text-xs);
}

.def-type-badge {
  font-size: 11px;
  background: var(--badge-schema-bg);
  color: var(--badge-schema);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
}

.def-card-desc {
  font-size: var(--text-sm);
  padding: 0 var(--space-4) var(--space-2);
  margin-top: calc(var(--space-1) * -1);
}

.def-card-body {
  border-top: 1px solid var(--border-light);
  padding: var(--space-4);
  background: var(--bg-primary);
}

.badge-type {
  background: var(--badge-schema-bg);
  color: var(--badge-schema);
}

.badge-type-sm {
  background: var(--bg-secondary);
  color: var(--text-secondary);
  font-size: 10px;
}

/* Landing page */
.landing-page {
  padding: var(--space-6);
  max-width: 1200px;
  margin: 0 auto;
}

.landing-header {
  margin-bottom: var(--space-8);
}

.landing-header h1 {
  font-size: var(--text-2xl);
  margin-bottom: var(--space-2);
}

.landing-description {
  font-size: var(--text-base);
  color: var(--text-secondary);
  line-height: var(--leading-relaxed);
  margin-bottom: var(--space-3);
  max-width: 700px;
}

.landing-subtitle {
  color: var(--text-muted);
  font-size: var(--text-sm);
  margin-bottom: var(--space-3);
}

.separator {
  margin: 0 var(--space-1);
}

.schema-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: var(--space-4);
}

.schema-card {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
  padding: var(--space-4);
  cursor: pointer;
  transition: all var(--transition-fast);
}

.schema-card:hover {
  border-color: var(--color-primary);
  box-shadow: var(--shadow-md);
}

.schema-card-icon {
  color: var(--color-primary);
  flex-shrink: 0;
  margin-top: 2px;
}

.schema-card-content {
  flex: 1;
  min-width: 0;
}

.schema-card-content h3 {
  font-size: var(--text-base);
  font-weight: 600;
  margin-bottom: var(--space-1);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.schema-card-desc {
  font-size: var(--text-sm);
  margin-bottom: var(--space-2);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.schema-card-meta {
  margin-bottom: var(--space-2);
}

.schema-card-stats {
  display: flex;
  gap: var(--space-3);
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.empty-state {
  padding: var(--space-8);
  text-align: center;
}
</style>
