require "releasy/packagers/packager"

module Releasy
  module Packagers
    # Windows self-extracting archive.
    #
    # If not on Windows, run "releasy install-sfx" after installing 7z, before you can use this.
    #
    # @example Package a particular build.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source do
    #       add_package :exe
    #     end
    #   end
    #
    # @example Package all builds.
    #   Releasy::Project.new do
    #     name "My App"
    #     add_build :source
    #     add_build :windows_folder
    #     add_package :exe
    #   end
    #
    class Exe < Packager
      TYPE = :exe
      DEFAULT_EXTENSION = ".exe"

      SFX_NAME = "7z.sfx"
      SFX_FILE = File.expand_path("../../../../bin/#{SFX_NAME}", __FILE__)

      Packagers.register self

      protected
      def command(folder)
        %[#{seven_zip_command} a -mmt -bd -t7z -mx9 -sfx#{SFX_NAME} "#{package(folder)}" "#{folder}"]
      end
    end
  end
end