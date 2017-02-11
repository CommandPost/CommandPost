# CommandPost

CommandPost (previously [FCPX Hacks](https://latenitefilms.com/blog/final-cut-pro-hacks/)) is a collection of free and open source [Lua](https://www.lua.org/about.html) scripts that are included in a [Hammerspoon](http://www.hammerspoon.org) fork as a standalone application that adds a mountain-load of new professional features to Apple's [Final Cut Pro](http://apple.com/final-cut-pro/).

FCPX Hacks was originally created by Chris Hocking. CommandPost is now developed by [Chris Hocking](https://latenitefilms.com/team/) & [David Peterson](https://randombits.org).

You can learn about FCPX Hack's origin story on the [LateNite Films Blog](https://latenitefilms.com/blog/final-cut-pro-hacks/).

Check how many people have downloaded FCPX Hacks & CommandPost [here](http://www.somsubhra.com/github-release-stats/?username=CommandPost&repository=CommandPost).

## User Installation:

Download the latest release [here](https://github.com/CommandPost/CommandPost/releases/latest).

## Developer Installation:

CommandPost is made up of two seperate components - the [standalone app](https://github.com/CommandPost/CommandPost-App) (which is a fork of [Hammerspoon](http://www.hammerspoon.org)), and the [Lua](https://www.lua.org/about.html) scripts contained within this repository.

To build your own version of CommandPost, first download or clone this repository. You can then either link the `~/CommandPost` directory to the GitHub `src` directory, or copy the contents of GitHub `src` into said directory.

### Option 1: Link

1. Open a Terminal window.
2. Navigate to the CommandPost project root directory.
3. Execute `./scripts/link-cp`

### Option 2: Copy

1. Open a Terminal window.
2. Navigate to the CommandPost project root directory.
2. Execute `./scripts/install-cp`

Next download or clone, then build the [standalone app](https://github.com/CommandPost/CommandPost-App):

1. Create a self-signed Code Signing certificate named **Internal Code Signing** as explained [here](http://bd808.com/blog/2013/10/21/creating-a-self-signed-code-certificate-for-xcode/) - however, please make sure you label the certificate "Internal Code Signing" and not "Self-signed Applications".
2. Open a Terminal window.
3. Navigate to the CommandPost-App project root directory.
4. Install `pip` by following [these instructions](https://packaging.python.org/installing/#install-pip-setuptools-and-wheel).
5. Execute `pip install -r requirements.txt`
4. Execute `./scripts/build_commandpost.sh`

On load, the standalone app will try to load `~/CommandPost/init.lua` first, and if that fails, it will then load the Lua scripts within the Application Bundle. This means you can keep developing by modifying the files within `~/CommandPost`, and then when you're done, simply execute `./scripts/build_commandpost.sh` again for distribution.

