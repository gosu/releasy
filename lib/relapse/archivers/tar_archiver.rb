require "relapse/archivers/archiver"

module Relapse
module Archivers
  # An archiver that tars and then compresses the folder.
  # @abstract
  class TarArchiver < Archiver
    protected
    def command(folder)
      %[7z a -so -mmt -bd -ttar "#{folder}.tar" "#{folder}" | 7z a -si -bd -t#{format} "#{folder}#{extension}"]
    end
  end
end
end