--- === cp.commands.shortcut ===
---
--- Shortcut Commands

local require = require
local log										 = require("hs.logger").new("shortcut")

local eventtap							 = require("hs.eventtap")
local hotkey								 = require("hs.hotkey")
local keycodes							 = require("hs.keycodes")

local englishKeyCodes				 = require("cp.commands.englishKeyCodes")

local prop									 = require("cp.prop")



-- The shortcut class
local shortcut = {}
shortcut.mt = {}
shortcut.mt.__index = shortcut.mt

-- The shortcut builder class
local builder = {}
builder.mt = {}
builder.mt.__index = builder.mt

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

--- cp.commands.shortcut.new(modifiers, keyCode) -> shortcut
--- Function
--- Creates a new keyboard shortcut, attached to the specified `hs.commands.command`
---
--- Parameters:
---  * `modifiers` 	- The modifiers.
---  * `keyCode`	- The key code.
---
--- Returns:
---  * shortcut - The shortcut that was created.
function shortcut.new(modifiers, keyCode)
    local o = {
        _modifiers	= modifiers or {},
        _keyCode	= keyCode,
    }
    return prop.extend(o, shortcut.mt)
end

--- cp.commands.shortcut.build(receiverFn) -> cp.commands.shortcut.builder
--- Function
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
---     `local myShortcut = shortcut.build():cmd():alt("x")`
---
---   Alternately, provide a `receiver` function and it will get passed the shortcut instead:
---
---     `shortcut.build(function(shortcut) self._myShortcut = shortcut end):cmd():alt("x")`
function shortcut.build(receiverFn)
    return builder.new(receiverFn)
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
function shortcut.mt:getModifiers()
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
function shortcut.mt:getKeyCode()
    return self._keyCode
end

--- cp.commands.shortcut:isEnabled <cp.prop: boolean>
--- Field
--- If `true`, the shortcut is enabled.
shortcut.mt.isEnabled = prop(
    function(self) return self._enabled end,
    function(enabled, self)
        self._enabled = enabled
        if self._hotkey then
            if enabled then
                self._hotkey:enable()
            else
                self._hotkey:disable()
            end
        end
    end
):bind(shortcut.mt)

--- cp.commands.shortcut:enable() -> shortcut
--- Method
--- This enables the shortcut. If a hotkey has been bound, it will be enabled also.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `self`
function shortcut.mt:enable()
    self:isEnabled(true)
    return self
end

--- cp.commands.shortcut:disable() -> shortcut
--- Method
--- This disables the shortcut. If a hotkey has been bound, it will be disabled also.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `self`
function shortcut.mt:disable()
    self:ifEnabled(false)
    return self
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
function shortcut.mt:bind(pressedFn, releasedFn, repeatedFn)

    --------------------------------------------------------------------------------
    -- Unbind any existing hotkey:
    --------------------------------------------------------------------------------
    self:unbind()

    --------------------------------------------------------------------------------
    -- Bind a new one with the specified callback functions:
    --------------------------------------------------------------------------------
    local keycode = shortcut.textToKeyCode(self:getKeyCode())
    local modifiers = self:getModifiers()

    if keycode ~= nil and keycode ~= "" then
        self._hotkey = hotkey.new(modifiers, keycode, pressedFn, releasedFn, repeatedFn)
        self._hotkey.shortcut = self
        if self:isEnabled() then
            self._hotkey:enable()
        else
            self._hotkey:disable()
        end
    else
        -- TODO: Why it this happening?
        log.ef("Unable to find key code for '%s'.", self:getKeyCode())
    end

    return self
end

--- cp.commands.shortcut:unbind() -> shortcut
--- Method
--- Unbinds a shortcut.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `self`
function shortcut.mt:unbind()
    local hk = self._hotkey
    if hk then
        hk:disable()
        hk:delete()
        self._hotkey = nil
    end
    return self
end

--- cp.commands.shortcut:delete() -> shortcut
--- Method
--- Deletes a shortcut.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `self`
function shortcut.mt:delete()
    return self:unbind()
end

--- cp.commands.shortcut:trigger() -> shortcut
--- Method
--- This will trigger the keystroke specified in the shortcut.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `self`
function shortcut.mt:trigger()
    local keyCode = shortcut.textToKeyCode(self:getKeyCode())
    eventtap.keyStroke(self._modifiers, keyCode)
    return self
end

function shortcut.mt:__tostring()
    local modifiers = table.concat(self._modifiers, "+")
    return string.format("shortcut: %s %s", modifiers, self:getKeyCode())
end

--- === cp.commands.shortcut.builder ===
---
--- Shortcut Commands Builder Module.

--- cp.commands.shortcut.builder.new([receiverFn]) -> builder
--- Method
--- Creates a new shortcut builder. If provided, the receiver function
--- will be called when the shortcut has been configured, and passed the new
--- shortcut. The result of that function will be returned to the next stage.
--- If no `receiverFn` is provided, the shortcut will be returned directly.
---
--- Parameters:
---  * `receiverFn`	- The function which will be called with the new shortcut, when built.
---
--- Returns:
---  * The builder instance
function builder.new(receiverFn)
    local o = {
        _receiver	= receiverFn,
        _modifiers 	= {},
    }
    setmetatable(o, builder.mt)
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
function builder.mt:add(modifier, keyCode)
    self._modifiers[#self._modifiers + 1] = modifier
    if keyCode then
        self._keyCode = keyCode
        -- we're done here
        local s = shortcut.new(self._modifiers, keyCode)
        if self._receiver then
            return self._receiver(s)
        end
        return self._command:addShortcut(self)
    else
        return self
    end
end

-- TODO: Add documentation
function builder.mt:control(keyCode)
    return self:add("control", keyCode)
end

-- TODO: Add documentation
function builder.mt:ctrl(keyCode)
    return self:control(keyCode)
end

-- TODO: Add documentation
function builder.mt:option(keyCode)
    return self:add("option", keyCode)
end

-- TODO: Add documentation
function builder.mt:alt(keyCode)
    return self:option(keyCode)
end

-- TODO: Add documentation
function builder.mt:command(keyCode)
    return self:add("command", keyCode)
end

-- TODO: Add documentation
function builder.mt:cmd(keyCode)
    return self:command(keyCode)
end

-- TODO: Add documentation
function builder.mt:shift(keyCode)
    return self:add("shift", keyCode)
end

return shortcut
