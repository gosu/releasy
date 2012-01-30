require 'releasy/deployers/deployer'
require "releasy/mixins/utilities"

module Releasy
  module Deployers
    # Deploys to a remote server, using the rsync command.
    #
    # @example
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source
    #     add_package :zip
    #     add_deploy :rsync do
    #       destination "example.com:/var/www/sites/mysite/downloads" # Required.
    #     end
    #   end
    #
    # @attr destination [String] Location to deploy to, such as "example.com:/var/www/sites/mysite/downloads".
    # @attr options [String] ('-glpPrtvz') Options to pass to rsync.
    class Rsync < Deployer
      include Mixins::Utilities

      TYPE = :rsync
      DEFAULT_OPTIONS = '-glpPrtvz'

      Deployers.register self

      attr_reader :destination
      def destination=(destination)
        raise TypeError, "destination must be a String, but received #{destination.inspect}" unless destination.is_a? String
        raise ArgumentError, 'destination requires no trailing slash' if destination[-1,1] == '/'
        @destination = destination
      end

      attr_reader :options
      def options=(options)
        raise TypeError, "options must be a String, but received #{options.inspect}" unless options.is_a? String
        @options = options
      end

      protected
      def setup
        @destination = nil
        @options = DEFAULT_OPTIONS
      end

      protected
      # @param file [String] Path to file to deploy.
      # @return [nil]
      def deploy(file)
        raise ConfigError, "#destination must be set" unless destination

        execute_command %[rsync #{options} "#{File.expand_path file}" "#{destination.chomp "/"}"]

        nil
      end
    end
  end
end