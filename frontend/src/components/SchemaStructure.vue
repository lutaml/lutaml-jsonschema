<template>
  <div class="schema-structure">
    <div v-for="prop in properties" :key="prop.name" class="prop-row">
      <div class="prop-main">
        <span class="prop-dot" :class="{ required: isRequired(prop.name) }" :title="isRequired(prop.name) ? 'Required' : 'Optional'"></span>
        <span class="prop-name font-mono">{{ prop.name }}</span>
        <span class="prop-type-badge">{{ displayType(prop) }}</span>
        <span v-if="prop.format" class="prop-format-badge">{{ prop.format }}</span>
        <span v-if="isRequired(prop.name)" class="req-badge">required</span>
        <span v-if="prop.deprecated" class="dep-badge">deprecated</span>
      </div>
      <div v-if="prop.description" class="prop-desc text-secondary">{{ prop.description }}</div>
      <div v-if="hasDetails(prop)" class="prop-details">
        <span v-if="prop.enum?.length" class="detail-chip">enum: {{ prop.enum.join(' | ') }}</span>
        <span v-if="prop.pattern" class="detail-chip font-mono">/{{ prop.pattern }}/</span>
        <span v-if="prop.minimum != null" class="detail-chip">min: {{ prop.minimum }}</span>
        <span v-if="prop.maximum != null" class="detail-chip">max: {{ prop.maximum }}</span>
        <span v-if="prop.minLength != null" class="detail-chip">minLength: {{ prop.minLength }}</span>
        <span v-if="prop.maxLength != null" class="detail-chip">maxLength: {{ prop.maxLength }}</span>
        <span v-if="prop.default != null" class="detail-chip">default: {{ prop.default }}</span>
        <span v-if="prop.examples?.length" class="detail-chip">e.g. {{ prop.examples.join(', ') }}</span>
        <span v-if="prop.ref" class="detail-chip ref-link">{{ prop.ref }}</span>
      </div>
    </div>
    <div v-if="!properties.length" class="empty-state">
      <p class="text-muted">No properties defined.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { SpaProperty } from '../types'

const props = defineProps<{
  properties: SpaProperty[]
  required: string[]
}>()

function isRequired(name: string) {
  return props.required.includes(name)
}

function displayType(prop: SpaProperty) {
  if (!prop.type) return 'any'
  if (prop.type === 'array' && prop.itemsType) return `array<${prop.itemsType}>`
  return prop.type
}

function hasDetails(prop: SpaProperty) {
  return !!(prop.enum?.length || prop.pattern ||
    prop.minimum != null || prop.maximum != null ||
    prop.minLength != null || prop.maxLength != null ||
    prop.default != null || prop.ref || prop.examples?.length)
}
</script>

<style scoped>
.schema-structure {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.prop-row {
  padding: var(--space-3) var(--space-4);
  border-radius: var(--radius-md);
  transition: background var(--transition-fast);
}

.prop-row:hover {
  background: var(--bg-hover);
}

.prop-main {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  flex-wrap: wrap;
}

.prop-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--border-medium);
  flex-shrink: 0;
}

.prop-dot.required {
  background: var(--color-primary);
}

.prop-name {
  font-weight: 600;
  font-size: var(--text-sm);
  color: var(--text-primary);
}

.prop-type-badge {
  font-size: 11px;
  font-weight: 500;
  background: var(--badge-schema-bg);
  color: var(--badge-schema);
  padding: 1px 6px;
  border-radius: var(--radius-sm);
}

.prop-format-badge {
  font-size: 11px;
  background: var(--bg-secondary);
  color: var(--text-muted);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
}

.req-badge {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.03em;
  color: var(--badge-required);
  background: var(--badge-required-bg);
  padding: 1px 5px;
  border-radius: 2px;
}

.dep-badge {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  color: var(--badge-deprecated);
  background: var(--badge-deprecated-bg);
  padding: 1px 5px;
  border-radius: 2px;
}

.prop-desc {
  font-size: var(--text-sm);
  line-height: var(--leading-normal);
  margin-top: var(--space-1);
  margin-left: 16px;
}

.prop-details {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-1);
  margin-top: var(--space-1);
  margin-left: 16px;
}

.detail-chip {
  font-size: 11px;
  color: var(--text-muted);
  background: var(--bg-secondary);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
}

.ref-link {
  color: var(--color-accent);
}

.empty-state {
  padding: var(--space-8);
  text-align: center;
}
</style>
