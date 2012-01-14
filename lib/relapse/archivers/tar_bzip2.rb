require "relapse/archivers/tar_archiver"

module Relapse
  module Archivers
    class TarBzip2 < TarArchiver
      def self.identifier; :tar_bz2; end
      def format; "bzip2"; end
    end
  end
end