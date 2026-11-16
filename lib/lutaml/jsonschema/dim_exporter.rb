# frozen_string_literal: true

require "json"

module Lutaml
  module Jsonschema
    # Exports a JSON Schema to a Diagram Interchange Model (DIM) 0.1
    # document — the graph the Etassia engine lays out and draws. The
    # formation decision: one node per named definition ($defs and the
    # legacy definitions keyword), the root schema as a node when it
    # carries properties or composition, each property as a member
    # block (`name!: type` when required), and the relationships as
    # semantic edges — allOf as generalization, oneOf as composition,
    # anyOf as dependency, and local $refs as references. The emitter
    # sets no positions; the engine computes them.
    #
    # Recorded losses (v0.1): only local refs (#/.../$defs/Name and the
    # legacy #/definitions/Name form) resolve — external documents are
    # not drawn; property-level anonymous object/array schemas flatten
    # to their type keyword, their nested properties are not drawn;
    # items, patternProperties, additionalProperties, dependentSchemas,
    # if/then/else, not, pattern, numeric and string bounds, enums and
    # consts are not drawn; boolean schemas contribute no edges; every
    # edge targets a node that exists in the graph.
    class DimExporter
      DIM_VERSION = "0.1"
      NOTATION = "json-schema"
      WIDTH = 220
      COMPOSITION_STYLES = {
        all_of: "generalization",
        one_of: "composition",
        any_of: "dependency",
      }.freeze
      LOCAL_REF = %r{\A#(?:/\$defs|/definitions)/([^#/]+)\z}

      def initialize(schema)
        @schema = schema
      end

      # The DIM document as a Hash conforming to dim-0.1.schema.json.
      def export
        {
          "dim" => DIM_VERSION,
          "notation" => NOTATION,
          "graph" => {
            "id" => graph_id,
            "layoutOptions" => {
              "elk.algorithm" => "layered",
              "elk.direction" => "DOWN",
            },
            "children" => nodes,
            "edges" => edges,
          },
        }
      end

      # The document as JSON, ready for Etassia::Native.render_dim.
      def export_json
        JSON.pretty_generate(export)
      end

      private

      def graph_id
        id = read(@schema, :dollar_id)
        "schema-#{id || 'anonymous'}"
      end

      def node_ids
        @node_ids ||= ["root",
                       *definition_entries.map { |e| "definition-#{e.name}" }]
      end

      def nodes
        node_list = definition_entries.map { |entry| schema_node(entry) }
        node_list.unshift(root_node) if root_drawn?
        node_list
      end

      def definition_entries
        Array(read(@schema, :definition_entries))
      end

      # The document's entry schema, drawn only when it describes
      # structure of its own (properties or composition arms).
      def root_node
        return nil unless root_drawn?

        node("root", root_title, @schema)
      end

      def root_title
        read(@schema, :title) || "root"
      end

      def root_drawn?
        Array(read(@schema, :property_entries)).any? ||
          COMPOSITION_STYLES.keys.any? { |arm| Array(read(@schema, arm)).any? }
      end

      def schema_node(entry)
        node("definition-#{entry.name}", entry.name, read(entry, :schema))
      end

      def node(id, title, schema)
        content = [
          label(title, "title"),
          label(stereotype(schema), "stereotype"),
        ]
        content.concat(member_blocks(schema))
        {
          "id" => id,
          "width" => WIDTH,
          "height" => 24 + (22 * content.length),
          "content" => content,
        }
      end

      def stereotype(schema)
        read(schema, :type) || "schema"
      end

      def member_blocks(schema)
        Array(read(schema, :property_entries)).map do |entry|
          label(member_text(entry, schema), "member")
        end
      end

      def member_text(entry, owner)
        name = read(entry, :name)
        flag = Array(read(owner, :required)).include?(name) ? "!" : ""
        "#{name}#{flag}: #{property_type(read(entry, :schema))}"
      end

      def property_type(schema)
        local_ref(read(schema, :dollar_ref)) || read(schema, :type) || "any"
      end

      def edges
        sources = [[nil, @schema]] +
          definition_entries.map { |e| [e.name, read(e, :schema)] }
        sources.flat_map { |name, schema| schema_edges(name, schema) }
      end

      def source_id(name)
        return "root" if name.nil?

        id = "definition-#{name}"
        node_ids.include?(id) ? id : nil
      end

      def schema_edges(name, schema)
        source = source_id(name)
        return [] if source.nil?

        composition_edges(schema, source) + reference_edges(schema, source)
      end

      def composition_edges(schema, source)
        COMPOSITION_STYLES.filter_map do |arm, style|
          Array(read(schema, arm)).filter_map.with_index do |item, index|
            next if item.boolean?

            target = local_ref(read(item.value, :dollar_ref))
            next unless target && node_ids.include?("definition-#{target}")

            edge("compose-#{arm}-#{source}-#{index}", source,
                 "definition-#{target}", style)
          end
        end.flatten
      end

      def reference_edges(schema, source)
        seen = []
        Array(read(schema, :property_entries)).filter_map do |entry|
          target = local_ref(read(read(entry, :schema), :dollar_ref))
          next if target.nil? || seen.include?(target)
          next unless node_ids.include?("definition-#{target}")

          seen << target
          edge("references-#{source}-#{seen.length}", source,
               "definition-#{target}", "reference")
        end
      end

      def edge(id, source, target, style)
        {
          "id" => id,
          "sources" => [source],
          "targets" => [target],
          "style" => style,
        }
      end

      def label(text, role)
        { "kind" => "label", "text" => text, "role" => role }
      end

      # Only local refs resolve: "#/$defs/Name" and the legacy
      # "#/definitions/Name" name a node; everything else is a loss.
      def local_ref(ref)
        return nil if ref.nil?

        LOCAL_REF.match(ref.to_s)&.captures&.first
      end

      # Reopened model attributes read back as an uninitialized sentinel
      # rather than nil; everything goes through this guard.
      def read(obj, name)
        return nil if obj.nil?

        value = obj.public_send(name)
        return nil if Lutaml::Model::Utils.uninitialized?(value)

        value
      end
    end
  end
end
