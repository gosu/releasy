require "release_packager/archiver"

module ReleasePackager
  module Archivers
    class SevenZip < Archiver
      def self.identifier; :"7z"; end
    end
  end
end