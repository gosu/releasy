require "releasy/archivers/tar_archiver"

module Releasy
  module Archivers
    # Archives with tar and Gzip formats.
    class TarGzip < TarArchiver
      TYPE = :tar_gz
      DEFAULT_EXTENSION = ".tar.gz"
      FORMAT = "gzip"
      Archivers.register self
    end
  end
end