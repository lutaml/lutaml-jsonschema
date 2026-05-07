# frozen_string_literal: true

module Lutaml
  module Jsonschema
    module Spa
      class SpaSchema < Base
        attribute :name, :string
        attribute :title, :string
        attribute :description, :string
        attribute :type, :string
        attribute :properties, SpaProperty, collection: true,
                                            initialize_empty: true
        attribute :definitions, SpaDefinition, collection: true,
                                               initialize_empty: true
        attribute :required, :string, collection: true
        attribute :examples, :string, collection: true
        attribute :source_json, :string, default: -> { "" }
        attribute :dollar_schema, :string
        attribute :dollar_id, :string
        attribute :additional_properties, :boolean
        attribute :min_properties, :integer
        attribute :max_properties, :integer
        attribute :has_all_of, :boolean
        attribute :has_any_of, :boolean
        attribute :has_one_of, :boolean

        json do
          map "name", to: :name
          map "title", to: :title
          map "description", to: :description
          map "type", to: :type
          map "properties", to: :properties
          map "definitions", to: :definitions
          map "required", to: :required
          map "examples", to: :examples
          map "sourceJson", to: :source_json
          map "$schema", to: :dollar_schema
          map "$id", to: :dollar_id
          map "additionalProperties", to: :additional_properties
          map "minProperties", to: :min_properties
          map "maxProperties", to: :max_properties
          map "hasAllOf", to: :has_all_of
          map "hasAnyOf", to: :has_any_of
          map "hasOneOf", to: :has_one_of
        end
      end
    end
  end
end
