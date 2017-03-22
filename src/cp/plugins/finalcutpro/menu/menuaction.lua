--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                         M E N U    A C T I O N                             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- A `action` which will trigger an Final Cut Pro menu with a matching path, if available/enabled.
--- The plugin registers itself with the `cp.plugins.core.actions.actionmanager`.

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("menuaction")

local choices			= require("cp.choices")
local fcp				= require("cp.finalcutpro")
local fnutils			= require("hs.fnutils")
local metadata			= require("cp.metadata")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local ID				= "menu"

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

--- cp.plugins.finalcutpro.menu.menuaction.init(actionmanager) -> none
--- Function
--- Initialises the Menu Action plugin
---
--- Parameters:
---  * `actionmanager` - the Action Manager plugin
---
--- Returns:
---  * None
---
function mod.init(actionmanager)
	mod._manager = actionmanager
	mod._manager.addAction(mod)
end

--- cp.plugins.finalcutpro.menu.menuaction.id() -> none
--- Function
--- Returns the menu ID
---
--- Parameters:
---  * None
---
--- Returns:
---  * a string contains the menu ID
---
function mod.id()
	return ID
end

--- cp.plugins.finalcutpro.menu.menuaction.setEnabled() -> none
--- Function
--- Sets
---
--- Parameters:
---  * `value` - boolean value
---
--- Returns:
---  * None
---
function mod.setEnabled(value)
	metadata.set("menuActionEnabled", value)
	mod._manager.refresh()
end

--- cp.plugins.finalcutpro.menu.menuaction.isEnabled() -> none
--- Function
--- Enabled the Menu Action
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
---
function mod.isEnabled()
	return metadata.get("menuActionEnabled", true)
end

--- cp.plugins.finalcutpro.menu.menuaction.toggleEnabled() -> none
--- Function
--- Toggles whether or not a menu action is enabled.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
---
function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

--- cp.plugins.finalcutpro.menu.menuaction.choices() -> table
--- Function
--- Returns an array of available choices
function mod.choices()
	--------------------------------------------------------------------------------
	-- Cache the choices, since commands don't change while the app is running.
	--------------------------------------------------------------------------------
	local result = choices.new(ID)

	fcp:menuBar():visitMenuItems(function(path, menuItem)
		local title = menuItem:title()

		if path[1] ~= "Apple" then
			local params = {}
			params.path	= fnutils.concat(fnutils.copy(path), { title })

			result:add(title)
				:subText(i18n("menuChoiceSubText", {path = table.concat(path, " > ")}))
				:params(params)
				:id(mod.getId(params))
		end
	end)
	return result
end

function mod.getId(params)
	return ID .. ":" .. table.concat(params.path, "||")
end

--- cp.plugins.finalcutpro.menu.menuaction.execute(params) -> boolean
--- Function
--- Executes the action with the provided parameters.
---
--- Parameters:
--- * `params`	- A table of parameters, matching the following:
---		* `group`	- The Command Group ID
---		* `id`		- The specific Command ID within the group.
---
--- * `true` if the action was executed successfully.
function mod.execute(params)
	if params and params.path then
		fcp:launch()

		fcp:menuBar():selectMenu(table.unpack(params.path))
		return true
	end
	return false
end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.core.actions.actionmanager"] = "actionmanager",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)
		mod.init(deps.actionmanager)
		return mod
	end

return plugin