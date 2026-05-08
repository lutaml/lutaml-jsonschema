import { ref, computed, watch } from 'vue'
import { useSchemaStore } from '../stores/schemaStore'
import { useUiStore } from '../stores/uiStore'

interface SearchResult {
  id: string
  type: 'schema' | 'property' | 'definition'
  name: string
  rawName: string
  schemaName: string
  description?: string
}

export function useSearch() {
  const schemaStore = useSchemaStore()
  const uiStore = useUiStore()

  const query = ref('')
  const results = ref<SearchResult[]>([])
  const isSearching = ref(false)
  let debounceTimer: ReturnType<typeof setTimeout> | null = null

  function buildSearchEntries(): SearchResult[] {
    return schemaStore.searchIndex.map(entry => ({
      id: `${entry.type}:${entry.schemaName}:${entry.name}`,
      type: entry.type as SearchResult['type'],
      name: entry.title || entry.name,
      rawName: entry.name,
      schemaName: entry.schemaName,
      description: entry.description,
    }))
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
      e.schemaName.toLowerCase().includes(q) ||
      (e.description && e.description.toLowerCase().includes(q))
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
      schemaStore.selectDefinition(result.rawName)
    } else {
      schemaStore.clearSelection()
    }
    uiStore.closeDetailPanel()
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
