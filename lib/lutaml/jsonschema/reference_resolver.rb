# frozen_string_literal: true

module Lutaml
  module Jsonschema
    class ReferenceResolver
      def initialize(schemas = {})
        @schemas = schemas
      end

      def resolve(ref, root_schema = nil)
        return nil unless ref

        if ref.start_with?("#/")
          resolve_local(ref, root_schema)
        else
          resolve_remote(ref)
        end
      end

      def resolve_local(ref, schema)
        parts = ref.delete_prefix("#/").split("/")
        current = schema

        parts.each do |part|
          case current
          when Schema
            current = navigate_schema(current, part)
          when Array
            entry = current.find { |e| e.is_a?(PropertyEntry) && e.name == part }
            current = entry&.schema
          else
            return nil
          end
          return nil unless current
        end

        current.is_a?(Schema) && current.dollar_ref ? resolve(current.dollar_ref, schema) : current
      end

      def resolve_remote(ref)
        return nil unless @schemas

        if ref.include?("#")
          file_path, fragment = ref.split("#", 2)
          schema = @schemas[file_path]
          schema ? resolve_local("##{fragment}", schema) : nil
        else
          @schemas[ref]
        end
      end

      private

      def navigate_schema(schema, part)
        case part
        when "definitions", "$defs"
          schema.definition_entries
        when "properties"
          schema.property_entries
        when "patternProperties"
          schema.pattern_property_entries
        when "items"
          schema.items
        when "allOf" then schema.all_of
        when "anyOf" then schema.any_of
        when "oneOf" then schema.one_of
        else
          entries = schema.definition_entries || []
          entries.find { |e| e.name == part }&.schema
        end
      end
    end
  end
end
