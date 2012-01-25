require "relapse/archivers/archiver"

module Relapse
  module Archivers
    # Archives with zip format. This isn't efficient, but can be decompressed on Windows Vista or later without requiring a 3rd party tool.
    class Zip < Archiver
      TYPE = :zip
      DEFAULT_EXTENSION = ".zip"
      Archivers.register self
    end
  end
end