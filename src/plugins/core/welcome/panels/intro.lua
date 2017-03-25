--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--             G E N E R A L    P R E F E R E N C E S    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plugins.core.preferences.panels.general ===
---
--- General Preferences Panel

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsGeneral")

local image										= require("hs.image")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local webview									= require("hs.webview")

local config									= require("cp.config")
local generate									= require("cp.web.generate")
local template									= require("cp.template")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local DEFAULT_PRIORITY 							= 0

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	--------------------------------------------------------------------------------
	-- CONTROLLER CALLBACK:
	--------------------------------------------------------------------------------
	local function controllerCallback(message)

		log.df("Callback Result: %s", hs.inspect(message))

	end

	--------------------------------------------------------------------------------
	-- GENERATE CONTENT:
	--------------------------------------------------------------------------------
	local function generateContent()

		local env = template.defaultEnv()

		env.i18n = i18n
		env.scriptName = config.scriptName

		return template.compileFile(config.pluginPath .. "core/welcome/html/intro.htm", env)

	end

	--------------------------------------------------------------------------------
	-- INITIALISE MODULE:
	--------------------------------------------------------------------------------
	function mod.init(deps)

		local id 			= "intro"
		local priority		= 1
		local contentFn		= generateContent
		local callbackFn 	= controllerCallback

		deps.manager.addPanel(id, priority, contentFn, callbackFn)

		return mod

	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.welcome.panels.intro",
	group			= "core",
	dependencies	= {
		["core.welcome.manager"]	= "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	return mod.init(deps)
end

return plugin