# frozen_string_literal: true

module Lutaml
  module Jsonschema
    class PropertyEntry < Base
      attribute :name, :string
      attribute :schema, Schema

      json do
        map "name", to: :name
        map "schema", to: :schema
      end
    end
  end
end
