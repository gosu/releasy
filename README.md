Releasy
=======

_Releasy_ automates the release of Ruby applications, such as games or GUI applications, for non-Ruby users.
By configuring a {Releasy::Project} in your application's Rakefile, Releasy can generate Rake tasks for use
when there is a need to build, package (archive) and/or deploy a new version of the application.

* Author: [Bil Bas (Spooner)](https://github.com/Spooner)
* Licence: [MIT](http://www.opensource.org/licenses/mit-license.php)
* [Github project](https://github.com/Spooner/releasy)
* [Reporting issues](https://github.com/Spooner/releasy/issues)
* IRC channel: #releasy ([irc.freenode.net](http://webchat.freenode.net/))
* Releasy has been tested on Ruby 1.9.3 and 1.8.7 on Windows, Lubuntu and OS X. However, since this is an early version, please ensure that you double-check any releases created by Releasy before publishing them!


Features and Limitations
------------

### Features

* Package up Ruby applications (Games, GUI applications, etc.) for non-ruby users.
* Build OS X application bundle (.app) on any platform.
* Build Windows executable (.exe) on any platform.
* Build Windows installer (Windows only).
* Build, package (compress) and deploy your executables for all platforms from a single rake command ('rake deploy').

### Limitations

* Building Windows executable on non-Windows systems will not work with compiled gems that aren't published as pre-compiled for Windows (_i386-mingw_ or _x86-mingw_).
* Building OS X apps on non-OS X systems will not currently work with compiled gems at all (other than Gosu, Chipmunk & TexPlay).
* One or more external applications need to be installed, separate to the Releasy gem (see below for details).
* :windows_wrapped executable with Ruby 1.8.7, 1.9.2 and 1.9.3 only.
* :osx_app executable with Ruby 1.9.2 only.
* Your main executable file couldn't be name "main.rb".
* In your Gemfile, put releasy in the development group to avoid loading it in the distribute app :

```ruby
group :development do
  gem "releasy"
end
```

* In the Rakefile, don't include unneeded gems (like Gosu or Chingu) :

```ruby
require 'bundler'
Bundler.require :development
```

* You shouldn't load bundler on production. Use this code to avoid it :

```ruby
require 'bundler/setup' unless defined?(OSX_EXECUTABLE) or ENV['OCRA_EXECUTABLE']
# Require your gems after this line.
```


Installation
------------

    gem install releasy


Example
-------

### Project's Rakefile

```ruby
require 'bundler'
Bundler.require :development
# Only require Releasy, since we don't need to load
# include unneeded gems like Gosu/Chingu at this point.

Releasy::Project.new do
  name "My Application"
  version "1.3.2"
  verbose # Can be removed if you don't want to see all build messages.

  executable "bin/my_application.rb"
  files [
    "lib/**/*.rb",
    "config/**/*.yml",
    "media/**/*.*"
    ]
  exposed_files "README.html", "LICENSE.txt"
  add_link "http://my_application.github.com", "My Application website"
  exclude_encoding # Applications that don't use advanced encoding (e.g. Japanese characters) can save build size with this.

  # Create a variety of releases, for all platforms.
  add_build :osx_app do
    url "com.github.my_application"
    wrapper "wrappers/gosu-mac-wrapper-0.7.41.tar.gz" # Assuming this is where you downloaded this file.
    icon "media/icon.icns"
    add_package :tar_gz
  end

  add_build :source do
    add_package :"7z"
  end

  # If building on a Windows machine, :windows_folder and/or :windows_installer are recommended.
  add_build :windows_folder do
    icon "media/icon.ico"
    executable_type :windows # Assuming you don't want it to run with a console window.
    add_package :exe # Windows self-extracting archive.
  end

  add_build :windows_installer do
    icon "media/icon.ico"
    start_menu_group "Spooner Games"
    readme "README.html" # User asked if they want to view readme after install.
    license "LICENSE.txt" # User asked to read this and confirm before installing.
    executable_type :windows # Assuming you don't want it to run with a console window.
    add_package :zip
  end

  # If unable to build on a Windows machine, :windows_wrapped is the only choice.
  add_build :windows_wrapped do
    wrapper "wrappers/ruby-1.9.3-p0-i386-mingw32.7z" # Assuming this is where you downloaded this file.
    executable_type :windows # Assuming you don't want it to run with a console window.
    exclude_tcl_tk # Assuming application doesn't use Tcl/Tk, then it can save a lot of size by using this.
    add_package :zip
  end

  add_deploy :github # Upload to a github project.
end
#>>>
```

### Tasks created

Note: The `windows:folder`, `windows:installer` and `windows:standalone` will be created only if running on Windows.
The `windows:wrapped` task will not be created if running on Windows.

The output from "rake -T" on Windows would be:

    rake build                                # Build My Application 1.3.2
    rake build:osx                            # Build all osx
    rake build:osx:app                        # Build OS X app
    rake build:source                         # Build source
    rake build:windows                        # Build all windows
    rake build:windows:folder                 # Build windows folder
    rake build:windows:installer              # Build windows installer
    rake deploy                               # Deploy My Application 1.3.2
    rake deploy:osx:app:tar_gz:github         # github <= osx app .tar.gz
    rake deploy:source:7z:github              # github <= source .7z
    rake deploy:windows:folder:exe:github     # github <= windows folder .exe
    rake deploy:windows:installer:zip:github  # github <= windows installer .zip
    rake package                              # Package My Application 1.3.2
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

### 7-Zip

The [7z](http://www.7-zip.org) command must be installed on your system for Releasy to work:

  * OS X homebrew:

    <pre>brew install p7zip</pre>

  * Ubuntu/Debian:

    <pre>sudo apt-get install p7zip-full</pre>

  * Windows

    - 32-bit

      * 7z 32-bit executable included in gem.

    - 64-bit

      * 7z 32-bit executable included in gem, which will work fine.
      * If compression/decompression speed is really important to you, install the 64-bit .msi version of [7-Zip](http://www.7-zip.org/download.html)

  * Other OS

    - [Download 7-Zip](http://www.7-zip.org/download.html)

### To build `:windows_installer` release (Windows only)

[InnoSetup](http://www.jrsoftware.org/isdl.php) is used to create an installer for the application.

### To build `:windows_wrapped` release (OS X/Linux)

[RubyInstaller 7-ZIP archives](http://rubyinstaller.org/downloads/) for Ruby 1.8.7, 1.9.2 or 1.9.3. Used as a wrapper for a Windows release built on non-Windows systems.

### To build `:osx_app` application bundle release (any platform)

[libgosu app wrapper](http://www.libgosu.org/downloads/). Latest version of the OS X-compatible wrapper is "gosu-mac-wrapper-0.7.44.tar.gz" which uses Ruby 1.9.2 and includes some binary gems: Gosu, Chipmunk and TexPlay.

Warning: "gosu-mac-0.7.44.tar.gz" is NOT the complete OS X app wrapper, but rather just the Gosu gem pre-compiled for OS X!

Similar tools
-------------

* [Ocra](https://github.com/larsch/ocra): Builds standalone Windows executable or a Windows installer. Releasy uses Ocra, but greatly extends its capabilities.
  - Advantages: Creating a standalone executable requires just a simple command.
  - Disadvantages: Can't build except on Windows; standalone executable slow to load; more difficult to create an installer.

* [Crate](https://github.com/copiousfreetime/crate): Cross-platform executable builder.
  - Advantages: Probably faster to load, since all source files are stored in an SQLite database; works _anywhere_ Ruby can be compiled.
  - Disadvantages: Requires C compiler; not compatible with Ruby 1.9; may not be supported any more.

* [exerb-mingw](https://github.com/snaury/exerb-mingw/)
  - Advantages: Unsure.
  - Disadvantages: Unsure; no English documentation; may not be supported any more.

* [rubyscript2exe](http://www.erikveen.dds.nl/rubyscript2exe/): Builds a standalone Windows executable.
  - Advantages: None.
  - Disadvantages: Not compatible with Ruby 1.9; may not be supported any more.

Credits
-------

* Thanks to jlnr for creating "RubyGosu App.app", an OS X application bundle used to wrap application code.
* Thanks to larsh for the [Ocra gem](http://ocra.rubyforge.org/), which is used for generating Win32 executables.
* Thanks to jlnr, SukiSan and shawn42 for help testing on OS X; without you I would have been screwed!
* Thanks to shawn42 and everyone at #gosu and #ruby (irc.freenode.org) for suggestions on how to improve the API.
* Thanks to kyrylo for coming up with the name, Releasy!

Third Party Assets included
---------------------------

* bin/7z.sfx - Windows [7-ZIP](http://www.7-zip.org) self-extractor module, which can be installed using `releasy install-sfx` [License: [GNU LGPL](http://www.7-zip.org/license.txt)]
* bin/7za.exe - Windows [7-ZIP](http://www.7-zip.org) CLI executable.
