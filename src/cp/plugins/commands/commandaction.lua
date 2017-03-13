--- A `action` which will execute a command with matching group/id values.
--- The plugin registers itself with the `cp.plugins.actions.actionmanager`.

-- Includes
local commands			= require("cp.commands")
local choices			= require("cp.choices")
local metadata			= require("cp.metadata")

-- The Modules
local mod = {}

local ID	= "command"

function mod.id()
	return ID
end

--- cp.plugins.actions.commandaction.choices() -> table
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

function mod.getId(params)
	return ID .. ":" .. string.format("%s:%s", params.group, params.id)
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

function mod.reset()
	mod._choices = nil
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.actions.actionmanager"] = "actionmanager",
}

function plugin.init(deps)
	deps.actionmanager.addAction(mod)
	return mod
end

return plugin