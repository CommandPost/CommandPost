--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     C  O  M  M  A  N  D      A C T I O N                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.commands.commandaction ===
---
--- An `action` which will execute a command with matching group/id values.
--- Registers itself with the `core.action.manager`.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local choices			= require("cp.choices")
local commands			= require("cp.commands")
local config			= require("cp.config")
local dialog			= require("cp.dialog")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local ID	= "command"

-- TODO: Add documentation
function mod.init(actionmanager)
	mod._manager = actionmanager
	mod._manager.addAction(mod)
end

-- TODO: Add documentation
function mod.id()
	return ID
end

-- TODO: Add documentation
function mod.setEnabled(value)
	config.set("commandActionEnabled", value)
	mod._manager.refresh()
end

-- TODO: Add documentation
function mod.isEnabled()
	return config.get("commandActionEnabled", true)
end

-- TODO: Add documentation
function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

--- plugins.core.commands.commandaction.choices() -> table
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
					local params = {
						group	= group:id(),
						id		= cmd:id(),
					}
					mod._choices:add(title)
						:subText(subText)
						:params(params)
						:id(mod.getId(params))
				end
			end
		end
	end
	return mod._choices
end

-- TODO: Add documentation
function mod.getId(params)
	return ID .. ":" .. string.format("%s:%s", params.group, params.id)
end

--- plugins.core.commands.commandaction.execute(params) -> boolean
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

-- TODO: Add documentation
function mod.reset()
	mod._choices = nil
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.commands.commandaction",
	group			= "core",
	dependencies	= {
		["core.action.manager"] = "actionmanager",
	}
}

function plugin.init(deps)
	mod.init(deps.actionmanager)
	return mod
end

return plugin