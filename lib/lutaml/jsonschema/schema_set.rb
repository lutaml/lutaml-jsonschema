# frozen_string_literal: true

module Lutaml
  module Jsonschema
    class SchemaSet
      attr_reader :schemas, :base_dir

      def initialize(base_dir: nil)
        @schemas = {}
        @base_dir = base_dir
        @resolver = ReferenceResolver.new(@schemas)
      end

      def self.load_from_files(*paths, base_dir: nil)
        set = new(base_dir: base_dir || infer_base_dir(paths))
        paths.each do |path|
          data = File.read(path)
          schema = Schema.from_json(data)
          name = File.basename(path, ".*")
          set.add(name, schema, path)
        end
        set
      end

      def self.load_from_directory(dir)
        paths = Dir.glob(File.join(dir, "*.json"))
        load_from_files(*paths, base_dir: dir)
      end

      def add(name, schema, file_path = nil)
        @schemas[name] = schema
        return unless file_path

        @file_paths ||= {}
        @file_paths[File.basename(file_path)] = file_path
      end

      def resolve_ref(ref_string, context_schema = nil)
        return nil unless ref_string

        if ref_string.start_with?("./")
          resolve_file_ref(ref_string, context_schema)
        elsif ref_string.start_with?("http://", "https://")
          resolve_remote_ref(ref_string)
        elsif ref_string.start_with?("#/")
          @resolver.resolve(ref_string, context_schema)
        elsif ref_string.start_with?("#") && !ref_string.start_with?("#/")
          resolve_anchor_ref(ref_string.delete_prefix("#"), context_schema)
        else
          @resolver.resolve(ref_string, context_schema)
        end
      end

      def validate!
        errors = []
        seen_refs = Set.new

        @schemas.each do |name, schema|
          collect_refs(schema, name, errors, seen_refs, "")
        end

        raise ValidationError, errors.join("\n") if errors.any?

        true
      end

      def valid?
        validate! rescue false
      end

      def all_definitions
        @schemas.flat_map do |_name, schema|
          schema.definition_entries
        end
      end

      def all_properties
        @schemas.flat_map do |_name, schema|
          schema.property_entries
        end
      end

      def validation_errors
        errors = []
        @schemas.each do |name, schema|
          collect_refs(schema, name, errors, Set.new, "")
        end
        errors
      end

      private

      def self.infer_base_dir(paths)
        return nil if paths.empty?

        File.dirname(paths.first)
      end

      def resolve_file_ref(ref, context_schema)
        return nil unless context_schema

        target_file = ref.sub(%r{^\./}, "")
        schema = find_schema_by_filename(target_file)
        return schema if schema

        # Try loading from base_dir
        if @base_dir
          path = File.join(@base_dir, target_file)
          if File.exist?(path)
            loaded = Schema.from_json(File.read(path))
            add(File.basename(target_file, ".*"), loaded, path)
            return loaded
          end
        end

        nil
      end

      def resolve_remote_ref(ref)
        return nil

        # Remote refs are not resolved — would need HTTP fetching
      end

      def resolve_anchor_ref(anchor, context_schema)
        return nil unless context_schema

        find_anchor(context_schema, anchor)
      end

      def find_anchor(schema, anchor)
        return schema if schema.dollar_anchor == anchor

        [
          schema.property_entries, schema.definition_entries,
          schema.pattern_property_entries, schema.all_of,
          schema.any_of, schema.one_of
        ].each do |entries|
          entries.each do |entry|
            next if entry.nil?

            child = entry.is_a?(PropertyEntry) ? entry.schema : entry
            next if child.nil?

            found = find_anchor(child, anchor)
            return found if found
          end
        end

        [schema.items, schema.not_schema, schema.if_schema,
         schema.then_schema, schema.else_schema].each do |child|
          next if child.nil?

          found = find_anchor(child, anchor)
          return found if found
        end

        nil
      end

      def find_schema_by_filename(filename)
        # Check if we already loaded this file
        @schemas.each do |name, schema|
          return schema if name == File.basename(filename, ".*")
        end

        # Check file_paths mapping
        return nil unless @file_paths&.key?(filename)

        name = File.basename(filename, ".*")
        @schemas[name]
      end

      def collect_refs(schema, source_name, errors, seen_refs, path)
        ref = schema.dollar_ref
        if ref && !seen_refs.include?("#{source_name}:#{path}:#{ref}")
          seen_refs.add("#{source_name}:#{path}:#{ref}")
          resolved = resolve_ref(ref, @schemas[source_name])
          errors << "#{source_name}#{path}: unresolvable $ref '#{ref}'" if resolved.nil? && ref.start_with?("#/", "./")
        end

        children = [
          [:property_entries, schema.property_entries],
          [:definition_entries, schema.definition_entries],
          [:pattern_property_entries, schema.pattern_property_entries],
        ]
        children.each do |key, entries|
          entries.each do |entry|
            collect_refs(entry.schema, source_name, errors, seen_refs, "#{path}/#{key}/#{entry.name}")
          end
        end

        schema.all_of.each_with_index { |s, i| collect_refs(s, source_name, errors, seen_refs, "#{path}/allOf[#{i}]") }
        schema.any_of.each_with_index { |s, i| collect_refs(s, source_name, errors, seen_refs, "#{path}/anyOf[#{i}]") }
        schema.one_of.each_with_index { |s, i| collect_refs(s, source_name, errors, seen_refs, "#{path}/oneOf[#{i}]") }

        single_children = {
          items: schema.items,
          not_schema: schema.not_schema,
          if_schema: schema.if_schema,
          then_schema: schema.then_schema,
          else_schema: schema.else_schema,
        }
        single_children.each do |attr, child|
          collect_refs(child, source_name, errors, seen_refs, "#{path}/#{attr}") if child
        end

        schema.links.each do |link|
          collect_refs(link.schema, source_name, errors, seen_refs, "#{path}/link.schema") if link.schema
          collect_refs(link.target_schema, source_name, errors, seen_refs, "#{path}/link.target_schema") if link.target_schema
        end
      end

      class ValidationError < StandardError; end
    end
  end
end
