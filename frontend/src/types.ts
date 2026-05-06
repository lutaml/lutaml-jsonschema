export interface SpaMetadata {
  title?: string
  version?: string
  description?: string
  baseUrl?: string
  theme?: string
}

export interface SpaProperty {
  name: string
  title?: string
  description?: string
  type?: string
  format?: string
  required?: boolean
  default?: string
  pattern?: string
  enum?: string[]
  /** Resolved $ref — normalized from backend's "$ref" key during loadFromWindow() */
  ref?: string
  /** Raw JSON Schema $ref — present in window.SCHEMA_DATA before normalization */
  $ref?: string
  minLength?: number
  maxLength?: number
  minimum?: number
  maximum?: number
  itemsType?: string
  deprecated?: boolean
  readOnly?: boolean
  writeOnly?: boolean
  examples?: string[]
  minItems?: number
  maxItems?: number
  uniqueItems?: boolean
  multipleOf?: number
  const?: string
  exclusiveMinimum?: number
  exclusiveMaximum?: number
  additionalProperties?: boolean
  contentMediaType?: string
  contentEncoding?: string
}

export interface SpaDefinition {
  name: string
  title?: string
  description?: string
  type?: string
  properties: SpaProperty[]
  required: string[]
  examples?: string[]
}

export interface SpaSchema {
  name: string
  title?: string
  description?: string
  type?: string
  properties: SpaProperty[]
  definitions: SpaDefinition[]
  required: string[]
  examples?: string[]
  sourceJson?: string
  $schema?: string
  $id?: string
  additionalProperties?: boolean
}

export interface SpaSearchEntry {
  name: string
  title?: string
  type: string
  schemaName: string
}

export interface SpaDocument {
  metadata: SpaMetadata
  schemas: SpaSchema[]
  searchIndex: SpaSearchEntry[]
}

declare global {
  interface Window {
    SCHEMA_DATA: SpaDocument
  }
}
