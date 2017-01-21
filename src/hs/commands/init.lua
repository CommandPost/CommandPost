local command					= require("hs.commands.command")

local commands = {}

--- hs.commands:new() -> commands
--- Creates a collection of commands. These commands can be enabled or disabled as a group.
---
--- Returns:
---  * commands - The commands that was created.
---
function commands:new(id)
	o = {
		id = id,
		commands = {},
		enabled = false,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function commands:id()
	return self.id
end

function commands:add(commandId)
	local cmd = command:new(commandId)
	self.commands[commandId] = cmd
	if self:isEnabled() then cmd:enable() end
	self:_notify("add", cmd)
	return cmd
end

function commands:get(commandId)
	return self.commands[commandId]
end

function commands:getAll()
	return self.commands
end

function commands:enable()
	self.enabled = true
	for _,command in pairs(self.commands) do
		command:enable()
	end
	return self
end

function commands:disable()
	for _,command in pairs(self.commands) do
		command:disable()
	end
	self.enabled = false
	return self
end

function commands:isEnabled()
	return self.enabled
end

function commands:watch(events)
	if not self.watchers then
		self.watchers = {}
	end
	self.watchers[#self.watchers + 1] = events
end

function commands:_notify(type, ...)
	if self.watchers then
		for _,watcher in ipairs(self.watchers) do
			if watcher[type] then
				watcher[type](...)
			end
		end
	end
end

return commands