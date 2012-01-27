require "releasy/packagers/packager"

module Releasy
  module Packagers
    # 7z archive format (LZMA)
    class SevenZip < Packager
      TYPE = :"7z"
      DEFAULT_EXTENSION = ".7z"
      Packagers.register self
    end
  end
end