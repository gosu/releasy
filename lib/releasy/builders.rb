require 'releasy/mixins/register'

module Releasy
  # Contains all {Builder} types.
  module Builders
    extend Mixins::Register
  end
end

%w[osx_app source windows_folder windows_wrapped windows_installer windows_standalone].each do |builder|
  require "releasy/builders/#{builder}"
end