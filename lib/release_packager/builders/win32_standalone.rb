require "release_packager/builders/win32_builder"

module ReleasePackager
  module Builders
    # Creates a completely standalone (self-extracting when run) win32 executable.
    class Win32Standalone < Win32Builder

      def self.folder_suffix; "WIN32_EXE"; end

      protected
      # Self-extracting standalone executable.
      def create_tasks
        directory standalone_folder_path

        file standalone_folder_path => project.files do
          cp project.readme, standalone_folder_path if project.readme
          create_link_files standalone_folder_path

          command = %[#{ocra_command} --output "#{standalone_folder_path}/#{executable_name}"]
          puts command if project.verbose?
          system command
        end

        desc "Build standalone exe #{project.version} [Ocra]"
        task "build:win32:standalone" => standalone_folder_path
      end

      protected
      def executable_name; "#{project.underscored_name}.exe"; end
      def standalone_folder_path; "#{project.folder_base}_#{folder_suffix}"; end
    end
  end
end