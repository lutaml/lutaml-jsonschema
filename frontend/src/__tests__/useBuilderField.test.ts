import { describe, it, expect } from 'vitest'
import { createField, buildDefaultJson, isCircular, parseFieldValue } from '../composables/useBuilderField'
import type { SpaProperty, SpaSchema, SpaDefinition } from '../types'

function prop(overrides: Partial<SpaProperty> = {}): SpaProperty {
  return { name: 'test', ...overrides }
}

function definition(overrides: Partial<SpaDefinition> = {}): SpaDefinition {
  return { name: 'Address', properties: [], required: [], ...overrides }
}

function spaSchema(overrides: Partial<SpaSchema> = {}): SpaSchema {
  return { name: 'Test', properties: [], definitions: [], required: [], ...overrides }
}

describe('createField', () => {
  it('marks field as required when in required list', () => {
    const field = createField(prop({ name: 'email' }), ['email'], spaSchema())
    expect(field.isRequired).toBe(true)
    expect(field.included).toBe(true)
  })

  it('marks field as optional when not in required list', () => {
    const field = createField(prop({ name: 'nickname' }), ['email'], spaSchema())
    expect(field.isRequired).toBe(false)
    expect(field.included).toBe(false)
  })

  it('resolves $ref to definition', () => {
    const addressDef = definition({
      name: 'address',
      properties: [
        prop({ name: 'street', type: 'string' }),
      ],
    })
    const s = spaSchema({ definitions: [addressDef] })
    const field = createField(
      prop({ name: 'address', type: 'object', ref: '#/definitions/address' }),
      [],
      s,
    )
    expect(field.resolvedDef).toBe(addressDef)
  })

  it('initializes array items for array type', () => {
    const field = createField(
      prop({ name: 'tags', type: 'array', itemsType: 'string' }),
      [],
      spaSchema(),
    )
    expect(field.arrayItems).toEqual([''])
  })

  it('leaves array items empty for non-array type', () => {
    const field = createField(prop({ name: 'name', type: 'string' }), [], spaSchema())
    expect(field.arrayItems).toEqual([])
  })
})

describe('buildDefaultJson', () => {
  it('builds object from properties', () => {
    const props = [
      prop({ name: 'name', type: 'string' }),
      prop({ name: 'age', type: 'integer' }),
    ]
    const result = buildDefaultJson(props)
    expect(result).toEqual({ name: 'string', age: 0 })
  })

  it('builds array property', () => {
    const props = [
      prop({ name: 'tags', type: 'array', itemsType: 'string' }),
    ]
    const result = buildDefaultJson(props)
    expect(result).toEqual({ tags: [''] })
  })

  it('builds empty object for object without ref', () => {
    const props = [
      prop({ name: 'meta', type: 'object' }),
    ]
    const result = buildDefaultJson(props)
    expect(result).toEqual({ meta: {} })
  })
})

describe('isCircular', () => {
  it('returns true when definition name is in visited set', () => {
    const field = createField(
      prop({ name: 'self', type: 'object', ref: '#/definitions/Address' }),
      [],
      spaSchema({ definitions: [definition({ name: 'Address' })] }),
    )
    expect(isCircular(field, new Set(['Address']))).toBe(true)
  })

  it('returns false when definition name is not in visited set', () => {
    const field = createField(
      prop({ name: 'self', type: 'object', ref: '#/definitions/Address' }),
      [],
      spaSchema({ definitions: [definition({ name: 'Address' })] }),
    )
    expect(isCircular(field, new Set())).toBe(false)
  })

  it('returns false when resolvedDef is null', () => {
    const field = createField(prop({ name: 'x', type: 'string' }), [], spaSchema())
    expect(isCircular(field, new Set())).toBe(false)
  })
})

describe('parseFieldValue', () => {
  it('parses string value', () => {
    const field = createField(prop({ name: 'x', type: 'string' }), [], spaSchema())
    field.rawValue = 'hello'
    expect(parseFieldValue(field)).toBe('hello')
  })

  it('parses integer value', () => {
    const field = createField(prop({ name: 'x', type: 'integer' }), [], spaSchema())
    field.rawValue = '42'
    expect(parseFieldValue(field)).toBe(42)
  })

  it('parses array from arrayItems', () => {
    const field = createField(prop({ name: 'x', type: 'array', itemsType: 'string' }), [], spaSchema())
    field.arrayItems = ['a', 'b']
    expect(parseFieldValue(field)).toEqual(['a', 'b'])
  })

  it('parses array of integers', () => {
    const field = createField(prop({ name: 'x', type: 'array', itemsType: 'integer' }), [], spaSchema())
    field.arrayItems = ['1', '2', '3']
    expect(parseFieldValue(field)).toEqual([1, 2, 3])
  })
})
