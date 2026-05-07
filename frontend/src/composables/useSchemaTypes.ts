import type { SpaProperty } from '../types'

/**
 * Extract the primary JSON Schema type from a type string.
 * Handles union types like "string,integer" by returning the first component.
 */
export function primaryType(type?: string): string {
  const t = (type || '').split(',')[0].trim()
  return t || 'any'
}

/**
 * Human-readable type display for the type badge.
 * Shows resolved definition title for $ref props, "array of X" notation,
 * and format suffix for primitives.
 */
export function displayType(prop: SpaProperty, resolvedTitle?: string): string {
  const t = primaryType(prop.type)
  if (t === 'array' && prop.itemsType) return `array of ${prop.itemsType}`
  if (resolvedTitle && (t === 'object' || t === 'any') && prop.ref) return resolvedTitle
  if (prop.format) return `${t} (${prop.format})`
  return t
}

/**
 * HTML input type based on JSON Schema format keyword.
 * Falls back to "text" for unrecognised formats.
 */
export function formatInputType(format?: string): string {
  switch (format) {
    case 'email': return 'email'
    case 'uri':
    case 'uri-reference': return 'url'
    case 'date': return 'date'
    case 'time': return 'time'
    case 'date-time': return 'datetime-local'
    default: return 'text'
  }
}

/**
 * Default string value based on format when no example/default is available.
 */
export function formatDefault(format?: string): string {
  switch (format) {
    case 'uri':
    case 'uri-reference': return 'https://example.com'
    case 'date-time': return '2024-01-01T00:00:00Z'
    case 'date': return '2024-01-01'
    case 'time': return '00:00:00Z'
    case 'email': return 'user@example.com'
    case 'uuid': return '00000000-0000-0000-0000-000000000000'
    default: return 'string'
  }
}

/**
 * The first meaningful value for a property: examples[0], default, first enum,
 * or a type-based fallback.
 */
export function initialValue(prop: SpaProperty): string {
  if (prop.examples?.length) return prop.examples[0]
  if (prop.default != null) return String(prop.default)
  if (prop.enum?.length) return prop.enum[0]

  const t = primaryType(prop.type)
  switch (t) {
    case 'integer': return '0'
    case 'number': return '0.0'
    case 'boolean': return 'false'
    case 'string': return formatDefault(prop.format)
    default: return ''
  }
}

/**
 * HTML input type for individual array item elements.
 */
export function arrayItemInputType(itemsType?: string): string {
  switch (itemsType) {
    case 'integer':
    case 'number': return 'number'
    case 'boolean': return 'checkbox'
    default: return 'text'
  }
}

/**
 * Default string value for a new array item.
 */
export function arrayDefaultValue(itemsType?: string): string {
  switch (itemsType) {
    case 'integer': return '0'
    case 'number': return '0.0'
    case 'boolean': return 'false'
    default: return ''
  }
}

/**
 * Parse a single array item string to its correct runtime type.
 */
export function parseArrayItem(item: string, itemsType?: string): unknown {
  switch (itemsType) {
    case 'integer': return parseInt(item, 10) || 0
    case 'number': return parseFloat(item) || 0.0
    case 'boolean': return item === 'true'
    default: return item
  }
}

/**
 * Check whether a property is an object (type=object or has a $ref without a type).
 */
export function isObjectProperty(prop: SpaProperty): boolean {
  const t = primaryType(prop.type)
  return t === 'object' || (!prop.type && !!prop.ref)
}

/**
 * Check whether a property has constraints that should be displayed as chips.
 */
export function hasConstraints(prop: SpaProperty): boolean {
  return !!(
    (prop.enum?.length && isObjectProperty(prop)) ||
    prop.pattern ||
    prop.minimum != null ||
    prop.maximum != null ||
    prop.minLength != null ||
    prop.maxLength != null ||
    prop.default != null ||
    prop.examples?.length ||
    prop.minItems != null ||
    prop.maxItems != null ||
    prop.uniqueItems ||
    prop.multipleOf != null ||
    prop.const != null ||
    prop.exclusiveMinimum != null ||
    prop.exclusiveMaximum != null ||
    prop.contentMediaType ||
    prop.contentEncoding
  )
}

/**
 * Parse a property's raw string value to its correct runtime type.
 * Handles enums, booleans, numbers, arrays, and objects.
 */
export function parsePropertyValue(rawValue: string, prop: SpaProperty): unknown {
  const t = primaryType(prop.type)
  if (prop.enum?.length) return rawValue
  if (t === 'boolean') return rawValue === 'true'
  if (t === 'integer') {
    const n = parseInt(rawValue, 10)
    return isNaN(n) ? 0 : n
  }
  if (t === 'number') {
    const n = parseFloat(rawValue)
    return isNaN(n) ? 0 : n
  }
  if (t === 'object' && !prop.ref) return {}
  return rawValue
}

export interface ConstraintChip {
  label: string
  class?: string
}

function numberRange(prop: SpaProperty): string | undefined {
  const hasMin = prop.minimum != null
  const hasMax = prop.maximum != null
  const hasExcMin = prop.exclusiveMinimum != null
  const hasExcMax = prop.exclusiveMaximum != null
  const excMin = prop.exclusiveMinimum != null
  const excMax = prop.exclusiveMaximum != null

  if (hasMin && hasMax) {
    const l = excMin ? '( ' : '[ '
    const r = excMax ? ' )' : ' ]'
    return `${l}${prop.minimum} .. ${prop.maximum}${r}`
  }
  if (hasMin && hasExcMax) {
    const l = excMin ? '( ' : '[ '
    return `${l}${prop.minimum} .. ${prop.exclusiveMaximum} )`
  }
  if (hasExcMin && hasMax) {
    const r = excMax ? ' )' : ' ]'
    return `( ${prop.exclusiveMinimum} .. ${prop.maximum}${r}`
  }
  if (hasMax) return `${excMax ? '< ' : '<= '}${prop.maximum}`
  if (hasMin) return `${excMin ? '> ' : '>= '}${prop.minimum}`
  if (hasExcMin && hasExcMax) return `( ${prop.exclusiveMinimum} .. ${prop.exclusiveMaximum} )`
  if (hasExcMax) return `< ${prop.exclusiveMaximum}`
  if (hasExcMin) return `> ${prop.exclusiveMinimum}`
  return undefined
}

function stringRange(prop: SpaProperty): string | undefined {
  if (prop.minLength != null && prop.maxLength != null) {
    if (prop.minLength === prop.maxLength) return `= ${prop.minLength} characters`
    return `[ ${prop.minLength} .. ${prop.maxLength} ] characters`
  }
  if (prop.minLength != null) {
    if (prop.minLength === 1) return 'non-empty'
    return `>= ${prop.minLength} characters`
  }
  if (prop.maxLength != null) return `<= ${prop.maxLength} characters`
  return undefined
}

function itemsRange(prop: SpaProperty): string | undefined {
  if (prop.minItems != null && prop.maxItems != null) {
    if (prop.minItems === prop.maxItems) return `= ${prop.minItems} items`
    return `[ ${prop.minItems} .. ${prop.maxItems} ] items`
  }
  if (prop.minItems != null) {
    if (prop.minItems === 1) return 'non-empty'
    return `>= ${prop.minItems} items`
  }
  if (prop.maxItems != null) return `<= ${prop.maxItems} items`
  return undefined
}

export function humanizeConstraints(prop: SpaProperty): ConstraintChip[] {
  const chips: ConstraintChip[] = []
  const t = primaryType(prop.type)

  if (prop.const != null) chips.push({ label: `const: ${prop.const}`, class: 'chip-const' })

  const tIsString = t === 'string' || !t || t === 'any'
  if (tIsString) {
    const range = stringRange(prop)
    if (range) chips.push({ label: range })
  }

  if (t === 'integer' || t === 'number') {
    const range = numberRange(prop)
    if (range) chips.push({ label: range })
    if (prop.multipleOf != null) {
      const s = prop.multipleOf.toString()
      if (/^0\.0*1$/.test(s)) {
        chips.push({ label: `decimal places <= ${s.split('.')[1].length}` })
      } else {
        chips.push({ label: `multiple of ${s}` })
      }
    }
  }

  if (t === 'array') {
    const range = itemsRange(prop)
    if (range) chips.push({ label: range })
    if (prop.uniqueItems) chips.push({ label: 'unique', class: 'chip-unique' })
  }

  if (prop.pattern) chips.push({ label: prop.pattern, class: 'chip-pattern' })
  if (prop.default != null) chips.push({ label: `default: ${prop.default}`, class: 'chip-default' })
  if (prop.examples?.length) chips.push({ label: `e.g. ${prop.examples.join(', ')}`, class: 'chip-example' })
  if (prop.contentMediaType) chips.push({ label: `content-type: ${prop.contentMediaType}` })
  if (prop.contentEncoding) chips.push({ label: `encoding: ${prop.contentEncoding}` })

  return chips
}
