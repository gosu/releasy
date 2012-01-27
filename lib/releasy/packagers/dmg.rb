require "releasy/packagers/packager"

module Releasy
  module Packagers
    # OS X .dmg format (self-extractor).
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