# frozen_string_literal: true

module Decidim
  module Api
    module Types
      class BaseField < GraphQL::Schema::Field
        argument_class Types::BaseArgument

        # Override graphql-ruby 1.13's new default complexity for connection fields
        # See: https://github.com/rmosolgo/graphql-ruby/pull/3609
        def calculate_complexity(query:, nodes:, child_complexity:)
          defined_complexity = complexity
          case defined_complexity
          when Proc
            arguments = query.arguments_for(nodes.first, self)
            defined_complexity.call(query.context, arguments.keyword_arguments, child_complexity)
          when Numeric
            defined_complexity + child_complexity
          else
            raise("Invalid complexity: #{defined_complexity.inspect} on #{path} (#{inspect})")
          end
        end
      end
    end
  end
end
