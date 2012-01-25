require "releasy/archivers/tar_archiver"

module Releasy
  module Archivers
    # Archives with tar and Bzip2 formats.
    class TarBzip2 < TarArchiver
      TYPE = :tar_bz2
      DEFAULT_EXTENSION = ".tar.bz2"
      FORMAT = "bzip2"
      Archivers.register self
    end
  end
end