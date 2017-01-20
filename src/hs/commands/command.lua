local modifier				= require("hs.commands.modifier")
local hotkey				= require("hs.hotkey")

local log					= require("hs.logger").new("command")

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
		hotkeys = {},
		enabled = false,
		bound = true,
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

function command:subtitled(subtitle)
	self.subtitle = subtitle
	return self
end

--- hs.commands.command:activatedBy(keyCode) -> command/modifier
--- Specifies that the command is activated by pressing a key combination.
--- * If the `keyCode` is provided, no modifiers need to be pressed to activate.
--- * If no `keyCode` is provided, a `modifier` is returned, which lets you specify keyboard combinations.
--- 
--- E.g:
---
--- ```
--- local global    	= commands.collection("global")
--- local pressA 		= global:add("commandA"):pressing("a")
--- local pressCmdA		= global:add("commandCmdA"):pressing():command("a")
--- local pressOptCmdA	= global:add("commandOptCmdA"):pressing():option():command("a")
--- global:enable()
--- ```
---
--- Parameters:
---  * `keyCode`	- (optional) The key code that will activate the command, with no modifiers.
---
--- Returns:
---  * `command` if a `keyCode` was provided, or `modifier` if not.
---
function command:activatedBy(keyCode)
	if keyCode then
		self:_addHotkey({}, keyCode)
		return self
	else
		return modifier:new(self)
	end
end

-- internal method
function command:_addHotkey(modifiers, key)
	local hk = hotkey.new(modifiers, key, 
		function() return self:pressed() end,
		function() return self:released() end,
		function() return self:repeated() end
	)
	-- mark it as a 'command' hotkey
	hk.command = self
	local hotkeys = self.hotkeys
	hotkeys[#hotkeys + 1] = hk
	
	-- enable it if appropriate
	if self:isEnabled() and self:isBound() then hk:enable() end
	return self
end

--- hs.commands.command:whenPressedDo(function) -> command
--- Sets the function that will be called when the command key combo is pressed.
---
--- Parameters:
---  * `pressedFn`	- the function to call when pressed.
---
--- Returns:
---  * command - The current command
---
function command:whenPressedDo(pressedFn)
	self.pressedFn = pressedFn
	return self
end

--- hs.commands.command:whenReleasedDo(function) -> command
--- Sets the function that will be called when the command key combo is released.
---
--- Parameters:
---  * `releasedFn`	- the function to call when released.
---
--- Returns:
---  * command - The current command
---
function command:whenReleasedDo(releasedFn)
	self.releasedFn = releasedFn
	return self
end

--- hs.commands.command:whenRepeatedDo(function) -> command
--- Sets the function that will be called when the command key combo is repeated.
---
--- Parameters:
---  * `repeatedFn`	- the function to call when repeated.
---
--- Returns:
---  * command - The current command
---
function command:whenRepeatedDo(repeatedFn)
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
	if self.pressedFn then return self.pressedFn() end
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
	if self.releasedFn then return self.releasedFn() end
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
	local result = nil
	result = self:pressed()
	result = self:repeated(repeats) or result
	result = self:released() or result
	return result
end

--- hs.commands.command:bind() -> command
--- Binds any hotkeys linked to the command.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the `command`
---
function command:bind()
	self.bound = true
	if self:isEnabled() then
		for _,hk in ipairs(self.hotkeys) do
			hk:enable()
		end
	end
	return self
end

--- hs.commands.command:unbind() -> command
--- Unbinds any hotkeys linked to the command.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * the `command`
---
function command:unbind()
	self.bound = false
	for _,hk in ipairs(self.hotkeys) do
		hk:disable()
	end
	return self
end

function command:isBound()
	return self.bound
end

function command:enable()
	self.enabled = true
	if self.bound then self:bind() end
	return self
end

function command:disable()
	self.enabled = false
	if self.bound then
		self:unbind() 
		 -- reset bound so it will kick back in when the command is enabled.
		self.bound = true
	end
	return self
end

function command:isEnabled()
	return self.enabled
end

return command
