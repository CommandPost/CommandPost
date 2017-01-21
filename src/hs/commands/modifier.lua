local log			= require("hs.logger").new("cmdmod")

local modifier = {}

--- hs.commands.modifier:new() -> modifier
--- Creates a new menu modifier, which can have items and sub-menus added to it.
---
--- Modifiers are additive, and intended to work alongside `command` instances.
--- You can create a complex keystroke combo by chaining the modifier names together.
--- For example:
---
--- `command:new("Foo"):activatedBy():cmd():alt("x")`
---
--- Returns:
---  * modifier - The modifier that was created.
---
function modifier:new(command)
	o = {
		_command = command,
		_modifiers = {},
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

--- hs.commands.modifier:_add(modifier, keyCode) -> modifier
--- Adds the specified modifier to the set. If a `keyCode` is provided,
--- no more modifiers can be added and the original command is returned.
--- Otherwise, `self` is returned and further modifiers can be added.
---
--- Parameters:
---  * modifier - The modifier that was added.
---  * keyCode	- (optional) The key code being modified.
--- Returns:
---  * `self` if no `keyCode` is provided, or the original `command`.
function modifier:add(modifier, keyCode)
	self._modifiers[#self._modifiers + 1] = modifier
	if keyCode then
		-- we're done here
		return self._command:_addHotkey(self._modifiers, keyCode)
	else
		return self
	end
end

function modifier:control(keyCode)
	return self:add("control", keyCode)
end

function modifier:ctrl(keyCode)
	return self:control(keyCode)
end

function modifier:option(keyCode)
	return self:add("option", keyCode)
end

function modifier:alt(keyCode)
	return self:option(keyCode)
end

function modifier:command(keyCode)
	return self:add("command", keyCode)
end

function modifier:cmd(keyCode)
	return self:command(keyCode)
end

function modifier:shift(keyCode)
	return self:add("shift", keyCode)
end

return modifier