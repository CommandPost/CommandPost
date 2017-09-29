--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.console ===
---
--- CommandPost Console

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local chooser			= require("hs.chooser")
local drawing 			= require("hs.drawing")
local fnutils 			= require("hs.fnutils")
local menubar			= require("hs.menubar")
local mouse				= require("hs.mouse")
local screen			= require("hs.screen")
local timer				= require("hs.timer")
local application		= require("hs.application")

local ax 				= require("hs._asm.axuielement")

local fcp				= require("cp.apple.finalcutpro")
local config			= require("cp.config")
local prop				= require("cp.prop")

local log				= require("hs.logger").new("console")

local format			= string.format

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 11000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.enabled = config.prop("consoleEnabled", true)

--------------------------------------------------------------------------------
-- LOAD CONSOLE:
--------------------------------------------------------------------------------
function mod.init(actionmanager)
	mod.actionmanager = actionmanager
	mod.activator = actionmanager.getActivator("finalcutpro.console")
		:preloadChoices()
end

--------------------------------------------------------------------------------
-- REFRESH CONSOLE CHOICES:
--------------------------------------------------------------------------------
function mod.refresh()
	if mod.activator and mod.enabled() then 
		mod.activator:refresh()
	end
end

--------------------------------------------------------------------------------
-- SHOW CONSOLE:
--------------------------------------------------------------------------------
function mod.show()
	if mod.activator and mod.enabled() then 
		mod.activator:show()
	end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.console",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.commands"]		= "fcpxCmds",
		["finalcutpro.action.manager"]	= "actionmanager",
		["finalcutpro.menu.tools"]		= "tools",
	}
}

function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Initialise Module:
	--------------------------------------------------------------------------------
	mod.init(deps.actionmanager)

	--------------------------------------------------------------------------------
	-- Add the command trigger:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpConsole")
		:groupedBy("commandPost")
		:whenActivated(function() mod.show() end)
		:activatedBy():ctrl("space")

	--------------------------------------------------------------------------------
	-- Add the 'Console' menu item:
	--------------------------------------------------------------------------------
	local menu = deps.tools:addMenu(PRIORITY, function() return i18n("console") end)
	menu:addItem(1000, function()
		return { title = i18n("enableConsole"),	fn = function() mod.enabled:toggle() end, checked = mod.enabled() }
	end)

	return mod

end

return plugin