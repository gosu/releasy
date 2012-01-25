require 'rake'

$LOAD_PATH.unshift File.expand_path("..", __FILE__)

# Application release manager.
module Releasy
  def self.win_platform?; RUBY_PLATFORM =~ /mingw|win32/; end

  # An error caused when Releasy configuration is incorrect or inconsistent.
  class ConfigError < StandardError; end

  # Modules used to extend Releasy classes.
  module Mixins; end
end

require "releasy/version"
require "releasy/project"

