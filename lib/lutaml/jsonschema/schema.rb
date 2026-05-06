# frozen_string_literal: true

module Lutaml
  module Jsonschema
    class Schema < Base
      # Document-level keywords
      attribute :dollar_schema, :string
      attribute :dollar_id, :string
      attribute :dollar_ref, :string
      attribute :dollar_comment, :string
      attribute :dollar_anchor, :string

      # Metadata
      attribute :title, :string
      attribute :description, :string
      attribute :default, :string
      attribute :examples, :string, collection: true
      attribute :deprecated, :boolean
      attribute :read_only, :boolean
      attribute :write_only, :boolean

      # Type keywords
      attribute :type, :string
      attribute :format, :string

      # Object keywords
      attribute :property_entries, PropertyEntry, collection: true, initialize_empty: true
      attribute :pattern_property_entries, PropertyEntry, collection: true, initialize_empty: true
      attribute :required, :string, collection: true, initialize_empty: true
      attribute :additional_properties, :boolean
      attribute :additional_properties_schema, Schema
      attribute :min_properties, :integer
      attribute :max_properties, :integer

      # Array keywords
      attribute :items, Schema
      attribute :min_items, :integer
      attribute :max_items, :integer
      attribute :unique_items, :boolean
      attribute :contains, Schema

      # Numeric keywords
      attribute :minimum, :float
      attribute :maximum, :float
      attribute :exclusive_minimum, :float
      attribute :exclusive_maximum, :float
      attribute :multiple_of, :float

      # String keywords
      attribute :min_length, :integer
      attribute :max_length, :integer
      attribute :pattern, :string
      attribute :content_type, :string
      attribute :content_encoding, :string

      # Enum / const
      attribute :enum, :string, collection: true
      attribute :const, :string

      # Composition (recursive)
      attribute :all_of, Schema, collection: true, initialize_empty: true
      attribute :any_of, Schema, collection: true, initialize_empty: true
      attribute :one_of, Schema, collection: true, initialize_empty: true
      attribute :not_schema, Schema

      # Conditional
      attribute :if_schema, Schema
      attribute :then_schema, Schema
      attribute :else_schema, Schema

      # Definitions ($defs / definitions)
      attribute :definition_entries, PropertyEntry, collection: true, initialize_empty: true

      # Hyper-schema links
      attribute :links, Link, collection: true, initialize_empty: true

      json do
        map "$schema", to: :dollar_schema
        map ["$id", "id"], to: :dollar_id
        map "$ref", to: :dollar_ref
        map "$comment", to: :dollar_comment
        map "$anchor", to: :dollar_anchor
        map "title", to: :title
        map "description", to: :description
        map "default", to: :default
        map ["examples", "example"], to: :examples
        map "deprecated", to: :deprecated
        map "readOnly", to: :read_only
        map "writeOnly", to: :write_only
        map "type", to: :type,
                   with: { from: :parse_type, to: :serialize_type }
        map "format", to: :format
        map "properties", to: :property_entries,
                          child_mappings: { name: :key, schema: :value }
        map "patternProperties", to: :pattern_property_entries,
                                  child_mappings: { name: :key, schema: :value }
        map "required", to: :required
        map "additionalProperties", to: :additional_properties,
                                   with: { from: :parse_additional_properties,
                                           to: :serialize_additional_properties }
        map "minProperties", to: :min_properties
        map "maxProperties", to: :max_properties
        map "items", to: :items
        map "minItems", to: :min_items
        map "maxItems", to: :max_items
        map "uniqueItems", to: :unique_items
        map "contains", to: :contains
        map "minimum", to: :minimum
        map "maximum", to: :maximum
        map "exclusiveMinimum", to: :exclusive_minimum
        map "exclusiveMaximum", to: :exclusive_maximum
        map "multipleOf", to: :multiple_of
        map "minLength", to: :min_length
        map "maxLength", to: :max_length
        map "pattern", to: :pattern
        map "contentMediaType", to: :content_type
        map "contentEncoding", to: :content_encoding
        map "enum", to: :enum
        map "const", to: :const
        map "allOf", to: :all_of
        map "anyOf", to: :any_of
        map "oneOf", to: :one_of
        map "not", to: :not_schema
        map "if", to: :if_schema
        map "then", to: :then_schema
        map "else", to: :else_schema
        map "$defs", to: :definition_entries,
                     child_mappings: { name: :key, schema: :value }
        map "definitions", to: :definition_entries,
                           with: { from: :parse_legacy_definitions, to: :noop_serializer }
        map "links", to: :links
      end

      def parse_type(instance, value)
        instance.type = value.is_a?(Array) ? value.join(",") : value
      end

      def serialize_type(instance, hash)
        t = instance.type
        return unless t

        parts = t.split(",")
        hash["type"] = parts.length == 1 ? parts.first : parts
      end

      def parse_additional_properties(instance, value)
        case value
        when true, false
          instance.additional_properties = value
        when Hash
          instance.additional_properties_schema = Schema.from_json(value.to_json)
        end
      end

      def serialize_additional_properties(instance, hash)
        if instance.additional_properties_schema
          hash["additionalProperties"] = JSON.parse(instance.additional_properties_schema.to_json)
        elsif !instance.additional_properties.nil?
          hash["additionalProperties"] = instance.additional_properties
        end
      end

      def object?
        types.include?("object")
      end

      def array?
        types.include?("array")
      end

      def types
        return [] unless type

        type.split(",")
      end

      def ref?
        !!dollar_ref
      end

      def all_property_entries
        result = property_entries.dup
        all_of.each { |s| result.concat(s.all_property_entries) }
        result
      end

      def noop_serializer(_instance, _hash); end

      def parse_legacy_definitions(instance, value)
        return unless value.is_a?(Hash)

        value.each do |name, schema_hash|
          next if instance.definition_entries.any? { |e| e.name == name }

          instance.definition_entries.push(
            PropertyEntry.new(
              name: name,
              schema: Schema.from_json(schema_hash.to_json)
            )
          )
        end
      end
    end
  end
end
