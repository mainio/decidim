# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ParticipatoryProcesses
    module AdminLog
      describe AdminLog::ParticipatoryProcessUserRolePresenter, type: :helper do
        include_examples "present admin log entry" do
          let(:admin_log_resource) { create(:participatory_process_user_role, user: user) }
          let(:action) { "delete" }
        end
      end
    end
  end
end
