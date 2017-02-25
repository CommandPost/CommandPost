local keycodes				= require("hs.keycodes")
local hotkey				= require("hs.hotkey")

local shortcut				= require("cp.commands.shortcut")

local log					= require("hs.logger").new("command")

-- Only show Hotkey Errors:
hotkey.setLogLevel("error")

local command = {}

--- hs.commands.command:new() -> command
--- Creates a new menu command, which can have items and sub-menus added to it.
---
--- Parameters:
---  * `id`	= the unique identifier for the command. E.g. 'FCPXHacksCustomCommand'
---
--- Returns:
---  * command - The command that was created.
---
function command:new(id)
	o = {
		id = id,
		shortcuts = {},
		enabled = false,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

--- hs.commands.command:titled(title) -> command
--- Applies the provided human-readable title to the command.
---
--- Parameters:
---  * `id`	= the unique identifier for the command. E.g. 'FCPXHacksCustomCommand'
---
--- Returns:
---  * command - The command that was created.
---
function command:titled(title)
	self.title = title
	return self
end

function command:getTitle()
	if self.title then
		return self.title
	else
		return i18n(self.id .. "_title")
	end
end

function command:subtitled(subtitle)
	self.subtitle = subtitle
	return self
end

function command:getSubtitle()
	if self.subtitle then
		return self.subtitle
	else
		return i18n(self.id .. "_subtitle")
	end
end

--- hs.commands.command:activatedBy([modifiers,] [keyCode]) -> command/modifier
--- Specifies that the command is activated by pressing a key combination.
--- This method can be called multiple times, and multiple key combinations will be registered for the command.
--- To remove existing key combinations, call the `command:deleteShortcuts()` method.
---
--- * If the `keyCode` is provided, no modifiers need to be pressed to activate and the `command` is returned.
--- * If the `modifiers` and `keyCode` are provided, the combination is created and the `command` is returned.
--- * If no `keyCode` is provided, a `modifier` is returned, which lets you specify keyboard combinations.
---
--- E.g:
---
--- ```
--- local global    	= commands.collection("global")
--- local pressA 		= global:add("commandA"):activatedBy("a")
--- local pressShiftA	= global:add("commandShiftA"):activatedBy({"shift"}, "a")
--- local pressCmdA		= global:add("commandCmdA"):activatedBy():command("a")
--- local pressOptCmdA	= global:add("commandOptCmdA"):activatedBy():option():command("a")
--- global:enable()
--- ```
---
--- Parameters:
---  * `modifiers`	- (optional) The table containing names of required modifiers.
---  * `keyCode`	- (optional) The key code that will activate the command, with no modifiers.
---
--- Returns:
---  * `command` if a `keyCode` was provided, or `modifier` if not.
---
function command:activatedBy(modifiers, keyCode)
	if keyCode and not modifiers then
		modifiers = {}
	elseif modifiers and not keyCode then
		keyCode = modifiers
		modifiers = {}
	end

	if keyCode then
		self:addShortcut(shortcut:new(modifiers, keyCode))
		return self
	else
		return shortcut:build(
			function(newShortcut)
				return self:addShortcut(newShortcut)
			end
		)
	end
end

--- hs.commands.command:deleteShortcuts() -> command
--- Sets the function that will be called when the command key combo is pressed.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * command - The current command
---
function command:deleteShortcuts()
	for i,shortcut in ipairs(self.shortcuts) do
		shortcut:delete()
	end
	self.shortcuts = {}
	return self
end

function command:setShortcuts(shortcuts)
	self:deleteShortcuts()
	for _,newShortcut in ipairs(shortcuts) do
		self:addShortcut(newShortcut)
	end
	return self
end

--- hs.commands.command:addShortcut() -> command
--- Adds the specified shortcut to the command.
--- If the command is enabled, the shortcut will also be enabled.
---
--- Parameters:
---  * `newShortcut`	- the shortcut
---
--- Returns:
---  * `self`
function command:addShortcut(newShortcut)
	newShortcut:bind(
		function() return self:pressed() end,
		function() return self:released() end,
		function() return self:repeated() end
	)
	-- mark it as a 'command' hotkey
	local shortcuts = self.shortcuts
	shortcuts[#shortcuts + 1] = newShortcut

	-- enable it if appropriate
	if self:isEnabled() then newShortcut:enable() end
	return self
end

--- hs.commands.command:getShortcuts() -> command
--- Returns the set of shortcuts assigned to this command.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * The associated shortcuts.
function command:getShortcuts()
	return self.shortcuts
end

--- hs.commands.command:whenActivated(function) -> command
--- Sets the function that will be called when the command is activated.
---
--- NOTE: This is a shortcut for calling `whenPressed(...)`
---
--- Parameters:
---  * `activatedFn`	- the function to call when activated.
---
--- Returns:
---  * command - The current command
---
function command:whenActivated(activatedFn)
	return self:whenPressed(activatedFn)
end

--- hs.commands.command:whenPressed(function) -> command
--- Sets the function that will be called when the command key combo is pressed.
---
--- Parameters:
---  * `pressedFn`	- the function to call when pressed.
---
--- Returns:
---  * command - The current command
---
function command:whenPressed(pressedFn)
	self.pressedFn = pressedFn
	return self
end

--- hs.commands.command:whenReleased(function) -> command
--- Sets the function that will be called when the command key combo is released.
---
--- Parameters:
---  * `releasedFn`	- the function to call when released.
---
--- Returns:
---  * command - The current command
---
function command:whenReleased(releasedFn)
	self.releasedFn = releasedFn
	return self
end

--- hs.commands.command:whenRepeated(function) -> command
--- Sets the function that will be called when the command key combo is repeated.
---
--- Parameters:
---  * `repeatedFn`	- the function to call when repeated.
---
--- Returns:
---  * command - The current command
---
function command:whenRepeated(repeatedFn)
	self.repeatedFn = repeatedFn
	return self
end

--- hs.commands.command:pressed() -> command
--- Executes the 'pressed' function, if present.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the result of the function, or `nil` if none is present.
---
function command:pressed()
	if self:isEnabled() and self.pressedFn then return self.pressedFn() end
	return nil
end

--- hs.commands.command:released() -> command
--- Executes the 'released' function, if present.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the result of the function, or `nil` if none is present.
---
function command:released()
	if self:isEnabled() and self.releasedFn then return self.releasedFn() end
	return nil
end

--- hs.commands.command:repeated(repeats) -> command
--- Executes the 'repeated' function, if present.
---
--- Parameters:
---  * `repeats`	- the number of times to repeat. Defaults to 1.
---
--- Returns:
---  * the last result.
---
function command:repeated(repeats)
	if not self:isEnabled() then return nil end

	if repeats == nil then
		repeats = 1
	end
	local result = nil
	if self.repeatedFn then
		for i = 1, repeats do
			result = self.repeatedFn()
		end
	end
	return result
end

--- hs.commands.command:activated(repeats) -> command
--- Executes the 'pressed', then 'repeated', then 'released' functions, if present.
---
--- Parameters:
---  * `repeats`	- the number of times to repeat the 'repeated' function. Defaults to 1.
---
--- Returns:
---  * the last 'truthy' result (non-nil/false).
---
function command:activated(repeats)
	if not self:isEnabled() then return nil end

	local result = nil
	result = self:pressed()
	result = self:repeated(repeats) or result
	result = self:released() or result
	return result
end

function command:enable()
	self.enabled = true
	for _,shortcut in ipairs(self.shortcuts) do
		shortcut:enable()
	end
	return self
end

function command:disable()
	self.enabled = false
	for _,shortcut in ipairs(self.shortcuts) do
		shortcut:disable()
	end
	return self
end

function command:isEnabled()
	return self.enabled
end

return command