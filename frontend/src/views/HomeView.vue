<template>
  <div class="home-view">
    <!-- Schema Detail Mode -->
    <div v-if="schemaStore.selectedSchema" class="selected-schema">
      <div class="schema-header">
        <div class="schema-header-info">
          <div class="schema-title-row">
            <h1>{{ schemaStore.selectedSchema.title || schemaStore.selectedSchema.name }}</h1>
            <div class="schema-actions">
              <div class="view-toggle">
                <button class="toggle-btn" :class="{ active: viewMode === 'builder' }" @click="viewMode = 'builder'">Builder</button>
                <button class="toggle-btn" :class="{ active: viewMode === 'source' }" @click="viewMode = 'source'">Source</button>
              </div>
              <button
                v-if="schemaStore.selectedSchema.sourceJson"
                class="btn btn-outline btn-sm"
                @click="downloadSchema(schemaStore.selectedSchema)"
              >
                Download JSON
              </button>
            </div>
          </div>
          <span v-if="schemaStore.selectedSchema.title && schemaStore.selectedSchema.title !== schemaStore.selectedSchema.name" class="schema-name-hint font-mono text-muted">{{ schemaStore.selectedSchema.name }}</span>
          <p v-if="schemaStore.selectedSchema.description" class="schema-desc text-secondary">{{ schemaStore.selectedSchema.description }}</p>
          <div class="schema-meta-row">
            <span class="badge badge-type">{{ schemaStore.selectedSchema.type || 'any' }}</span>
            <span class="text-muted">{{ schemaStore.selectedSchema.properties.length }} properties</span>
            <span v-if="schemaStore.selectedSchema.required.length" class="text-muted">&middot; {{ schemaStore.selectedSchema.required.length }} required</span>
            <span v-if="schemaStore.selectedSchema.definitions.length" class="text-muted">&middot; {{ schemaStore.selectedSchema.definitions.length }} definitions</span>
            <span v-if="schemaStore.selectedSchema.additionalProperties === false" class="badge badge-locked">no additional properties</span>
          </div>
          <div v-if="schemaStore.selectedSchema.$schema || schemaStore.selectedSchema.$id" class="schema-id-row">
            <span v-if="schemaStore.selectedSchema.$schema" class="meta-id-chip font-mono text-muted" title="JSON Schema version">{{ schemaStore.selectedSchema.$schema }}</span>
            <span v-if="schemaStore.selectedSchema.$id" class="meta-id-chip font-mono text-muted" title="Schema $id">{{ schemaStore.selectedSchema.$id }}</span>
          </div>
          <div v-if="schemaStore.selectedSchema.required.length" class="schema-required">
            <span class="required-label text-muted">Required:</span>
            <div class="required-tags">
              <span v-for="r in schemaStore.selectedSchema.required" :key="r" class="required-tag">{{ r }}</span>
            </div>
          </div>
          <details v-if="schemaStore.selectedSchema.examples?.length" class="schema-examples-details">
            <summary class="examples-summary text-muted">Examples ({{ schemaStore.selectedSchema.examples.length }})</summary>
            <pre class="examples-pre"><code>{{ formatJson(schemaStore.selectedSchema.examples) }}</code></pre>
          </details>
        </div>
      </div>

      <!-- Builder View -->
      <template v-if="viewMode === 'builder'">
      <!-- Properties -->
      <div class="schema-section">
        <SchemaBuilder
          :properties="schemaStore.selectedSchema.properties"
          :required="schemaStore.selectedSchema.required"
          :schema="schemaStore.selectedSchema"
          :all-schemas="schemaStore.schemas"
        />
      </div>

      <!-- Definitions -->
      <div v-if="schemaStore.selectedSchema.definitions.length" class="schema-section">
        <div class="section-heading-row">
          <h2 class="section-heading">Definitions</h2>
          <div class="section-actions">
            <button class="btn btn-ghost btn-sm" @click="expandAllDefs">Expand All</button>
            <button class="btn btn-ghost btn-sm" @click="collapseAllDefs">Collapse All</button>
          </div>
        </div>
        <div class="def-list">
          <div
            v-for="def in schemaStore.selectedSchema.definitions"
            :key="def.name"
            :id="`def-${def.name}`"
            class="def-card card"
            :class="{ 'def-card-highlighted': def.name === schemaStore.selectedDefinitionName }"
          >
            <div class="def-card-header" @click="toggleDef(def.name)">
              <span class="def-chevron" :class="{ expanded: expandedDefs.has(def.name) }">&#9654;</span>
              <span class="def-card-title">{{ def.title || def.name }}</span>
              <span v-if="def.title && def.title !== def.name" class="def-card-name font-mono text-muted">{{ def.name }}</span>
              <span v-if="def.type" class="def-type-badge">{{ def.type }}</span>
              <span class="text-muted">{{ def.properties.length }} props</span>
              <span v-if="def.required?.length" class="text-muted">&middot; {{ def.required.length }} req</span>
              <span v-if="def.examples?.length" class="text-muted">&middot; {{ def.examples.length }} ex</span>
            </div>
            <div class="def-card-info">
              <p v-if="def.description" class="def-card-desc text-secondary">{{ def.description }}</p>
              <div v-if="def.required?.length" class="def-card-required">
                <span v-for="r in def.required" :key="r" class="required-tag-sm">{{ r }}</span>
              </div>
              <details v-if="def.examples?.length" class="def-card-examples">
                <summary class="text-muted">Examples</summary>
                <pre class="def-examples-pre"><code>{{ formatJson(def.examples) }}</code></pre>
              </details>
            </div>
            <div v-if="expandedDefs.has(def.name)" class="def-card-body">
              <SchemaBuilder
                :properties="def.properties"
                :required="def.required"
                :schema="schemaStore.selectedSchema"
                :all-schemas="schemaStore.schemas"
              />
            </div>
          </div>
        </div>
      </div>
      </template>

      <!-- Source JSON View -->
      <div v-if="viewMode === 'source'" class="schema-section">
        <div v-if="schemaStore.selectedSchema.sourceJson" class="source-viewer">
          <pre class="source-pre"><code v-html="highlightedSource"></code></pre>
        </div>
        <div v-else class="source-empty">
          <p class="text-muted">Source JSON Schema not available for this schema.</p>
        </div>
      </div>
    </div>

    <!-- Landing Page -->
    <div v-else class="landing-page">
      <div class="landing-header">
        <div>
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
        <button
          v-if="hasSourceJson"
          class="btn btn-outline btn-sm"
          @click="downloadAllSchemas"
        >
          Download All Schemas (.zip)
        </button>
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
            <span v-if="schema.title && schema.title !== schema.name" class="schema-card-name font-mono text-muted">{{ schema.name }}</span>
            <p v-if="schema.description" class="schema-card-desc text-secondary">{{ schema.description }}</p>
            <div class="schema-card-meta">
              <span class="badge badge-type-sm">{{ schema.type || 'any' }}</span>
            </div>
            <div class="schema-card-stats">
              <span>{{ schema.properties.length }} props</span>
              <span>{{ schema.definitions.length }} defs</span>
              <span v-if="schema.required.length">{{ schema.required.length }} required</span>
              <span v-if="schema.examples?.length">{{ schema.examples.length }} examples</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch, nextTick } from 'vue'
import { useSchemaStore } from '../stores/schemaStore'
import SchemaBuilder from '../components/SchemaBuilder.vue'
import { downloadFile } from '../composables/useDownload'
import type { SpaSchema } from '../types'

const schemaStore = useSchemaStore()
const expandedDefs = reactive(new Set<string>())
const viewMode = ref<'builder' | 'source'>('builder')

function expandAllDefs() {
  for (const def of schemaStore.selectedSchema?.definitions ?? []) {
    expandedDefs.add(def.name)
  }
}

function collapseAllDefs() {
  expandedDefs.clear()
}

const highlightedSource = computed(() => {
  const src = schemaStore.selectedSchema?.sourceJson
  if (!src) return ''
  return syntaxHighlight(src)
})

function syntaxHighlight(json: string): string {
  return json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/("(\\u[\da-fA-F]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)/g, (match) => {
      let cls = 'json-number'
      if (/^"/.test(match)) {
        cls = /:$/.test(match) ? 'json-key' : 'json-string'
      } else if (/true|false/.test(match)) {
        cls = 'json-boolean'
      } else if (/null/.test(match)) {
        cls = 'json-null'
      }
      return `<span class="${cls}">${match}</span>`
    })
}

function selectSchema(name: string) {
  schemaStore.selectSchema(name)
}

function toggleDef(name: string) {
  if (expandedDefs.has(name)) {
    expandedDefs.delete(name)
  } else {
    expandedDefs.add(name)
  }
}

function downloadSchema(schema: SpaSchema) {
  if (!schema.sourceJson) return
  downloadFile(`${schema.name}.json`, schema.sourceJson)
}

const hasSourceJson = computed(() =>
  schemaStore.schemas.some(s => s.sourceJson),
)

function formatJson(value: unknown): string {
  return JSON.stringify(value, null, 2)
}

function downloadAllSchemas() {
  const bundle: Record<string, unknown> = {}
  for (const s of schemaStore.schemas) {
    if (s.sourceJson) {
      bundle[`${s.name}.json`] = JSON.parse(s.sourceJson)
    }
  }
  const name = schemaStore.metadata?.title || 'schemas'
  downloadFile(`${name.replace(/\s+/g, '-')}-bundle.json`, JSON.stringify(bundle, null, 2))
}

watch(() => schemaStore.selectedDefinitionName, (name) => {
  if (!name) return
  expandedDefs.add(name)
  nextTick(() => {
    const el = document.getElementById(`def-${name}`)
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' })
    }
  })
})
</script>

<style scoped>
.home-view {
  max-width: 1400px;
  margin: 0 auto;
}

.schema-header {
  margin-bottom: var(--space-6);
}

.schema-header-info {
  width: 100%;
}

.schema-title-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--space-4);
  margin-bottom: var(--space-1);
}

.schema-title-row h1 {
  font-size: var(--text-2xl);
  margin: 0;
}

.schema-actions {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-shrink: 0;
}

.view-toggle {
  display: flex;
  border: 1px solid var(--border-medium);
  border-radius: var(--radius-md);
  overflow: hidden;
}

.toggle-btn {
  padding: var(--space-1) var(--space-3);
  font-size: var(--text-xs);
  font-weight: 500;
  color: var(--text-muted);
  background: transparent;
  transition: all var(--transition-fast);
  border: none;
}

.toggle-btn:not(:last-child) {
  border-right: 1px solid var(--border-medium);
}

.toggle-btn.active {
  background: var(--color-primary-alpha);
  color: var(--color-primary);
}

.toggle-btn:hover:not(.active) {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.schema-name-hint {
  font-size: var(--text-xs);
  display: block;
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
  flex-wrap: wrap;
}

.schema-id-row {
  display: flex;
  gap: var(--space-2);
  margin-top: var(--space-2);
  flex-wrap: wrap;
}

.meta-id-chip {
  font-size: 10px;
  background: var(--bg-secondary);
  padding: 2px 6px;
  border-radius: var(--radius-sm);
  max-width: 400px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.badge-locked {
  font-size: 10px;
  color: var(--color-orange);
  background: var(--color-orange-alpha);
  padding: 2px 6px;
  border-radius: var(--radius-sm);
  font-weight: 500;
}

.schema-required {
  display: flex;
  align-items: flex-start;
  gap: var(--space-2);
  margin-top: var(--space-3);
  flex-wrap: wrap;
}

.required-label {
  font-size: var(--text-xs);
  font-weight: 500;
  white-space: nowrap;
  padding-top: 2px;
}

.required-tags {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
}

.required-tag {
  font-size: 11px;
  font-family: var(--font-mono);
  background: var(--badge-required-bg);
  color: var(--badge-required);
  padding: 2px 6px;
  border-radius: var(--radius-sm);
  font-weight: 500;
}

.required-tag-sm {
  font-size: 10px;
  font-family: var(--font-mono);
  background: var(--bg-secondary);
  color: var(--text-muted);
  padding: 1px 4px;
  border-radius: 2px;
}

.schema-examples-details {
  margin-top: var(--space-3);
}

.examples-summary {
  font-size: var(--text-xs);
  font-weight: 500;
  cursor: pointer;
  padding: var(--space-1) 0;
}

.examples-summary:hover {
  color: var(--text-primary);
}

.examples-pre {
  background: var(--bg-secondary);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-md);
  padding: var(--space-3);
  font-size: var(--text-sm);
  line-height: var(--leading-relaxed);
  overflow-x: auto;
  margin-top: var(--space-2);
  max-height: 300px;
  overflow-y: auto;
}

.examples-pre code {
  font-family: var(--font-mono);
  color: var(--text-primary);
}

.schema-section {
  margin-bottom: var(--space-6);
}

.section-heading {
  font-size: var(--text-lg);
  font-weight: 600;
  margin-bottom: var(--space-4);
  color: var(--text-primary);
}

.section-heading-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-4);
}

.section-actions {
  display: flex;
  gap: var(--space-2);
}

/* Source viewer */
.source-viewer {
  border-radius: var(--radius-lg);
  overflow: hidden;
}

.source-pre {
  background: var(--bg-secondary);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-lg);
  padding: var(--space-4);
  font-size: var(--text-sm);
  line-height: var(--leading-relaxed);
  overflow-x: auto;
  max-height: 70vh;
  overflow-y: auto;
  margin: 0;
}

.source-pre :deep(.json-key) { color: var(--color-primary-dark); }
.source-pre :deep(.json-string) { color: var(--color-green); }
.source-pre :deep(.json-number) { color: var(--color-orange); }
.source-pre :deep(.json-boolean) { color: var(--color-accent); }
.source-pre :deep(.json-null) { color: var(--text-muted); }

:root[data-theme="dark"] .source-pre :deep(.json-key) { color: var(--color-primary-light); }
:root[data-theme="dark"] .source-pre :deep(.json-string) { color: var(--color-teal); }

.source-empty {
  padding: var(--space-8);
  text-align: center;
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
  margin-bottom: var(--space-2);
}

.def-card-info {
  padding: 0 var(--space-4) var(--space-3);
  margin-top: calc(var(--space-1) * -1);
}

.def-card-required {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
  margin-bottom: var(--space-2);
}

.def-card-examples {
  margin-top: var(--space-2);
}

.def-card-examples summary {
  font-size: var(--text-xs);
  cursor: pointer;
}

.def-examples-pre {
  background: var(--bg-primary);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-sm);
  padding: var(--space-2);
  font-size: var(--text-xs);
  overflow-x: auto;
  margin-top: var(--space-1);
  max-height: 200px;
  overflow-y: auto;
}

.def-examples-pre code {
  font-family: var(--font-mono);
  color: var(--text-primary);
}

.def-card-body {
  border-top: 1px solid var(--border-light);
  padding: var(--space-4);
  background: var(--bg-primary);
}

.def-card-highlighted {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 2px var(--color-primary-alpha);
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
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--space-4);
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
  margin-bottom: 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.schema-card-name {
  font-size: var(--text-xs);
  display: block;
  margin-bottom: var(--space-1);
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
