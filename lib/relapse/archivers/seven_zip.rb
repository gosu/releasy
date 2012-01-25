require "relapse/archivers/archiver"

module Relapse
  module Archivers
    # 7z archive format (LZMA)
    class SevenZip < Archiver
      TYPE = :"7z"
      DEFAULT_EXTENSION = ".7z"
      Archivers.register self
    end
  end
end