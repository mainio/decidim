# frozen_string_literal: true

module Decidim
  module Core
    class ComponentInputSort < BaseInputSort
      include HasLocalizedInputSort

      graphql_name "ComponentSort"
      description "A type used for sorting any component parent objects"

      argument :id, Decidim::Core::SortDirectionType, "Sort by ID, valid values are ASC or DESC", required: false
      argument :name,
               type: Decidim::Core::SortDirectionType,
               description: "Sort by name of the component, alphabetically, valid values are ASC or DESC",
               required: false,
               as: :name,
               prepare: :prepared_name
      argument :type,
               type: Decidim::Core::SortDirectionType,
               description: "Sort by type of component, alphabetically, valid values are ASC or DESC",
               required: false,
               as: :manifest_name
      argument :weight, Decidim::Core::SortDirectionType, "Sort by weight (order in the website), valid values are ASC or DESC", required: false

      def self.prepared_name(direction, ctx)
        lambda do |locale|
          locale = ctx[:current_organization].default_locale if locale.blank?
          field = Arel::Nodes::InfixOperation.new("->", Arel.sql("name"), Arel::Nodes.build_quoted(locale))
          # Arel::Nodes::InfixOperation.new("", field, Arel.sql(direction.upcase))
          order =
            case direction.upcase
            when "DESC"
              Arel::Nodes::Descending
            else
              Arel::Nodes::Ascending
            end
          order.new(field)
        end
      end
    end
  end
end
