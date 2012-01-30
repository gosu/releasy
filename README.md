Releasy
=======

_Releasy_ automates the release of Ruby applications for non-Ruby users, such as games or GUI applications.
By configuring a {Releasy::Project} in your application's Rakefile, Releasy can generate Rake tasks for use
when there is a need to build, package (archive) and/or deploy a new version of the application.

* Author: [Bil Bas (Spooner)](https://github.com/Spooner)
* Licence: [MIT](http://www.opensource.org/licenses/mit-license.php)
* [Github project](https://github.com/Spooner/releasy)
* [Reporting issues](https://github.com/Spooner/releasy/issues)
* Releasy has been tested on Ruby 1.9.3 and 1.8.7 on Windows, Lubuntu and OS X. However, since this is an early version, please ensure that you double-check any releases created by Releasy before publishing them!


Key features
------------

* Package up Ruby applications (Games, GUI applications, etc.) for non-ruby users.
* Build OSX application bundle (.app) on any platform.
* Build Windows executable (.exe) on any platform.
* Build Windows installer on Windows only.
* Build, package (compress) and deploy your executables for all platforms from a single rake command ('rake deploy').


Installation
------------

    gem install releasy


Example
-------

### Project's Rakefile

    require 'rubygems'
    require 'bundler/setup' # Releasy doesn't require that your application uses bundler, but it does make things easier.
    require 'releasy'
    require 'lib/my_application/version'

    #<<<
    Releasy::Project.new do
      name "My Application"
      version MyApplication::VERSION

      executable "bin/my_application.rbw"
      files `git ls-files`.split("\n")
      files.exclude '.gitignore'

      exposed_files ["README.html", "LICENSE.txt"]
      add_link "http://my_application.github.com", "My Application website"
      exclude_encoding

      # Create a variety of releases, for all platforms.
      add_build :osx_app do
        url "com.github.my_application"
        wrapper "../osx_app/gosu-mac-wrapper-0.7.41.tar.gz"
        icon "media/icon.icns"
        add_package :tar_gz
      end

      add_build :source do
        add_package :"7z"
      end

      add_build :windows_folder do
        icon "media/icon.ico"
        add_package :exe
      end

      add_build :windows_installer do
        icon "media/icon.ico"
        start_menu_group "Spooner Games"
        readme "README.html" # User asked if they want to view readme after install.
        license "LICENSE.txt" # User asked to read this and confirm before installing.
        add_package :zip
      end

      add_deploy :github # Upload to a github project.
    end
    #>>>

### Tasks created

Note: The `windows:folder`, `windows:installer` and `windows:standalone` will be created only if running on Windows.
The `windows:wrapped` task will not be created if running on Windows.

    rake build                                # Build My Application 1.4.0
    rake build:osx                            # Build all osx
    rake build:osx:app                        # Build OS X app
    rake build:source                         # Build source
    rake build:windows                        # Build all windows
    rake build:windows:folder                 # Build windows folder
    rake build:windows:installer              # Build windows installer
    rake deploy                               # Deploy My Application 1.4.0
    rake deploy:osx:app:tar_gz:github         # github <= osx app .tar.gz
    rake deploy:source:7z:github              # github <= source .7z
    rake deploy:windows:folder:exe:github     # github <= windows folder .exe
    rake deploy:windows:installer:zip:github  # github <= windows installer .zip
    rake generate:images                      # Generate images
    rake package                              # Package My Application 1.4.0
    rake package:osx:app:tar_gz               # Package osx app .tar.gz
    rake package:source:7z                    # Package source .7z
    rake package:windows:folder:exe           # Package windows folder .exe
    rake package:windows:installer:zip        # Package windows installer .zip

A variety of unlisted tasks are also created, that allow for more control, such as `deploy:github` (Deploy all packages to Github only),
`deploy:windows:folder` (deploy all windows folder packages all destinations) or `package:windows` (Package all windows builds).


Build types supported
----------------------

The project can build one or more release folders:

* `:source`
  - Plain source folder, which can be used by anyone with Ruby already installed.
  - See {Releasy::Builders::Source}
* `:osx_app`
  - OS X application bundle (.app) build, requiring a pre-made Ruby OS X wrapper. Note that this only contains binary gems for Gosu, TexPlay and Chipmunk, but will work with applications using any other source gems.
  - See {Releasy::Builders::OsxApp}
* `:windows_folder`
  - A folder containing Ruby, application source files and an EXE to run them.
  - Available on _Windows only_.
  - See {Releasy::Builders::WindowsFolder}
* `:windows_wrapped`
  - A folder containing Ruby, application source files and an EXE to run them, requiring a copy of a RubyInstaller archive.
  - Available on _OS X and Linux only_.
  - Creates larger release than other Windows build options.
  - See {Releasy::Builders::WindowsWrapped}
* `:windows_installer`
  - A Windows installer.
  - Available on _Windows only and requires [InnoSetup](http://www.jrsoftware.org/isinfo.php) to be installed_.
  - See {Releasy::Builders::WindowsInstaller}
* `:windows_standalone`
  - Standalone EXE file that self-extracts to a temporary directory, which is the default behaviour for [Ocra](https://github.com/larsch/ocra).
  - Available on _Windows only_.
  - Slower startup than the other Windows build options (up to 2s slower).
  - See {Releasy::Builders::WindowsStandalone}

See {Releasy::Project#add_build}


Package types supported
-----------------------

Optionally, release folders can be packaged into an archive using one or more of:

* `:"7z"`
  - 7Zip format (.7z - Best compression).
  - See {Releasy::Packagers::SevenZip}
* `:dmg`
  - OS X self-extractor (.dmg - requires `hdiutil` to be installed, so only available on OS X).
  - Available on OS X only (`hdiutils` command required).
  - See {Releasy::Packagers::Dmg}
* `:exe`
  - Windows self-extractor (.exe - Includes a 7z decompression module, so not efficient for small releases).
  - See {Releasy::Packagers::Exe}
* `:tar_bz2`
  - Bzip2 tarball (.tar.bz2).
  - See {Releasy::Packagers::TarBzip2}
* `:tar_gz`
  - Gzip tarball (.tar.gz).
  - See {Releasy::Packagers::TarGzip}
* `:zip`
  - Standard zip format (.zip - Poor compression, but best compatibility).
  - See {Releasy::Packagers::Zip}

See {Releasy::Mixins::HasPackagers#add_package}


Deploy types supported
----------------------

Optionally, packaged releases can be deployed using one or more of:

* `:github`
  - Upload to a Github project's downloads page.
  - See {Releasy::Deployers::Github}
* `:local`
  - Copy files locally, for example into a local web server or dropbox folder.
  - See {Releasy::Deployers::Local}
* `:rsync`
  - Upload to remote server with rsync (requires 'rsync' command be installed).
  - See {Releasy::Deployers::Rsync}

See {Releasy::Project#add_deploy}


CLI Commands
------------

Releasy also provides some supplementary commands:

* `releasy install-sfx [options]` - Installs a copy of the Windows self-extractor in the local 7z installation, to allow use of the `:exe` archive format (it comes with the Windows version of 7z, so only need to use this command on OS X/Linux).


External Requirements
---------------------

### 7-Zip (OS X/Linux only - Windows `7za` executable included in Windows)

The [7z](http://www.7-zip.org) command must be installed on your system for Releasy to work:

  - Installing on OS X homebrew:

    <pre>brew install p7zip</pre>

  - Installing on Ubuntu/Debian:

    <pre>sudo apt-get install p7zip-full</pre>

  - Installing on other OS

    * [Download 7-Zip](http://www.7-zip.org/download.html)

### To build `:windows_installer` release (Windows only)

[InnoSetup](http://www.jrsoftware.org/isdl.php) is used to create an installer for the application.

### To build `:windows_wrapped` release (OS X/Linux)

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

* bin/7z.sfx - Windows [7-ZIP](http://www.7-zip.org) self-extractor module, which can be installed using `releasy install-sfx` [License: [GNU LGPL](http://www.7-zip.org/license.txt)]
* bin/7za.exe - Windows [7-ZIP](http://www.7-zip.org) CLI executable.
