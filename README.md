Relapse
================

_Relapse_ automates the release of Ruby applications (its name is a perversion of "release apps").
By configuring a Relapse::Project in your application's rakefile, Relapse can generates a number of Rake tasks for use
when there is a need to release a new version of the application.

Relapse allows cross-platform releases, relying on pre-made OS X or Windows wrappers to act as templates
(Relapse is able to make the latter type of wrapper itself).

* Author: [Bil Bas (Spooner)](https://github.com/Spooner)
* Licence: [MIT](http://www.opensource.org/licenses/mit-license.php)
* [Github project](https://github.com/Spooner/relapse)
* [Reporting issues](https://github.com/Spooner/relapse/issues)
* Wrappers used to build cross-platform releases:
  - Win32 wrapper not yet published, but can be made on a Windows system with `relapse windows-wrapper` command.
  - [OS X wrapper downloads from libgosu.org](http://www.libgosu.org/downloads/), including Gosu, Chipmunk and Texplay binary gems. Latest version is [gosu-mac-wrapper-0.7.41](http://www.libgosu.org/downloads/gosu-mac-wrapper-0.7.41.tar.gz).

Output types supported
----------------------

The project can create one or more release folders:

* `:source` - Plain source folder, which can be used by anyone with Ruby already installed.
* `:osx_app` - OSX application bundle (.app) build, requiring a pre-made Ruby OS X wrapper [Note that this only contains binary gems for Gosu, TexPlay and Chipmunk, but will work with applications using any other source gems].
* `:windows_folder` - A folder containing Ruby, application source files and an EXE to run them [creation on Windows only]
* `:windows_folder_from_wrapper` - A folder containing Ruby, application source files and an EXE to run them, requiring a pre-made Ruby Windows wrapper [creation on Linux/OS X only]
* `:windows_installer` - A regular Windows installer [creation on Windows only and requires InnoSetup to be installed]
* `:windows_standalone` - Standalone EXE file that self-extracts to a temporary directory - slower startup than the other Windows options [creation on Windows only]

Archive types supported
-----------------------

Optionally, release folders can be archived using one or more of:

* `:dmg` - OS X self-extractor (.dmg - requires `hdiutil` to be installed, so only available on OS X)
* `:exe` - Windows self-extractor (.exe - Includes a 7z decompression module, so not efficient for small releases)
* `:"7z"` - 7Zip format (.7z - Best compression)
* `:tar_bz2` - BZip2 tarball (.tar.bz2)
* `:tar_gz` - GZip tarball (.tar.gz)
* `:zip` - Standard zip format (.zip - Poor compression, but best compatibility)

Example
-------

### Project's Rakefile

    # Example is from my game, Alpha Channel.
    require 'rubygems'
    require 'bundler/setup' # Relapse doesn't require that your application uses bundler, but it does make things easier.
    require 'relapse'
    require 'lib/alpha_channel/version'

    #<<<
    Relapse::Project.new do
      name "Alpha Channel"
      version AlphaChannel::VERSION

      executable "bin/alpha_channel.rbw"
      files `git ls-files`.split("\n") - ['.gitignore']
      exposed_files ["README.html"]
      add_link "http://spooner.github.com/games/alpha_channel", "Alpha Channel website"

      # Create a variety of releases, for all platforms.
      add_build :osx_app do
        add_archive :tar_gz
        url "com.github.spooner.games.alpha_channel"
        wrapper "../osx_app/RubyGosu App.app"
        icon "media/icon.icns"
      end

      add_build :source

      add_build :windows_folder do
        icon "media/icon.ico"
        add_archive :exe
        ocra_parameters "--no-enc"
      end

      add_build :windows_installer do
        icon "media/icon.ico"
        ocra_parameters "--no-enc"
        start_menu_group "Spooner Games"
        readme "README.html" # User asked if they want to view it after install.
      end

      add_archive :zip # All outputs given this archive format.
    end
    #>>>

### Tasks created

Note: The `windows` tasks (except `windows:folder_from_wrapper`) will not be created unless running on Windows.
Note: The `windows:folder_from_wrapper` task not be created if running on Windows.

    rake build                         # Build all outputs
    rake build:osx                     # Build all osx outputs
    rake build:osx:app                 # Build OS X app
    rake build:source                  # Build source folder
    rake build:windows                 # Build all Windows outputs
    rake build:windows:folder          # Build source/exe folder 1.4.0
    rake build:windows:installer       # Build installer 1.4.0 [Innosetup]
    rake package                       # Package all
    rake package:osx                   # Package all OS X
    rake package:osx:app               # Package all :osx_app
    rake package:osx:app:tar_gz        # Create pkg/alpha_channel_1_4_0_OSX.tar.gz
    rake package:osx:app:zip           # Create pkg/alpha_channel_1_4_0_OSX.zip
    rake package:source                # Package all :source
    rake package:source:zip            # Create pkg/alpha_channel_1_4_0_SOURCE.zip
    rake package:windows               # Package all Windows outputs
    rake package:windows:folder        # Package all :windows_folder outputs
    rake package:windows:folder:exe    # Create pkg/alpha_channel_1_4_0_WIN32.exe
    rake package:windows:folder:zip    # Create pkg/alpha_channel_1_4_0_WIN32.zip
    rake package:windows:installer     # Package all :windows_installer
    rake package:windows:installer:zip # Create pkg/alpha_channel_1_4_0_WIN32_I...

CLI Commands
------------

Relapse also provides some supplementary commands:

* `relapse Windows-wrapper [options]` - Build a Windows wrapper for use to build the `:windows_folder_from_wrapper` output on non-Windows platforms (runs on Windows only).


External Requirements (Optional)
--------------------------------

### To create package archives (except `:dmg`)

[7z](http://www.7-zip.org) must be installed.

  - Installing on OS X homebrew:

    <pre>brew install p7zip</pre>

  - Installing on Ubuntu/Debian:

    <pre>sudo apt-get install p7zip-full</pre>

  - Installing on Windows (or other OS)

    * [Download](http://www.7-zip.org/download.html)

### To create `:windows_installer` output

[InnoSetup](http://www.jrsoftware.org/isdl.php) must be installed.

Credits
-------

* Thanks to jlnr for creating "RubyGosu App.app", an OS X application bundle used to wrap application code.
* Thanks to larsh for the [Ocra gem](http://ocra.rubyforge.org/), which is used for generating Win32 executables.
* Thanks to jlnr for help testing the OS X package builder.
* Thanks to shawn42 for help designing the API.

Third Party Assets included
---------------------------

* bin/7z.sfx - Windows [7z 9.20](http://www.7-zip.org) self-extractor module [License: [GNU LGPL](http://www.7-zip.org/license.txt)]

