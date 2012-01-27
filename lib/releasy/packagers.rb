require 'releasy/mixins/register'

module Releasy
  # Contains all {Packager} types.
  module Packagers
    extend Mixins::Register
  end
end

%w[dmg exe seven_zip tar_bzip2 tar_gzip zip].each do |packager|
  require "releasy/packagers/#{packager}"
end