# frozen_string_literal: true

module Lutaml
  module Jsonschema
    # Resolves `$ref` values: JSON Pointer fragments (RFC 6901),
    # anchors (`$anchor`, and the draft-04 legacy `id: "#name"` form),
    # and remote/document refs through the schema set's name map.
    class ReferenceResolver
      def initialize(schemas = {})
        @schemas = schemas
      end

      def resolve(ref, root_schema = nil)
        return nil unless ref
        return root_schema if ref == "#"
        return resolve_local(ref, root_schema) if ref.start_with?("#/")
        return resolve_anchor(ref.delete_prefix("#"), root_schema) if ref.start_with?("#")

        resolve_remote(ref)
      end

      def resolve_local(ref, schema)
        parts = ref.delete_prefix("#/").split("/", -1)
        current = schema

        parts.each do |part|
          current = navigate(current, decode_segment(part))
          return nil unless current
        end

        if current.is_a?(Schema) && current.dollar_ref
          resolve(current.dollar_ref, schema)
        else
          current
        end
      end

      # A non-pointer fragment names an anchor: `$anchor` (2019-09+), or
      # the draft-04 legacy `id: "#name"`.
      def resolve_anchor(name, schema)
        return nil unless schema

        find_anchor(schema, decode_segment(name), {}.compare_by_identity)
      end

      def resolve_remote(ref)
        return nil unless @schemas

        if ref.include?("#")
          file_path, fragment = ref.split("#", 2)
          schema = @schemas[file_path]
          return nil unless schema
          return schema if fragment.empty?

          resolve("##{fragment}", schema)
        else
          @schemas[ref]
        end
      end

      private

      def navigate(current, part)
        case current
        when Schema
          current.child_at(part)
        when Array
          if part.match?(/\A\d+\z/)
            current[part.to_i]
          else
            entry = current.find do |e|
              e.is_a?(PropertyEntry) && e.name == part
            end
            entry&.schema
          end
        end
      end

      def find_anchor(schema, name, seen)
        return nil unless schema.is_a?(Schema)
        return nil if seen.key?(schema)

        seen[schema] = true
        return schema if schema.dollar_anchor == name
        return schema if schema.dollar_id == "##{name}"

        schema.each_child do |child, _segment|
          found = find_anchor(child, name, seen)
          return found if found
        end
        nil
      end

      # RFC 6901: percent-decode the fragment, then unescape ~1 -> "/"
      # and finally ~0 -> "~" (order matters: "~01" decodes to "~1").
      def decode_segment(segment)
        bytes = segment.b.gsub(/%([0-9A-Fa-f]{2})/) do
          Regexp.last_match(1).hex.chr
        end
        bytes.force_encoding(Encoding::UTF_8).gsub("~1", "/").gsub("~0", "~")
      end
    end
  end
end
