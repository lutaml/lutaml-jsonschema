# frozen_string_literal: true

require "lutaml/jsonschema"

RSpec.describe Lutaml::Jsonschema::Spa::SpaDocument do
  let(:fixtures_dir) { File.join(__dir__, "..", "fixtures") }
  let(:schema_set) do
    Lutaml::Jsonschema::SchemaSet.load_from_files(
      File.join(fixtures_dir, "person.json")
    )
  end

  describe ".from_schema_set" do
    subject(:doc) { described_class.from_schema_set(schema_set) }

    it "creates a SpaDocument with metadata" do
      expect(doc.metadata).not_to be_nil
    end

    it "creates SpaSchema entries for each schema" do
      expect(doc.schemas.length).to eq(1)
      expect(doc.schemas.first.name).to eq("person")
      expect(doc.schemas.first.title).to eq("Person")
    end

    it "maps property entries to SpaProperty" do
      schema = doc.schemas.first
      expect(schema.properties.length).to eq(6)
      first_name = schema.properties.find { |p| p.name == "firstName" }
      expect(first_name.type).to eq("string")
      expect(first_name.required).to eq(true)
      expect(first_name.description).to eq("The person's first name.")
    end

    it "marks properties as required" do
      schema = doc.schemas.first
      last_name = schema.properties.find { |p| p.name == "lastName" }
      expect(last_name.required).to eq(true)
      age = schema.properties.find { |p| p.name == "age" }
      expect(age.required).to eq(false)
    end

    it "maps definition entries" do
      schema = doc.schemas.first
      expect(schema.definitions.length).to eq(1)
      expect(schema.definitions.first.name).to eq("address")
    end

    it "creates search index entries" do
      expect(doc.search_index.length).to be > 0
      schema_entry = doc.search_index.find { |e| e.type == "schema" }
      expect(schema_entry.name).to eq("person")
    end
  end

  describe "#to_json (serialization)" do
    it "produces valid JSON" do
      doc = described_class.from_schema_set(schema_set)
      json = doc.to_json
      parsed = JSON.parse(json)

      expect(parsed).to have_key("metadata")
      expect(parsed).to have_key("schemas")
      expect(parsed).to have_key("searchIndex")
      expect(parsed["schemas"]).to be_a(Array)
      expect(parsed["schemas"].first["name"]).to eq("person")
    end

    it "round-trips through JSON" do
      doc = described_class.from_schema_set(schema_set)
      json = doc.to_json
      reparsed = described_class.from_json(json)

      expect(reparsed.metadata).not_to be_nil
      expect(reparsed.schemas.length).to eq(doc.schemas.length)
      expect(reparsed.schemas.first.name).to eq("person")
    end
  end
end

RSpec.describe Lutaml::Jsonschema::Spa::SpaProperty do
  it "serializes to JSON with expected keys" do
    prop = described_class.new(
      name: "id",
      type: "string",
      format: "uuid",
      required: true
    )
    json = prop.to_json
    parsed = JSON.parse(json)

    expect(parsed["name"]).to eq("id")
    expect(parsed["type"]).to eq("string")
    expect(parsed["format"]).to eq("uuid")
    expect(parsed["required"]).to eq(true)
  end
end
