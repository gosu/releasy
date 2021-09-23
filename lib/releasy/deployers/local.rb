require 'releasy/deployers/deployer'

module Releasy
  module Deployers
    # Deploys (copies) to a local destination, such as into your Dropbox folder.
    #
    # @example
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source
    #     add_package :zip
    #     add_deploy :local do
    #       path "C:/Users/X/Dropbox/Public" # Required.
    #     end
    #   end
    #
    # @attr path [String] Path to copy files to.
    class Local < Deployer
      TYPE = :local

      Deployers.register self

      attr_reader :path
      def path=(path)
        raise TypeError, "path must be a String, but received #{path.class}" unless path.is_a? String
        @path = path
      end

      protected
      def setup
        @path = nil
      end

      protected
      # @param file [String] Path to file to deploy.
      # @return [nil]
      def deploy(file)
        raise ConfigError, "#path must be set" unless path

        destination = File.join path, File.basename(file)
        raise ConfigError, "#path is same as build directory" if File.expand_path(destination) == File.expand_path(file)

        # If destination file already exists or is as new as the one we are going to copy over it, don't bother.
        if (not File.exists?(destination)) or (File.ctime(destination) < File.ctime(file))
          mkdir_p path, **fileutils_options unless File.exists? path
          cp file, path, **fileutils_options
        else
          warn "Skipping '#{File.basename(file)}' because it already exists in '#{path}'"
        end

        nil
      end
    end
  end
end