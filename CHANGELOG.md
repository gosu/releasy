Releasy Change Log
==================

v0.2.1
------

  * Added new deployers: :rsync and :local
  * Removed 7z installation dependency on Windows (included 7za.exe in gem).
  * Fixes for Ruby 1.8.7

v0.2.0
------

  * Name changed from "relapse" to "releasy" because of universal dislike and/or confusion about it :)
  * Warning: API changed significantly from v0.1.0 because it was dreadful :D
  * Allowed outputs to be configured separately from the project.
  * Included gems in osx-app more safely, so that no files will be missing.
  * Added `:exe` archive format (Windows self-extractor, used on any OS).
  * Added `:dmg` archive format (OS X self-extractor, used on OS X only).
  * Added `:windows_wrapped` output (windows folder made from a RubyInstaller archive, used on OSX/Linux).
  * Allowed project and outputs to have archive formats (when called on Project, affecting all outputs).
  * Archive formats can have a different `#extension` set.
  * Output formats can have a different `#folder_suffix` set.
  * No longer require Innosetup to be installed in order to create `:windows_folder` output.
  * Added command, 'releasy install-sfx' that installs the self-extractor package for 7z, to enable :exe archiving (non-Windows only).
  * Lots of other things fixes, refactors and additions, that I lost track of :$

v0.1.0
------

  * First public release as "relapse"