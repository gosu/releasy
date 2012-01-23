Relapse Change Log
==================

v0.2.0
------

  * Warning: API changed significantly from v0.1.0 because it was dreadful :D
  * Allowed outputs to be configured separately from the project.
  * Included gems in osx-app more safely, so that no files will be missing.
  * Added `:exe` archive format (Windows self-extractor, used on any OS).
  * Added `:windows_folder_from_ruby_dist` output (windows folder made from a RubyInstaller archive, used on OSX/Linux).
  * Allowed project and outputs to have archive formats (when called on Project, affecting all outputs).
  * Archive formats can have a different `#extension` set.
  * Output formats can have a different `#folder_suffix` set.
  * No longer require Innosetup to be installed in order to create `:windows_folder` output.
  * Added command, 'relapse install-sfx' that installs the self-extractor package for 7z, to enable :exe archiving (non-Windows only).
  * Lots of other things fixes, refactors and additions, that I lost track of :$

v0.1.0
------

  * First public release