require 'relapse/mixins/register'

module Relapse
  # Contains all {Builder} types.
  module Builders
    extend Mixins::Register
  end
end

%w[osx_app source windows_folder windows_folder_from_ruby_dist windows_installer windows_standalone].each do |builder|
  require "relapse/builders/#{builder}"
end