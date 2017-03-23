--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     M E T A D A T A    M O D U L E                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local application		= require("hs.application")
local settings			= require("hs.settings")
local window			= require("hs.window")

-------------------------------------------------------------------------------
-- THE MODULE:
-------------------------------------------------------------------------------
local mod = {}

	-------------------------------------------------------------------------------
	-- VARIABLES:
	-------------------------------------------------------------------------------
	mod.scriptName			= "CommandPost"
	mod.settingsPrefix		= "cp"
	mod.scriptVersion       = "0.79"
	mod.bugReportEmail      = "chris@latenitefilms.com"
	mod.checkUpdateURL      = "https://api.github.com/repos/CommandPost/CommandPost/releases/latest"

	mod.pluginPaths			= {"cp.plugins", "plugins"}
	mod.customPluginPath	= "~/CommandPost/plugins"

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

	-------------------------------------------------------------------------------
	-- RETURNS COMMANDPOST APPLICATION:
	-------------------------------------------------------------------------------
	function mod.application()
		if not mod._application then
			mod._application = application.applicationForPID(mod.processID)
		end
		return mod._application
	end

	-------------------------------------------------------------------------------
	-- IS COMMANDPOST FRONTMOST:
	-------------------------------------------------------------------------------
	function mod.isFrontmost()
		local app = mod.application()
		local fw = window.focusedWindow()

		return fw ~= nil and fw:application() == app
	end

	-------------------------------------------------------------------------------
	-- GET SETTINGS:
	-------------------------------------------------------------------------------
	function mod.get(key, defaultValue)
		local value = settings.get(mod.settingsPrefix .. "." .. key)
		if value == nil then
			value = defaultValue
		end
		return value
	end

	-------------------------------------------------------------------------------
	-- SET SETTINGS:
	-------------------------------------------------------------------------------
	function mod.set(key, value)
		return settings.set(mod.settingsPrefix .. "." .. key, value)
	end

	-------------------------------------------------------------------------------
	-- RESET SETTINGS:
	-------------------------------------------------------------------------------
	function mod.reset()
		for i, v in ipairs(settings.getKeys()) do
			if (v:sub(1,string.len(mod.settingsPrefix .. "."))) == mod.settingsPrefix .. "." then
				settings.set(v, nil)
			end
		end
	end

return mod
