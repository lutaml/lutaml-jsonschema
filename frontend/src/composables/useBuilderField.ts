import { resolveSchemaRef } from './useDefinitionResolver'
import {
  primaryType,
  initialValue,
  arrayDefaultValue,
  parsePropertyValue,
  parseArrayItem,
} from './useSchemaTypes'
import type { SpaProperty, SpaSchema, SpaDefinition } from '../types'

/**
 * Typed field state for the SchemaBuilder.
 * Each property in a schema becomes one BuilderField.
 */
export interface BuilderField {
  prop: SpaProperty
  included: boolean
  isRequired: boolean
  rawValue: string
  expanded: boolean
  resolvedDef: SpaDefinition | null
  nestedJson: Record<string, unknown>
  arrayItems: string[]
}

/**
 * Factory: create a BuilderField from a property definition.
 * Resolves $ref, determines required status, initializes defaults.
 */
export function createField(
  prop: SpaProperty,
  requiredNames: string[],
  schema: SpaSchema,
): BuilderField {
  const isReq = requiredNames.includes(prop.name) || prop.required === true
  const def = resolveSchemaRef(prop.ref, schema)
  const isArray = primaryType(prop.type) === 'array'

  return {
    prop,
    included: isReq,
    isRequired: isReq,
    rawValue: initialValue(prop),
    expanded: false,
    resolvedDef: def,
    nestedJson: def ? buildDefaultJson(def.properties) : {},
    arrayItems: isArray ? [arrayDefaultValue(prop.itemsType)] : [],
  }
}

/**
 * Build a default JSON object from a list of properties.
 * Uses initial values and type-based parsing.
 */
export function buildDefaultJson(properties: SpaProperty[]): Record<string, unknown> {
  const obj: Record<string, unknown> = {}
  for (const prop of properties) {
    const t = primaryType(prop.type)
    const isArray = t === 'array'

    if (isArray) {
      const items = [arrayDefaultValue(prop.itemsType)]
      obj[prop.name] = items.map(item => parseArrayItem(item, prop.itemsType))
    } else {
      obj[prop.name] = parsePropertyValue(initialValue(prop), prop)
    }
  }
  return obj
}

/**
 * Check whether expanding this field would create a circular reference.
 */
export function isCircular(field: BuilderField, visited: ReadonlySet<string>): boolean {
  return !!field.resolvedDef && visited.has(field.resolvedDef.name)
}

/**
 * Parse a field's current state to its runtime JSON value.
 * Handles nested objects (via nestedJson), arrays (via arrayItems),
 * and primitive values (via parsePropertyValue).
 */
export function parseFieldValue(field: BuilderField): unknown {
  const prop = field.prop
  const t = primaryType(prop.type)

  if (t === 'array') {
    return field.arrayItems.map(item => parseArrayItem(item, prop.itemsType))
  }

  return parsePropertyValue(field.rawValue, prop)
}
