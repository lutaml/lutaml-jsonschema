import { resolveSchemaRef } from './useDefinitionResolver'
import {
  primaryType,
  initialValue,
  arrayDefaultValue,
  parsePropertyValue,
  parseArrayItem,
} from './useSchemaTypes'
import type { SpaProperty, SpaSchema, SpaDefinition } from '../types'

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

export function createField(
  prop: SpaProperty,
  requiredNames: string[],
  schema: SpaSchema,
  allSchemas?: SpaSchema[],
): BuilderField {
  const isReq = requiredNames.includes(prop.name) || prop.required === true
  const def = resolveSchemaRef(prop.ref, schema, allSchemas)
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

export function buildDefaultJson(properties: SpaProperty[]): Record<string, unknown> {
  const obj: Record<string, unknown> = {}
  for (const prop of properties) {
    const t = primaryType(prop.type)
    if (t === 'array') {
      const items = [arrayDefaultValue(prop.itemsType)]
      obj[prop.name] = items.map(item => parseArrayItem(item, prop.itemsType))
    } else {
      obj[prop.name] = parsePropertyValue(initialValue(prop), prop)
    }
  }
  return obj
}

export function isCircular(field: BuilderField, visited: ReadonlySet<string>): boolean {
  return !!field.resolvedDef && visited.has(field.resolvedDef.name)
}

export function parseFieldValue(field: BuilderField): unknown {
  const t = primaryType(field.prop.type)
  if (t === 'array') {
    return field.arrayItems.map(item => parseArrayItem(item, field.prop.itemsType))
  }
  return parsePropertyValue(field.rawValue, field.prop)
}
