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
                <div v-if="propertyItem?.format" class="meta-row">
                  <span class="meta-label">Format</span>
                  <span class="badge badge-format">{{ propertyItem.format }}</span>
                </div>
                <div v-if="itemDescription" class="meta-row">
                  <span class="meta-label">Description</span>
                  <span class="text-secondary">{{ itemDescription }}</span>
                </div>
                <div v-if="propertyItem" class="meta-row">
                  <span class="meta-label">Required</span>
                  <span :class="['badge', propertyItem.required ? 'badge-required' : 'badge-optional']">
                    {{ propertyItem.required ? 'Yes' : 'No' }}
                  </span>
                </div>
                <div v-if="propertyItem?.deprecated" class="meta-row">
                  <span class="meta-label">Status</span>
                  <span class="badge badge-deprecated">Deprecated</span>
                </div>
                <div v-if="propertyItem?.ref" class="meta-row">
                  <span class="meta-label">Reference</span>
                  <span class="font-mono text-secondary">{{ propertyItem.ref }}</span>
                </div>
                <div v-if="propertyItem?.compositionSource" class="meta-row">
                  <span class="meta-label">Source</span>
                  <span class="badge badge-composition-detail">{{ propertyItem.compositionSource }}</span>
                </div>
                <div v-if="propertyItem?.default" class="meta-row">
                  <span class="meta-label">Default</span>
                  <span class="font-mono">{{ propertyItem.default }}</span>
                </div>
                <div v-if="item.kind === 'schema' && schema.required.length" class="meta-row">
                  <span class="meta-label">Required</span>
                  <div class="meta-tags">
                    <span v-for="r in schema.required" :key="r" class="badge badge-required-sm">{{ r }}</span>
                  </div>
                </div>
                <div v-if="item.kind === 'schema' && schema.$schema" class="meta-row">
                  <span class="meta-label">JSON Schema</span>
                  <span class="font-mono text-secondary" style="font-size: var(--text-xs); word-break: break-all;">{{ schema.$schema }}</span>
                </div>
                <div v-if="item.kind === 'schema' && schema.$id" class="meta-row">
                  <span class="meta-label">$id</span>
                  <span class="font-mono text-secondary" style="font-size: var(--text-xs); word-break: break-all;">{{ schema.$id }}</span>
                </div>
                <div v-if="item.kind === 'schema' && (schema.hasAllOf || schema.hasAnyOf || schema.hasOneOf)" class="meta-row">
                  <span class="meta-label">Composition</span>
                  <div class="meta-tags">
                    <span v-if="schema.hasAllOf" class="badge badge-composition-detail">allOf</span>
                    <span v-if="schema.hasAnyOf" class="badge badge-composition-detail">anyOf</span>
                    <span v-if="schema.hasOneOf" class="badge badge-composition-detail">oneOf</span>
                  </div>
                </div>
                <div v-if="item.kind === 'schema' && (schema.minProperties != null || schema.maxProperties != null)" class="meta-row">
                  <span class="meta-label">Properties</span>
                  <span class="text-secondary">
                    <template v-if="schema.minProperties != null && schema.maxProperties != null">{{ schema.minProperties }}..{{ schema.maxProperties }}</template>
                    <template v-else-if="schema.minProperties != null">&ge; {{ schema.minProperties }}</template>
                    <template v-else>&le; {{ schema.maxProperties }}</template>
                  </span>
                </div>
                <div v-if="item.kind === 'schema' && schema.additionalProperties === false" class="meta-row">
                  <span class="meta-label">Additional</span>
                  <span class="badge badge-locked-detail">Denied</span>
                </div>
                <div v-if="definitionItem && definitionItem.required?.length" class="meta-row">
                  <span class="meta-label">Required</span>
                  <div class="meta-tags">
                    <span v-for="r in definitionItem.required" :key="r" class="badge badge-required-sm">{{ r }}</span>
                  </div>
                </div>
                <div v-if="definitionItem && (definitionItem.hasAllOf || definitionItem.hasAnyOf || definitionItem.hasOneOf)" class="meta-row">
                  <span class="meta-label">Composition</span>
                  <div class="meta-tags">
                    <span v-if="definitionItem.hasAllOf" class="badge badge-composition-detail">allOf</span>
                    <span v-if="definitionItem.hasAnyOf" class="badge badge-composition-detail">anyOf</span>
                    <span v-if="definitionItem.hasOneOf" class="badge badge-composition-detail">oneOf</span>
                  </div>
                </div>
                <div v-if="definitionItem && (definitionItem.minProperties != null || definitionItem.maxProperties != null)" class="meta-row">
                  <span class="meta-label">Properties</span>
                  <span class="text-secondary">
                    <template v-if="definitionItem.minProperties != null && definitionItem.maxProperties != null">{{ definitionItem.minProperties }}..{{ definitionItem.maxProperties }}</template>
                    <template v-else-if="definitionItem.minProperties != null">&ge; {{ definitionItem.minProperties }}</template>
                    <template v-else>&le; {{ definitionItem.maxProperties }}</template>
                  </span>
                </div>
                <div v-if="definitionItem && definitionItem.additionalProperties === false" class="meta-row">
                  <span class="meta-label">Additional</span>
                  <span class="badge badge-locked-detail">Denied</span>
                </div>
              </div>
            </div>

            <!-- Constraints for property -->
            <div v-if="propertyItem && hasConstraints" class="detail-section">
              <h3 class="detail-heading">Constraints</h3>
              <table class="table constraint-table">
                <tbody>
                  <tr v-if="propertyItem.minimum != null">
                    <td class="constraint-key">Minimum</td>
                    <td>{{ propertyItem.minimum }}</td>
                  </tr>
                  <tr v-if="propertyItem.maximum != null">
                    <td class="constraint-key">Maximum</td>
                    <td>{{ propertyItem.maximum }}</td>
                  </tr>
                  <tr v-if="propertyItem.minLength != null">
                    <td class="constraint-key">Min Length</td>
                    <td>{{ propertyItem.minLength }}</td>
                  </tr>
                  <tr v-if="propertyItem.maxLength != null">
                    <td class="constraint-key">Max Length</td>
                    <td>{{ propertyItem.maxLength }}</td>
                  </tr>
                  <tr v-if="propertyItem.pattern">
                    <td class="constraint-key">Pattern</td>
                    <td class="font-mono">{{ propertyItem.pattern }}</td>
                  </tr>
                  <tr v-if="propertyItem.enum?.length">
                    <td class="constraint-key">Enum</td>
                    <td>{{ propertyItem.enum.join(', ') }}</td>
                  </tr>
                  <tr v-if="propertyItem.itemsType">
                    <td class="constraint-key">Items</td>
                    <td>{{ propertyItem.itemsType }}</td>
                  </tr>
                  <tr v-if="propertyItem.exclusiveMinimum != null">
                    <td class="constraint-key">Exclusive Min</td>
                    <td>{{ propertyItem.exclusiveMinimum }}</td>
                  </tr>
                  <tr v-if="propertyItem.exclusiveMaximum != null">
                    <td class="constraint-key">Exclusive Max</td>
                    <td>{{ propertyItem.exclusiveMaximum }}</td>
                  </tr>
                  <tr v-if="propertyItem.minItems != null">
                    <td class="constraint-key">Min Items</td>
                    <td>{{ propertyItem.minItems }}</td>
                  </tr>
                  <tr v-if="propertyItem.maxItems != null">
                    <td class="constraint-key">Max Items</td>
                    <td>{{ propertyItem.maxItems }}</td>
                  </tr>
                  <tr v-if="propertyItem.uniqueItems">
                    <td class="constraint-key">Unique Items</td>
                    <td>Yes</td>
                  </tr>
                  <tr v-if="propertyItem.multipleOf != null">
                    <td class="constraint-key">Multiple Of</td>
                    <td>{{ propertyItem.multipleOf }}</td>
                  </tr>
                  <tr v-if="propertyItem.const != null">
                    <td class="constraint-key">Const</td>
                    <td class="font-mono">{{ propertyItem.const }}</td>
                  </tr>
                  <tr v-if="propertyItem.contentMediaType">
                    <td class="constraint-key">Content Type</td>
                    <td>{{ propertyItem.contentMediaType }}</td>
                  </tr>
                  <tr v-if="propertyItem.contentEncoding">
                    <td class="constraint-key">Content Encoding</td>
                    <td>{{ propertyItem.contentEncoding }}</td>
                  </tr>
                  <tr v-if="propertyItem.additionalProperties === false">
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

          <!-- Examples tab -->
          <template v-if="uiStore.activePanelTab === 'examples'">
            <div class="detail-section">
              <div v-if="examples.length" class="example-group">
                <h4 class="example-label">Provided Examples</h4>
                <div v-for="(ex, idx) in examples" :key="idx" class="example-block">
                  <pre class="example-pre"><code>{{ formatExample(ex) }}</code></pre>
                </div>
              </div>
              <div v-if="generatedExample" class="example-group">
                <h4 class="example-label">Generated Example</h4>
                <pre class="example-pre example-generated"><code>{{ generatedExample }}</code></pre>
              </div>
              <p v-if="!examples.length && !generatedExample" class="text-muted">No examples available.</p>
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

function formatExample(value: unknown): string {
  if (typeof value === 'string') {
    try { return JSON.stringify(JSON.parse(value), null, 2) } catch { return value }
  }
  return JSON.stringify(value, null, 2)
}

const hasConstraints = computed(() => {
  const p = propertyItem.value
  if (!p) return false
  return p.minimum != null || p.maximum != null ||
    p.minLength != null || p.maxLength != null ||
    p.pattern || p.enum?.length || p.itemsType ||
    p.exclusiveMinimum != null || p.exclusiveMaximum != null ||
    p.minItems != null || p.maxItems != null || p.uniqueItems ||
    p.multipleOf != null || p.const != null ||
    p.contentMediaType || p.contentEncoding
})

type TabId = 'overview' | 'properties' | 'examples'

const examples = computed(() => {
  if (!item.value) return []
  switch (item.value.kind) {
    case 'schema': return item.value.schema.examples ?? []
    case 'definition': return item.value.definition.examples ?? []
    case 'property': return item.value.property.examples ?? []
  }
})

const generatedExample = computed(() => {
  if (!item.value) return null
  if (item.value.kind === 'property') {
    const p = item.value.property
    if (p.default != null) return p.default
    if (p.const != null) return p.const
    if (p.enum?.length) return p.enum[0]
    if (p.examples?.length) return p.examples[0]
    const t = p.type?.split(',')[0]?.trim() || 'any'
    switch (t) {
      case 'string': return p.format === 'email' ? 'user@example.com' : p.format === 'uri' ? 'https://example.com' : '"string"'
      case 'integer': return '0'
      case 'number': return '0.0'
      case 'boolean': return 'false'
      case 'array': return '[]'
      case 'object': return '{}'
      default: return null
    }
  }
  if (item.value.kind === 'schema' || item.value.kind === 'definition') {
    const props = item.value.kind === 'schema' ? item.value.schema.properties : item.value.definition.properties
    const req = item.value.kind === 'schema' ? item.value.schema.required : item.value.definition.required
    const obj: Record<string, unknown> = {}
    for (const prop of props) {
      if (prop.default != null) { obj[prop.name] = prop.default; continue }
      if (prop.const != null) { obj[prop.name] = prop.const; continue }
      if (prop.enum?.length) { obj[prop.name] = prop.enum[0]; continue }
      if (prop.examples?.length) { obj[prop.name] = prop.examples[0]; continue }
      const t = prop.type?.split(',')[0]?.trim() || 'any'
      switch (t) {
        case 'string': obj[prop.name] = prop.format === 'email' ? 'user@example.com' : prop.format === 'uri' ? 'https://example.com' : 'string'; break
        case 'integer': obj[prop.name] = 0; break
        case 'number': obj[prop.name] = 0; break
        case 'boolean': obj[prop.name] = false; break
        case 'array': obj[prop.name] = []; break
        default: obj[prop.name] = null
      }
    }
    return JSON.stringify(obj, null, 2)
  }
  return null
})

const currentTabs = computed<{ id: TabId; label: string }[]>(() => {
  const tabs: { id: TabId; label: string }[] = [
    { id: 'overview', label: 'Overview' },
  ]
  if (properties.value.length > 0) {
    tabs.push({ id: 'properties', label: `Properties (${properties.value.length})` })
  }
  if (examples.value.length > 0 || generatedExample.value) {
    const count = examples.value.length || 1
    tabs.push({ id: 'examples', label: `Examples (${count})` })
  }
  return tabs
})

const propertyItem = computed<SpaProperty | null>(() => {
  if (item.value?.kind !== 'property') return null
  return item.value.property
})

const definitionItem = computed(() => {
  if (item.value?.kind !== 'definition') return null
  return item.value.definition
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

.badge-composition-detail {
  font-size: 11px;
  color: var(--color-teal);
  background: var(--color-teal-alpha);
  padding: 1px 6px;
  border-radius: var(--radius-sm);
  font-family: var(--font-mono);
  font-weight: 500;
}

.badge-locked-detail {
  font-size: 11px;
  color: var(--color-orange);
  background: var(--color-orange-alpha);
  padding: 1px 6px;
  border-radius: var(--radius-sm);
  font-weight: 500;
}

.constraint-table td:first-child {
  font-weight: 500;
  color: var(--text-secondary);
  width: 120px;
}

.constraint-key {
  white-space: nowrap;
}

/* Examples */
.example-group {
  margin-bottom: var(--space-4);
}

.example-label {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-secondary);
  margin-bottom: var(--space-2);
}

.example-block {
  margin-bottom: var(--space-2);
}

.example-pre {
  background: var(--bg-secondary);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-md);
  padding: var(--space-3);
  font-size: var(--text-sm);
  overflow-x: auto;
  margin: 0;
}

.example-pre code {
  font-family: var(--font-mono);
  color: var(--text-primary);
}

.example-generated {
  border-color: var(--color-primary-alpha);
}
</style>
