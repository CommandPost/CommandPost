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
local log				= require("hs.logger").new("console")

local application		= require("hs.application")
local chooser			= require("hs.chooser")
local drawing 			= require("hs.drawing")
local fnutils 			= require("hs.fnutils")
local menubar			= require("hs.menubar")
local mouse				= require("hs.mouse")
local screen			= require("hs.screen")
local timer				= require("hs.timer")

local ax 				= require("hs._asm.axuielement")

local config			= require("cp.config")
local fcp				= require("cp.apple.finalcutpro")
local prop				= require("cp.prop")
local tools				= require("cp.tools")

local format			= string.format

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 		= 11000
local GROUP			= "fcpx"
local WIDGETS		= "widgets"

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
	if mod.actionmanager and mod.enabled() then
		if not mod.activator then
			mod.activator = mod.actionmanager.getActivator("finalcutpro.console")
				:preloadChoices()

			-- --------------------------------------------------------------------------------
			-- -- Restrict Allowed Handlers for Activator to current group:
			-- --------------------------------------------------------------------------------
			local allowedHandlers = {}
			local handlerIds = mod.actionmanager.handlerIds()
			for _,id in pairs(handlerIds) do
				local handlerTable = tools.split(id, "_")
				if handlerTable[2]~= WIDGETS then
					table.insert(allowedHandlers, id)
				end
			end
			log.df("allowedHandlers: %s", hs.inspect(allowedHandlers))
			mod.activator:allowHandlers(table.unpack(allowedHandlers))
		end

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
		["core.action.manager"]			= "actionmanager",
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