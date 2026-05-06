# frozen_string_literal: true

require "thor"
require "json"
require "lutaml/jsonschema"
require "lutaml/jsonschema/configuration"

module Lutaml
  module Jsonschema
    class Cli < Thor
      desc "spa SCHEMA_FILES...", "Generate SPA documentation from JSON Schema files"
      option :output, aliases: "-o", type: :string, default: "output",
                      desc: "Output directory"
      option :config, aliases: "-c", type: :string,
                      desc: "Path to YAML configuration file"
      option :title, type: :string, desc: "Documentation title"
      option :theme, type: :string, default: "light", desc: "Theme (light/dark)"
      def spa(*schema_files)
        raise Error, "No schema files provided" if schema_files.empty?

        config = load_config(options[:config])
        config.output_path = options[:output] if options[:output]
        config.title = options[:title] if options[:title]
        config.theme = options[:theme] if options[:theme]

        schema_set = SchemaSet.load_from_files(*schema_files)
        generator = Spa::Generator.new(schema_set, config.output_path,
                                       metadata: config.to_metadata)
        generator.generate
        puts "SPA documentation generated at #{config.output_path}/index.html"
      rescue Errno::ENOENT => e
        abort "Error: #{e.message}"
      end

      desc "combine SCHEMA_FILES...", "Combine multiple JSON Schema files into one"
      option :output, aliases: "-o", type: :string, default: "-",
                      desc: "Output file path (use - for stdout)"
      def combine(*schema_files)
        raise Error, "No schema files provided" if schema_files.empty?

        schema_set = SchemaSet.load_from_files(*schema_files)
        combined = Combiner.new.combine(schema_set)
        json = JSON.pretty_generate(JSON.parse(combined.to_json))

        if options[:output] == "-"
          $stdout.write(json)
        else
          File.write(options[:output], json)
          puts "Combined schema written to #{options[:output]}"
        end
      rescue Errno::ENOENT => e
        abort "Error: #{e.message}"
      end

      desc "validate SCHEMA_FILE", "Validate a JSON Schema file"
      def validate(schema_file)
        data = File.read(schema_file)
        json = JSON.parse(data)
        Schema.from_json(data)

        errors = validate_structure(json)
        if errors.empty?
          puts "#{schema_file}: valid"
        else
          errors.each { |e| warn "  #{e}" }
          abort "#{schema_file}: #{errors.length} validation error(s)"
        end
      rescue JSON::ParserError => e
        abort "Invalid JSON: #{e.message}"
      rescue Errno::ENOENT => e
        abort "Error: #{e.message}"
      end

      desc "version", "Show version"
      def version
        puts "lutaml-jsonschema #{VERSION}"
      end

      private

      def load_config(path)
        return Configuration.new unless path

        Configuration.load_from_file(path)
      rescue Errno::ENOENT
        abort "Configuration file not found: #{path}"
      end

      def validate_structure(json)
        errors = []
        errors << "Missing $schema" unless json.key?("$schema")
        errors << "Missing type" unless json.key?("type")

        errors << "properties must be an object" if json.key?("properties") && !json["properties"].is_a?(Hash)

        errors << "required must be an array" if json.key?("required") && !json["required"].is_a?(Array)

        errors
      end
    end
  end
end
