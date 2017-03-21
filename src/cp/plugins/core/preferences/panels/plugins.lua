--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--            P L U G I N S    P R E F E R E N C E S    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plugins.core.preferences.panels.plugins ===
---
--- Plugins Preferences Panel

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsPlugin")

local application								= require("hs.application")
local base64									= require("hs.base64")
local console									= require("hs.console")
local drawing									= require("hs.drawing")
local geometry									= require("hs.geometry")
local screen									= require("hs.screen")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local urlevent									= require("hs.urlevent")
local webview									= require("hs.webview")

local image										= require("hs.image")

local dialog									= require("cp.dialog")
local fcp										= require("cp.finalcutpro")
local metadata									= require("cp.metadata")
local plugins									= require("cp.plugins")
local template									= require("cp.template")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	local function generateContent()
		return "The Plugin Manager is currently under construction."
	end

	function mod.init(deps)

		local id 		= "plugins"
		local label 	= "Plugins"
		local image		= image.imageFromPath("/System/Library/PreferencePanes/Extensions.prefPane/Contents/Resources/Extensions.icns")
		local priority	= 3
		local tooltip	= "Plugins Panel"
		local contentFn	= generateContent

		deps.manager.addPanel(id, label, image, priority, tooltip, contentFn)

	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.core.preferences.manager"]			= "manager",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)
		return mod.init(deps)
	end

return plugin