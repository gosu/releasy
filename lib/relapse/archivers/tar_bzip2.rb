require "relapse/archivers/tar_archiver"

module Relapse
  module Archivers
    class TarBzip2 < TarArchiver
      FORMAT = "bzip2"
      def self.type; :tar_bz2; end
      Archivers.register self
    end
  end
end