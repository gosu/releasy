require "relapse/builders/win32_builder"

module Relapse
  module Builders
    # Builds a folder containing Ruby + your source + a small win32 executable to run your executable script.
    class Win32Folder < Win32Builder
      Builders.register self

      INSTALLER_SCRIPT = "win32_folder.iss"
      UNINSTALLER_FILES = %w[unins000.dat unins000.exe]

      def self.folder_suffix; "WIN32"; end

      # FOLDER containing EXE, Ruby + source.
      def generate_tasks
        directory folder

        file folder => project.files do
          create_link_files folder
          project.exposed_files.each {|file| cp file, folder }

          create_installer installer_name, :links => false

          # Extract the installer to the directory.
          command = %[#{installer_name} /VERYSILENT /DIR=#{folder}]
          puts command if project.verbose?
          system command

          # Remove files that would be used to uninstall.
          UNINSTALLER_FILES.each {|f| rm File.join(folder, f) }
          rm temp_installer_script
          rm installer_name
        end

        desc "Build source/exe folder #{project.version} [Innosetup]"
        task "build:win32:folder" => folder
      end

      protected
      def temp_installer_script; "#{project.output_path}/#{INSTALLER_SCRIPT}"; end
      def installer_name; "#{project.folder_base}_setup_to_folder.exe"; end
      def executable_name; "#{project.underscored_name}.exe"; end
    end
  end
end