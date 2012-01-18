require 'rake'

$LOAD_PATH.unshift File.expand_path("..", __FILE__)

module Relapse
  def self.win_platform?; RUBY_PLATFORM =~ /mingw|win32/; end

  # An error caused when Relapse configuration is incorrect or inconsistent.
  class ConfigError < StandardError; end
end

require "relapse/version"
require "relapse/project"

