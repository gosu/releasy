require "relapse/archivers/archiver"

module Relapse
  module Archivers
    # OS X .dmg format (self-extractor).
    class Dmg < Archiver
      TYPE = :dmg
      DEFAULT_EXTENSION = ".dmg"

      Archivers.register self

      protected
      def command(folder)
        %[GZIP=-9 hdiutil create -fs HFS+ -srcfolder "#{folder}" -volname "#{project.name} #{project.version}" "#{package(folder)}"]
      end
    end
  end
end