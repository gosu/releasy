require "releasy/packagers/packager"

module Releasy
  module Packagers
    # Windows self-extracting archive.
    #
    # If not on Windows, run "releasy install-sfx" after installing 7z, before you can use this.
    class Exe < Packager
      TYPE = :exe
      DEFAULT_EXTENSION = ".exe"

      SFX_NAME = "7z.sfx"
      SFX_FILE = File.expand_path("../../../../bin/#{SFX_NAME}", __FILE__)

      Packagers.register self

      protected
      def command(folder)
        %[7z a -mmt -bd -t7z -mx9 -sfx#{SFX_NAME} "#{package(folder)}" "#{folder}"]
      end
    end
  end
end