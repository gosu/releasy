require 'releasy/mixins/register'

module Releasy
  # Contains all {Archiver} types.
  module Archivers
    extend Mixins::Register
  end
end

%w[dmg exe seven_zip tar_bzip2 tar_gzip zip].each do |archiver|
  require "releasy/archivers/#{archiver}"
end