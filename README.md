# FCPX Hacks

FCPX Hacks is a free and open source [Hammerspoon](http://www.hammerspoon.org) script that adds a mountain-load of new features to Final Cut Pro.

You can learn about it's origin story, as well as explore its full feature list on the [LateNite Films Blog](https://latenitefilms.com/blog/final-cut-pro-hacks/).

## Installing

To install, you can either link the `~/.hammerspoon` directory to the `src` directory, or copy the contents of `src` into said directory.

### Option 1: Link

1. Open a Terminal window.
2. Navigate to the FCPX Hacks project root directory.
3. Execute `./link-hs`

### Option 2: Copy

1. Open a Terminal window.
2. Navigate to the FCPX Hacks project root directory.
2. Execute `./install-hs`

## Building the Distribution DMG

1. Open a Terminal window
2. If not already done, install [dmgbuild](https://dmgbuild.readthedocs.io/en/latest/index.html):
`easy_install dmgbuild`
3. Run the build script: `./make-dmg`

A DMG file will be created in `build/FCPXHacks.dmg`
