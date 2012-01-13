require "release_packager/archivers/tar_archiver"

module ReleasePackager
  module Archivers
    class TarGzip < TarArchiver
      def self.identifier; :tar_gz; end
      def format; "gzip"; end
    end
  end
end