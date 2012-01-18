require "relapse/archivers/archiver"

module Relapse
  module Archivers
    class Zip < Archiver
      Archivers.register self
    end
  end
end