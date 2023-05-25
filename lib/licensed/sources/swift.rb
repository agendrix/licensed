# frozen_string_literal: true
require "json"
require "pathname"
require "uri"

module Licensed
  module Sources
    class Swift < Source
      def initialize(configuration)
        super
        return unless Licensed::Shell.tool_available?("xcodebuild")
        set_derived_data_path
      end

      def enabled?
        return unless @derived_data_path
        File.exist?(package_resolved_file_path)
      end

      def enumerate_dependencies
        pins.map { |pin|
          name = pin["identity"]
          version = pin.dig("state", "version")
          path = dependency_path_for_url(pin["location"])
          error = "Unable to determine project path from #{url}" unless path

          Dependency.new(
            name: name,
            path: path,
            version: version,
            errors: Array(error),
            metadata: {
              "type"      => Swift.type,
              "homepage"  => homepage_for_url(pin["location"])
            }
          )
        }
      end

      private

      def pins
        return @pins if defined?(@pins)

        @pins = begin
          json = JSON.parse(File.read(package_resolved_file_path))
          json.dig("pins")
        rescue => e
          message = "Licensed was unable to read the Package.resolved file. Error: #{e.message}"
          raise Licensed::Sources::Source::Error, message
        end
      end

      def dependency_path_for_url(url)
        last_path_component = URI(url).path.split("/").last.sub(/\.git$/, "").rstrip
        File.join(@derived_data_path, "SourcePackages", "checkouts", last_path_component)
      rescue URI::InvalidURIError
      end

      def homepage_for_url(url)
        return unless %w{http https}.include?(URI(url).scheme)
        url.sub(/\.git$/, "")
      rescue URI::InvalidURIError
      end

      def package_resolved_file_path
        File.join(config.pwd, "ios.xcworkspace/xcshareddata/swiftpm", "Package.resolved")
      end

      def set_derived_data_path
        build_dir =  JSON.parse(`xcodebuild -showBuildSettings $@ -json`).first.dig("buildSettings", "BUILD_DIR")
        @derived_data_path = build_dir.delete_suffix("/Build/Products")
      end
    end
  end
end
