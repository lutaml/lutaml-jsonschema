<template>
  <div class="builder-layout">
    <div class="builder-fields">
      <div v-for="(field, idx) in sortedFields" :key="field.prop.name" :id="`prop-${field.prop.name}`" class="field-row" :class="{ 'field-row-alt': idx % 2 === 1, [`depth-${depth % 3}`]: depth > 0 }">
        <div class="field-main">
          <input
            type="checkbox"
            :checked="field.included"
            :disabled="field.isRequired"
            class="field-check"
            :aria-label="`Include ${field.prop.name}`"
            @change="toggleField(field, ($event.target as HTMLInputElement).checked)"
          />
          <button class="field-name" :class="{ dimmed: !field.included, deprecated: field.prop.deprecated }" :aria-label="`View details for ${field.prop.name}`" @click="openPropertyDetail(field.prop)">
            <span v-if="field.prop.title && field.prop.title !== field.prop.name" class="field-human-title">{{ field.prop.title }}</span>
            <span class="font-mono">{{ field.prop.name }}</span>
          </button>
          <span class="field-type-badge" :class="typeBadgeClass(field.prop)">{{ displayType(field.prop, field.resolvedDef?.title || field.resolvedDef?.name) }}</span>
          <span v-if="field.prop.format" class="field-format-badge">{{ field.prop.format }}</span>
          <span v-if="field.prop.contentMediaType" class="field-format-badge">content-type: {{ field.prop.contentMediaType }}</span>
          <span v-if="field.prop.contentEncoding" class="field-format-badge">encoding: {{ field.prop.contentEncoding }}</span>
          <span v-if="field.prop.const != null" class="const-badge font-mono">const: {{ field.prop.const }}</span>
          <span v-else-if="field.prop.default != null" class="default-badge font-mono">default: {{ field.prop.default }}</span>
          <span v-if="field.isRequired" class="req-badge">required</span>
          <span v-if="field.prop.deprecated" class="deprecated-badge">deprecated</span>
          <span v-if="field.prop.readOnly" class="readonly-badge">read-only</span>
          <span v-if="field.prop.writeOnly" class="writeonly-badge">write-only</span>
          <span v-if="field.prop.compositionSource" class="composition-badge">{{ field.prop.compositionSource }}</span>

          <div class="field-control">
            <!-- Resolved $ref: expand button (works for object, array, and union types) -->
            <button
              v-if="field.resolvedDef"
              class="btn btn-ghost ctrl-expand"
              :disabled="!field.included"
              :aria-expanded="field.expanded"
              :aria-label="`${field.expanded ? 'Collapse' : 'Expand'} ${field.resolvedDef.title || field.resolvedDef.name}`"
              @click="field.expanded = !field.expanded"
            >
              <span class="chevron" :class="{ expanded: field.expanded }" aria-hidden="true">&#9654;</span>
              {{ field.resolvedDef.title || field.resolvedDef.name }}
              <span class="text-muted">{{ field.resolvedDef.properties.length }} props</span>
            </button>

            <!-- Enum -->
            <select
              v-else-if="field.prop.enum?.length"
              v-model="field.rawValue"
              class="ctrl-select"
              :disabled="!field.included"
            >
              <option v-for="e in field.prop.enum" :key="e" :value="e">{{ e }}</option>
            </select>

            <!-- Boolean -->
            <label v-else-if="primaryType(field.prop.type) === 'boolean'" class="ctrl-toggle">
              <input type="checkbox" :checked="field.rawValue === 'true'" :disabled="!field.included"
                @change="field.rawValue = ($event.target as HTMLInputElement).checked ? 'true' : 'false'" />
              <span class="toggle-label">{{ field.rawValue }}</span>
            </label>

            <!-- Integer -->
            <input
              v-else-if="primaryType(field.prop.type) === 'integer'"
              type="number" step="1"
              :value="field.rawValue"
              :disabled="!field.included"
              class="ctrl-number"
              :class="{ 'ctrl-error': fieldError(field.prop.name) }"
              @input="field.rawValue = ($event.target as HTMLInputElement).value"
              @blur="validate(field.prop.name, field.rawValue, field.prop)"
            />

            <!-- Number -->
            <input
              v-else-if="primaryType(field.prop.type) === 'number'"
              type="number" step="any"
              :value="field.rawValue"
              :disabled="!field.included"
              class="ctrl-number"
              :class="{ 'ctrl-error': fieldError(field.prop.name) }"
              @input="field.rawValue = ($event.target as HTMLInputElement).value"
              @blur="validate(field.prop.name, field.rawValue, field.prop)"
            />

            <!-- Object without $ref: editable JSON textarea -->
            <textarea
              v-else-if="isObjectProperty(field.prop)"
              v-model="field.rawValue"
              :disabled="!field.included"
              class="ctrl-textarea"
              :class="{ 'ctrl-error': fieldError(field.prop.name) }"
              rows="2"
              placeholder='{"key": "value"}'
              @blur="validate(field.prop.name, field.rawValue, field.prop)"
            />

            <!-- Array with itemsType -->
            <div v-else-if="primaryType(field.prop.type) === 'array'" class="ctrl-array">
              <div v-for="(item, idx) in field.arrayItems" :key="idx" class="array-item-row">
                <input
                  :type="arrayItemInputType(field.prop.itemsType)"
                  v-model="field.arrayItems[idx]"
                  class="ctrl-text"
                  :disabled="!field.included"
                />
                <button
                  v-if="field.arrayItems.length > 1"
                  class="btn btn-ghost btn-xs"
                  :disabled="!field.included"
                  @click="field.arrayItems.splice(idx, 1)"
                  title="Remove item"
                >x</button>
              </div>
              <button
                class="btn btn-ghost btn-xs"
                :disabled="!field.included"
                @click="field.arrayItems.push(arrayDefaultValue(field.prop.itemsType))"
              >+ Add</button>
            </div>

            <!-- String (default) -->
            <input
              v-else
              :type="formatInputType(field.prop.format)"
              :value="field.rawValue"
              :disabled="!field.included"
              class="ctrl-text"
              :class="{ 'ctrl-error': fieldError(field.prop.name) }"
              @input="field.rawValue = ($event.target as HTMLInputElement).value"
              @blur="validate(field.prop.name, field.rawValue, field.prop)"
            />
          </div>
        </div>

        <div v-if="fieldError(field.prop.name)" class="field-error-hint">
          {{ fieldError(field.prop.name) }}
        </div>

        <div v-if="field.prop.description" class="field-desc-wrap">
          <div class="field-desc text-secondary" :class="{ 'desc-collapsed': !descExpanded.has(field.prop.name) && field.prop.description.length > 200 }" v-html="renderInlineMarkdown(field.prop.description)"></div>
          <button v-if="field.prop.description.length > 200" class="btn-see-more" @click="toggleDesc(field.prop.name)">
            {{ descExpanded.has(field.prop.name) ? 'Show less' : 'Show more' }}
          </button>
        </div>

        <div v-if="hasConstraints(field.prop) || field.prop.ref || field.prop.enum?.length" class="field-constraints">
          <span v-if="field.prop.ref" class="constraint-chip chip-ref">ref → {{ field.resolvedDef?.title || field.resolvedDef?.name || field.prop.ref }}</span>
          <template v-if="field.prop.enum?.length && !isObjectProperty(field.prop)">
            <span v-for="e in visibleEnums(field.prop.name, field.prop.enum)" :key="e" class="enum-chip" :class="{ 'enum-chip-active': field.rawValue === e }">{{ e }}</span>
            <button v-if="field.prop.enum.length > MAX_ENUM_SHOW && !enumExpanded.has(field.prop.name)" class="btn-see-more" @click.stop="toggleEnum(field.prop.name)">+{{ field.prop.enum.length - MAX_ENUM_SHOW }} more</button>
          </template>
          <span v-else-if="field.prop.enum?.length && isObjectProperty(field.prop)" class="constraint-chip">enum: {{ field.prop.enum.join(' | ') }}</span>
          <span v-for="(chip, idx) in humanizeConstraints(field.prop)" :key="idx" class="constraint-chip" :class="chip.class">
            <template v-if="chip.class === 'chip-pattern'">
              /{{ truncatedPattern(chip.label).text }}/
              <button v-if="truncatedPattern(chip.label).truncated" class="btn-toggle-pattern" @click.stop="togglePattern(chip.label)">
                {{ expandedPatterns.has(chip.label) ? 'Hide' : 'Show' }}
              </button>
            </template>
            <template v-else>{{ chip.label }}</template>
          </span>
          <span v-if="field.prop.additionalProperties === false" class="constraint-chip chip-locked">no additional properties</span>
          <template v-if="field.prop.examples?.length">
            <span class="constraint-chip chip-example">example:</span>
            <span v-for="(ex, exi) in field.prop.examples" :key="exi" class="example-chip">{{ typeof ex === 'object' ? JSON.stringify(ex) : ex }}</span>
          </template>
        </div>

        <!-- Nested object builder -->
        <Transition name="expand">
        <div v-if="field.expanded && field.included && field.resolvedDef && !isCircular(field, visited)" class="nested-section">
          <div class="nested-header">
            <span class="nested-title">{{ field.resolvedDef.title || field.resolvedDef.name }}</span>
            <span class="nested-meta text-muted">
              {{ field.resolvedDef.type || 'object' }}
              <span v-if="field.resolvedDef.properties.length">{{ field.resolvedDef.properties.length }} properties</span>
              <span v-if="field.resolvedDef.required?.length">{{ field.resolvedDef.required.length }} required</span>
            </span>
          </div>
          <SchemaBuilder
            :properties="field.resolvedDef.properties"
            :required="field.resolvedDef.required"
            :schema="schema"
            :all-schemas="allSchemas"
            :visited="new Set([...visited, field.resolvedDef.name])"
            :depth="depth + 1"
            @update:json="(v: Record<string, unknown>) => { field.nestedJson = v }"
          />
        </div>
        </Transition>

        <!-- Circular reference label -->
        <div v-if="field.expanded && field.included && field.resolvedDef && isCircular(field, visited)" class="circular-ref-label">
          <span class="circular-badge">Circular</span>
          {{ field.resolvedDef?.name }}
        </div>
      </div>

      <div v-if="!sortedFields.length" class="empty-hint">
        <p class="text-muted">No properties defined.</p>
      </div>
    </div>

    <div class="builder-preview">
      <div class="preview-inner">
        <div class="preview-toolbar">
          <span class="toolbar-label text-muted">JSON Preview</span>
          <div class="toolbar-actions">
            <button class="btn btn-ghost btn-sm" @click="expandAllJson">Expand all</button>
            <button class="btn btn-ghost btn-sm" @click="collapseAllJson">Collapse all</button>
            <button class="btn btn-ghost btn-sm" @click="copyJson">
              {{ copied ? 'Copied!' : 'Copy' }}
            </button>
          </div>
        </div>
        <pre ref="jsonBlockRef" class="json-block" @click="handleJsonClick" v-html="highlightedJson"></pre>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import type { SpaProperty, SpaSchema } from '../types'
import { useSchemaStore } from '../stores/schemaStore'
import { useUiStore } from '../stores/uiStore'
import {
  primaryType,
  displayType,
  formatInputType,
  arrayItemInputType,
  arrayDefaultValue,
  isObjectProperty,
  hasConstraints,
  humanizeConstraints,
  validateFieldValue,
} from '../composables/useSchemaTypes'
import {
  createField,
  isCircular,
  parseFieldValue,
} from '../composables/useBuilderField'
import { renderInlineMarkdown } from '../composables/useMarkdownLite'
import { jsonToCollapsibleHtml } from '../composables/useJsonViewer'
import type { BuilderField } from '../composables/useBuilderField'

const schemaStore = useSchemaStore()
const uiStore = useUiStore()

function openPropertyDetail(prop: SpaProperty) {
  schemaStore.selectProperty(prop.name)
  uiStore.openDetailPanel()
}

const props = withDefaults(defineProps<{
  properties: SpaProperty[]
  required: string[]
  schema: SpaSchema
  allSchemas?: SpaSchema[]
  visited?: Set<string>
  depth?: number
}>(), {
  visited: () => new Set<string>(),
  depth: 0,
})

const emit = defineEmits<{
  'update:json': [value: Record<string, unknown>]
}>()

const copied = ref(false)
const expandedPatterns = ref(new Set<string>())
const jsonBlockRef = ref<HTMLElement | null>(null)
const descExpanded = ref(new Set<string>())
const enumExpanded = ref(new Set<string>())

const MAX_ENUM_SHOW = 8
const validationErrors = ref<Map<string, string>>(new Map())

function toggleDesc(name: string) {
  const s = new Set(descExpanded.value)
  if (s.has(name)) s.delete(name)
  else s.add(name)
  descExpanded.value = s
}

function visibleEnums(name: string, enums: string[]): string[] {
  if (enumExpanded.value.has(name) || enums.length <= MAX_ENUM_SHOW) return enums
  return enums.slice(0, MAX_ENUM_SHOW)
}

function toggleEnum(name: string) {
  const s = new Set(enumExpanded.value)
  if (s.has(name)) s.delete(name)
  else s.add(name)
  enumExpanded.value = s
}

function fieldError(name: string): string | undefined {
  return validationErrors.value.get(name)
}

function validate(name: string, rawValue: string, prop: SpaProperty) {
  const err = validateFieldValue(rawValue, prop)
  const m = new Map(validationErrors.value)
  if (err) m.set(name, err)
  else m.delete(name)
  validationErrors.value = m
}

const fields = ref<BuilderField[]>(props.properties.map(p => createField(p, props.required, props.schema, props.allSchemas)))

const sortedFields = computed(() => {
  return [...fields.value].sort((a, b) => {
    if (a.isRequired && !b.isRequired) return -1
    if (!a.isRequired && b.isRequired) return 1
    return 0
  })
})

function toggleField(field: BuilderField, checked: boolean) {
  field.included = checked
  if (!checked) field.expanded = false
}

const outputJson = computed(() => {
  const obj: Record<string, unknown> = {}
  for (const field of fields.value) {
    if (!field.included) continue
    if (field.resolvedDef) {
      obj[field.prop.name] = field.nestedJson
    } else {
      obj[field.prop.name] = parseFieldValue(field)
    }
  }
  return JSON.stringify(obj, null, 2)
})

const outputObj = computed(() => {
  try { return JSON.parse(outputJson.value) } catch { return {} }
})

watch(outputObj, (v) => { emit('update:json', v) }, { immediate: true, deep: true })

const highlightedJson = computed(() => {
  try {
    return jsonToCollapsibleHtml(JSON.parse(outputJson.value), 2)
  } catch {
    return outputJson.value
  }
})

function expandAllJson() {
  const container = jsonBlockRef.value
  if (!container) return
  container.querySelectorAll('.jv-collapsed').forEach(el => el.classList.remove('jv-collapsed'))
  container.querySelectorAll('.jv-toggle').forEach(btn => btn.setAttribute('aria-label', 'collapse'))
}

function collapseAllJson() {
  const container = jsonBlockRef.value
  if (!container) return
  const children = container.querySelectorAll('.jv-children')
  children.forEach((el, i) => {
    if (i === 0) return
    el.classList.add('jv-collapsed')
  })
  container.querySelectorAll('.jv-toggle').forEach((btn, i) => {
    if (i === 0) return
    btn.setAttribute('aria-label', 'expand')
  })
}

function handleJsonClick(event: MouseEvent) {
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

const MAX_PATTERN_LEN = 45

function typeBadgeClass(prop: SpaProperty): string {
  const t = primaryType(prop.type)
  switch (t) {
    case 'string': return 'type-string'
    case 'number': return 'type-number'
    case 'integer': return 'type-integer'
    case 'boolean': return 'type-boolean'
    case 'object': return 'type-object'
    case 'array': return 'type-array'
    case 'null': return 'type-null'
    default: return ''
  }
}

function truncatedPattern(pattern: string): { text: string; truncated: boolean } {
  if (pattern.length <= MAX_PATTERN_LEN) return { text: pattern, truncated: false }
  if (expandedPatterns.value.has(pattern)) return { text: pattern, truncated: true }
  return { text: pattern.slice(0, MAX_PATTERN_LEN) + '…', truncated: true }
}

function togglePattern(pattern: string) {
  const s = new Set(expandedPatterns.value)
  if (s.has(pattern)) s.delete(pattern)
  else s.add(pattern)
  expandedPatterns.value = s
}

async function copyJson() {
  try {
    await navigator.clipboard.writeText(outputJson.value)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
  } catch { /* noop */ }
}
</script>

<style scoped>
.builder-layout {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-4);
  align-items: start;
}

.builder-fields {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.field-row {
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-md);
}

.field-row:hover {
  background: var(--bg-hover);
}

.field-row-alt {
  background: var(--bg-secondary);
}

.field-row-alt:hover {
  background: var(--bg-hover);
}

.field-main {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.field-check {
  accent-color: var(--color-primary);
  flex-shrink: 0;
  cursor: pointer;
}

.field-check:disabled {
  cursor: default;
}

.field-name {
  font-weight: 600;
  font-size: var(--text-sm);
  min-width: 100px;
  display: flex;
  flex-direction: column;
  gap: 0;
  line-height: 1.3;
  text-align: left;
  cursor: pointer;
  padding: 0;
  border: none;
  background: none;
  color: inherit;
  font-family: inherit;
}

.field-name:hover .font-mono {
  color: var(--color-primary);
}

.field-human-title {
  font-size: var(--text-xs);
  font-weight: 400;
  font-style: italic;
  color: var(--text-secondary);
  font-family: var(--font-sans);
}

.field-name.dimmed {
  opacity: 0.35;
}

.field-name.deprecated {
  text-decoration: line-through;
  opacity: 0.7;
}

.field-type-badge {
  font-size: 11px;
  font-weight: 500;
  background: var(--badge-schema-bg);
  color: var(--badge-schema);
  padding: 1px 6px;
  border-radius: var(--radius-sm);
  flex-shrink: 0;
  transition: background var(--transition-fast), color var(--transition-fast);
}

.field-type-badge.type-string { background: var(--type-string-bg); color: var(--type-string); }
.field-type-badge.type-number { background: var(--type-number-bg); color: var(--type-number); }
.field-type-badge.type-integer { background: var(--type-integer-bg); color: var(--type-integer); }
.field-type-badge.type-boolean { background: var(--type-boolean-bg); color: var(--type-boolean); }
.field-type-badge.type-object { background: var(--type-object-bg); color: var(--type-object); }
.field-type-badge.type-array { background: var(--type-array-bg); color: var(--type-array); }
.field-type-badge.type-null { background: var(--type-null-bg); color: var(--type-null); }

.req-badge {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  color: var(--badge-required);
  background: var(--badge-required-bg);
  padding: 1px 5px;
  border-radius: 2px;
  flex-shrink: 0;
}

.field-format-badge {
  font-size: 10px;
  color: var(--text-muted);
  background: var(--bg-secondary);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
  font-family: var(--font-mono);
}

.deprecated-badge {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  color: var(--badge-deprecated);
  background: var(--badge-deprecated-bg);
  padding: 1px 5px;
  border-radius: 2px;
  flex-shrink: 0;
}

.readonly-badge,
.writeonly-badge {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  padding: 1px 5px;
  border-radius: 2px;
  flex-shrink: 0;
}

.readonly-badge {
  color: var(--color-teal);
  background: var(--color-teal-alpha);
}

.writeonly-badge {
  color: var(--color-orange);
  background: var(--color-orange-alpha);
}

.composition-badge {
  font-size: 10px;
  font-weight: 600;
  text-transform: none;
  color: var(--color-teal);
  background: var(--color-teal-alpha);
  padding: 1px 5px;
  border-radius: 2px;
  flex-shrink: 0;
  font-family: var(--font-mono);
}

.const-badge,
.default-badge {
  font-size: 10px;
  font-weight: 500;
  padding: 1px 5px;
  border-radius: 2px;
  flex-shrink: 0;
  max-width: 160px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.const-badge {
  color: var(--color-primary);
  background: var(--color-primary-alpha);
}

.default-badge {
  color: var(--text-secondary);
  background: var(--bg-secondary);
  border: 1px solid var(--border-light);
}

.field-control {
  flex: 1;
  min-width: 120px;
  max-width: 240px;
}

.ctrl-text,
.ctrl-number,
.ctrl-select {
  width: 100%;
  padding: 3px 8px;
  font-size: var(--text-sm);
  font-family: var(--font-mono);
  background: var(--bg-primary);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-sm);
  color: var(--text-primary);
}

.ctrl-text:disabled,
.ctrl-number:disabled,
.ctrl-select:disabled {
  opacity: 0.35;
}

.ctrl-text:focus,
.ctrl-number:focus,
.ctrl-select:focus {
  outline: none;
  border-color: var(--color-primary);
}

.ctrl-error {
  border-color: var(--color-red) !important;
}

.ctrl-error:focus {
  box-shadow: 0 0 0 2px rgba(179, 31, 36, 0.15);
}

.field-error-hint {
  font-size: var(--text-xs);
  color: var(--color-red);
  margin-top: 2px;
  margin-left: 22px;
}

.ctrl-toggle {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  cursor: pointer;
}

.ctrl-toggle input {
  accent-color: var(--color-primary);
}

.toggle-label {
  font-family: var(--font-mono);
  color: var(--text-secondary);
}

.ctrl-expand {
  display: flex;
  align-items: center;
  gap: var(--space-1);
  font-size: var(--text-xs);
  color: var(--color-primary);
}

.ctrl-static {
  font-size: var(--text-sm);
  font-family: var(--font-mono);
  color: var(--text-muted);
}

.ctrl-textarea {
  width: 100%;
  padding: 3px 8px;
  font-size: var(--text-sm);
  font-family: var(--font-mono);
  background: var(--bg-primary);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-sm);
  color: var(--text-primary);
  resize: vertical;
  min-height: 2em;
}

.ctrl-textarea:disabled {
  opacity: 0.35;
}

.ctrl-textarea:focus {
  outline: none;
  border-color: var(--color-primary);
}

.chevron {
  font-size: 10px;
  transition: transform var(--transition-fast);
}

.chevron.expanded {
  transform: rotate(90deg);
}

.field-desc-wrap {
  margin-top: var(--space-1);
  margin-left: 22px;
}

.field-desc {
  font-size: var(--text-xs);
  line-height: var(--leading-normal);
}

.field-desc.desc-collapsed {
  max-height: 3.6em;
  overflow: hidden;
  position: relative;
}

.field-desc.desc-collapsed::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 1.8em;
  background: linear-gradient(transparent, var(--bg-primary));
}

.field-row-alt .field-desc.desc-collapsed::after {
  background: linear-gradient(transparent, var(--bg-secondary));
}

.btn-see-more {
  display: block;
  font-size: var(--text-xs);
  color: var(--color-primary);
  background: none;
  border: none;
  cursor: pointer;
  padding: 2px 0;
  margin-top: 2px;
}

.btn-see-more:hover {
  text-decoration: underline;
}

.field-desc :deep(.md-code) {
  font-family: var(--font-mono);
  font-size: inherit;
  background: var(--bg-secondary);
  padding: 1px 4px;
  border-radius: 2px;
  border: 1px solid var(--border-light);
}

.field-desc :deep(.md-link) {
  color: var(--color-primary);
  text-decoration: none;
}

.field-desc :deep(.md-link:hover) {
  text-decoration: underline;
}

.field-constraints {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
  margin-top: var(--space-1);
  margin-left: 22px;
}

.constraint-chip {
  font-size: 11px;
  color: var(--text-muted);
  background: var(--bg-secondary);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
}

.constraint-chip.chip-pattern {
  font-family: var(--font-mono);
  color: #0e7c86;
  background: rgba(14, 124, 134, 0.08);
  border: 1px solid rgba(14, 124, 134, 0.15);
}

:root[data-theme="dark"] .constraint-chip.chip-pattern {
  color: #4dd0e1;
  background: rgba(77, 208, 225, 0.1);
  border-color: rgba(77, 208, 225, 0.2);
}

.btn-toggle-pattern {
  background: none;
  border: none;
  color: var(--color-primary);
  font-size: 10px;
  cursor: pointer;
  padding: 0 2px;
  margin-left: 4px;
  text-decoration: underline;
}

.btn-toggle-pattern:hover {
  opacity: 0.8;
}

.constraint-chip.chip-locked {
  color: var(--color-orange);
  background: var(--color-orange-alpha);
  font-weight: 500;
}

.constraint-chip.chip-example {
  font-style: italic;
  color: var(--text-muted);
  background: transparent;
  padding: 0;
  margin-right: 0;
}

.example-chip {
  font-size: 10px;
  font-family: var(--font-mono);
  color: var(--color-primary);
  background: var(--color-primary-alpha);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
  max-width: 200px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* Enum chips */
.enum-chip {
  font-size: 10px;
  font-family: var(--font-mono);
  color: var(--text-muted);
  background: var(--bg-secondary);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border-light);
  transition: all var(--transition-fast);
}

.enum-chip-active {
  color: var(--color-primary);
  background: var(--color-primary-alpha);
  border-color: var(--color-primary);
  font-weight: 500;
}

.nested-section {
  margin-left: 22px;
  margin-top: var(--space-2);
  padding: var(--space-3);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-md);
  background: var(--bg-secondary);
  border-left: 3px solid var(--color-primary);
  position: relative;
}

.nested-section::before {
  content: '';
  position: absolute;
  left: -11px;
  top: 0;
  bottom: 0;
  width: 2px;
  background: var(--border-light);
  border-radius: 1px;
}

/* Depth-aware alternating backgrounds */
:root[data-theme="light"] .depth-0 { background: var(--bg-secondary); }
:root[data-theme="light"] .depth-1 { background: var(--bg-primary); }
:root[data-theme="light"] .depth-2 { background: var(--bg-secondary); }
:root[data-theme="dark"] .depth-0 { background: var(--bg-secondary); }
:root[data-theme="dark"] .depth-1 { background: var(--bg-primary); }
:root[data-theme="dark"] .depth-2 { background: var(--bg-secondary); }

.nested-header {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  margin-bottom: var(--space-3);
  padding-bottom: var(--space-2);
  border-bottom: 1px solid var(--border-light);
}

.nested-title {
  font-weight: 600;
  font-size: var(--text-sm);
  color: var(--color-primary);
}

.nested-meta {
  font-size: var(--text-xs);
}

.builder-preview {
  position: sticky;
  top: var(--space-4);
}

.preview-inner {
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}

.preview-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.toolbar-label {
  font-size: var(--text-xs);
}

.btn-sm {
  font-size: var(--text-xs);
  padding: var(--space-1) var(--space-2);
}

.json-block {
  background: var(--bg-secondary);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-md);
  padding: var(--space-4);
  overflow-x: auto;
  font-size: var(--text-sm);
  line-height: var(--leading-relaxed);
  margin: 0;
  max-height: 70vh;
  overflow-y: auto;
  font-family: var(--font-mono);
  color: var(--text-primary);
}

.json-block :deep(ul) {
  list-style: none;
  padding-left: var(--space-4);
  margin: 0;
}

.json-block :deep(li) {
  margin: 0;
}

.json-block :deep(.jv-toggle) {
  background: none;
  border: 1px solid var(--border-light);
  border-radius: 2px;
  cursor: pointer;
  width: 14px;
  height: 14px;
  font-size: 9px;
  line-height: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: var(--text-muted);
  padding: 0;
  margin-right: 4px;
  vertical-align: middle;
  transition: background var(--transition-fast);
}

.json-block :deep(.jv-toggle:hover) {
  background: var(--bg-hover);
}

.json-block :deep(.jv-toggle[aria-label="expand"])::after { content: '+'; }
.json-block :deep(.jv-toggle[aria-label="collapse"])::after { content: '−'; }

.json-block :deep(.jv-ellipsis) {
  display: none;
  color: var(--text-muted);
  font-size: var(--text-xs);
  margin-left: 4px;
}

.json-block :deep(.jv-ellipsis::after) {
  content: ' … ';
}

.json-block :deep(.jv-children.jv-collapsed) {
  display: none;
}

.json-block :deep(.jv-children.jv-collapsed + .jv-ellipsis) {
  display: inline;
}

.json-block :deep(.jv-key) {
  color: var(--color-primary-dark);
}

.json-block :deep(.jv-punct) {
  color: var(--text-muted);
}

.json-block :deep(.jv-string) {
  color: var(--color-green);
}

.json-block :deep(.jv-number) {
  color: var(--color-orange);
}

.json-block :deep(.jv-boolean) {
  color: var(--color-accent);
}

.json-block :deep(.jv-null) {
  color: var(--text-muted);
  font-style: italic;
}

.json-block :deep(.jv-link) {
  color: var(--color-primary);
  text-decoration: underline;
}

.json-block :deep(.jv-row:hover) {
  background: var(--bg-hover);
  border-radius: 2px;
}

:root[data-theme="dark"] .json-block :deep(.jv-key) { color: var(--color-primary-light); }
:root[data-theme="dark"] .json-block :deep(.jv-string) { color: var(--color-teal); }

.toolbar-actions {
  display: flex;
  gap: var(--space-1);
}

.empty-hint {
  padding: var(--space-8);
  text-align: center;
}

/* Editable arrays */
.ctrl-array {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.array-item-row {
  display: flex;
  align-items: center;
  gap: var(--space-1);
}

.array-item-row input {
  flex: 1;
}

.btn-xs {
  font-size: 11px;
  padding: 2px 6px;
  border: none;
  background: transparent;
  color: var(--text-muted);
  cursor: pointer;
}

.btn-xs:hover:not(:disabled) {
  color: var(--text-primary);
}

.btn-xs:disabled {
  opacity: 0.35;
  cursor: default;
}

/* Circular reference */
.circular-ref-label {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: var(--text-sm);
  color: var(--text-muted);
  padding: var(--space-2) var(--space-3);
  margin-left: 22px;
}

.circular-badge {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  color: var(--color-orange);
  background: var(--color-orange-alpha);
  padding: 1px 5px;
  border-radius: 2px;
}

/* Responsive */
@media (max-width: 768px) {
  .builder-layout {
    grid-template-columns: 1fr;
  }
  .builder-preview {
    position: static;
    order: -1;
  }
}

/* Expand/collapse transition */
.expand-enter-active,
.expand-leave-active {
  transition: all var(--transition-slow);
  overflow: hidden;
}
.expand-enter-from,
.expand-leave-to {
  opacity: 0;
  max-height: 0;
  margin-top: 0;
  margin-bottom: 0;
  padding-top: 0;
  padding-bottom: 0;
}
.expand-enter-to,
.expand-leave-from {
  opacity: 1;
  max-height: 2000px;
}
</style>
