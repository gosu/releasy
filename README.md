Relapse
================

_Relapse_ automates the release of Ruby applications (from: "release apps").
It generates a number of Rake tasks for use when there is a need to release a new version of the
application.

Project
-------

* [Github project](https://github.com/Spooner/relapse)
* [Reporting issues](https://github.com/Spooner/relapse/issues)

Output types supported
----------------------

The project can create one or more release folders:

* `:source` - Plain source folder, which can be used by anyone with Ruby already installed.
* `:osx_app` - OSX application bundle (.app) build, requiring a pre-made Ruby OS X wrapper [won't be executable if generated on Windows, but otherwise will work. Note that this only contains binary gems for Gosu, TexPlay and Chipmunk, but will work with applications using any source gems].
* `:win32_folder` - A folder containing Ruby, application source files and an EXE to run them [creation on Windows only and requires InnoSetup to be installed]
* `:win32_folder_from_wrapper` - A folder containing Ruby, application source files and an EXE to run them, requiring a pre-made Ruby win32 wrapper [creation on Linux/OS X]
* `:win32_installer` - A regular Windows installer [creation on Windows only and requires InnoSetup to be installed]
* `:win32_standalone` - Standalone EXE file that self-extracts to a temporary directory - slower startup than the other win32 options [creation on Windows only]

Archive types supported
-----------------------

Optionally, release folders can be archived using one or more of:

* `:exe` - Windows self-extractor (.exe - Includes a 7z decompression module, so not efficient for small releases)
* `:"7z"` - 7Zip format (.7z - Best compression)
* `:tar_bz2` - BZip2 tarball (.tar.bz2)
* `:tar_gz` - GZip tarball (.tar.gz)
* `:zip` - Standard zip format (.zip - Poor compression, but best compatibility)

Example
-------

### Project's Rakefile

    require 'relapse'

    # Example is from my game, Alpha Channel.
    Relapse::Project.new do |p|
      p.name = "Alpha Channel"
      p.version = AlphaChannel::VERSION
      p.executable = "bin/alpha_channel.rbw"
      p.files = `git ls-files`.split("\n").reject {|f| f[0] == '.' }
      o.exposed_files = ["README.html"]
      p.add_link "http://spooner.github.com/games/alpha_channel", "Alpha Channel website"

      # Create a variety of releases, for all platforms.
      p.add_output :osx_app do |o|
        o.add_archive_format :tar_gz
        o.url = "com.github.spooner.games.alpha_channel"
        o.wrapper = "../osx_app/RubyGosu App.app"
        o.gemspecs = Bundler.definition.specs_for([:default]) # Don't want :development gems.
        o.icon = "media/icon.icns"
      end
      p.add_output :source
      p.add_output :win32_folder do |o|
        o.icon = "media/icon.ico"
        o.add_archive_format :exe
        o.ocra_parameters = "--no-enc"
      end
      p.add_output :win32_installer do |o|
        o.icon = "media/icon.ico"
        o.ocra_parameters = "--no-enc"
        o.start_menu_group = "Spooner Games"
        o.readme = "README.html" # User asked if they want to view it after install.
      end

      o.add_archive_format :zip # All outputs given this archive format.
    end

### Tasks created

Note: The _win32_ tasks will not be created unless running on Windows.

    rake build                         # Build all outputs
    rake build:osx                     # Build all osx outputs
    rake build:osx:app                 # Build OS X app
    rake build:source                  # Build source folder
    rake build:win32                   # Build all win32 outputs
    rake build:win32:folder            # Build source/exe folder 1.4.0 [Innosetup]
    rake build:win32:installer         # Build installer 1.4.0 [Innosetup]
    rake package                       # Package all
    rake package:osx                   # Package all osx
    rake package:osx:app               # Package all osx_app
    rake package:osx:app:tar_gz        # Create pkg/alpha_channel_1_4_0_OSX.tar.gz
    rake package:osx:app:zip           # Create pkg/alpha_channel_1_4_0_OSX.zip
    rake package:source                # Package all source
    rake package:source:zip            # Create pkg/alpha_channel_1_4_0_SOURCE.zip
    rake package:win32                 # Package all win32
    rake package:win32:folder          # Package all win32_folder
    rake package:win32:folder:exe      # Create pkg/alpha_channel_1_4_0_WIN32.exe
    rake package:win32:folder:zip      # Create pkg/alpha_channel_1_4_0_WIN32.zip
    rake package:win32:installer       # Package all win32_installer
    rake package:win32:installer:zip   # Create pkg/alpha_channel_1_4_0_WIN32_I...

External Requirements
---------------------

* To create package archives (optional), [7z](http://www.7-zip.org) must be installed.
  - Installing on OS X homebrew:

    `brew install p7zip`

  - Installing on Ubuntu/Debian:

    `sudo apt-get install p7zip-full`

  - Installing on win32 (or other OS):

    [7z downloads](http://www.7-zip.org/download.html)

* To create `:win32_folder` and `:win32_installer` outputs, [InnoSetup](http://www.jrsoftware.org/isdl.php) must be installed.

Credits
-------

* Thanks to jlnr for creating "RubyGosu App.app", an OS X application bundle used to wrap application code.
* Thanks to larsh for the [Ocra gem](http://ocra.rubyforge.org/), which is used for generating Win32 executables.
* Thanks to jlnr for help testing the OS X package builder.
* Thanks to shawn42 for help designing the API.

Third Party Assets included
---------------------------

* bin/7z.sfx - Windows [7z 9.20](http://www.7-zip.org) self-extractor module [License: [GNU LGPL](http://www.7-zip.org/license.txt)]

