require "release_packager/archiver"

module ReleasePackager
  class TarArchiver < Archiver
    def command(folder)
      %[7z a -so -mmt -bd -ttar "#{folder}.tar" "#{folder}" | 7z a -si -bd -t#{format} "#{folder}.#{extension}"]
    end
  end
end