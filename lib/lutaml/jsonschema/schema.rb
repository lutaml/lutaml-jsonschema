# frozen_string_literal: true

require "yeptris"

module Lutaml
  module Jsonschema
    class Schema < Base
      # Document-level keywords
      attribute :dollar_schema, :string
      attribute :dollar_id, :string
      attribute :dollar_ref, :string
      attribute :dollar_comment, :string
      attribute :dollar_anchor, :string
      attribute :dollar_dynamic_anchor, :string
      attribute :dollar_dynamic_ref, :string
      attribute :dollar_recursive_anchor, :boolean
      attribute :dollar_recursive_ref, :string

      # Metadata
      attribute :title, :string
      attribute :description, :string
      attribute :default, :string
      attribute :examples, :string, collection: true
      attribute :deprecated, :boolean
      attribute :read_only, :boolean
      attribute :write_only, :boolean
      attribute :external_docs, :hash

      # Type keywords
      attribute :type, :string
      attribute :format, :string

      # Object keywords
      attribute :property_entries, PropertyEntry, collection: true,
                                                  initialize_empty: true
      attribute :pattern_property_entries, PropertyEntry, collection: true,
                                                          initialize_empty: true
      attribute :required, :string, collection: true, initialize_empty: true
      attribute :additional_properties, :boolean
      attribute :additional_properties_schema, Schema
      attribute :unevaluated_properties, :boolean
      attribute :unevaluated_properties_schema, Schema
      attribute :property_names, Schema
      attribute :dependent_required, :hash
      attribute :dependent_schemas_entries, PropertyEntry, collection: true,
                                                           initialize_empty: true
      attribute :dependencies, :hash
      attribute :min_properties, :integer
      attribute :max_properties, :integer

      # Array keywords
      attribute :items, Schema
      attribute :prefix_items, Schema, collection: true, initialize_empty: true
      attribute :additional_items, :boolean
      attribute :additional_items_schema, Schema
      attribute :unevaluated_items, :boolean
      attribute :unevaluated_items_schema, Schema
      attribute :min_items, :integer
      attribute :max_items, :integer
      attribute :unique_items, :boolean
      attribute :contains, Schema
      attribute :min_contains, :integer
      attribute :max_contains, :integer

      # Numeric keywords (exclusive* is boolean in draft-04, numeric from draft-06)
      attribute :minimum, :float
      attribute :maximum, :float
      attribute :exclusive_minimum, %i[float boolean]
      attribute :exclusive_maximum, %i[float boolean]
      attribute :multiple_of, :float

      # String keywords
      attribute :min_length, :integer
      attribute :max_length, :integer
      attribute :pattern, :string
      attribute :content_type, :string
      attribute :content_encoding, :string
      attribute :content_schema, Schema

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
      attribute :definition_entries, PropertyEntry, collection: true,
                                                    initialize_empty: true

      # Hyper-schema links
      attribute :links, Link, collection: true, initialize_empty: true

      # rubocop:disable Metrics/BlockLength -- the keyword mapping table
      json do
        map "$schema", to: :dollar_schema
        map ["$id", "id"], to: :dollar_id
        map "$ref", to: :dollar_ref
        map "$comment", to: :dollar_comment
        map "$anchor", to: :dollar_anchor
        map "$dynamicAnchor", to: :dollar_dynamic_anchor
        map "$dynamicRef", to: :dollar_dynamic_ref
        map "$recursiveAnchor", to: :dollar_recursive_anchor
        map "$recursiveRef", to: :dollar_recursive_ref
        map "title", to: :title
        map "description", to: :description
        map "default", to: :default
        map ["examples", "example"], to: :examples
        map "deprecated", to: :deprecated
        map "readOnly", to: :read_only
        map "writeOnly", to: :write_only
        map "externalDocs", to: :external_docs
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
        map "unevaluatedProperties", to: :unevaluated_properties,
                                     with: { from: :parse_unevaluated_properties,
                                             to: :serialize_unevaluated_properties }
        map "propertyNames", to: :property_names
        map "dependentRequired", to: :dependent_required
        map "dependentSchemas", to: :dependent_schemas_entries,
                                child_mappings: { name: :key, schema: :value }
        map "dependencies", to: :dependencies
        map "minProperties", to: :min_properties
        map "maxProperties", to: :max_properties
        map "items", to: :items
        map "prefixItems", to: :prefix_items
        map "additionalItems", to: :additional_items,
                               with: { from: :parse_additional_items,
                                       to: :serialize_additional_items }
        map "unevaluatedItems", to: :unevaluated_items,
                                with: { from: :parse_unevaluated_items,
                                        to: :serialize_unevaluated_items }
        map "minItems", to: :min_items
        map "maxItems", to: :max_items
        map "uniqueItems", to: :unique_items
        map "contains", to: :contains
        map "minContains", to: :min_contains
        map "maxContains", to: :max_contains
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
        map "contentSchema", to: :content_schema
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
                           with: { from: :parse_legacy_definitions, to: :suppress_output }
        map "links", to: :links
      end
      # rubocop:enable Metrics/BlockLength

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
          hash["additionalProperties"] =
            Yeptris::JSON.load(instance.additional_properties_schema.to_json)
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

      def child_at(segment)
        case segment
        when "definitions", "$defs" then definition_entries
        when "properties" then property_entries
        when "patternProperties" then pattern_property_entries
        when "dependentSchemas" then dependent_schemas_entries
        when "items" then items
        when "prefixItems" then prefix_items
        when "additionalItems" then additional_items_schema
        when "unevaluatedItems" then unevaluated_items_schema
        when "unevaluatedProperties" then unevaluated_properties_schema
        when "propertyNames" then property_names
        when "contentSchema" then content_schema
        when "allOf" then all_of
        when "anyOf" then any_of
        when "oneOf" then one_of
        when "not" then not_schema
        when "if" then if_schema
        when "then" then then_schema
        when "else" then else_schema
        else
          definition_entries.find { |e| e.name == segment }&.schema
        end
      end

      def each_child
        return enum_for(:each_child) unless block_given?

        property_entries.each do |e|
          yield e.schema, "properties/#{e.name}" if e.schema
        end
        definition_entries.each do |e|
          yield e.schema, "$defs/#{e.name}" if e.schema
        end
        pattern_property_entries.each do |e|
          yield e.schema, "patternProperties/#{e.name}" if e.schema
        end
        dependent_schemas_entries.each do |e|
          yield e.schema, "dependentSchemas/#{e.name}" if e.schema
        end
        all_of.each_with_index { |s, i| yield s, "allOf[#{i}]" }
        any_of.each_with_index { |s, i| yield s, "anyOf[#{i}]" }
        one_of.each_with_index { |s, i| yield s, "oneOf[#{i}]" }
        prefix_items.each_with_index { |s, i| yield s, "prefixItems[#{i}]" }
        yield items, "items" if items
        yield additional_items_schema, "additionalItems" if additional_items_schema
        yield unevaluated_items_schema, "unevaluatedItems" if unevaluated_items_schema
        if unevaluated_properties_schema
          yield unevaluated_properties_schema, "unevaluatedProperties"
        end
        yield property_names, "propertyNames" if property_names
        yield content_schema, "contentSchema" if content_schema
        yield not_schema, "not" if not_schema
        yield if_schema, "if" if if_schema
        yield then_schema, "then" if then_schema
        yield else_schema, "else" if else_schema
        links.each do |link|
          yield link.schema, "link.schema" if link.schema
          yield link.target_schema, "link.target_schema" if link.target_schema
        end
      end

      def suppress_output(_instance, _hash); end

      # -- Dialect and draft-aware semantics -----------------------------

      def dialect
        Dialect.detect(dollar_schema)
      end

      # draft-04 expresses exclusivity as a boolean modifier on
      # minimum/maximum; from draft-06 on the bound lives in the
      # exclusive* keyword itself. Return the effective numeric bound.
      def exclusive_minimum_value
        exclusive_bound_value(exclusive_minimum, minimum)
      end

      def exclusive_maximum_value
        exclusive_bound_value(exclusive_maximum, maximum)
      end

      def exclusive_bound_value(exclusive, bound)
        return nil if exclusive.nil? || exclusive == false
        return bound if exclusive == true

        exclusive
      end

      # -- Boolean-or-schema keywords ------------------------------------

      def parse_additional_items(instance, value)
        parse_boolean_or_schema(instance, value,
                                :additional_items=, :additional_items_schema=)
      end

      def serialize_additional_items(instance, hash)
        serialize_boolean_or_schema(hash, "additionalItems",
                                    instance.additional_items,
                                    instance.additional_items_schema)
      end

      def parse_unevaluated_items(instance, value)
        parse_boolean_or_schema(instance, value,
                                :unevaluated_items=, :unevaluated_items_schema=)
      end

      def serialize_unevaluated_items(instance, hash)
        serialize_boolean_or_schema(hash, "unevaluatedItems",
                                    instance.unevaluated_items,
                                    instance.unevaluated_items_schema)
      end

      def parse_unevaluated_properties(instance, value)
        parse_boolean_or_schema(instance, value,
                                :unevaluated_properties=,
                                :unevaluated_properties_schema=)
      end

      def serialize_unevaluated_properties(instance, hash)
        serialize_boolean_or_schema(hash, "unevaluatedProperties",
                                    instance.unevaluated_properties,
                                    instance.unevaluated_properties_schema)
      end

      def parse_boolean_or_schema(instance, value, boolean_writer,
                                  schema_writer)
        case value
        when true, false
          instance.public_send(boolean_writer, value)
        when Hash
          instance.public_send(schema_writer, Schema.from_json(value.to_json))
        end
      end

      def serialize_boolean_or_schema(hash, key, boolean, schema)
        if schema
          hash[key] = Yeptris::JSON.load(schema.to_json)
        elsif !boolean.nil?
          hash[key] = boolean
        end
      end

      def parse_legacy_definitions(instance, value)
        return unless value.is_a?(Hash)

        value.each do |name, schema_hash|
          next if instance.definition_entries.any? { |e| e.name == name }

          instance.definition_entries.push(
            PropertyEntry.new(
              name: name,
              schema: Schema.from_json(schema_hash.to_json),
            ),
          )
        end
      end
    end
  end
end
