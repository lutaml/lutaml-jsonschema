# frozen_string_literal: true

require_relative "jsonschema/version"
require "lutaml/model"

module Lutaml
  module Jsonschema
    class Error < StandardError; end
  end
end

require_relative "jsonschema/base"
require_relative "jsonschema/link"
require_relative "jsonschema/property_entry"
require_relative "jsonschema/schema"
require_relative "jsonschema/reference_resolver"
require_relative "jsonschema/schema_set"
require_relative "jsonschema/combiner"
require_relative "jsonschema/spa/metadata"
require_relative "jsonschema/spa/spa_property"
require_relative "jsonschema/spa/spa_definition"
require_relative "jsonschema/spa/spa_schema"
require_relative "jsonschema/spa/spa_search_entry"
require_relative "jsonschema/spa/spa_builder"
require_relative "jsonschema/spa/spa_document"
require_relative "jsonschema/spa/output_strategy"
require_relative "jsonschema/spa/vue_inlined_strategy"
require_relative "jsonschema/spa/generator"
require_relative "jsonschema/configuration"
