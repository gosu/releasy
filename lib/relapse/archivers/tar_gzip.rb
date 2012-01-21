require "relapse/archivers/tar_archiver"

module Relapse
  module Archivers
    class TarGzip < TarArchiver
      FORMAT = "gzip"
      def self.type; :tar_gz; end
      Archivers.register self
    end
  end
end