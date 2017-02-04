# CommandPost

CommandPost (previously [FCPX Hacks](https://latenitefilms.com/blog/final-cut-pro-hacks/)) is a collection of free and open source [Lua](https://www.lua.org/about.html) scripts that are included in a [Hammerspoon](http://www.hammerspoon.org) fork as a standalone application that adds a mountain-load of new professional features to Apple's [Final Cut Pro](http://apple.com/final-cut-pro/).

FCPX Hacks was originally created by Chris Hocking. CommandPost is now developed by [Chris Hocking](https://latenitefilms.com/team/) & [David Peterson](https://randombits.org).

You can learn about FCPX Hack's origin story on the [LateNite Films Blog](https://latenitefilms.com/blog/final-cut-pro-hacks/).

Check how many people have downloaded FCPX Hacks & CommandPost [here](http://www.somsubhra.com/github-release-stats/?username=CommandPost&repository=CommandPost).

## User Installation:

Download the latest release [here](https://github.com/CommandPost/CommandPost/releases/latest).

## Developer Installation:

CommandPost is made up of two seperate components - the [standalone app](https://github.com/CommandPost/CommandPost-App), and [Lua](https://www.lua.org/about.html) scripts contained within this repository.

To install, first download or clone then build the [standalone app](https://github.com/CommandPost/CommandPost-App).

Then download or clone this repository. You can either link the `~/CommandPost` directory to the `src` directory, or copy the contents of `src` into said directory.

### Option 1: Link

1. Open a Terminal window.
2. Navigate to the CommandPost project root directory.
3. Execute `./scripts/link-cp`

### Option 2: Copy

1. Open a Terminal window.
2. Navigate to the CommandPost project root directory.
2. Execute `./scripts/install-cp`
