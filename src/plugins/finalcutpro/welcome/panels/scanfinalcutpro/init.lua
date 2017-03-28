--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--             S C A N    F I N A L    C U T    P R O    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === finalcutpro.welcome.panels.scanfinalcutpro  ===
---
--- Scan Final Cut Pro Panel Welcome Screen.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("scanfinalcutpro")

local timer										= require("hs.timer")

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
		if result == "scanQuit" then
			config.application():kill()
		elseif result == "scanSkip" then
			mod.manager.nextPanel(mod._priority)
		elseif result == "scanFinalCutPro" then
			local scanResult = mod.scanfinalcutpro.scanFinalCutPro()
			if scanResult then
				mod.manager.nextPanel(mod._priority)
			end
			timer.doAfter(0.1, function() mod.manager.webview:hswindow():focus() end)
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
			log.ef("Error while generating Accessibility Welcome Panel: %", err)
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

		mod._id 			= "scanfinalcutpro"
		mod._priority		= 40
		mod._contentFn		= generateContent
		mod._callbackFn 	= controllerCallback

		mod.manager = deps.manager
		mod.scanfinalcutpro = deps.scanfinalcutproPrefs

		mod.manager.addPanel(mod._id, mod._priority, mod._contentFn, mod._callbackFn)
		
		mod.renderPanel = env:compileTemplate("html/panel.html")
		mod.iconPath = env:pathToAbsolute("html/fcp_icon.png")

		return mod

	end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.welcome.panels.scanfinalcutpro",
	group			= "finalcutpro",
	dependencies	= {
		["core.welcome.manager"]					= "manager",
		["finalcutpro.preferences.scanfinalcutpro"] = "scanfinalcutproPrefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	return mod.init(deps, env)
end

return plugin