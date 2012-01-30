require "releasy/builders/ocra_builder"

module Releasy
  module Builders
    # Builds a win32 installer for the application.
    class WindowsInstaller < OcraBuilder
      TYPE = :windows_installer
      INSTALLER_SCRIPT = "windows_installer.iss"
      DEFAULT_FOLDER_SUFFIX = "WIN32_INSTALLER"

      Builders.register self

      # @return [String] Optional start-menu grouping of the application when installed (if name == "app" and installer_group == "frog", then it will get put into 'frog/app' in the start menu).
      attr_accessor :start_menu_group

      # @return [String] File name of readme file - End user will have the option to view this after the Windows installer has installed, recommended to be .txt, .rtf or .html.
      attr_accessor :readme
      # @return [String] Filename of license file - Must be .txt or .rtf file, which will be shown to user who will be requested to accept it (Windows installer only).
      attr_accessor :license

      protected
      # Regular windows installer, but some users consider them evil.
      def generate_tasks
        file folder => project.files do
          mkdir_p folder, fileutils_options
          create_link_files folder
          project.exposed_files.each {|file| cp file, folder, fileutils_options }

          create_installer installer_name, :links => true

          rm temp_installer_script, fileutils_options
        end

        desc "Build windows installer"
        task "build:windows:installer" => folder
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

      protected
      def create_installer(file, options = {})
        generate_installer_script file, options
        execute_command %[#{ocra_command} --chdir-first --no-lzma --innosetup "#{temp_installer_script}"]
      end

      # Generate innosetup script to build installer.
      protected
      def generate_installer_script(output_file, options = {})
        installer_links = options[:links]

        File.open(temp_installer_script, "w") do |file|
          file.write <<END
[Setup]
AppName=#{project.name}
AppVersion=#{project.version}
DefaultDirName={pf}\\#{project.name.gsub(/[^\w\s]/, '')}
OutputDir=#{File.dirname output_file}
OutputBaseFilename=#{File.basename(output_file).chomp(File.extname(output_file))}
UninstallDisplayIcon={app}\\#{project.underscored_name}.exe
END

          if installer_links
            if start_menu_group
              file.puts "DefaultGroupName=#{start_menu_group}\\#{project.name}"
            else
              file.puts "DefaultGroupName=#{project.name}"
            end

            file.puts "LicenseFile=#{license}" if license # User must accept license.
            file.puts "SetupIconFile=#{icon}" if icon
            file.puts

            file.puts "[Files]"

            file.puts %[Source: "#{license}"; DestDir: "{app}"] if license
            file.puts %[Source: "#{readme}";  DestDir: "{app}"; Flags: isreadme] if readme

            dir = File.dirname(output_file).tr("/", "\\")
            project.send(:links).each_value do |title|
              file.puts %[Source: "#{dir}\\#{title}.url"; DestDir: "{app}"]
            end
          end

          file.write <<END

[Run]
Filename: "{app}\\#{project.underscored_name}.exe"; Description: "Launch"; Flags: postinstall nowait skipifsilent unchecked

[Icons]
Name: "{group}\\#{project.name}"; Filename: "{app}\\#{project.underscored_name}.exe"
Name: "{group}\\Uninstall #{project.name}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\\#{project.name}"; Filename: "{app}\\#{project.underscored_name}.exe"; Tasks: desktopicon

[Tasks]
Name: desktopicon; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:";
Name: desktopicon\\common; Description: "For all users"; GroupDescription: "Additional icons:"; Flags: exclusive
Name: desktopicon\\user; Description: "For the current user only"; GroupDescription: "Additional icons:"; Flags: exclusive unchecked
Name: quicklaunchicon; Description: "Create a &Quick Launch icon"; GroupDescription: "Additional icons:"; Flags: unchecked
END
        end
      end
    end
  end
end