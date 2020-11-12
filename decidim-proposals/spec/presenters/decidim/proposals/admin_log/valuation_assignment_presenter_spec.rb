# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Proposals
    module AdminLog
      describe ValuationAssignmentPresenter, type: :helper do
        include_examples "present admin log entry" do
          let(:participatory_space) { create(:participatory_process, organization: organization) }
          let(:component) { create(:proposal_component, participatory_space: participatory_space) }
          let(:proposal) { create(:proposal, component: component) }
          let(:admin_log_resource) { create(:valuation_assignment, proposal: proposal) }
          let(:action) { "delete" }
        end
      end
    end
  end
end
