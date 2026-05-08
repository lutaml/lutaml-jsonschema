# frozen_string_literal: true

module Lutaml
  module Jsonschema
    module Spa
      class SpaDefinition < Base
        attribute :name, :string
        attribute :title, :string
        attribute :description, :string
        attribute :type, :string
        attribute :properties, SpaProperty, collection: true,
                                            initialize_empty: true
        attribute :required, :string, collection: true
        attribute :examples, :string, collection: true
        attribute :min_properties, :integer
        attribute :max_properties, :integer
        attribute :additional_properties, :boolean
        attribute :has_all_of, :boolean
        attribute :has_any_of, :boolean
        attribute :has_one_of, :boolean

        json do
          map "name", to: :name
          map "title", to: :title
          map "description", to: :description
          map "type", to: :type
          map "properties", to: :properties
          map "required", to: :required
          map "examples", to: :examples
          map "minProperties", to: :min_properties
          map "maxProperties", to: :max_properties
          map "additionalProperties", to: :additional_properties
          map "hasAllOf", to: :has_all_of
          map "hasAnyOf", to: :has_any_of
          map "hasOneOf", to: :has_one_of
        end
      end
    end
  end
end
