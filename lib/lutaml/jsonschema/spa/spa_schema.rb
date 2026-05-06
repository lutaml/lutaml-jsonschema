# frozen_string_literal: true

module Lutaml
  module Jsonschema
    module Spa
      class SpaSchema < Base
        attribute :name, :string
        attribute :title, :string
        attribute :description, :string
        attribute :type, :string
        attribute :properties, SpaProperty, collection: true, initialize_empty: true
        attribute :definitions, SpaDefinition, collection: true, initialize_empty: true
        attribute :required, :string, collection: true
        attribute :examples, :string, collection: true
        attribute :source_json, :string, default: -> { "" }

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
        end
      end
    end
  end
end
