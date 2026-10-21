# frozen_string_literal: true

module Lutaml
  module Jsonschema
    module Exports
      # Renders a SchemaSet as an AsciiDoc reference document, suitable for
      # Metanorma/standards-body pipelines.
      #
      # Approximation notes: descriptions and constraints are prose; boolean
      # schemas render as "any value" / "no value"; external $refs link by
      # their last path segment.
      #
      # With embeddable: true the document title (the level-0 `=` heading)
      # is dropped and definition anchors are prefixed with the schema
      # name, so the output can be `include::`-ed into a Metanorma
      # document — or any AsciiDoc host — without heading-level or
      # anchor collisions.
      class Adoc
        def initialize(schema_set, embeddable: false)
          @schema_set = schema_set
          @embeddable = embeddable
        end

        def render
          parts = []
          parts << document_title unless @embeddable
          @schema_set.schemas.each do |name, schema|
            parts << render_schema(name, schema)
          end
          "#{parts.join("\n\n").strip}\n"
        end

        private

        def document_title
          title = @schema_set.schemas.values.first&.title
          "= #{title || 'JSON Schema Reference'}"
        end

        def render_schema(name, schema)
          @anchor_prefix = @embeddable ? "#{anchor_slug(name)}-" : ""
          lines = ["== #{schema.title || name}", ""] + body_lines(schema)
          schema.definition_entries.each do |entry|
            lines << render_definition(entry) << ""
          end
          lines.join("\n").strip
        end

        def body_lines(schema)
          lines = []
          lines << "#{schema.description}\n" if present?(schema.description)
          if schema.property_entries.empty?
            lines << "Type: #{type_label(schema)}" << ""
          else
            lines.concat(properties_table(schema))
          end
          lines
        end

        def render_definition(entry)
          value = entry.schema_value
          body = if value.is_a?(Schema)
                   body_lines(value)
                 else
                   [value ? "Any value." : "No value allowed.", ""]
                 end
          lines = ["[##{anchor_id(entry.name)}]", "=== #{entry.name}",
                   ""] + body
          lines.join("\n").strip
        end

        def properties_table(schema)
          return [] if schema.property_entries.empty?

          required = schema.required || []
          lines = ['[cols="2,2,1,4",options="header"]', "|==="]
          lines << "|Name |Type |Required |Description"
          schema.property_entries.each do |entry|
            lines << property_row(entry, required)
          end
          lines << "|===" << ""
          lines
        end

        def property_row(entry, required)
          cells = [
            "`#{entry.name}`",
            type_label(entry.schema_value),
            required.include?(entry.name) ? "Yes" : "No",
            description_cell(entry.schema_value),
          ]
          "|#{cells.map { |cell| escape_cell(cell) }.join(' |')}"
        end

        def type_label(value)
          return "any value" if value == true
          return "no value" if value == false
          return "any" unless value.is_a?(Schema)

          schema_type_label(value)
        end

        def schema_type_label(schema)
          return ref_link(schema.dollar_ref) if schema.dollar_ref

          tuple = schema.tuple_items
          return tuple_label(schema, tuple) if tuple
          return "array of #{type_label(schema.items)}" if array?(schema)

          schema.type || schema.title || "any"
        end

        def tuple_label(schema, tuple)
          members = tuple.map { |item| type_label(item) }
          unless schema.items_closed?
            tail = schema.items_tail_schema
            members << (tail ? type_label(tail) : "...")
          end
          "[#{members.join(', ')}]"
        end

        def array?(schema)
          schema.types.include?("array") || schema.items || schema.prefix_items.any?
        end

        def description_cell(value)
          return "" unless value.is_a?(Schema)

          parts = []
          if present?(value.description)
            parts << value.description.to_s.strip.delete_suffix(".")
          end
          summary = constraints(value)
          parts << summary if summary
          parts.join("; ")
        end

        def constraints(schema)
          items = []
          items << "Allowed: #{schema.enum.join(', ')}" if schema.enum&.any?
          items << "Pattern: `#{schema.pattern}`" if present?(schema.pattern)
          items.concat(range_constraints(schema))
          items.empty? ? nil : items.join("; ")
        end

        def range_constraints(schema)
          [
            bounded("Minimum", schema.minimum),
            bounded("Maximum", schema.maximum),
            bounded("Min length", schema.min_length),
            bounded("Max length", schema.max_length),
          ].compact
        end

        def bounded(label, value)
          "#{label}: #{number(value)}" unless value.nil?
        end

        def number(value)
          value == value.to_i ? value.to_i.to_s : value.to_s
        end

        def ref_link(ref)
          name = ref.split("/").last
          "<<#{anchor_id(name)},#{name}>>"
        end

        # definition anchors: `def-<name>` standalone, `def-<schema>-<name>`
        # when embedded so a host document (and sibling includes) cannot
        # collide
        def anchor_slug(name)
          name.to_s.gsub(/[^A-Za-z0-9_-]/, "-").downcase
        end

        def anchor_id(name)
          id = name.to_s.gsub(/[^A-Za-z0-9_-]/, "-")
          "def-#{@anchor_prefix}#{id}"
        end

        def escape_cell(text)
          text.to_s.gsub("|", "\\\\|").gsub("\n", " ").strip
        end

        def present?(value)
          !value.nil? && !value.to_s.empty?
        end
      end
    end
  end
end
