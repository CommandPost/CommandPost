local eventtap									= require("hs.eventtap")
local hotkey									= require("hs.hotkey")
local keycodes									= require("hs.keycodes")
local englishKeyCodes							= require("hs.commands.englishKeyCodes")

local log										= require("hs.logger").new("shortcut")

--- The shortcut class
local shortcut = {}

-- The shortcut builder class
local builder = {}


--- shortcut.textToKeyCode() -> string
--- Function
--- Translates string into a key code.
---
--- Parameters:
---  * input - string
---
--- Returns:
---  * Keycode as String or ""
---
function shortcut.textToKeyCode(input)
	local result = englishKeyCodes[input]
	if not result then
		result = keycodes.map[input]
		if not result then
			result = ""
		end
	end
	return result
end

--- hs.commands.shortcut:new(command) -> shortcut
--- Creates a new keyboard shortcut, attached to the specified `hs.commands.command`
---
--- Parameters:
---  * `modifiers` 	- The modifiers.
---  * `keyCode`	- The key code.
---
--- Returns:
---  * shortcut - The shortcut that was created.
---
function shortcut:new(modifiers, keyCode)
	o = {
		_modifiers = modifiers or {},
		_keyCode = keyCode,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

--- hs.commands.shortcut:build(receiverFn) > hs.commands.shortcut.builder
--- Creates a new shortcut builder. If provided, the receiver function
--- will be called when the shortcut has been configured, and passed the new
--- shortcut. The result of that function will be returned to the next stage.
--- If no `receiverFn` is provided, the shortcut will be returned directly.
---
--- The builder is additive. You can create a complex keystroke combo by
--- chaining the shortcut names together.
---
--- For example:
---
--- `local myShortcut = shortcut:build():cmd():alt("x")`
---
--- Alternately, provide a `receiver` function and it will get passed the shortcut instead:
---
--- `shortcut:build(function(shortcut) self._myShortcut = shortcut end):cmd():alt("x")`
---
--- Parameters:
---  * `receiverFn`		- (optional) a function which will get passed the shortcut when the build is complete.
---
--- Returns:
---  * `shortcut.builder` which can be used to create the shortcut.
function shortcut:build(receiverFn)
	return builder:new(receiverFn)
end

function shortcut:getModifiers()
	return self._modifiers
end

function shortcut:getKeyCode()
	return self._keyCode
end

function shortcut:isEnabled()
	return self._enabled
end

--- hs.commands.shortcut:enable() - > shortcut
--- This enables the shortcut. If a hotkey has been bound, it will be enabled also.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * `self`
function shortcut:enable()
	self._enabled = true
	if self._hotkey then
		self._hotkey:enable()
	end
	return self
end

--- hs.commands.shortcut:enable() - > shortcut
--- This enables the shortcut. If a hotkey has been bound, it will be enabled also.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * `self`
function shortcut:disable()
	self._enabled = false
	if self._hotkey then
		self._hotkey:disable()
	end
	return self
end

--- hs.commands.shortcut:bind(pressedFn, releasedFn, repeatedFn) -> shortcut
--- This function binds the shortcut to a hotkey, with the specified callback functions for
--- `pressedFn`, `releasedFn` and `repeatedFn`.
---
--- If the shortcut is enabled, the hotkey will also be enabled at this point.
---
--- Parameters:
---  * `pressedFn`	- (optional) If present, this is called when the shortcut combo is pressed.
---  * `releasedFn`	- (optional) If present, this is called when the shortcut combo is released.
---  * `repeatedFn`	- (optional) If present, this is called when the shortcut combo is repeated.
---
--- Returns:
---  * `self`
function shortcut:bind(pressedFn, releasedFn, repeatedFn)
	-- Unbind any existing hotkey
	self:unbind()
	-- Bind a new one with the specified calleback functions.
	local keyCode = shortcut.textToKeyCode(self:getKeyCode())
	if keyCode ~= nil and keyCode ~= "" then
		self._hotkey = hotkey.new(self:getModifiers(), keyCode, pressedFn, releasedFn, repeatedFn)
		self._hotkey.shortcut = self
		if self:isEnabled() then
			self._hotkey:enable()
		end
	else
		--TODO: Why it this happening?
		log.e("keyCode was empty.")
	end
	return self
end

function shortcut:unbind()
	local hotkey = self._hotkey
	if hotkey then
		hotkey:disable()
		hotkey:delete()
		self._hotkey = nil
	end
	return self
end

function shortcut:delete()
	return self:unbind()
end

--- hs.commands.shortcut:trigger() -> shortcut
--- This will trigger the keystroke specified in the shortcut.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * `self`
function shortcut:trigger()
	local keyCode = shortcut.textToKeyCode(self:getKeyCode())
	eventtap.keyStroke(self._modifiers, keyCode)
	return self
end

--- hs.commands.shortcut.builder:new(receiverFn)
--- Creates a new shortcut builder. If provided, the receiver function
--- will be called when the shortcut has been configured, and passed the new
--- shortcut. The result of that function will be returned to the next stage.
--- If no `receiverFn` is provided, the shortcut will be returned directly.
function builder:new(receiverFn)
	o = {
		_receiver	= receiverFn,
		_modifiers 	= modifiers or {},
	}
	setmetatable(o, self)
	self.__index = self
	return o
end


--- hs.commands.shortcut.builder:add(modifier, [keyCode]) -> shortcut/command
--- Adds the specified modifier to the set. If a `keyCode` is provided,
--- no more modifiers can be added and the original `command` is returned instead.
--- Otherwise, `self` is returned and further modifiers can be added.
---
--- Parameters:
---  * modifier - (optional) The modifier that was added.
---  * keyCode	- (optional) The key code being modified.
--- Returns:
---  * `self` if no `keyCode` is provided, or the original `command`.
function builder:add(modifier, keyCode)
	self._modifiers[#self._modifiers + 1] = modifier
	if keyCode then
		self._keyCode = keyCode
		-- we're done here
		local shortcut = shortcut:new(self._modifiers, keyCode)
		if self._receiver then
			return self._receiver(shortcut)
		else
			return
		end
		return self._command:addShortcut(self)
	else
		return self
	end
end

function builder:control(keyCode)
	return self:add("control", keyCode)
end

function builder:ctrl(keyCode)
	return self:control(keyCode)
end

function builder:option(keyCode)
	return self:add("option", keyCode)
end

function builder:alt(keyCode)
	return self:option(keyCode)
end

function builder:command(keyCode)
	return self:add("command", keyCode)
end

function builder:cmd(keyCode)
	return self:command(keyCode)
end

function builder:shift(keyCode)
	return self:add("shift", keyCode)
end

return shortcut