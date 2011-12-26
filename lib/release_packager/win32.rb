module ReleasePackager
  module Win32
    OCRA_COMMAND = "ocra"
    INSTALLER_SCRIPT = "installer.iss"

    def build_win32_installer
      file INSTALLER_SCRIPT do
        generate_installer_script
      end

      file installer_folder => installer_name do
        mkdir_p installer_folder
        mv installer_name, installer_folder
      end

      file installer_name => "build:win32_installer"
      desc "Ocra/Innosetup => #{installer_name}"
      task "build:win32_installer" => @files do
        system "#{ocra_command} --chdir-first --no-lzma --innosetup #{INSTALLER_SCRIPT}"
      end
    end

    # FOLDER containing EXE, Ruby + source.
    def build_win32_folder
      file executable_folder_path => "build:win32_exe"
      task "build:win32_exe" => installer_name do
        system %[#{installer_name} /SILENT /DIR=#{executable_folder_path}]
        rm File.join(executable_folder_path, "unins000.dat")
        rm File.join(executable_folder_path, "unins000.exe")
      end
    end

    # Self-extracting standalone executable.
    def build_win32_standalone
      file executable_name => "build:win32_standalone"
      desc "Create #{executable_name} #{version} with Ocra"
      task "build:win32_standalone" => @files do
        system ocra_command
      end
    end

    protected
    def installer_folder; "#{underscored_name}_#{version}_WIN32_INSTALLER"; end
    def installer_name; "#{underscored_name}_#{version}_setup.exe"; end
    def executable_name; "#{underscored_name}.exe"; end
    def executable_folder_path; "#{underscored_name}_#{version}_EXE"; end

    protected
    def ocra_command
      command = "#{OCRA_COMMAND} #{@execute} #{@ocra_parameters} "
      command += "--icon #{icon} " if @icon
      command += @files.map {|f| %["#{f}"]}.join(" ")
      command
    end

    protected
    def create_link_file(url, title)
      File.open("#{title}.url", "w") do |file|
        file.puts <<END
[InternetShortcut]
URL=#{url}
END
      end
    end

    # Generate innosetup script to build installer.
    protected
    def generate_installer_script
      File.open(INSTALLER_SCRIPT, "w") do |file|
        file.write <<END
[Setup]
AppName=#{underscored_name}
AppVersion=#{@version}
DefaultDirName={pf}\\#{@name.gsub(/[^\w\s]/, '')}
DefaultGroupName=#{@installer_group ? "#{@installer_group}\\" : ""}#{@name}
OutputDir=#{@output_path}
OutputBaseFilename=#{installer_name}
SetupIconFile=media/icon.ico
UninstallDisplayIcon={app}\\#{underscored_name}.exe

[Files]
END

          file.puts %[Source: "#{@license}"; DestDir: "{app}"] if @license
          file.puts %[Source: "#{@readme}";  DestDir: "{app}"; Flags: isreadme] if @readme

          @links.each_pair do |url, title|
            file.puts %[Source: "#{title}.url"; DestDir: "{app}"]
          end

          # TODO: add other extra files including the changelog.

          file.write <<END
[Run]
Filename: "{app}\\#{@id}.exe"; Description: "Launch"; Flags: postinstall nowait skipifsilent unchecked

[Icons]
Name: "{group}\\#{name}"; Filename: "{app}\\#{underscored_name}.exe"
Name: "{group}\\Uninstall #{name}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\\#{name}"; Filename: "{app}\\#{underscored_name}.exe"; Tasks: desktopicon

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