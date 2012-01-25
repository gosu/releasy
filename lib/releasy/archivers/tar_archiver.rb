require "releasy/archivers/archiver"

module Releasy
module Archivers
  # An archiver that tars and then compresses the folder.
  # @abstract
  class TarArchiver < Archiver
    protected
    def command(folder)
      %[7z a -so -mmt -bd -ttar "#{folder}.tar" "#{folder}" | 7z a -si -bd -t#{self.class::FORMAT} -mx9 "#{folder}#{extension}"]
    end
  end
end
end