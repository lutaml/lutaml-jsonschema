# frozen_string_literal: true

require "spec_helper"
require "lutaml/jsonschema/configuration"

RSpec.describe Lutaml::Jsonschema::Configuration do
  describe ".new" do
    it "has sensible defaults" do
      config = described_class.new
      expect(config.theme).to eq("light")
      expect(config.output_path).to eq("output")
      expect(config.title).to be_nil
    end
  end

  describe ".load_from_file" do
    it "loads configuration from YAML" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "config.yml")
        File.write(path, <<~YAML)
          title: Test Docs
          version: "1.0"
          theme: dark
          output_path: /tmp/docs
        YAML
        config = described_class.load_from_file(path)
        expect(config.title).to eq("Test Docs")
        expect(config.version).to eq("1.0")
        expect(config.theme).to eq("dark")
        expect(config.output_path).to eq("/tmp/docs")
      end
    end

    it "returns defaults for missing file" do
      config = described_class.load_from_file("/nonexistent.yml")
      expect(config).to be_a(described_class)
      expect(config.theme).to eq("light")
    end
  end

  describe "#to_metadata" do
    it "converts to Spa::Metadata" do
      config = described_class.new
      config.title = "Test"
      config.version = "2.0"
      metadata = config.to_metadata
      expect(metadata).to be_a(Lutaml::Jsonschema::Spa::Metadata)
      expect(metadata.title).to eq("Test")
      expect(metadata.version).to eq("2.0")
    end
  end
end
