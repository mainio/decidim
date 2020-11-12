# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Conferences
    module AdminLog
      describe RegistrationTypePresenter, type: :helper do
        include_examples "present admin log entry" do
          let(:conference) { create(:conference, organization: organization) }
          let(:admin_log_resource) { create(:registration_type, conference: conference) }
          let(:action) { "delete" }
        end
      end
    end
  end
end