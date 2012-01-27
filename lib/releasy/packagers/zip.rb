require "releasy/packagers/packager"

module Releasy
  module Packagers
    # Archives with zip format. This isn't efficient, but can be decompressed on Windows Vista or later without requiring a 3rd party tool.
    class Zip < Packager
      TYPE = :zip
      DEFAULT_EXTENSION = ".zip"
      Packagers.register self
    end
  end
end