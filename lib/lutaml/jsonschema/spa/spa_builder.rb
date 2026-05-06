# frozen_string_literal: true

module Lutaml
  module Jsonschema
    module Spa
      class SpaBuilder
        def initialize(schema_set, metadata: nil)
          @schema_set = schema_set
          @metadata = metadata || Metadata.new
        end

        def build
          infer_metadata_title if @metadata.title.nil?

          schemas = build_schemas
          search_index = build_search_index(schemas)

          SpaDocument.new(
            metadata: @metadata,
            schemas: schemas,
            search_index: search_index
          )
        end

        private

        def infer_metadata_title
          first_schema = @schema_set.schemas.values.first
          @metadata.title = first_schema&.title if first_schema&.title
        end

        def build_schemas
          @schema_set.schemas.map do |name, schema|
            build_spa_schema(name, schema)
          end
        end

        def build_spa_schema(name, schema)
          all_props = collect_all_properties(schema)
          all_defs = collect_all_definitions(schema)
          all_required = collect_all_required(schema)

          properties = build_properties(all_props, schema, all_required)
          definitions = build_definitions_from_entries(all_defs, schema)

          SpaSchema.new(
            name: name,
            title: schema.title,
            description: schema.description,
            type: schema.type,
            properties: properties,
            definitions: definitions,
            required: all_required,
            examples: schema.examples
          )
        end

        def collect_all_properties(schema)
          entries = schema.property_entries.dup
          composition_schemas(schema).each do |s|
            entries.concat(collect_all_properties(s))
          end
          entries
        end

        def collect_all_definitions(schema)
          entries = schema.definition_entries.dup
          composition_schemas(schema).each do |s|
            entries.concat(collect_all_definitions(s))
          end
          entries
        end

        def collect_all_required(schema)
          required = schema.required.dup
          composition_schemas(schema).each do |s|
            required.concat(collect_all_required(s))
          end
          required
        end

        def composition_schemas(schema)
          schema.all_of + schema.any_of + schema.one_of
        end

        def build_definitions_from_entries(entries, root_schema)
          entries.map do |entry|
            s = entry.schema
            properties = build_properties(s.property_entries, root_schema, s.required)

            SpaDefinition.new(
              name: entry.name,
              title: s.title,
              description: s.description,
              type: s.type,
              properties: properties,
              required: s.required,
              examples: s.examples
            )
          end
        end

        def build_properties(entries, root_schema, all_required = root_schema.required)
          entries.map do |entry|
            resolved = resolve_property(entry, root_schema)
            SpaProperty.new(
              name: entry.name,
              title: resolved.title,
              description: resolved.description,
              type: resolved.type,
              format: resolved.format,
              required: all_required.include?(entry.name),
              default: resolved.default,
              pattern: resolved.pattern,
              enum: resolved.enum,
              ref: entry.schema.dollar_ref,
              min_length: resolved.min_length,
              max_length: resolved.max_length,
              minimum: resolved.minimum,
              maximum: resolved.maximum,
              items_type: resolved.items&.type,
              deprecated: resolved.deprecated,
              examples: resolved.examples
            )
          end
        end

        def resolve_property(entry, root_schema)
          return entry.schema unless entry.schema.dollar_ref

          @schema_set.resolve_ref(entry.schema.dollar_ref, root_schema) || entry.schema
        end

        def build_search_index(schemas)
          schemas.flat_map do |spa_schema|
            raw_schema = @schema_set.schemas[spa_schema.name]

            entries = [SpaSearchEntry.new(
              name: spa_schema.name,
              title: spa_schema.title,
              type: "schema",
              schema_name: spa_schema.name
            )]

            spa_schema.properties.each do |prop|
              entries << SpaSearchEntry.new(
                name: prop.name,
                title: prop.title,
                type: "property",
                schema_name: spa_schema.name
              )
            end

            spa_schema.definitions.each do |defn|
              entries << SpaSearchEntry.new(
                name: defn.name,
                title: defn.title,
                type: "definition",
                schema_name: spa_schema.name
              )

              defn.properties.each do |prop|
                entries << SpaSearchEntry.new(
                  name: prop.name,
                  title: prop.title,
                  type: "property",
                  schema_name: spa_schema.name
                )
              end
            end

            entries
          end
        end
      end
    end
  end
end
