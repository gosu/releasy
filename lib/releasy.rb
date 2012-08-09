require 'bundler'
require 'rake'

$LOAD_PATH.unshift File.expand_path("..", __FILE__)

# Application release manager.
module Releasy
  def self.win_platform?; !!(RUBY_PLATFORM =~ /mingw|win32/); end

  class ReleasyError < StandardError; end

  # An error caused when Releasy configuration is incorrect or inconsistent.
  class ConfigError < ReleasyError; end

  # Failed to find a particular CLI command on the system.
  class CommandNotFoundError < ReleasyError; end

  # Modules used to extend Releasy classes.
  module Mixins; end
end

require "releasy/version"
require "releasy/project"

