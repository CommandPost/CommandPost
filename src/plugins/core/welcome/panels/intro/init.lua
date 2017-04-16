--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                           I N T R O   P A N E L                            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.welcome.panels.intro  ===
---
--- Intro Panel Welcome Screen.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("intro")

local toolbar                  					= require("hs.webview.toolbar")
local webview									= require("hs.webview")

local config									= require("cp.config")
local generate									= require("cp.web.generate")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- CONTROLLER CALLBACK:
--------------------------------------------------------------------------------
local function controllerCallback(message)

	local result = message["body"][1]

	if result == "introQuit" then
		config.application():kill()
	elseif result == "introContinue" then
		mod.manager.nextPanel(mod._priority)
	end

end

--------------------------------------------------------------------------------
-- GENERATE CONTENT:
--------------------------------------------------------------------------------
local function generateContent()

	generate.setWebviewLabel(mod.webviewLabel)

	local env = {
		appName		= config.appName,
		generate 	= generate,
		iconPath	= mod.iconPath,
	}

	local result, err = mod.renderPanel(env)
	if err then
		log.ef("Error while generating Intro Welcome Panel: %", err)
		return err
	else
		return result, mod.panelBaseURL
	end

end

--------------------------------------------------------------------------------
-- INITIALISE MODULE:
--------------------------------------------------------------------------------
function mod.init(deps, env)
	mod.webviewLabel = deps.manager.getLabel()

	mod._id 			= "intro"
	mod._priority		= 20
	mod._contentFn		= generateContent
	mod._callbackFn 	= controllerCallback

	mod.manager = deps.manager

	mod.manager.addPanel(mod._id, mod._priority, mod._contentFn, mod._callbackFn)

	mod.renderPanel = env:compileTemplate("html/panel.html")
	mod.iconPath = env:pathToAbsolute("html/commandpost_icon.png")

	return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
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
function plugin.init(deps, env)
	return mod.init(deps, env)
end

return plugin