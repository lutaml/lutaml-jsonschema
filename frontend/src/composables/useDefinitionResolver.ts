import type { SpaSchema, SpaDefinition } from '../types'

/**
 * Resolve a JSON Schema $ref string to its SpaDefinition.
 * Handles: #/definitions/NAME and #/$defs/NAME patterns.
 * Returns null if the ref is empty, malformed, or not found.
 */
export function resolveSchemaRef(ref: string | undefined, schema: SpaSchema): SpaDefinition | null {
  if (!ref) return null

  const match = ref.match(/^#\/(?:definitions|\$defs)\/([^/]+)$/)
  if (match) {
    return schema.definitions.find(d => d.name === match[1]) ?? null
  }

  return null
}
