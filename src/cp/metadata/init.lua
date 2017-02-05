local mod = {}

local settings			= require("hs.settings")

local bundleID 			= hs.processInfo["bundleID"]
local configdir			= hs.configdir
local resourcePath		= hs.processInfo["resourcePath"]

-------------------------------------------------------------------------------
-- CONSTANTS:
-------------------------------------------------------------------------------
mod.scriptName			= "CommandPost"
mod.settingsPrefix		= "cp"
mod.scriptVersion       = "0.79"
mod.bugReportEmail      = "chris@latenitefilms.com"
mod.developerURL        = "https://latenitefilms.com/blog/final-cut-pro-hacks/"
mod.updateURL           = "https://latenitefilms.com/blog/final-cut-pro-hacks/#download"
mod.checkUpdateURL      = "https://latenitefilms.com/downloads/fcpx-hammerspoon-version.html"

if bundleID == "org.hammerspoon.Hammerspoon" then
	mod.scriptPath			= configdir
	mod.assetsPath			= configdir .. "/cp/resources/assets/"
	mod.iconPath            = mod.assetsPath .. "CommandPost.icns"
	mod.menubarIconPath     = mod.assetsPath .. "CommandPost.png"
else
	mod.scriptPath			= resourcePath .. "/extensions/"
	mod.assetsPath			= resourcePath .. "/cp/resources/assets/"
	mod.iconPath            = mod.assetsPath .. "CommandPost.icns"
	mod.menubarIconPath     = mod.assetsPath .. "CommandPost.png"
end

mod.languagePath			= mod.scriptPath .. "/cp/resources/languages/"

-------------------------------------------------------------------------------
-- Settings
-------------------------------------------------------------------------------

function mod.get(key, defaultValue)
	local value = settings.get(mod.settingsPrefix .. "." .. key)
	if value == nil then
		value = defaultValue
	end
	return value
end

function mod.set(key, value)
	return settings.set(mod.settingsPrefix .. "." .. key, value)
end

function mod.reset()
	for i, v in ipairs(settings.getKeys()) do
		if (v:sub(1,string.len(mod.settingsPrefix .. "."))) == mod.settingsPrefix .. "." then
			settings.set(v, nil)
		end
	end
end

-------------------------------------------------------------------------------

return mod