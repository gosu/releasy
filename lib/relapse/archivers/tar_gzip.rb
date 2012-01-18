require "relapse/archivers/tar_archiver"

module Relapse
  module Archivers
    class TarGzip < TarArchiver
      def self.type; :tar_gz; end
      Archivers.register self

      def format; "gzip"; end
    end
  end
end