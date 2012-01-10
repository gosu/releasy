module ReleasePackager
  module Win32
    OCRA_COMMAND = "ocra"
    INSTALLER_SCRIPT = "installer.iss"
    UNINSTALLER_FILES = %w[unins000.dat unins000.exe]

    # Regular windows installer, but some users consider them evil.
    def build_win32_installer
      file INSTALLER_SCRIPT do
        generate_installer_script
      end

      directory installer_folder
      file installer_folder => installer_name

      file installer_name => files + [INSTALLER_SCRIPT] do
        system "#{ocra_command} --chdir-first --no-lzma --innosetup #{INSTALLER_SCRIPT}"
        rm INSTALLER_SCRIPT
        mv installer_name.pathmap('%2d%f'), installer_folder
      end

      desc "Build installer #{version} [Ocra/Innosetup]"
      task "build:win32:installer" => installer_folder
    end

    # FOLDER containing EXE, Ruby + source.
    def build_win32_folder
      file INSTALLER_SCRIPT do
        generate_installer_script
      end

      directory executable_folder_path
      file executable_folder_path => folder_installer_name

      file folder_installer_name => files + [INSTALLER_SCRIPT]

      desc "Build source/exe folder #{version} [Ocra/Innosetup]"
      task "build:win32:folder" => executable_folder_path do
        # Extract the installer and remove the uninstall files.
        system %[#{folder_installer_name} /SILENT /DIR=#{executable_folder_path}]
        UNINSTALLER_FILES.each {|f| rm File.join(executable_folder_path, f) }
      end
    end

    # Self-extracting standalone executable.
    def build_win32_standalone
      executable_path = "#{standalone_folder_path}/#{executable_name}"

      file executable_path => files do
        system ocra_command
        mv executable_name, standalone_folder_path
      end

      file standalone_folder_path => executable_path

      directory standalone_folder_path

      desc "Build standalone exe #{version} [Ocra]"
      task "build:win32:standalone" => standalone_folder_path
    end

    protected
    def installer_folder; "#{folder_base}_WIN32_INSTALLER"; end
    def installer_name; "#{installer_folder}/#{underscored_name}_setup.exe"; end
    def folder_installer_name; "#{folder_base}_setup_to_folder.exe"; end
    def executable_name; "#{underscored_name}.exe"; end
    def executable_folder_path; "#{folder_base}_WIN32"; end
    def standalone_folder_path; "#{folder_base}_WIN32_EXE"; end

    protected
    def ocra_command
      command = "#{OCRA_COMMAND} #{executable} #{ocra_parameters} "
      command += "--icon #{icon} " if icon
      command += files.map {|f| %["#{f}"]}.join(" ")
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
AppVersion=#{version}
DefaultDirName={pf}\\#{name.gsub(/[^\w\s]/, '')}
DefaultGroupName=#{installer_group ? "#{installer_group}\\" : ""}#{name}
OutputDir=#{output_path}
OutputBaseFilename=#{installer_name}
#{icon ? "SetupIconFile=#{icon}" : "" }
UninstallDisplayIcon={app}\\#{underscored_name}.exe

[Files]
END

          file.puts %[Source: "#{license}"; DestDir: "{app}"] if license
          file.puts %[Source: "#{readme}";  DestDir: "{app}"; Flags: isreadme] if readme

          links.each_pair do |url, title|
            file.puts %[Source: "#{title}.url"; DestDir: "{app}"]
          end

          # TODO: add other extra files including the changelog.

          file.write <<END
[Run]
Filename: "{app}\\#{underscored_name}.exe"; Description: "Launch"; Flags: postinstall nowait skipifsilent unchecked

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