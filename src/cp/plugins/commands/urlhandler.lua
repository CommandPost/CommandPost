--- URL Handler
-- This plugin watches for URL request of the form `commandpost://[group id]?id=[command id]`
-- For example, if there is a command group called `fcpx`, with a command called `cpMyCommand`, it can be
-- triggered by a url of `commandpost://fcpx?id=cpMyCommand`

-- Imports
local dialog		= require("cp.dialog")
local urlevent		= require("hs.urlevent")

-- The module
local mod = {}

function mod.init(...)
	for _,cmds in ipairs(table.pack(...)) do
		urlevent.bind(cmds:id(), function(eventName, params)
			if eventName ~= cmds:id() then
				-- Mismatch!
				dialog.displayMessage(i18n("cmdMismatchError", {expected = cmds:id(), actual = eventName}))
				return
			end
			local cmdId = params.id
			if cmdId == nil or cmdId == "" then
				-- No command ID provided!
				dialog.displayMessage(i18n("cmdIdMissingError"))
				return
			end
			local cmd = cmds:get(cmdId)
			if cmd == nil then
				-- No matching command!
				dialog.displayMessage(i18n("cmdDoesNotExistError"), {id = cmdId})
				return
			end
			
			cmd:activated()
		end)
	end
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.commands.global"]	= "global",
	["cp.plugins.commands.fcpx"]	= "fcpx",
}

function plugin.init(deps)
	mod.init(deps.global, deps.fcpx)
	return mod
end

return plugin