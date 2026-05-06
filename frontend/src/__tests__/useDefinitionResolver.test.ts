import { describe, it, expect } from 'vitest'
import { resolveSchemaRef } from '../composables/useDefinitionResolver'
import type { SpaSchema, SpaDefinition } from '../types'

function definition(overrides: Partial<SpaDefinition> = {}): SpaDefinition {
  return { name: 'Test', properties: [], required: [], ...overrides }
}

function schema(overrides: Partial<SpaSchema> = {}): SpaSchema {
  return { name: 'TestSchema', properties: [], definitions: [], required: [], ...overrides }
}

describe('resolveSchemaRef', () => {
  it('returns null for undefined ref', () => {
    expect(resolveSchemaRef(undefined, schema())).toBeNull()
  })

  it('returns null for empty string ref', () => {
    expect(resolveSchemaRef('', schema())).toBeNull()
  })

  it('resolves #/definitions/NAME', () => {
    const address = definition({ name: 'address', title: 'Address', type: 'object' })
    const s = schema({ definitions: [address] })
    expect(resolveSchemaRef('#/definitions/address', s)).toBe(address)
  })

  it('resolves #/$defs/NAME', () => {
    const email = definition({ name: 'email', type: 'object' })
    const s = schema({ definitions: [email] })
    expect(resolveSchemaRef('#/$defs/email', s)).toBe(email)
  })

  it('returns null for non-existent definition', () => {
    const s = schema({ definitions: [definition({ name: 'other' })] })
    expect(resolveSchemaRef('#/definitions/missing', s)).toBeNull()
  })

  it('returns null for malformed ref', () => {
    expect(resolveSchemaRef('not-a-ref', schema())).toBeNull()
  })

  it('returns null for partial ref without definition name', () => {
    expect(resolveSchemaRef('#/definitions/', schema())).toBeNull()
  })
})
