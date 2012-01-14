ReleasePackager
================

ReleasePackager automates the release of Ruby applications.
It generates a number of Rake tasks for use when there is a need to release a new version of the
application.

Project
-------

* [Github project](https://github.com/Spooner/release_packager)
* [Reporting issues](https://github.com/Spooner/release_packager/issues)

Output types supported
----------------------

The project can create one or more release folders:

* `:source` - Plain source folder, which can be used by anyone with Ruby already installed.
* `:osx_app` - OSX application bundle (.app) [won't be executable if generated on Windows, but otherwise will work. Note that this only contains binary gems for Gosu, TexPlay and Chipmunk, but will work with applications using any source gems].
* `:win32_folder` - A folder containing Ruby, application source files and an EXE to run them [creation on Windows only and requires InnoSetup to be installed]
* `:win32_installer` - A regular Windows installer [creation on Windows only and requires InnoSetup to be installed]
* `:win32_standalone` - Standalone EXE file that self-extracts to a temporary directory - slower startup than the other win32 options [creation on Windows only]

Archive types supported
-----------------------

Optionally, release folders can be archived using one or more of:

* `:"7z"` - 7Zip format (.7z - Best compression)
* `:tar_bz2` - BZip2 tarball (.tar.bz2)
* `:tar_gz` - GZip tarball (.tar.gz)
* `:zip` - Standard zip format (.zip - Poor compression, but best compatibility)

Example
-------

### Project's Rakefile

    require 'release_packager'

    # Example is from my game, Alpha Channel.
    ReleasePackager::Project.new do |p|
      p.name = "Alpha Channel"
      p.version = AlphaChannel::VERSION
      p.executable = "bin/alpha_channel.rbw"
      p.files = `git ls-files`.split("\n").reject {|f| f[0] == '.' }
      p.ocra_parameters = "--no-enc"
      p.icon = "media/icon.ico"
      p.readme = "README.html"

      p.add_link "http://spooner.github.com/games/alpha_channel", "Alpha Channel website"

      # Create a variety of releases, for all platforms.
      p.add_output :osx_app
      p.add_output :source
      p.add_output :win32_folder
      p.add_output :win32_installer

      # Settings for specific outputs.
      p.win32_installer_group = "Spooner Games"
      p.osx_app_url = "com.github.spooner.games.alpha_channel"
      p.osx_app_wrapper = "../osx_app/RubyGosu App.app"

      # Create all packages as zip and 7z archives.
      p.add_archive_format :zip
      p.add_archive_format :'7z'
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
    rake package:osx:app               # Package Alpha Channel in all archive f...
    rake package:osx:app:7z            # Create pkg/alpha_channel_1_4_0_OSX.7z
    rake package:osx:app:zip           # Create pkg/alpha_channel_1_4_0_OSX.zip
    rake package:source                # Package Alpha Channel in all archive f...
    rake package:source:7z             # Create pkg/alpha_channel_1_4_0_SOURCE.7z
    rake package:source:zip            # Create pkg/alpha_channel_1_4_0_SOURCE.zip
    rake package:win32                 # Package all win32
    rake package:win32:folder          # Package Alpha Channel in all archive f...
    rake package:win32:folder:7z       # Create pkg/alpha_channel_1_4_0_WIN32.7z
    rake package:win32:folder:zip      # Create pkg/alpha_channel_1_4_0_WIN32.zip
    rake package:win32:installer       # Package Alpha Channel in all archive f...
    rake package:win32:installer:7z    # Create pkg/alpha_channel_1_4_0_WIN32_I...
    rake package:win32:installer:zip   # Create pkg/alpha_channel_1_4_0_WIN32_I...

External Requirements
---------------------

* To create package archives (optional), the [7z](http://www.7-zip.org/download.html) must be installed.
* To create `:win32_folder` and `:win32_installer` outputs, [InnoSetup](http://www.jrsoftware.org/isdl.php) must be installed.

Credits
-------

* Thanks to jlnr for creating "RubyGosu App.app", an OS X application bundle used to wrap application code.
* Thanks to larsh for the [Ocra gem](http://ocra.rubyforge.org/), which is used for generating Win32 executables.
* Thanks to jlnr for help testing the OS X package builder.
* Thanks to shawn42 for help designing the API.

