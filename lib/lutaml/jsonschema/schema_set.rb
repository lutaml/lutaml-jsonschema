# frozen_string_literal: true

module Lutaml
  module Jsonschema
    class SchemaSet
      attr_reader :schemas
      attr_accessor :base_dir

      def initialize(base_dir: nil)
        @schemas = {}
        @base_dir = base_dir
        @file_paths = {}
        @source_jsons = {}
        @resolver = ReferenceResolver.new(@schemas)
      end

      def self.load_from_files(*paths, base_dir: nil)
        set = new(base_dir: base_dir || infer_base_dir(paths))
        paths.each do |path|
          data = File.read(path, encoding: "utf-8")
          schema = Schema.from_json(data)
          name = File.basename(path, ".*")
          set.add(name, schema, path, data)
        end
        set
      end

      def self.load_from_directory(dir)
        paths = Dir.glob(File.join(dir, "*.json"))
        load_from_files(*paths, base_dir: dir)
      end

      def add(name, schema, file_path = nil, source_json = nil)
        @schemas[name] = schema
        return unless file_path

        @file_paths[File.basename(file_path)] = file_path
        @source_jsons[name] = source_json if source_json
      end

      def source_json(name)
        @source_jsons[name]
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
        errors = validation_errors
        raise ValidationError, errors.join("\n") if errors.any?

        true
      end

      def valid?
        validate!
      rescue StandardError
        false
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

      def resolve_remote_ref(_ref)
        nil

        # Remote refs are not resolved — would need HTTP fetching
      end

      def resolve_anchor_ref(anchor, context_schema)
        return nil unless context_schema

        find_anchor(context_schema, anchor)
      end

      def find_anchor(schema, anchor)
        return schema if schema.dollar_anchor == anchor

        schema.each_child do |child, _segment|
          found = find_anchor(child, anchor)
          return found if found
        end

        nil
      end

      def find_schema_by_filename(filename)
        @schemas.each do |name, schema|
          return schema if name == File.basename(filename, ".*")
        end

        return nil unless @file_paths.key?(filename)

        name = File.basename(filename, ".*")
        @schemas[name]
      end

      def collect_refs(schema, source_name, errors, seen_refs, path)
        ref = schema.dollar_ref
        if ref && !seen_refs.include?("#{source_name}:#{path}:#{ref}")
          seen_refs.add("#{source_name}:#{path}:#{ref}")
          resolved = resolve_ref(ref, @schemas[source_name])
          errors << "#{source_name}#{path}: unresolvable $ref '#{ref}'" if resolved.nil? && ref.start_with?(
            "#/", "./"
          )
        end

        schema.each_child do |child, segment|
          collect_refs(child, source_name, errors, seen_refs,
                       "#{path}/#{segment}")
        end
      end

      class ValidationError < StandardError; end
    end
  end
end
