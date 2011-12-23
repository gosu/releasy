module ReleasePackager
  module Win32

  end
end

=begin
WIN32_EXECUTABLE = "#{APP}.exe"
APP_WITH_VERSION = "#{APP}_v#{RELEASE_VERSION.tr(".", "-")}_WIN32"
WIN32_INSTALLER_NAME = "#{APP_WITH_VERSION}_setup"
WIN32_INSTALLER = "#{RELEASE_FOLDER}/#{WIN32_INSTALLER_NAME}.exe"

WIN32_FOLDER = "#{RELEASE_FOLDER_BASE}/#{APP_WITH_VERSION}"

RELEASE_FOLDER_WIN32_EXE = "#{RELEASE_FOLDER_BASE}_WIN32"
RELEASE_FOLDER_WIN32_INSTALLER = "#{RELEASE_FOLDER_BASE}_WIN32_INSTALLER"

WEBSITE_FILE = "website.url"

#--no-dep-run --gemfile Gemfile
OCRA_COMMAND = "ocra bin/#{APP}.rbw --windows  --icon media/icon.ico --no-enc #{SOURCE_FOLDERS.map {|s| "#{s}/**/*.* "}.join}"

INSTALLER_BUILD_SCRIPT = File.expand_path("installer.iss", RELEASE_FOLDER)

CLOBBER.include WIN32_EXECUTABLE, WIN32_INSTALLER

# RELEASES
desc "Create win32 releases v#{RELEASE_VERSION}"
task "release:win32" => ["release:win32:exe_zip", "release:win32:installer_zip"] # No point making a 7z, since it is same size.

#desc "Create win32 exe releases v#{RELEASE_VERSION}"
task "release:win32:exe" => ["release:win32:exe_zip"] # No point making a 7z, since it is same size.

#desc "Create win32 installer releases v#{RELEASE_VERSION}"
task "release:win32:installer" => ["release:win32:installer_zip"] # No point making a 7z, since it is same size.

# EXECUTABLE
file WIN32_EXECUTABLE => "build:win32:standalone"
desc "Ocra => #{WIN32_EXECUTABLE} v#{RELEASE_VERSION}"
task "build:win32:standalone" => SOURCE_FOLDER_FILES do
  system OCRA_COMMAND
end

# INSTALLER
file RELEASE_FOLDER_WIN32_INSTALLER => [WIN32_INSTALLER, README_HTML] do
  mkdir_p RELEASE_FOLDER_WIN32_INSTALLER
  mv WIN32_INSTALLER, RELEASE_FOLDER_WIN32_INSTALLER
  cp CHANGELOG_FILE, RELEASE_FOLDER_WIN32_INSTALLER
  cp README_HTML, RELEASE_FOLDER_WIN32_INSTALLER
end

file WIN32_INSTALLER => "build:win32:installer"
desc "Ocra/Innosetup => #{WIN32_INSTALLER}"
task "build:win32:installer" => SOURCE_FOLDER_FILES do
  # Link to website.
  File.open(WEBSITE_FILE, "w") do |file|
    file.puts <<END
[InternetShortcut]
URL=http://spooner.github.com/games/#{APP}
END
  end

  # Script to build installer.
  File.open(INSTALLER_BUILD_SCRIPT, "w") do |file|
    file.write <<END
[Setup]
AppName=#{APP_READABLE}
AppVersion=#{RELEASE_VERSION}
DefaultDirName={pf}\\#{APP_READABLE.gsub(/[^\w\s]/, '')}
DefaultGroupName=Spooner Games\\#{APP_READABLE}
OutputDir=#{RELEASE_FOLDER}
OutputBaseFilename=#{WIN32_INSTALLER_NAME}
SetupIconFile=media/icon.ico
UninstallDisplayIcon={app}\\#{APP}.exe

[Files]
Source: "#{CHANGELOG_FILE}"; DestDir: "{app}"
#{defined?(LICENSE_FILE) ? %[Source: "#{LICENSE_FILE}"; DestDir: "{app}"] : ""}
Source: "#{README_HTML}"; DestDir: "{app}"; Flags: isreadme
Source: "website.url"; DestDir: "{app}"

[Run]
Filename: "{app}\\#{APP}.exe"; Description: "Launch game"; Flags: postinstall nowait skipifsilent unchecked

[Icons]
Name: "{group}\\#{APP_READABLE}"; Filename: "{app}\\#{APP}.exe"
Name: "{group}\\#{APP_READABLE} Web Site"; Filename: "{app}\\website.url"
Name: "{group}\\Uninstall #{APP_READABLE}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\\#{APP_READABLE}"; Filename: "{app}\\#{APP}.exe"; Tasks: desktopicon

[Tasks]
Name: desktopicon; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:";
Name: desktopicon\\common; Description: "For all users"; GroupDescription: "Additional icons:"; Flags: exclusive
Name: desktopicon\\user; Description: "For the current user only"; GroupDescription: "Additional icons:"; Flags: exclusive unchecked
Name: quicklaunchicon; Description: "Create a &Quick Launch icon"; GroupDescription: "Additional icons:"; Flags: unchecked

END

#LicenseFile=COPYING.txt
  end

  system OCRA_COMMAND + " --chdir-first --no-lzma --innosetup #{INSTALLER_BUILD_SCRIPT}"
  
  rm INSTALLER_BUILD_SCRIPT
  rm WEBSITE_FILE
end

# FOLDER containing EXE.
file RELEASE_FOLDER_WIN32_EXE => "build:win32:exe"
task "build:win32:exe" => WIN32_INSTALLER do
  system %[#{WIN32_INSTALLER} /SILENT /DIR=#{RELEASE_FOLDER_WIN32_EXE}]
  rm File.join(RELEASE_FOLDER_WIN32_EXE, "unins000.dat")
  rm File.join(RELEASE_FOLDER_WIN32_EXE, "unins000.exe")
end

=end