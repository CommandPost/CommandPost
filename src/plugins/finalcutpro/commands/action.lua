--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     C  O  M  M  A  N  D      A C T I O N                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.commands.action ===
---
--- An `action` which will execute a command with matching group/id values.
--- Registers itself with the `finalcutpro.action.manager`.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local choices			= require("cp.choices")
local config			= require("cp.config")
local dialog			= require("cp.dialog")
local prop				= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local ID	= "fcpx"

-- TODO: Add documentation
function mod.init(actionmanager, cmds)
	mod._cmds = cmds
	
	mod._manager = actionmanager
	mod._manager.addAction(mod)
end

-- TODO: Add documentation
function mod.id()
	return ID
end

--- plugins.finalcutpro.commands.action.enabled <cp.prop: boolean>
--- Field
--- This will be `true` when the command actions are enabled.
mod.enabled = config.prop("commandActionEnabled", true)

--- plugins.finalcutpro.commands.action.choices <cp.prop: cp.choices; read-only>
--- Field
--- Returns an array of available choices
mod.choices = prop.new(function()
	-- Cache the choices, since commands don't change while the app is running.
	if not mod._choices then
		mod._choices = choices.new(ID)
		for _,cmd in pairs(mod._cmds:getAll()) do
			local title = cmd:getTitle()
			if title then
				local subText = cmd:getSubtitle()
				if not subText and cmd:getGroup() then
					subText = i18n(cmd:getGroup() .. "_group")
				end
				local params = {
					id		= cmd:id(),
				}
				mod._choices:add(title)
					:subText(subText)
					:params(params)
					:id(mod.getId(params))
			end
		end
	end
	return mod._choices
end)

-- TODO: Add documentation
function mod.getId(params)
	return ID .. ":" .. string.format("%s", params.id)
end

--- plugins.finalcutpro.commands.action.execute(params) -> boolean
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
	local group = mod._cmds
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
	mod.choices:update()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.commands.action",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.action.manager"]		= "actionmanager",
		["finalcutpro.commands"]	= "cmds",
	}
}

function plugin.init(deps)
	mod.init(deps.actionmanager, deps.cmds)
	return mod
end

return plugin