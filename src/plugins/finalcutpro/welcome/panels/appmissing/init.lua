--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      C O M P L E T I O N    P A N E L                      --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.welcome.panels.appmissing  ===
---
--- Final Cut Pro Missing Panel.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("intro")

local config									= require("cp.config")
local generate									= require("cp.web.generate")
local fcp										= require("cp.apple.finalcutpro")

local v											= require("semver")

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
	if result == "fcpxQuit" then
		config.application():kill()
	elseif result == "fcpxMissingContinue" then
		mod.manager.nextPanel(mod._id)
	end

end

--------------------------------------------------------------------------------
-- GENERATE CONTENT:
--------------------------------------------------------------------------------
local function generateContent()

	generate.setWebviewLabel(mod.webviewLabel)

	local env = {
		generate 	= generate,
		iconPath	= mod.iconPath,
		version		= fcp.EARLIEST_SUPPORTED_VERSION,
	}

	local result, err = mod.renderPanel(env)
	if err then
		log.ef("Error while generating FCP Is Missing Welcome Panel: %", err)
		return err
	else
		return result, mod.panelBaseURL
	end
end

--------------------------------------------------------------------------------
-- PANEL ENABLED:
--------------------------------------------------------------------------------
local function panelEnabled()
	local result = fcp:isInstalled()
	return not result and not mod.manager.welcomeComplete()
end

--------------------------------------------------------------------------------
-- INITIALISE MODULE:
--------------------------------------------------------------------------------
function mod.init(deps, env)

	mod.webviewLabel = deps.manager.getLabel()
	mod.manager = deps.manager

	mod.renderPanel = env:compileTemplate("html/panel.html")
	mod.iconPath = env:pathToAbsolute("html/commandpost_icon.png")

	local id 			= "appmissing"
	mod._priority		= 5
	local contentFn		= generateContent
	local callbackFn 	= controllerCallback
	local enabledFn		= panelEnabled

	mod.manager.addPanel(id, mod._priority, contentFn, callbackFn, enabledFn)

	return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.welcome.panels.app.missing",
	group			= "finalcutpro",
	dependencies	= {
		["core.welcome.manager"]					= "welcome",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	-- return mod.init(deps, env)
end

return plugin