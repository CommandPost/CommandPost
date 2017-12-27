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

local fs						= require("hs.fs")
local json						= require("hs.json")
local timer						= require("hs.timer")

local command					= require("cp.commands.command")
local config					= require("cp.config")
local prop						= require("cp.prop")
local tools						= require("cp.tools")

local _							= require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local commands = {}
commands.mt = {}
commands.mt.__index = commands.mt

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

--- cp.commands.groups() -> table of cp.commands
--- Function
--- Returns a table with the set of commands.
---
--- Parameters:
--- * `id`		- The ID to retrieve
---
--- Returns:
---  * `cp.commands` - The command group with the specified ID, or `nil` if none exists.
function commands.groups()
	return _.clone(commands._groups, true)
end

--- cp.commands.new(id) -> cp.commands
--- Function
--- Creates a collection of commands. These commands can be enabled or disabled as a group.
---
--- Parameters:
---  * `id`		- The unique ID for this command group.
---
--- Returns:
---  * cp.commands - The command group that was created.
function commands.new(id)
	if commands.group(id) ~= nil then
		error("Duplicate command group ID: "..id)
	end
	local o = {
		_id = id,
		_commands = {},
		_enabled = false,
	}
	prop.extend(o, commands.mt)

	commands._groups[id] = o
	return o
end

--- cp.commands:id() -> string
--- Method
--- Returns the unique ID of the command group.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The command group ID string.
function commands.mt:id()
	return self._id
end

--- cp.commands:add(commandId) -> cp.commands.command
--- Method
--- Adds a new command with the specified ID to this group. Additional configuration
--- should be applied to the returned `command` instance. Eg:
---
--- ```lua
--- myCommands:add("fooBar"):groupedBy("foo"):whenActivated(function() ... end)`
--- ```
---
--- Parameters:
--- * `commandId`	- The unique ID for the new command.
---
--- Returns:
--- * The new `cp.commands.command` instance.
function commands.mt:add(commandId)
	local cmd = command.new(commandId, self)
	self._commands[commandId] = cmd
	-- if self:isEnabled() then cmd:enable() end
	self:_notify("add", cmd)
	return cmd
end

--- cp.commands:get(commandId) -> cp.commands.command
--- Method
--- Returns the command with the specified ID, or `nil` if none exists.
---
--- Parameters:
--- * `commandId`	- The command ID to retrieve.
---
--- Returns:
--- * The `cp.commands.command`, or `nil`.
function commands.mt:get(commandId)
	return self._commands[commandId]
end

--- cp.commands:getAll() -> table of cp.commands.command
--- Method
--- Returns the table of commands, with the key being the ID and the value being the command instance. Eg:
---
--- ```lua
--- for id,cmd in pairs(myCommands:getAll()) do
--- 	...
--- end
--- ```
function commands.mt:getAll()
	return self._commands
end

--- cp.commands:clear() -> cp.commands
--- Method
--- Clears all commands and their shortcuts.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The command group instance.
function commands.mt:clear()
	self:deleteShortcuts()
	self._commands = {}
	return self
end

--- cp.commands:deleteShortcuts() -> cp.commands
--- Method
--- Clears all shortcuts associated with commands in this command group.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The command group instance.
function commands.mt:deleteShortcuts()
	for _,command in pairs(self._commands) do
		command:deleteShortcuts()
	end
	return self
end

--- cp.commands.enabled <cp.prop: boolean>
--- Field
--- If enabled, the commands in the group will be active as well.
commands.mt.isEnabled = prop.TRUE():watch(function(enabled, self)
	--log.df("%s.isEnabled: %s", self:id(), enabled)
	if enabled then
		self:_notify('enable')
	else
		self:_notify('disable')
	end
end):bind(commands.mt)

--- cp.commands.isEditable <cp.prop: boolean>
--- Field
--- If set to `false`, the command group is not user-editable.
commands.isEditable = prop.TRUE():bind(commands.mt)

--- cp.commands:enable() -> cp.commands
--- Method
--- Enables the command group.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The command group instance.
function commands.mt:enable()
	self:isEnabled(true)
	return self
end

--- cp.commands:disable() -> cp.commands
--- Method
--- Disables the command group.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The command group instance.
function commands.mt:disable()
	self:isEnabled(false)
	return self
end

--- cp.commands:watch(events) -> cp.commands
--- Method
--- Adds an event watcher to the command group.
---
--- Parameters:
--- * events	- The table of events to watch for (see Notes).
---
--- Returns:
--- * The command group instance.
---
--- Notes:
--- * The table can have properties with the following functions, which will be called for the specific event:
--- ** `add(command)`: 		Called after the provided `cp.commands.command` instance has been added.
--- ** `activate()`			Called when the command group is activated.
--- ** `enable()`:			Called when the command group is enabled.
--- ** `disable()`:			Called when the command group is disabled.
function commands.mt:watch(events)
	if not self.watchers then
		self.watchers = {}
	end
	self.watchers[#self.watchers + 1] = events
	return self
end

-- cp.commands:_notify(type, ...) -> nil
-- Private Method
-- Called when notifying watchers about an event type.
--
-- Parameters:
-- * type		- The string ID for the event type.
-- * ...		- The list of parameters to pass to watchers.
--
-- Returns:
-- * Nothing.
function commands.mt:_notify(type, ...)
	if self.watchers then
		for _,watcher in ipairs(self.watchers) do
			if watcher[type] then
				watcher[type](...)
			end
		end
	end
end

--- cp.commands:activate(successFn, failureFn) -> nil
--- Method
--- Will trigger an 'activate' event, and then execute either the `successFn` or `failureFn` if the
--- command group is not enabled within 5 seconds.
---
--- Parameters:
--- * successFn		- the function to call if successfully activated.
--- * failureFn		- the function to call if not activated after 5 seconds.
---
--- Returns:
--- * Nothing.
function commands.mt:activate(successFn, failureFn)
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

--- cp.commands:saveShortcuts() -> table
--- Method
--- Returns a table that is approprate to be saved to file that contains the shortuct
--- for all contained `cp.commands.command` instances.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The table of shortcuts for commands.
function commands.mt:saveShortcuts()
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

--- cp.commands:loadShortcuts(data) -> nil
--- Method
--- Loads the shortcut details in the data table and applies them to the commands in this group.
--- The data should probably come from the `saveShortcuts` method.
---
--- Parameters:
--- * data		- The data table containing shortcuts.
---
--- Returns:
--- * Nothing
function commands.mt:loadShortcuts(data)
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

--- cp.commands.getShortcutsPath(name) -> string
--- Function
--- Returns the path to the named shortcut set.
function commands.getShortcutsPath(name)
	shortcutsPath = config.userConfigRootPath .. "/Shortcuts/"

	--------------------------------------------------------------------------------
	-- Create Shortcuts Directory if it doesn't already exist:
	--------------------------------------------------------------------------------
	if not tools.doesDirectoryExist(shortcutsPath) then
		local result = fs.mkdir(shortcutsPath)
		if not result then
			return nil
		end
	end

	return shortcutsPath .. name .. commands.defaultExtension
end

--------------------------------------------------------------------------------
-- GET HISTORY:
--------------------------------------------------------------------------------

--- cp.commands.loadFromFile(name) -> boolean
--- Function
--- Loads a shortcut set from the standard location with the specified name.
---
--- Parameters:
--- * name		- The name of the shortcut set. E.g. "My Custom Shortcuts"
---
--- Returns:
--- * `true` if the file was found and loaded successfully.
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

--- cp.commands.saveToFile(name) -> boolean
--- Function
--- Saves the current shortcuts for all groups to a file in the standard location with the provided name.
---
--- Parameters:
--- * name		- The name of the command set. E.g. "My Custom Commands"
---
--- Returns:
--- * `true` if the shortcuts were saved successfully.
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