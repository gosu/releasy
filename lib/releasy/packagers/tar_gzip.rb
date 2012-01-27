require "releasy/packagers/tar_packager"

module Releasy
  module Packagers
    # Archives with tar and Gzip formats.
    class TarGzip < TarPackager
      TYPE = :tar_gz
      DEFAULT_EXTENSION = ".tar.gz"
      FORMAT = "gzip"
      Packagers.register self
    end
  end
end