require "relapse/archivers/archiver"

module Relapse
  module Archivers
    class SevenZip < Archiver
      def self.type; :"7z"; end
      Archivers.register self
    end
  end
end