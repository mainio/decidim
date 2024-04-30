# frozen_string_literal: true

module Decidim
  # Provides the methods for the view to load the packed assets.
  module AssetPackHelper
    def asset_packer
      Decidim::Assets::Packer.instance
    end

    def asset_pack_path(name, **options)
      path_to_asset(asset_packer.path_to(name), options)
    end

    def asset_pack_url(name, **options)
      url_to_asset(asset_packer.path_to(name), options)
    end

    def image_pack_path(name, **options)
      path_to_asset(asset_packer.path_to(name), options)
    end

    def image_pack_url(name, **options)
      url_to_asset(asset_packer.path_to(name), options)
    end

    def image_pack_tag(name, **options)
      image_tag(path_to_asset(asset_packer.path_to(name)), options)
    end

    def javascript_pack_tag(*, defer: true, **options)
      append_javascript_pack_tag(*, defer:)
      non_deferred = sources_from_manifest_entrypoints(javascript_pack_tags[:non_deferred], type: :javascript)
      deferred = sources_from_manifest_entrypoints(javascript_pack_tags[:deferred], type: :javascript) - non_deferred

      @javascript_pack_tags ||= { deferred: [], non_deferred: [] }

      capture do
        concat javascript_include_tag(*deferred, **options.tap { |o| o[:defer] = true })
        concat "\n" if non_deferred.any? && deferred.any?
        concat javascript_include_tag(*non_deferred, **options.tap { |o| o[:defer] = false })
      end
    end

    def stylesheet_pack_tag(*, **)
      append_stylesheet_pack_tag(*)
      packs = sources_from_manifest_entrypoints(stylesheet_pack_tags, type: :stylesheet)

      @stylesheet_pack_tags ||= []

      stylesheet_link_tag(*packs, **)
    end

    def append_stylesheet_pack_tag(*)
      stylesheet_pack_tags.push(*).uniq!

      nil
    end

    def append_javascript_pack_tag(*, defer: true)
      javascript_pack_tags[defer ? :deferred : :non_deferred].push(*).uniq!

      nil
    end

    def prepend_javascript_pack_tag(*, defer: true)
      javascript_pack_tags[defer ? :deferred : :non_deferred].unshift(*)

      nil
    end

    private

    def javascript_pack_tags
      @javascript_pack_tags ||= { deferred: [], non_deferred: [] }
    end

    def stylesheet_pack_tags
      @stylesheet_pack_tags ||= []
    end

    def sources_from_manifest_entrypoints(names, type:)
      ext =
        case type
        when :javascript
          "js"
        when :stylesheet
          "css"
        else
          type.to_s
        end
      names.map { |name| asset_packer.path_to("#{name}.#{ext}") }.flatten.compact.uniq
    end
  end
end
