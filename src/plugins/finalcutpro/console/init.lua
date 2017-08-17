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

mod.mainChooser			= nil 		-- the actual hs.chooser
mod.hiderChooser		= nil		-- the chooser for hiding/unhiding items.
mod.activeChooser		= nil		-- the currently-visible chooser.
mod.active 				= false		-- is the Hacks Console Active?

mod.enabled = config.prop("consoleEnabled", true)

mod.reducedTransparency = prop.new(function()
	return screen.accessibilitySettings()["ReduceTransparency"]
end)

mod.searchSubtext = config.prop("searchSubtext", true)

mod.lastQueryRemembered = config.prop("consoleLastQueryRemembered", true)

mod.lastQueryValue = config.prop("consoleLastQueryValue", "")

--------------------------------------------------------------------------------
-- LOAD CONSOLE:
--------------------------------------------------------------------------------
function mod.init(actionmanager)
	mod.actionmanager = mod.actionmanager or actionmanager
	mod.activator = actionmanager.getActivator("finalcutpro.console")
end

--------------------------------------------------------------------------------
-- REFRESH CONSOLE CHOICES:
--------------------------------------------------------------------------------
function mod.refresh()
	mod.activator:refresh()
end

--------------------------------------------------------------------------------
-- SHOW CONSOLE:
--------------------------------------------------------------------------------
function mod.show()
	mod.activator:show()
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

	mod.init(deps.actionmanager)

	-- Add the command trigger
	deps.fcpxCmds:add("cpConsole")
		:groupedBy("commandPost")
		:whenActivated(function() mod.show() end)
		:activatedBy():ctrl("space")

	-- Add the 'Console' menu items
	local menu = deps.tools:addMenu(PRIORITY, function() return i18n("console") end)

	menu:addItem(1000, function()
		return { title = i18n("enableConsole"),	fn = function() mod.enabled:toggle() end, checked = mod.enabled() }
	end)

	return mod

end

return plugin