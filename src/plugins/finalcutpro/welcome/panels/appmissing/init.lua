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
local fcp										= require("cp.finalcutpro")

local semver									= require("semver")

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
-- INITIALISE MODULE:
--------------------------------------------------------------------------------
function mod.init(deps, env)

	--------------------------------------------------------------------------------
	-- Check Final Cut Pro Version:
	--------------------------------------------------------------------------------
	local fcpVersion = fcp:getVersion()
	if fcpVersion:sub(1,4) ~= "10.3" then

		mod.webviewLabel = deps.manager.getLabel()

		mod._id 			= "complete"
		mod._priority		= 1
		mod._contentFn		= generateContent
		mod._callbackFn 	= controllerCallback

		mod.manager = deps.manager

		mod.manager.addPanel(mod._id, mod._priority, mod._contentFn, mod._callbackFn)

		mod.renderPanel = env:compileTemplate("html/panel.html")
		mod.iconPath = env:pathToAbsolute("html/commandpost_icon.png")

	end

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
		["core.welcome.manager"]					= "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	return mod.init(deps, env)
end

return plugin