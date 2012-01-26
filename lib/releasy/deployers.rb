require 'releasy/mixins/register'

module Releasy
  # Contains all {Deployer} types.
  module Deployers
    extend Mixins::Register
  end
end

%w[github].each do |deployer|
  require "releasy/deployers/#{deployer}"
end