<template>
  <aside class="sidebar" :class="{ collapsed: uiStore.sidebarCollapsed }">
    <div class="sidebar-content">
      <!-- Branding -->
      <div class="sidebar-branding">
        <img
          :src="uiStore.isDark ? 'https://raw.githubusercontent.com/lutaml/branding/refs/heads/main/svg/lutaml-logo_logo-icon-dark.svg' : 'https://raw.githubusercontent.com/lutaml/branding/refs/heads/main/svg/lutaml-logo_logo-icon-light.svg'"
          alt="LutaML"
          class="branding-logo"
        />
        <div class="branding-text">
          <span class="branding-title">{{ schemaStore.metadata?.title || 'JSON Schema Docs' }}</span>
          <span class="branding-subtitle">LutaML JSON Schema</span>
        </div>
      </div>

      <!-- Overview -->
      <div class="sidebar-section overview-section">
        <button
          class="overview-btn"
          :class="{ active: !schemaStore.selectedSchema }"
          @click="goHome"
        >
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
            <path d="M2 7.5L8 2.5L14 7.5" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M3 7.5V13.5C3 13.5 3 14 4 14H12C12 14 13 14 13 13.5V7.5" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <span>Overview</span>
        </button>
      </div>

      <!-- Schema Tree -->
      <div class="sidebar-section flex-1 overflow-auto">
        <div class="section-header">
          <span class="section-title">Schemas</span>
        </div>
        <div class="schema-tree">
          <div
            v-for="schema in schemaStore.schemas"
            :key="schema.name"
            class="schema-node"
          >
            <div
              class="schema-node-header"
              :class="{ active: schema.name === schemaStore.selectedSchemaName }"
              @click="toggleAndSelect(schema.name)"
            >
              <svg width="12" height="12" viewBox="0 0 12 12" fill="none" :class="{ expanded: uiStore.isSchemaExpanded(schema.name) }">
                <path d="M4 3l3 3-3 3" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
              <span class="schema-name">{{ schema.title || schema.name }}</span>
              <span class="schema-badge-count">{{ schema.definitions.length }}D</span>
            </div>

            <div v-if="uiStore.isSchemaExpanded(schema.name)" class="schema-children">
              <div
                v-for="def in schema.definitions"
                :key="def.name"
                class="tree-item definition-item"
                :class="{ active: schema.name === schemaStore.selectedSchemaName && def.name === schemaStore.selectedDefinitionName }"
                @click.stop="selectDefinition(schema.name, def.name)"
              >
                <span class="badge badge-definition-sm">D</span>
                <span class="tree-item-name">{{ def.title || def.name }}</span>
                <span class="tree-item-count">{{ def.properties.length }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Stats -->
      <div class="sidebar-section stats-section">
        <div class="stats-grid">
          <div class="stat-item">
            <span class="stat-value">{{ schemaStore.schemaCounts.schemas }}</span>
            <span class="stat-label">Schemas</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">{{ schemaStore.schemaCounts.properties }}</span>
            <span class="stat-label">Properties</span>
          </div>
          <div class="stat-item">
            <span class="stat-value">{{ schemaStore.schemaCounts.definitions }}</span>
            <span class="stat-label">Definitions</span>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div class="sidebar-footer">
        <a href="https://www.lutaml.org" target="_blank" rel="noopener" class="footer-brand" title="LutaML">
          <img
            :src="uiStore.isDark ? 'https://raw.githubusercontent.com/lutaml/branding/refs/heads/main/svg/lutaml-logo_logo-full-dark.svg' : 'https://raw.githubusercontent.com/lutaml/branding/refs/heads/main/svg/lutaml-logo_logo-full-light.svg'"
            alt="LutaML"
            class="lutaml-logo"
          />
        </a>
        <div class="footer-text-group">
          <span class="footer-text">
            Generated with
            <a href="https://github.com/lutaml/lutaml-jsonschema" target="_blank" rel="noopener">LutaML JSON Schema</a>
          </span>
        </div>
      </div>
    </div>
  </aside>
</template>

<script setup lang="ts">
import { useSchemaStore } from '../stores/schemaStore'
import { useUiStore } from '../stores/uiStore'

const schemaStore = useSchemaStore()
const uiStore = useUiStore()

function goHome() {
  schemaStore.selectSchema(null)
  uiStore.closeDetailPanel()
}

function toggleAndSelect(name: string) {
  schemaStore.selectSchema(name)
  uiStore.toggleSchemaExpanded(name)
}

function selectDefinition(schemaName: string, defName: string) {
  schemaStore.selectSchema(schemaName)
  schemaStore.selectDefinition(defName)
  uiStore.closeDetailPanel()
}
</script>

<style scoped>
.sidebar {
  width: 280px;
  flex-shrink: 0;
  background: var(--bg-secondary);
  border-right: 1px solid var(--border-light);
  display: flex;
  flex-direction: column;
  transition: width var(--transition-slow);
  overflow: hidden;
}

.sidebar.collapsed {
  width: 0;
}

.sidebar-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  min-width: 280px;
}

.sidebar-branding {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-4);
  border-bottom: 1px solid var(--border-light);
}

.branding-logo {
  width: 28px;
  height: 28px;
  flex-shrink: 0;
}

.branding-text {
  display: flex;
  flex-direction: column;
  line-height: 1.2;
  min-width: 0;
}

.branding-title {
  font-size: var(--text-sm);
  font-weight: 600;
  color: var(--text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.branding-subtitle {
  font-size: var(--text-xs);
  color: var(--text-muted);
  font-weight: 400;
}

.overview-section {
  padding: var(--space-2) var(--space-3);
  border-bottom: 1px solid var(--border-light);
}

.overview-btn {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  width: 100%;
  padding: var(--space-2) var(--space-3);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--text-secondary);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all var(--transition-fast);
}

.overview-btn:hover {
  background: var(--bg-hover);
  color: var(--text-primary);
}

.overview-btn.active {
  background: var(--color-primary-alpha);
  color: var(--color-primary);
}

.sidebar-section {
  padding: var(--space-4);
  border-bottom: 1px solid var(--border-light);
}

.sidebar-section.flex-1 {
  flex: 1;
  overflow: auto;
}

.section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-3);
}

.section-title {
  font-size: var(--text-xs);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-muted);
}

.schema-tree {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
}

.schema-node-header {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: var(--space-1) var(--space-2);
  cursor: pointer;
  transition: background var(--transition-fast);
  font-size: var(--text-sm);
  border-radius: var(--radius-sm);
}

.schema-node-header:hover {
  background: var(--bg-hover);
}

.schema-node-header.active {
  background: var(--color-primary-alpha);
}

.schema-node-header.active .schema-name {
  color: var(--color-primary);
}

.schema-node-header.active svg {
  color: var(--color-primary);
}

.schema-node-header svg {
  color: var(--text-muted);
  transition: transform var(--transition-fast);
  flex-shrink: 0;
}

.schema-node-header svg.expanded {
  transform: rotate(90deg);
}

.schema-name {
  flex: 1;
  font-weight: 500;
  color: var(--text-primary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.schema-badge-count {
  font-size: var(--text-xs);
  color: var(--text-muted);
  background: var(--bg-primary);
  padding: 1px 5px;
  border-radius: var(--radius-sm);
}

.schema-children {
  margin-left: var(--space-4);
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.tree-item {
  display: flex;
  align-items: center;
  gap: var(--space-2);
  padding: 3px var(--space-2);
  font-size: var(--text-xs);
  cursor: pointer;
  border-radius: var(--radius-sm);
  transition: background var(--transition-fast);
}

.tree-item:hover {
  background: var(--bg-hover);
}

.tree-item.active {
  background: var(--color-primary-alpha);
}

.tree-item.active .tree-item-name {
  color: var(--color-primary);
}

.tree-item-name {
  flex: 1;
  color: var(--text-secondary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.tree-item-count {
  font-size: 10px;
  color: var(--text-muted);
  background: var(--bg-primary);
  padding: 0px 4px;
  border-radius: 2px;
  flex-shrink: 0;
}

.badge-definition-sm {
  background: var(--badge-definition-bg);
  color: var(--badge-definition);
  font-size: 9px;
  padding: 1px 4px;
  border-radius: 2px;
  font-weight: 600;
  flex-shrink: 0;
}

.stats-section {
  background: var(--bg-primary);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--space-2);
  text-align: center;
}

.stat-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stat-value {
  font-size: var(--text-lg);
  font-weight: 600;
  color: var(--text-primary);
}

.stat-label {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.sidebar-footer {
  padding: var(--space-3) var(--space-4);
  border-top: 1px solid var(--border-light);
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.footer-brand {
  display: flex;
  align-items: center;
  flex-shrink: 0;
}

.lutaml-logo {
  height: 18px;
  flex-shrink: 0;
  opacity: 0.7;
}

.footer-text-group {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.footer-text {
  font-size: var(--text-xs);
  color: var(--text-muted);
}

.footer-text a {
  color: var(--color-primary);
  text-decoration: none;
}

.footer-text a:hover {
  text-decoration: underline;
}
</style>
