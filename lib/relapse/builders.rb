require 'relapse/mixins/register'

module Relapse
  module Builders
    extend Mixins::Register
  end
end

%w[osx_app source win32_folder win32_folder_from_wrapper win32_installer win32_standalone].each do |builder|
  require "relapse/builders/#{builder}"
end