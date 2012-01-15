require "relapse/archiver"

module Relapse
  module Archivers
    class SevenZip < Archiver
      def self.type; :"7z"; end
    end
  end
end