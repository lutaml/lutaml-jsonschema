# frozen_string_literal: true

module Lutaml
  module Jsonschema
    module Spa
      class SpaDefinition < Base
        attribute :name, :string
        attribute :title, :string
        attribute :description, :string
        attribute :type, :string
        attribute :format, :string
        attribute :enum, :string, collection: true
        attribute :const_value, :string
        attribute :pattern, :string
        attribute :default, :string
        attribute :min_length, :integer
        attribute :max_length, :integer
        attribute :minimum, :float
        attribute :maximum, :float
        attribute :exclusive_minimum, :float
        attribute :exclusive_maximum, :float
        attribute :multiple_of, :float
        attribute :content_type, :string
        attribute :content_encoding, :string
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
          map "format", to: :format
          map "enum", to: :enum
          map "const", to: :const_value
          map "pattern", to: :pattern
          map "default", to: :default
          map "minLength", to: :min_length
          map "maxLength", to: :max_length
          map "minimum", to: :minimum
          map "maximum", to: :maximum
          map "exclusiveMinimum", to: :exclusive_minimum
          map "exclusiveMaximum", to: :exclusive_maximum
          map "multipleOf", to: :multiple_of
          map "contentMediaType", to: :content_type
          map "contentEncoding", to: :content_encoding
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
