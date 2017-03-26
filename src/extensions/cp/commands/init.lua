--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                               C O M M A N D S                              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.commands ===
---
--- Commands Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local command					= require("cp.commands.command")
local timer						= require("hs.timer")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local commands = {}

commands._groups = {}

--- cp.commands.groupIds() -> table
--- Function
--- Returns an array of IDs of command groups which have been created.
---
--- Parameters:
--- * N/A
---
--- Returns:
---  * `table` - The array of group IDs.
---
function commands.groupIds()
	local ids = {}
	for id,_ in pairs(commands._groups) do
		ids[#ids + 1] = id
	end
	return ids
end

--- cp.commands.group(id) -> cp.command or nil
--- Function
--- Creates a collection of commands. These commands can be enabled or disabled as a group.
---
--- Parameters:
--- * `id`		- The ID to retrieve
---
--- Returns:
---  * `cp.commands` - The command group with the specified ID, or `nil` if none exists.
---
function commands.group(id)
	return commands._groups[id]
end

--- cp.commands:new(id) -> cp.commands
--- Method
--- Creates a collection of commands. These commands can be enabled or disabled as a group.

--- Parameters:
--- * `id`		- The unique ID for this command group.
---
--- Returns:
---  * cp.commands - The commands group that was created.
---
function commands:new(id)
	if commands.group(id) ~= nil then
		error("Duplicate command group ID: "..id)
	end
	o = {
		_id = id,
		_commands = {},
		_enabled = false,
	}
	setmetatable(o, self)
	self.__index = self

	commands._groups[id] = o
	return o
end

function commands:id()
	return self._id
end

function commands:add(commandId)
	local cmd = command:new(commandId, self)
	self._commands[commandId] = cmd
	if self:isEnabled() then cmd:enable() end
	self:_notify("add", cmd)
	return cmd
end

function commands:get(commandId)
	return self._commands[commandId]
end

function commands:getAll()
	return self._commands
end

function commands:clear()
	self:deleteShortcuts()
	self._commands = {}
	return self
end

function commands:deleteShortcuts()
	for _,command in pairs(self._commands) do
		command:deleteShortcuts()
	end
	return self
end

function commands:enable()
	self._enabled = true
	for _,command in pairs(self._commands) do
		command:enable()
	end
	self:_notify('enable')
	return self
end

function commands:disable()
	for _,command in pairs(self._commands) do
		command:disable()
	end
	self._enabled = false
	self:_notify('disable')
	return self
end

function commands:isEnabled()
	return self._enabled
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

function commands:activate(successFn, failureFn)
	self:_notify('activate')
	local count = 0
	timer.waitUntil(
		function() count = count + 1; return self:isEnabled() or count == 1000 end,
		function()
			if self:isEnabled() then
				if successFn then
					successFn(self)
				end
			else
				if failureFn then
					failureFn(self)
				end
			end
		end,
		0.001
	)
end

return commands