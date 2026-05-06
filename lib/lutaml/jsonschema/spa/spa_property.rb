# frozen_string_literal: true

module Lutaml
  module Jsonschema
    module Spa
      class SpaProperty < Base
        attribute :name, :string
        attribute :title, :string
        attribute :description, :string
        attribute :type, :string
        attribute :format, :string
        attribute :required, :boolean
        attribute :default, :string
        attribute :pattern, :string
        attribute :enum, :string, collection: true
        attribute :ref, :string
        attribute :min_length, :integer
        attribute :max_length, :integer
        attribute :minimum, :float
        attribute :maximum, :float
        attribute :items_type, :string
        attribute :deprecated, :boolean
        attribute :read_only, :boolean
        attribute :write_only, :boolean
        attribute :examples, :string, collection: true
        attribute :min_items, :integer
        attribute :max_items, :integer
        attribute :unique_items, :boolean
        attribute :multiple_of, :float
        attribute :const_value, :string

        json do
          map "name", to: :name
          map "title", to: :title
          map "description", to: :description
          map "type", to: :type
          map "format", to: :format
          map "required", to: :required
          map "default", to: :default
          map "pattern", to: :pattern
          map "enum", to: :enum
          map "$ref", to: :ref
          map "minLength", to: :min_length
          map "maxLength", to: :max_length
          map "minimum", to: :minimum
          map "maximum", to: :maximum
          map "itemsType", to: :items_type
          map "deprecated", to: :deprecated
          map "readOnly", to: :read_only
          map "writeOnly", to: :write_only
          map "examples", to: :examples
          map "minItems", to: :min_items
          map "maxItems", to: :max_items
          map "uniqueItems", to: :unique_items
          map "multipleOf", to: :multiple_of
          map "const", to: :const_value
        end
      end
    end
  end
end
