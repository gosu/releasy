require "releasy/archivers/archiver"

module Releasy
  module Archivers
    # 7z archive format (LZMA)
    class SevenZip < Archiver
      TYPE = :"7z"
      DEFAULT_EXTENSION = ".7z"
      Archivers.register self
    end
  end
end