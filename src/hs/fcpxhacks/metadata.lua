local mod = {}

local bundleID 			= hs.processInfo["bundleID"]
local configdir			= hs.configdir
local resourcePath		= hs.processInfo["resourcePath"]

-------------------------------------------------------------------------------
-- CONSTANTS:
-------------------------------------------------------------------------------
mod.scriptName			= "CommandPost"
mod.scriptVersion       = "0.79"
mod.bugReportEmail      = "chris@latenitefilms.com"
mod.developerURL        = "https://latenitefilms.com/blog/final-cut-pro-hacks/"
mod.updateURL           = "https://latenitefilms.com/blog/final-cut-pro-hacks/#download"
mod.checkUpdateURL      = "https://latenitefilms.com/downloads/fcpx-hammerspoon-version.html"

if bundleID == "org.hammerspoon.Hammerspoon" then
	mod.scriptPath			= configdir
	mod.assetsPath			= configdir .. "/hs/fcpxhacks/assets/"
	mod.iconPath            = mod.assetsPath .. "CommandPost.icns"
	mod.menubarIconPath     = mod.assetsPath .. "CommandPost.png"
else
	mod.scriptPath			= resourcePath .. "/extensions/"
	mod.assetsPath			= resourcePath .. "/hs/fcpxhacks/assets/"
	mod.iconPath            = mod.assetsPath .. "CommandPost.icns"
	mod.menubarIconPath     = mod.assetsPath .. "CommandPost.png"
end
-------------------------------------------------------------------------------

return mod