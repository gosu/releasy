Releasy
=======

_Releasy_ automates the release of Ruby applications (name comes from "Release + easy").
By configuring a {Releasy::Project} in your application's rakefile, Releasy can generates a number of Rake tasks for use
when there is a need to release a new version of the application.

Releasy allows cross-platform releases, relying on OS X or Windows "wrappers" to act as templates.

* Author: [Bil Bas (Spooner)](https://github.com/Spooner)
* Licence: [MIT](http://www.opensource.org/licenses/mit-license.php)
* [Github project](https://github.com/Spooner/releasy)
* [Reporting issues](https://github.com/Spooner/releasy/issues)
* Relapse has been tested on Ruby 1.9.3 and 1.8.7 on Windows, Lubuntu and OS X. However, since this is an early version, please ensure that you double-check any releases created by Releasy before publishing them!

Output types supported
----------------------

The project can build one or more release folders:

* `:source` - Plain source folder, which can be used by anyone with Ruby already installed.
* `:osx_app` - OS X application bundle (.app) build, requiring a pre-made Ruby OS X wrapper. Note that this only contains binary gems for Gosu, TexPlay and Chipmunk, but will work with applications using any other source gems.
* `:windows_folder` - A folder containing Ruby, application source files and an EXE to run them [creation on Windows only].
* `:windows_folder_from_ruby_dist` - A folder containing Ruby, application source files and an EXE to run them, requiring a copy of a RubyInstaller archive [creation on OSX/Linux].
* `:windows_installer` - A regular Windows installer [creation on Windows only and requires InnoSetup to be installed].
* `:windows_standalone` - Standalone EXE file that self-extracts to a temporary directory - slower startup than the other Windows options [creation on Windows only].

Archive types supported
-----------------------

Optionally, release folders can be archived using one or more of:

* `:dmg` - OS X self-extractor (.dmg - requires `hdiutil` to be installed, so only available on OS X).
* `:exe` - Windows self-extractor (.exe - Includes a 7z decompression module, so not efficient for small releases).
* `:"7z"` - 7Zip format (.7z - Best compression).
* `:tar_bz2` - BZip2 tarball (.tar.bz2).
* `:tar_gz` - GZip tarball (.tar.gz).
* `:zip` - Standard zip format (.zip - Poor compression, but best compatibility).

Example
-------

### Project's Rakefile

    # Example is from my game, Alpha Channel.
    require 'rubygems'
    require 'bundler/setup' # Releasy doesn't require that your application uses bundler, but it does make things easier.
    require 'releasy'
    require 'lib/alpha_channel/version'

    #<<<
    Releasy::Project.new do
      name "Alpha Channel"
      version AlphaChannel::VERSION

      executable "bin/alpha_channel.rbw"
      files `git ls-files`.split("\n")
      files.exclude '.gitignore'

      exposed_files ["README.html", "LICENSE.txt"]
      add_link "http://spooner.github.com/games/alpha_channel", "Alpha Channel website"

      # Create a variety of releases, for all platforms.
      add_build :osx_app do
        add_archive :tar_gz
        url "com.github.spooner.games.alpha_channel"
        wrapper "../osx_app/gosu-mac-wrapper-0.7.41.tar.gz"
        icon "media/icon.icns"
      end

      add_build :source

      add_build :windows_folder do
        icon "media/icon.ico"
        add_archive :exe
        exclude_encoding
      end

      add_build :windows_installer do
        icon "media/icon.ico"
        exclude_encoding
        start_menu_group "Spooner Games"
        readme "README.html" # User asked if they want to view readme after install.
        license "LICENSE.txt" # User asked to read this and confirm before installing.
      end

      add_archive :zip # All outputs given this archive format.
    end
    #>>>

### Tasks created

Note: The `windows:folder`, `windows:installer` and `windows:standalone` will be created only if running on Windows.
The `windows:folder_from_ruby_dist` task will not be created if running on Windows.

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

Releasy also provides some supplementary commands:

* `releasy install-sfx [options]` - Installs a copy of the Windows self-extractor in the local 7z installation, to allow use of the `:exe` archive format (it comes with the Windows version of 7z, so only need to use this command on OS X/Linux).


External Requirements
---------------------

### 7-Zip

[7z](http://www.7-zip.org) must be installed on your system for Releasy to work:

  - Installing on OS X homebrew:

    <pre>brew install p7zip</pre>

  - Installing on Ubuntu/Debian:

    <pre>sudo apt-get install p7zip-full</pre>

  - Installing on Windows (or other OS)

    * [Download](http://www.7-zip.org/download.html)

### To build `:windows_installer` release (Windows only)

[InnoSetup](http://www.jrsoftware.org/isdl.php) is used to create an installer for the application.

### To build `:windows_folder_from_ruby_dist` release (OS X/Linux)

[RubyInstaller 7-ZIP archives](http://rubyinstaller.org/downloads/) for Ruby 1.8.7, 1.9.2 or 1.9.3. Used as a wrapper for a Windows release built on non-Windows systems.

### To build `:osx_app` application bundle release (any platform)

[libgosu app wrapper](http://www.libgosu.org/downloads/). Latest version of the OS X-compatible wrapper is "gosu-mac-wrapper-0.7.41.tar.gz" which uses Ruby 1.9.2 and includes some binary gems: Gosu, Chipmunk and TexPlay.

Credits
-------

* Thanks to jlnr for creating "RubyGosu App.app", an OS X application bundle used to wrap application code.
* Thanks to larsh for the [Ocra gem](http://ocra.rubyforge.org/), which is used for generating Win32 executables.
* Thanks to jlnr and shawn42 for help testing on OS X; without you I would have been screwed!
* Thanks to shawn42 and everyone at #gosu and #rubylang for suggestions on how to improve the API.
* Thanks to kyrylo for coming up with the name, Releasy!

Third Party Assets included
---------------------------

* bin/7z.sfx - Windows [7z 9.20](http://www.7-zip.org) self-extractor module, which can be installed using `releasy install-sfx` [License: [GNU LGPL](http://www.7-zip.org/license.txt)]

