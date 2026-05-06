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

        schema.property_entries.each { |e| rewrite_refs!(e.schema) }
        schema.definition_entries.each { |e| rewrite_refs!(e.schema) }
        schema.pattern_property_entries.each { |e| rewrite_refs!(e.schema) }
        rewrite_refs!(schema.items)
        rewrite_refs!(schema.not_schema)
        rewrite_refs!(schema.if_schema)
        rewrite_refs!(schema.then_schema)
        rewrite_refs!(schema.else_schema)
        schema.all_of.each { |s| rewrite_refs!(s) }
        schema.any_of.each { |s| rewrite_refs!(s) }
        schema.one_of.each { |s| rewrite_refs!(s) }
        schema.links.each do |l|
          rewrite_refs!(l.schema)
          rewrite_refs!(l.target_schema)
        end
      end

      def localize_ref(ref)
        ref
      end
    end
  end
end
