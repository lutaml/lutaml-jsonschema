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
            search_index: search_index,
          )
        end

        private

        def infer_metadata_title
          first_schema = @schema_set.schemas.values.first
          @metadata.title = first_schema&.title if first_schema&.title
        end

        def build_schemas
          @schema_set.schemas.to_a.map do |name, schema|
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
            examples: schema.examples,
            source_json: @schema_set.source_json(name) || "",
            dollar_schema: schema.dollar_schema,
            dollar_id: schema.dollar_id,
            additional_properties: schema.additional_properties,
          )
        end

        def collect_all_properties(schema, context_schema = schema)
          # Collect inherited properties first, then own properties override
          inherited = []
          composition_schemas(schema).each do |s|
            resolved = resolve_composition_schema(s, context_schema)
            inherited.concat(collect_all_properties(resolved, context_schema))
          end
          own = schema.property_entries.dup
          # Merge: own properties override inherited ones with the same name
          deduplicated_merge(inherited, own)
        end

        def collect_all_definitions(schema, context_schema = schema)
          inherited = []
          composition_schemas(schema).each do |s|
            resolved = resolve_composition_schema(s, context_schema)
            inherited.concat(collect_all_definitions(resolved, context_schema))
          end
          own = schema.definition_entries.dup
          deduplicated_merge(inherited, own)
        end

        def collect_all_required(schema, context_schema = schema)
          required = schema.required.dup
          composition_schemas(schema).each do |s|
            resolved = resolve_composition_schema(s, context_schema)
            required.concat(collect_all_required(resolved, context_schema))
          end
          required
        end

        def resolve_composition_schema(schema, context_schema)
          return schema unless schema.dollar_ref

          @schema_set.resolve_ref(schema.dollar_ref, context_schema) || schema
        end

        def composition_schemas(schema)
          schema.all_of + schema.any_of + schema.one_of
        end

        def deduplicated_merge(inherited, own)
          seen = {}
          all = inherited + own
          all.each_with_index do |entry, idx|
            seen[entry.name] = idx
          end
          seen.values.sort.map { |i| all[i] }
        end

        def build_definitions_from_entries(entries, root_schema)
          entries.map do |entry|
            s = entry.schema
            all_props = collect_all_properties(s)
            all_required = collect_all_required(s)
            properties = build_properties(all_props, root_schema, all_required)

            SpaDefinition.new(
              name: entry.name,
              title: s.title,
              description: s.description,
              type: s.type,
              properties: properties,
              required: all_required,
              examples: s.examples,
            )
          end
        end

        def build_properties(entries, root_schema,
all_required = root_schema.required)
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
              read_only: resolved.read_only,
              write_only: resolved.write_only,
              examples: resolved.examples,
              min_items: resolved.min_items,
              max_items: resolved.max_items,
              unique_items: resolved.unique_items,
              multiple_of: resolved.multiple_of,
              const_value: resolved.const,
              exclusive_minimum: resolved.exclusive_minimum,
              exclusive_maximum: resolved.exclusive_maximum,
              additional_properties: resolved.additional_properties,
              content_type: resolved.content_type,
              content_encoding: resolved.content_encoding,
            )
          end
        end

        def resolve_property(entry, root_schema)
          return entry.schema unless entry.schema.dollar_ref

          @schema_set.resolve_ref(entry.schema.dollar_ref,
                                  root_schema) || entry.schema
        end

        def build_search_index(schemas)
          schemas.flat_map do |spa_schema|
            @schema_set.schemas[spa_schema.name]

            entries = [SpaSearchEntry.new(
              name: spa_schema.name,
              title: spa_schema.title,
              type: "schema",
              schema_name: spa_schema.name,
            )]

            spa_schema.properties.each do |prop|
              entries << SpaSearchEntry.new(
                name: prop.name,
                title: prop.title,
                type: "property",
                schema_name: spa_schema.name,
              )
            end

            spa_schema.definitions.each do |defn|
              entries << SpaSearchEntry.new(
                name: defn.name,
                title: defn.title,
                type: "definition",
                schema_name: spa_schema.name,
              )

              defn.properties.each do |prop|
                entries << SpaSearchEntry.new(
                  name: prop.name,
                  title: prop.title,
                  type: "property",
                  schema_name: spa_schema.name,
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
