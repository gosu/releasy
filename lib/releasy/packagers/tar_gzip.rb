require "releasy/packagers/tar_packager"

module Releasy
  module Packagers
    # Archives with tar and Gzip formats.
    #
    # @example Package a particular build and change extension.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source do
    #       add_package :tar_gz do
    #         extension ".tgz"
    #       end
    #     end
    #   end
    #
    # @example Package all builds.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source
    #     add_build :windows_folder
    #     add_package :tar_gz
    #   end
    #
    class TarGzip < TarPackager
      TYPE = :tar_gz
      DEFAULT_EXTENSION = ".tar.gz"
      FORMAT = "gzip"
      Packagers.register self
    end
  end
end