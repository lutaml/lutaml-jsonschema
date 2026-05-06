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

        json do
          map "name", to: :name
          map "title", to: :title
          map "description", to: :description
          map "type", to: :type
          map "properties", to: :properties
          map "required", to: :required
          map "examples", to: :examples
        end
      end
    end
  end
end
