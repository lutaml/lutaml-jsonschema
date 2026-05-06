# frozen_string_literal: true

require "spec_helper"
require "lutaml/jsonschema/cli"
require "tmpdir"

RSpec.describe Lutaml::Jsonschema::Cli do
  let(:fixtures_dir) { File.expand_path("../fixtures", __dir__) }
  let(:person_schema) { File.join(fixtures_dir, "person.json") }
  let(:user_schema) { File.join(fixtures_dir, "user.json") }
  let(:post_schema) { File.join(fixtures_dir, "post.json") }

  describe "spa" do
    it "generates SPA documentation" do
      Dir.mktmpdir do |dir|
        described_class.start(["spa", person_schema, "-o", dir])
        output = File.join(dir, "index.html")
        expect(File.exist?(output)).to be true
        html = File.read(output)
        expect(html).to include("window.SCHEMA_DATA")
        expect(html).to include("<!DOCTYPE html>")
      end
    end

    it "generates with custom title" do
      Dir.mktmpdir do |dir|
        described_class.start(["spa", person_schema, "-o", dir, "--title",
                               "My Docs"])
        html = File.read(File.join(dir, "index.html"))
        expect(html).to include("My Docs")
      end
    end

    it "generates from multiple schema files" do
      Dir.mktmpdir do |dir|
        described_class.start(["spa", person_schema, user_schema, post_schema,
                               "-o", dir])
        html = File.read(File.join(dir, "index.html"))
        expect(html).to include("person")
        expect(html).to include("user")
        expect(html).to include("post")
      end
    end

    it "raises error with no schema files" do
      expect do
        described_class.start(["spa"])
      end.to raise_error(Lutaml::Jsonschema::Error,
                         /No schema files/)
    end
  end

  describe "combine" do
    it "combines schemas to stdout" do
      expect { described_class.start(["combine", person_schema, user_schema]) }
        .to output(/"\$defs"/).to_stdout
    end

    it "combines schemas to file" do
      Dir.mktmpdir do |dir|
        output = File.join(dir, "combined.json")
        described_class.start(["combine", person_schema, user_schema, "-o",
                               output])
        expect(File.exist?(output)).to be true
        json = JSON.parse(File.read(output))
        expect(json).to have_key("$defs")
      end
    end
  end

  describe "validate" do
    it "validates a valid schema" do
      expect { described_class.start(["validate", person_schema]) }
        .to output(/valid/).to_stdout
    end

    it "reports errors for invalid JSON" do
      Dir.mktmpdir do |dir|
        bad = File.join(dir, "bad.json")
        File.write(bad, "not json")
        expect { described_class.start(["validate", bad]) }
          .to raise_error(SystemExit)
      end
    end
  end

  describe "version" do
    it "prints the version" do
      expect { described_class.start(["version"]) }
        .to output(/lutaml-jsonschema #{Lutaml::Jsonschema::VERSION}/o).to_stdout
    end
  end
end
