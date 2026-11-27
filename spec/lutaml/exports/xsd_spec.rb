# frozen_string_literal: true

require "spec_helper"
require "moxml"

RSpec.describe Lutaml::Jsonschema::Exports::Xsd do
  def schema_set_from(hash, name: "demo")
    set = Lutaml::Jsonschema::SchemaSet.new
    set.add(name, Lutaml::Jsonschema::Schema.from_json(Yeptris::JSON.dump(hash)))
    set
  end

  def render(hash)
    described_class.new(schema_set_from(hash)).render
  end

  def parse_xml(xml)
    Moxml.parse(xml)
  end

  def find_element(scope, expression)
    scope.xpath(expression, "xs" => described_class::XS_NS).first
  end

  def attr(element, name)
    element.attribute(name)&.value
  end

  it "emits an xs:schema with the target namespace" do
    doc = parse_xml(render("type" => "object"))
    root = doc.root

    expect(root.name).to eq("schema")
    expect(attr(root, "targetNamespace")).to eq("urn:lutaml:jsonschema")
    expect(root.namespace_prefix).to eq("xs")
    expect(root.namespace_uri).to eq("http://www.w3.org/2001/XMLSchema")
  end

  it "renders object properties with scalar types and optionality" do
    doc = parse_xml(render(
                      "type" => "object",
                      "required" => %w[name],
                      "properties" => {
                        "name" => { "type" => "string" },
                        "age" => { "type" => "integer" },
                      },
                    ))
    root = doc.root

    name = find_element(root, "//xs:element[@name='name']")
    age = find_element(root, "//xs:element[@name='age']")

    expect(attr(name, "type")).to eq("xs:string")
    expect(attr(name, "minOccurs")).to be_nil
    expect(attr(age, "minOccurs")).to eq("0")
  end

  it "renders boolean items without supplying a bogus element type" do
    doc = parse_xml(render(
                      "type" => "object",
                      "properties" => {
                        "tags" => { "type" => "array", "items" => false },
                      },
                    ))
    element = doc.root.xpath("//xs:element", "xs" => described_class::XS_NS)
                     .find { |e| attr(e, "name") == "tags" }

    expect(attr(element, "type")).to be_nil
  end

  it "leaves boolean property schemas untyped" do
    doc = parse_xml(render(
                      "type" => "object",
                      "properties" => { "flag" => true },
                    ))
    element = doc.root.xpath("//xs:element", "xs" => described_class::XS_NS)
                     .find { |e| attr(e, "name") == "flag" }

    expect(attr(element, "type")).to be_nil
  end

  it "renders arrays as unbounded repeated items" do
    doc = parse_xml(render(
                      "type" => "object",
                      "properties" => { "tags" => { "type" => "array",
                                                    "items" => { "type" => "string" } } },
                    ))

    tags = find_element(doc.root, "//xs:element[@name='tags']")
    expect(attr(tags, "maxOccurs")).to eq("unbounded")
    expect(attr(tags, "type")).to eq("xs:string")
  end

  it "renders definitions as named types and refs as tns references" do
    output = render(
      "definitions" => {
        "address" => { "type" => "object",
                       "properties" => { "city" => { "type" => "string" } } },
      },
      "type" => "object",
      "properties" => { "address" => { "$ref" => "#/definitions/address" } },
    )
    doc = parse_xml(output)

    type = find_element(doc.root, "//xs:complexType[@name='address']")
    member = find_element(doc.root, "//xs:element[@name='address']")
    expect(type).not_to be_nil
    expect(attr(member, "type")).to eq("tns:address")
  end

  it "renders enums as simpleType restrictions" do
    doc = parse_xml(render(
                      "type" => "object",
                      "properties" => { "status" => { "enum" => %w[a b] } },
                    ))

    values = doc.root.xpath("//xs:enumeration", "xs" => described_class::XS_NS)
                   .map { |node| attr(node, "value") }
    expect(values).to contain_exactly("a", "b")
  end

  it "exports through the CLI with --format xsd" do
    expect do
      Lutaml::Jsonschema::Cli.start(
        ["export", fixture_path("person.json"), "--format", "xsd"],
      )
    end.to output(/xs:schema/).to_stdout
  end
end
