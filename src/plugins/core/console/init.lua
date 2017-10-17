--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.console ===
---
--- Global Console

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("globalConsole")

local tools				= require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local GROUP			= "global"
local WIDGETS		= "widgets"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- SHOW CONSOLE:
--------------------------------------------------------------------------------
function mod.show()

	if not mod.activator then
		mod.activator = mod.actionmanager.getActivator("core.console")
			:preloadChoices()

		--------------------------------------------------------------------------------
		-- Restrict Allowed Handlers for Activator to current group:
		--------------------------------------------------------------------------------
		local allowedHandlers = {}
		local handlerIds = mod.actionmanager.handlerIds()
		for _,id in pairs(handlerIds) do
			local handlerTable = tools.split(id, "_")
			if handlerTable[2]~= WIDGETS and handlerTable[1] == GROUP then
				table.insert(allowedHandlers, id)
			end
		end
		mod.activator:allowHandlers(table.unpack(allowedHandlers))

	end
	mod.activator:show()

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.console",
	group			= "core",
	dependencies	= {
		["core.commands.global"] 		= "global",
		["core.action.manager"]			= "actionmanager",
	}
}

function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Initialise Module:
	--------------------------------------------------------------------------------
	mod.actionmanager = deps.actionmanager

	--------------------------------------------------------------------------------
	-- Add the command trigger:
	--------------------------------------------------------------------------------
	deps.global:add("cpGlobalConsole")
		:groupedBy("commandPost")
		:whenActivated(function() mod.show() end)
		:activatedBy():ctrl():option():cmd("space")

	return mod

end

return plugin