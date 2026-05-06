<template>
  <div class="detail-panel-overlay" @click.self="uiStore.closeDetailPanel">
    <aside class="detail-panel">
      <div class="panel-header">
        <div class="panel-title">
          <h2 v-if="item">{{ itemTitle }}</h2>
        </div>
        <button class="btn btn-ghost" @click="uiStore.closeDetailPanel">
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none">
            <path d="M5 5l8 8M13 5l-8 8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
          </svg>
        </button>
      </div>

      <div v-if="item" class="panel-tabs">
        <button
          v-for="tab in currentTabs"
          :key="tab.id"
          class="panel-tab"
          :class="{ active: uiStore.activePanelTab === tab.id }"
          @click="uiStore.setPanelTab(tab.id)"
        >
          {{ tab.label }}
        </button>
      </div>

      <div class="panel-content">
        <template v-if="item">
          <!-- Overview tab -->
          <template v-if="uiStore.activePanelTab === 'overview'">
            <div class="detail-section">
              <div class="detail-meta">
                <div v-if="item.kind === 'schema' || item.kind === 'definition'" class="meta-row">
                  <span class="meta-label">Type</span>
                  <span class="badge badge-type">{{ itemType }}</span>
                </div>
                <div v-if="item.kind === 'property' && (item as any).property.format" class="meta-row">
                  <span class="meta-label">Format</span>
                  <span class="badge badge-format">{{ (item as any).property.format }}</span>
                </div>
                <div v-if="itemDescription" class="meta-row">
                  <span class="meta-label">Description</span>
                  <span class="text-secondary">{{ itemDescription }}</span>
                </div>
                <div v-if="item.kind === 'property'" class="meta-row">
                  <span class="meta-label">Required</span>
                  <span :class="['badge', (item as any).property.required ? 'badge-required' : 'badge-optional']">
                    {{ (item as any).property.required ? 'Yes' : 'No' }}
                  </span>
                </div>
                <div v-if="item.kind === 'property' && (item as any).property.deprecated" class="meta-row">
                  <span class="meta-label">Status</span>
                  <span class="badge badge-deprecated">Deprecated</span>
                </div>
                <div v-if="item.kind === 'property' && (item as any).property.ref" class="meta-row">
                  <span class="meta-label">Reference</span>
                  <span class="font-mono text-secondary">{{ (item as any).property.ref }}</span>
                </div>
                <div v-if="item.kind === 'property' && (item as any).property.default" class="meta-row">
                  <span class="meta-label">Default</span>
                  <span class="font-mono">{{ (item as any).property.default }}</span>
                </div>
                <div v-if="item.kind === 'schema' && schema.required.length" class="meta-row">
                  <span class="meta-label">Required</span>
                  <div class="meta-tags">
                    <span v-for="r in schema.required" :key="r" class="badge badge-required-sm">{{ r }}</span>
                  </div>
                </div>
              </div>
            </div>

            <!-- Constraints for property -->
            <div v-if="item.kind === 'property' && hasConstraints" class="detail-section">
              <h3 class="detail-heading">Constraints</h3>
              <table class="table constraint-table">
                <tbody>
                  <tr v-if="(item as any).property.minimum != null">
                    <td class="constraint-key">Minimum</td>
                    <td>{{ (item as any).property.minimum }}</td>
                  </tr>
                  <tr v-if="(item as any).property.maximum != null">
                    <td class="constraint-key">Maximum</td>
                    <td>{{ (item as any).property.maximum }}</td>
                  </tr>
                  <tr v-if="(item as any).property.minLength != null">
                    <td class="constraint-key">Min Length</td>
                    <td>{{ (item as any).property.minLength }}</td>
                  </tr>
                  <tr v-if="(item as any).property.maxLength != null">
                    <td class="constraint-key">Max Length</td>
                    <td>{{ (item as any).property.maxLength }}</td>
                  </tr>
                  <tr v-if="(item as any).property.pattern">
                    <td class="constraint-key">Pattern</td>
                    <td class="font-mono">{{ (item as any).property.pattern }}</td>
                  </tr>
                  <tr v-if="(item as any).property.enum?.length">
                    <td class="constraint-key">Enum</td>
                    <td>{{ (item as any).property.enum.join(', ') }}</td>
                  </tr>
                  <tr v-if="(item as any).property.itemsType">
                    <td class="constraint-key">Items</td>
                    <td>{{ (item as any).property.itemsType }}</td>
                  </tr>
                  <tr v-if="(item as any).property.exclusiveMinimum != null">
                    <td class="constraint-key">Exclusive Min</td>
                    <td>{{ (item as any).property.exclusiveMinimum }}</td>
                  </tr>
                  <tr v-if="(item as any).property.exclusiveMaximum != null">
                    <td class="constraint-key">Exclusive Max</td>
                    <td>{{ (item as any).property.exclusiveMaximum }}</td>
                  </tr>
                  <tr v-if="(item as any).property.minItems != null">
                    <td class="constraint-key">Min Items</td>
                    <td>{{ (item as any).property.minItems }}</td>
                  </tr>
                  <tr v-if="(item as any).property.maxItems != null">
                    <td class="constraint-key">Max Items</td>
                    <td>{{ (item as any).property.maxItems }}</td>
                  </tr>
                  <tr v-if="(item as any).property.uniqueItems">
                    <td class="constraint-key">Unique Items</td>
                    <td>Yes</td>
                  </tr>
                  <tr v-if="(item as any).property.multipleOf != null">
                    <td class="constraint-key">Multiple Of</td>
                    <td>{{ (item as any).property.multipleOf }}</td>
                  </tr>
                  <tr v-if="(item as any).property.const != null">
                    <td class="constraint-key">Const</td>
                    <td class="font-mono">{{ (item as any).property.const }}</td>
                  </tr>
                  <tr v-if="(item as any).property.contentMediaType">
                    <td class="constraint-key">Content Type</td>
                    <td>{{ (item as any).property.contentMediaType }}</td>
                  </tr>
                  <tr v-if="(item as any).property.contentEncoding">
                    <td class="constraint-key">Content Encoding</td>
                    <td>{{ (item as any).property.contentEncoding }}</td>
                  </tr>
                  <tr v-if="(item as any).property.additionalProperties === false">
                    <td class="constraint-key">Additional Props</td>
                    <td>Denied</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </template>

          <!-- Properties/Definition tab -->
          <template v-if="uiStore.activePanelTab === 'properties'">
            <div class="detail-section">
              <table v-if="properties.length" class="table">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Type</th>
                    <th>Required</th>
                    <th>Description</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="prop in properties" :key="prop.name">
                    <td>
                      <span class="font-mono">{{ prop.name }}</span>
                      <span v-if="prop.deprecated" class="badge badge-deprecated-sm">deprecated</span>
                    </td>
                    <td>
                      <span class="prop-type">{{ prop.type || 'any' }}</span>
                      <span v-if="prop.format" class="prop-format">{{ prop.format }}</span>
                      <span v-if="prop.itemsType" class="prop-format">[{{ prop.itemsType }}]</span>
                    </td>
                    <td>
                      <span v-if="prop.required" class="badge badge-required-sm">yes</span>
                      <span v-else class="text-muted">no</span>
                    </td>
                    <td class="text-secondary">{{ prop.description || '—' }}</td>
                  </tr>
                </tbody>
              </table>
              <p v-else class="text-muted">No properties defined.</p>
            </div>
          </template>
        </template>

        <div v-else class="panel-empty">
          <p>Select an item to view details</p>
        </div>
      </div>
    </aside>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useSchemaStore, type SelectedItem } from '../stores/schemaStore'
import { useUiStore } from '../stores/uiStore'
import type { SpaProperty } from '../types'

const schemaStore = useSchemaStore()
const uiStore = useUiStore()

const item = computed<SelectedItem | null>(() => schemaStore.selectedItem)
const schema = computed(() => schemaStore.selectedSchema)

const itemTitle = computed(() => {
  if (!item.value) return ''
  switch (item.value.kind) {
    case 'schema': return item.value.schema.title || item.value.schema.name
    case 'definition': return item.value.definition.title || item.value.definition.name
    case 'property': return item.value.property.name
  }
})

const itemType = computed(() => {
  if (!item.value) return ''
  switch (item.value.kind) {
    case 'schema': return item.value.schema.type || 'any'
    case 'definition': return item.value.definition.type || 'any'
    case 'property': return item.value.property.type || 'any'
  }
})

const itemDescription = computed(() => {
  if (!item.value) return ''
  switch (item.value.kind) {
    case 'schema': return item.value.schema.description
    case 'definition': return item.value.definition.description
    case 'property': return item.value.property.description
  }
})

const properties = computed<SpaProperty[]>(() => {
  if (!item.value) return []
  switch (item.value.kind) {
    case 'schema': return item.value.schema.properties
    case 'definition': return item.value.definition.properties
    case 'property': return []
  }
})

const hasConstraints = computed(() => {
  if (item.value?.kind !== 'property') return false
  const p = item.value.property
  return p.minimum != null || p.maximum != null ||
    p.minLength != null || p.maxLength != null ||
    p.pattern || p.enum?.length || p.itemsType ||
    p.exclusiveMinimum != null || p.exclusiveMaximum != null ||
    p.minItems != null || p.maxItems != null || p.uniqueItems ||
    p.multipleOf != null || p.const != null ||
    p.contentMediaType || p.contentEncoding
})

type TabId = 'overview' | 'properties'

const currentTabs = computed<{ id: TabId; label: string }[]>(() => {
  const tabs: { id: TabId; label: string }[] = [
    { id: 'overview', label: 'Overview' },
  ]
  if (properties.value.length > 0) {
    tabs.push({ id: 'properties', label: `Properties (${properties.value.length})` })
  }
  return tabs
})
</script>

<style scoped>
.detail-panel-overlay {
  position: fixed;
  inset: 0;
  background: var(--bg-overlay);
  display: flex;
  justify-content: flex-end;
  z-index: 100;
  animation: fadeIn var(--transition-fast);
}

.detail-panel {
  width: 100%;
  max-width: 640px;
  height: 100%;
  background: var(--bg-elevated);
  box-shadow: var(--shadow-lg);
  display: flex;
  flex-direction: column;
  animation: slideIn var(--transition-slow);
}

.panel-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-4) var(--space-5);
  border-bottom: 1px solid var(--border-light);
  flex-shrink: 0;
}

.panel-title h2 {
  font-size: var(--text-lg);
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.panel-tabs {
  display: flex;
  gap: var(--space-1);
  padding: var(--space-2) var(--space-5);
  border-bottom: 1px solid var(--border-light);
  flex-shrink: 0;
}

.panel-tab {
  padding: var(--space-2) var(--space-3);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-muted);
  border-radius: var(--radius-md);
  transition: all var(--transition-fast);
}

.panel-tab:hover {
  color: var(--text-primary);
  background: var(--bg-hover);
}

.panel-tab.active {
  color: var(--color-primary);
  background: var(--color-primary-alpha);
}

.panel-content {
  flex: 1;
  overflow-y: auto;
  padding: var(--space-5);
}

.panel-empty {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  color: var(--text-muted);
  font-size: var(--text-sm);
}

.detail-section {
  margin-bottom: var(--space-6);
}

.detail-heading {
  font-size: var(--text-base);
  font-weight: 600;
  margin-bottom: var(--space-3);
  color: var(--text-primary);
}

.detail-meta {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}

.meta-row {
  display: flex;
  align-items: flex-start;
  gap: var(--space-3);
}

.meta-label {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-muted);
  min-width: 80px;
  flex-shrink: 0;
}

.meta-tags {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
}

.prop-type {
  color: var(--color-primary);
  font-weight: 500;
}

.prop-format {
  font-size: var(--text-xs);
  color: var(--text-muted);
  margin-left: var(--space-1);
}

.badge-type {
  background: var(--badge-schema-bg);
  color: var(--badge-schema);
}

.badge-format {
  background: var(--bg-secondary);
  color: var(--text-secondary);
}

.badge-required {
  background: var(--badge-required-bg);
  color: var(--badge-required);
}

.badge-optional {
  background: var(--bg-secondary);
  color: var(--text-muted);
}

.badge-deprecated {
  background: var(--badge-deprecated-bg);
  color: var(--badge-deprecated);
}

.badge-required-sm {
  background: var(--badge-required-bg);
  color: var(--badge-required);
  font-size: 10px;
  padding: 1px 4px;
  border-radius: 2px;
}

.badge-deprecated-sm {
  background: var(--badge-deprecated-bg);
  color: var(--badge-deprecated);
  font-size: 10px;
  padding: 1px 4px;
  border-radius: 2px;
  margin-left: 4px;
}

.constraint-table td:first-child {
  font-weight: 500;
  color: var(--text-secondary);
  width: 120px;
}

.constraint-key {
  white-space: nowrap;
}
</style>
