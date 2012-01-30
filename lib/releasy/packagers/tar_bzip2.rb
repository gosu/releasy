require "releasy/packagers/tar_packager"

module Releasy
  module Packagers
    # Archives with tar and Bzip2 formats.
    #
    # @example Package a particular build and change extension.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source do
    #       add_package :tar_bz2 do
    #         extension ".tbz"
    #       end
    #     end
    #   end
    #
    # @example Package all builds.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source
    #     add_build :windows_folder
    #     add_package :tar_bz2
    #   end
    #
    class TarBzip2 < TarPackager
      TYPE = :tar_bz2
      DEFAULT_EXTENSION = ".tar.bz2"
      FORMAT = "bzip2"
      Packagers.register self
    end
  end
end