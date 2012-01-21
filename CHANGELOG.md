Relapse Change Log
==================

v0.2.0
------

  * Warning: API changed significantly from v0.1.0 because it was dreadful :D
  * Allowed outputs to be configured separately from the project.
  * Included gems in osx-app more safely, so that no files will be missing.
  * Added `:exe` archive format (Windows self-extractor, used on any OS).
  * Added `:windows_folder_from_wrapper` output (windows folder made from a pre-made wrapper, used on OSX/Linux).
  * '`relapse windows_wrapper`' command can create a Windows wrapper (created on windows to be used to generate the `:windows_folder_from_wrapper` output on non-Windows OSes).
  * `:windows_folder_from_wrapper` output now pulls Windows pre-compiled binary gems from rubygems rather than needing them in the wrapper.
  * Allowed project and outputs to have archive formats (when called on Project, affecting all outputs).
  * Archive formats can have a different `#extension` set.
  * Output formats can have a different `#folder_suffix` set.
  * No longer require Innosetup to be installed in order to create `:windows_folder` output.
  * Lots of other things fixes, refactors and additions, that I lost track of :$

v0.1.0
------

  * First public release