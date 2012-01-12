module ReleasePackager
  module Win32
    OCRA_COMMAND = "ocra"
    INSTALLER_SCRIPT = "installer.iss"
    UNINSTALLER_FILES = %w[unins000.dat unins000.exe]

    # Regular windows installer, but some users consider them evil.
    def build_win32_installer
      directory installer_folder

      file installer_folder => files do
        create_link_files installer_folder
        cp readme, installer_folder if readme

        create_installer installer_name, :links => true

        rm temp_installer_script
      end

      desc "Build installer #{version} [Innosetup]"
      task "build:win32:installer" => installer_folder
    end

    # FOLDER containing EXE, Ruby + source.
    def build_win32_folder
      directory executable_folder_path

      file executable_folder_path => files do
        create_link_files executable_folder_path

        create_installer folder_installer_name, :links => false

        # Extract the installer to the directory.
        command = %[#{folder_installer_name} /SILENT /DIR=#{executable_folder_path}]
        puts command if verbose?
        system command

        # Remove files that would be used to uninstall.
        UNINSTALLER_FILES.each {|f| rm File.join(executable_folder_path, f) }
        rm temp_installer_script
        rm folder_installer_name
      end

      desc "Build source/exe folder #{version} [Innosetup]"
      task "build:win32:folder" => executable_folder_path
    end

    # Self-extracting standalone executable.
    def build_win32_standalone
      directory standalone_folder_path

      file standalone_folder_path => files do
        cp readme, standalone_folder_path if readme
        create_link_files standalone_folder_path

        command = %[#{ocra_command} --output "#{standalone_folder_path}/#{executable_name}"]
        puts command if verbose?
        system command
      end

      desc "Build standalone exe #{version} [Ocra]"
      task "build:win32:standalone" => standalone_folder_path
    end

    protected
    def temp_installer_script; "#{@output_path}/#{INSTALLER_SCRIPT}"; end
    def installer_folder; "#{folder_base}_WIN32_INSTALLER"; end
    def installer_name; "#{installer_folder}/#{underscored_name}_setup.exe"; end
    def folder_installer_name; "#{folder_base}_setup_to_folder.exe"; end
    def executable_name; "#{underscored_name}.exe"; end
    def executable_folder_path; "#{folder_base}_WIN32"; end
    def standalone_folder_path; "#{folder_base}_WIN32_EXE"; end

    protected
    def ocra_command
      command = %[#{OCRA_COMMAND} "#{executable}" #{ocra_parameters} ]
      command += %[--icon "#{icon}" ] if icon
      command += (files - [executable]).map {|f| %["#{f}"]}.join(" ")
      command
    end

    protected
    def create_installer(file, options = {})
      generate_installer_script file, options
      command = %[#{ocra_command} --chdir-first --no-lzma --innosetup "#{temp_installer_script}"]
      puts command if verbose?
      system command
    end

    protected
    def create_link_files(dir)
      @links.each_pair do |url, title|
        create_link_file url, File.join(dir, title)
      end
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
    def generate_installer_script(output_file, options = {})
      installer_links = options[:links]

      File.open(temp_installer_script, "w") do |file|
        file.write <<END
[Setup]
AppName=#{underscored_name}
AppVersion=#{version}
DefaultDirName={pf}\\#{name.gsub(/[^\w\s]/, '')}
DefaultGroupName=#{installer_group ? "#{installer_group}\\" : ""}#{name}
OutputDir=#{File.dirname output_file}
OutputBaseFilename=#{File.basename(output_file).chomp(File.extname(output_file))}
UninstallDisplayIcon={app}\\#{underscored_name}.exe
END

        if installer_links
          file.puts "LicenseFile=#{license}" if license # User must accept license.
          file.puts "SetupIconFile=#{icon}" if icon
          file.puts

          file.puts "[Files]"

          file.puts %[Source: "#{license}"; DestDir: "{app}"] if license
          file.puts %[Source: "#{readme}";  DestDir: "{app}"; Flags: isreadme] if readme

          dir = File.dirname(output_file).tr("/", "\\")
          @links.each_value do |title|
            file.puts %[Source: "#{dir}\\#{title}.url"; DestDir: "{app}"]
          end
        end

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