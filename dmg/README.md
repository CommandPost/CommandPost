# Distribution DMG Resources

This folder contains resources used to build the Distribution DMG. Key files of interest:

* `1. Install Hammerspoon` - a simple webloc link to the Hammerspoon website.
* `2. Install FCPX Hacks` - An AppleScript application that copies the FCPX Hacks files into the user's home directory.
* `background.psd` - Contains the DMG background. This needs to be exported into the `background-assets` folder as two files: `background.png` (larger, at 1x) and `background@2x.png`, which is half the size.
* `license.txt` - The text file used in the DMG license preamble.
* `licenseDMG.py` - The script which signs/adds the licensing text to the DMG.
* `settings.py` - Used to configure the details of the DMG.

See also the `make-dmg` script in the root directory of the project.