--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    S H O R T C U T   C O M M A N D S                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.commands.shortcut ===
---
--- Shortcut Commands

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("shortcut")

local eventtap									= require("hs.eventtap")
local fnutils									= require("hs.fnutils")
local hotkey									= require("hs.hotkey")
local keycodes									= require("hs.keycodes")

local englishKeyCodes							= require("cp.commands.englishKeyCodes")
local plist										= require("cp.plist")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

-- The shortcut class
local shortcut = {}

-- The shortcut builder class
local builder = {}

-- Only show Hotkey Errors:
hotkey.setLogLevel("error")

-- shortcut.textToKeyCode() -> string
-- Function
-- Translates string into a key code.
--
-- Parameters:
--  * input - string
--
-- Returns:
--  * Keycode as String or ""
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

--- cp.commands.shortcut:new(command) -> shortcut
--- Method
--- Creates a new keyboard shortcut, attached to the specified `hs.commands.command`
---
--- Parameters:
---  * `modifiers` 	- The modifiers.
---  * `keyCode`	- The key code.
---
--- Returns:
---  * shortcut - The shortcut that was created.
function shortcut:new(modifiers, keyCode)
	local o = {
		_modifiers = modifiers or {},
		_keyCode = keyCode,
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

--- cp.commands.shortcut:build(receiverFn) -> cp.commands.shortcut.builder
--- Method
--- Creates a new shortcut builder.
---
--- Parameters:
---  * `receiverFn`		- (optional) a function which will get passed the shortcut when the build is complete.
---
--- Returns:
---  * `shortcut.builder` which can be used to create the shortcut.
---
--- Notes:
--- * If provided, the receiver function will be called when the shortcut has been configured, and passed the new
---   shortcut. The result of that function will be returned to the next stage.
---   If no `receiverFn` is provided, the shortcut will be returned directly.
---
---   The builder is additive. You can create a complex keystroke combo by
---   chaining the shortcut names together.
---
---   For example:
---
---     `local myShortcut = shortcut:build():cmd():alt("x")`
---
---   Alternately, provide a `receiver` function and it will get passed the shortcut instead:
---
---     `shortcut:build(function(shortcut) self._myShortcut = shortcut end):cmd():alt("x")`
function shortcut:build(receiverFn)
	return builder:new(receiverFn)
end

--- cp.commands.shortcut:getModifiers() -> table
--- Method
--- Returns a table containing the modifiers for a shortcut.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `table` containing the modifiers of the shortcut.
function shortcut:getModifiers()
	return self._modifiers
end

--- cp.commands.shortcut:getKeyCode() -> string
--- Method
--- Returns a string containing the keycode of the shortcut.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `string` containing the keycode of the shortcut.
function shortcut:getKeyCode()
	return self._keyCode
end

--- cp.commands.shortcut:isEnabled() -> boolean
--- Method
--- Is the shortcut enabled?
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns `true` if the shortcut is enabled otherwise `false`
function shortcut:isEnabled()
	return self._enabled
end

--- cp.commands.shortcut:enable() -> shortcut
--- Method
--- This enables the shortcut. If a hotkey has been bound, it will be enabled also.
---
--- Parameters:
---  * None
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

--- cp.commands.shortcut:enable() -> shortcut
--- Method
--- This enables the shortcut. If a hotkey has been bound, it will be enabled also.
---
--- Parameters:
---  * None
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

-- getListOfUnavailableShortcuts() -> table
-- Function
-- Returns a table of shortcuts already in use by macOS
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of shortcuts that are already in use by macOS.
function getListOfUnavailableShortcuts()
	local unavailibleShortcuts = {}
	local symbolichotkeys = plist.binaryFileToTable("~/Library/Preferences/com.apple.symbolichotkeys.plist")
	if symbolichotkeys and symbolichotkeys["AppleSymbolicHotKeys"] then
		for i, v in pairs(symbolichotkeys["AppleSymbolicHotKeys"]) do
			if v["enabled"] and v["value"]["parameters"] and v["value"]["parameters"][2] and v["value"]["parameters"][3] and next(tools.modifierMaskToModifiers(v["value"]["parameters"][3])) ~= nil then
				unavailibleShortcuts[#unavailibleShortcuts + 1] = { keycode = v["value"]["parameters"][2], modifiers = tools.modifierMaskToModifiers(v["value"]["parameters"][3]) }
			end
		end
	end
	return unavailibleShortcuts
end

-- isShortcutAvailable() -> boolean
-- Function
-- Returns whether or not a shortcut is already used by macOS
--
-- Parameters:
--  * modifiers - a table of modifiers
--  * keycode - keycode as string
--
-- Returns:
--  * `true` if the shortcut is available and not already used by macOS otherwise `false`
function isShortcutAvailable(modifiers, keycode)
	local listOfUnavailableShortcuts = getListOfUnavailableShortcuts()
	for i, v in pairs(listOfUnavailableShortcuts) do
		local modifierMatch = true
		if #modifiers ~= #v.modifiers then
			modifierMatch = false
		else
			for ii, vv in pairs(v.modifiers) do
				if not fnutils.contains(modifiers, vv) then
					modifierMatch = false
				end
			end
		end
		if modifierMatch and keycode == v.keycode then
			return false
		end
	end
	return true
end

--- cp.commands.shortcut:bind(pressedFn, releasedFn, repeatedFn) -> shortcut
--- Method
--- This function binds the shortcut to a hotkey, with the specified callback functions for `pressedFn`, `releasedFn` and `repeatedFn`.
---
--- Parameters:
---  * `pressedFn`	- (optional) If present, this is called when the shortcut combo is pressed.
---  * `releasedFn`	- (optional) If present, this is called when the shortcut combo is released.
---  * `repeatedFn`	- (optional) If present, this is called when the shortcut combo is repeated.
---
--- Returns:
---  * `self`
---
--- Notes:
---  * If the shortcut is enabled, the hotkey will also be enabled at this point.
function shortcut:bind(pressedFn, releasedFn, repeatedFn)
	-- Unbind any existing hotkey
	self:unbind()
	-- Bind a new one with the specified calleback functions.
	local keycode = shortcut.textToKeyCode(self:getKeyCode())
	local modifiers = self:getModifiers()

	if not isShortcutAvailable(modifiers, keycode) then

		--------------------------------------------------------------------------------
		--
		-- TODO: Should this do something else? Disable the command/shortcut?
		--
		--------------------------------------------------------------------------------

		log.wf("This shortcut is currently used by macOS, so skipping: %s %s", keycode, hs.inspect(modifiers))

	else
		if keycode ~= nil and keycode ~= "" then
			self._hotkey = hotkey.new(modifiers, keycode, pressedFn, releasedFn, repeatedFn)
			self._hotkey.shortcut = self
			if self:isEnabled() then
				self._hotkey:enable()
			end
		else
			-- TODO: Why it this happening?
			log.wf("Unable to find key code for '%s'.", self:getKeyCode())
		end
	end
	return self
end

-- TODO: Add documentation
function shortcut:unbind()
	local hotkey = self._hotkey
	if hotkey then
		hotkey:disable()
		hotkey:delete()
		self._hotkey = nil
	end
	return self
end

-- TODO: Add documentation
function shortcut:delete()
	return self:unbind()
end

--- cp.commands.shortcut:trigger() -> shortcut
--- Method
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

--- === cp.commands.shortcut.builder ===
---
--- Shortcut Commands Builder Module.

--- cp.commands.shortcut.builder:new(receiverFn)
--- Method
--- Creates a new shortcut builder. If provided, the receiver function
--- will be called when the shortcut has been configured, and passed the new
--- shortcut. The result of that function will be returned to the next stage.
--- If no `receiverFn` is provided, the shortcut will be returned directly.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function builder:new(receiverFn)
	local o = {
		_receiver	= receiverFn,
		_modifiers 	= modifiers or {},
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

--- cp.commands.shortcut.builder:add(modifier, [keyCode]) -> shortcut/command
--- Method
--- Adds the specified modifier to the set. If a `keyCode` is provided,
--- no more modifiers can be added and the original `command` is returned instead.
--- Otherwise, `self` is returned and further modifiers can be added.
---
--- Parameters:
---  * modifier - (optional) The modifier that was added.
---  * keyCode	- (optional) The key code being modified.
---
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

-- TODO: Add documentation
function builder:control(keyCode)
	return self:add("control", keyCode)
end

-- TODO: Add documentation
function builder:ctrl(keyCode)
	return self:control(keyCode)
end

-- TODO: Add documentation
function builder:option(keyCode)
	return self:add("option", keyCode)
end

-- TODO: Add documentation
function builder:alt(keyCode)
	return self:option(keyCode)
end

-- TODO: Add documentation
function builder:command(keyCode)
	return self:add("command", keyCode)
end

-- TODO: Add documentation
function builder:cmd(keyCode)
	return self:command(keyCode)
end

-- TODO: Add documentation
function builder:shift(keyCode)
	return self:add("shift", keyCode)
end

return shortcut