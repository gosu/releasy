require "relapse/builders/win32_builder"

module Relapse
  module Builders
    # Builds a win32 installer for the application.
    class Win32Installer < Win32Builder
      Builders.register self

      INSTALLER_SCRIPT = "win32_installer.iss"

      # @return [String] Optional start-menu grouping of the application when installed (if name == "app" and installer_group == "frog", then it will get put into 'frog/app' in the start menu).
      attr_accessor :start_menu_group

      # @return [String] File name of readme file - End user will have the option to view this after the win32 installer has installed, recommended to be .txt, .rtf or .html.
      attr_accessor :readme
      # @return [String] Filename of license file - Must be .txt or .rtf file, which will be shown to user who will be requested to accept it (win32 installer only).
      attr_accessor :license

      def self.folder_suffix; "WIN32_INSTALLER"; end

      # Regular windows installer, but some users consider them evil.
      def generate_tasks
        directory folder

        file folder => project.files do
          create_link_files folder
          project.exposed_files.each {|file| cp file, folder }

          create_installer installer_name, :links => true

          rm temp_installer_script
        end

        desc "Build installer #{project.version} [Innosetup]"
        task "build:win32:installer" => folder
      end

      protected
      def setup
        super
        @start_menu_group = nil
        @readme = nil
        @license = nil
      end

      protected
      def temp_installer_script; "#{project.output_path}/#{INSTALLER_SCRIPT}"; end
      def installer_name; "#{folder}/#{project.underscored_name}_setup.exe"; end
    end
  end
end