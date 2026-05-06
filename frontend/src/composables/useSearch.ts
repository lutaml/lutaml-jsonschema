import { ref, computed, watch } from 'vue'
import { useSchemaStore } from '../stores/schemaStore'
import { useUiStore } from '../stores/uiStore'

interface SearchResult {
  id: string
  type: 'schema' | 'property' | 'definition'
  name: string
  schemaName: string
  doc?: string
}

export function useSearch() {
  const schemaStore = useSchemaStore()
  const uiStore = useUiStore()

  const query = ref('')
  const results = ref<SearchResult[]>([])
  const isSearching = ref(false)
  let debounceTimer: ReturnType<typeof setTimeout> | null = null

  function buildSearchEntries(): SearchResult[] {
    const entries: SearchResult[] = []
    for (const schema of schemaStore.schemas) {
      entries.push({
        id: `schema:${schema.name}`,
        type: 'schema',
        name: schema.title || schema.name,
        schemaName: schema.name,
        doc: schema.description,
      })
      for (const prop of schema.properties) {
        entries.push({
          id: `property:${schema.name}:${prop.name}`,
          type: 'property',
          name: prop.name,
          schemaName: schema.name,
          doc: prop.description,
        })
      }
      for (const def of schema.definitions) {
        entries.push({
          id: `definition:${schema.name}:${def.name}`,
          type: 'definition',
          name: def.title || def.name,
          schemaName: schema.name,
          doc: def.description,
        })
      }
    }
    return entries
  }

  function search() {
    if (!query.value.trim()) {
      results.value = []
      return
    }

    isSearching.value = true
    const q = query.value.toLowerCase().trim()
    const entries = buildSearchEntries()

    results.value = entries.filter(e =>
      e.name.toLowerCase().includes(q) ||
      (e.doc && e.doc.toLowerCase().includes(q))
    ).slice(0, 50)

    isSearching.value = false
  }

  function debouncedSearch() {
    if (debounceTimer) clearTimeout(debounceTimer)
    debounceTimer = setTimeout(search, 150)
  }

  watch(query, debouncedSearch)

  const hasResults = computed(() => results.value.length > 0)

  function selectResult(result: SearchResult) {
    schemaStore.selectSchema(result.schemaName)
    if (result.type === 'definition') {
      schemaStore.selectDefinition(result.name)
    }
    uiStore.openDetailPanel()
    closeSearch()
  }

  function closeSearch() {
    uiStore.closeSearch()
    query.value = ''
    results.value = []
  }

  return {
    query,
    results,
    isSearching,
    hasResults,
    selectResult,
    closeSearch,
  }
}
