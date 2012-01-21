require 'relapse/mixins/register'

module Relapse
  module Builders
    extend Mixins::Register
  end
end

%w[osx_app source windows_folder windows_folder_from_wrapper windows_installer windows_standalone].each do |builder|
  require "relapse/builders/#{builder}"
end