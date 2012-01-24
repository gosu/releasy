require "relapse/builders/ocra_builder"

module Relapse
  module Builders
    # Creates a completely standalone (self-extracting when run) Windows executable.
    class WindowsStandalone < OcraBuilder
      TYPE = :windows_standalone
      DEFAULT_FOLDER_SUFFIX = "WIN32_EXE"

      Builders.register self

      protected
      # Self-extracting standalone executable.
      def generate_tasks
        directory folder

        file folder => project.files do
          Rake::FileUtilsExt.verbose project.verbose?

          project.exposed_files.each {|file| cp file, folder }

          create_link_files folder

          exec %[#{ocra_command} --output "#{folder}/#{executable_name}"]
        end

        desc "Build standalone exe #{project.version} [Ocra]"
        task "build:windows:standalone" => folder
      end

      protected
      def executable_name; "#{project.underscored_name}.exe"; end
    end
  end
end