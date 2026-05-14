<template>
  <div class="detail-panel-overlay" @click.self="uiStore.closeDetailPanel">
    <aside class="detail-panel" ref="panelRef">
      <div class="panel-header">
        <div class="panel-title">
          <h2 v-if="item">{{ itemTitle }}</h2>
        </div>
        <button ref="closeBtnRef" class="btn btn-ghost" @click="uiStore.closeDetailPanel" aria-label="Close panel">
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
                  <span class="text-secondary md-content" v-html="renderInlineMarkdown(itemDescription)"></span>
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
                <div v-if="propertyItem?.readOnly" class="meta-row">
                  <span class="meta-label">Access</span>
                  <span class="badge badge-readonly-detail">Read-only</span>
                </div>
                <div v-if="propertyItem?.writeOnly" class="meta-row">
                  <span class="meta-label">Access</span>
                  <span class="badge badge-writeonly-detail">Write-only</span>
                </div>
                <div v-if="propertyItem?.ref" class="meta-row">
                  <span class="meta-label">Reference</span>
                  <span class="ref-link font-mono" role="button" tabindex="0" @click="navigateToRef(propertyItem.ref)" @keydown.enter="navigateToRef(propertyItem.ref)">{{ propertyItem.ref }}</span>
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
                <div v-if="item.kind === 'schema'" class="meta-row">
                  <span class="meta-label">Properties</span>
                  <span class="text-secondary">{{ schema.properties.length }}</span>
                </div>
                <div v-if="item.kind === 'schema' && schema.definitions.length" class="meta-row">
                  <span class="meta-label">Definitions</span>
                  <span class="text-secondary">{{ schema.definitions.length }}</span>
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
                  <tr v-if="propertyItem.minimum != null || propertyItem.maximum != null || propertyItem.exclusiveMinimum != null || propertyItem.exclusiveMaximum != null">
                    <td class="constraint-key">Range</td>
                    <td class="constraint-value">{{ numberRangeLabel }}</td>
                  </tr>
                  <tr v-if="propertyItem.minLength != null || propertyItem.maxLength != null">
                    <td class="constraint-key">Length</td>
                    <td class="constraint-value">{{ stringRangeLabel }}</td>
                  </tr>
                  <tr v-if="propertyItem.minItems != null || propertyItem.maxItems != null">
                    <td class="constraint-key">Items</td>
                    <td class="constraint-value">{{ itemsRangeLabel }}</td>
                  </tr>
                  <tr v-if="propertyItem.pattern">
                    <td class="constraint-key">Pattern</td>
                    <td class="constraint-value font-mono constraint-pattern">{{ propertyItem.pattern }}</td>
                  </tr>
                  <tr v-if="propertyItem.enum?.length">
                    <td class="constraint-key">Enum</td>
                    <td>
                      <div class="enum-values-list">
                        <span v-for="e in visibleEnumValues(propertyItem.name, propertyItem.enum)" :key="e" class="enum-value-chip">{{ e }}</span>
                        <button v-if="propertyItem.enum.length > 8 && !detailEnumExpanded.has(propertyItem.name)" class="enum-more-btn" @click="toggleDetailEnum(propertyItem.name)">+{{ propertyItem.enum.length - 8 }} more</button>
                      </div>
                    </td>
                  </tr>
                  <tr v-if="propertyItem.itemsType">
                    <td class="constraint-key">Items Type</td>
                    <td class="constraint-value">{{ propertyItem.itemsType }}</td>
                  </tr>
                  <tr v-if="propertyItem.uniqueItems">
                    <td class="constraint-key">Unique Items</td>
                    <td class="constraint-value"><span class="constraint-yes">Yes</span></td>
                  </tr>
                  <tr v-if="propertyItem.multipleOf != null">
                    <td class="constraint-key">Multiple Of</td>
                    <td class="constraint-value">{{ propertyItem.multipleOf }}</td>
                  </tr>
                  <tr v-if="propertyItem.const != null">
                    <td class="constraint-key">Const</td>
                    <td class="constraint-value font-mono">{{ propertyItem.const }}</td>
                  </tr>
                  <tr v-if="propertyItem.contentMediaType">
                    <td class="constraint-key">Content Type</td>
                    <td class="constraint-value">{{ propertyItem.contentMediaType }}</td>
                  </tr>
                  <tr v-if="propertyItem.contentEncoding">
                    <td class="constraint-key">Content Encoding</td>
                    <td class="constraint-value">{{ propertyItem.contentEncoding }}</td>
                  </tr>
                  <tr v-if="propertyItem.additionalProperties === false">
                    <td class="constraint-key">Additional Props</td>
                    <td class="constraint-value"><span class="constraint-denied">Denied</span></td>
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
                  <tr v-for="prop in properties" :key="prop.name" class="prop-row" @click="navigateToProperty(prop.name)">
                    <td>
                      <span class="font-mono">{{ prop.name }}</span>
                      <span v-if="prop.title && prop.title !== prop.name" class="prop-title">({{ prop.title }})</span>
                      <span v-if="prop.deprecated" class="badge badge-deprecated-sm">deprecated</span>
                    </td>
                    <td>
                      <span v-if="prop.ref" class="prop-ref-link" role="button" tabindex="0" @click.stop="navigateToRef(prop.ref)">{{ prop.type || 'object' }} → {{ refName(prop.ref) }}</span>
                      <template v-else>
                        <span class="prop-type-badge" :class="propTypeClass(prop.type)">{{ prop.type || 'any' }}</span>
                        <span v-if="prop.format" class="prop-format">&lt;{{ prop.format }}&gt;</span>
                        <span v-if="prop.itemsType" class="prop-format">[{{ prop.itemsType }}]</span>
                      </template>
                      <span v-if="prop.default != null" class="prop-default">default: {{ prop.default }}</span>
                      <span v-if="prop.enum?.length" class="prop-enum">{{ prop.enum.length }} values</span>
                    </td>
                    <td>
                      <span v-if="prop.required" class="badge badge-required-sm">yes</span>
                      <span v-else class="text-muted">no</span>
                    </td>
                    <td>
                      <span v-if="prop.description" class="text-secondary md-content" v-html="renderInlineMarkdown(prop.description)"></span>
                      <span v-else class="text-muted">—</span>
                      <div v-if="prop.examples?.length" class="prop-examples">
                        <span class="prop-examples-label">Examples:</span>
                        <span v-for="(ex, i) in prop.examples.slice(0, 3)" :key="i" class="prop-example-chip">{{ typeof ex === 'object' ? JSON.stringify(ex) : ex }}</span>
                        <span v-if="prop.examples.length > 3" class="text-muted">+{{ prop.examples.length - 3 }} more</span>
                      </div>
                    </td>
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
                  <div v-if="isComplexExample(ex)" class="example-collapsible" @click="toggleExampleCollapse($event)" @keydown="handleExampleKey($event)">
                    <pre class="example-pre jv-viewer" v-html="renderExampleHtml(ex)"></pre>
                  </div>
                  <pre v-else class="example-pre"><code>{{ formatExample(ex) }}</code></pre>
                </div>
              </div>
              <div v-if="generatedExample" class="example-group">
                <h4 class="example-label">Generated Example</h4>
                <pre class="example-pre example-generated jv-viewer" v-html="renderExampleHtml(generatedExample)"></pre>
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
import { computed, ref, reactive, onMounted, onUnmounted } from 'vue'
import { useSchemaStore, type SelectedItem } from '../stores/schemaStore'
import { useUiStore } from '../stores/uiStore'
import { renderInlineMarkdown } from '../composables/useMarkdownLite'
import { jsonToCollapsibleHtml } from '../composables/useJsonViewer'
import type { SpaProperty } from '../types'

const schemaStore = useSchemaStore()
const uiStore = useUiStore()

const panelRef = ref<HTMLElement | null>(null)
const closeBtnRef = ref<HTMLButtonElement | null>(null)
const detailEnumExpanded = reactive(new Set<string>())

function visibleEnumValues(name: string, enums: string[]): string[] {
  if (detailEnumExpanded.has(name) || enums.length <= 8) return enums
  return enums.slice(0, 8)
}

function toggleDetailEnum(name: string) {
  if (detailEnumExpanded.has(name)) detailEnumExpanded.delete(name)
  else detailEnumExpanded.add(name)
}

onMounted(() => {
  closeBtnRef.value?.focus()
  document.addEventListener('keydown', trapFocus)
})

onUnmounted(() => {
  document.removeEventListener('keydown', trapFocus)
})

function trapFocus(e: KeyboardEvent) {
  if (e.key !== 'Tab' || !panelRef.value) return
  const focusable = panelRef.value.querySelectorAll<HTMLElement>(
    'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])',
  )
  if (!focusable.length) return
  const first = focusable[0]
  const last = focusable[focusable.length - 1]
  if (e.shiftKey) {
    if (document.activeElement === first) { e.preventDefault(); last.focus() }
  } else {
    if (document.activeElement === last) { e.preventDefault(); first.focus() }
  }
}

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
    p.contentMediaType || p.contentEncoding ||
    p.additionalProperties === false
})

const numberRangeLabel = computed(() => {
  const p = propertyItem.value
  if (!p) return ''
  const hasMin = p.minimum != null
  const hasMax = p.maximum != null
  const excMin = p.exclusiveMinimum != null
  const excMax = p.exclusiveMaximum != null
  if (hasMin && hasMax) {
    return `${excMin ? '( ' : '[ '}${p.minimum} .. ${p.maximum}${excMax ? ' )' : ' ]'}`
  }
  if (excMin && excMax) return `( ${p.exclusiveMinimum} .. ${p.exclusiveMaximum} )`
  if (hasMin) return `${excMin ? '> ' : '>= '}${p.minimum}`
  if (hasMax) return `${excMax ? '< ' : '<= '}${p.maximum}`
  if (excMin) return `> ${p.exclusiveMinimum}`
  if (excMax) return `< ${p.exclusiveMaximum}`
  return ''
})

const stringRangeLabel = computed(() => {
  const p = propertyItem.value
  if (!p) return ''
  if (p.minLength != null && p.maxLength != null) {
    if (p.minLength === p.maxLength) return `= ${p.minLength} characters`
    return `[ ${p.minLength} .. ${p.maxLength} ] characters`
  }
  if (p.minLength != null) return p.minLength === 1 ? 'non-empty' : `>= ${p.minLength} characters`
  if (p.maxLength != null) return `<= ${p.maxLength} characters`
  return ''
})

const itemsRangeLabel = computed(() => {
  const p = propertyItem.value
  if (!p) return ''
  if (p.minItems != null && p.maxItems != null) {
    if (p.minItems === p.maxItems) return `= ${p.minItems} items`
    return `[ ${p.minItems} .. ${p.maxItems} ] items`
  }
  if (p.minItems != null) return p.minItems === 1 ? 'non-empty' : `>= ${p.minItems} items`
  if (p.maxItems != null) return `<= ${p.maxItems} items`
  return ''
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

function navigateToRef(ref: string | undefined) {
  if (!ref) return
  const match = ref.match(/^#\/(?:definitions|\$defs)\/([^/]+)$/)
  if (match) {
    uiStore.closeDetailPanel()
    schemaStore.selectDefinition(match[1])
  }
}

function refName(ref: string): string {
  const match = ref.match(/^#\/(?:definitions|\$defs)\/([^/]+)$/)
  return match ? match[1] : ref
}

function navigateToProperty(name: string) {
  uiStore.closeDetailPanel()
  schemaStore.selectProperty(name)
}

function isComplexExample(value: unknown): boolean {
  if (typeof value === 'string') {
    try { return typeof JSON.parse(value) === 'object' } catch { return false }
  }
  return typeof value === 'object' && value !== null
}

function renderExampleHtml(value: unknown): string {
  let parsed: unknown
  if (typeof value === 'string') {
    try { parsed = JSON.parse(value) } catch { return escapeHtml(value) }
  } else {
    parsed = value
  }
  try {
    return jsonToCollapsibleHtml(parsed, 3)
  } catch {
    return escapeHtml(typeof parsed === 'string' ? parsed : JSON.stringify(parsed, null, 2))
  }
}

function propTypeClass(type?: string): string {
  const t = (type || 'any').split(',')[0].trim()
  switch (t) {
    case 'string': return 'ptype-string'
    case 'number': return 'ptype-number'
    case 'integer': return 'ptype-integer'
    case 'boolean': return 'ptype-boolean'
    case 'object': return 'ptype-object'
    case 'array': return 'ptype-array'
    case 'null': return 'ptype-null'
    default: return ''
  }
}

function escapeHtml(t: string): string {
  return t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

function toggleExampleCollapse(event: MouseEvent) {
  const target = event.target as HTMLElement
  if (!target.classList.contains('jv-toggle')) return
  const parent = target.parentElement
  if (!parent) return
  const children = parent.querySelector('.jv-children')
  if (!children) return
  const isCollapsed = children.classList.contains('jv-collapsed')
  if (isCollapsed) {
    children.classList.remove('jv-collapsed')
    target.setAttribute('aria-label', 'collapse')
  } else {
    children.classList.add('jv-collapsed')
    target.setAttribute('aria-label', 'expand')
  }
}

function handleExampleKey(event: KeyboardEvent) {
  if (event.key !== 'Enter' && event.key !== ' ') return
  const target = event.target as HTMLElement
  if (!target.classList.contains('jv-toggle')) return
  event.preventDefault()
  toggleExampleCollapse(event as unknown as MouseEvent)
}
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
  font-size: var(--text-sm);
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  margin-bottom: var(--space-3);
  color: var(--text-secondary);
  padding-bottom: var(--space-2);
  border-bottom: 1px solid var(--border-light);
  position: relative;
}

.detail-heading::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 0;
  width: 32px;
  height: 2px;
  background: var(--color-primary);
  border-radius: 1px;
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

.prop-type-badge {
  font-size: 11px;
  font-weight: 500;
  font-family: var(--font-mono);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
  background: var(--badge-schema-bg);
  color: var(--badge-schema);
}

.prop-type-badge.ptype-string { background: var(--type-string-bg); color: var(--type-string); }
.prop-type-badge.ptype-number { background: var(--type-number-bg); color: var(--type-number); }
.prop-type-badge.ptype-integer { background: var(--type-integer-bg); color: var(--type-integer); }
.prop-type-badge.ptype-boolean { background: var(--type-boolean-bg); color: var(--type-boolean); }
.prop-type-badge.ptype-object { background: var(--type-object-bg); color: var(--type-object); }
.prop-type-badge.ptype-array { background: var(--type-array-bg); color: var(--type-array); }
.prop-type-badge.ptype-null { background: var(--type-null-bg); color: var(--type-null); }

.prop-format {
  font-size: var(--text-xs);
  color: var(--color-accent);
  margin-left: var(--space-1);
  font-family: var(--font-mono);
}

.prop-row {
  cursor: pointer;
  transition: background var(--transition-fast);
}

.prop-row:hover {
  background: var(--bg-hover);
}

.prop-ref-link {
  color: var(--color-primary);
  cursor: pointer;
  font-family: var(--font-mono);
  font-size: var(--text-xs);
}

.prop-ref-link:hover {
  text-decoration: underline;
}

.prop-title {
  display: block;
  font-size: var(--text-xs);
  color: var(--text-secondary);
  font-style: italic;
}

.prop-default {
  display: block;
  font-size: 10px;
  color: var(--text-muted);
  font-family: var(--font-mono);
}

.prop-enum {
  display: block;
  font-size: 10px;
  color: var(--color-teal);
  background: var(--color-teal-alpha);
  padding: 1px 4px;
  border-radius: 2px;
  display: inline-block;
  margin-top: 2px;
}

.prop-examples {
  margin-top: var(--space-1);
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  align-items: center;
}

.prop-examples-label {
  font-size: 10px;
  color: var(--text-muted);
  font-weight: 500;
}

.prop-example-chip {
  font-size: 10px;
  font-family: var(--font-mono);
  background: rgba(28, 25, 23, 0.05);
  padding: 1px 5px;
  border-radius: 2px;
  border: 1px solid rgba(28, 25, 23, 0.1);
  color: var(--text-secondary);
  word-break: break-word;
}

:root[data-theme="dark"] .prop-example-chip {
  background: rgba(255, 255, 255, 0.06);
  border-color: rgba(255, 255, 255, 0.1);
}

.badge-type {
  background: var(--badge-schema-bg);
  color: var(--badge-schema);
  font-family: var(--font-mono);
  font-size: var(--schema-labels-size);
}

.badge-format {
  background: var(--bg-secondary);
  color: var(--text-secondary);
}

.badge-required {
  background: var(--schema-require-bg);
  color: var(--schema-require-label);
}

.badge-optional {
  background: var(--bg-secondary);
  color: var(--text-muted);
}

.badge-deprecated {
  background: var(--color-orange-alpha);
  color: var(--color-orange);
  font-size: var(--text-xs);
  padding: 2px 6px;
  border-radius: var(--radius-sm);
  font-weight: 500;
}

.badge-required-sm {
  background: var(--schema-require-bg);
  color: var(--schema-require-label);
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

.badge-readonly-detail {
  font-size: 11px;
  color: var(--color-teal);
  background: var(--color-teal-alpha);
  padding: 1px 6px;
  border-radius: var(--radius-sm);
  font-weight: 500;
}

.badge-writeonly-detail {
  font-size: 11px;
  color: var(--color-orange);
  background: var(--color-orange-alpha);
  padding: 1px 6px;
  border-radius: var(--radius-sm);
  font-weight: 500;
}

.ref-link {
  color: var(--color-primary);
  cursor: pointer;
  font-size: var(--text-xs);
  word-break: break-all;
}

.ref-link:hover {
  text-decoration: underline;
}

.enum-values-list {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
}

.enum-value-chip {
  font-size: 11px;
  font-family: var(--font-mono);
  background: rgba(28, 25, 23, 0.05);
  border: 1px solid rgba(28, 25, 23, 0.1);
  padding: 1px 5px;
  border-radius: 2px;
  color: var(--text-primary);
  word-break: break-word;
}

.enum-more-btn {
  font-size: 11px;
  color: var(--color-primary);
  background: none;
  border: none;
  cursor: pointer;
  padding: 1px 4px;
  font-family: var(--font-mono);
}

.enum-more-btn:hover {
  text-decoration: underline;
}

.constraint-table td:first-child {
  font-weight: 500;
  color: var(--text-secondary);
  width: 120px;
}

.constraint-key {
  white-space: nowrap;
}

.constraint-value {
  font-family: var(--font-mono);
  font-size: var(--text-sm);
}

.constraint-pattern {
  word-break: break-all;
  color: var(--color-teal);
  background: var(--color-teal-alpha);
  padding: 1px 4px;
  border-radius: var(--radius-sm);
}

.constraint-yes {
  color: var(--color-teal);
  background: var(--color-teal-alpha);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
  font-size: var(--text-xs);
  font-weight: 500;
}

.constraint-denied {
  color: var(--color-orange);
  background: var(--color-orange-alpha);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
  font-size: var(--text-xs);
  font-weight: 500;
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
  position: relative;
}

.example-group:has(.example-generated) .example-label::after {
  content: ' auto-generated';
  font-size: 10px;
  font-weight: 400;
  color: var(--text-muted);
  text-transform: none;
  font-style: italic;
}

.example-collapsible {
  cursor: default;
}

/* Dark mode overrides *//* Dark mode overrides */
:root[data-theme="dark"] .detail-panel {
  border-left: 1px solid rgba(255, 255, 255, 0.08);
}

:root[data-theme="dark"] .enum-value-chip {
  background: rgba(255, 255, 255, 0.06);
  border-color: rgba(255, 255, 255, 0.12);
}

:root[data-theme="dark"] .example-pre {
  background: rgba(0, 0, 0, 0.15);
  border-color: rgba(255, 255, 255, 0.08);
}
</style>
