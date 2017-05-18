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
	mod._manager.addAction(mod)
	
	-- watch for restarts
	fcp:watch({
		launched	= function() timer.doAfter(0.1, mod.update) end,
		terminated	= function() timer.doAfter(0.1, mod.clear) end,
	})
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

--- plugins.finalcutpro.menu.menuaction.enabled <cp.prop: boolean>
--- Field
--- This will be `true` when menu actions are enabled.
mod.enabled = config.prop("menuActionEnabled", true)

--- plugins.finalcutpro.menu.menuaction.choices <cp.prop: cp.choices; read-only>
--- Field
--- Returns an array of available choices
mod.choices = prop.new(function() return mod._choices end):watch(function(choices) log.df("choices updated: #%s choices", choices and #choices or 0) end)

function mod.update()
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
	
	mod._choices = result
	mod.choices:update()
end

function mod.clear()
	mod._choices = nil
	mod.choices:update()
end

function mod.getId(params)
	return ID .. ":" .. table.concat(params.path, "||")
end

--- plugins.finalcutpro.menu.menuaction.execute(params) -> boolean
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

		fcp:menuBar():selectMenu(params.path)
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