local mod = {}

local settings			= require("hs.settings")
local application		= require("hs.application")
local window			= require("hs.window")

-------------------------------------------------------------------------------
-- CONSTANTS:
-------------------------------------------------------------------------------

mod.scriptName			= "CommandPost"
mod.settingsPrefix		= "cp"
mod.scriptVersion       = "0.79"
mod.bugReportEmail      = "chris@latenitefilms.com"
mod.checkUpdateURL      = "https://api.github.com/repos/CommandPost/CommandPost/releases/latest"

if hs.hasinitfile then
	-------------------------------------------------------------------------------
	-- Use assets in ~/CommandPost directory:
	-------------------------------------------------------------------------------
	mod.scriptPath			= os.getenv("HOME") .. "/CommandPost/"
	mod.assetsPath			= mod.scriptPath .. "/cp/resources/assets/"
else
	-------------------------------------------------------------------------------
	-- Use assets within the Application Bundle:
	-------------------------------------------------------------------------------
	mod.scriptPath			= hs.processInfo["resourcePath"] .. "/extensions/"
	mod.assetsPath			= mod.scriptPath .. "/cp/resources/assets/"
end

mod.iconPath            = mod.assetsPath .. "CommandPost.icns"
mod.menubarIconPath     = mod.assetsPath .. "CommandPost.png"

mod.languagePath		= mod.scriptPath .. "/cp/resources/languages/"

mod.bundleID			= hs.processInfo["bundleID"]
mod.processID			= hs.processInfo["processID"]

function mod.application()
	if not mod._application then
		mod._application = application.applicationForPID(mod.processID)
	end
	return mod._application
end

function mod.isFrontmost()
	local app = mod.application()
	local fw = window.focusedWindow()

	return fw ~= nil and fw:application() == app
end

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
