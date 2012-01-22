require "relapse/archivers/tar_archiver"

module Relapse
  module Archivers
    class TarBzip2 < TarArchiver
      TYPE = :tar_bz2
      DEFAULT_EXTENSION = ".tar.bz2"
      FORMAT = "bzip2"
      Archivers.register self
    end
  end
end