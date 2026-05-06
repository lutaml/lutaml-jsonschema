import { describe, it, expect } from 'vitest'
import {
  primaryType,
  displayType,
  formatInputType,
  formatDefault,
  initialValue,
  arrayItemInputType,
  arrayDefaultValue,
  parseArrayItem,
  isObjectProperty,
  hasConstraints,
  parsePropertyValue,
} from '../composables/useSchemaTypes'
import type { SpaProperty } from '../types'

function prop(overrides: Partial<SpaProperty> = {}): SpaProperty {
  return { name: 'test', ...overrides }
}

describe('primaryType', () => {
  it('returns the first type from a comma-separated string', () => {
    expect(primaryType('string,integer')).toBe('string')
  })

  it('returns the single type', () => {
    expect(primaryType('object')).toBe('object')
  })

  it('returns "any" for undefined', () => {
    expect(primaryType(undefined)).toBe('any')
  })

  it('returns "any" for empty string', () => {
    expect(primaryType('')).toBe('any')
  })
})

describe('displayType', () => {
  it('shows array<itemsType> for arrays', () => {
    expect(displayType(prop({ type: 'array', itemsType: 'string' }))).toBe('array<string>')
  })

  it('shows type (format) when format is set', () => {
    expect(displayType(prop({ type: 'string', format: 'email' }))).toBe('string (email)')
  })

  it('shows plain type when no format', () => {
    expect(displayType(prop({ type: 'integer' }))).toBe('integer')
  })
})

describe('formatInputType', () => {
  it.each([
    ['email', 'email'],
    ['uri', 'url'],
    ['uri-reference', 'url'],
    ['date', 'date'],
    ['time', 'time'],
    ['date-time', 'datetime-local'],
    [undefined, 'text'],
    ['unknown', 'text'],
  ])('maps format %s to input type %s', (format, expected) => {
    expect(formatInputType(format)).toBe(expected)
  })
})

describe('formatDefault', () => {
  it('returns URI for uri format', () => {
    expect(formatDefault('uri')).toBe('https://example.com')
  })

  it('returns "string" for unknown format', () => {
    expect(formatDefault('unknown')).toBe('string')
  })

  it('returns "string" for no format', () => {
    expect(formatDefault(undefined)).toBe('string')
  })
})

describe('initialValue', () => {
  it('uses examples[0] first', () => {
    expect(initialValue(prop({ examples: ['hello', 'world'], type: 'string' }))).toBe('hello')
  })

  it('uses default second', () => {
    expect(initialValue(prop({ default: 'fallback', type: 'string' }))).toBe('fallback')
  })

  it('uses first enum value third', () => {
    expect(initialValue(prop({ enum: ['a', 'b'], type: 'string' }))).toBe('a')
  })

  it('uses type-based fallback for integer', () => {
    expect(initialValue(prop({ type: 'integer' }))).toBe('0')
  })

  it('uses type-based fallback for boolean', () => {
    expect(initialValue(prop({ type: 'boolean' }))).toBe('false')
  })

  it('uses format-aware default for string', () => {
    expect(initialValue(prop({ type: 'string', format: 'email' }))).toBe('user@example.com')
  })
})

describe('arrayItemInputType', () => {
  it.each([
    ['integer', 'number'],
    ['number', 'number'],
    ['boolean', 'checkbox'],
    ['string', 'text'],
    [undefined, 'text'],
  ])('maps itemsType %s to input type %s', (itemsType, expected) => {
    expect(arrayItemInputType(itemsType)).toBe(expected)
  })
})

describe('arrayDefaultValue', () => {
  it.each([
    ['integer', '0'],
    ['number', '0.0'],
    ['boolean', 'false'],
    ['string', ''],
    [undefined, ''],
  ])('returns %s default for itemsType %s', (itemsType, expected) => {
    expect(arrayDefaultValue(itemsType)).toBe(expected)
  })
})

describe('parseArrayItem', () => {
  it('parses integer', () => {
    expect(parseArrayItem('42', 'integer')).toBe(42)
  })

  it('parses number', () => {
    expect(parseArrayItem('3.14', 'number')).toBeCloseTo(3.14)
  })

  it('parses boolean true', () => {
    expect(parseArrayItem('true', 'boolean')).toBe(true)
  })

  it('parses boolean false', () => {
    expect(parseArrayItem('false', 'boolean')).toBe(false)
  })

  it('returns string for unknown itemsType', () => {
    expect(parseArrayItem('hello', 'string')).toBe('hello')
  })

  it('returns string for undefined itemsType', () => {
    expect(parseArrayItem('hello', undefined)).toBe('hello')
  })
})

describe('isObjectProperty', () => {
  it('returns true for type=object', () => {
    expect(isObjectProperty(prop({ type: 'object' }))).toBe(true)
  })

  it('returns true for no type but has ref', () => {
    expect(isObjectProperty(prop({ type: undefined, ref: '#/definitions/X' }))).toBe(true)
  })

  it('returns false for string', () => {
    expect(isObjectProperty(prop({ type: 'string' }))).toBe(false)
  })
})

describe('hasConstraints', () => {
  it('returns true for pattern', () => {
    expect(hasConstraints(prop({ pattern: '[0-9]+' }))).toBe(true)
  })

  it('returns true for minimum', () => {
    expect(hasConstraints(prop({ minimum: 0 }))).toBe(true)
  })

  it('returns true for examples', () => {
    expect(hasConstraints(prop({ examples: ['a'] }))).toBe(true)
  })

  it('returns false for no constraints', () => {
    expect(hasConstraints(prop({ type: 'string' }))).toBe(false)
  })

  it('returns true for minItems', () => {
    expect(hasConstraints(prop({ minItems: 1 }))).toBe(true)
  })

  it('returns true for maxItems', () => {
    expect(hasConstraints(prop({ maxItems: 10 }))).toBe(true)
  })

  it('returns true for uniqueItems', () => {
    expect(hasConstraints(prop({ uniqueItems: true }))).toBe(true)
  })

  it('returns true for multipleOf', () => {
    expect(hasConstraints(prop({ multipleOf: 0.5 }))).toBe(true)
  })

  it('returns true for const', () => {
    expect(hasConstraints(prop({ const: 'fixed' }))).toBe(true)
  })
})

describe('parsePropertyValue', () => {
  it('returns enum raw value', () => {
    expect(parsePropertyValue('a', prop({ enum: ['a', 'b'], type: 'string' }))).toBe('a')
  })

  it('parses boolean', () => {
    expect(parsePropertyValue('true', prop({ type: 'boolean' }))).toBe(true)
    expect(parsePropertyValue('false', prop({ type: 'boolean' }))).toBe(false)
  })

  it('parses integer', () => {
    expect(parsePropertyValue('42', prop({ type: 'integer' }))).toBe(42)
  })

  it('parses integer as 0 for NaN', () => {
    expect(parsePropertyValue('abc', prop({ type: 'integer' }))).toBe(0)
  })

  it('parses number', () => {
    expect(parsePropertyValue('3.14', prop({ type: 'number' }))).toBeCloseTo(3.14)
  })

  it('returns empty object for object without ref', () => {
    expect(parsePropertyValue('', prop({ type: 'object' }))).toEqual({})
  })

  it('returns raw string for string type', () => {
    expect(parsePropertyValue('hello', prop({ type: 'string' }))).toBe('hello')
  })
})
