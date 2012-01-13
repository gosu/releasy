require "release_packager/builders/win32_builder"

module ReleasePackager
  module Builders
    class Win32Folder < Win32Builder
      INSTALLER_SCRIPT = "win32_folder.iss"
      UNINSTALLER_FILES = %w[unins000.dat unins000.exe]

      def self.folder_suffix; "WIN32"; end

      protected
      # FOLDER containing EXE, Ruby + source.
      def create_tasks
        directory executable_folder_path

        file executable_folder_path => project.files do
          create_link_files executable_folder_path

          create_installer folder_installer_name, :links => false

          # Extract the installer to the directory.
          command = %[#{folder_installer_name} /SILENT /DIR=#{executable_folder_path}]
          puts command if project.verbose?
          system command

          # Remove files that would be used to uninstall.
          UNINSTALLER_FILES.each {|f| rm File.join(executable_folder_path, f) }
          rm temp_installer_script
          rm folder_installer_name
        end

        desc "Build source/exe folder #{project.version} [Innosetup]"
        task "build:win32:folder" => executable_folder_path
      end

      protected
      def temp_installer_script; "#{@output_path}/#{INSTALLER_SCRIPT}"; end
      def folder_installer_name; "#{project.folder_base}_setup_to_folder.exe"; end
      def executable_name; "#{project.underscored_name}.exe"; end
      def executable_folder_path; "#{project.folder_base}_WIN32"; end
    end
  end
end