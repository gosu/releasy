require "releasy/packagers/packager"

module Releasy
  module Packagers
    # 7z archive format (LZMA)
    #
    # @example Package a particular build.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source do
    #       add_package :"7z"
    #     end
    #   end
    #
    # @example Package all builds.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source
    #     add_build :windows_folder
    #     add_package :"7z"
    #   end
    #
    class SevenZip < Packager
      TYPE = :"7z"
      DEFAULT_EXTENSION = ".7z"
      Packagers.register self
    end
  end
end