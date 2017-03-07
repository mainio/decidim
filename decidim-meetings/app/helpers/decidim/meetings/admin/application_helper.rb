# frozen_string_literal: true
module Decidim
  module Meetings
    module Admin
      # Custom helpers, scoped to the meetings admin engine.
      #
      module ApplicationHelper
        include Decidim::Meetings::MapHelper
      end
    end
  end
end
