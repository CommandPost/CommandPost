--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                         M E N U    A C T I O N                             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- A `action` which will trigger an FCPX menu with a matching path, if available/enabled.
--- The plugin registers itself with the `cp.plugins.actions.actionmanager`.

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local fnutils			= require("hs.fnutils")

local choices			= require("cp.choices")
local fcp				= require("cp.finalcutpro")
local metadata			= require("cp.metadata")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local ID				= "menu"

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

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

	function mod.id()
		return ID
	end

	--- cp.plugins.actions.commandaction.choices() -> table
	--- Function
	--- Returns an array of available choices
	function mod.choices()
		-- Cache the choices, since commands don't change while the app is running.
		local result = choices.new(ID)

		fcp:menuBar():visitMenuItems(function(path, menuItem)
			local title = menuItem:title()

			result:add(title)
				:subText(i18n("menuChoiceSubText", {path = table.concat(path, " > ")}))
				:params({
					path	= fnutils.concat(fnutils.copy(path), { title }),
				})
		end)
		return result
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
		deps.actionmanager.addAction(mod)
		return mod
	end

return plugin