require "relapse/archivers/archiver"

module Relapse
  module Archivers
    class Exe < Archiver
      TYPE = :exe
      DEFAULT_EXTENSION = ".exe"

      SFX_NAME = "7z.sfx"
      SFX_FILE = File.expand_path("../../../../bin/#{SFX_NAME}", __FILE__)
      SFX_FOLDER = "/usr/lib/p7zip"

      Archivers.register self

      protected
      def self_extractor
        if Relapse.win_platform?
          SFX_NAME
        elsif File.exists? SFX_FOLDER
          if File.exists? "#{SFX_FOLDER}/#{SFX_NAME}"
            SFX_NAME
          else
            raise %[7z installed, but Windows self-extractor file not installed.\nRun: sudo cp "#{SFX_FILE}" "#{SFX_FOLDER}"]
          end
        else
          raise "Not sure where 7z is installed, but #{SFX_FILE} must be manually copied into the 7z assets folder (expected to be '#{SFX_FOLDER}')."
        end
      end

      protected
      def command(folder)
        %[7z a -mmt -bd -t7z -sfx#{self_extractor} "#{package(folder)}" "#{folder}"]
      end
    end
  end
end