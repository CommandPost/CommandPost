--- URL Handler
-- This plugin watches for URL request of the form `commandpost://[group id]?id=[command id]`
-- For example, if there is a command group called `fcpx`, with a command called `cpMyCommand`, it can be
-- triggered by a url of `commandpost://fcpx?id=cpMyCommand`

-- Imports
local dialog		= require("cp.dialog")

local timer			= require("hs.timer")
local urlevent		= require("hs.urlevent")
local log			= require("hs.logger").new("urlhandler")

-- The module
local mod = {}

mod.log = log

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
			
			log.df("activating '%s'", cmds:id())
			cmds:activate()
			local count = 0
			timer.waitUntil(
				function() count = count + 1; return cmds:isEnabled() or count == 1000 end,
				function() 
					log.df("activating '%s': enabled = ", cmd:id(), cmd:isEnabled())
					cmd:activated()
				end,
				0.001
			)
		end)
	end
	-- Unknown command handler
	urlevent.bind("_undefined", function()
		dialog.displayMessage(i18n("cmdUndefinedError"))
	end)
end

function mod.getURL(command)
	if command then
		-- log.df("getURL: command = %s", hs.inspect(command))
		return string.format("commandpost://%s?id=%s", command:parent():id(), command:id())
	else
		return string.format("commandpost://_undefined")
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