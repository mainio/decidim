# frozen_string_literal: true

require "active_support/core_ext/hash/keys"
require "json"
require "decidim/webpacker"
require "open3"

module Decidim
  module Assets
    class Packer
      def self.instance(*, **)
        @instance ||= new(*, **)
      end

      def self.run
        instance.run
      end

      attr_reader :root

      def initialize(root = determine_root, watch: false, dev_server: false)
        @root = root
        @watch = watch
        @dev_server = dev_server
      end

      def run
        load_asset_configurations

        # Write runtime configuration for Tailwind
        # This method is called here because in Decidim CSS compilation is done
        # via Node.
        Decidim::Assets::Tailwind.write_runtime_configuration

        paths = Decidim::Webpacker.configuration.additional_paths
        imports = Decidim::Webpacker.configuration.stylesheet_imports
        entrypoints = Decidim::Webpacker.configuration.entrypoints

        env = {
          "NODE_ENV" => ENV.fetch("RAILS_ENV", "development").start_with?("production") ? "production" : "development",
          "NODE_PATH" => ENV.fetch("NODE_PATH", "#{root}/node_modules")
        }
        config = {
          root:,
          watch:,
          devServer: dev_server && env["NODE_ENV"] == "development",
          outdir:,
          publicPath: public_path,
          entryPoints: entrypoints,
          additionalPaths: paths,
          stylesheetImports: imports
        }
        Open3.popen3(env, "/usr/bin/env", "node", build_cmd, chdir: root) do |stdin, stdout, stderr|
          stdout.sync = true
          stderr.sync = true

          stdin.write(config.to_json)
          stdin.close

          $stdout.sync = true
          begin
            while (line = stdout.gets)
              $stdout.puts line
            end
            $stdout.puts ""
            while (line = stderr.gets)
              $stdout.puts line
            end
          rescue Interrupt
            $stdout.puts ""
          end
        end
      end

      def manifest
        @manifest ||= begin
          raise "Assets have not been built yet at #{outdir}" unless File.exist?(manifest_path)

          JSON.load_file!(manifest_path)
        end
      end

      # Checks that the loaded manifest is up-to-date during development. If the
      # manifest file has changed, clears the old manifest which causes it to be
      # reloaded when it is requested the next time.
      #
      # This needs to be called once at the beginning of the request.
      def check_manifest_reload
        unless File.exist?(manifest_path)
          @manifest = nil
          @manifest_digest = nil
          return
        end

        current_digest = Digest::MD5.file(manifest_path).hexdigest
        return if @manifest_digest == current_digest

        @manifest = nil
        @manifest_digest = current_digest
      end

      def path_to(name)
        return unless manifest[name]

        "#{public_asset_path}/#{manifest[name]}"
      end

      private

      attr_reader :watch, :dev_server

      def determine_root
        # Note the packer is not run under the Rails environment but it is used
        # also under the Rails environment for determining the paths to the
        # assets.
        if defined?(Rails)
          Rails.root
        else
          Bundler.root
        end
      end

      # Returns the relative path to the assets directory.
      def public_asset_path
        @public_asset_path ||= outdir.sub(/^#{Rails.public_path}/, "")
      end

      def manifest_path
        @manifest_path ||= "#{outdir}/manifest.json"
      end

      def load_asset_configurations
        # Decidim gem assets
        decidim_gems = Bundler.load.specs.select { |spec| spec.name =~ /^decidim-/ }
        decidim_gems.each do |gem|
          asset_config_path = File.join(gem.full_gem_path, "config/assets.rb")
          next unless File.exist?(asset_config_path)

          load asset_config_path
        end

        # Application assets
        asset_config_path = File.join(root, "config/assets.rb")
        load asset_config_path if File.exist?(asset_config_path)
      end

      def outdir
        @outdir ||= "#{root}/public/#{packs_dir}"
      end

      def public_path
        @public_path ||= ENV.fetch("ASSETS_PUBLIC_PATH", "/#{packs_dir}")
      end

      def packs_dir
        @packs_dir ||= "build"
      end

      def build_cmd
        @build_cmd ||= File.join(bin_path, "decidimpack-build")
      end

      def bin_path
        @bin_path ||= File.join(core_gem_path, "exe")
      end

      def core_gem_path
        @core_gem_path ||= Gem.loaded_specs["decidim-core"].full_gem_path
      end
    end
  end
end
