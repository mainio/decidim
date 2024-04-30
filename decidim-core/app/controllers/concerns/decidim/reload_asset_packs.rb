# frozen_string_literal: true

require "active_support/concern"

module Decidim
  module ReloadAssetPacks
    extend ActiveSupport::Concern

    included do
      before_action :reload_asset_packs
    end

    private

    def reload_asset_packs
      Decidim::Assets::Packer.instance.check_manifest_reload
    end
  end
end
