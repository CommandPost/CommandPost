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
local log						= require("hs.logger").new("commands")

local command					= require("cp.commands.command")
local config					= require("cp.config")
local prop						= require("cp.prop")
local timer						= require("hs.timer")
local json						= require("hs.json")
local _							= require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local commands = {}

commands.defaultExtension = ".cpShortcuts"

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
function commands.group(id)
	return commands._groups[id]
end

--- cp.commands:new(id) -> cp.commands
--- Method
--- Creates a collection of commands. These commands can be enabled or disabled as a group.
---
--- Parameters:
---  * `id`		- The unique ID for this command group.
---
--- Returns:
---  * cp.commands - The commands group that was created.
function commands:new(id)
	if commands.group(id) ~= nil then
		error("Duplicate command group ID: "..id)
	end
	local o = {
		_id = id,
		_commands = {},
		_enabled = false,
	}
	prop.extend(o, commands)

	commands._groups[id] = o
	return o
end

-- TODO: Add documentation
function commands:id()
	return self._id
end

-- TODO: Add documentation
function commands:add(commandId)
	local cmd = command:new(commandId, self)
	self._commands[commandId] = cmd
	if self:isEnabled() then cmd:enable() end
	self:_notify("add", cmd)
	return cmd
end

-- TODO: Add documentation
function commands:get(commandId)
	return self._commands[commandId]
end

-- TODO: Add documentation
function commands:getAll()
	return self._commands
end

-- TODO: Add documentation
function commands:clear()
	self:deleteShortcuts()
	self._commands = {}
	return self
end

-- TODO: Add documentation
function commands:deleteShortcuts()
	for _,command in pairs(self._commands) do
		command:deleteShortcuts()
	end
	return self
end

-- TODO: Add documentation
function commands:enable()
	self:isEnabled(true)
	return self
end

-- TODO: Add documentation
function commands:disable()
	self:isEnabled(false)
	return self
end

--- cp.commands.enabled <cp.prop: boolean>
--- Field
--- If enabled, the commands in the group will be active as well.
commands.isEnabled = prop.TRUE():bind(commands):watch(function(enabled, self)
	if enabled then
		self:_notify('enable')
	else
		self:_notify('disable')
end)

--- cp.commands.isEditable <cp.prop: boolean>
--- Field
--- If set to `false`, the command group is not user-editable.
commands.isEditable = prop.TRUE():bind(commands)

-- TODO: Add documentation
function commands:watch(events)
	if not self.watchers then
		self.watchers = {}
	end
	self.watchers[#self.watchers + 1] = events
end

-- TODO: Add documentation
function commands:_notify(type, ...)
	if self.watchers then
		for _,watcher in ipairs(self.watchers) do
			if watcher[type] then
				watcher[type](...)
			end
		end
	end
end

-- TODO: Add documentation
function commands:activate(successFn, failureFn)
	self:_notify('activate')
	local count = 0
	timer.waitUntil(
		function() count = count + 1; return self:isEnabled() or count == 5000 end,
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

-- TODO: Add documentation
function commands:saveShortcuts()
	local data = {}

	for id,command in pairs(self:getAll()) do
		local commandData = {}
		for i,shortcut in ipairs(command:getShortcuts()) do
			commandData[#commandData + 1] = {
				modifiers = _.clone(shortcut:getModifiers()),
				keyCode = shortcut:getKeyCode(),
			}
		end
		data[id] = commandData
	end
	return data
end

-- TODO: Add documentation
function commands:loadShortcuts(data)
	self:deleteShortcuts()
	for id,commandData in pairs(data) do
		local command = self:get(id)
		if command then
			for i,shortcut in ipairs(commandData) do
				command:activatedBy(shortcut.modifiers, shortcut.keyCode)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- GET HISTORY PATH:
--------------------------------------------------------------------------------

-- TODO: Add documentation
function commands.getShortcutsPath(name)
	shortcutsPath = config.userConfigRootPath .. "/Shortcuts/"
	return shortcutsPath .. name .. commands.defaultExtension
end

--------------------------------------------------------------------------------
-- GET HISTORY:
--------------------------------------------------------------------------------

-- TODO: Add documentation
function commands.loadFromFile(name)
	local groupData = {}

	-- load the file
	local filePath = commands.getShortcutsPath(name)
	local file = io.open(filePath, "r")
	if file then
		log.df("Loading shortcuts: '%s'", filePath)
		local content = file:read("*all")
		file:close()
		if not _.isEmpty(content) then
			groupData = json.decode(content)
		else
			log.df("Empty shortcut file: '%s'", filePath)
			return false
		end
	else
		log.df("Unable to load shortcuts: '%s'", filePath)
		return false
	end

	-- apply the shortcuts
	for groupId,shortcuts in pairs(groupData) do
		local group = commands.group(groupId)
		if group then
			-- clear existing shortcuts
			group:deleteShortcuts()
			-- apply saved ones
			group:loadShortcuts(shortcuts)
		end
	end
	return true
end

--------------------------------------------------------------------------------
-- SET HISTORY:
--------------------------------------------------------------------------------

-- TODO: Add documentation
function commands.saveToFile(name)
	-- get the shortcuts
	local groupData = {}
	for id,group in pairs(commands._groups) do
		groupData[id] = group:saveShortcuts()
	end

	-- save the file
	local filePath = commands.getShortcutsPath(name)
	file = io.open(filePath, "w")
	if file then
		log.df("Saving shortcuts: '%s'", filePath)
		file:write(json.encode(groupData))
		file:close()
		return true
	else
		log.df("Unable to save shortcuts: '%s'", filePath)
	end
	return false
end

return commands