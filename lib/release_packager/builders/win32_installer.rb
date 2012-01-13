require "release_packager/builders/win32_builder"

module ReleasePackager
  module Builders
    class Win32Installer < Win32Builder
      INSTALLER_SCRIPT = "win32_installer.iss"

      def self.folder_suffix; "WIN32_INSTALLER"; end

      protected
      # Regular windows installer, but some users consider them evil.
      def create_tasks
        directory installer_folder

        file installer_folder => project.files do
          create_link_files installer_folder
          cp project.readme, installer_folder if project.readme

          create_installer installer_name, :links => true

          rm temp_installer_script
        end

        desc "Build installer #{project.version} [Innosetup]"
        task "build:win32:installer" => installer_folder
      end

      protected
      def temp_installer_script; "#{@output_path}/#{INSTALLER_SCRIPT}"; end
      def installer_folder; "#{project.folder_base}_#{folder_suffix}"; end
      def installer_name; "#{installer_folder}/#{project.underscored_name}_setup.exe"; end
    end
  end
end