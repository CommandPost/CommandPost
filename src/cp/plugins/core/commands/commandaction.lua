--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       C O M M A N D    A C T I O N                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- A `action` which will execute a command with matching group/id values.
--- The plugin registers itself with the `cp.plugins.core.actions.actionmanager`.

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local commands			= require("cp.commands")
local choices			= require("cp.choices")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local ID				= "command"

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	function mod.id()
		return ID
	end

	--- cp.plugins.core.actions.commandaction.choices() -> table
	--- Function
	--- Returns an array of available choices
	function mod.choices()
		-- Cache the choices, since commands don't change while the app is running.
		if not mod._choices then
			mod._choices = choices.new(ID)
			for _,id in pairs(commands.groupIds()) do
				local group = commands.group(id)
				for _,cmd in pairs(group:getAll()) do
					local title = cmd:getTitle()
					if title then
						local subText = cmd:getSubtitle()
						if not subText and cmd:getGroup() then
							subText = i18n(cmd:getGroup() .. "_group")
						end

						mod._choices:add(title)
							:subText(subText)
							:params({
								group	= group:id(),
								id		= cmd:id(),
							})
					end
				end
			end
		end
		return mod._choices
	end

	--- cp.plugins.core.actions.commandaction.execute(params) -> boolean
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
		local group = commands.group(params.group)
		if group then
			local cmdId = params.id
			if cmdId == nil or cmdId == "" then
				-- No command ID provided!
				dialog.displayMessage(i18n("cmdIdMissingError"))
				return false
			end
			local cmd = group:get(cmdId)
			if cmd == nil then
				-- No matching command!
				dialog.displayMessage(i18n("cmdDoesNotExistError"), {id = cmdId})
				return false
			end

			-- Ensure the command group is active
			group:activate(
				function() cmd:activated() end,
				function() dialog.displayMessage(i18n("cmdGroupNotActivated"), {id = group.id}) end
			)
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