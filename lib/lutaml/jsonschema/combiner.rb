# frozen_string_literal: true

module Lutaml
  module Jsonschema
    class Combiner
      def combine(schema_set)
        combined = Schema.new

        schema_set.schemas.each do |name, schema|
          schema.definition_entries.each do |entry|
            combined.definition_entries.push(entry)
          end

          ref_entry = PropertyEntry.new(
            name: name,
            schema: Schema.new(dollar_ref: "#/definitions/#{name}"),
          )
          combined.property_entries.push(ref_entry)

          combined.title ||= schema.title if schema.title
        end

        rewrite_refs!(combined)
        combined
      end

      private

      def rewrite_refs!(schema)
        return unless schema

        schema.dollar_ref = localize_ref(schema.dollar_ref) if schema.dollar_ref&.start_with?("#/")

        schema.each_child do |child, _segment|
          rewrite_refs!(child)
        end
      end

      def localize_ref(ref)
        ref.sub(%r{^#/definitions/}, "#/$defs/")
      end
    end
  end
end
