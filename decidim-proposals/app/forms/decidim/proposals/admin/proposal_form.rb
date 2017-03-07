# frozen_string_literal: true
module Decidim
  module Proposals
    module Admin
      # A form object to be used when admin users want to create a proposal.
      class ProposalForm < Decidim::Form
        mimic :proposal

        attribute :title, String
        attribute :body, String
        attribute :address, String
        attribute :latitude, Float
        attribute :longitude, Float
        attribute :decidim_category_id, Integer
        attribute :decidim_scope_id, Integer

        validates :title, :body, presence: true
        validates :address, geocoding: true, if: -> { current_feature.settings.geocoding_enabled? }
        validates :category, presence: true, if: ->(form) { form.decidim_scope_id.present? }
        validates :scope, presence: true, if: ->(form) { form.decidim_scope_id.present? }

        delegate :categories, to: :current_feature, prefix: false

        def organization_scopes
          current_organization.scopes
        end

        def process_scope
          current_feature.participatory_process.scope
        end

        alias feature current_feature

        # Finds the Category from the decidim_category_id.
        #
        # Returns a Decidim::Category
        def category
          @category ||= categories.where(id: decidim_category_id).first
        end

        # Finds the Scope from the decidim_scope_id.
        #
        # Returns a Decidim::Scope
        def scope
          @scope ||= process_scope || organization_scopes.where(id: decidim_scope_id).first
        end
      end
    end
  end
end
