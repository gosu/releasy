require 'rake'

$LOAD_PATH.unshift File.expand_path("..", __FILE__)

# Application release manager.
module Relapse
  def self.win_platform?; RUBY_PLATFORM =~ /mingw|win32/; end

  # An error caused when Relapse configuration is incorrect or inconsistent.
  class ConfigError < StandardError; end

  # Modules used to extend Relapse classes.
  module Mixins; end
end

require "relapse/version"
require "relapse/project"

