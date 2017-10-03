--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     C  O  M  M  A  N  D      A C T I O N                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.commands.actions ===
---
--- An `action` which will execute a command with matching group/id values.
--- Registers itself with the `core.action.manager`.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local choices			= require("cp.choices")
local config			= require("cp.config")
local dialog			= require("cp.dialog")
local prop				= require("cp.prop")

local format			= string.format

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local ID	= "cmds"
local GROUP = "global"

-- TODO: Add documentation
function mod.init(actionmanager, cmds)
	mod._cmds = cmds

	mod._manager = actionmanager

	mod._handler = actionmanager.addHandler(GROUP .. "_" .. ID, GROUP)
	:onChoices(mod.onChoices)
	:onExecute(mod.onExecute)
	:onActionId(mod.getId)
end

--- plugins.core.commands.actions.onChoices(choices) -> nothing
--- Function
--- Adds available choices to the  selection.
---
--- Parameters:
--- * `choices`		- The `cp.choices` to add choices to.
---
--- Returns:
--- * Nothing
function mod.onChoices(choices)
	for _,cmd in pairs(mod._cmds:getAll()) do
		local title = cmd:getTitle()
		if title then
			local group = cmd:getSubtitle()
			if not group and cmd:getGroup() then
				group = i18n(cmd:getGroup().."_group")
			end
			group = group or ""
			local action = {
				id		= cmd:id(),
			}
			choices:add(title)
				:subText(i18n("commandChoiceSubText", {group = group}))
				:params(action)
				:id(mod.getId(action))
		end
	end
end

-- TODO: Add documentation
function mod.getId(action)
	return format("%s:%s", ID, action.id)
end

--- plugins.core.commands.actions.execute(action) -> boolean
--- Function
--- Executes the action with the provided parameters.
---
--- Parameters:
--- * `action`	- A table representing the action, matching the following:
---		* `id`		- The specific Command ID within the group.
---
--- * `true` if the action was executed successfully.
function mod.onExecute(action)
	local group = mod._cmds
	if group then
		local cmdId = action.id
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

--- plugins.core.commands.actions.reset() -> nothing
--- Function
--- Resets the set of choices.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function mod.reset()
	mod._handler:reset()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.commands.actions",
	group			= "core",
	dependencies	= {
		["core.action.manager"]		= "actionmanager",
		["core.commands.global"]	= "cmds",
	}
}

function plugin.init(deps)
	mod.init(deps.actionmanager, deps.cmds)
	return mod
end

return plugin