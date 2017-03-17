--- A `action` which will trigger an FCPX menu with a matching path, if available/enabled.
--- The plugin registers itself with the `cp.plugins.actions.actionmanager`.

-- Includes
local choices			= require("cp.choices")
local fcp				= require("cp.finalcutpro")
local metadata			= require("cp.metadata")
local fnutils			= require("hs.fnutils")

local log				= require("hs.logger").new("menuaction")

-- The Modules
local mod = {}

local ID	= "menu"

function mod.init(actionmanager)
	mod._manager = actionmanager
	mod._manager.addAction(mod)
end

function mod.id()
	return ID
end

function mod.setEnabled(value)
	metadata.set("menuActionEnabled", value)
	mod._manager.refresh()
end

function mod.isEnabled()
	return metadata.get("menuActionEnabled", true)
end

function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

--- cp.plugins.actions.commandaction.choices() -> table
--- Function
--- Returns an array of available choices
function mod.choices()
	-- Cache the choices, since commands don't change while the app is running.
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

--- cp.plugins.actions.commandaction.execute(params) -> boolean
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

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.actions.actionmanager"] = "actionmanager",
}

function plugin.init(deps)
	mod.init(deps.actionmanager)
	return mod
end

return plugin