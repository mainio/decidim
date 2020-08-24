# frozen_string_literal: true

module Decidim
  module Budgets
    # This cell renders information when current user can't create more budgets orders.
    class LimitAnnouncementCell < BaseCell
      alias budget model

      def show
        cell("decidim/announcement", announcement_args) if announce?
      end

      private

      def announce?
        return unless current_settings.votes_enabled?
        return unless current_user
        return if current_workflow.voted?(budget)

        discardable.any? || not_allowed_to_vote?
      end

      def announcement_args
        {
          callout_class: "warning",
          announcement: announcement_message
        }
      end

      def announcement_message
        if discardable.any?
          t(:limit_reached, scope: i18n_scope,
                            links: budgets_link_list(current_workflow.discardable),
                            landing_path: budgets_path)
        else
          t(:cant_vote, scope: i18n_scope, landing_path: budgets_path)
        end
      end

      def discardable
        @discardable ||= if should_discard_to_vote?
                           current_workflow.discardable - [budget]
                         else
                           []
                         end
      end

      def should_discard_to_vote?
        current_workflow.limit_reached? && current_workflow.discardable.any?
      end

      def not_allowed_to_vote?
        !current_workflow.vote_allowed?(budget, false)
      end

      def i18n_scope
        "decidim.budgets.limit_announcement"
      end
    end
  end
end
