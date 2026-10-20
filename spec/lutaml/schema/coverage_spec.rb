# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Schema dialect coverage" do
  def parse(hash)
    described_class = Lutaml::Jsonschema::Schema
    described_class.from_json(Yeptris::JSON.dump(hash))
  end

  def round_trip(hash)
    Yeptris::JSON.load(parse(hash).to_json)
  end

  describe Lutaml::Jsonschema::Dialect do
    it "detects every supported dialect, with or without fragment or http scheme" do
      # rubocop:disable Naming/VariableNumber -- symbols mirror published dialect names
      {
        "http://json-schema.org/draft-04/schema#" => :draft4,
        "https://json-schema.org/draft-04/schema" => :draft4,
        "http://json-schema.org/draft-06/schema#" => :draft6,
        "http://json-schema.org/draft-07/schema#" => :draft7,
        "https://json-schema.org/draft/2019-09/schema" => :draft2019_09,
        "https://json-schema.org/draft/2020-12/schema" => :draft2020_12,
        "https://json-schema.org/draft/2020-12/schema#" => :draft2020_12,
      }.each do |uri, expected|
        expect(described_class.detect(uri)).to eq(expected)
      end
      # rubocop:enable Naming/VariableNumber
    end

    it "returns :unspecified for nil, empty, and unknown URIs" do
      expect(described_class.detect(nil)).to eq(:unspecified)
      expect(described_class.detect("")).to eq(:unspecified)
      expect(described_class.detect("urn:example:not-json-schema")).to eq(:unspecified)
    end
  end

  describe "dialect on a schema" do
    it "reports the schema dialect" do
      schema = parse(
        "$schema" => "https://json-schema.org/draft/2020-12/schema",
        "type" => "object",
      )

      expect(schema.dialect).to eq(:draft2020_12) # rubocop:disable Naming/VariableNumber
    end
  end

  describe "exclusive bounds across drafts" do
    it "keeps draft-04 boolean modifiers verbatim and exposes the effective bound" do
      schema = parse(
        "$schema" => "http://json-schema.org/draft-04/schema#",
        "minimum" => 5,
        "exclusiveMinimum" => true,
      )

      expect(schema.exclusive_minimum).to be(true)
      expect(schema.exclusive_minimum_value).to eq(5)
      expect(round_trip(
               "$schema" => "http://json-schema.org/draft-04/schema#",
               "minimum" => 5,
               "exclusiveMinimum" => true,
             )).to include("exclusiveMinimum" => true, "minimum" => 5)
    end

    it "treats a draft-04 false modifier as non-exclusive" do
      schema = parse(
        "$schema" => "http://json-schema.org/draft-04/schema#",
        "maximum" => 10,
        "exclusiveMaximum" => false,
      )

      expect(schema.exclusive_maximum_value).to be_nil
    end

    it "keeps draft-06+ numeric bounds as the effective bound" do
      schema = parse(
        "$schema" => "http://json-schema.org/draft-07/schema#",
        "exclusiveMinimum" => 2.5,
      )

      expect(schema.exclusive_minimum).to eq(2.5)
      expect(schema.exclusive_minimum_value).to eq(2.5)
      expect(round_trip("exclusiveMinimum" => 2.5)).to include("exclusiveMinimum" => 2.5)
    end
  end

  describe "2019-09 and 2020-12 keywords" do
    it "round-trips the dynamic and recursive ref keywords" do
      hash = {
        "$dynamicAnchor" => "meta",
        "$dynamicRef" => "#meta",
        "$recursiveAnchor" => true,
        "$recursiveRef" => "#",
      }

      expect(round_trip(hash)).to eq(hash)
    end

    it "round-trips dependentRequired and dependentSchemas" do
      hash = {
        "dependentRequired" => { "credit_card" => ["billing_address"] },
        "dependentSchemas" => {
          "billing_address" => { "required" => ["street"] },
        },
      }
      result = round_trip(hash)

      expect(result["dependentRequired"])
        .to eq("credit_card" => ["billing_address"])
      expect(result["dependentSchemas"]["billing_address"])
        .to include("required" => ["street"])
    end

    it "round-trips legacy dependencies verbatim" do
      hash = {
        "dependencies" => {
          "a" => ["b"],
          "c" => { "required" => ["d"] },
        },
      }

      expect(round_trip(hash)).to eq(hash)
    end

    it "round-trips unevaluatedProperties and unevaluatedItems in both shapes" do
      expect(round_trip("unevaluatedProperties" => false))
        .to eq("unevaluatedProperties" => false)
      expect(round_trip("unevaluatedProperties" => { "type" => "string" }))
        .to eq("unevaluatedProperties" => { "type" => "string" })
      expect(round_trip("unevaluatedItems" => true))
        .to eq("unevaluatedItems" => true)
      expect(round_trip("unevaluatedItems" => { "type" => "integer" }))
        .to eq("unevaluatedItems" => { "type" => "integer" })
    end

    it "round-trips propertyNames, contentSchema, minContains, maxContains" do
      hash = {
        "propertyNames" => { "pattern" => "^[a-z]+$" },
        "contentSchema" => { "type" => "object" },
        "contains" => { "type" => "string" },
        "minContains" => 2,
        "maxContains" => 4,
      }
      result = round_trip(hash)

      expect(result["propertyNames"]).to eq("pattern" => "^[a-z]+$")
      expect(result["contentSchema"]).to eq("type" => "object")
      expect(result).to include("minContains" => 2, "maxContains" => 4)
    end
  end

  describe "array items across drafts" do
    it "round-trips 2020-12 prefixItems" do
      hash = {
        "prefixItems" => [{ "type" => "string" }, { "type" => "integer" }],
        "items" => { "type" => "string" },
      }

      expect(round_trip(hash)).to include(
        "prefixItems" => [{ "type" => "string" }, { "type" => "integer" }],
        "items" => { "type" => "string" },
      )
    end

    it "round-trips draft-04 boolean additionalItems" do
      expect(round_trip("items" => { "type" => "string" },
                        "additionalItems" => false))
        .to include("additionalItems" => false)
    end

    # draft-04..07 tuple `items` (array value) needs a collection
    # attribute populated from the `items` key, but lutaml-model's
    # post-parse defaults pass resets any attribute that is not a
    # mapping target — and one key cannot target two attributes
    # without breaking the single-schema form. Tracked in
    # TODO.sota/01; boolean-schema values (items: false) share the
    # same normalization gap.
    it "parses draft-04 tuple items" do
      pending "tuple items need framework support (see TODO.sota/01)"
      schema = parse(
        "$schema" => "http://json-schema.org/draft-04/schema#",
        "items" => [{ "type" => "string" }, { "type" => "integer" }],
      )

      expect(schema.prefix_items.map(&:type)).to eq(%w[string integer])
    end
  end

  describe "child traversal" do
    it "yields schemas inside every new schema-bearing keyword" do
      schema = parse(
        "dependentSchemas" => { "a" => { "type" => "string" } },
        "prefixItems" => [{ "type" => "string" }],
        "additionalItems" => { "type" => "integer" },
        "unevaluatedItems" => { "type" => "boolean" },
        "unevaluatedProperties" => { "type" => "number" },
        "propertyNames" => { "type" => "string" },
        "contentSchema" => { "type" => "object" },
      )

      segments = schema.each_child.map { |_child, segment| segment }

      expect(segments).to include(
        "dependentSchemas/a",
        "prefixItems[0]",
        "additionalItems",
        "unevaluatedItems",
        "unevaluatedProperties",
        "propertyNames",
        "contentSchema",
      )
    end

    it "resolves new keyword segments through child_at" do
      schema = parse(
        "dependentSchemas" => { "a" => { "type" => "string" } },
        "propertyNames" => { "type" => "string" },
      )

      expect(schema.child_at("propertyNames").type).to eq("string")
      expect(schema.child_at("dependentSchemas").first.name).to eq("a")
    end
  end
end
