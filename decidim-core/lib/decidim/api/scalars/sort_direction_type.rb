# frozen_string_literal: true

module Decidim
  module Core
    class SortDirectionType < Decidim::Api::Types::BaseScalar
      description "The sort direction for sort inputs, valid values are ASC or DESC"

      class << self
        def coerce_input(value, _ctx)
          value =
            case value
            when String
              value
            when GraphQL::Language::Nodes::Enum
              value.name
            end

          normalized = value.upcase
          raise GraphQL::CoercionError, "Invalid order value, only ASC or DESC are valids (received #{value.inspect})" unless valid_order?(normalized)

          normalized
        end

        private

        def valid_order?(value)
          %w(ASC DESC).include?(value)
        end
      end
    end
  end
end
