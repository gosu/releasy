require "releasy/packagers/tar_packager"

module Releasy
  module Packagers
    # Archives with tar and Bzip2 formats.
    class TarBzip2 < TarPackager
      TYPE = :tar_bz2
      DEFAULT_EXTENSION = ".tar.bz2"
      FORMAT = "bzip2"
      Packagers.register self
    end
  end
end