require "relapse/archiver"

module Relapse
  module Archivers
    class SevenZip < Archiver
      def self.identifier; :"7z"; end
    end
  end
end