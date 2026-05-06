<template>
  <div class="builder-layout">
    <div class="builder-fields">
      <div v-for="field in fields" :key="field.prop.name" class="field-row">
        <div class="field-main">
          <input
            type="checkbox"
            :checked="field.included"
            :disabled="field.isRequired"
            class="field-check"
            @change="toggleField(field, ($event.target as HTMLInputElement).checked)"
          />
          <span class="field-name font-mono" :class="{ dimmed: !field.included }">{{ field.prop.name }}</span>
          <span class="field-type-badge">{{ displayType(field.prop) }}</span>
          <span v-if="field.isRequired" class="req-badge">required</span>

          <div class="field-control">
            <!-- Enum -->
            <select
              v-if="field.prop.enum?.length && !isObjectProperty(field.prop)"
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
              @input="field.rawValue = ($event.target as HTMLInputElement).value"
            />

            <!-- Number -->
            <input
              v-else-if="primaryType(field.prop.type) === 'number'"
              type="number" step="any"
              :value="field.rawValue"
              :disabled="!field.included"
              class="ctrl-number"
              @input="field.rawValue = ($event.target as HTMLInputElement).value"
            />

            <!-- Object with $ref: expand button -->
            <button
              v-else-if="isObjectProperty(field.prop) && field.resolvedDef"
              class="btn btn-ghost ctrl-expand"
              :disabled="!field.included"
              @click="field.expanded = !field.expanded"
            >
              <span class="chevron" :class="{ expanded: field.expanded }">&#9654;</span>
              {{ field.resolvedDef.title || field.resolvedDef.name }}
              <span class="text-muted">{{ field.resolvedDef.properties.length }} props</span>
            </button>

            <!-- Object without $ref -->
            <span v-else-if="isObjectProperty(field.prop)" class="ctrl-static">{"..."}</span>

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
              @input="field.rawValue = ($event.target as HTMLInputElement).value"
            />
          </div>
        </div>

        <div v-if="field.prop.description" class="field-desc text-secondary">{{ field.prop.description }}</div>

        <div v-if="hasConstraints(field.prop)" class="field-constraints">
          <span v-if="field.prop.enum?.length && isObjectProperty(field.prop)" class="constraint-chip">enum: {{ field.prop.enum.join(' | ') }}</span>
          <span v-if="field.prop.pattern" class="constraint-chip font-mono">/{{ field.prop.pattern }}/</span>
          <span v-if="field.prop.minimum != null" class="constraint-chip">min: {{ field.prop.minimum }}</span>
          <span v-if="field.prop.maximum != null" class="constraint-chip">max: {{ field.prop.maximum }}</span>
          <span v-if="field.prop.minLength != null" class="constraint-chip">minLength: {{ field.prop.minLength }}</span>
          <span v-if="field.prop.maxLength != null" class="constraint-chip">maxLength: {{ field.prop.maxLength }}</span>
          <span v-if="field.prop.default != null" class="constraint-chip">default: {{ field.prop.default }}</span>
          <span v-if="field.prop.examples?.length" class="constraint-chip">e.g. {{ field.prop.examples.join(', ') }}</span>
        </div>

        <!-- Nested object builder -->
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
            :visited="new Set([...visited, field.resolvedDef.name])"
            @update:json="(v: Record<string, unknown>) => { field.nestedJson = v }"
          />
        </div>

        <!-- Circular reference label -->
        <div v-else-if="isCircular(field, visited)" class="circular-ref-label">
          <span class="circular-badge">Circular</span>
          {{ field.resolvedDef?.name }}
        </div>
      </div>

      <div v-if="!fields.length" class="empty-hint">
        <p class="text-muted">No properties defined.</p>
      </div>
    </div>

    <div class="builder-preview">
      <div class="preview-inner">
        <div class="preview-toolbar">
          <span class="toolbar-label text-muted">JSON Preview</span>
          <button class="btn btn-ghost btn-sm" @click="copyJson">
            {{ copied ? 'Copied!' : 'Copy' }}
          </button>
        </div>
        <pre class="json-block"><code>{{ outputJson }}</code></pre>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import type { SpaProperty, SpaSchema } from '../types'
import {
  primaryType,
  displayType,
  formatInputType,
  arrayItemInputType,
  arrayDefaultValue,
  isObjectProperty,
  hasConstraints,
} from '../composables/useSchemaTypes'
import {
  createField,
  isCircular,
  parseFieldValue,
} from '../composables/useBuilderField'
import type { BuilderField } from '../composables/useBuilderField'

const props = withDefaults(defineProps<{
  properties: SpaProperty[]
  required: string[]
  schema: SpaSchema
  visited?: Set<string>
}>(), {
  visited: () => new Set<string>(),
})

const emit = defineEmits<{
  'update:json': [value: Record<string, unknown>]
}>()

const copied = ref(false)

const fields = ref<BuilderField[]>(props.properties.map(p => createField(p, props.required, props.schema)))

function toggleField(field: BuilderField, checked: boolean) {
  field.included = checked
  if (!checked) field.expanded = false
}

const outputJson = computed(() => {
  const obj: Record<string, unknown> = {}
  for (const field of fields.value) {
    if (!field.included) continue
    const t = primaryType(field.prop.type)
    if ((t === 'object' || (!field.prop.type && field.prop.ref)) && field.resolvedDef) {
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
}

.field-name.dimmed {
  opacity: 0.35;
}

.field-type-badge {
  font-size: 11px;
  font-weight: 500;
  background: var(--badge-schema-bg);
  color: var(--badge-schema);
  padding: 1px 6px;
  border-radius: var(--radius-sm);
  flex-shrink: 0;
}

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

.chevron {
  font-size: 10px;
  transition: transform var(--transition-fast);
}

.chevron.expanded {
  transform: rotate(90deg);
}

.field-desc {
  font-size: var(--text-xs);
  line-height: var(--leading-normal);
  margin-top: var(--space-1);
  margin-left: 22px;
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

.nested-section {
  margin-left: 22px;
  margin-top: var(--space-2);
  padding: var(--space-3);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-md);
  background: var(--bg-secondary);
}

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
}

.json-block code {
  font-family: var(--font-mono);
  color: var(--text-primary);
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
  color: #b45309;
  background: #fef3c7;
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
</style>
