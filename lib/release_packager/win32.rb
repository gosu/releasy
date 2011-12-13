WIN32_EXECUTABLE = "#{APP}.exe"
WIN32_INSTALLER_NAME = "#{APP}_v#{RELEASE_VERSION.tr(".", "-")}_setup"
WIN32_INSTALLER = "#{RELEASE_FOLDER}/#{WIN32_INSTALLER_NAME}.exe"

RELEASE_FOLDER_WIN32_EXE = "#{RELEASE_FOLDER_BASE}_WIN32_EXE"
RELEASE_FOLDER_WIN32_INSTALLER = "#{RELEASE_FOLDER_BASE}_WIN32_INSTALLER"

OCRA_COMMAND = "ocra bin/#{APP}.rbw --windows --no-dep-run --gemfile Gemfile --icon media/icon.ico --no-enc lib/**/*.* media/**/*.* bin/**/*.*"

INSTALLER_BUILD_SCRIPT = File.expand_path("installer.iss", RELEASE_FOLDER)

CLOBBER.include WIN32_EXECUTABLE, WIN32_INSTALLER

# EXECUTABLE
file WIN32_EXECUTABLE => "build:win32:executable"
desc "Ocra => #{WIN32_EXECUTABLE} v#{RELEASE_VERSION}"
task "build:win32:executable" => SOURCE_FOLDER_FILES do
  system OCRA_COMMAND
end

# INSTALLER
file WIN32_INSTALLER => "build:win32:installer"
desc "Ocra/Innosetup => #{WIN32_INSTALLER}"
task "build:win32:installer" => SOURCE_FOLDER_FILES do
  File.open(INSTALLER_BUILD_SCRIPT, "w") do |file|
    file.write <<END
[Setup]
AppName=#{APP_READABLE}
AppVersion=#{RELEASE_VERSION}
DefaultDirName={pf}\\#{APP_READABLE.gsub(/[^\w\s]/, '')}
DefaultGroupName=Spooner Games\\#{APP_READABLE}
OutputDir=#{RELEASE_FOLDER}
OutputBaseFilename=#{WIN32_INSTALLER_NAME}

[Files]
Source: "#{CHANGELOG_FILE}"; DestDir: "{app}"
#{defined?(LICENSE_FILE) ? %[Source: "#{LICENSE_FILE}"; DestDir: "{app}"] : ""}
Source: "#{README_FILE}"; DestDir: "{app}"; Flags: isreadme

[Run]
Filename: "{app}\\#{APP}.exe"; Description: "Launch game"; Flags: postinstall nowait skipifsilent unchecked

[Icons]
Name: "{group}\\#{APP_READABLE}"; Filename: "{app}\\#{APP}.exe"
Name: "{group}\\Uninstall #{APP_READABLE}"; Filename: "{uninstallexe}"
END

#LicenseFile=COPYING.txt
  end

  system OCRA_COMMAND + " --chdir-first --no-lzma --innosetup #{INSTALLER_BUILD_SCRIPT}"
  
  rm INSTALLER_BUILD_SCRIPT
end