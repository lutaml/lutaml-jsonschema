# frozen_string_literal: true

require "yaml"

module Lutaml
  module Jsonschema
    class Configuration
      attr_accessor :title, :version, :description, :base_url, :theme,
                    :output_path

      def initialize
        @title = nil
        @version = nil
        @description = nil
        @base_url = nil
        @theme = "light"
        @output_path = "output"
      end

      def self.load_from_file(path)
        return new unless File.exist?(path)

        data = YAML.safe_load_file(path)
        config = new
        return config unless data.is_a?(Hash)

        config.title = data["title"] if data.key?("title")
        config.version = data["version"] if data.key?("version")
        config.description = data["description"] if data.key?("description")
        config.base_url = data["base_url"] if data.key?("base_url")
        config.theme = data["theme"] if data.key?("theme")
        config.output_path = data["output_path"] if data.key?("output_path")
        config
      end

      def to_metadata
        Spa::Metadata.new(
          title: title,
          version: version,
          description: description,
          base_url: base_url,
          theme: theme
        )
      end
    end
  end
end
