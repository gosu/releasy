require "relapse/archivers/tar_archiver"

module Relapse
  module Archivers
    class TarGzip < TarArchiver
      TYPE = :tar_gz
      DEFAULT_EXTENSION = ".tar.gz"
      FORMAT = "gzip"
      Archivers.register self
    end
  end
end