require "relapse/archivers/archiver"

module Relapse
  module Archivers
    # OS X .dmg format (self-extractor).
    class Dmg < Archiver
      Archivers.register self

      def command(folder)
        %[GZIP=-9 hdiutil create -fs HFS+ -srcfolder "#{folder}" -volname "#{project.name} #{project.version}" "#{package(folder)}"]
      end
    end
  end
end