require "relapse/builders/win32_builder"

module Relapse
  module Builders
    # Builds a win32 installer for the application.
    class Win32Installer < Win32Builder
      INSTALLER_SCRIPT = "win32_installer.iss"

      def self.folder_suffix; "WIN32_INSTALLER"; end

      protected
      # Regular windows installer, but some users consider them evil.
      def create_tasks
        directory folder

        file folder => project.files do
          create_link_files folder
          cp project.readme, folder if project.readme

          create_installer installer_name, :links => true

          rm temp_installer_script
        end

        desc "Build installer #{project.version} [Innosetup]"
        task "build:win32:installer" => folder
      end

      protected
      def temp_installer_script; "#{project.output_path}/#{INSTALLER_SCRIPT}"; end
      def folder; "#{project.folder_base}_#{folder_suffix}"; end
      def installer_name; "#{folder}/#{project.underscored_name}_setup.exe"; end
    end
  end
end