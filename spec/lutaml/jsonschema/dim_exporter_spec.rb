# frozen_string_literal: true

require "spec_helper"
require "json"
require "lutaml/jsonschema"

RSpec.describe Lutaml::Jsonschema::DimExporter do
  let(:schema) { Lutaml::Jsonschema::Schema.from_json(source) }
  let(:document) { described_class.new(schema).export }
  let(:graph) { document["graph"] }

  let(:source) do
    <<~JSON
      {
        "$id": "https://example.com/person",
        "type": "object",
        "required": ["name", "address"],
        "properties": {
          "name": { "type": "string" },
          "address": { "$ref": "#/$defs/Address" },
          "tags": { "type": "array" }
        },
        "$defs": {
          "Address": {
            "type": "object",
            "properties": {
              "street": { "type": "string" },
              "lines": { "$ref": "#/definitions/Line" }
            }
          },
          "Line": { "type": "string" },
          "Status": {
            "allOf": [{ "$ref": "#/$defs/Line" }],
            "oneOf": [{ "$ref": "#/$defs/Address" }],
            "anyOf": [{ "$ref": "https://external.example/other" }]
          }
        }
      }
    JSON
  end

  it "emits a DIM 0.1 document in the json-schema notation" do
    expect(document.values_at("dim", "notation")).to eq(["0.1", "json-schema"])
  end

  it "steers the engine with layered layout flowing down" do
    expect(graph["layoutOptions"]).to include(
      "elk.algorithm" => "layered",
      "elk.direction" => "DOWN",
    )
  end

  it "draws the root schema and one node per named definition" do
    expect(graph["children"].map { |n| n["id"] }).to contain_exactly(
      "root", "definition-Address", "definition-Line", "definition-Status"
    )
  end

  it "titles the root node from the schema's id-less title or fallback" do
    root = graph["children"].find { |n| n["id"] == "root" }
    title = root["content"].find { |c| c["role"] == "title" }

    expect(title["text"]).to eq("root")
  end

  it "marks required properties and types the rest" do
    root = graph["children"].find { |n| n["id"] == "root" }
    members = root["content"].select { |c| c["role"] == "member" }

    expect(members.map { |c| c["text"] }).to contain_exactly(
      "name!: string", "address!: Address", "tags: array"
    )
  end

  it "resolves the legacy definitions form in member text" do
    address = graph["children"].find { |n| n["id"] == "definition-Address" }
    members = address["content"].select { |c| c["role"] == "member" }

    expect(members.map { |c| c["text"] }).to contain_exactly(
      "street: string", "lines: Line"
    )
  end

  it "references in-graph member definitions only" do
    references = graph["edges"].select { |e| e["style"] == "reference" }

    expect(references.map { |e| e["targets"] }.flatten)
      .to contain_exactly("definition-Address", "definition-Line")
  end

  it "maps allOf, oneOf and anyOf to their DIM styles" do
    styles = graph["edges"].select { |e| e["id"].start_with?("compose-") }

    expect(styles.map { |e| e.values_at("id", "style") }).to contain_exactly(
      ["compose-all_of-definition-Status-0", "generalization"],
      ["compose-one_of-definition-Status-0", "composition"],
    )
  end

  it "never draws an edge to an external document" do
    expect(graph["edges"].flat_map { |e| e["targets"] })
      .to all(match(/\A(?:definition-|root\z)/))
  end

  it "serializes to JSON that parses back" do
    expect(JSON.parse(described_class.new(schema).export_json))
      .to eq(document)
  end

  context "with a bare scalar schema and no definitions" do
    let(:source) do
      <<~JSON
        { "type": "string", "pattern": "^a" }
      JSON
    end

    it "emits an empty graph" do
      expect(graph.values_at("children", "edges")).to eq([[], []])
    end
  end
end
