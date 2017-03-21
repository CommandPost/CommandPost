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
local log										= require("hs.logger").new("welcome")

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

	function generateContent()
		return "The Shortcut Manager is currently under construction."
	end

	function mod.init(deps)

		local id 		= "shorcuts"
		local label 	= "Shortcuts"
		local image		= image.imageFromPath("/System/Library/PreferencePanes/Keyboard.prefPane/Contents/Resources/Keyboard.icns")
		local priority	= 2
		local tooltip	= "Shortcuts Panel"
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