require "releasy/packagers/packager"

module Releasy
  module Packagers
    # OS X .dmg format (self-extractor).
    #
    # @example Package a particular build.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source do
    #       add_package :dmg
    #     end
    #   end
    #
    # @example Package all builds.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source
    #     add_build :windows_folder
    #     add_package :dmg
    #   end
    #
    class Dmg < Packager
      TYPE = :dmg
      DEFAULT_EXTENSION = ".dmg"

      Packagers.register self

      protected
      def command(folder)
        %[GZIP=-9 hdiutil create -fs HFS+ -srcfolder "#{folder}" -volname "#{project.name} #{project.version}" "#{package(folder)}"]
      end
    end
  end
end