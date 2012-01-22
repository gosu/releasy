require "relapse/archivers/archiver"

module Relapse
  module Archivers
    class Zip < Archiver
      TYPE = :zip
      DEFAULT_EXTENSION = ".zip"
      Archivers.register self
    end
  end
end