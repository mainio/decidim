# frozen_string_literal: true

module Decidim
  module Budgets
    # The data store for a Order in the Decidim::Budgets component. It is unique for each
    # user and component and contains a collection of projects
    class Order < Budgets::ApplicationRecord
      include Decidim::DataPortability
      include Decidim::NewsletterParticipant

      belongs_to :user, class_name: "Decidim::User", foreign_key: "decidim_user_id"
      belongs_to :budget, foreign_key: "decidim_budgets_budget_id", class_name: "Decidim::Budgets::Budget", inverse_of: :orders
      has_one :component, through: :budget, foreign_key: "decidim_component_id", class_name: "Decidim::Component"
      has_many :line_items, class_name: "Decidim::Budgets::LineItem", foreign_key: "decidim_order_id", dependent: :destroy
      has_many :projects, through: :line_items, class_name: "Decidim::Budgets::Project", foreign_key: "decidim_project_id"

      validates :user, uniqueness: { scope: :budget }
      validates :budget, presence: true
      validate :user_belongs_to_organization

      with_options unless: :projects_rule? do
        validates :total_budget, numericality: {
          greater_than_or_equal_to: :minimum_budget
        }, if: :checked_out?

        validates :total_budget, numericality: {
          less_than_or_equal_to: :maximum_budget
        }
      end
      with_options if: :projects_rule? do
        validates :total_projects, numericality: {
          greater_than_or_equal_to: :minimum_projects
        }, if: :checked_out?

        validates :total_projects, numericality: {
          less_than_or_equal_to: :maximum_projects
        }
      end

      validate :reach_minimum_projects, if: :checked_out?

      scope :finished, -> { where.not(checked_out_at: nil) }
      scope :pending, -> { where(checked_out_at: nil) }

      # Public: Returns the available budget allocation the user is able to
      # allocate to this order or the maximum amount of projects to be selected
      # in case the project selection voting is enabled.
      def available_allocation
        return maximum_projects if projects_rule?

        maximum_budget
      end

      # Public: Returns the numeric amount the given project should allocate
      # from the total available allocation when it is added to the order. The
      # allocation is normally the project's budget but for project selection
      # voting, the allocation is one.
      def allocation_for(project)
        return 1 if projects_rule?

        project.budget
      end

      # Public: Returns the sum of project budgets
      def total_budget
        projects.to_a.sum(&:budget_amount)
      end

      # Public: Returns the amount of projects selected for the vote
      def total_projects
        projects.count
      end

      # Public: For budget voting returns the total budget and for project
      # selection voting, returns the amount of selected projects.
      def total
        return total_projects if projects_rule?

        total_budget
      end

      # Public: Returns true if the order has been checked out
      def checked_out?
        checked_out_at.present?
      end

      # Public: Check if the order total budget is enough to checkout
      def can_checkout?
        if minimum_projects_rule? || projects_rule?
          projects.count >= minimum_projects
        else
          total_budget.to_f >= minimum_budget
        end
      end

      # Public: Returns the order budget percent from the settings total budget
      # or the progress for selected projects if the selected project rule is
      # enabled
      def budget_percent
        return (projects.count.to_f / maximum_projects) * 100 if projects_rule?

        (total_budget.to_f / budget.total_budget.to_f) * 100
      end

      # Public: Returns the required minimum budget to checkout
      def minimum_budget
        return 0 unless budget
        return 0 if minimum_projects_rule? || projects_rule?

        budget.total_budget.to_f * (budget.settings.vote_threshold_percent.to_f / 100)
      end

      # Public: Returns the required maximum budget to checkout
      def maximum_budget
        return 0 unless budget

        budget.total_budget.to_f
      end

      # Public: Returns if it is required a minimum projects limit to checkout
      def minimum_projects_rule?
        return unless budget

        budget.settings.vote_rule_minimum_budget_projects_enabled
      end

      # Public: Returns true if the project voting rule is enabled
      def projects_rule?
        return unless budget

        budget.settings.vote_rule_selected_projects_enabled
      end

      # Public: Returns the required minimum projects to checkout
      def minimum_projects
        return 0 unless budget

        if minimum_projects_rule?
          budget.settings.vote_minimum_budget_projects_number
        elsif projects_rule?
          budget.settings.vote_selected_projects_minimum
        else
          0
        end
      end

      # Public: Returns the required minimum projects to checkout
      def maximum_projects
        return nil unless budget

        if projects_rule?
          budget.settings.vote_selected_projects_maximum
        else
          0
        end
      end

      def self.user_collection(user)
        where(decidim_user_id: user.id)
      end

      def self.export_serializer
        Decidim::Budgets::DataPortabilityBudgetsOrderSerializer
      end

      def self.newsletter_participant_ids(component)
        Decidim::Budgets::Order.finished
                               .joins(budget: [:component])
                               .where(budget: {
                                        decidim_components: { id: component.id }
                                      })
                               .pluck(:decidim_user_id)
                               .flatten.compact.uniq
      end

      private

      def user_belongs_to_organization
        organization = budget.try(:component).try(:organization)

        return if !user || !organization

        errors.add(:user, :invalid) unless user.organization == organization
      end

      def reach_minimum_projects
        return if !minimum_projects_rule? && !projects_rule?

        errors.add(:projects, :invalid) if minimum_projects > projects.count
      end
    end
  end
end
