require 'relapse/mixins/register'

module Relapse
  module Archivers
    extend Mixins::Register
  end
end

%w[exe seven_zip tar_bzip2 tar_gzip zip].each do |archiver|
  require "relapse/archivers/#{archiver}"
end