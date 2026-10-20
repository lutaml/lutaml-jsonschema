# frozen_string_literal: true

require "spec_helper"

RSpec.describe Lutaml::Jsonschema::Exports::Adoc do
  def schema_set_from(hash, name = "demo")
    set = Lutaml::Jsonschema::SchemaSet.new
    set.add(name, Lutaml::Jsonschema::Schema.from_json(Yeptris::JSON.dump(hash)))
    set
  end

  def render(hash, name = "demo")
    described_class.new(schema_set_from(hash, name)).render
  end

  it "renders a document title and a section per schema" do
    output = render("title" => "Pet", "type" => "object")

    expect(output).to start_with("= Pet")
    expect(output).to include("== Pet")
  end

  it "renders a properties table with required flags and constraints" do
    output = render(
      "title" => "Pet",
      "type" => "object",
      "required" => ["name"],
      "properties" => {
        "name" => { "type" => "string", "description" => "Pet name",
                    "minLength" => 1 },
        "age" => { "type" => "integer", "minimum" => 0 },
      },
    )

    expect(output).to include("|`name` |string |Yes |Pet name; Min length: 1")
    expect(output).to include("|`age` |integer |No |Minimum: 0")
  end

  it "links $ref properties to definition anchors" do
    output = render(
      "title" => "Pet",
      "type" => "object",
      "definitions" => {
        "Tag" => {
          "title" => "Tag",
          "type" => "object",
          "properties" => { "id" => { "type" => "string" } },
        },
      },
      "properties" => { "tag" => { "$ref" => "#/definitions/Tag" } },
    )

    expect(output).to include("[#def-Tag]")
    expect(output).to include("=== Tag")
    expect(output).to include("<<def-Tag,Tag>>")
  end

  it "renders tuple and closed-array types" do
    output = render(
      "title" => "Pair",
      "type" => "array",
      "prefixItems" => [{ "type" => "string" }, { "type" => "integer" }],
      "items" => false,
    )

    expect(output).to include("Type: [string, integer]")
  end

  it "renders an open tuple tail type" do
    output = render(
      "title" => "Row",
      "type" => "array",
      "items" => [{ "type" => "string" }],
      "additionalItems" => { "type" => "integer" },
    )

    expect(output).to include("Type: [string, integer]")
  end

  it "renders boolean definitions as prose" do
    output = render(
      "title" => "Flags",
      "type" => "object",
      "definitions" => { "never" => false, "anything" => true },
    )

    expect(output).to include("=== never")
    expect(output).to include("No value allowed.")
    expect(output).to include("=== anything")
    expect(output).to include("Any value.")
  end

  it "escapes table cell pipes" do
    output = render(
      "title" => "Pet",
      "type" => "object",
      "properties" => {
        "name" => { "type" => "string", "description" => "a | b" },
      },
    )

    expect(output).to include("a \\| b")
  end
end
