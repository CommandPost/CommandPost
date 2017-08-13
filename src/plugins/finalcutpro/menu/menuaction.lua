--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                         M E N U    A C T I O N                             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.menuaction ===
---
--- A `action` which will trigger an Final Cut Pro menu with a matching path, if available/enabled.
--- Registers itself with the `plugins.core.actions.actionmanager`.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("menuaction")

local choices			= require("cp.choices")
local fcp				= require("cp.apple.finalcutpro")
local fnutils			= require("hs.fnutils")
local config			= require("cp.config")
local prop				= require("cp.prop")
local timer				= require("hs.timer")

local concat			= table.concat

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local ID				= "menu"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.menu.menuaction.init(actionmanager) -> none
--- Function
--- Initialises the Menu Action plugin
---
--- Parameters:
---  * `actionmanager` - the Action Manager plugin
---
--- Returns:
---  * None
function mod.init(actionmanager)
	mod._manager = actionmanager
	mod._handler = actionmanager.addHandler(ID)
	:onChoices(mod.onChoices)
	:onExecute(mod.onExecute)

	-- watch for restarts
	fcp.isRunning:watch(function(running)
		timer.doAfter(0.1, mod.reset)
	end, true)
end

--- plugins.finalcutpro.menu.menuaction.id() -> none
--- Function
--- Returns the menu ID
---
--- Parameters:
---  * None
---
--- Returns:
---  * a string contains the menu ID
function mod.id()
	return ID
end

function mod.onChoices(choices)
	fcp:menuBar():visitMenuItems(function(path, menuItem)
		local title = menuItem:title()

		if path[1] ~= "Apple" then
			local params = {}
			params.path	= fnutils.concat(fnutils.copy(path), { title })

			choices:add(title)
				:subText(i18n("menuChoiceSubText", {path = concat(path, " > ")}))
				:params(params)
				:id(mod.actionId(params))
		end
	end)
end

function mod.reset()
	mod._handler:reset()
end

function mod.actionId(params)
	return ID .. ":" .. concat(params.path, "||")
end

--- plugins.finalcutpro.menu.menuaction.execute(action) -> boolean
--- Function
--- Executes the action with the provided parameters.
---
--- Parameters:
--- * `action`	- A table of parameters, matching the following:
---		* `group`	- The Command Group ID
---		* `id`		- The specific Command ID within the group.
---
--- * `true` if the action was executed successfully.
function mod.onExecute(action)
	if action and action.path then
		fcp:launch()

		fcp:menuBar():selectMenu(action.path)
		return true
	end
	return false
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.menu.menuaction",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.action.manager"]	= "actionmanager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	mod.init(deps.actionmanager)
	return mod
end

return plugin