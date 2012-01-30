require "releasy/packagers/packager"

module Releasy
  module Packagers
    # Archives with zip format. This isn't efficient, but can be decompressed on Windows Vista or later without requiring a 3rd party tool.
    #
    # @example Package a particular build.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source do
    #       add_package :zip
    #     end
    #   end
    #
    # @example Package all builds.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source
    #     add_build :windows_folder
    #     add_package :zip
    #   end
    #
    class Zip < Packager
      TYPE = :zip
      DEFAULT_EXTENSION = ".zip"
      Packagers.register self
    end
  end
end