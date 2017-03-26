--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                  C O N F I G U R A T I O N    M O D U L E                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.config ===
---
--- Manage CommandPost's constants and settings.

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local application		= require("hs.application")
local fs				= require("hs.fs")
local settings			= require("hs.settings")
local window			= require("hs.window")

-------------------------------------------------------------------------------
-- THE MODULE:
-------------------------------------------------------------------------------
local mod = {}

--- cp.config.scriptName
--- Constant
--- The name of the Application
mod.scriptName			= "CommandPost"

--- cp.config.configPrefix
--- Constant
--- Prefix used for Configuration Settings
mod.configPrefix		= "cp"

--- cp.config.scriptVersion
--- Constant
--- Prefix used for Configuration Settings
mod.scriptVersion       = hs.processInfo["version"]

--- cp.config.bugReportEmail
--- Constant
--- Email address used for bug reports
mod.bugReportEmail      = "chris@latenitefilms.com"

--- cp.config.checkUpdateURL
--- Constant
--- URL used for checking Application Updates
mod.checkUpdateURL      = "https://api.github.com/repos/CommandPost/CommandPost/releases/latest"

--- cp.config.scriptPath
--- Constant
--- Path to where Application Scripts are stored

--- cp.config.assetsPath
--- Constant
--- Path to where Application Assets are stored
if fs.pathToAbsolute(hs.configdir .. "/cp/init.lua") then
	-------------------------------------------------------------------------------
	-- Use assets in either the Developer or User Library directory:
	-------------------------------------------------------------------------------
	mod.scriptPath			= hs.configdir
else
	-------------------------------------------------------------------------------
	-- Use assets within the Application Bundle:
	-------------------------------------------------------------------------------
	mod.scriptPath			= hs.processInfo["resourcePath"] .. "/extensions"
end

mod.assetsPath			= mod.scriptPath .. "/cp/resources/assets/"

--- cp.config.basePath
--- Constant
--- Path to where the Extensions & Plugins folders are stored.
mod.basePath = fs.pathToAbsolute(mod.scriptPath .. "/..")

--- cp.config.bundledPluginsPath
--- Constant
--- The path to bundled plugins
mod.bundledPluginsPath	= mod.basePath .. "/plugins"

--- cp.config.userPluginsPath
--- Constant
--- The path to user plugins
mod.userPluginsPath		= os.getenv("HOME") .. "/Library/Application Support/CommandPost/Plugins"

--- cp.config.pluginPaths
--- Constant
--- Table of Plugins Paths. Earlier entries take precedence.
mod.pluginPaths			= {
	mod.userPluginsPath,
	mod.bundledPluginsPath,
}


--- cp.config.iconPath
--- Constant
--- Path to the Application Icon
mod.iconPath            = mod.assetsPath .. "CommandPost.icns"

--- cp.config.menubarIconPath
--- Constant
--- Path to the Menubar Application Icon
mod.menubarIconPath     = mod.assetsPath .. "CommandPost.png"

--- cp.config.languagePath
--- Constant
--- Path to the Languages Folder
mod.languagePath		= mod.scriptPath .. "/cp/resources/languages/"

--- cp.config.bundleID
--- Constant
--- Application's Bundle ID
mod.bundleID			= hs.processInfo["bundleID"]

--- cp.config.processID
--- Constant
--- Application's Process ID
mod.processID			= hs.processInfo["processID"]

--- cp.config.application() -> hs.application object
--- Function
--- Returns the Application as a hs.application object
---
--- Parameters:
---  * None
---
--- Returns:
---  * hs.application object
function mod.application()
	if not mod._application then
		mod._application = application.applicationForPID(mod.processID)
	end
	return mod._application
end

--- cp.config.isFrontmost() -> boolean
--- Function
--- Returns whether or not the Application is front most
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if Application is front most otherwise `false`
function mod.isFrontmost()
	local app = mod.application()
	local fw = window.focusedWindow()

	return fw ~= nil and fw:application() == app
end

--- cp.config.get() -> string or boolean or number or nil or table or binary data
--- Function
--- Loads a setting
---
--- Parameters:
---  * key - A string containing the name of the setting
---  * defaultValue - A default value if the setting doesn't already exist
---
--- Returns:
---  * The value of the setting
function mod.get(key, defaultValue)
	local value = settings.get(mod.configPrefix .. "." .. key)
	if value == nil then
		value = defaultValue
	end
	return value
end

--- cp.config.set(key, value)
--- Function
--- Saves a setting with common datatypes
---
--- Parameters:
---  * key - A string containing the name of the setting
---  * val - An optional value for the setting. Valid datatypes are:
---    * string
---    * number
---    * boolean
---    * nil
---    * table (which may contain any of the same valid datatypes)
---  * if no value is provided, it is assumed to be nil
---
--- Returns:
---  * None
---
--- Notes:
---  * This function cannot set dates or raw data types
function mod.set(key, value)
	return settings.set(mod.configPrefix .. "." .. key, value)
end

--- cp.config.reset()
--- Function
--- Resets all the settings for the Application
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.reset()
	for i, v in ipairs(settings.getKeys()) do
		if (v:sub(1,string.len(mod.configPrefix .. "."))) == mod.configPrefix .. "." then
			settings.set(v, nil)
		end
	end
end

return mod
